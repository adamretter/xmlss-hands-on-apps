xquery version "1.0";

module namespace mylist = "http://whatithink.com/xquery/mylist";

declare namespace atom = "http://www.w3.org/2005/Atom";
declare namespace xh = "http://www.w3.org/1999/xhtml";
declare namespace order = "http://whatithink.com/order";
declare namespace status = "http://whatithink.com/printer/order/status";

import module namespace dt = "http://exist-db.org/xquery/datetime";
import module namespace httpclient = "http://exist-db.org/xquery/httpclient";
import module namespace util = "http://exist-db.org/xquery/util";

import module namespace config = "http://whatithink.com/xquery/config" at "config.xqm";
import module namespace entry = "http://whatithink.com/xquery/entry" at "entry.xqm";
import module namespace security = "http://whatithink.com/xquery/security" at "security.xqm";

declare variable $mylist:mylist-filename := "mylist.xml";

declare function mylist:add($entry as document-node()) as xs:boolean {
    let $mylist := mylist:get-or-create() return
        if($mylist/mylist:list/mylist:entry/@ref = $entry/atom:entry/atom:id/text())then
            true()
        else(
            let $null := update insert <mylist:entry ref="{$entry/atom:entry/atom:id}"/> into $mylist/mylist:list return
                true()
        )
};

declare function mylist:browse-all-entries() as element(xh:ul) {
    <xh:ul id="myEntryList">
    {
        for $entry in mylist:get-entries() return   
            <xh:li><xh:a href="entry/browse/{entry:create-uri($entry)}">{$entry/atom:title/text()}</xh:a></xh:li>
    }
    </xh:ul>
};

declare function mylist:get-entries() as element(atom:entry)* {
    for $list-entry in mylist:get-or-create()/mylist:list/mylist:entry return
        entry:get-entry-from-id($list-entry/@ref)/atom:entry
};

(:
TODO - 
    declare function mylist:as-atom-feed() as document-node(element(atom:feed))
:)
declare function mylist:as-atom-feed() as document-node() {
    document {
        <feed xmlns="http://www.w3.org/2005/Atom">
            <title>whatithink.com by {security:get-username()}</title>
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

declare function mylist:get-or-create() as document-node() {

    let $mylist-uri := fn:concat(security:get-user-collection-path(), "/", $mylist:mylist-filename) return

        if(fn:doc-available($mylist-uri))then
            fn:doc($mylist-uri)
        else
            let $mylist-uri := xmldb:store(security:get-user-collection-path(), $mylist:mylist-filename, <mylist:list/>) return
                fn:doc($mylist-uri)
};

declare function mylist:clear() as empty() {
    let $mylist := mylist:get-or-create() return
        update delete $mylist/mylist:list/mylist:entry
};

declare function mylist:order-from-xml($order-upload as element(order-upload)) as xs:boolean {
    
    (: decode the base64 uploaded file :)
    let $order := util:parse(util:base64-decode($order-upload/file)),
    $for-username := $order-upload/for/username return
        
       let $order-for-user := mylist:replace-element($order/order:Order, <order:RequestId>{$for-username}</order:RequestId>) return
       
            mylist:order($order-for-user)
        
};

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

declare function mylist:browse-all-orders() as element(xh:table) {
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