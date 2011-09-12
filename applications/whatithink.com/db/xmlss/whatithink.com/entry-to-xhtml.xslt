<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:atom="http://www.w3.org/2005/Atom" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:saxon="http://saxon.sf.net/" xmlns:xs="http://www.w3.org/2001/XMLSchema" version="2.0" exclude-result-prefixes="#all">
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
        This module converts an Atom Entry into XHTML for display purposes
        
        @author Adam Retter <adam.retter@googlemail.com>
        @version 201109122029
    -->
    <xsl:param name="is-logged-in" as="xs:string" select="false"/>
    <xsl:param name="entry-uri"/>
    <xsl:output method="xhtml" version="1.1" media-type="text/html" encoding="UTF-8" indent="yes" omit-xml-declaration="no"/>
    <xsl:include href="xml-to-html.xslt"/>
    <xsl:template match="atom:entry">
        <div>
            <div id="content">
                <xsl:apply-templates select="*[local-name(.) != 'category'][local-name(.) != 'updated']"/>
                <div id="entryTerms">
                    <h3>Terms</h3>
                    <ul>
                        <xsl:apply-templates select="atom:category"/>
                    </ul>
                </div>
                <xsl:apply-templates select="atom:updated"/>
                <xsl:if test="$is-logged-in eq 'true'">
                    <script type="text/javascript">
                        <![CDATA[
                            $(document).ready(function(){
                                prettyPrint();
                            
                                $('#xmlViewButton').click(function(){
                                    $('#xmlView').show();
                                });
                            });
                         ]]></script>
                    <div class="centeredText">
                        <a id="xmlViewButton" href="#xmlViewAnchor">View XML</a>
                    </div>
                    <a name="xmlViewAnchor"/>
                    <pre id="xmlView" class="prettyprint" style="display: none;">
                        <xsl:apply-templates select="." mode="xml-to-html"/>
                    </pre>
                </xsl:if>
            </div>
            <div id="contentFooter">
                <a href="entry/browse">Browse</a> | <a href="./">Home</a>
            </div>
        </div>
    </xsl:template>
    <xsl:template match="atom:id"/>
    <xsl:template match="atom:title">
        <h4>
            <xsl:value-of select="."/>
        </h4>
    </xsl:template>
    <xsl:template match="atom:link">
        <div>
            <span class="solidText">More information:</span>&#160;<a href="{@href}">
                <xsl:value-of select="@href"/>
            </a>
        </div>
    </xsl:template>
    <xsl:template match="atom:summary">
        <div id="entryContent">
            <!-- xsl:value-of select="saxon:parse(concat('<div>', ., '</div>'))"/ -->
            <pre>
                <xsl:value-of select="."/>
            </pre>
        </div>
    </xsl:template>
    <xsl:template match="atom:category">
        <li>
            <xsl:value-of select="@term"/>
        </li>
    </xsl:template>
    <xsl:template match="atom:updated">
        <div id="entryCreated" class="stressedText">
            <span class="solidText">Published:</span>&#160;
            <xsl:value-of select="format-dateTime(., '[h]:[m01] [PN] [FNn] [D1o] [MNn], [Y]', 'en', (), ())"/>
        </div>
    </xsl:template>
</xsl:stylesheet>