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
: This script forms the URI router for the whatithink.com
: webapp. All web-requests are intercepted and dispatched by this script.
:
: @author Adam Retter <adam.retter@googlemail.com>
: @version 201109122029
:)
xquery version "1.0";

declare namespace atom = "http://www.w3.org/2005/Atom";
declare namespace exist = "http://exist.sourceforge.net/NS/exist";
declare namespace xf = "http://www.w3.org/2002/xforms";
declare namespace xh = "http://www.w3.org/1999/xhtml";
declare namespace order = "http://whatithink.com/order";

import module namespace request = "http://exist-db.org/xquery/request";
import module namespace response = "http://exist-db.org/xquery/response";
import module namespace transform = "http://exist-db.org/xquery/transform";
import module namespace xmldb = "http://exist-db.org/xquery/xmldb";
import module namespace util = "http://exist-db.org/xquery/util";
import module namespace xslfo = "http://exist-db.org/xquery/xslfo";

import module namespace config = "http://whatithink.com/xquery/config" at "config.xqm";
import module namespace entry = "http://whatithink.com/xquery/entry" at "entry.xqm";
import module namespace mylist = "http://whatithink.com/xquery/mylist" at "mylist.xqm";
import module namespace security = "http://whatithink.com/xquery/security" at "security.xqm";
import module namespace template = "http://whatithink.com/xquery/template" at "template.xqm";
import module namespace ontology = "http://whatithink.com/xquery/ontology" at "ontology.xqm";


(: xhtml 1.1 :)
declare option exist:serialize "media-type=text/html method=xhtml doctype-public=-//W3C//DTD&#160;XHTML&#160;1.1//EN doctype-system=http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd";
(:
declare option exist:serialize "media-type=text/html method=xhtml";
:)

declare variable $exist:path external;
declare variable $exist:root external;
declare variable $exist:controller external;

declare variable $DEFAULT-TEMPLATE := "template.xhtml";
declare variable $rel-path := fn:concat($exist:root, '/', $exist:controller);

declare variable $is-logged-in := xmldb:get-current-user() ne $config:guest-username;



declare function local:ignore() as element(exist:ignore) {
    <ignore xmlns="http://exist.sourceforge.net/NS/exist">
        <cache-control cache="yes"/>
    </ignore>
};

declare function local:redirect($uri as xs:string) as element(exist:dispatch) {
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="{$uri}"/>
    </dispatch>
};

declare function local:redirect-rel($uri as xs:string) as element(exist:dispatch) {
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="{template:make-relative-uri($exist:path, $uri)}"/>
    </dispatch>
};

declare function local:apply-specific-menu($standard-menus as document-node()+, $specific-menu as document-node()) as document-node()+ {
    for $standard-menu in $standard-menus return
        template:merge($exist:path, $standard-menu, $specific-menu)
};


(: is someone logged in? :)
let $menus := if($is-logged-in)then
        (
            if(security:is-user() or security:is-manager())then
                fn:doc(fn:concat($rel-path, "/user-header-links.xml"))
            else()
            ,
            
            if(security:is-user())then
                fn:doc(fn:concat($rel-path, "/user-menu-box.xml"))
            else()
            ,
            
            if(security:is-manager())then(
                fn:doc(fn:concat($rel-path, "/user-header-links.xml")),
                fn:doc(fn:concat($rel-path, "/manager-menu-box.xml"))
            )else()
        )
    else (
        if(request:get-parameter("login", ()) eq "failed") then
            template:merge($exist:path, fn:doc(fn:concat($rel-path, "/login-box.xml")),  fn:doc(fn:concat($rel-path, "/login-box.failed-message.xml"))) 
        else
            fn:doc(fn:concat($rel-path, "/login-box.xml"))
    )
    return

        (: process url path :)
        
        if($exist:path eq "")then
            local:redirect(fn:concat(request:get-uri(), "/"))
            
        else if($exist:path eq "/" or $exist:path eq "/home.xml") then
            template:process-template($rel-path, $exist:path, $DEFAULT-TEMPLATE, ($menus, fn:doc(fn:concat($rel-path, "/home.xml"))))
        
        else if($exist:path eq "/login") then
            if(security:login(request:get-parameter("username", "unknown"), request:get-parameter("password", "unknown")))then
                local:redirect("entry/browse")
            else
                local:redirect("./?login=failed")

        else if($exist:path eq "/logout") then
        (
            security:logout(),
            local:redirect("./")
        )
        
        (: if not logged in and not accessing static content or home page then redirect to home page :)
        (: safe urls below :)
        else if($is-logged-in eq false() and fn:not(fn:starts-with($exist:path, "/entry/browse")) and fn:not($exist:path = ("/register")) and not(fn:starts-with($exist:path, "/images") or fn:starts-with($exist:path, "/css") or fn:starts-with($exist:path, "/scripts")))then
            local:redirect(fn:replace(request:get-uri(), fn:concat("(.*", $exist:controller, "/).*"), "$1"))
       
        else if($exist:path eq "/register") then
            if(request:get-method() eq "GET")then
                template:process-template($rel-path, $exist:path, $DEFAULT-TEMPLATE, ($menus, fn:doc(fn:concat($rel-path, "/registration.xml"))))
            else if(request:get-method() eq "POST")then
                let $request-data := request:get-data()/user return
                    if(security:register-user($request-data))then
                        local:redirect("entry/browse")
                    else
                    (
                        (: could not register the user - xform will show error :)
                        response:set-status-code(400),
                        <message>Unable to register the user '{$request-data/username}'</message>
                    )   
            else
                local:ignore()
        
        else if($exist:path eq "/entry/browse") then
            let $browse-user-entries-template := 
                if($is-logged-in)then
                    let $user-entries := entry:browse-user-entries() return
                        document { 
                            template:copy-and-replace($exist:path, fn:doc(fn:concat($rel-path, "/browse-entries.user.xml"))/xh:div, $user-entries)
                        }
                else()
            ,
            $browse-entries-template-with-user-entries := template:merge($exist:path, fn:doc(fn:concat($rel-path, "/browse-entries.xml")), $browse-user-entries-template),
            $browse-entries-template := document {
                template:copy-and-replace($exist:path, $browse-entries-template-with-user-entries/xh:div, entry:browse-all-entries())
            } return
                template:process-template($rel-path, $exist:path, $DEFAULT-TEMPLATE, ($menus, $browse-entries-template))

        else if(fn:starts-with($exist:path, "/entry/view/")) then
            let $entry-uri := fn:replace($exist:path, "/entry/view/", ""),
            $entry := entry:get-entry-from-uri($entry-uri),
            $html-entry := document { transform:transform($entry, doc(fn:concat($rel-path, "/entry-to-xhtml.xslt")), <parameters><param name="is-logged-in" value="{$is-logged-in}"/><param name="entry-uri" value="{$entry-uri}"/></parameters>) } return
                template:process-template($rel-path, $exist:path, $DEFAULT-TEMPLATE, ($menus, $html-entry))
        
        else if($exist:path eq "/entry/add") then
            if(request:get-method() eq "GET")then
                let $form-with-terms := template:merge($exist:path, fn:doc(fn:concat($rel-path, "/add-entry.xml")), document { <xf:instance xmlns="http://www.w3.org/2005/Atom" id="termList"><terms>{ ontology:get-as-atom-categories() }</terms></xf:instance> } ) return
                    template:process-template($rel-path, $exist:path, $DEFAULT-TEMPLATE, ($menus, $form-with-terms))
            else if(request:get-method() eq "POST")then
                let $request-data := request:get-data()/atom:entry return
                    if(entry:add($request-data))then
                        let $add-entry-success-template := template:merge($exist:path, fn:doc(fn:concat($rel-path, "/add-entry.success.xml")), document { <xh:span id="itemDescription">{$request-data/atom:title/text()}</xh:span> }) return
                            template:process-template($rel-path, $exist:path, $DEFAULT-TEMPLATE, ($menus, $add-entry-success-template))
                    else
                    (
                        (: could not add the entry - xform will show error :)
                        response:set-status-code(400),
                        <message>Unable to add the entry '{$request-data/atom:title}'</message>
                    )
            else
                local:ignore()
                
        else if($exist:path eq "/entry/add/xml") then
            if(request:get-method() eq "GET")then
                let $form-with-terms := template:merge($exist:path, fn:doc(fn:concat($rel-path, "/add-entry-xml.xml")), document { <xf:instance xmlns="" id="userList"><users>{for $user in sm:get-group-members($config:wit-group) return <user name="{$user}" username="{$user}"/> }</users></xf:instance> } ) return
                    template:process-template($rel-path, $exist:path, $DEFAULT-TEMPLATE, ($menus, $form-with-terms))
            else if(request:get-method() eq "POST")then
                let $request-data := request:get-data()/entry-upload return
                    if(entry:add-xml($request-data))then
                        template:process-template($rel-path, $exist:path, $DEFAULT-TEMPLATE, ($menus, fn:doc(fn:concat($rel-path, "/add-entry-xml.success.xml"))))
                    else
                    (
                        (: could not add the entry - xform will show error :)
                        response:set-status-code(400),
                        <message>Unable to add the entry for user '{$request-data/for/username}'</message>
                    )
            else
                local:ignore()
                
        else if($exist:path eq "/user/add/xml") then
            if(request:get-method() eq "GET")then
                let $form := fn:doc(fn:concat($rel-path, "/add-user-xml.xml")) return
                    template:process-template($rel-path, $exist:path, $DEFAULT-TEMPLATE, ($menus, $form))
            else if(request:get-method() eq "POST")then
                let $request-data := request:get-data()/user-upload return
                    if(security:create-user-from-xml($request-data))then
                        template:process-template($rel-path, $exist:path, $DEFAULT-TEMPLATE, ($menus, fn:doc(fn:concat($rel-path, "/add-user-xml.success.xml"))))
                    else
                    (
                        (: could not register the user - xform will show error :)
                        response:set-status-code(400),
                        <message>Unable to register the user</message>
                    )   
            else
                local:ignore()
        
        else if($exist:path eq "/ontology/upload/xml") then
            if(request:get-method() eq "GET")then
                let $form := fn:doc(fn:concat($rel-path, "/upload-ontology-xml.xml")) return
                    template:process-template($rel-path, $exist:path, $DEFAULT-TEMPLATE, ($menus, $form))
            else if(request:get-method() eq "POST")then
                let $request-data := request:get-data()/ontology-upload return
                    if(ontology:create-from-xml($request-data))then
                        template:process-template($rel-path, $exist:path, $DEFAULT-TEMPLATE, ($menus, fn:doc(fn:concat($rel-path, "/upload-ontology-xml.success.xml"))))
                    else
                    (
                        (: could not register the user - xform will show error :)
                        response:set-status-code(400),
                        <message>Unable to register the user</message>
                    )   
            else
                local:ignore()
        
        else if($exist:path eq "/ontology.owl") then
            let $null := util:declare-option("exist:serialize", "media-type=application/rdf+xml method=xml") return
                ontology:get()
        
        else if($exist:path eq "/order/add/xml") then
            if(request:get-method() eq "GET")then
                let $form-with-terms := template:merge($exist:path, fn:doc(fn:concat($rel-path, "/add-order-xml.xml")), document { <xf:instance xmlns="" id="userList"><users>{for $user in sm:get-group-members($config:wit-group) return <user name="{$user}" username="{$user}"/> }</users></xf:instance> } ) return
                    template:process-template($rel-path, $exist:path, $DEFAULT-TEMPLATE, ($menus, $form-with-terms))
            else if(request:get-method() eq "POST")then
                let $request-data := request:get-data()/order-upload return
                    if(mylist:order-from-xml($request-data))then
                        template:process-template($rel-path, $exist:path, $DEFAULT-TEMPLATE, ($menus, fn:doc(fn:concat($rel-path, "/add-order-xml.success.xml"))))
                    else
                    (
                        (: could not place the order - xform will show error :)
                        response:set-status-code(400),
                        <message>Unable to place the order for user '{$request-data/for/username}'</message>
                    )
            else
                local:ignore()
        
        else if($exist:path eq "/xquery") then
            if(request:get-method() eq "GET")then
                let $form := fn:doc(fn:concat($rel-path, "/xquery.xml")) return
                    template:process-template($rel-path, $exist:path, $DEFAULT-TEMPLATE, ($menus, $form))
            else if(request:get-method() eq "POST") then
                let $null := util:declare-option("exist:serialize", "media-type=text/html method=xhtml") return
                <results>{util:eval-with-context(request:get-parameter("xquery",()), (), false())}</results>
        else
            local:ignore()
        
        else if($exist:path eq "/entry/search") then
        
            (: create search specific menus :)
            let $specific-menus := local:apply-specific-menu($menus, fn:doc(fn:concat($rel-path, "/search-menu-box.xml"))),
            $search-results-template := 
                if(request:get-parameter("keywords",()))then
                    let $search-results := entry:search($rel-path, $exist:path, $is-logged-in, request:get-parameter("keywords", ())) return
                        document { 
                            template:copy-and-replace($exist:path, fn:doc(fn:concat($rel-path, "/search-by-content.results.xml"))/xh:div, $search-results)
                        } 
                else()
            ,
            $search-template := template:merge($exist:path, fn:doc(fn:concat($rel-path, "/search-by-content.xml")), $search-results-template) return
                template:process-template($rel-path, $exist:path, $DEFAULT-TEMPLATE, ($specific-menus, $search-template))
        
        else if($exist:path eq "/entry/term/search") then
            (: create search specific menus :)
            let $specific-menus := local:apply-specific-menu($menus, fn:doc(fn:concat($rel-path, "/search-menu-box.xml"))),
            $search-results-template := 
                if(request:get-parameter("term",()))then
                    let $search-results := entry:search-by-term($rel-path, $exist:path, $is-logged-in, request:get-parameter("term", ())) return
                        document { 
                            template:copy-and-replace($exist:path, fn:doc(fn:concat($rel-path, "/search-by-term.results.xml"))/xh:div, $search-results)
                        } 
                else()
            ,
            $search-by-term-template-with-terms := template:merge($exist:path, fn:doc(fn:concat($rel-path, "/search-by-term.xml")), document { <xh:select id="term" name="term">{for $term in fn:doc(fn:concat($rel-path, "/terms.xml"))/terms/term return <xh:option value="{$term}">{string($term/@label)}</xh:option>}</xh:select> }),
            $search-template := template:merge($exist:path, $search-by-term-template-with-terms, $search-results-template) return
                template:process-template($rel-path, $exist:path, $DEFAULT-TEMPLATE, ($specific-menus, $search-template))
        
        else if(fn:starts-with($exist:path, "/mylist/add/entry/"))then
            (: ONLY called from AJAX :)
            let $entry-uri := fn:replace($exist:path, "/mylist/add/entry/", ""),
            $entry := entry:get-entry-from-uri($entry-uri) return
            
                if(mylist:add($entry))then
                    <result>true</result>
                else(
                    response:set-status-code(400),
                    <result>false</result>
                )
            (:
            let $entry-uri := fn:replace($exist:path, "/mylist/add/entry/", ""),
            $entry := entry:get-entry-from-uri($entry-uri),
            $entry-title := document { <xh:span id="entryTitle">{$entry/atom:title/text()}</xh:span> },
            $mylist-template := template:merge(
                $exist:path,
                if(mylist:add($entry))then
                    fn:doc(fn:concat($rel-path, "/add-to-mylist.success.xml"))
                else
                    fn:doc(fn:concat($rel-path, "/add-to-mylist.error.xml"))
                ,
                $entry-title
            )
            return
                template:process-template($rel-path, $exist:path, $DEFAULT-TEMPLATE, ($menus, $mylist-template))
            :)
        
        else if(fn:starts-with($exist:path, "/mylist/remove/entry/"))then
            (: ONLY called from AJAX :)
            let $entry-uri := fn:replace($exist:path, "/mylist/remove/entry/", ""),
            $entry := entry:get-entry-from-uri($entry-uri) return
                if(mylist:remove($entry))then
                    <result>true</result>
                else(
                    response:set-status-code(400),
                    <result>false</result>
                )

            (:
            let $entry-uri := fn:replace($exist:path, "/mylist/remove/entry/", ""),
            $entry := entry:get-entry-from-uri($entry-uri),
            $entry-title := document { <xh:span id="entryTitle">{$entry/atom:title/text()}</xh:span> },
            $mylist-template := template:merge(
                $exist:path,
                if(mylist:remove($entry))then
                    fn:doc(fn:concat($rel-path, "/remove-from-mylist.success.xml"))
                else
                    fn:doc(fn:concat($rel-path, "/remove-from-mylist.error.xml"))
                ,
                $entry-title
            )
            return
                template:process-template($rel-path, $exist:path, $DEFAULT-TEMPLATE, ($menus, $mylist-template))
            :)
        
        else if($exist:path eq "/mylist")then
            let $mylist-template := template:merge($exist:path, fn:doc(fn:concat($rel-path, "/mylist.xml")), document{ mylist:browse-all-entries() }) return
                template:process-template($rel-path, $exist:path, $DEFAULT-TEMPLATE, ($menus, $mylist-template))
                
        else if($exist:path eq "/mylist.atom")then
            (: TODO consider a redirect to /list/<username>/mylist.atom i.e. make lists public atom feeds etc :)
            let $null := util:declare-option("exist:serialize", "media-type=application/atom+xml method=xml") return
                mylist:as-atom-feed()
                
        else if($exist:path eq "/mylist.pdf")then
            if(empty(mylist:get-entries()))then
                local:redirect("mylist")
            else
                (: TODO consider a redirect to /list/<username>/mylist.pdf i.e. make lists public atom feeds etc :)
                let $atom := mylist:as-atom-feed(),
                $fo-doc := transform:transform($atom, fn:doc(fn:concat($rel-path, "/mylist-to-fo.xslt")), <parameters><param name="logoUri" value="{$rel-path}/images/bg/banner.gif"/><param name="bgUri" value="{$rel-path}/images/bg/fo-background.gif"/></parameters>),
                $pdf := xslfo:render($fo-doc, "application/pdf", ()) return
                    (
                        response:stream-binary($pdf, "application/pdf", ()),
                        <empty/> (: TODO for some reason the URLRewrite controller in latest eXist-db trunk insists on at least one element being returned?!? :)
                    )
        
        else if($exist:path eq "/mylist/clear")then
            let $null := mylist:clear() return
                local:redirect-rel("mylist")
                
        else if($exist:path eq "/mylist/order") then
            if(request:get-method() eq "GET")then
                template:process-template($rel-path, $exist:path, $DEFAULT-TEMPLATE, ($menus, fn:doc(fn:concat($rel-path, "/order.xml"))))
            else if(request:get-method() eq "POST")then
                let $request-data := request:get-data()/order:Order return
                    if(mylist:order($request-data))then
                        let $order-success-template := template:merge($exist:path, fn:doc(fn:concat($rel-path, "/order.success.xml")), document { <xh:span id="itemDescription">{$request-data/order:Item/order:Description/text()}</xh:span> }) return
                            template:process-template($rel-path, $exist:path, $DEFAULT-TEMPLATE, ($menus, $order-success-template))
                else
                (
                    (: could not add the entry - xform will show error :)
                    response:set-status-code(400),
                    <message>Unable to send the order for book '{$request-data/order:Item/order:Description/text()}'</message>
                )
            else
                local:ignore()

        else if($exist:path eq "/mylist/orders") then
            let $mylist-orders-template := template:merge($exist:path, fn:doc(fn:concat($rel-path, "/mylist.orders.xml")), document{ mylist:browse-all-orders() }) return
                template:process-template($rel-path, $exist:path, $DEFAULT-TEMPLATE, ($menus, $mylist-orders-template))
                
        else
            local:ignore()