xquery version "1.0";

module namespace security = "http://whatithink.com/xquery/security";

import module namespace session = "http://exist-db.org/xquery/session";
import module namespace xmldb = "http://exist-db.org/xquery/xmldb";
import module namespace util = "http://exist-db.org/xquery/util";

import module namespace config = "http://whatithink.com/xquery/config" at "config.xqm";

declare variable $security:user-metadata-filename := "user.metadata.xml";

(: declare function security:register-user($user as document-node(element(user))) as xs:boolean { :)
declare function security:register-user($user as element(user)) as xs:boolean {    
    
    (: temporarily become admin :)
    if(security:login($config:admin-username, $config:admin-password)) then
    
        util:catch(
            "java.lang.Exception",
            (
                (: create the user account :)
                let $null := xmldb:create-user($user/username, $user/password1, $config:wit-group, "/db") return
                
                (: login as the new user :)
                if(security:login($user/username, $user/password1))then
                (
                
                    (: create the users home collection :)
                    let $user-collection-path := xmldb:create-collection($config:wit-users-collection, $user/username),
                    
                    (: set collection permissions :)
                    $null := xmldb:set-collection-permissions($user-collection-path, $user/username, $config:wit-group, xmldb:string-to-permissions("rwur--r--")),
                    
                    (: store their metadata :)
                    $user-metadata-filename := xmldb:store($user-collection-path, $security:user-metadata-filename, <user>{$user/metadata}</user>),
                    
                    (: set metadata permissions :)
                    $null := xmldb:set-resource-permissions($user-collection-path, $security:user-metadata-filename, $user/username, $config:wit-group, xmldb:string-to-permissions("rwu------"))
                    
                    return
                        true()
                ) else
                    false()
            ),
            (
                (: could not create user so reset to guest user :)
                let $null := security:logout() return
                    false()
            )
        )
    else
        false()
};

declare function security:create-user-from-xml($user-upload as element(user-upload)) as xs:boolean {    
    
    (: decode the base64 uploaded file :)
    let $user := util:parse(util:base64-decode($user-upload/file))/user return
    
        (: temporarily become admin :)
        util:catch(
            "java.lang.Exception",
            (
                (: create the user account :)
                let $null := xmldb:create-user($user/username, $user/password1, $config:wit-group, "/db") return
                
                (: create the users home collection :)
                let $user-collection-path := xmldb:create-collection($config:wit-users-collection, $user/username),
                    
                (: set collection permissions :)
                $null := xmldb:set-collection-permissions($user-collection-path, $user/username, $config:wit-group, xmldb:string-to-permissions("rwur--r--")),
                    
                (: store their metadata :)
                $user-metadata-filename := xmldb:store($user-collection-path, $security:user-metadata-filename, <user>{$user/metadata}</user>),
                    
                (: set metadata permissions :)
                $null := xmldb:set-resource-permissions($user-collection-path, $security:user-metadata-filename, $user/username, $config:wit-group, xmldb:string-to-permissions("rwu------"))
                    
                return
                    true()
            ),
            (
                    false()
            )
        )
};

declare function security:login($username as xs:string, $password as xs:string) as xs:boolean {
    xmldb:login($config:db-root-collection, $username, $password)
};

declare function security:is-user() as xs:boolean {
    xmldb:get-user-groups(security:get-username()) = $config:wit-group
};

declare function security:is-manager() as xs:boolean {
  xmldb:get-user-groups(security:get-username()) = $config:wit-manager-group
};

declare function security:get-username() as xs:string {
    xmldb:get-current-user()
};

declare function security:get-user-email() as xs:string {
    let $user-collection-path := fn:concat($config:wit-users-collection, "/", security:get-username()) return
        fn:doc(fn:concat($user-collection-path, "/", $security:user-metadata-filename))/user/metadata/email
};

declare function security:get-user-collection-path() as xs:string {
    fn:concat($config:wit-users-collection, "/", security:get-username())
};

declare function security:get-user-collection-path($username as xs:string) as xs:string {
    fn:concat($config:wit-users-collection, "/", $username)
};

declare function security:logout() as empty() {
    let $null := security:login($config:guest-username, $config:guest-password),
    $null := session:clear() return
        ()
};