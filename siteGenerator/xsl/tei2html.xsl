<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:x="http://www.w3.org/1999/xhtml" 
    xmlns:srophe="https://srophe.app" xmlns:saxon="http://saxon.sf.net/" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:local="http://syriaca.org/ns" exclude-result-prefixes="xs t x saxon local" version="2.0">

 <!-- ================================================================== 
       Copyright 2013 New York University  
       
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
       tei2html.xsl
       
       This XSLT transforms tei.xml to html.
       
       parameters:
            
        
       code by: 
        + Winona Salesky (wsalesky@gmail.com)
          for use with eXist-db
        + Tom Elliott (http://www.paregorios.org) 
          for the Institute for the Study of the Ancient World, New York
          University, under contract to Vanderbilt University for the
          NEH-funded Syriac Reference Portal project.
          
       funding provided by:
        + National Endowment for the Humanities (http://www.neh.gov). Any 
          views, findings, conclusions, or recommendations expressed in 
          this code do not necessarily reflect those of the National 
          Endowment for the Humanities.
       
       ================================================================== -->
 <!-- =================================================================== -->
 <!-- import component stylesheets for HTML page portions -->
 <!-- =================================================================== -->
    <xsl:import href="citation.xsl"/>
    <xsl:import href="bibliography.xsl"/>
    <!-- Calls Srophe specific display XSLT, you can add your own or edit this one. -->
    <xsl:import href="core.xsl"/>
    <!-- Helper functions and templates -->
    <xsl:import href="helper-functions.xsl"/>
    <xsl:import href="collations.xsl"/>
    
 <!-- =================================================================== -->
 <!-- set output so we get (mostly) indented HTML -->
 <!-- =================================================================== -->
    <xsl:output name="html" encoding="UTF-8" method="xhtml" indent="no" omit-xml-declaration="yes"/>

 <!-- =================================================================== -->
 <!--  initialize top-level variables and transform parameters -->
 <!-- =================================================================== -->
    
    <!-- Parameters passed from global.xqm (set in config.xml) default values if params are empty -->
    <!-- WS:Note, only used in bibliography.xsl -->
    <xsl:param name="data-root" select="'/db/apps/srophe-data'"/>
    <!-- eXist app root for app deployment-->
    <xsl:param name="app-root" select="'/db/apps/srophe'"/>
    <!-- Root of app for building dynamic links. Default is eXist app root -->
    <xsl:param name="nav-base" select="'/exist/apps/srophe'"/>
    <!-- Base URI for identifiers in app data -->
    <xsl:param name="base-uri" select="'http://syriaca.org'"/>
    <!-- Add a collection parameter to make it possible to switch XSLT stylesheets, or views via collections -->
    <xsl:param name="collection"/>
    <!-- Hard coded values-->
    <xsl:param name="normalization">NFKC</xsl:param>
    <!-- Repo-config passed from staticHTML-->
    <xsl:param name="config"/>
    <xsl:param name="idno"/>
    <xsl:param name="repository-title"/>
    <xsl:param name="collection-title"/>
    
    <!-- Resource id -->
    <xsl:variable name="resource-id">
        <xsl:choose>
            <xsl:when test="$idno != ''">
                <xsl:value-of select="$idno"/>
            </xsl:when>
            <xsl:when test="string(/*/@id)">
                <xsl:value-of select="string(/*/@id)"/>
            </xsl:when>
            <xsl:when test="/descendant::t:publicationStmt/t:idno[@type='URI'][starts-with(.,$base-uri)]">
                <xsl:value-of select="replace(replace(/descendant::t:publicationStmt[1]/t:idno[@type='URI'][starts-with(.,$base-uri)][1],'/tei',''),'/source','')"/>
            </xsl:when>
            <xsl:when test="/descendant::t:publicationStmt/t:idno[@type='URI']">
                <xsl:value-of select="replace(replace(/descendant::t:publicationStmt[1]/t:idno[@type='URI'][1],'/tei',''),'/source','')"/>
            </xsl:when>
            <xsl:when test="/descendant::t:idno[@type='URI'][starts-with(.,$base-uri)]">
                <xsl:value-of select="replace(replace(/descendant::t:idno[@type='URI'][starts-with(.,$base-uri)][1],'/tei',''),'/source','')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="concat($base-uri,'/0000')"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- Resource title -->
    <xsl:variable name="resource-title">
        <xsl:apply-templates select="/descendant-or-self::t:titleStmt/t:title[1]"/>
    </xsl:variable>
 
    <!-- =================================================================== -->
    <!-- Templates -->
    <!-- =================================================================== -->
    <!-- Root -->
    <xsl:template match="/">
        <xsl:apply-templates/>
    </xsl:template>
    
    <!-- =================================================================== -->
    <!--  Custom Syriaca.org templates, remove overwrite or edit to change the display -->
    <!-- =================================================================== -->
    <!-- A -->
    <xsl:template name="aboutEntry">
        <div id="about">
            <xsl:choose>
                <xsl:when test="contains($resource-id,'/bibl/')">
                    <h3>About this Online Entry</h3>
                    <xsl:apply-templates select="descendant-or-self::t:teiHeader/t:fileDesc/t:titleStmt" mode="about-bibl"/>
                </xsl:when>
                <xsl:otherwise>
                    <h3>About this Entry</h3>
                    <xsl:apply-templates select="descendant-or-self::t:teiHeader/t:fileDesc/t:titleStmt" mode="about"/>
                </xsl:otherwise>
            </xsl:choose>
        </div>
    </xsl:template>
    <!-- Named template for bibl about -->
    <xsl:template match="t:srophe-about">
        <div id="citation-note" class="content-block">
            <xsl:call-template name="aboutEntry"/>
        </div>
    </xsl:template>
    <xsl:template match="t:affiliation">
        <span class="tei-affiliation">
            <xsl:apply-templates/>
        </span>
    </xsl:template>
    
    <!-- B -->
    <!-- suppress bibl in title mode -->
    <xsl:template match="t:bibl" mode="title"/>
    <xsl:template match="t:bibl">
        <xsl:choose>
            <xsl:when test="@type !=('lawd:ConceptualWork','lawd:Citation')">
                <li>
                    <xsl:if test="descendant::t:lang/text()">
                        <span class="tei-label">
                            <xsl:value-of select="local:expand-lang(descendant::t:lang[1]/text(),'lawd:Edition')"/>:
                        </span>
                    </xsl:if>
                    <span>
                        <xsl:sequence select="local:attributes(.)"/>
                        <xsl:if test="t:idno">
                            <span class="footnote idno">
                                <xsl:value-of select="t:idno"/>
                            </span>
                        </xsl:if>
                        <xsl:call-template name="footnote"/>
                        <xsl:if test="t:listRelation/t:relation">
                            <xsl:variable name="parent" select="/"/>
                            <xsl:variable name="bibl-type" select="local:translate-label(string(@type),0)"/>
                            <xsl:for-each select="t:listRelation/t:relation[not(@ref='lawd:embodies')]">
                                <!-- List all bibs grouped by type to get correct position for constructed relationship sentance. -->
                                <xsl:variable name="all-bibs">
                                    <bibs xmlns="http://www.tei-c.org/ns/1.0">
                                        <xsl:for-each-group select="ancestor::t:bibl[@type='lawd:ConceptualWork']/t:bibl" group-by="@type">
                                            <bibList>
                                                <xsl:for-each select="current-group()">
                                                    <bibl bibid="{@xml:id}" position="{position()}" type="{local:translate-label(string(current-grouping-key()),count(current-group()))}" ref="{string-join(child::t:ptr[1]/@target,' ')}"/>
                                                </xsl:for-each>
                                            </bibList>
                                        </xsl:for-each-group>
                                    </bibs>
                                </xsl:variable>
                                <!-- Get related bibs based on @passive -->
                                <xsl:variable name="bibl-rel">
                                    <xsl:choose>
                                        <xsl:when test="@ref='lawd:hasCitation'">
                                            <bib-relations xmlns="http://www.tei-c.org/ns/1.0">
                                                <xsl:for-each select="tokenize(@active,' ')">
                                                    <xsl:choose>
                                                        <xsl:when test="contains(.,'#')">
                                                            <xsl:variable name="bibl-id" select="replace(.,'#','')"/>
                                                            <xsl:for-each select="$all-bibs/descendant::t:bibl[@bibid = $bibl-id]">
                                                                <xsl:copy-of select="."/>
                                                            </xsl:for-each>
                                                        </xsl:when>
                                                        <xsl:otherwise>
                                                            <xsl:variable name="bibl-id" select="."/>
                                                            <xsl:for-each select="$all-bibs/descendant::t:bibl[@ref = $bibl-id]">
                                                                <xsl:copy-of select="."/>
                                                            </xsl:for-each>    
                                                        </xsl:otherwise>
                                                    </xsl:choose>
                                                </xsl:for-each>
                                            </bib-relations>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <bib-relations xmlns="http://www.tei-c.org/ns/1.0">
                                                <xsl:for-each select="tokenize(@passive,' ')">
                                                    <xsl:choose>
                                                        <xsl:when test="contains(.,'#')">
                                                            <xsl:variable name="bibl-id" select="replace(.,'#','')"/>
                                                            <xsl:for-each select="$all-bibs/descendant::t:bibl[@bibid = $bibl-id]">
                                                                <xsl:copy-of select="."/>
                                                            </xsl:for-each>
                                                        </xsl:when>
                                                        <xsl:otherwise>
                                                            <xsl:variable name="bibl-id" select="."/>
                                                            <xsl:for-each select="$all-bibs/descendant::t:bibl[@ref = $bibl-id]">
                                                                <xsl:copy-of select="."/>
                                                            </xsl:for-each>   
                                                        </xsl:otherwise>
                                                    </xsl:choose>
                                                </xsl:for-each>
                                            </bib-relations>                                            
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:variable>
                                <!-- Compile sentance -->
                                <xsl:text> (</xsl:text>
                                <xsl:value-of select="$bibl-type"/>
                                <xsl:choose>
                                    <xsl:when test="@ref='lawd:hasCitation'">
                                        <xsl:text> cites </xsl:text>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:text> based on  </xsl:text>
                                    </xsl:otherwise>
                                </xsl:choose>
                                <xsl:for-each-group select="$bibl-rel/descendant-or-self::t:bibl" group-by="@type">
                                    <xsl:copy-of select="current-group()"/>
                                    <xsl:if test="current-grouping-key() != 'ref'">
                                        <xsl:value-of select="current-grouping-key()"/>
                                    </xsl:if>
                                    <xsl:for-each select="current-group()">
                                        <xsl:text> </xsl:text>
                                        <xsl:value-of select="string(@position)"/>
                                        <xsl:if test="not(position()=last())">
                                            <xsl:text>, </xsl:text>
                                        </xsl:if>
                                    </xsl:for-each>
                                </xsl:for-each-group>
                                <xsl:text>.)</xsl:text>
                                <xsl:if test="t:desc">
                                    <xsl:text> [</xsl:text>
                                    <xsl:value-of select="t:desc"/>
                                    <xsl:text>]</xsl:text>
                                </xsl:if>
                            </xsl:for-each>
                        </xsl:if>
                    </span>
                </li>
            </xsl:when>
            <xsl:when test="parent::t:note">
                <xsl:choose>
                    <xsl:when test="t:ptr[contains(@target,'/work/')]">
                        <a href="{t:ptr/@target}">
                            <xsl:apply-templates mode="inline"/>
                        </a>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="footnote"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="child::*">
                <xsl:apply-templates mode="footnote"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!-- suppress biblScope in title mode -->
    <xsl:template match="t:biblScope"/>
    <xsl:template match="preferredCitation">
        <xsl:apply-templates select="." mode="bibliography"/>.
    </xsl:template>
    <xsl:template match="t:biblStruct">
        <xsl:choose>
            <xsl:when test="parent::t:body">
                <div class="content-block preferred-citation">
                    <h2>Preferred Citation</h2>
                    <div class="indent citation">
                        <xsl:apply-templates select="self::*" mode="bibliography"/>.
                    </div>
                </div>
                <h3>Full Citation Information</h3>
                <div class="section indent">
                    <h4>Permanent Identifiers</h4>
                    <div class="indent">
                        <xsl:apply-templates select="descendant::t:idno" mode="full"/>
                    </div>
                    <bdi>
                    <xsl:apply-templates mode="full"/>
                    </bdi>
                </div>
                <div class="info-btns">  
                    <xsl:variable name="status" select="string(/descendant-or-self::t:revisionDesc/@status)"/>
                    <xsl:if test="$status != ''">
                        <span class="rec-status {$status} btn btn-info">Status: <xsl:value-of select="$status"/></span>    
                    </xsl:if>
                    <!-- Button trigger corrections email modal -->
                    <button class="btn btn-info" data-toggle="modal" data-target="#feedback">Corrections/Additions?</button> 
                    <a href="#" class="btn btn-info" data-toggle="modal" data-target="#selection" data-ref="../documentation/faq.html" id="showSection">
                        Is this record complete?
                    </a>
                </div>
            </xsl:when>
            <xsl:otherwise>
                <span class="section indent">
                    <xsl:apply-templates mode="footnote"/>
                </span>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="t:body">
        <div class="body">
            <xsl:sequence select="local:attributes(.)"/>
            <div class="section" style="display:block;">
                <xsl:apply-templates/>
            </div>
            <xsl:if test="//t:note[@place='foot']">
                <div class="footnotes" lang="en">
                    <h2>Footnotes</h2>
                    <bdi>
                        <xsl:apply-templates select="//t:note[@place='foot']" mode="footnote"/>
                    </bdi>
                </div>    
            </xsl:if>
        </div>
    </xsl:template>
    <!-- C -->
    <xsl:template name="citationInfo">
        <xsl:param name="idno"/>
        <div class="citationinfo">
            <h3>How to Cite This Entry</h3>
            <div id="citation-note" class="content-block indent">
                <xsl:apply-templates select="descendant-or-self::t:teiHeader/t:fileDesc/t:titleStmt" mode="cite-foot"/>
                <div class="collapse" id="showcit">
                    <div id="citation-bibliography">
                        <h4>Bibliography:</h4>
                        <xsl:apply-templates select="descendant-or-self::t:teiHeader/t:fileDesc/t:titleStmt" mode="cite-biblist"/>
                    </div>
                    <xsl:call-template name="aboutEntry"/>
                    <div id="license">
                        <h3>Copyright and License for Reuse</h3>
                        <div>
                            <xsl:text>Except otherwise noted, this page is © </xsl:text>
                            <xsl:choose>
                                <xsl:when test="descendant-or-self::t:teiHeader/t:fileDesc/t:publicationStmt/t:date[1]/text() castable as xs:date">
                                    <xsl:value-of select="format-date(xs:date(//t:teiHeader/t:fileDesc/t:publicationStmt/t:date[1]), '[Y]')"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="descendant-or-self::t:teiHeader/t:fileDesc/t:publicationStmt/t:date[1]"/>
                                </xsl:otherwise>
                            </xsl:choose>.
                        </div>
                        <xsl:apply-templates select="descendant-or-self::t:teiHeader/t:fileDesc/t:publicationStmt/t:availability/t:licence"/>
                    </div>
                </div>
                <a class="togglelink pull-right btn-link" data-toggle="collapse" data-target="#showcit" data-text-swap="Hide citation">Show full citation information...</a>
            </div>
        </div>
    </xsl:template>
    <xsl:template match="t:choice" mode="#all">
        <xsl:apply-templates/>
    </xsl:template>
    
    <!-- D  -->
    <xsl:template match="t:div | t:div1 | t:div2 | t:div3 | t:div4 | t:div5">
        <xsl:param name="parentID"/>
        <xsl:variable name="currentid">
            <xsl:choose>
                <xsl:when test="$parentID">
                    <xsl:value-of select="$parentID"/>
                </xsl:when>
                <xsl:when test="@n">
                    <xsl:value-of select="concat('id','.',@n)"/>
                </xsl:when>
                <xsl:when test="@xml:id">
                    <xsl:value-of select="concat('id','.',@xml:id)"/>
                </xsl:when>
            </xsl:choose>
        </xsl:variable> 
        <div class="{concat('tei-',name(.))}{if(@unit) then concat(' tei-',@unit) else ()} {if(@type) then concat(' tei-',@type) else ()}">
            <xsl:if test="$currentid != ''">
                <xsl:attribute name="id">
                    <xsl:choose>
                        <xsl:when test="child::t:head">
                            <xsl:value-of select="concat('Head-',$currentid)"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$currentid"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:attribute>
            </xsl:if>
            <xsl:choose>
                <xsl:when test="@lang">
                    <xsl:sequence select="local:attributes(.)"/>
                </xsl:when>
                <xsl:when test="ancestor-or-self::*[@xml:lang][1]/@xml:lang">
                    <xsl:attribute name="lang">
                        <xsl:value-of select="ancestor-or-self::*[@xml:lang][1]/@xml:lang"/>
                    </xsl:attribute>                    
                </xsl:when>
                <xsl:when test="@type='title' or @type='ab'">
                    <xsl:choose>
                        <xsl:when test="@xml:lang">
                            <xsl:sequence select="local:attributes(.)"/>
                        </xsl:when>
                        <xsl:when test="child::*[1]/@xml:lang">
                            <xsl:copy-of select="child::*[1]/@xml:lang"/>
                            <xsl:attribute name="lang">
                                <xsl:value-of select="child::*[1]/@xml:lang"/>    
                            </xsl:attribute>
                        </xsl:when>
                    </xsl:choose>
                </xsl:when>
                <xsl:otherwise/>
            </xsl:choose>
            <xsl:if test="@n">
                <xsl:choose>
                    <xsl:when test="child::t:head">
                        <span id="{$currentid}">
                            <xsl:if test="@n != child::t:head/text()">
                                <xsl:attribute name="class">text-number</xsl:attribute>
                                <xsl:value-of select="@n"/>
                            </xsl:if>
                        </span>
                    </xsl:when>
                    <xsl:otherwise>
                        <span class="text-number badge">
                            <xsl:value-of select="@n"/>
                        </span>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:if>
            <xsl:choose>
                <xsl:when test="@type='footnotes'">
                    <div id="sources">
                        <xsl:apply-templates select="t:head"/>
                        <ul>
                            <xsl:apply-templates select="t:note" mode="footnote"/>
                        </ul>                        
                    </div>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates>
                        <xsl:with-param name="parentID" select="$currentid"/>
                    </xsl:apply-templates>                    
                </xsl:otherwise>
            </xsl:choose>
        </div>
    </xsl:template>
    <xsl:template match="t:desc | t:label" mode="plain">
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="t:label">
        <label>
            <xsl:if test="@type">
                <xsl:attribute name="class">
                    <xsl:value-of select="@type"/>
                </xsl:attribute>
            </xsl:if>
            <xsl:sequence select="local:attributes(.)"/>
            <xsl:call-template name="rend"/>
        </label>
    </xsl:template>
    
    <!-- E -->
    <xsl:template match="t:event">
        <!-- There are several desc templates, this 'plain' mode ouputs all the child elements with no p or li tags -->
        <xsl:apply-templates select="child::*" mode="plain"/>
        <!-- Adds dates if available -->
        <xsl:text> (</xsl:text>
        <xsl:sequence select="local:do-dates(.)"/>
        <xsl:text>)</xsl:text>
        <!-- Adds footnotes if available -->
        <xsl:if test="@source">
            <xsl:sequence select="local:add-footnotes(@source,ancestor::t:*[@xml:lang][1])"/>
        </xsl:if>
    </xsl:template>
    <xsl:template match="t:event" mode="event">
        <li>
            <!-- There are several desc templates, this 'plain' mode ouputs all the child elements with no p or li tags -->
            <xsl:apply-templates select="child::*" mode="plain"/>
            <!-- Adds dates if available -->
            <xsl:text> (</xsl:text>
            <xsl:sequence select="local:do-dates(.)"/>
            <xsl:text>)</xsl:text>
            <!-- Adds footnotes if available -->
            <xsl:if test="@source">
                <xsl:sequence select="local:add-footnotes(@source,ancestor::t:*[@xml:lang][1])"/>
            </xsl:if>
        </li>
    </xsl:template>
    
    <!-- F -->
    <xsl:template match="t:foreign">
        <xsl:choose>
            <xsl:when test="starts-with(@xml:lang,'syr') or starts-with(@xml:lang,'ar')">
                <span lang="{@xml:lang}" dir="rtl">
                    <xsl:value-of select="."/>
                </span>
            </xsl:when>
            <xsl:otherwise>
                <span lang="{@xml:lang}">
                    <xsl:value-of select="."/>
                </span>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- H -->
    <xsl:template match="t:head">
        <xsl:choose>
            <xsl:when test="parent::t:div1">
                <h2 class="tei-head {if(parent::*[1]/@type) then concat(' tei-',parent::*[1]/@type) else ()}">
                    <xsl:sequence select="local:attributes(.)"/>
                    <xsl:apply-templates/>
                </h2>
            </xsl:when>
            <xsl:when test="parent::t:div2">
                <h3 class="tei-head {if(parent::*[1]/@type) then concat(' tei-',parent::*[1]/@type) else ()}">
                    <xsl:sequence select="local:attributes(.)"/>
                    <xsl:apply-templates/>
                </h3>
            </xsl:when>
            <xsl:when test="parent::t:div and parent::t:div/parent::t:body">
                <h3 class="tei-head {if(parent::*[1]/@type) then concat(' tei-',parent::*[1]/@type) else ()}">
                    <xsl:sequence select="local:attributes(.)"/>
                    <xsl:apply-templates/>
                </h3>
            </xsl:when>
            <xsl:otherwise>
                <span class="{concat('tei-',name(parent::*[1]))} {if(parent::*[1]/@type) then concat(' tei-',parent::*[1]/@type) else ()} tei-head">
                    <xsl:sequence select="local:attributes(.)"/>
                    <xsl:apply-templates/>
                </span>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- I -->
    <xsl:template name="id">
        <xsl:choose>
            <xsl:when test="@xml:id">
                <xsl:attribute name="id">
                    <xsl:value-of select="@xml:id"/>
                </xsl:attribute>
            </xsl:when>
            <xsl:when test="@n">
                <xsl:attribute name="id">
                    <xsl:value-of select="@n"/>
                </xsl:attribute>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    
    <!-- L -->
    <xsl:template match="t:location">
        <xsl:choose>
            <xsl:when test=".[@type='geopolitical' or @type='relative']">
                <li>
                    <xsl:choose>
                        <xsl:when test="@subtype='quote'">"<xsl:apply-templates/>"</xsl:when>
                        <xsl:otherwise><xsl:apply-templates/></xsl:otherwise>
                    </xsl:choose>
                    <xsl:sequence select="local:add-footnotes(@source,.)"/>
                </li>
            </xsl:when>
            <xsl:when test="@type='nested'">
                <li>Within 
                    <xsl:for-each select="t:*">
                        <xsl:apply-templates select="."/>
                        <xsl:if test="following-sibling::t:*">
                            <xsl:text>, </xsl:text>
                        </xsl:if>
                    </xsl:for-each>
                    <xsl:text>.</xsl:text>
                    <xsl:sequence select="local:add-footnotes(@source,.)"/>
                </li>
            </xsl:when>
            <xsl:when test=".[@type='gps' and t:geo]">
                <li>Coordinates 
                    <xsl:if test="@subtype != ''">
                        <xsl:value-of select="concat(' (',@subtype,')')"/>
                    </xsl:if>: 
                    <ul class="unstyled offset1">
                        <li>
                            <xsl:value-of select="concat('Lat. ',tokenize(t:geo,' ')[1],'°')"/>
                            <xsl:text> </xsl:text>
                            <xsl:value-of select="concat('Long. ',tokenize(t:geo,' ')[2],'°')"/>
                            <xsl:sequence select="local:add-footnotes(@source,.)"/>
                        </li>
                    </ul>
                </li>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    <xsl:template name="link-icons-list">
        <xsl:param name="title"/>
        <xsl:if test="descendant::t:idno[@type='URI'][not(starts-with(.,$base-uri))]">
            <div id="see-also" class="see-also content-block">
                <h3>See Also</h3>
                <ul>
                    <xsl:for-each select="//t:idno[contains(.,'csc.org.il')]">
                        <li>
                            <a href="{normalize-space(.)}"> "
                                <xsl:value-of select="substring-before(substring-after(normalize-space(.),'sK='),'&amp;sT=')"/>" in the Comprehensive Bibliography on Syriac Christianity</a>
                        </li>
                    </xsl:for-each>
                    <!-- WorldCat Identities -->
                    <xsl:for-each select="//t:idno[contains(.,'http://worldcat.org/identities')]">
                        <li>
                            <a href="{normalize-space(.)}"> "<xsl:value-of select="substring-after(.,'http://worldcat.org/identities/')"/>" in WorldCat Identities</a>
                        </li>
                    </xsl:for-each>
                    <!-- VIAF -->
                    <xsl:for-each select="//t:idno[contains(.,'http://viaf.org/')]">
                        <li>
                            <a href="{normalize-space(.)}">VIAF</a>
                        </li>
                    </xsl:for-each>
                    <!-- Pleiades links -->
                    <xsl:for-each select="//t:idno[contains(.,'pleiades')]">
                        <li>
                            <a href="{normalize-space(.)}">
                                <img src="/resources/images/circle-pi-25.png" alt="Image of the Greek letter pi in blue; small icon of the Pleiades project" title="click to view {$title} in Pleiades"/> View in Pleiades</a>
                        </li>
                    </xsl:for-each>
                    <!-- Google map links -->
                    <xsl:for-each select="//descendant::t:location[@type='gps']/t:geo">
                        <li>
                            <xsl:variable name="geoRef">
                                <xsl:variable name="coords" select="tokenize(normalize-space(.), '\s+')"/>
                                <xsl:value-of select="$coords[1]"/>
                                <xsl:text>, </xsl:text>
                                <xsl:value-of select="$coords[2]"/>
                            </xsl:variable>
                            <a href="https://maps.google.com/maps?q={$geoRef}+(name)&amp;z=10&amp;ll={$geoRef}">
                                <img src="/resources/images/gmaps-25.png" alt="The Google Maps icon" title="click to view {$title} on Google Maps"/> View in Google Maps
                            </a>
                        </li>
                    </xsl:for-each>
                    
                    <!-- Wikipedia links -->
                    <xsl:for-each select="//t:idno[contains(.,'wikipedia')]">
                        <xsl:variable name="get-title">
                            <xsl:value-of select="replace(tokenize(.,'/')[last()],'_',' ')"/>
                        </xsl:variable>
                        <li>
                            <a href="{.}">
                                <img src="/resources/images/Wikipedia-25.png" alt="The Wikipedia icon" title="click to view {$get-title} in Wikipedia"/> "<xsl:value-of select="$get-title"/>" in Wikipedia</a>
                        </li>
                    </xsl:for-each>
                </ul>
            </div>            
        </xsl:if>
    </xsl:template>
    <xsl:template match="t:listBibl">
        <ul class="listBibl">
            <xsl:for-each select="t:bibl">
                <li>
                    <xsl:if test="@xml:id">
                        <xsl:attribute name="id">
                            <xsl:value-of select="@xml:id"/>
                        </xsl:attribute>
                    </xsl:if>
                    <xsl:variable name="bibl-text">
                        <xsl:apply-templates mode="biblist" xml:space="preserve"/>     
                    </xsl:variable>
                    <xsl:sequence select="$bibl-text"/>
                    <xsl:if test="not(ends-with(string-join($bibl-text//text(),''),'.'))">
                        <xsl:text>.</xsl:text>
                    </xsl:if>
                </li>
            </xsl:for-each>
        </ul>
    </xsl:template>
    <xsl:template match="t:listBibl[parent::t:note]">
        <xsl:choose>
            <xsl:when test="t:bibl/t:msIdentifier">
                <xsl:choose>
                    <xsl:when test="t:bibl/t:msIdentifier/t:altIdentifier">
                        <xsl:text> </xsl:text>
                        <a href="{t:bibl/t:msIdentifier/t:altIdentifier/t:idno[@type='URI']/text()}">
                            <xsl:value-of select="t:bibl/t:msIdentifier/t:idno"/>
                        </a>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="t:idno"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates mode="plain"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="t:listPerson">
        <ul>
            <xsl:apply-templates/>
        </ul>
    </xsl:template>
    <!-- Handles t:link elements for deperciated notes, pulls value from matching element, output element and footnotes -->
    <xsl:template match="t:link">
        <xsl:variable name="elementID" select="substring-after(substring-before(@target,' '),'#')"/>
        <xsl:for-each select="/descendant-or-self::*[@xml:id=$elementID]">
            <xsl:apply-templates select="."/>
            <xsl:text> </xsl:text>
        </xsl:for-each>
    </xsl:template>
    <xsl:template name="leftMenu">
        <xsl:param name="nodes"/>
        <!-- Original left menu was generated via xquery -->
        <xsl:variable name="toc"><xsl:call-template name="toc"><xsl:with-param name="nodes" select="$nodes"/></xsl:call-template></xsl:variable>
        <xsl:variable name="vol" select="$nodes/descendant::t:sourceDesc/descendant::t:biblScope[@type='vol']/@n"></xsl:variable>
        <xsl:choose>
            <xsl:when test="$toc != ''">
                <div class="left-menu">
                    <span style="display:block; margin:1em;">
                        <i class="fas fa-book"></i>&#160;<a href="/volume/{$vol}">Volume <xsl:value-of select="$vol"/> 
                            <xsl:if test="$nodes/descendant::t:sourceDesc/descendant::t:imprint/t:date[. != '']">(<xsl:value-of select="$nodes/descendant::t:sourceDesc/descendant::t:imprint/t:date"/>)</xsl:if></a>
                    </span>
                    <xsl:if test="$nodes/descendant::t:body/descendant::t:pb">
                        <div class="panel panel-default">
                            <div class="panel-heading"><a href="#" data-toggle="collapse" data-target="#toggleText">Show  </a>
                                <span class="glyphicon glyphicon-question-sign text-info moreInfo" aria-hidden="true" data-toggle="tooltip" title="Toggle the text display to show line numbers, section numbers and other structural divisions"></span>
                                <div class="panel-body collapse in" id="toggleText">
                                    <div class="toggle-buttons">
                                        <span class="toggle-label"> page break : </span>
                                        <input class="toggleDisplay" type="checkbox" id="togglepb" data-element="tei-pb"/>
                                        <label for="togglepb">page break</label>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </xsl:if>
                    <xsl:if test="$toc != ''">
                        <div class="panel panel-default" id="toc">
                            <div class="panel-heading"><a href="#" data-toggle="collapse" data-target="#showToc">Table of Contents</a></div>
                            <div class="panel-body collapse in" id="showToc">
                                <xsl:sequence select="$toc"/>
                            </div>
                        </div>
                    </xsl:if>
                </div>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    <xsl:template name="toc">
        <xsl:param name="nodes"/>
        <xsl:for-each select="$nodes/descendant::t:head">
            <xsl:choose>
                <xsl:when test="parent::t:div">
                   <xsl:apply-templates select="." mode="toc"/>
                </xsl:when>
                <xsl:when test="parent::t:div2">
                   <span class="toc div2"><xsl:apply-templates select="." mode="toc"/></span>
                </xsl:when>
                <xsl:when test="parent::t:div3">
                   <span class="toc div3"><xsl:apply-templates select="." mode="toc"/></span>
                </xsl:when>
                <xsl:when test="parent::t:div4">
                  <span class="toc div4"><xsl:apply-templates select="." mode="toc"/></span>
                </xsl:when>
                <xsl:otherwise><xsl:apply-templates select="." mode="toc"/></xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
<!--        <xsl:apply-templates select="." mode="toc"/>-->
    </xsl:template>
    <xsl:template mode="toc" match="t:head">
        <xsl:variable name="id" >
            <xsl:choose>
                <xsl:when test="@xml:id"><xsl:value-of select="@xml:id"/></xsl:when>
                <xsl:when test="parent::*[1]/@n"><xsl:value-of select="concat('Head-id.',string-join(parent::*[@n][1]/@n,'.'))"/></xsl:when>
                <xsl:when test="parent::*[1]/@xml:id"><xsl:value-of select="concat('Head-id.',string-join(parent::*[@xml:id][1]/@xml:id,'.'))"/></xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="text">
            <xsl:for-each select="descendant-or-self::text()[not(parent::t:note)]">
                <xsl:value-of select="."/>
            </xsl:for-each>
        </xsl:variable>
        <a href="#{$id}" class="toc-item"><xsl:value-of select="string-join($text,' ')"/></a>
    </xsl:template>
    <xsl:template name="displayIDs">
        <xsl:param name="nodes"/>
        <div class="panel panel-default">
            <div class="panel-heading"><a href="#" data-toggle="collapse" data-target="#aboutDigitalText">About This Digital Text</a></div>
            <div class="panel-body collapse in" id="aboutDigitalText">
                <xsl:if test="$nodes/descendant::t:publicationStmt/t:idno[@type='URI']">
                    <div>
                        <h5>Record ID:</h5>
                        <span><xsl:value-of select="$nodes/descendant::t:publicationStmt/t:idno[@type='URI']"/></span>
                    </div>
                </xsl:if>
                <xsl:if test="$nodes/descendant::t:fileDesc/t:titleStmt/t:title[1]/@ref">
                    <div>
                        <h5>NHSL Work ID(s):</h5>
                        <xsl:for-each select="$nodes/descendant::t:fileDesc/t:titleStmt/t:title[@ref]">
                            <span><a href="{string(@ref)}"><xsl:value-of select="@ref"/></a><br/></span>
                        </xsl:for-each>
                    </div>
                </xsl:if>
                <div style="margin-top:1em;">
                    <span class="h5-inline">Status: </span>
                    <span>
                        <xsl:choose>
                            <xsl:when test="$nodes/descendant::t:revisionDesc/@status = 'PDF'">PDF</xsl:when>
                            <xsl:otherwise>
                                <xsl:variable name="string" select="string($nodes/descendant::t:revisionDesc/@status)"/>
                                <xsl:variable name="split" select="concat(substring($string,1,1), replace(substring($string,2),'(\p{Lu})', concat(' ', '$1')))"/>
                                <xsl:value-of select="concat(upper-case(substring($split,1,1)),substring($split,2))"/>
<!--                                <xsl:value-of select="functx:capitalize-first(functx:camel-case-to-words(string($nodes/descendant::t:revisionDesc/@status),' '))"/>-->
                            </xsl:otherwise>
                        </xsl:choose>
                        <xsl:if test="$nodes/descendant::t:revisionDesc/@status = 'PDF'">PDF</xsl:if>
                     </span>
                    &#160;<a href="/documentation/wiki.html?wiki-page=/Status-of-Contents-in-Hugoye&amp;wiki-uri=https://github.com/Beth-Mardutho/hugoye-data/wiki"><span class="glyphicon glyphicon-question-sign text-info moreInfo"></span></a>
                </div>
                <div style="margin-top:1em;">
                    <span class="h5-inline">Publication Date: </span>
                    <xsl:value-of select="format-date(xs:date($nodes/descendant::t:revisionDesc/t:change[1]/@when), '[MNn] [D], [Y]')"/>
                </div>
            </div>
        </div>
        <div class="panel panel-default">
            <div class="panel-heading"><a href="#" data-toggle="collapse" data-target="#citationText">How to Cite this Article</a></div>
            <div class="panel-body collapse in" id="citationText">
                <div>
                    <xsl:apply-templates select="$nodes/descendant::t:sourceDesc"></xsl:apply-templates>
                    <xsl:apply-templates select="$nodes/descendant::t:sourceDesc" mode="bibliography"></xsl:apply-templates>
                    <!--{(:global:tei2html($model("data")/descendant::tei:sourceDesc):)
                    bibl2html:citation($model("data")/descendant::tei:sourceDesc)}-->
                </div>
            </div>
        </div>
    </xsl:template>
    <xsl:template name="peerReview">
        <xsl:param name="nodes"/>
        <span class="badge access-pills"><a href="/documentation/wiki.html?wiki-page=/Peer-Review-Policy&amp;wiki-uri=https://github.com/Beth-Mardutho/hugoye-data/wiki" style="color:#555">peer reviewed <i class="fas fa-check"></i></a></span>
    </xsl:template>
    
    <!-- M -->
    <xsl:template match="t:milestone | t:cit | t:ab | t:l | t:lg | t:pb | t:cb | t:lb">
        <xsl:param name="parentID"/>
        <xsl:variable name="currentid" select="concat(if($parentID != '') then $parentID else 'id','.',@n)"/>
        <span class="{concat('tei-',name(.))}             {if(@unit) then concat(' tei-',@unit) else ()} {if(@type) then concat(' tei-',@type) else ()}">
            <!-- {if(self::t:l) then concat(name(.),'-display') else ()} -->
            <xsl:choose>
                <xsl:when test="child::t:head">
                    <xsl:attribute name="id">
                        <xsl:value-of select="concat('Head-',$currentid)"/>
                    </xsl:attribute>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:attribute name="id">
                        <xsl:value-of select="$currentid"/>
                    </xsl:attribute>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:choose>
                <xsl:when test="@lang">
                    <xsl:sequence select="local:attributes(.)"/>
                </xsl:when>
                <xsl:when test="ancestor-or-self::*[@xml:lang][1]/@xml:lang">
                    <xsl:attribute name="lang">
                        <xsl:value-of select="ancestor-or-self::*[@xml:lang][1]/@xml:lang"/>
                    </xsl:attribute>                    
                </xsl:when>
                <xsl:otherwise/>
            </xsl:choose>
            
            <xsl:choose>
                <xsl:when test="child::t:head">
                    <span id="{$currentid}"/>
                </xsl:when>
                <xsl:otherwise>
                    <span class="text-number badge">
                        <xsl:if test="self::t:pb">pb. </xsl:if> <xsl:value-of select="@n"/>
                    </span>
                </xsl:otherwise>
            </xsl:choose>
            
            <xsl:apply-templates>
                <xsl:with-param name="parentID" select="$currentid"/>
            </xsl:apply-templates>
        </span>
    </xsl:template>
    
    <!-- N -->
    <xsl:template match="t:note">
        <xsl:variable name="xmlid" select="@xml:id"/>
        <xsl:choose>
            <xsl:when test="ancestor::t:choice">
                <xsl:text> (</xsl:text>
                <span>
                    <xsl:sequence select="local:attributes(.)"/>
                    <xsl:apply-templates/>
                </span>
                <xsl:text>) </xsl:text>
                <xsl:sequence select="local:add-footnotes(@source,.)"/>
            </xsl:when>
            <!-- Adds definition list for depreciated names -->
            <xsl:when test="@type='deprecation'">
                <div class="tei-note">
                    <span>
                        <xsl:if test="../t:link[contains(@target,$xmlid)]">
                            <xsl:apply-templates select="../t:link[contains(@target,$xmlid)]"/>:
                        </xsl:if>
                        <xsl:apply-templates/>
                        <!-- Check for ending punctuation, if none, add . -->
                        <!-- NOTE not working -->
                    </span>
                    <xsl:sequence select="local:add-footnotes(@source,.)"/>
                </div>
            </xsl:when>
            <xsl:when test="@type='ancientVersion'">
                <div class="tei-note">
                    <xsl:if test="descendant::t:lang/text()">
                        <span class="srp-label">
                            <xsl:value-of select="local:expand-lang(descendant::t:lang[1]/text(),'ancientVersion')"/>:
                        </span>
                    </xsl:if>
                    <span>
                        <xsl:sequence select="local:attributes(.)"/>
                        <xsl:apply-templates/>
                    </span>
                    <xsl:sequence select="local:add-footnotes(@source,.)"/>
                </div>
            </xsl:when>
            <xsl:when test="@type='modernTranslation'">
                <li>
                    <xsl:if test="descendant::t:lang/text()">
                        <span class="srp-label">
                            <xsl:value-of select="local:expand-lang(descendant::t:lang[1]/text(),'modernTranslation')"/>:
                        </span>
                    </xsl:if>
                    <span>
                        <xsl:sequence select="local:attributes(.)"/>
                        <xsl:apply-templates/>
                    </span>
                    <xsl:sequence select="local:add-footnotes(@source,.)"/>
                </li>
            </xsl:when>
            <xsl:when test="@type='editions'">
                <div class="tei-note">
                    <span>
                        <xsl:sequence select="local:attributes(.)"/>
                        <xsl:apply-templates/>
                        <xsl:if test="t:bibl/@corresp">
                            <xsl:variable name="mss" select="../t:note[@type='MSS']"/>
                            <xsl:text> (</xsl:text>
                            <xsl:choose>
                                <xsl:when test="@ana='partialTranslation'">Partial edition</xsl:when>
                                <xsl:otherwise>Edition</xsl:otherwise>
                            </xsl:choose>
                            <xsl:text> from manuscript </xsl:text>
                            <xsl:choose>
                                <xsl:when test="contains(t:bibl/@corresp,' ')">
                                    <xsl:text>witnesses </xsl:text>
                                    <xsl:for-each select="tokenize(t:bibl/@corresp,' ')">
                                        <xsl:variable name="corresp" select="."/>
                                        <xsl:for-each select="$mss/t:bibl">
                                            <xsl:if test="@xml:id = $corresp">
                                                <xsl:value-of select="position()"/>
                                            </xsl:if>
                                        </xsl:for-each>
                                        <xsl:if test="position() != last()">, </xsl:if>
                                    </xsl:for-each>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:variable name="corresp" select="substring-after(t:bibl/@corresp,'#')"/>
                                    <xsl:text>witness </xsl:text>
                                    <xsl:for-each select="$mss/t:bibl">
                                        <xsl:if test="@xml:id = $corresp">
                                            <xsl:value-of select="position()"/>
                                        </xsl:if>
                                    </xsl:for-each>
                                </xsl:otherwise>
                            </xsl:choose>
                            <xsl:text>. See below.)</xsl:text>
                        </xsl:if>
                    </span>
                    <xsl:sequence select="local:add-footnotes(@source,.)"/>
                </div>
            </xsl:when>
            <xsl:otherwise>
                <div class="tei-note">  
                    <xsl:choose>
                        <xsl:when test="t:quote"><xsl:apply-templates/></xsl:when>
                        <xsl:otherwise><span><xsl:sequence select="local:attributes(.)"/><xsl:apply-templates/></span><xsl:sequence select="local:add-footnotes(@source,.)"/></xsl:otherwise>
                    </xsl:choose>
                </div>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="t:note" mode="footnote">
        <p class="footnote-text">
            <xsl:if test="@n">
                <xsl:attribute name="id" select="concat('note',@n)"/>
                <span class="notes footnote-refs">
                    <span class="footnote-ref">‎<xsl:value-of select="@n"/>
                    </span> </span>
            </xsl:if>
            <xsl:choose>
                <xsl:when test="t:quote">
                    <xsl:apply-templates/>
                </xsl:when>
                <xsl:when test="t:p">
                    <xsl:for-each select="t:p">
                        <span>
                            <xsl:sequence select="local:attributes(.)"/>
                            <xsl:apply-templates/>
                        </span>                        
                    </xsl:for-each>
                </xsl:when>
                <xsl:otherwise>
                    <span>
                        <xsl:sequence select="local:attributes(.)"/>
                        <xsl:apply-templates/>
                    </span>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:if test="@source">
                <xsl:sequence select="local:add-footnotes(@source,@xml:lang)"/>
            </xsl:if>
        </p>
    </xsl:template>
    <xsl:template match="t:note" mode="abstract">
        <p>
            <xsl:apply-templates/>
            <xsl:if test="@source">
                <xsl:sequence select="local:add-footnotes(@source,@xml:lang)"/>
            </xsl:if>
        </p>
    </xsl:template>
    
    <!-- O -->
    <xsl:template match="t:offset | t:measure | t:source ">
        <xsl:if test="preceding-sibling::*">
            <xsl:text> </xsl:text>
        </xsl:if>
        <xsl:apply-templates select="." mode="plain"/>
    </xsl:template>

    <xsl:template match="t:orig">
        <xsl:text> (</xsl:text>
        <xsl:apply-templates/>
        <xsl:text>) </xsl:text>
    </xsl:template>
    <xsl:template match="t:sic">
        <xsl:text> [sic: </xsl:text>
        <xsl:apply-templates/>
        <xsl:text>] </xsl:text>
    </xsl:template>
    
    <!-- P -->
    <!-- Main page modules for syriaca.org display -->
    <xsl:template match="t:p">
        <xsl:param name="parentID"/>
        <xsl:variable name="currentid" select="concat(if($parentID != '') then $parentID else 'id','.',@n)"/>
        <p class="{concat('tei-',name(.))}{if(@unit) then concat(' tei-',@unit) else ()} text-display">
            <xsl:choose>
                <xsl:when test="child::t:head">
                    <xsl:attribute name="id">
                        <xsl:value-of select="concat('Head-',$currentid)"/>
                    </xsl:attribute>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:attribute name="id">
                        <xsl:value-of select="$currentid"/>
                    </xsl:attribute>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:choose>
                <xsl:when test="@lang or @xml:lang">
                    <xsl:sequence select="local:attributes(.)"/>
                </xsl:when>
                <xsl:when test="ancestor-or-self::*[@xml:lang][1]/@xml:lang">
                    <xsl:attribute name="lang">
                        <xsl:value-of select="ancestor-or-self::*[@xml:lang][1]/@xml:lang"/>
                    </xsl:attribute>                    
                </xsl:when>
                <xsl:otherwise/>
            </xsl:choose>
            <xsl:if test="@n">
                <xsl:choose>
                    <xsl:when test="child::t:head">
                        <span id="{$currentid}"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <span class="text-number badge">
                            <xsl:value-of select="@n"/>
                        </span>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:if>
            <xsl:apply-templates>
                <xsl:with-param name="parentID" select="$currentid"/>
            </xsl:apply-templates>
        </p>
    </xsl:template>
    
    <xsl:template match="t:person | t:personGrp">
        <xsl:if test="t:desc[@type='abstract'] | t:desc[starts-with(@xml:id, 'abstract-en')] | t:note[@type='abstract']">
            <xsl:choose>
                <xsl:when test="$collection = 'johnofephesusPersons'">
                    <xsl:if test="t:note[@type='abstract'][contains(@corresp,'http://syriaca.org/johnofephesus/persons')]">
                        <div class="tei-desc text abstract">
                            <xsl:apply-templates select="t:note[@type='abstract'][contains(@corresp,'http://syriaca.org/johnofephesus/persons')]"/>
                        </div>
                    </xsl:if>
                </xsl:when>
                <xsl:when test="t:note[@type='abstract'][contains(@corresp,'http://syriaca.org/persons')]">
                    <div class="tei-desc text abstract">
                        <xsl:apply-templates select="t:note[@type='abstract'][contains(@corresp,'http://syriaca.org/persons')]"/>    
                    </div>
                </xsl:when>
                <xsl:otherwise>
                    <div class="tei-desc text abstract">
                        <xsl:apply-templates select="t:desc[@type='abstract' or starts-with(@xml:id, 'abstract-en')][1] | t:note[@type='abstract'][1]"/>
                    </div>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
        <xsl:if test="t:persName[not(empty(descendant-or-self::text()))]">
            <h3>Names</h3>
            <ul class="persNames">
                <xsl:apply-templates select="t:persName[@srophe:tags='#syriaca-headword' and starts-with(@xml:lang,'syr')]" mode="list">
                    <xsl:sort lang="syr" select="."/>
                </xsl:apply-templates>
                <xsl:apply-templates select="t:persName[@srophe:tags='#syriaca-headword' and starts-with(@xml:lang,'en')]" mode="list">
                    <xsl:sort collation="{$mixed}" select="."/>
                </xsl:apply-templates>
                <xsl:apply-templates select="t:persName[(not(@srophe:tags) or @srophe:tags!='#syriaca-headword') and starts-with(@xml:lang, 'syr')]" mode="list">
                    <xsl:sort lang="syr" select="."/>
                </xsl:apply-templates>
                <xsl:apply-templates select="t:persName[starts-with(@xml:lang, 'ar')]" mode="list">
                    <xsl:sort lang="ar" select="."/>
                </xsl:apply-templates>
                <xsl:apply-templates select="t:persName[(not(@srophe:tags) or @srophe:tags!='#syriaca-headword') and not(starts-with(@xml:lang, 'syr') or starts-with(@xml:lang, 'ar')) and not(@srophe:tags='#syriaca-simplified-script')]" mode="list">                    
                    <xsl:sort collation="{$mixed}" select="."/>    
                </xsl:apply-templates> 
            </ul>   
        </xsl:if>
        <xsl:apply-templates select="t:sex | t:gender | t:death | t:birth | t:floruit"/>
        <!-- Work in progress
        <xsl:if test="t:state">
            <xsl:for-each-group select="//t:state[not(@when) and not(@notBefore) and not(@notAfter) and not(@to) and not(@from)]" group-by="@type">
                <h4>
                    <xsl:value-of select="concat(upper-case(substring(current-grouping-key(),1,1)),substring(current-grouping-key(),2))"/>
                </h4>
                <ul>
                    <xsl:for-each select="current-group()[not(t:desc/@xml:lang = 'en-x-gedsh')]">
                        <li>
                            <xsl:apply-templates mode="plain"/>
                            <xsl:sequence select="local:add-footnotes(self::*/@source,.)"/>
                        </li>
                    </xsl:for-each>
                </ul>
            </xsl:for-each-group>
        </xsl:if>
        -->
        <xsl:if test="not(empty(t:desc[not(starts-with(@xml:id,'abstract'))][1])) or not(empty(t:note[@type='description'][1]))">
            <h3>Descriptions</h3>
            <xsl:for-each-group select="t:desc[not(starts-with(@xml:id,'abstract'))] | t:note[@type='description']" group-by="if (contains(@xml:lang, '-')=true()) then substring-before(@xml:lang, '-') else @xml:lang">
                <xsl:sort collation="{$languages}" select="if (contains(@xml:lang, '-')=true()) then substring-before(@xml:lang, '-') else @xml:lang"/>
                <xsl:for-each select="current-group()">
                    <xsl:sort lang="{current-grouping-key()}" select="normalize-space(.)"/>
                    <div class="tei-desc text">
                        <xsl:apply-templates select="."/>
                    </div>
                </xsl:for-each>
            </xsl:for-each-group>
        </xsl:if> 
        <!-- Events -->
        <xsl:if test="t:event[not(@type='attestation')]">
            <div id="event">
                <h3>Event<xsl:if test="count(t:event[not(@type='attestation')]) &gt; 1">s</xsl:if>
                </h3>
                <div class="text-block">
                    <xsl:for-each select="t:event[not(@type='attestation')]">
                        <xsl:sort select="if(exists(@notBefore)) then @notBefore else @when"/>
                        <span class="text-block">
                            <xsl:apply-templates select="."/>
                        </span>
                    </xsl:for-each>
                </div>
            </div>
        </xsl:if>
        
        <!-- Events/attestation -->
        <xsl:if test="t:event[@type='attestation']">
            <div id="attestation">
                <h3>Attestation<xsl:if test="count(t:event[@type='attestation']) &gt; 1">s</xsl:if></h3>
                <div class="text-block">
                    <!-- Sorts events on dates, checks first for @notBefore and if not present, uses @when -->
                    <xsl:for-each select="t:event[@type='attestation']">
                        <xsl:sort select="if(exists(@notBefore)) then @notBefore else @when"/>
                        <span class="text-block">
                            <xsl:apply-templates select="."/>     
                        </span>
                    </xsl:for-each>
                </div>
            </div>
        </xsl:if>
        
        <xsl:if test="not(empty(t:note[not(@type='description')][1]))">
            <xsl:choose>
                <xsl:when test="$collection = 'johnofephesusPersons'">
                    <xsl:if test="t:note[not(@type='abstract')][not(@type='description')][contains(@corresp,'http://syriaca.org/johnofephesus/persons')]">
                        <h3>Notes</h3>
                        <xsl:apply-templates select="t:note[not(@type='abstract')][not(@type='description')][not(contains(@corresp,'http://syriaca.org/johnofephesus/persons'))]"/>
                    </xsl:if>
                </xsl:when>
                <xsl:when test="t:note[not(@type='abstract')][contains(@corresp,'http://syriaca.org/persons')]">
                    <h3>Notes</h3>
                    <xsl:apply-templates select="t:note[not(@type='abstract')][not(@type='description')][not(contains(@corresp,'http://syriaca.org/persons'))]"/>
                </xsl:when>
                <xsl:otherwise>
                    <h3>Notes</h3>
                    <xsl:apply-templates select="t:note[not(@type='abstract')][not(@type='description')]"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
        
        <div class="info-btns">  
            <xsl:variable name="status" select="string(/descendant-or-self::t:revisionDesc/@status)"/>
            <xsl:if test="$status != ''">
                <span class="rec-status {$status} btn btn-info">Status: <xsl:value-of select="$status"/></span>    
            </xsl:if>
            <!-- Button trigger corrections email modal -->
            <button class="btn btn-info" data-toggle="modal" data-target="#feedback">Corrections/Additions?</button> 
            <a href="#" class="btn btn-info" data-toggle="modal" data-target="#selection" data-ref="../documentation/faq.html" id="showSection">
                Is this record complete?
            </a>
        </div>
        <!-- Build see also -->
        <xsl:call-template name="link-icons-list">
            <xsl:with-param name="title">
                <xsl:value-of select="//t:teiHeader/descendant::t:titleStmt/t:title[1]"/>
            </xsl:with-param>
        </xsl:call-template>
        <xsl:call-template name="sources"/>
    </xsl:template>
    <xsl:template match="t:place">
        <xsl:if test="t:desc[@type='abstract'] | t:desc[starts-with(@xml:id, 'abstract-en')] | t:note[@type='abstract']">
            <xsl:choose>
                <xsl:when test="$collection = 'johnofephesusPlace'">
                    <xsl:if test="t:note[@type='abstract'][contains(@corresp,'http://syriaca.org/johnofephesus/places')]">
                        <div class="tei-desc text abstract">
                            <xsl:apply-templates select="t:note[@type='abstract'][contains(@corresp,'http://syriaca.org/johnofephesus/places')]"/>
                        </div>
                    </xsl:if>
                </xsl:when>
                <xsl:when test="t:note[@type='abstract'][contains(@corresp,'http://syriaca.org/places')]">
                    <div class="tei-desc text abstract">
                        <xsl:apply-templates select="t:note[@type='abstract'][contains(@corresp,'http://syriaca.org/places')]"/>    
                    </div>
                </xsl:when>
                <xsl:otherwise>
                    <div class="tei-desc text abstract">
                        <xsl:apply-templates select="t:desc[@type='abstract' or starts-with(@xml:id, 'abstract-en')][1] | t:note[@type='abstract'][1]"/>
                    </div>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
        <xsl:if test="t:placeName">
            <div id="placenames" class="content-block">
                <h3>Names</h3>
                <ul>
                    <xsl:apply-templates select="t:placeName[@srophe:tags='#syriaca-headword' and @xml:lang='syr']" mode="list">
                        <xsl:sort lang="syr" select="."/>
                    </xsl:apply-templates>
                    <xsl:apply-templates select="t:placeName[@srophe:tags='#syriaca-headword' and @xml:lang='en']" mode="list">
                        <xsl:sort collation="{$mixed}" select="."/>
                    </xsl:apply-templates>
                    <xsl:apply-templates select="t:placeName[(not(@srophe:tags) or @srophe:tags!='#syriaca-headword') and starts-with(@xml:lang, 'syr')]" mode="list">
                        <xsl:sort lang="syr" select="."/>
                    </xsl:apply-templates>
                    <xsl:apply-templates select="t:placeName[starts-with(@xml:lang, 'ar')]" mode="list">
                        <xsl:sort lang="ar" select="."/>
                    </xsl:apply-templates>
                    <xsl:apply-templates select="t:placeName[(not(@srophe:tags) or @srophe:tags!='#syriaca-headword') and not(starts-with(@xml:lang, 'syr') or starts-with(@xml:lang, 'ar')) and not(@syriaca-tags='#syriaca-simplified-script')]" mode="list">
                        <xsl:sort collation="{$mixed}" select="."/>
                    </xsl:apply-templates>
                </ul>
            </div>
        </xsl:if>
        <div class="content-block">
            <h3>Place Type</h3>
            <p class="text-block">
                <xsl:value-of select="@type"/>
            </p>
        </div>
        <xsl:if test="t:location">
            <div id="placenames" class="content-block">
                <h3>Location</h3>
                <ul>
                    <xsl:apply-templates select="t:location"/>    
                </ul>
            </div>
        </xsl:if>
        <xsl:if test="not(empty(t:desc[not(starts-with(@xml:id,'abstract'))][1])) or not(empty(t:note[@type='description'][1]))">
            <h3>Descriptions</h3>
            <xsl:for-each-group select="t:desc[not(starts-with(@xml:id,'abstract'))] | t:note[@type='description']" group-by="if (contains(@xml:lang, '-')=true()) then substring-before(@xml:lang, '-') else @xml:lang">
                <xsl:sort collation="{$languages}" select="if (contains(@xml:lang, '-')=true()) then substring-before(@xml:lang, '-') else @xml:lang"/>
                <xsl:for-each select="current-group()">
                    <xsl:sort lang="{current-grouping-key()}" select="normalize-space(.)"/>
                    <div class="tei-desc text">
                        <xsl:apply-templates select="."/>
                    </div>
                </xsl:for-each>
            </xsl:for-each-group>
        </xsl:if> 
        <xsl:if test="t:state[. != '']">
            <xsl:for-each-group select="//t:state[not(@when) and not(@notBefore) and not(@notAfter) and not(@to) and not(@from)]" group-by="@type">
                <h3><xsl:value-of select="concat(upper-case(substring(current-grouping-key(),1,1)),substring(current-grouping-key(),2))"/></h3>
                <ul>
                    <xsl:for-each select="current-group()[not(t:desc/@xml:lang = 'en-x-gedsh')]">
                        <li>
                            <xsl:apply-templates mode="plain"/>
                            <xsl:sequence select="local:add-footnotes(self::*/@source,.)"/>
                        </li>
                    </xsl:for-each>
                </ul>
            </xsl:for-each-group>
        </xsl:if>
        <!-- Events -->
        <xsl:if test="t:event[not(@type='attestation')]">
            <div id="event">
                <h3>Event<xsl:if test="count(t:event[not(@type='attestation')]) &gt; 1">s</xsl:if></h3>
                <div class="text-block">
                    <xsl:for-each select="t:event[not(@type='attestation')]">
                        <xsl:sort select="if(exists(@notBefore)) then @notBefore else @when"/>
                        <span class="text-block">
                            <xsl:apply-templates select="."/>
                        </span>
                    </xsl:for-each>
                </div>
            </div>
        </xsl:if>
        
        <!-- Events/attestation -->
        <xsl:if test="t:event[@type='attestation']">
            <div id="attestation">
                <h3>Attestation<xsl:if test="count(t:event[@type='attestation']) &gt; 1">s</xsl:if></h3>
                <div class="text-block">
                    <!-- Sorts events on dates, checks first for @notBefore and if not present, uses @when -->
                    <xsl:for-each select="t:event[@type='attestation']">
                        <xsl:sort select="if(exists(@notBefore)) then @notBefore else @when"/>
                        <span class="text-block">
                            <xsl:apply-templates select="."/>     
                        </span>
                    </xsl:for-each>
                </div>
            </div>
        </xsl:if>
        
        <xsl:if test="not(empty(t:note[not(@type='description')][1]))">
            <xsl:choose>
                <xsl:when test="$collection = 'johnofephesusPlace'">
                    <xsl:if test="t:note[not(@type='abstract')][not(@type='description')][contains(@corresp,'http://syriaca.org/johnofephesus/places')]">
                        <h3>Notes</h3>
                        <xsl:apply-templates select="t:note[not(@type='abstract')][not(@type='description')][not(contains(@corresp,'http://syriaca.org/johnofephesus/places'))]"/>
                    </xsl:if>
                </xsl:when>
                <xsl:when test="t:note[not(@type='abstract')][not(@type='description')][contains(@corresp,'http://syriaca.org/places')]">
                    <h3>Notes</h3>
                    <xsl:apply-templates select="t:note[not(@type='abstract')][not(@type='description')][not(contains(@corresp,'http://syriaca.org/places'))]"/>
                </xsl:when>
                <xsl:otherwise>
                    <h3>Notes</h3>
                    <xsl:apply-templates select="t:note[not(@type='abstract')][not(@type='description')]"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
        <!-- Confessions/Religious Communities -->
        <xsl:if test="t:state[@type='confession'][parent::t:place]">
            <div>
                <h3>Known Religious Communities</h3>
                <p class="caveat">
                    <em>This list is not necessarily exhaustive, and the order does not represent importance or proportion of the population. Dates do not represent starting or ending dates of a group's presence, but rather when they are attested. Instead, the list only represents groups for which Syriaca.org has source(s) and dates.</em>
                </p>
                <xsl:choose>
                    <xsl:when test="doc-available(concat($applicationPath,'/documentation/confessions.xml'))">
                        <xsl:call-template name="confessions">
                            <xsl:with-param name="confessionsDoc" select="document(concat($applicationPath,'/documentation/confessions.xml'))"/>
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                        <ul>
                            <xsl:for-each select="t:state[@type='confession']">
                                <li>
                                    <xsl:apply-templates mode="plain"/>
                                </li>
                            </xsl:for-each>
                        </ul>
                    </xsl:otherwise>
                </xsl:choose>
            </div>
        </xsl:if>
        
        <div class="info-btns">  
            <xsl:variable name="status" select="string(/descendant-or-self::t:revisionDesc/@status)"/>
            <xsl:if test="$status != ''">
                <span class="rec-status {$status} btn btn-info">Status: <xsl:value-of select="$status"/></span>    
            </xsl:if>
            <!-- Button trigger corrections email modal -->
            <button class="btn btn-info" data-toggle="modal" data-target="#feedback">Corrections/Additions?</button> 
            <a href="#" class="btn btn-info" data-toggle="modal" data-target="#selection" data-ref="../documentation/faq.html" id="showSection">
                Is this record complete?
            </a>
        </div>
        
        <!-- Build see also -->
        <xsl:call-template name="link-icons-list">
            <xsl:with-param name="title">
                <xsl:value-of select="//t:teiHeader/descendant::t:titleStmt/t:title[1]"/>
            </xsl:with-param>
        </xsl:call-template>
        <xsl:call-template name="sources"/>
        
        <!-- WS: Note, this was constructed by XQuery, will need to pull it in another way -->
        <!--
        <xsl:if test="t:nested-place">
            <div id="contents">
                <h3>Contains</h3>
                <ul>
                    <xsl:for-each select="/child::*/t:nested-place">
                        <xsl:sort collation="{$mixed}" select="t:placeName[@xml:lang='en'][1]/@reg"/>
                        <li>
                            <a href="{concat('/place/',@id,'.html')}">
                                <xsl:value-of select="."/>
                                <xsl:value-of select="concat(' (',@type,')')"/>
                            </a>
                        </li>
                    </xsl:for-each>
                </ul>
            </div>
        </xsl:if>
        -->

    </xsl:template>
    <xsl:template match="t:bibl[starts-with(@xml:id,'work-')]">
        <div class="content-block">
            <h3>Titles</h3>
            <ul>                
                <xsl:for-each select="t:title[(not(@type) or not(@type=('initial-rubric','final-rubric','abbreviation'))) and not(@syriaca-tags='#syriaca-simplified-script')]">
                    <xsl:apply-templates select=".[contains(@srophe:tags,'#syriaca-headword') and starts-with(@xml:lang,'en')]" mode="list">
                        <xsl:sort collation="{$mixed}" select="."/>
                    </xsl:apply-templates>
                    <xsl:apply-templates select=".[contains(@srophe:tags,'#syriaca-headword') and starts-with(@xml:lang,'syr')]" mode="list">
                        <xsl:sort lang="syr" select="."/>
                    </xsl:apply-templates>
                    <xsl:apply-templates select=".[(not(@srophe:tags) or not(contains(@srophe:tags,'#syriaca-headword'))) and starts-with(@xml:lang, 'syr')]" mode="list">
                        <xsl:sort lang="syr" select="."/>
                    </xsl:apply-templates>
                    <xsl:apply-templates select=".[starts-with(@xml:lang, 'ar')]" mode="list">
                        <xsl:sort lang="ar" select="."/>
                    </xsl:apply-templates>
                    <xsl:apply-templates select=".[(not(@srophe:tags) or not(contains(@srophe:tags,'#syriaca-headword'))) and not(starts-with(@xml:lang, 'syr') or starts-with(@xml:lang, 'ar'))]" mode="list">
                        <xsl:sort collation="{$mixed}" select="."/>
                    </xsl:apply-templates>
                </xsl:for-each>
            </ul>
            <xsl:if test="t:title[@type='abbreviation']">
                <h3>Abbreviations</h3>
                <ul>
                    <xsl:for-each select="t:title[@type='abbreviation']">
                        <xsl:apply-templates select="." mode="list"/>
                    </xsl:for-each>
                </ul>
            </xsl:if>
            <xsl:if test="t:author | t:editor">
                <h3>Authors</h3>
                <ul>
                    <xsl:for-each select="t:author | t:editor">
                        <li>
                            <xsl:apply-templates select="."/>
                        </li>
                    </xsl:for-each>
                </ul>
            </xsl:if>
            <xsl:if test="not(empty(t:desc[@type='abstract' or starts-with(@xml:id, 'abstract-en')][1] | t:note[@type='abstract']))">
                <h3>Abstract</h3>
                <xsl:apply-templates select="t:desc[@type='abstract' or starts-with(@xml:id, 'abstract-en')][1] | t:note[@type='abstract']"/>
            </xsl:if>
            <xsl:if test="@ana">
                <xsl:for-each select="tokenize(@ana,' ')">
                    <xsl:variable name="filepath">
                        <!-- WS:NOTE need to resolve -->
<!--                        <xsl:value-of select="concat('xmldb:exist://',substring-before(replace(.,$base-uri,$nav-base),'#'))"/>-->
                        <xsl:value-of select="substring-before(replace(.,$base-uri,$nav-base),'#')"/>
                    </xsl:variable>
                    <xsl:variable name="ana-id" select="substring-after(.,'#')"/>
                    <xsl:if test="doc-available($filepath)">
                        <p>
                            <strong>Subject: </strong>
                            <xsl:for-each select="document($filepath)/descendant::t:*[@xml:id = $ana-id]">
                                <xsl:value-of select="t:label"/>
                            </xsl:for-each>
                        </p>
                    </xsl:if>
                </xsl:for-each>
            </xsl:if>
            <xsl:if test="t:date">
                <p>
                    <strong>Date: </strong>
                    <xsl:apply-templates select="t:date"/>
                </p>
            </xsl:if>
            <xsl:if test="t:extent">
                <p>
                    <strong>Extent: </strong>
                    <xsl:apply-templates select="t:extent"/>
                </p>
            </xsl:if>
            <xsl:if test="t:idno">
                <h3>Reference Numbers</h3>
                <p class="indent">
                    <xsl:for-each select="t:idno[contains(.,$base-uri)]">
                        <xsl:choose>
                            <xsl:when test="@type='URI'">
                                <a href="{.}">
                                    <xsl:value-of select="."/>
                                </a>
                            </xsl:when>
                            <xsl:when test="@type = 'BHSYRE'">
                                <xsl:value-of select="concat(replace(@type,'BHSYRE','BHS'),': ',.)"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="concat(@type,': ',.)"/>
                            </xsl:otherwise>
                        </xsl:choose>
                        <xsl:if test="position() != last()"> = </xsl:if>
                    </xsl:for-each>
                </p>
            </xsl:if>
        </div>
        
        <xsl:if test="t:title[@type='initial-rubric']">
            <h3>Initial Rubrics</h3>
            <ul>
                <xsl:for-each select="t:title[@type='initial-rubric']">
                    <xsl:apply-templates select="." mode="list"/>
                </xsl:for-each>
            </ul>
        </xsl:if>
        <xsl:if test="t:title[@type='final-rubric']">
            <h3>Final Rubrics</h3>
            <ul>
                <xsl:for-each select="t:title[@type='final-rubric']">
                    <xsl:apply-templates select="." mode="list"/>
                </xsl:for-each>
            </ul>
        </xsl:if>
        <xsl:if test="self::t:bibl[@type='lawd:Citation' or @type='lawd:ConceptualWork'] or parent::t:body">
            <xsl:variable name="type-order"/>
            <xsl:for-each-group select="t:bibl[exists(@type)][@type != 'lawd:Citation']" group-by="@type">
                <xsl:sort select="local:bibl-type-order(current-grouping-key())" order="ascending"/>
                <xsl:variable name="label">
                    <xsl:variable name="l" select="local:translate-label(current-grouping-key(),count(current-group()))"/>
                    <xsl:choose>
                        <xsl:when test="$l != ''">
                            <xsl:value-of select="$l"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="current-grouping-key()"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <h3>
                    <span class="anchor" id="bibl{$label}"/>
                    <xsl:value-of select="concat(upper-case(substring($label,1,1)),substring($label,2))"/>
                </h3>
                <ol>
                    <xsl:for-each select="current-group()[position() &lt; 9]">
                        <xsl:apply-templates select="self::*"/>
                    </xsl:for-each>
                    <xsl:if test="count(current-group()) &gt; 8">
                        <div class="collapse" id="showMore-{local:bibl-type-order(current-grouping-key())}">
                            <xsl:for-each select="current-group()[position() &gt; 8]">
                                <xsl:apply-templates select="self::*"/>
                            </xsl:for-each>                                    
                        </div>
                        <button class="btn btn-link bibl-show togglelink" data-toggle="collapse" data-target="#showMore-{local:bibl-type-order(current-grouping-key())}" data-text-swap="Hide">Show all <xsl:value-of select="count(current-group())"/>
                            <xsl:text> </xsl:text> <xsl:value-of select="$label"/>
                        </button>
                    </xsl:if>
                </ol>
            </xsl:for-each-group>
            <xsl:for-each select="t:note[not(exists(@type))]">
                <h3>Note</h3>
                <div class="left-padding bottom-padding">
                    <xsl:apply-templates/>
                </div>
            </xsl:for-each>
        </xsl:if>
        
        <xsl:if test="not(empty(t:desc[not(starts-with(@xml:id,'abstract'))][1])) or not(empty(t:note[@type='description'][1]))">
            <h3>Descriptions</h3>
            <xsl:for-each-group select="t:desc[not(starts-with(@xml:id,'abstract'))] | t:note[@type='description']" group-by="if (contains(@xml:lang, '-')=true()) then substring-before(@xml:lang, '-') else @xml:lang">
                <xsl:sort collation="{$languages}" select="if (contains(@xml:lang, '-')=true()) then substring-before(@xml:lang, '-') else @xml:lang"/>
                <xsl:for-each select="current-group()">
                    <xsl:sort lang="{current-grouping-key()}" select="normalize-space(.)"/>
                    <div class="tei-desc text">
                        <xsl:apply-templates select="."/>
                    </div>
                </xsl:for-each>
            </xsl:for-each-group>
        </xsl:if> 
        
        <xsl:if test="t:note[not(@type='abstract')]">
            <xsl:variable name="rules" select="                 '&lt; prologue &lt; incipit &lt; explicit &lt;                  editions &lt; modernTranslation &lt;                  ancientVersion &lt; MSS'"/>
            <xsl:for-each-group select="t:note[not(@type='abstract')][exists(@type)]" group-by="@type">
                <xsl:sort select="current-grouping-key()" collation="http://saxon.sf.net/collation?rules={encode-for-uri($rules)};ignore-case=yes;ignore-modifiers=yes;ignore-symbols=yes)" order="ascending"/>
                <!--<xsl:sort select="current-grouping-key()" order="descending"/>-->
                <xsl:variable name="label">
                    <xsl:choose>
                        <xsl:when test="current-grouping-key() = 'MSS'">Syriac Manuscript Witnesses</xsl:when>
                        <xsl:when test="current-grouping-key() = 'incipit'">Incipit (Opening Line)</xsl:when>
                        <xsl:when test="current-grouping-key() = 'explicit'">Explicit (Closing Line)</xsl:when>
                        <xsl:when test="current-grouping-key() = 'ancientVersion'">Ancient Versions</xsl:when>
                        <xsl:when test="current-grouping-key() = 'modernTranslation'">Modern Translations</xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="current-grouping-key()"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <h3>
                    <xsl:value-of select="concat(upper-case(substring($label,1,1)),substring($label,2))"/>
                </h3>
                <div class="indent">
                    <xsl:for-each select="current-group()">
                        <xsl:sort select="if(current-grouping-key() = 'MSS') then substring-after(t:bibl[1]/@xml:id,'-') = '' else if(current-grouping-key() = 'editions') then substring-after(t:bibl/@corresp,'-') = '' else if(@xml:lang) then local:expand-lang(@xml:lang,$label) else ." order="ascending"/>
                        <xsl:sort select="if(current-grouping-key() = 'MSS' and (substring-after(t:bibl[1]/@xml:id,'-') castable as xs:integer)) then xs:integer(substring-after(t:bibl/@xml:id,'-')) else if(@xml:lang) then local:expand-lang(@xml:lang,$label) else ()" order="ascending"/>
                        <xsl:apply-templates select="self::*"/>
                    </xsl:for-each>
                </div>
            </xsl:for-each-group>
            <xsl:for-each select="t:note[not(exists(@type))]">
                <h3>Note</h3>
                <div class="left-padding bottom-padding">
                    <xsl:apply-templates/>
                </div>
            </xsl:for-each>
        </xsl:if>
        
        <div class="info-btns">  
            <xsl:variable name="status" select="string(/descendant-or-self::t:revisionDesc/@status)"/>
            <xsl:if test="$status != ''">
                <span class="rec-status {$status} btn btn-info">Status: <xsl:value-of select="$status"/></span>    
            </xsl:if>
            <!-- Button trigger corrections email modal -->
            <button class="btn btn-info" data-toggle="modal" data-target="#feedback">Corrections/Additions?</button> 
            <a href="#" class="btn btn-info" data-toggle="modal" data-target="#selection" data-ref="../documentation/faq.html" id="showSection">
                Is this record complete?
            </a>
        </div>
        
        <!-- Build see also -->
        <xsl:call-template name="link-icons-list">
            <xsl:with-param name="title">
                <xsl:value-of select="//t:teiHeader/descendant::t:titleStmt/t:title[1]"/>
            </xsl:with-param>
        </xsl:call-template>
        <xsl:call-template name="sources"/>
    </xsl:template>
    <xsl:template match="t:entryFree">
        <xsl:if test="not(empty(t:desc[not(starts-with(@xml:id,'abstract'))][1]))">
            <div id="description">
                <h3>Brief Descriptions</h3>
                    <xsl:for-each-group select="t:desc" group-by="if (contains(@xml:lang, '-')=true()) then substring-before(@xml:lang, '-') else @xml:lang">
                        <xsl:sort collation="{$languages}" select="if (contains(@xml:lang, '-')=true()) then substring-before(@xml:lang, '-') else @xml:lang"/>
                        <xsl:for-each select="current-group()">
                            <xsl:sort lang="{current-grouping-key()}" select="normalize-space(.)"/>
                            <div class="tei-desc text">
                                <xsl:apply-templates select="."/>
                            </div>
                        </xsl:for-each>
                    </xsl:for-each-group>
            </div>
        </xsl:if>
        <xsl:if test="self::t:entryFree">
                <xsl:if test="t:desc[@type='abstract'] | t:desc[starts-with(@xml:id, 'abstract-en')] | t:note[@type='abstract']">
                    <div style="margin-bottom:1em;">
                        <h3>Abstract</h3>
                        <xsl:apply-templates select="t:desc[@type='abstract' or starts-with(@xml:id, 'abstract-en')][1] | t:note[@type='abstract']"/>
                    </div>
                </xsl:if>
                <xsl:if test="t:term">
                    <h3>Terms</h3>
                    <ul class="inline-list-boxes">
                        <xsl:for-each-group select="t:term" group-by=".">
                            <xsl:for-each select="current-group()">
                                <xsl:for-each-group select="." group-by="@xml:lang">
                                    <xsl:sort collation="{$mixed}" select="."/>
                                    <xsl:apply-templates select="." mode="list"/>
                                </xsl:for-each-group>    
                            </xsl:for-each>
                        </xsl:for-each-group>
                    </ul>
                </xsl:if>
                <br class="clearfix"/>
        </xsl:if>
        
        <!-- Notes -->
        <!-- NOTE: need to handle abstract notes -->
        <xsl:if test="t:note[not(@type='abstract')]">
            <xsl:variable name="rules" select="                 '&lt; prologue &lt; incipit &lt; explicit &lt;                  editions &lt; modernTranslation &lt;                  ancientVersion &lt; MSS'"/>
            <xsl:for-each-group select="t:note[not(@type='abstract')][exists(@type)]" group-by="@type">
                <xsl:sort select="current-grouping-key()" collation="http://saxon.sf.net/collation?rules={encode-for-uri($rules)};ignore-case=yes;ignore-modifiers=yes;ignore-symbols=yes)" order="ascending"/>
                <!--<xsl:sort select="current-grouping-key()" order="descending"/>-->
                <xsl:variable name="label">
                    <xsl:choose>
                        <xsl:when test="current-grouping-key() = 'MSS'">Syriac Manuscript Witnesses</xsl:when>
                        <xsl:when test="current-grouping-key() = 'incipit'">Incipit (Opening Line)</xsl:when>
                        <xsl:when test="current-grouping-key() = 'explicit'">Explicit (Closing Line)</xsl:when>
                        <xsl:when test="current-grouping-key() = 'ancientVersion'">Ancient Versions</xsl:when>
                        <xsl:when test="current-grouping-key() = 'modernTranslation'">Modern Translations</xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="current-grouping-key()"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <h3>
                    <xsl:value-of select="concat(upper-case(substring($label,1,1)),substring($label,2))"/>
                </h3>
                <div class="indent">
                    <xsl:for-each select="current-group()">
                        <xsl:sort select="if(current-grouping-key() = 'MSS') then substring-after(t:bibl/@xml:id,'-') = '' else if(current-grouping-key() = 'editions') then substring-after(t:bibl/@corresp,'-') = '' else if(@xml:lang) then local:expand-lang(@xml:lang,$label) else ." order="ascending"/>
                        <xsl:sort select="if(current-grouping-key() = 'MSS' and (substring-after(t:bibl/@xml:id,'-') castable as xs:integer)) then xs:integer(substring-after(t:bibl/@xml:id,'-')) else if(@xml:lang) then local:expand-lang(@xml:lang,$label) else ()" order="ascending"/>
                        <xsl:apply-templates select="self::*"/>
                    </xsl:for-each>
                </div>
            </xsl:for-each-group>
            <xsl:for-each select="t:note[not(exists(@type))]">
                <h3>Note</h3>
                <div class="left-padding bottom-padding">
                    <xsl:apply-templates/>
                </div>
            </xsl:for-each>
        </xsl:if>
        
        <xsl:if test="t:gloss">
            <h3>Gloss</h3>
            <div class="indent">
                <xsl:for-each-group select="t:gloss" group-by="@xml:lang">
                    <xsl:sort select="current-grouping-key()"/>
                    <h4>
                        <xsl:value-of select="local:translate-label(current-grouping-key(),0)"/>
                    </h4>
                    <xsl:for-each select="current-group()">
                        <xsl:apply-templates/>   
                        <xsl:if test="position() != last()">
                            <xsl:text>, </xsl:text>
                        </xsl:if>
                    </xsl:for-each>
                </xsl:for-each-group>                
            </div>
        </xsl:if>
       
        <div class="info-btns">  
            <xsl:variable name="status" select="string(/descendant-or-self::t:revisionDesc/@status)"/>
            <xsl:if test="$status != ''">
                <span class="rec-status {$status} btn btn-info">Status: <xsl:value-of select="$status"/></span>    
            </xsl:if>
            <!-- Button trigger corrections email modal -->
            <button class="btn btn-info" data-toggle="modal" data-target="#feedback">Corrections/Additions?</button> 
            <a href="#" class="btn btn-info" data-toggle="modal" data-target="#selection" data-ref="../documentation/faq.html" id="showSection">
                Is this record complete?
            </a>
        </div>
       
        <!-- Build see also -->
        <xsl:call-template name="link-icons-list">
            <xsl:with-param name="title">
                <xsl:value-of select="//t:teiHeader/descendant::t:titleStmt/t:title[1]"/>
            </xsl:with-param>
        </xsl:call-template>
        <xsl:call-template name="sources"/>
    </xsl:template>
    
    <xsl:template match="t:placeName | t:title | t:persName | t:term" mode="list">
        <xsl:variable name="nameID" select="concat('#',@xml:id)"/>
        <xsl:choose>
            <!-- Suppress depreciated names here -->
            <xsl:when test="/descendant-or-self::t:link[substring-before(@target,' ') = $nameID][contains(@target,'deprecation')]"/>
            <xsl:when test="@type='deprecated'"/>
            <!-- Output all other names -->
            <xsl:otherwise>
                <li dir="ltr">
                    <!-- write out the placename itself, with appropriate language and directionality indicia -->
                    <span class="tei-{local-name(.)}">
                        <xsl:sequence select="local:attributes(.)"/>
                        <!--<xsl:apply-templates select="." mode="plain"/>-->
                        <xsl:value-of select="normalize-space(.)"/>
                    </span>
                    <xsl:sequence select="local:add-footnotes(@source,ancestor::t:*[@xml:lang][1])"/>
                </li>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="t:persName | t:region | t:settlement | t:placeName | t:author | t:editor ">
        <xsl:if test="@role">
            <span class="srp-label">
                <xsl:value-of select="concat(upper-case(substring(@role,1,1)),substring(@role,2))"/>: 
            </span>
        </xsl:if>
        <xsl:choose>
            <xsl:when test="@ref">
                <xsl:choose>
                    <xsl:when test="string-length(@ref) &lt; 1">
                        <span>
                            <xsl:sequence select="local:attributes(.)"/>
                            <xsl:apply-templates/>
                        </span>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text> </xsl:text>
                        <a class="{local-name(.)}" href="{@ref}">
                            <xsl:sequence select="local:attributes(.)"/>
                            <xsl:apply-templates/>
                        </a>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <span class="tei-{local-name(.)}">
                    <xsl:sequence select="local:attributes(.)"/>
                    <xsl:apply-templates/>
                    <xsl:sequence select="local:add-footnotes(@source,@xml:lang)"/>
                </span>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="t:persName" mode="title">
        <span class="persName">
            <xsl:sequence select="local:attributes(.)"/>
            <xsl:apply-templates/>
        </span>
    </xsl:template>
    <xsl:template match="t:persName" mode="list">
        <xsl:variable name="nameID" select="concat('#',@xml:id)"/>
        <xsl:choose>
            <!-- Suppress depreciated names here -->
            <xsl:when test="/descendant-or-self::t:link[substring-before(@target,' ') = $nameID][contains(@target,'deprecation')]"/>
            <!-- Output all other names -->
            <xsl:otherwise>
                <span dir="ltr" class="label label-default pers-label">
                    <span class="persName">
                        <xsl:sequence select="local:attributes(.)"/>
                        <xsl:apply-templates/>
                    </span>
                    <xsl:sequence select="local:add-footnotes(@source,ancestor::t:*[@xml:lang][1])"/>
                </span>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="t:persName" mode="plain">
        <span class="persName">
            <xsl:sequence select="local:attributes(.)"/>
            <xsl:apply-templates/>
        </span>
    </xsl:template>
    <xsl:template match="t:roleName">
        <xsl:apply-templates mode="plain"/>
        <xsl:text> </xsl:text>
    </xsl:template>
    <xsl:template match="t:forename | t:addName">
        <xsl:if test="preceding-sibling::node()[1][not(matches(.,'$(\s|\(|\.|,)|\[|'))]">
            <xsl:text> </xsl:text>
        </xsl:if>
        <xsl:apply-templates mode="plain"/>
        <xsl:if test="following-sibling::node()[1][not(matches(.,'^(\s|\)|\.|,)|\]|;|:'))]">
            <xsl:text> </xsl:text>
        </xsl:if>
    </xsl:template>
    <xsl:template match="t:placeName | t:title" mode="list">
        <xsl:variable name="nameID" select="concat('#',@xml:id)"/>
        <xsl:choose>
            <!-- Suppress depreciated names here -->
            <xsl:when test="/descendant-or-self::t:link[substring-before(@target,' ') = $nameID][contains(@target,'deprecation')]"/>
            <!-- Output all other names -->
            <xsl:otherwise>
                <li dir="ltr">
                    <!-- write out the placename itself, with appropriate language and directionality indicia -->
                    <span class="placeName">
                        <xsl:sequence select="local:attributes(.)"/>
                        <xsl:apply-templates select="." mode="plain"/>
                    </span>
                    <xsl:sequence select="local:add-footnotes(@source,ancestor::t:*[@xml:lang][1])"/>
                </li>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="t:list">
        <ul>
            <xsl:apply-templates/>
        </ul>
    </xsl:template>
    <xsl:template match="t:item">
        <li>
            <xsl:apply-templates/>
        </li>
    </xsl:template>
    <xsl:template match="t:table">
        <table>
            <xsl:apply-templates/>
        </table>
    </xsl:template>
    <xsl:template match="t:row">
        <tr>
            <xsl:apply-templates/>
        </tr>
    </xsl:template>
    <xsl:template match="t:cell">
        <td>
            <xsl:apply-templates/>
        </td>
    </xsl:template>
    
    <!-- R -->
    <xsl:template match="t:relation">
        <!--
        <xsl:choose>
            <xsl:when test="ancestor::t:div[@uri]"/>
            <xsl:otherwise>
                <div>
                    <xsl:variable name="label">
                        <xsl:variable name="labelString">
                            <xsl:choose>
                                <xsl:when test="@name">
                                    <xsl:choose>
                                        <xsl:when test="contains(@name,':')">
                                            <xsl:value-of select="substring-after(@name,':')"/>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:value-of select="@name"/>
                                            <xsl:text>: </xsl:text>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:when>
                                <xsl:otherwise>
                                    Relationship
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:variable>
                        <xsl:value-of select="concat(upper-case(substring(concat(substring($labelString,1,1),replace(substring($labelString,2),'(\p{Lu})',concat(' ', '$1'))),1,1)),substring(concat(substring($labelString,1,1),replace(substring($labelString,2),'(\p{Lu})',concat(' ', '$1'))),2))"/>
                    </xsl:variable>
                    <span class="srp-label">
                        <xsl:value-of select="concat($label,': ')"/>
                    </span>
                    <xsl:choose>
                        <xsl:when test="@active">
                            <xsl:value-of select="@active"/>
                            <xsl:text> - </xsl:text>
                            <xsl:value-of select="@passive"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="@mutual"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </div>
            </xsl:otherwise>
        </xsl:choose>
        -->
    </xsl:template>
    
    <!-- T -->
    <xsl:template match="text()" mode="#all">
        <xsl:choose>
            <xsl:when test="ancestor-or-self::*[@xml:lang][1]/@xml:lang = 'syr'">
                <xsl:analyze-string select="." regex="\W">
                    <xsl:matching-substring>
                        <xsl:value-of select="."/>
                    </xsl:matching-substring>
                    <xsl:non-matching-substring>
                        <a href="https://sedra.bethmardutho.org/api/word/{.}.html" class="sedra">
                            <xsl:value-of select="." xml:space="preserve"/>
                        </a>
                    </xsl:non-matching-substring>
                </xsl:analyze-string>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="." xml:space="preserve"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="t:TEI">
        <xsl:param name="idno"/>
        <xsl:apply-templates select="//t:titleStmt" mode="huyoye-article">
            <xsl:with-param name="idno"><xsl:value-of select="$idno"/></xsl:with-param>
        </xsl:apply-templates>
        <xsl:apply-templates select="//t:text">
            <xsl:with-param name="idno"><xsl:value-of select="$idno"/></xsl:with-param>
        </xsl:apply-templates>
    </xsl:template>
    <xsl:template match="t:titleStmt" mode="huyoye-article">
        <xsl:param name="idno"/>
        <div class="article-header text-center">
            <xsl:apply-templates select="t:title | t:author"/>
        </div>
    </xsl:template>
    <xsl:template match="t:teiHeader" mode="#all">
        <xsl:param name="idno"/>
        <div class="panel panel-default">
            <div class="panel-heading">How to Cite this Electronic Edition</div>
            <div class="panel-body">
                <div id="citation-note">
                    <xsl:apply-templates select="//t:teiHeader/t:fileDesc/t:titleStmt" mode="cite-foot"/>
                </div>
            </div>
        </div>
    </xsl:template>
    <xsl:template match="t:text | t:front | t:back">
        <div class="section {concat('tei-',name(.))}">
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    <!-- Template for page titles -->
    <xsl:template match="t:srophe-title | t:titleStmt">
        <xsl:param name="idno"/>
        <xsl:call-template name="h1">
            <xsl:with-param name="idno"><xsl:value-of select="$idno"/></xsl:with-param>
        </xsl:call-template>
    </xsl:template>
    <xsl:template name="h1">
        <xsl:param name="idno"/>
        <xsl:variable name="id">
            <xsl:choose>
                <xsl:when test="$idno"><xsl:value-of select="$idno"/></xsl:when>
                <xsl:otherwise><xsl:value-of select="$resource-id"/></xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <div class="title">
            <h1>
                <!-- Format title, calls template in place-title-std.xsl -->
<!--                <xsl:call-template name="title"/>-->
            </h1>
            <!-- Call link icons (located in link-icons.xsl) -->
<!--            <xsl:call-template name="link-icons"/>   -->
            <!-- End Title -->
        </div>
        <!-- emit record URI and associated help links -->
        <div class="idno seriesStmt" style="margin:0; margin-top:.25em; margin-bottom: 1em; padding:1em; color: #999999;">
            <xsl:variable name="current-id">
                <xsl:variable name="idString" select="tokenize($id,'/')[last()]"/>
                <xsl:variable name="idSubstring">
                    <xsl:choose>
                        <xsl:when test="contains($idString,'-')">
                            <xsl:value-of select="substring-after($idString,'-')"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$idString"/>
                        </xsl:otherwise>
                    </xsl:choose>                    
                </xsl:variable>
                <xsl:choose>
                    <xsl:when test="$idSubstring  castable as xs:integer">
                        <xsl:value-of select="$idSubstring cast as xs:integer"/>
                    </xsl:when>
                    <xsl:otherwise>0</xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:variable name="next-id" select="$current-id + 1"/>
            <xsl:variable name="prev-id" select="$current-id - 1"/>
            <xsl:variable name="next-uri" select="replace($id,$current-id,string($next-id))"/>
            <xsl:variable name="prev-uri" select="replace($id,$current-id,string($prev-id))"/>                
            <small>
                <span class="uri">
                    <xsl:if test="starts-with($nav-base,'/exist/apps')">
                        <a href="{replace($prev-uri,$base-uri,$nav-base)}">
                            <span class="glyphicon glyphicon-backward" aria-hidden="true"/>
                        </a>
                    </xsl:if>
                    <xsl:text> </xsl:text>
                    <button type="button" class="btn btn-default btn-xs" id="idnoBtn" data-clipboard-action="copy" data-clipboard-target="#syriaca-id">
                        <span class="srp-label">URI</span>
                    </button>
                    <xsl:text> </xsl:text>
                    <span id="syriaca-id">
                        <xsl:value-of select="$id"/>
                    </span>
                    <script>
                        var clipboard = new Clipboard('#idnoBtn');
                        clipboard.on('success', function(e) {
                        console.log(e);
                        });
                        
                        clipboard.on('error', function(e) {
                        console.log(e);
                        });
                    </script>
                    <xsl:text> </xsl:text>
                    <xsl:if test="starts-with($nav-base,'/exist/apps')">
                        <a href="{replace($next-uri,$base-uri,$nav-base)}">
                            <span class="glyphicon glyphicon-forward" aria-hidden="true"/>
                        </a>
                    </xsl:if>
                </span>
                <xsl:if test="t:seriesStmt/t:biblScope/t:title">
                    <span class="series pull-right" style="margin-left:2em; padding-left:2em; display:inline">
                        <xsl:text>This page is an entry in </xsl:text>
                        <xsl:for-each select="distinct-values(t:seriesStmt/t:biblScope/t:title)">
                            <xsl:choose>
                                <xsl:when test=". = 'The Syriac Biographical Dictionary'"/>
                                <xsl:when test=". = 'A Guide to Syriac Authors'">
                                    <xsl:text> </xsl:text>
                                    <a href="/authors/index.html">
                                        <span class="syriaca-icon syriaca-authors" style="font-size:1.35em; vertical-align: middle;">
                                            <span class="path1"/>
                                            <span class="path2"/>
                                            <span class="path3"/>
                                            <span class="path4"/>
                                        </span>
                                        <span> A Guide to Syriac Authors</span>
                                    </a>
                                </xsl:when>
                                <xsl:when test=". = 'Qadishe: A Guide to the Syriac Saints'">
                                    <xsl:text> </xsl:text>
                                    <a href="/q/index.html">
                                        <span class="syriaca-icon syriaca-q" style="font-size:1.35em; vertical-align: middle;">
                                            <span class="path1"/>
                                            <span class="path2"/>
                                            <span class="path3"/>
                                            <span class="path4"/>
                                        </span>
                                        <span> Qadishe: A Guide to the Syriac Saints</span>
                                    </a>
                                </xsl:when>
                                <xsl:when test=". = 'Bibliotheca Hagiographica Syriaca Electronica'">
                                    <xsl:text> </xsl:text>
                                    <a href="/bhse/index.html">
                                        <span class="syriaca-icon syriaca-bhse" style="font-size:1.35em; vertical-align: middle;">
                                            <span class="path1"/>
                                            <span class="path2"/>
                                            <span class="path3"/>
                                            <span class="path4"/>
                                        </span>
                                        <span> Bibliotheca Hagiographica Syriaca Electronica</span>
                                    </a>
                                </xsl:when>
                                <xsl:when test=". = 'New Handbook of Syriac Literature'">
                                    <xsl:text> </xsl:text>
                                    <a href="/nhsl/index.html">
                                        <span class="syriaca-icon syriaca-nhsl" style="font-size:1.35em; vertical-align: middle;">
                                            <span class="path1"/>
                                            <span class="path2"/>
                                            <span class="path3"/>
                                            <span class="path4"/>
                                        </span>
                                        <span> New Handbook of Syriac Literature</span>
                                    </a>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="."/>
                                </xsl:otherwise>
                            </xsl:choose>
                            <xsl:if test="position() != last()"> and </xsl:if>
                        </xsl:for-each>    
                    </span>
                </xsl:if>
            </small>
        </div>
    </xsl:template>
    
    <xsl:template match="t:title">
        <xsl:choose>
            <xsl:when test="@type='main'">
                <h1>
                    <xsl:apply-templates/>
                </h1>
            </xsl:when>
            <xsl:when test="@type='sub'">
                <h2>
                    <xsl:apply-templates/>
                </h2>
            </xsl:when>
            <xsl:when test="@ref">
                <a href="{@ref}">
                    <xsl:sequence select="local:attributes(.)"/>
                    <xsl:apply-templates/>
                    [<xsl:value-of select="@ref"/>]
                </a>
            </xsl:when>
            <xsl:otherwise>
                <span>
                    <xsl:sequence select="local:attributes(.)"/>
                    <xsl:apply-templates/>
                </span>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
   
    <!-- S -->
    <!-- Template to print out confession section -->
    <xsl:template match="t:state[@type='confession']">
        <!-- WS:NOTE should probably change to static site for long term use, then don't have to keep old site around. -->
        <!--
        <xsl:choose>
            <xsl:when test="doc-available(concat($applicationPath,'/documentation/confessions.xml'))">
                <xsl:message>Confessions available</xsl:message>
                <xsl:variable name="confessions" select="document(concat($applicationPath,'/documentation/confessions.xml'))/descendant::t:body/t:list"/>
                <xsl:variable name="id" select="substring-after(@ref,'http://syriaca.org/taxonomy/')"/>
                <li>
                    <xsl:value-of select="$id"/>: 
                    <xsl:for-each select="$confessions//t:item[@xml:id = $id]/ancestor-or-self::*/t:label">
                        <xsl:value-of select="."/>
                    </xsl:for-each>
                </li> 
            </xsl:when>
            <xsl:otherwise>
                <xsl:message>Confessions NOT available</xsl:message>
            </xsl:otherwise>
        </xsl:choose>
        -->
        <!-- 
            <xsl:when test="doc-available($biblfilepath)">
            
        <xsl:if test="doc-available(concat($applicationPath,'/documentation/confessions.xml'))">
            <xsl:variable name="confessions" select="document(concat($applicationPath,'/documentation/confessions.xml'))//t:body/t:list"/>
            <xsl:variable name="id" select="substring-after(@ref,'#')"/>
            <li>
                <xsl:value-of select="$id"/>: 
                <xsl:for-each select="$confessions//t:item[@xml:id = $id]/ancestor-or-self::*/t:label">
                    <xsl:value-of select="."/>
                </xsl:for-each>
            </li>  
        </xsl:if>
        -->
    </xsl:template>
    <xsl:template match="t:state | t:birth | t:death | t:floruit | t:sex | t:gender | t:langKnowledge">
       <div class="person-details">
           <h3>
               <xsl:choose>
                   <xsl:when test="self::t:birth">Birth</xsl:when>
                   <xsl:when test="self::t:death">Death</xsl:when>
                   <xsl:when test="self::t:floruit">Floruit</xsl:when>
                   <xsl:when test="self::t:sex">Sex</xsl:when>
                   <xsl:when test="self::t:gender">Sex</xsl:when>
                   <xsl:when test="self::t:langKnowledge">Language Knowledge</xsl:when>
                   <xsl:when test="@role">
                       <xsl:value-of select="concat(upper-case(substring(@role,1,1)),substring(@role,2))"/>
                   </xsl:when>
                   <xsl:otherwise>
                       <xsl:value-of select="concat(upper-case(substring(@type,1,1)),substring(@type,2))"/>      
                   </xsl:otherwise>
               </xsl:choose>
           </h3>
           <div class="indent">
           <xsl:choose>
               <xsl:when test="count(t:date) &gt; 1">
                   <xsl:for-each select="t:date">
                       <xsl:apply-templates/>
                       <xsl:sequence select="local:add-footnotes(@source,.)"/>
                       <xsl:if test="position() != last()"> or </xsl:if>
                   </xsl:for-each>
               </xsl:when>
               <xsl:otherwise>
                   <xsl:apply-templates mode="plain"/>
               </xsl:otherwise>
           </xsl:choose>
           <xsl:sequence select="local:add-footnotes(@source,.)"/>
           </div>    
       </div>
    </xsl:template>
    <xsl:template match="t:sources">
        <xsl:call-template name="sources"/>
    </xsl:template>
    <!-- Named template for sources calls bibliography.xsl -->
    <xsl:template name="sources">
        <xsl:param name="node"/>
        <div class="content-block">
            <!-- Sources -->
            <div id="sources">
                <h3>Works Cited</h3>
                <p>
                    <small>Any information without attribution has been created following the Syriaca.org <a href="http://syriaca.org/documentation/">editorial guidelines</a>.</small>
                </p>
                <ul>
                    <!-- Bibliography elements are processed by bibliography.xsl -->
                    <!-- Old works model 
                    <xsl:choose>
                        <xsl:when test="t:bibl[@type='lawd:Citation']">
                            <xsl:apply-templates select="t:bibl[@type='lawd:Citation']" mode="footnote"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates select="t:bibl" mode="footnote"/>
                        </xsl:otherwise>
                    </xsl:choose>
                    -->
                    <xsl:for-each select="t:bibl">
                       <xsl:sort select="xs:integer(translate(substring-after(@xml:id,'-'),translate(substring-after(@xml:id,'-'), '0123456789', ''), ''))"/>
                        <xsl:sort select="
                        if (contains(@xml:id, '-') and normalize-space(substring-after(@xml:id, '-')) != '') 
                        then number(substring-after(@xml:id, '-')) 
                        else 0"/>
                        <xsl:apply-templates select="." mode="footnote"/>
                    </xsl:for-each>
                </ul>
            </div>
        </div>
    </xsl:template>
    
    <!-- W -->
    <xsl:template match="t:work-toc">
        <xsl:if test="//t:bibl[exists(@type)][@type != 'lawd:Citation']">
            <div class="jump-menu">
                <span class="jump-menu srp-label">Jump to: </span> 
                <xsl:for-each-group select="//t:bibl[exists(@type)][@type != 'lawd:Citation']" group-by="@type">
                    <xsl:sort select="local:bibl-type-order(current-grouping-key())" order="ascending"/>
                    <xsl:variable name="label">
                        <xsl:variable name="l" select="local:translate-label(current-grouping-key(),count(current-group()))"/>
                        <xsl:choose>
                            <xsl:when test="$l != ''">
                                <xsl:value-of select="$l"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="current-grouping-key()"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <a href="#bibl{$label}" class="btn btn-default">
                        <xsl:value-of select="concat(upper-case(substring($label,1,1)),substring($label,2))"/>
                    </a> 
                </xsl:for-each-group>            
            </div>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="t:graphic">
        <span class="tei-graphic">
            <xsl:variable name="url">
                <xsl:choose>
                    <xsl:when test="starts-with(@url,$base-uri)">
                        <xsl:value-of select="replace(@url, $base-uri, 'https://github.com/Beth-Mardutho/hugoye-data/raw/master')"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="@url"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:variable name="width">
                <xsl:choose>
                    <xsl:when test="@width">
                        <xsl:value-of select="@width"/>
                    </xsl:when>
                    <xsl:otherwise>80%</xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <img src="{$url}" class="{string(@rend)}" width="{$width}"/>
        </span>
    </xsl:template>
    <xsl:template match="t:caption">
        <span class="tei-caption {if(@rend) then string(@rend) else ()}">
            <xsl:apply-templates/>
        </span>
    </xsl:template>
    <xsl:template match="t:ref">
        <a href="{@target}">
            <xsl:if test="@type='noteAnchor'">
                <xsl:attribute name="class">note-anchor footnote-refs</xsl:attribute>
            </xsl:if>
            <xsl:apply-templates/>
        </a>
    </xsl:template>
    <xsl:template match="@xml:id">
        <xsl:attribute name="id" select="."/>
    </xsl:template>
    <xsl:template match="t:hi" mode="#all">
        <xsl:call-template name="rend"/>
    </xsl:template>
    <xsl:template match="t:abbr">
        <xsl:if test="preceding-sibling::node()[1][not(matches(.,'$(\s|\(|\.|,)|\[|'))]">
            <xsl:text> </xsl:text>
        </xsl:if>
        <xsl:apply-templates/>
        <xsl:if test="following-sibling::node()[1][not(matches(.,'^(\s|\)|\.|,)|\]|;|:'))]">
            <xsl:text> </xsl:text>
        </xsl:if>
    </xsl:template>
    
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     Special Gazetteer templates 
    ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <!-- Named template to handle nested confessions -->
    <xsl:template name="confessions">
        <xsl:param name="confessionsDoc"/>
        <!-- Variable stores all confessions from confessions.xml -->
        <xsl:variable name="confessions" select="$confessionsDoc/descendant::t:list"/>
        <xsl:variable name="place-data" select="."/>
        <!-- Variable to store the value of the confessions of current place-->
        <xsl:variable name="current-confessions">
            <xsl:for-each select="//t:state[@type='confession']">
                <xsl:variable name="id" select="substring-after(@ref,'http://syriaca.org/taxonomy/')"/>
                <!-- outputs current confessions as a space seperated list -->
                <xsl:value-of select="concat($id,' ')"/>
            </xsl:for-each>
        </xsl:variable>
        <!-- Works through the tree structure in the confessions.xml to output only the relevant confessions -->
        <xsl:for-each select="$confessionsDoc/descendant::t:list[1]">
            <ul>
                <!-- Checks for top level confessions that may have a match or a descendant with a match, supresses any that do not -->
                <xsl:if test="descendant-or-self::t:item[contains($current-confessions,@xml:id)]">
                    <!-- Goes through each item to check for a match or a child match -->
                    <xsl:for-each select="t:item">
                        <xsl:if test="descendant-or-self::t:item[contains($current-confessions,@xml:id)]">
                            <!-- output current level -->
                            <li>
                                <!-- print label -->
                                <xsl:apply-templates select="t:label" mode="confessions"/>
                                <!-- build dates based on attestation information -->
                                <xsl:call-template name="confession-dates">
                                    <xsl:with-param name="place-data" select="$place-data"/>
                                    <xsl:with-param name="confession-id" select="@xml:id"/>
                                </xsl:call-template>
                                <!-- check next level -->
                                <xsl:if test="descendant::t:item[contains($current-confessions,@xml:id)]">
                                    <ul>
                                        <xsl:for-each select="child::*/t:item">
                                            <xsl:if test="descendant-or-self::t:item[contains($current-confessions,@xml:id)]">
                                                <li>
                                                    <xsl:apply-templates select="t:label" mode="confessions"/>
                                                    <!-- build dates based on attestation information -->
                                                    <xsl:call-template name="confession-dates">
                                                        <xsl:with-param name="place-data" select="$place-data"/>
                                                        <xsl:with-param name="confession-id" select="@xml:id"/>
                                                    </xsl:call-template>
                                                    <xsl:if test="descendant::t:item[contains($current-confessions,@xml:id)]">
                                                        <ul>
                                                            <xsl:for-each select="child::*/t:item">
                                                                <xsl:if test="descendant-or-self::t:item[contains($current-confessions,@xml:id)]">
                                                                    <li>
                                                                        <xsl:apply-templates select="t:label" mode="confessions"/>
                                                                        <!-- build dates based on attestation information -->
                                                                        <xsl:call-template name="confession-dates">
                                                                            <xsl:with-param name="place-data" select="$place-data"/>
                                                                            <xsl:with-param name="confession-id" select="@xml:id"/>
                                                                        </xsl:call-template>
                                                                        <xsl:if test="descendant::t:item[contains($current-confessions,@xml:id)]">
                                                                            <ul>
                                                                                <xsl:for-each select="child::*/t:item">
                                                                                    <xsl:if test="descendant-or-self::t:item[contains($current-confessions,@xml:id)]">
                                                                                        <li>
                                                                                            <xsl:apply-templates select="t:label" mode="confessions"/>
                                                                                            <!-- build dates based on attestation information -->
                                                                                            <xsl:call-template name="confession-dates">
                                                                                                <xsl:with-param name="place-data" select="$place-data"/>
                                                                                                <xsl:with-param name="confession-id" select="@xml:id"/>
                                                                                            </xsl:call-template>
                                                                                        </li>
                                                                                    </xsl:if>
                                                                                </xsl:for-each>
                                                                            </ul>
                                                                        </xsl:if>
                                                                    </li>
                                                                </xsl:if>
                                                            </xsl:for-each>
                                                        </ul>
                                                    </xsl:if>
                                                </li>
                                            </xsl:if>
                                        </xsl:for-each>
                                    </ul>
                                </xsl:if>
                            </li>
                        </xsl:if>
                    </xsl:for-each>
                </xsl:if>
            </ul>
        </xsl:for-each>
    </xsl:template>
    
    <!-- Create labels for confessions -->
    <xsl:template match="t:label" mode="confessions">
        <xsl:value-of select="."/>
    </xsl:template>
    
    <!-- Named template to build confession dates based on attestation dates -->
    <xsl:template name="confession-dates">
        <!-- param passes place data for processing -->
        <xsl:param name="place-data"/>
        <!-- confession id -->
        <xsl:param name="confession-id"/>
        <!-- find confessions in place data using confession-id -->
        <xsl:choose>
            <xsl:when test="$place-data//t:state[@type='confession' and substring-after(@ref,'#') = $confession-id]">
                <xsl:variable name="child-id" select="string-join(descendant-or-self::t:item/@xml:id,' ')"/>
                <xsl:for-each select="$place-data//t:state[@type='confession' and substring-after(@ref,'#') = $confession-id]">
                    <!-- Build ref id to find attestations -->
                    <xsl:variable name="ref-id" select="concat('#',@xml:id)"/>
                    <!-- Find attestations with matching confession-id in link/@target  -->
                    <xsl:choose>
                        <xsl:when test="//t:event[@type='attestation' and child::*[contains(@target,$ref-id)] ]">
                            <!-- If there is a match process dates -->
                            (<xsl:for-each select="//t:event[@type='attestation' and t:link[contains(@target,$ref-id)] ]">
                                <!-- Sort dates -->
                                <xsl:sort select="if(exists(@notBefore)) then @notBefore else @when"/>
                                <xsl:choose>
                                    <!-- process @when dates use, local:trim-date function to trim 0 from dates-->
                                    <xsl:when test="./@when">
                                        <xsl:choose>
                                            <xsl:when test="position() = 1">attested as early as <xsl:value-of select="local:trim-date(@when)"/>
                                            </xsl:when>
                                            <xsl:when test="position()=last()">, as late as <xsl:value-of select="local:trim-date(@when)"/>
                                            </xsl:when>
                                            <xsl:otherwise/>
                                        </xsl:choose>
                                    </xsl:when>
                                    <!-- process @notBefore dates -->
                                    <xsl:when test="./@notBefore">
                                        <xsl:choose>
                                            <xsl:when test="position() = 1">attested around <xsl:value-of select="local:trim-date(@notBefore)"/>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <xsl:if test="preceding-sibling::*">, </xsl:if>as late as <xsl:value-of select="local:trim-date(@notBefore)"/>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                    </xsl:when>
                                    <!-- process @notAfter dates -->
                                    <xsl:when test="./@notAfter">
                                        <xsl:if test="./@notBefore">, </xsl:if>as late as <xsl:value-of select="local:trim-date(@notAfter)"/>
                                    </xsl:when>
                                    <xsl:otherwise/>
                                </xsl:choose>
                            </xsl:for-each>
                            <xsl:if test="count(//t:event[@type='attestation' and child::*[contains(@target,$ref-id)] ]) = 1">
                                <xsl:choose>
                                    <xsl:when test="//t:event[@type='attestation' and child::*[contains(@target,$ref-id)]][@notBefore] or //t:event[@type='attestation' and child::*[contains(@target,$ref-id)]][@when]">
                                        <xsl:variable name="end-date-list">
                                            <xsl:for-each select="//t:state[@type='confession' and contains($child-id,substring-after(@ref,'#'))]">
                                                <xsl:variable name="confession-id" select="substring-after(@ref,'#')"/>
                                                <xsl:variable name="ref-id" select="concat('#',@xml:id)"/>
                                                <!-- Checks for attestations that reference any children of the current confession -->
                                                <xsl:for-each select="//t:event[@type='attestation' and t:link[contains(@target,$ref-id)]]">
                                                    <xsl:if test="@when or @notAfter">
                                                        <xsl:variable name="date" select="@when | @notAfter"/>
                                                        <li date="{string($date)}">as late as <xsl:value-of select="local:trim-date($date)"/>
                                                        </li>
                                                    </xsl:if>
                                                </xsl:for-each>
                                            </xsl:for-each>
                                        </xsl:variable>
                                        <xsl:variable name="end-date">
                                            <xsl:for-each select="$end-date-list/child::*">
                                                <!-- sorts list by date and outputs first date -->
                                                <xsl:sort select="@date"/>
                                                <xsl:if test="position()=last()">
                                                    <xsl:value-of select="."/>
                                                </xsl:if>
                                            </xsl:for-each>
                                        </xsl:variable>
                                        <xsl:value-of select="concat(', ',$end-date)"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:variable name="start-date-list">
                                            <xsl:for-each select="//t:state[@type='confession' and contains($child-id,substring-after(@ref,'#'))]">
                                                <xsl:variable name="confession-id" select="substring-after(@ref,'#')"/>
                                                <xsl:variable name="ref-id" select="concat('#',@xml:id)"/>
                                                <!-- Checks for attestations that reference any children of the current confession -->
                                                <xsl:for-each select="//t:event[@type='attestation' and t:link[contains(@target,$ref-id)]]">
                                                    <xsl:if test="@when or @notBefore">
                                                        <xsl:variable name="date" select="@when |@notBefore"/>
                                                        <li date="{string($date)}">
                                                            <xsl:choose>
                                                                <!-- process @when dates use, local:trim-date function to trim 0 from dates-->
                                                                <xsl:when test="./@when">attested as early as <xsl:value-of select="local:trim-date(@when)"/>
                                                                </xsl:when>
                                                                <!-- process @notBefore dates -->
                                                                <xsl:when test="./@notBefore">attested around <xsl:value-of select="local:trim-date(@notBefore)"/>
                                                                </xsl:when>
                                                            </xsl:choose>
                                                        </li>
                                                    </xsl:if>
                                                </xsl:for-each>
                                            </xsl:for-each>
                                        </xsl:variable>
                                        <xsl:variable name="start-date">
                                            <xsl:for-each select="$start-date-list/child::*">
                                                <!-- sorts list by date and outputs first date -->
                                                <xsl:sort select="@date"/>
                                                <xsl:if test="position()=1">
                                                    <xsl:value-of select="."/>
                                                </xsl:if>
                                            </xsl:for-each>
                                        </xsl:variable>
                                        <xsl:value-of select="concat($start-date,', ')"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:if>)
                        </xsl:when>
                        <!-- If not attestation information -->
                        <xsl:otherwise> 
                            (no attestations yet recorded)
                        </xsl:otherwise>
                    </xsl:choose>
                    <!-- Add refs if they exist -->    
                    <xsl:sequence select="local:add-footnotes(@source,'eng')"/>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise> 
                <!-- Checks for children with of current confession by checking confessions.xml information -->
                <xsl:variable name="child-id" select="string-join(descendant-or-self::t:item/@xml:id,' ')"/>
                <!-- Checks for existing children of current confession by matching against child-id -->
                <xsl:variable name="start-date-list">
                    <xsl:for-each select="$place-data//t:state[@type='confession' and contains($child-id,substring-after(@ref,'#'))]">
                        <xsl:variable name="confession-id" select="substring-after(@ref,'#')"/>
                        <xsl:variable name="ref-id" select="concat('#',@xml:id)"/>
                        <!-- Checks for attestations that reference any children of the current confession -->
                        <xsl:for-each select="//t:event[@type='attestation' and t:link[contains(@target,$ref-id)]]">
                            <xsl:if test="@when or @notBefore">
                                <xsl:variable name="date" select="@when |@notBefore"/>
                                <li date="{string($date)}">
                                    <xsl:choose>
                                        <!-- process @when dates use, local:trim-date function to trim 0 from dates-->
                                        <xsl:when test="./@when">attested as early as <xsl:value-of select="local:trim-date(@when)"/>
                                        </xsl:when>
                                        <!-- process @notBefore dates -->
                                        <xsl:when test="./@notBefore">attested around <xsl:value-of select="local:trim-date(@notBefore)"/>
                                        </xsl:when>
                                    </xsl:choose>
                                </li>
                            </xsl:if>
                        </xsl:for-each>
                    </xsl:for-each>
                </xsl:variable>
                <xsl:variable name="start-date">
                    <xsl:for-each select="$start-date-list/child::*">
                        <!-- sorts list by date and outputs first date -->
                        <xsl:sort select="@date"/>
                        <xsl:if test="position()=1">
                            <xsl:value-of select="."/>
                        </xsl:if>
                    </xsl:for-each>
                </xsl:variable>
                
                <!-- Looks for end dates -->
                <xsl:variable name="end-date-list">
                    <xsl:for-each select="$place-data//t:state[@type='confession' and contains($child-id,substring-after(@ref,'#'))]">
                        <xsl:variable name="confession-id" select="substring-after(@ref,'#')"/>
                        <xsl:variable name="ref-id" select="concat('#',@xml:id)"/>
                        <!-- Checks for attestations that reference any children of the current confession -->
                        <xsl:for-each select="//t:event[@type='attestation' and t:link[contains(@target,$ref-id)]]">
                            <xsl:if test="@when or @notAfter">
                                <xsl:variable name="date" select="@when | @notAfter"/>
                                <li date="{string($date)}">as late as <xsl:value-of select="local:trim-date($date)"/>
                                </li>
                            </xsl:if>
                        </xsl:for-each>
                    </xsl:for-each>
                </xsl:variable>
                <xsl:variable name="end-date">
                    <xsl:for-each select="$end-date-list/child::*">
                        <!-- sorts list by date and outputs first date -->
                        <xsl:sort select="@date"/>
                        <xsl:if test="position()=last()">
                            <xsl:value-of select="."/>
                        </xsl:if>
                    </xsl:for-each>
                </xsl:variable>
                
                <!-- Putting start and end dates together -->
                <xsl:if test="(string-length($start-date) &gt; 1) or string-length($end-date) &gt;1">
                    (<xsl:if test="string-length($start-date) &gt; 1">
                        <xsl:value-of select="$start-date"/>
                    </xsl:if>
                    <xsl:if test="string-length($end-date) &gt;1">
                        <xsl:if test="string-length($start-date) &gt; 1">, </xsl:if>
                        <xsl:value-of select="$end-date"/>
                    </xsl:if>)
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template> 
        
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
        Related Places templates used by places.xqm only
    ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:relation" mode="related-place">
        <xsl:variable name="name-string">
            <xsl:choose>
                <!-- Differentiates between resided and other name attributes -->
                <xsl:when test="@name='resided'">
                    <xsl:value-of select="@name"/> in 
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="replace(@name,'-',' ')"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="currentPlace" select="//t:div[@id='heading']/t:placeName[1]/text()"/>
        <xsl:choose>
            <xsl:when test="@id=concat('#place-',$resource-id)"/>
            <xsl:when test="@varient='active'">
                <li>
                    <a href="{concat('/place/',@id,'.html')}">
                        <xsl:value-of select="t:placeName"/>
                    </a>
                    <xsl:text> </xsl:text>
                    <xsl:value-of select="$name-string"/>
                    <xsl:text> </xsl:text>
                    <xsl:value-of select="$currentPlace"/>
                    <xsl:text> (</xsl:text>
                    <xsl:value-of select="local:do-dates(.)"/>
                    <xsl:text>) </xsl:text>
                    <!-- If footnotes exist call function do-refs pass footnotes and language variables to function -->
                    <xsl:sequence select="local:add-footnotes(@source,.)"/>
                </li>
            </xsl:when>
            <xsl:when test="@varient='passive'">
                <li>
                    <xsl:value-of select="$currentPlace"/>
                    <xsl:text> </xsl:text>
                    <xsl:value-of select="$name-string"/>
                    <xsl:text> </xsl:text>
                    <a href="{concat('/place/',@id,'.html')}">
                        <xsl:value-of select="t:placeName"/>
                    </a>
                    <xsl:text> (</xsl:text>
                    <xsl:value-of select="local:do-dates(.)"/>
                    <xsl:text>) </xsl:text>
                    <!-- If footnotes exist call function do-refs pass footnotes and language variables to function -->
                    <xsl:sequence select="local:add-footnotes(@source,.)"/>
                </li>
            </xsl:when>
            <xsl:when test="@varient='mutual'">
                <li>
                    <!--                    <xsl:value-of select="$currentPlace"/> -->
                    <!-- Need to test number of groups and output only the first two -->
                    <xsl:variable name="group1-count">
                        <xsl:for-each-group select="t:mutual" group-by="@type">
                            <xsl:sort select="count(current-group()/child::*)" order="descending"/>
                            <xsl:if test="position()=1">
                                <xsl:value-of select="count(current-group()/child::*)"/>
                            </xsl:if>
                        </xsl:for-each-group>
                    </xsl:variable>
                    <xsl:variable name="group2-count">
                        <xsl:for-each-group select="t:mutual" group-by="@type">
                            <xsl:sort select="count(current-group()/child::*)" order="descending"/>
                            <xsl:if test="position()=2">
                                <xsl:value-of select="count(current-group()/child::*)"/>
                            </xsl:if>
                        </xsl:for-each-group>
                    </xsl:variable>
                    <xsl:variable name="total-count" select="count(t:mutual/child::*)"/>
                    <xsl:for-each-group select="t:mutual" group-by="@type">
                        <xsl:sort select="count(current-group()/child::*)" order="descending"/>
                        <xsl:variable name="plural-type">
                            <xsl:choose>
                                <xsl:when test="current-grouping-key() = 'building'">Buildings</xsl:when>
                                <xsl:when test="current-grouping-key() = 'church'">Churches</xsl:when>
                                <xsl:when test="current-grouping-key() = 'diocese'">Dioceses</xsl:when>
                                <xsl:when test="current-grouping-key() = 'fortification'">Fortifications</xsl:when>
                                <xsl:when test="current-grouping-key() = 'island'">Islands</xsl:when>
                                <xsl:when test="current-grouping-key() = 'madrasa'">Madrasas</xsl:when>
                                <xsl:when test="current-grouping-key() = 'monastery'">Monasteries</xsl:when>
                                <xsl:when test="current-grouping-key() = 'mosque'">Mosques</xsl:when>
                                <xsl:when test="current-grouping-key() = 'mountain'">Mountains</xsl:when>
                                <xsl:when test="current-grouping-key() = 'open-water'">Bodies of open-water</xsl:when>
                                <xsl:when test="current-grouping-key() = 'parish'">Parishes</xsl:when>
                                <xsl:when test="current-grouping-key() = 'province'">Provinces</xsl:when>
                                <xsl:when test="current-grouping-key() = 'quarter'">Quarters</xsl:when>
                                <xsl:when test="current-grouping-key() = 'region'">Regions</xsl:when>
                                <xsl:when test="current-grouping-key() = 'river'">Rivers</xsl:when>
                                <xsl:when test="current-grouping-key() = 'settlement'">Settlements</xsl:when>
                                <xsl:when test="current-grouping-key() = 'state'">States</xsl:when>
                                <xsl:when test="current-grouping-key() = 'synagogue'">Synagogues</xsl:when>
                                <xsl:when test="current-grouping-key() = 'temple'">Temples</xsl:when>
                                <xsl:when test="current-grouping-key() = 'unknown'">Unknown</xsl:when>
                            </xsl:choose>
                        </xsl:variable>
                        <xsl:variable name="type" select="concat(upper-case(substring(current-grouping-key(),1,1)),substring(current-grouping-key(),2))"/>
                        <xsl:choose>
                            <xsl:when test="position()=1">
                                <xsl:value-of select="count(current-group()/child::*)"/>
                                <xsl:text> </xsl:text>
                                <xsl:choose>
                                    <xsl:when test="count(current-group()/child::*) &gt; 1">
                                        <xsl:value-of select="$plural-type"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="$type"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                                <xsl:text> </xsl:text>
                            </xsl:when>
                            <xsl:when test="position() = 2">
                                <xsl:choose>
                                    <xsl:when test="last() &gt; 2">, </xsl:when>
                                    <xsl:when test="last() = 2"> and </xsl:when>
                                </xsl:choose>
                                <xsl:value-of select="count(current-group()/child::*)"/>
                                <xsl:text> </xsl:text>
                                <xsl:choose>
                                    <xsl:when test="count(current-group()/child::*) &gt; 1">
                                        <xsl:value-of select="$plural-type"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="$type"/>
                                    </xsl:otherwise>
                                </xsl:choose>,
                                <!-- Need to count remaining items, this is not correct just place holder -->
                                <xsl:if test="last() &gt; 2"> and 
                                    <xsl:value-of select="$total-count - ($group1-count + $group2-count)"/> 
                                    other places, 
                                </xsl:if>
                            </xsl:when>
                            <xsl:otherwise/>
                        </xsl:choose>
                    </xsl:for-each-group>
                    <xsl:text> </xsl:text>
                    <xsl:value-of select="replace(child::*[1]/@name,'-',' ')"/>
                    with '<xsl:value-of select="$currentPlace"/>'
                    <xsl:text> (</xsl:text>
                    <xsl:value-of select="local:do-dates(child::*[1])"/>
                    <xsl:text>) </xsl:text>
                    <!-- If footnotes exist call function do-refs pass footnotes and language variables to function -->
                    <xsl:if test="child::*[1]/@source">
                        <xsl:sequence select="local:add-footnotes(child::*[1]/@source,.)"/>
                    </xsl:if>
                    <!-- toggle to full list, grouped by type -->
                    <a class="togglelink btn-link" data-toggle="collapse" data-target="#relatedlist" data-text-swap="(hide list)">(see list)</a>
                    <dl class="collapse" id="relatedlist">
                        <xsl:for-each-group select="t:mutual" group-by="@type">
                            <xsl:sort select="count(current-group()/child::*)" order="descending"/>
                            <xsl:variable name="plural-type">
                                <xsl:choose>
                                    <xsl:when test="current-grouping-key() = 'building'">Buildings</xsl:when>
                                    <xsl:when test="current-grouping-key() = 'church'">Churches</xsl:when>
                                    <xsl:when test="current-grouping-key() = 'diocese'">Dioceses</xsl:when>
                                    <xsl:when test="current-grouping-key() = 'fortification'">Fortifications</xsl:when>
                                    <xsl:when test="current-grouping-key() = 'island'">Islands</xsl:when>
                                    <xsl:when test="current-grouping-key() = 'madrasa'">Madrasas</xsl:when>
                                    <xsl:when test="current-grouping-key() = 'monastery'">Monasteries</xsl:when>
                                    <xsl:when test="current-grouping-key() = 'mosque'">Mosques</xsl:when>
                                    <xsl:when test="current-grouping-key() = 'mountain'">Mountains</xsl:when>
                                    <xsl:when test="current-grouping-key() = 'open-water'">Bodies of open-water</xsl:when>
                                    <xsl:when test="current-grouping-key() = 'parish'">Parishes</xsl:when>
                                    <xsl:when test="current-grouping-key() = 'province'">Provinces</xsl:when>
                                    <xsl:when test="current-grouping-key() = 'quarter'">Quarters</xsl:when>
                                    <xsl:when test="current-grouping-key() = 'region'">Regions</xsl:when>
                                    <xsl:when test="current-grouping-key() = 'river'">Rivers</xsl:when>
                                    <xsl:when test="current-grouping-key() = 'settlement'">Settlements</xsl:when>
                                    <xsl:when test="current-grouping-key() = 'state'">States</xsl:when>
                                    <xsl:when test="current-grouping-key() = 'synagogue'">Synagogues</xsl:when>
                                    <xsl:when test="current-grouping-key() = 'temple'">Temples</xsl:when>
                                    <xsl:when test="current-grouping-key() = 'unknown'">Unknown</xsl:when>
                                </xsl:choose>
                            </xsl:variable>
                            <dt>
                                <xsl:value-of select="$plural-type"/>
                            </dt>
                            <xsl:for-each select="current-group()">
                                <dd>
                                    <a href="{concat('/place/',@id,'.html')}">
                                        <xsl:value-of select="t:placeName"/>
                                        <xsl:value-of select="concat(' (',string(@type),', place/',@id,')')"/>
                                    </a>
                                </dd>
                            </xsl:for-each>
                        </xsl:for-each-group>
                    </dl>
                </li>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="t:relation" mode="relation">
        <a href="{@uri}">
            <xsl:choose>
                <xsl:when test="child::*/t:place">
                    <xsl:value-of select="child::*/t:place/t:placeName"/>
                </xsl:when>
                <xsl:when test="contains(child::*/t:title,' — ')">
                    <xsl:value-of select="substring-before(child::*[1]/t:title,' — ')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="child::*/t:title"/>
                </xsl:otherwise>
            </xsl:choose>
        </a>
        <xsl:if test="preceding-sibling::*">,</xsl:if>
        <!--  If footnotes exist call function do-refs pass footnotes and language variables to function -->
        <xsl:sequence select="local:add-footnotes(@source,.)"/>
    </xsl:template>
    
</xsl:stylesheet>
