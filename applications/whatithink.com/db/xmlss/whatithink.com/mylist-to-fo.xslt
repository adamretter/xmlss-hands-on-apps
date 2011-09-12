<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:atom="http://www.w3.org/2005/Atom" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" exclude-result-prefixes="xs" version="2.0">
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
        This module converts a users list of atom entries into FO for render to PDF.
        
        @author Adam Retter <adam.retter@googlemail.com>
        @version 201109122029
    -->
    <xsl:param name="logoUri"/>
    <xsl:param name="bgUri"/>
    <xsl:output indent="yes"/>
    <xsl:template match="atom:feed">
        <fo:root font-size="12pt">
            <fo:layout-master-set>
                <fo:simple-page-master master-name="A4" page-width="297mm" page-height="210mm" margin-top="1cm" margin-bottom="1cm" margin-left="1cm" margin-right="1cm">
                    <fo:region-body margin-top="5.2cm" margin-left="1cm" margin-bottom="1cm" margin-right="1cm"/>
                    <fo:region-before extent="4.2cm"/>
                    <fo:region-after extent="1cm"/>
                    <fo:region-start extent="1cm"/>
                    <fo:region-end extent="1cm"/>
                </fo:simple-page-master>
            </fo:layout-master-set>
            <fo:page-sequence master-reference="A4">
                <fo:static-content flow-name="xsl-region-before">
                    <fo:block text-align="center" vertical-align="top">
                        <fo:block background-image="url({$bgUri})" background-repeat="repeat-x">
                            <fo:external-graphic src="url({$logoUri})" content-height="scale-to-fit" content-width="scale-to-fit" scaling="uniform" height="40mm"/>
                            <!-- fo:external-graphic src="url({$logoUri})" content-height="scale-to-fit" content-width="scale-to-fit" scaling="uniform" height="18mm"/ -->
                        </fo:block>
                    </fo:block>
                    <fo:block text-align="left" margin-top="0.2cm" font-size="12pt" border-bottom-width="thin" border-bottom-style="solid" border-bottom-color="black">
                        <xsl:value-of select="/atom:feed/atom:author/atom:name"/>'s List
                    </fo:block>
                </fo:static-content>
                <fo:static-content flow-name="xsl-region-after">
                    <fo:block font-family="verdana" font-size="8pt" color="grey" text-align="center">
                        Page <fo:page-number/>
                    </fo:block>
                </fo:static-content>
                <fo:flow flow-name="xsl-region-body">
                    <xsl:apply-templates select="atom:entry"/>
                </fo:flow>
            </fo:page-sequence>
        </fo:root>
    </xsl:template>
    <xsl:template match="atom:entry">
        <fo:block margin-top="0.25cm">
            <xsl:apply-templates/>
        </fo:block>
    </xsl:template>
    <xsl:template match="atom:title">
        <fo:block font-size="10pt" color="blue" font-weight="bold">
            <xsl:value-of select="."/>
        </fo:block>
    </xsl:template>
    <xsl:template match="atom:summary">
        <fo:block font-size="9pt" font-family="verdana">
            <xsl:value-of select="."/>
        </fo:block>
    </xsl:template>
    <xsl:template match="atom:id"/>
    <xsl:template match="atom:updated"/>
</xsl:stylesheet>