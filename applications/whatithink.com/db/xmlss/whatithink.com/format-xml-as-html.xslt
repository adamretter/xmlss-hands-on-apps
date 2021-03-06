<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0">
    <!--
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
    -->
    
    <!--
        This module converts an XML document into XHTML for display purposes
        
        @author Adam Retter <adam.retter@googlemail.com>
        @version 201109122029
    -->
    <xsl:output method="xhtml" version="1.1" media-type="text/html" encoding="UTF-8" indent="yes" omit-xml-declaration="no"/>
    <xsl:include href="xml-to-html.xslt"/>
    <xsl:template match="/">
        <xsl:apply-templates select="." mode="xml-to-html"/>
    </xsl:template>
</xsl:stylesheet>