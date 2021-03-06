(:
 Copyright 2011 Adam Retter

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
:)

(:~
: This module manages a logged in Users list of
: atom entries that they want to order as a book
: and/or send to the printers
:
: @author Adam Retter <adam.retter@googlemail.com>
: @version 201109122029
:)
xquery version "1.0";

module namespace mylist = "http://whatithink.com/xquery/mylist";

declare namespace atom = "http://www.w3.org/2005/Atom";
declare namespace xh = "http://www.w3.org/1999/xhtml";
declare namespace order = "http://whatithink.com/order";
declare namespace status = "http://whatithink.com/printer/order/status";

import module namespace dt = "http://exist-db.org/xquery/datetime";
import module namespace httpclient = "http://exist-db.org/xquery/httpclient";
import module namespace sm = "http://exist-db.org/xquery/securitymanager";
import module namespace util = "http://exist-db.org/xquery/util";

import module namespace config = "http://whatithink.com/xquery/config" at "config.xqm";
import module namespace entry = "http://whatithink.com/xquery/entry" at "entry.xqm";
import module namespace security = "http://whatithink.com/xquery/security" at "security.xqm";

declare variable $mylist:mylist-filename := "mylist.xml";

(:~
: Adds an atom entry to the users list
:
: @param entry
:   The atom entry to add to the list
:
: @return
:   true() if the entry was added to the list, false() otherwise
:)
declare function mylist:add($entry as document-node()) as xs:boolean {
    let $mylist := mylist:get-or-create() return
        if($mylist/mylist:list/mylist:entry/@ref = $entry/atom:entry/atom:id/text())then
            true()
        else(
            let $null := update insert <mylist:entry ref="{$entry/atom:entry/atom:id}"/> into $mylist/mylist:list return
                true()
        )
};

(:~
: Removes an atom entry from the users list
:
: @param entry
:   The atom entry to remove to the list
:
: @return
:   true() if the entry was removed from the list, false() otherwise
:)
declare function mylist:remove($entry as document-node()) as xs:boolean {
    let $mylist := mylist:get-or-create(),
    $mylist-entry := $mylist/mylist:list/mylist:entry[@ref eq $entry/atom:entry/atom:id] return
        if(fn:empty($mylist-entry))then
            true()
        else(
            let $null := update delete $mylist-entry return
                true()
        )
};

(:~
: Generates an XHTML list of the current logged in users atom entries
:
: @return
:   An XHTML list of the current logged in users atom entries,
:   complete with hyperlinks to retrieve each entry
:)
declare function mylist:browse-all-entries() as element(xh:ul) {
    <xh:ul id="myEntryList">
    {
        for $entry in mylist:get-entries() return   
            <xh:li><xh:a href="entry/view/{entry:create-uri($entry)}">{$entry/atom:title/text()}</xh:a>{entry:show-add-to-mylist($entry, security:is-user() or security:is-manager())}</xh:li>
    }
    </xh:ul>
};

(:~
: Gets the current logged in users atom:entries from their list
:
: @return
:   The current logged in users atom:entries from their list
:)
declare function mylist:get-entries() as element(atom:entry)* {
    for $list-entry in mylist:get-or-create()/mylist:list/mylist:entry return
        entry:get-entry-from-id($list-entry/@ref)/atom:entry
};

(:~
: Gets the current logged in users list of atom:entries as an atom feed
:
: @return
:   An atom feed of the currently logged in users atom:entries
:)
declare function mylist:as-atom-feed() as document-node() {
    document {
        <feed xmlns="http://www.w3.org/2005/Atom">
            <title>seewhatithink.com by {security:get-username()}</title>
            <id>urn:uuid:{util:uuid()}</id>
            <updated>{xmldb:created(security:get-user-collection-path(), $mylist:mylist-filename)}</updated>
            <author>
                <name>{security:get-username()}</name>
                <email>{security:get-user-email()}</email>
            </author>
            {
                mylist:get-entries()
            }
        </feed>
    }
};

(:~
: Gets the document that holds the currently logged in users list.
: If the document does not exist it will be created.
:
: @return
:   The document which holds the users personal list of atom entries
:)
declare function mylist:get-or-create() as document-node() {

    let $mylist-uri := fn:concat(security:get-user-collection-path(), "/", $mylist:mylist-filename) return

        if(fn:doc-available($mylist-uri))then
            fn:doc($mylist-uri)
        else
            let $mylist-uri := xmldb:store(security:get-user-collection-path(), $mylist:mylist-filename, <mylist:list/>),
            $null := sm:chmod(xs:anyURI($mylist-uri), "rwxr--r--") return
                fn:doc($mylist-uri)
};

(:~
: Determines whether the entry exists in the users list
:
: @param $entry
:   The atom entry
:
: @return
:   true() if the entry exists in the users list, false() otherwise
:)
declare function mylist:has-entry($entry as element(atom:entry)) as xs:boolean {
    let $mylist := mylist:get-or-create() return
        fn:not(fn:empty($mylist[mylist:list/mylist:entry/@ref = $entry/atom:id])) 
};

(:~
: Clears all entries from the currently logged in users list
:)
declare function mylist:clear() as empty() {
    let $mylist := mylist:get-or-create() return
        update delete $mylist/mylist:list/mylist:entry
};

(:~
: Places an order with the Printers for
: the contents of a list
:
: The list is uploaded by an admin
: whom specifies the user. The list is
: then ordered for that user.
:
: @param order-upload
:   The Order wrapped in an order-upload element,
:   with the following format - 
:       <order-upload>
:           <file xsi:type="xsd:base64Binary" filename="" media-type=""/>
:               <for>
:                   <username/>
:               </for>
:       </order-upload>
:
: @return
:   true() if we could order the list, false() otherwise
:)
declare function mylist:order-from-xml($order-upload as element(order-upload)) as xs:boolean {
    
    (: decode the base64 uploaded file :)
    let $order := util:parse(util:base64-decode($order-upload/file)),
    
    (: get the username of whom this order is for :)
    $for-username := $order-upload/for/username return
        
       let $order-for-user := mylist:replace-element($order/order:Order, <order:RequestId>{$for-username}</order:RequestId>) return
       
            mylist:order($order-for-user)
        
};

(:~
: Replaces one element with another.
:
: The function looks at the given $src element
: and all child elements recursively
: if the QName of the $replacement element
: matches the element under comparisson then
: it is replaced.
:
: @param src
:   The element to replace or a container of the element to replace
:
: @param replacement
:   The element to substitute
:
: @return the src with any replacements made
:)
declare function mylist:replace-element($src as element(), $replacement as element()) as element() {
    if(node-name($src) eq node-name($replacement))then
        $replacement
    else
        element { node-name($src) } {
            $src/@*,
            $src/text(),
            for $child in $src/child::element() return
                mylist:replace-element($child, $replacement)
            
        }
};

(:~
: Sends an Order to the Printers via REST
:
: @param order
:   The order to send to the printers
:
: @return
:   true() if the order was sent, false() otherwise
:)
declare function mylist:order($order as element(order:Order)) as xs:boolean {
    let $result := httpclient:post(
        $config:printer-webapp-restful-order-uri,
        $order,
        false(),
        <headers>
            <header name="Content-Type" value="text/xml"/>
        </headers>
    ) return
        $result/@statusCode eq "200"
};

(:~
: Gets a list of all Orders for the currently logged in user
: via REST from the Printers.
:
: @return an XHTML snippet describing the Orders from the Printers
:)
declare function mylist:browse-all-orders() as element() {
    let $my-orders := httpclient:get(
        xs:anyURI(fn:concat($config:printer-webapp-restful-order-status-uri, "?requestId=", security:get-username())),
        false(),
        ()
    ) return
    
        if($my-orders/@statusCode ne "200")then
            <xh:p id="errorMsg">Could not contact the Printer's RESTful API for order status!</xh:p>
        else
            <xh:div id="myEntryListOrders">
                <xh:table>
                    <xh:thead>
                        <xh:tr>
                            <xh:th>Order Description</xh:th>
                            <xh:th>Quantity</xh:th>
                            <xh:th>Price</xh:th>
                            <xh:th>Date</xh:th>
                            <xh:th>Dispatched</xh:th>
                        </xh:tr>
                    </xh:thead>
                    <xh:tbody>
                    {
                        
                        for $order-status in $my-orders/httpclient:body/status:status/status:order return
                            <xh:tr>
                                <xh:td>{$order-status/status:description/text()}</xh:td>
                                <xh:td>{$order-status/status:quantity/text()}</xh:td>
                                <xh:td>&#163;&#160;{$order-status/status:price/text()}</xh:td>
                                <xh:td>{dt:format-dateTime($order-status/status:date_placed, "dd/MM/yy HH:mm")}</xh:td>
                                <xh:td style="background-color: {if($order-status/status:dispatched eq "true")then "#ccffcc" else "#ffffcc" };">{$order-status/status:dispatched/text()}</xh:td>
                            </xh:tr>
                    }
                    </xh:tbody>
                </xh:table>
            </xh:div>
};