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
: This module takes the XML instance from a betterForm XForm
: and transforms it into pretty printed XHTML code for the purpose
: of embedding as an example inside an existing HTML page.
:
: @author Adam Retter <adam.retter@googlemail.com>
: @version 201109122029
:)

xquery version "1.0";

import module namespace request = "http://exist-db.org/xquery/request";
import module namespace transform = "http://exist-db.org/xquery/transform";

import module namespace config = "http://whatithink.com/xquery/config" at "config.xqm";

declare option exist:serialize "media-type=text/html method=xhtml doctype-public=-//W3C//DTD&#160;XHTML&#160;1.1//EN doctype-system=http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd indent=false";

let $session-id := request:get-parameter("bf-session-id", ()),
$model-id := request:get-parameter("xf-model-id", ()),
$instance-id := request:get-parameter("xf-instance-id", ()) return

let $betterform-instance := fn:doc(fn:concat("http://", request:get-server-name(), ":", request:get-server-port(), "/exist/inspector/", $session-id, "/", $model-id, "/", $instance-id)) return
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