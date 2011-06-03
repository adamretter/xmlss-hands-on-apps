xquery version "1.0";

module namespace ontology = "http://whatithink.com/xquery/ontology";

declare namespace atom = "http://www.w3.org/2005/Atom";
declare namespace ont = "http://www.xmlsummerschool.com/ontologies/philosophy#";

import module namespace config = "http://whatithink.com/xquery/config" at "config.xqm";

declare variable $ontology:ontology-doc := "philosophy.owl";


declare function ontology:create-from-xml($ontology-upload as element(ontology-upload)) as xs:boolean {
    
    (: decode the base64 uploaded file :)
    let $ontology := util:parse(util:base64-decode($ontology-upload/file)) return
        
        (: overwrite the ontology :)
        let $null := xmldb:store($config:wit-ontology-collection, $ontology:ontology-doc, $ontology) return
            true() 
};

declare function ontology:get-as-atom-categories() as element(atom:category)* {
    for $term in ontology:get()//ont:term return
        <category xmlns="http://www.w3.org/2005/Atom" label="{$term/text()}" term="{$term/text()}"/>
};

(: TODO - declare function ontology:get() as document-node(element(rdf:RDF)):)
declare function ontology:get() as document-node() {
    fn:doc(fn:concat($config:wit-ontology-collection, "/", $ontology:ontology-doc))
};