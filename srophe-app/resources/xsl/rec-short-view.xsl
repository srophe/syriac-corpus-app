<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:exist="http://exist-db.org" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:x="http://www.w3.org/1999/xhtml" xmlns:saxon="http://saxon.sf.net/" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:local="http://syriaca.org/ns" exclude-result-prefixes="xs t x saxon local exist" version="2.0">

 <!-- ================================================================== 
       Copyright 2015 Syriaca.org
       
       This file is part of the Syriac Reference Portal Places Application.
       
       The Syriac Reference Portal Places Application is free software: 
       you can redistribute it and/or modify it under the terms of the GNU 
       General Public License as published by the Free Software Foundation, 
       either version 3 of the License, or (at your option) any later 
       version.
       
       The Syriac Reference Portal Places Application is distributed in 
       the hope that it will be useful, but WITHOUT ANY WARRANTY; without 
       even the implied warranty of MERCHANTABILITY or FITNESS FOR A 
       PARTICULAR PURPOSE.  See the GNU General Public License for more 
       details.
       
       You should have received a copy of the GNU General Public License
       along with the Syriac Reference Portal Places Application.  If not,
       see (http://www.gnu.org/licenses/).
       
       ================================================================== --> 
 
 <!-- ================================================================== 
       rec-short-view.xsl
       
       This XSLT transforms tei.xml to a concise view, title, type, dates, 
       alternate names and a truncated description.
       
       code by: 
        + Winona Salesky (wsalesky@gmail.com)
          for use with eXist-db
       
       ================================================================== -->
    <xsl:import href="tei2html.xsl"/>
    <xsl:import href="helper-functions.xsl"/>
    <xsl:import href="link-icons.xsl"/>
    <xsl:import href="manuscripts.xsl"/>
    <xsl:import href="citation.xsl"/>
    <xsl:import href="bibliography.xsl"/>
    <xsl:import href="json-uri.xsl"/>
    <xsl:import href="langattr.xsl"/>
    <xsl:import href="collations.xsl"/>
 <!-- =================================================================== -->
 <!-- set output so we get (mostly) indented HTML -->
 <!-- =================================================================== -->
    <xsl:output name="html" encoding="UTF-8" method="xhtml" indent="no"/>

 <!-- =================================================================== -->
 <!--  initialize top-level variables and transform parameters -->
 <!-- =================================================================== -->
    
    <!-- Parameters passed from global.xqm (set in config.xml) default values if params are empty -->
    <xsl:param name="data-root" select="'/db/apps/srophe-data'"/>
    <xsl:param name="app-root" select="'/db/apps/srophe'"/>
    <xsl:param name="nav-base" select="'/db/apps/srophe'"/>
    <xsl:param name="base-uri" select="'/db/apps/srophe'"/>
    <xsl:param name="lang" select="'en'"/>
    <!-- Resource id -->
    <xsl:variable name="resource-id">
        <xsl:choose>
            <xsl:when test="string(/*/@id)">
                <xsl:value-of select="string(/*/@id)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="replace(/descendant::t:idno[@type='URI'][starts-with(.,$base-uri)][1],'/tei','')"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    
 <!-- =================================================================== -->
 <!-- TEMPLATES -->
 <!-- =================================================================== -->


 <!-- ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||| -->
 <!-- |||| Root template matches tei root -->
 <!-- ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||| -->
    <xsl:template match="/">
        <xsl:call-template name="shortview"/>
    </xsl:template>
    <xsl:template name="shortview">
        <xsl:variable name="uri">
            <xsl:choose>
                <xsl:when test="descendant::t:idno[@type='URI'][starts-with(.,$base-uri)]">
                    <xsl:value-of select="replace(descendant::t:idno[@type='URI'][starts-with(.,$base-uri)][1],'/tei','')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="descendant::t:div[1]/@uri"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="ana">
            <xsl:for-each select="descendant::t:titleStmt/t:title[@level='m' or @level='s']">
                <xsl:choose>
                    <xsl:when test=". = 'A Guide to Syriac Authors'">
                        <a href="{$nav-base}/authors/index.html">
                            <img src="{$nav-base}/resources/img/icons-authors-sm.png" alt="A Guide to Syriac Authors"/>author</a>
                    </xsl:when>
                    <xsl:when test=". = 'Qadishe: A Guide to the Syriac Saints'">
                        <a href="{$nav-base}/q/index.html">
                            <img src="{$nav-base}/resources/img/icons-q-sm.png" alt="Qadishe: A Guide to the Syriac Saints"/>saint</a>
                    </xsl:when>
                </xsl:choose>
                <xsl:if test="following-sibling::*/text() = ('A Guide to Syriac Authors','Qadishe: A Guide to the Syriac Saints')">, </xsl:if>
            </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="type" select="descendant::t:place/@type"/>
        <xsl:variable name="en-title">
            <xsl:choose>
                <xsl:when test="descendant::*[contains(@syriaca-tags,'#syriaca-headword')][matches(@xml:lang,'^en')][1]">
                    <xsl:value-of select="string-join(descendant::*[contains(@syriaca-tags,'#syriaca-headword')][matches(@xml:lang,'^en')][1]//text(),' ')"/>
                </xsl:when>
                <xsl:when test="descendant-or-self::t:titleStmt">
                    <xsl:apply-templates select="descendant::t:title[@level='a']"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="descendant-or-self::*[not(self::t:idno)]/text()"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="syr-title">
            <xsl:choose>
                <xsl:when test="descendant::*[contains(@syriaca-tags,'#syriaca-headword')][matches(@xml:lang,'^syr')][1]">
                    <xsl:value-of select="string-join(descendant::*[contains(@syriaca-tags,'#syriaca-headword')][matches(@xml:lang,'^syr')][1]//text(),' ')"/>
                </xsl:when>
                <xsl:when test="descendant::*[contains(@syriaca-tags,'#syriaca-headword')]">[Syriac Not Available]</xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="birth">
            <xsl:if test="$ana != ''">
                <xsl:value-of select="descendant::t:birth/text()"/>
            </xsl:if>
        </xsl:variable>
        <xsl:variable name="death">
            <xsl:if test="$ana != ''">
                <xsl:value-of select="descendant::t:death/text()"/>
            </xsl:if>
        </xsl:variable>
        <xsl:variable name="floruit">
            <xsl:if test="descendant-or-self::t:floruit/text()">
                <xsl:value-of select="concat('active ',descendant-or-self::t:floruit/text())"/>
            </xsl:if>
        </xsl:variable>
        <xsl:variable name="dates">
            <xsl:if test="$birth != ''">
                <xsl:value-of select="$birth"/>
            </xsl:if>
            <xsl:if test="$birth != '' and $death != ''">
                <xsl:text> - </xsl:text>
            </xsl:if>
            <xsl:if test="$death != '' and $birth = ''">
                <xsl:text>d. </xsl:text>
                <xsl:value-of select="$death"/>
            </xsl:if>
            <xsl:if test="$floruit != ''">
                <xsl:if test="$birth != '' or $death != ''">
                    <xsl:text>, </xsl:text>
                </xsl:if>
                <xsl:value-of select="$floruit"/>
            </xsl:if>
        </xsl:variable>    
 
        <!--let $desc := rec:truncate-string($node/descendant::*[starts-with(@xml:id,'abstract')]/descendant-or-self::text())-->
        <div class="results-list">
            <a href="{replace($uri,$base-uri,$nav-base)}">
                <xsl:choose>
                    <xsl:when test="$lang='syr'">
                        <span dir="rtl" lang="syr" xml:lang="syr">
                            <xsl:value-of select="$syr-title"/>
                        </span>
                        <xsl:text> - </xsl:text>
                        <span dir="ltr" lang="en">
                            <xsl:value-of select="$en-title"/>
                            <xsl:if test="$type != ''">
                                <xsl:value-of select="concat('(',$type,')')"/>
                            </xsl:if>
                        </span>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$en-title"/>
                        <xsl:if test="$type != ''">
                            <xsl:value-of select="concat(' (',$type,')')"/>
                        </xsl:if>
                        
                        <xsl:choose>
                            <xsl:when test="$syr-title = '[Syriac Not Available]'">
                                <xsl:text> - </xsl:text>
                                <xsl:text> [Syriac Not Available]</xsl:text>
                            </xsl:when>
                            <xsl:when test="$syr-title != ''">
                                <xsl:text> - </xsl:text>
                                <span dir="rtl" lang="syr" xml:lang="syr">
                                    <xsl:value-of select="$syr-title"/>
                                </span>
                            </xsl:when>
                        </xsl:choose>
                    </xsl:otherwise>
                </xsl:choose>
            </a>
            <xsl:if test="$ana != ''">
                <span class="results-list-desc type" dir="ltr" lang="en">
                    <xsl:text> (</xsl:text>
                    <xsl:sequence select="$ana"/>
                    <xsl:if test="$dates != ''">
                        <xsl:text>, </xsl:text>
                        <xsl:value-of select="$dates"/>
                    </xsl:if>
                    <xsl:text>) </xsl:text>
                </span>
            </xsl:if>
            <xsl:if test="descendant::t:person/t:persName[not(contains(@syriaca-tags,'#syriaca-headword'))][not(matches(@xml:lang,('^syr|^ar|^en-xsrp1')))] | descendant::t:place/t:placeName[not(contains(@syriaca-tags,'#syriaca-headword'))][not(matches(@xml:lang,('^syr|^ar|^en-xsrp1')))]">
                <span class="results-list-desc names" dir="ltr" lang="en">
                    <xsl:text>Names: </xsl:text>
                    <xsl:for-each select="descendant::t:person/t:persName[not(contains(@syriaca-tags,'#syriaca-headword'))][not(matches(@xml:lang,('^syr|^ar|^en-xsrp1')))] | descendant::t:place/t:placeName[not(contains(@syriaca-tags,'#syriaca-headword'))][not(matches(@xml:lang,('^syr|^ar|^en-xsrp1')))]">
                        <xsl:if test="position() &lt; 8">
                            <span class="pers-label badge">
                                <xsl:apply-templates/>
                            </span>
                        </xsl:if>
                    </xsl:for-each>
                </span>
            </xsl:if>
            <xsl:if test="descendant::*[starts-with(@xml:id,'abstract')]">
                <span class="results-list-desc desc" dir="ltr" lang="en">
                    <xsl:variable name="string" select="string-join(descendant::*[starts-with(@xml:id,'abstract')]/descendant::text(),' ')"/>
                    <xsl:variable name="last-words" select="tokenize($string, '\W+')[position() = 14]"/>
                    <xsl:choose>
                        <xsl:when test="count(tokenize($string, '\W+')[. != '']) gt 12">
                            <xsl:value-of select="concat(substring-before($string, $last-words),'...')"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$string"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </span>
            </xsl:if>
            <xsl:if test="//*:match">
                <span class="results-list-desc srp-label">Matches:</span>
                <xsl:for-each select="//*:match">
                    <xsl:if test="position() lt 8">
                        <span class="results-list-desc container">
                            <span class="srp-label">
                                <xsl:value-of select="concat(position(),'. (', name(parent::*[1]),') ')"/>
                            </span>
                            <xsl:apply-templates select="parent::*[1]" mode="plain"/>
                        </span>
                    </xsl:if>
                    <xsl:if test="position() = 8">
                        <span class="results-list-desc container">more ...</span>
                    </xsl:if>
                </xsl:for-each>
            </xsl:if>
            <span class="results-list-desc uri">
                <span class="srp-label">URI: </span>
                <a href="{replace($uri,$base-uri,$nav-base)}">
                    <xsl:value-of select="$uri"/>
                </a>
            </span>
        </div>
    </xsl:template>
    <xsl:template match="*:match">
        <span class="match" style="background-color:yellow; padding:0 .25em;">
            <xsl:value-of select="."/>
        </span>
    </xsl:template>
</xsl:stylesheet>