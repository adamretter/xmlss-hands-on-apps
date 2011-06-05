xquery version "1.0";

module namespace config = "http://whatithink.com/xquery/config";

declare variable $config:admin-username := "admin";
declare variable $config:admin-password := "";

declare variable $config:guest-username := "guest";
declare variable $config:guest-password := "";

(: wit is short for What I Think :)
declare variable $config:wit-group := "whatithink.users";
declare variable $config:wit-manager-group := "dba";

declare variable $config:db-root-collection := "/db";

declare variable $config:wit-collection := fn:concat($config:db-root-collection, "/xmlss/whatithink.com");
declare variable $config:wit-users-collection := fn:concat($config:wit-collection, "/users");
declare variable $config:wit-ontology-collection := fn:concat($config:wit-collection, "/ontology");

declare variable $config:printer-webapp-address := xs:anyURI("http://localhost:9090/");
declare variable $config:printer-webapp-restful-order-uri := xs:anyURI(fn:concat($config:printer-webapp-address, "/order"));
declare variable $config:printer-webapp-restful-order-status-uri := xs:anyURI(fn:concat($config:printer-webapp-restful-order-uri, "/status")); 
