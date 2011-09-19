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
: This module deals with the creation and searching of the Atom
: entries for the whatithink.com web application.
:
: @author Adam Retter <adam.retter@googlemail.com>
: @version 201109122029
:)
xquery version "1.0";

module namespace entry = "http://whatithink.com/xquery/entry";

declare namespace atom = "http://www.w3.org/2005/Atom";
declare namespace xh = "http://www.w3.org/1999/xhtml";

import module namespace kwic = "http://exist-db.org/xquery/kwic";
import module namespace sm = "http://exist-db.org/xquery/securitymanager";
import module namespace util = "http://exist-db.org/xquery/util";

import module namespace config = "http://whatithink.com/xquery/config" at "config.xqm";
import module namespace mylist = "http://whatithink.com/xquery/mylist" at "mylist.xqm";
import module namespace security = "http://whatithink.com/xquery/security" at "security.xqm";

(:~
: Searches for atom entries matching keywords
:
: @param rel-path
:   Relative path to the URI routing controller
: @param request-rel-path
:   Relative path of this request URI
: @param is-logged-in
:   true() if a user has logged in, false() otherwise
: @param keywords
:   The keywords to search for
:
: @return
:   An XHTML snippet showing the result count and any matches
:)
declare function entry:search($rel-path as xs:string, $request-rel-path as xs:string, $is-logged-in as xs:boolean, $keywords as xs:string) as element()+ {
    let $results := fn:collection($config:wit-users-collection)/atom:entry[ft:query(atom:summary, $keywords)] return
        (
            <xh:span id="keywords">{$keywords}</xh:span>,
            <xh:span id="count">{count($results)}</xh:span>,
            <xh:div id="searchResultsList">
                <xh:ul>
                {
                    for $result in $results order by ft:score($result) descending return
                        <xh:li>
                            <xh:div><xh:a href="entry/view/{entry:create-uri($result)}">{$result/atom:title/text()}</xh:a>{entry:show-add-to-mylist($result, $is-logged-in)}</xh:div>
                            <xh:div>{kwic:summarize($result/atom:summary, <config width="40"/>)}</xh:div>
                        </xh:li>        
                }
                </xh:ul>
            </xh:div>
        )
};

(:~
: Searches for atom entries with a specific term from the ontology
:
: @param rel-path
:   Relative path to the URI routing controller
: @param request-rel-path
:   Relative path of this request URI
: @param is-logged-in
:   true() if a user has logged in, false() otherwise
: @param term
:   The term to search for
:
: @return
:   An XHTML snippet showing the result count and any matches
:)
declare function entry:search-by-term($rel-path as xs:string, $request-rel-path as xs:string, $is-logged-in as xs:boolean, $term as xs:string) as element()+ {
    let $results := fn:collection($config:wit-users-collection)/atom:entry[atom:category/@term = $term] return
        (
            <xh:span id="term">{$term}</xh:span>,
            <xh:span id="count">{count($results)}</xh:span>,
            <xh:div id="searchResultsList">
                <xh:ul>
                {
                    for $result in $results order by $result/atom:updated descending return
                        <xh:li>
                            <xh:div><xh:a href="entry/view/{entry:create-uri($result)}">{$result/atom:title/text()}</xh:a>{entry:show-add-to-mylist($result, $is-logged-in)}</xh:div>
                            <xh:div><xh:span class="following">{fn:substring($result/atom:summary, 0, 80)}...</xh:span></xh:div>
                        </xh:li>        
                }
                </xh:ul>
            </xh:div>
        )
};

(:~
: Generates a small `add to my list` XHTML snippet
: if there is a logged in user
:
: @param entry
:   The atom entry to generate the snippet for
: @param is-logged-in
:   true() if a user has logged in, false() otherwise
:
: @return
:   An XHTML hyperlink for adding the entry to the logged in users list, or an empty sequence
:)
declare function entry:show-add-to-mylist($entry as element(atom:entry), $is-logged-in as xs:boolean) as element(xh:a)? {
    if($is-logged-in and fn:starts-with(fn:document-uri(fn:root($entry)), security:get-user-collection-path()))then
        <xh:a href="mylist/add/entry/{entry:create-uri($entry)}"><xh:img src="images/icons/tick.gif" alt="Print/Order"/></xh:a>
    else()
};

(:~
: Generates an XHTML list of the current logged in users atom entries
:
: @return
:   An XHTML list of the current logged in users atom entries,
:   complete with hyperlinks to retrieve each entry
:)
declare function entry:browse-user-entries() as element(xh:ul) {
    <xh:ul id="userEntryList">
    {
        for $entry in fn:collection(security:get-user-collection-path())/atom:entry
        let $entry-uri := entry:create-uri($entry) return
            element xh:li {
                element xh:a {
                    attribute href { fn:concat("entry/view/", $entry-uri) },
                    $entry/atom:title/text()
                },
                element xh:input {
                    attribute type { "checkbox" },
                    attribute value { $entry-uri },
                    if(mylist:has-entry($entry))then
                        attribute checked{ "checked" }
                    else()
                }
            }
    }
    <!-- xh:a href="mylist/add/entry/{$entry-uri}"><xh:img src="images/icons/tick.gif" alt="Print/Order"/></xh:a -->
    </xh:ul>
};

(:~
: Generates an XHTML list of the all atom entries
:
: @return
:   An XHTML list of all atom entries,
:   complete with hyperlinks to retrieve each entry
:)
declare function entry:browse-all-entries() as element(xh:ul) {
    <xh:ul id="publicEntryList">
    {
        for $entry in fn:collection($config:wit-users-collection)/atom:entry return
            <xh:li><xh:a href="entry/view/{entry:create-uri($entry)}">{$entry/atom:title/text()}</xh:a></xh:li>
    }
    </xh:ul>
};

(:~
: Adds a new atom entry to the database.
:
: The new entry is stored in a collection owned by the 
: currently logged in user which sent the entry.
:
: @param entry
:   The atom entry
:
: @return
:   true() if we could store the new entry, false() otherwise
:)
declare function entry:add($entry as element(atom:entry)) as xs:boolean {
    let $entry-uri := xmldb:store(security:get-user-collection-path(), (), $entry),
    $null := sm:chmod(xs:anyURI($entry-uri), "rwur-ur--"),
    $null := update value fn:doc($entry-uri)/atom:entry/atom:id with fn:concat("urn:uuid:", util:uuid()) return
        not(empty($entry-uri))
};

(:~
: Adds a new atom entry to the database.
:
: The new entry is uploaded by an admin
: whom specifies the user. The entry is
: then stored into that users collection.
:
: @param entry-upload
:   The atom entry wrapped in an entry-upload element,
:   with the following format - 
:       <entry-upload>
:           <file xsi:type="xsd:base64Binary" filename="" media-type=""/>
:               <for>
:                   <username/>
:               </for>
:       </entry-upload>
:
: @return
:   true() if we could store the new entry, false() otherwise
:)
declare function entry:add-xml($entry-upload as element(entry-upload)) as xs:boolean {
    
    (: decode the base64 uploaded file :)
    let $entry := util:parse(util:base64-decode($entry-upload/file)),
    
    (: get the username of whom this entry is for :)
    $for-username := $entry-upload/for/username return
    
        let $entry-uri := xmldb:store(security:get-user-collection-path($for-username), (), $entry),
        $null := sm:chown(xs:anyURI($entry-uri), $for-username),
        $null := sm:chmod(xs:anyURI($entry-uri), "rwur-ur--") return
            not(empty($entry-uri))
};

(:~
: Creates a unique uri for an atom entry
:
: @param entry
:   The atom entry
:
: @return
:   The unique uri
:)
declare function entry:create-uri($entry as element(atom:entry)) as xs:string {
    fn:lower-case(fn:concat(
        entry:make-uri-safe($entry/atom:title),
        if(exists((fn:collection($config:wit-users-collection)/atom:entry except $entry)[string(atom:title) eq string($entry/atom:title)]))then
            fn:concat(
                "_",
                entry:timetstamp-in-seconds($entry/atom:updated)
            )
        else
            ()
    ))  
};

(:~
: Simple character replacement for a keyword that may be places in a URI
:
: @param string
:   The string to replace characters in
:
: @return The string with replaced characters
:)
declare function entry:make-uri-safe($string as xs:string) as xs:string {
    fn:replace(
        fn:replace(
            fn:replace($string, " - ", "_"), 
            " ", "_"),
        "-", "")
};

(:~
: Gets the dateTime as a Timestamp since the Unix epoch in seconds
:
: @param date-time
:   The dateTime to calculate a timestamp for
:
: @return
:   The timestamp in seconds since the Unix epoch
:)
declare function entry:timetstamp-in-seconds($date-time as xs:dateTime) {
    let $duration-since-epoch := $date-time - xs:dateTime("1970-01-01T00:00:00Z") return
        ($duration-since-epoch div xs:dayTimeDuration("PT1S")) * 1000
};

(:~
: Given the distinct URI of an atom entry, the entry will be retrieved
:
: @param entry-uri
:   The uri of the atom entry to retrieve
:
: @return
:   The atom entry
:)
declare function entry:get-entry-from-uri($entry-uri as xs:string) as document-node() {
    fn:collection($config:wit-users-collection)[atom:entry][entry:create-uri(atom:entry) eq $entry-uri]
};

(:~
: Given the distinct id of an atom entry, the entry will be retrieved
:
: @param id
:   The id of the atom entry to retrieve
:
: @return
:   The atom entry
:)
declare function entry:get-entry-from-id($id as xs:string) as document-node() {
    fn:collection($config:wit-users-collection)[atom:entry/atom:id eq $id]
};