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
: This module manages user registration and login for
: the whatithink.com web application
:
: @author Adam Retter <adam.retter@googlemail.com>
: @version 201109122029
:)
xquery version "1.0";

module namespace security = "http://whatithink.com/xquery/security";

import module namespace session = "http://exist-db.org/xquery/session";
import module namespace xmldb = "http://exist-db.org/xquery/xmldb";
import module namespace util = "http://exist-db.org/xquery/util";

import module namespace config = "http://whatithink.com/xquery/config" at "config.xqm";

(: Each user has a small document which stores some
additional metadata about them. This is the name of that document.:)
declare variable $security:user-metadata-filename := "user.metadata.xml";

(:~
: Processes a new User Registration for the 
: whatithink.com web application
:
: @param user
:   An XML element describing the user, with the following format - 
:       <user>
:           <username/>
:           <password1/>
:           <password2/>
:           <metadata>
:               <created/>
:               <email/>
:           </metadata>
:           <agreement>false</agreement>
:       </user>
:
: @return
:   true() if the registration succeeded, false() otherwise
:)
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

(:~
: Processes a new User Registration for the 
: whatithink.com web application
:
: The new user registration is uploaded by an admin.
:
: @param user-upload
:   The user registration wrapped in a user-upload element,
:   with the following format -  
:       <user-upload>
:           <file xsi:type="xsd:base64Binary" filename="" media-type=""/>
:       </user-upload>
:
: For the format of the file @see security:register-user($user as element(user)) as xs:boolean
:
: @return
:   true() if the registration succeeded, false() otherwise
:)
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

(:~
: Attempts to log a user into the system
:
: @param username
:   The username of the user
: @param password
:   The password of the user
:
: @return
:   true() if the user was successfully authenticated, false() otherwise 
:)
declare function security:login($username as xs:string, $password as xs:string) as xs:boolean {
    xmldb:login($config:db-root-collection, $username, $password)
};

(:~
: Determines if there is a currently logged in user
:
: @return
:   true() if there is a currently logged in user, false() otherwise 
:)
declare function security:is-user() as xs:boolean {
    xmldb:get-user-groups(security:get-username()) = $config:wit-group
};

(:~
: Determines if there is a currently logged in user whom has the manager role
:
: @return
:   true() if there is a currently logged in user with the manager role, false() otherwise 
:)
declare function security:is-manager() as xs:boolean {
  xmldb:get-user-groups(security:get-username()) = $config:wit-manager-group
};

(:~
: Gets the username of the currently logged in user
:
: @return
:   The username of the currently logged in user, if no one is logged in then 'guest' is returned 
:)
declare function security:get-username() as xs:string {
    xmldb:get-current-user()
};

(:~
: Gets the email address of the currently logged in user
:
: @return
:   The email address of the currently logged in user, if no one is logged in then an empty sequence 
:)
declare function security:get-user-email() as xs:string? {
    let $user-collection-path := fn:concat($config:wit-users-collection, "/", security:get-username()) return
        fn:doc(fn:concat($user-collection-path, "/", $security:user-metadata-filename))/user/metadata/email
};

(:~
: Gets the path of the logged in user's personal collection in the db
:
: @return
:   The path of the currently logged in user's collection 
:)
declare function security:get-user-collection-path() as xs:string {
    fn:concat($config:wit-users-collection, "/", security:get-username())
};

(:~
: Gets the personal collection path of the user in the db 
:
: @param username
:   The username of the user for which to get the personal collection path
:
: @return
:   The personal collection path of the user
:)
declare function security:get-user-collection-path($username as xs:string) as xs:string {
    fn:concat($config:wit-users-collection, "/", $username)
};

(:~
: Logout the currently logged in user
:)
declare function security:logout() as empty() {
    let $null := security:login($config:guest-username, $config:guest-password),
    $null := session:clear() return
        ()
};