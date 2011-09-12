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

module namespace ontology = "http://whatithink.com/xquery/ontology";

declare namespace atom = "http://www.w3.org/2005/Atom";
declare namespace ont = "http://www.xmlsummerschool.com/ontologies/philosophy#";

import module namespace sm = "http://exist-db.org/xquery/securitymanager";

import module namespace config = "http://whatithink.com/xquery/config" at "config.xqm";

(: document name of the Ontology :)
declare variable $ontology:ontology-doc := "philosophy.owl";

(:~
: Stores a new Ontology into the system
:
: The Ontology is uploaded by an admin
:
: @param ontology-upload
:   The Ontology wrapped in an ontology-upload element,
:   with the following format - 
:       <ontology-upload>
:           <file xsi:type="xsd:base64Binary" filename="" media-type=""/>
:       </ontology-upload>
:
: @return
:   true() if we could store the Ontology, false() otherwise
:)
declare function ontology:create-from-xml($ontology-upload as element(ontology-upload)) as xs:boolean {
    
    (: decode the base64 uploaded file :)
    let $ontology := util:parse(util:base64-decode($ontology-upload/file)) return
        
        (: overwrite the existing Ontology :)
        let $ontology-uri := xmldb:store($config:wit-ontology-collection, $ontology:ontology-doc, $ontology),
        $null := sm:chmod(xs:anyURI($ontology-uri), "rwurwur--") return
            true() 
};

(:~
: Gets the terms from the Ontology as a sequence of atom categorys
:
: @return
:   The sequence of atom categories
:)
declare function ontology:get-as-atom-categories() as element(atom:category)* {
    for $term in ontology:get()//ont:term return
        <category xmlns="http://www.w3.org/2005/Atom" label="{$term/text()}" term="{$term/text()}"/>
};

(:~
: Get the Ontology document
:
: @return
:   The Ontology
:)
declare function ontology:get() as document-node() {
    fn:doc(fn:concat($config:wit-ontology-collection, "/", $ontology:ontology-doc))
};