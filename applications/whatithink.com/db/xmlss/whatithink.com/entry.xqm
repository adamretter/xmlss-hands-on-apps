xquery version "1.0";

module namespace entry = "http://whatithink.com/xquery/entry";

declare namespace atom = "http://www.w3.org/2005/Atom";
declare namespace xh = "http://www.w3.org/1999/xhtml";

import module namespace kwic = "http://exist-db.org/xquery/kwic";
import module namespace util = "http://exist-db.org/xquery/util";

import module namespace config = "http://whatithink.com/xquery/config" at "config.xqm";
import module namespace security = "http://whatithink.com/xquery/security" at "security.xqm";

declare function entry:search($rel-path as xs:string, $request-rel-path as xs:string, $is-logged-in as xs:boolean, $keywords as xs:string) as element(xh:div)+ {
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

declare function entry:search-by-term($rel-path as xs:string, $request-rel-path as xs:string, $is-logged-in as xs:boolean, $term as xs:string) as element(xh:div)+ {
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

declare function entry:show-add-to-mylist($entry as element(atom:entry), $is-logged-in as xs:boolean) as element(xh:a)? {
    if($is-logged-in and fn:starts-with(fn:document-uri(fn:root($entry)), security:get-user-collection-path()))then
        <xh:a href="mylist/add/entry/{entry:create-uri($entry)}"><xh:img src="images/icons/tick.gif" alt="Print/Order"/></xh:a>
    else()
};

declare function entry:browse-user-entries() as element(xh:ul) {
    <xh:ul id="userEntryList">
    {
        for $entry in fn:collection(security:get-user-collection-path())/atom:entry
        let $entry-uri := entry:create-uri($entry) return
            <xh:li>
                <xh:a href="entry/view/{$entry-uri}">{$entry/atom:title/text()}</xh:a><xh:a href="mylist/add/entry/{$entry-uri}"><xh:img src="images/icons/tick.gif" alt="Print/Order"/></xh:a>
            </xh:li>
    }
    </xh:ul>
};

declare function entry:browse-all-entries() as element(xh:ul) {
    <xh:ul id="publicEntryList">
    {
        for $entry in fn:collection($config:wit-users-collection)/atom:entry return
            <xh:li><xh:a href="entry/view/{entry:create-uri($entry)}">{$entry/atom:title/text()}</xh:a></xh:li>
    }
    </xh:ul>
};

declare function entry:add($entry as element(atom:entry)) as xs:boolean {
    let $entry-uri := xmldb:store(security:get-user-collection-path(), (), $entry),
    $null := update value fn:doc($entry-uri)/atom:entry/atom:id with fn:concat("urn:uuid:", util:uuid()) return
        not(empty($entry-uri))
};

declare function entry:add-xml($entry-upload as element(entry-upload)) as xs:boolean {
    
    (: decode the base64 uploaded file :)
    let $entry := util:parse(util:base64-decode($entry-upload/file)),
    $for-username := $entry-upload/for/username return
    
        let $entry-uri := xmldb:store(security:get-user-collection-path($for-username), (), $entry) return
            not(empty($entry-uri))
};

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

declare function entry:make-uri-safe($string as xs:string) as xs:string {
    fn:replace(
        fn:replace(
            fn:replace($string, " - ", "_"), 
            " ", "_"),
        "-", "")
};

(: timestamp since the epoch in milliseconds :)
declare function entry:timetstamp-in-seconds($date-time as xs:dateTime) {
    let $duration-since-epoch := $date-time - xs:dateTime("1970-01-01T00:00:00Z") return
        ($duration-since-epoch div xs:dayTimeDuration("PT1S")) * 1000
};

declare function entry:get-entry-from-uri($entry-uri as xs:string) as document-node() {
    fn:collection($config:wit-users-collection)[atom:entry][entry:create-uri(atom:entry) eq $entry-uri]
};

declare function entry:get-entry-from-id($id as xs:string) as document-node() {
    fn:collection($config:wit-users-collection)[atom:entry/atom:id eq $id]
};