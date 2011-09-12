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
        This template does basic pretty printing of xml into html for display
        inside another html page
        
        @author Adam Retter <adam.retter@googlemail.com>
        @version 201109122029
    -->
    <xsl:template match="node()" mode="xml-to-html">
        <xsl:param name="depth" select="0"/>
        <xsl:param name="default-namespace" select="''"/>
        <xsl:choose>
            <xsl:when test=". instance of element()">
                <xsl:for-each select="1 to $depth">
                    <xsl:text>	</xsl:text>
                </xsl:for-each>
                <xsl:value-of select="concat('&lt;', node-name(.),  if(namespace-uri() ne '' and namespace-uri() ne $default-namespace)then(concat(' xmlns=&#34;', namespace-uri(), '&#34;'))else(), if(@*)then(' ')else(), string-join(for $attr in @* return concat(node-name($attr), '=&#34;', $attr, '&#34;'), ' '), '&gt;', if(element())then('&#xA;')else(''))"/>
                <xsl:apply-templates select="node()" mode="xml-to-html">
                    <xsl:with-param name="depth" select="if(./element())then($depth + 1)else($depth)"/>
                    <xsl:with-param name="default-namespace" select="namespace-uri()"/>
                </xsl:apply-templates>
                <xsl:value-of select="concat('&lt;/', node-name(.), '&gt;&#xA;')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:apply-templates select="node()" mode="xml-to-html"/>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>