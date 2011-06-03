xquery version "1.0";

import module namespace request = "http://exist-db.org/xquery/request";
import module namespace transform = "http://exist-db.org/xquery/transform";

import module namespace config = "http://whatithink.com/xquery/config" at "config.xqm";

declare option exist:serialize "media-type=text/html method=xhtml doctype-public=-//W3C//DTD&#160;XHTML&#160;1.1//EN doctype-system=http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd indent=false";

let $session-id := request:get-parameter("bf-session-id", ()),
$model-id := request:get-parameter("xf-model-id", ()),
$instance-id := request:get-parameter("xf-instance-id", ()) return

let $betterform-instance := fn:doc(fn:concat("http://localhost:8080/exist/inspector/", $session-id, "/", $model-id, "/", $instance-id)) return
    <html>
        <head>
            <title>Instance XML</title>
            <link href="scripts/prettify/prettify.css" type="text/css" rel="stylesheet" />
            <script type="text/javascript" src="scripts/prettify/prettify.js"></script> 
        </head>
        <body onload="prettyPrint()">
<pre class="prettyprint" style="white-space: pre-line">{transform:transform($betterform-instance, doc(fn:concat($config:wit-collection, "/format-xml-as-html.xslt")), ())}</pre>
        </body>
    </html>