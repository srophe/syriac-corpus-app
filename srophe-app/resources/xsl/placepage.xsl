<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:s="http://syriaca.org" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:saxon="http://saxon.sf.net/" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:local="http://syriaca.org/ns" xmlns:x="http://www.w3.org/1999/xhtml" exclude-result-prefixes="xs t s saxon" version="2.0">

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
       placepage.xsl
       
       This XSLT transforms places xml (TEI) files to HTML. It builds the
       guts of the website, in effect.
       
       parameters:
       
       assumptions and dependencies:
        + transform has been tested with Saxon PE 9.4.0.6 on tei generated from /srophe/modules/record.xql
        
       code by: 
        + Tom Elliott (http://www.paregorios.org) 
          for the Institute for the Study of the Ancient World, New York
          University, under contract to Vanderbilt University for the
          NEH-funded Syriac Reference Portal project.
        + Edited by Winona Salesky for use with eXist-db
          
       funding provided by:
        + National Endowment for the Humanities (http://www.neh.gov). Any 
          views, findings, conclusions, or recommendations expressed in 
          this code do not necessarily reflect those of the National 
          Endowment for the Humanities.
       
       ================================================================== -->
 <!-- =================================================================== -->
 <!-- import component stylesheets for HTML page portions -->
 <!-- =================================================================== -->
    <xsl:import href="place-title-std.xsl"/>
    <xsl:import href="helper-functions.xsl"/>
    <xsl:import href="link-icons.xsl"/>
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
 <!--  sourcedir: where to look for XML files to summarize/link to -->
 <!--  description: a meta description for the HTML page we will output -->
 <!--  name-app: name of the application (for use in head/title) -->
 <!--  name-page-short: short name of the page (for use in head/title) -->
 <!--  colquery: constructed variable with query for collection fn. -->
 <!-- =================================================================== -->
    <xsl:param name="normalization">NFKC</xsl:param>
    <!-- NOTE: Change to eXist xml -->
    <xsl:param name="xmlbase">/db/apps/srophe/data/places/tei/xml/</xsl:param>
    <xsl:param name="editoruriprefix">http://syriaca.org/editors.xml#</xsl:param>
    <xsl:variable name="editorssourcedoc">/db/apps/srophe/data/editors/tei/editors.xml</xsl:variable>
    <xsl:param name="uribase">http://syriaca.org/place/</xsl:param>
    <xsl:variable name="placenum" select="substring-after(/descendant::*/t:place[1]/@xml:id,'place-')"/>
 <!-- =================================================================== -->
 <!-- TEMPLATES -->
 <!-- =================================================================== -->


 <!-- ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||| -->
 <!-- |||| Root template matches tei root -->
 <!-- ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||| -->
    <xsl:template match="/">
        <div class="row-fluid">
            <div class="span12">
    <!-- Start Title and link icons -->
                <div class="row-fluid title">
                    <h2 class="span8">
                        <!-- Format title, calls template in place-title-std.xsl -->
                        <xsl:call-template name="get-title"/>
                    </h2>
                    <!-- Call link icons (located in link-icons.xsl) -->
                    <xsl:call-template name="link-icons"/>   
     <!-- End Title -->
                </div>
                <!-- Main place page content -->
                <xsl:apply-templates select="//t:place"/>
            </div>
        </div>
  <!-- End main content section -->
  <!-- Citations section -->
        <div class="row-fluid">
            <xsl:variable name="htmluri" select="concat('?id=',$placenum)"/>
            <div class="span12 citationinfo">
                <h3>How to Cite This Entry</h3>
                <div id="citation-note" class="well">
                    <xsl:apply-templates select="//t:teiHeader/t:fileDesc/t:titleStmt" mode="cite-foot"/>
                    <br/>
                    <span class="pull-right">
                        <a id="moreInfo">Show full citation information...</a>
                    </span>
                    <div id="citation">
                        <div id="citation-bibliography">
                            <h4>Bibliography:</h4>
                            <xsl:apply-templates select="//t:teiHeader/t:fileDesc/t:titleStmt" mode="cite-biblist"/>
                        </div>
                        <div id="about">
                            <h3>About this Entry</h3>
                            <xsl:apply-templates select="//t:teiHeader/t:fileDesc/t:titleStmt" mode="about"/>
                        </div>
                        <div id="license">
                            <h3>Copyright and License for Reuse</h3>
                            <p>
                                <xsl:text>Except otherwise noted, this page is © </xsl:text>
                                <xsl:value-of select="format-date(xs:date(//t:teiHeader/t:fileDesc/t:publicationStmt/t:date[1]), '[Y]')"/>.</p>
                            <xsl:apply-templates select="//t:teiHeader/t:fileDesc/t:publicationStmt/t:availability/t:licence"/>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </xsl:template>
    
<!-- ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||| -->
<!-- |||| Place templates -->
<!-- ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||| -->
    <xsl:template match="t:place">
        <!-- Start place content -->
        <div class="row-fluid">
            <!-- Main content -->
            <div class="span10">
                <div class="row-fluid">
                    <div class="span12 main">
                        <!-- Place URI and Abstract -->
                        <div class="row-fluid">
                            <div class="span12">
                                <!-- emit place URI and associated help links -->
                                <xsl:for-each select="t:idno[contains(.,'syriaca.org')]">
                                    <div style="margin:0 1em 1em; color: #999999;">
                                        <small>
                                            <a href="help/terms.html#place-uri" title="Click to read more about Place URIs">
                                                <div class="helper circle">
                                                    <p>i</p>
                                                </div>
                                            </a>
                                            <p>
                                                <span class="srp-label">Place URI</span>
                                                <xsl:text>: </xsl:text>
                                                <xsl:value-of select="."/>
                                            </p>
                                        </small>
                                    </div>
                                </xsl:for-each>
                                <xsl:apply-templates select="t:desc[@type='abstract' or starts-with(@xml:id, 'abstract-en')][1]" mode="abstract"/>
                            </div>
                        </div>
                        <!-- End abstract row -->
                        <!-- Start of two column content -->
                        <div class="row-fluid">
                            <!-- Column 1 -->
                            <div class="span8 column1">
                                <xsl:call-template name="col1"/>
                                <xsl:if test="not(exists(t:desc)) or string-length(t:desc[not(starts-with(@xml:id,'abstract'))][1]) &lt; 1">
                                    <xsl:call-template name="sources"/>
                                </xsl:if>
                            </div>
                            <!-- Column 2 -->
                            <div class="span4 column2">
                                <xsl:call-template name="col2"/>
                            </div>
                        </div>
                        <xsl:if test="string-length(t:desc[not(starts-with(@xml:id,'abstract'))][1]) &gt; 1">
                            <xsl:call-template name="sources"/>
                        </xsl:if>
                    </div>
                </div>
            </div>
            <!-- RDF Results -->
            <div class="span2">
                <h3>RDF Results</h3>
                <div>
                    Results
                </div>
            </div>
        </div>
    </xsl:template>
    <!-- Place content is split into two columns -->
    <xsl:template name="col1">
        <!-- NOTE, for map do well with map in half and type and location in other half, force better proportions -->
        <xsl:choose>
            <xsl:when test="t:location[@type='gps'and t:geo]">
                <div class="well">
                    <div class="row-fluid">
                        <!-- The map widget -->
                        <div class="span7">
                            <!-- If map data exists generate location link for use by map.js -->
                            <xsl:if test="t:location/t:geo[1]">
                                <xsl:apply-templates select="t:location[t:geo][1]/t:geo[1]" mode="json-uri"/>
                            </xsl:if>
                            <div id="map"/>
                        </div>
                        <div class="span5" style="padding-left:1em;padding-top:.5em;">
                            <div id="type">
                                <!-- NOTE: may need to move this elsewhere -->
                                <p>
                                    <strong>Place Type: </strong>
                                    <a href="../help/types.html#{normalize-space(@type)}">
                                        <xsl:value-of select="@type"/>
                                    </a>
                                </p>
                            </div>
                            <xsl:if test="t:location">
                                <div id="location">
                                    <h4>Location</h4>
                                    <ul style="margin-left:1.25em;margin-top:-.5em;padding:0;">
                                        <xsl:apply-templates select="t:location"/>
                                    </ul>
                                </div>
                            </xsl:if>
                        </div>
                    </div>
                </div>
            </xsl:when>
            <xsl:otherwise>
                <div class="well">
                    <div class="row-fluid">
                        <div class="span12" style="padding-left:1em;padding-top:.5em;">
                            <div id="type">
                                <!-- NOTE: may need to move this elsewhere -->
                                <p>
                                    <strong>Place Type: </strong>
                                    <a href="../help/types.html#{normalize-space(@type)}">
                                        <xsl:value-of select="@type"/>
                                    </a>
                                </p>
                            </div>
                            <xsl:if test="t:location">
                                <div id="location">
                                    <h4>Location</h4>
                                    <ul style="margin-left:1.25em;margin-top:-.5em;padding:0;">
                                        <xsl:apply-templates select="t:location"/>
                                    </ul>
                                </div>
                            </xsl:if>
                        </div>
                    </div>
                </div>
            </xsl:otherwise>
        </xsl:choose>
        <div style="padding:.5em;">
            <xsl:if test="string-length(t:desc[not(starts-with(@xml:id,'abstract'))][1]) &gt; 1">
                <div id="description">
                    <h3>Brief Descriptions</h3>
                    <ul>
                        <xsl:for-each-group select="t:desc" group-by="if (contains(@xml:lang, '-')=true()) then substring-before(@xml:lang, '-') else @xml:lang">
                            <xsl:sort collation="{$languages}" select="if (contains(@xml:lang, '-')=true()) then substring-before(@xml:lang, '-') else @xml:lang"/>
                            <xsl:for-each select="current-group()">
                                <xsl:sort lang="{current-grouping-key()}" select="normalize-space(.)"/>
                                <xsl:apply-templates select="."/>
                            </xsl:for-each>
                        </xsl:for-each-group>
                    </ul>
                </div>
            </xsl:if>
            <!-- 
                Checks for nested locations, nested location is added to the tei via record.xql
                XML ouput:
                    <nested-places xmlns="http://www.w3.org/1999/xhtml" id="place-1721" type="">
                        <placeName xmlns="http://www.tei-c.org/ns/1.0" xml:id="name1721-1" xml:lang="en" syriaca-tags="#syriaca-headword" source="#bib1721-1">Shūrzāq</placeName>
                    </nested-places>
            -->
            <xsl:if test="/child::*/nested-place">
                <div id="contents">
                    <h3>Contains</h3>
                    <ul>
                        <xsl:for-each select="/child::*/nested-place">
                            <xsl:sort collation="{$mixed}" select="t:placeName[@xml:lang='en'][1]/@reg"/>
                            <li>
                                <a href="{concat('place.html?id=',@id)}">
<!--                                <xsl:call-template name="place-title-std"/>-->
                                    <xsl:value-of select="."/>
                                </a>
                            </li>
                        </xsl:for-each>
                    </ul>
                </div>
            </xsl:if>
          
          <!-- Events without @type="attestation" -->
            <xsl:if test="t:event[not(@type='attestation')]">
                <div id="event">
                    <h3>Event<xsl:if test="count(t:event[not(@type='attestation')]) &gt; 1">s</xsl:if>
                    </h3>
                    <ul>
                        <xsl:apply-templates select="t:event[not(@type='attestation')]" mode="event"/>
                    </ul>
                </div>
            </xsl:if> 
          
          <!-- Events with @type="attestation" -->
            <xsl:if test="t:event[@type='attestation']">
                <div id="event">
                    <h3>Attestation<xsl:if test="count(t:event[@type='attestation']) &gt; 1">s</xsl:if>
                    </h3>
                    <ul>
                        <!-- Sorts events on dates, checks first for @notBefore and if not present, uses @when -->
                        <xsl:for-each select="t:event[@type='attestation']">
                            <xsl:sort select="if(exists(@notBefore)) then @notBefore else @when"/>
                            <xsl:apply-templates select="." mode="event"/>
                        </xsl:for-each>
                    </ul>
                </div>
            </xsl:if>
            
          <!-- Calls named template to pull confession information -->
            <xsl:if test="t:state[@type='confession']">
                <div id="description">
                    <h3>Known Religious Communities</h3>
                    <p class="caveat">
                        <em>This list is not necessarily exhaustive, and the order does not represent importance or proportion of the population. Dates do not represent starting or ending dates of a group's presence, but rather when they are attested. Instead, the list only represents groups for which Syriaca.org has source(s) and dates.</em>
                    </p>
                    <xsl:call-template name="confessions"/>
                </div>
            </xsl:if>
          <!-- Note type Incerta  -->
            <xsl:if test="t:note[@type='incerta']">
                <div id="errata">
                    <h3>Incerta</h3>
                    <ul>
                        <xsl:apply-templates select="t:note[@type='incerta']"/>
                    </ul>
                </div>
            </xsl:if>
          <!-- Note type Incerta  -->
            <xsl:if test="t:note[@type='corrigenda']">
                <div id="errata">
                    <h3>Corrigenda</h3>
                    <ul>
                        <xsl:apply-templates select="t:note[@type='corrigenda']"/>
                    </ul>
                </div>
            </xsl:if>
        </div>
    </xsl:template>
    <xsl:template name="col2">
        <div id="placenames" class="well">
            <h3>Names</h3>
            <xsl:apply-templates select="t:placeName[@syriaca-tags='#syriaca-headword' and @xml:lang='syr']" mode="list">
                <xsl:sort lang="syr" select="."/>
            </xsl:apply-templates>
            <xsl:apply-templates select="t:placeName[@syriaca-tags='#syriaca-headword' and @xml:lang='en']" mode="list">
                <xsl:sort collation="{$mixed}" select="."/>
            </xsl:apply-templates>
            <xsl:apply-templates select="t:placeName[(not(@syriaca-tags) or @syriaca-tags!='#syriaca-headword') and starts-with(@xml:lang, 'syr')]" mode="list">
                <xsl:sort lang="syr" select="."/>
            </xsl:apply-templates>
            <xsl:apply-templates select="t:placeName[starts-with(@xml:lang, 'ar')]" mode="list">
                <xsl:sort lang="ar" select="."/>
            </xsl:apply-templates>
            <xsl:apply-templates select="t:placeName[(not(@syriaca-tags) or @syriaca-tags!='#syriaca-headword') and not(starts-with(@xml:lang, 'syr') or starts-with(@xml:lang, 'ar'))]" mode="list">
                <xsl:sort collation="{$mixed}" select="."/>
            </xsl:apply-templates>
        </div>
        <!-- Build related places and people if they exist -->
        <xsl:if test="../t:relation">
            <div id="relations" class="well">
                <h3>Related Places</h3>
                <ul>
                    <xsl:apply-templates select="/child::*/related-items"/>
                </ul>
            </div>
        </xsl:if>
        <xsl:call-template name="link-icons-text"/>
    </xsl:template>
    <xsl:template name="sources">
        <div class="well">
            <!-- Sources -->
            <div id="sources">
                <h3>Sources</h3>
                <p>
                    <small>Any information without attribution has been created following the Syriaca.org <a href="http://syriaca.org/documentation/">editorial guidelines</a>.</small>
                </p>
                <ul>
                    <!-- Bibliography elements are processed by bibliography.xsl -->
                    <xsl:apply-templates select="t:bibl" mode="footnote"/>
                </ul>
            </div>
        </div>
    </xsl:template>
    <!-- Children of place element -->
    <!-- Template to print out events -->
    <xsl:template match="t:event" mode="event">
        <li> 
            <!-- There are several desc templates, this 'plain' mode ouputs all the child elements with no p or li tags -->
            <xsl:apply-templates select="child::*" mode="plain"/>
            <!-- Adds dates if available -->
            <xsl:sequence select="local:do-dates(.)"/>
            <!-- Adds footnotes if available -->
            <xsl:if test="@source">
                <xsl:sequence select="local:do-refs(@source,ancestor::t:*[@xml:lang][1])"/>
            </xsl:if>
        </li>
    </xsl:template>
    
    <!-- Named template to handle nested confessions -->
    <xsl:template name="confessions">
        <!-- Variable stores all confessions from confessions.xml -->
        <xsl:variable name="confessions" select="/child::*/t:confessions/descendant::t:list"/>
        <xsl:variable name="place-data" select="."/>
        <!-- Variable to store the value of the confessions of current place-->
        <xsl:variable name="current-confessions">
            <xsl:for-each select="t:state[@type='confession']">
                <xsl:variable name="id" select="substring-after(@ref,'#')"/>
                <!-- outputs current confessions as a space seperated list -->
                <xsl:value-of select="concat($id,' ')"/>
            </xsl:for-each>
        </xsl:variable>
        <!-- Works through the tree structure in the confessions.xml to output only the relevant confessions -->
        <xsl:for-each select="/child::*/t:confessions/descendant::t:list[1]">
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
    
    <!-- Named template to build confession dates bassed on attestation dates -->
    <xsl:template name="confession-dates">
        <!-- param passes place data for processing -->
        <xsl:param name="place-data"/>
        <!-- confession id -->
        <xsl:param name="confession-id"/>
        <!-- find confessions in place data using confession-id -->
        <xsl:choose>
            <xsl:when test="$place-data//t:state[@type='confession' and substring-after(@ref,'#') = $confession-id]">
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
                                            <xsl:when test="position() = 1">
                                                attested around <xsl:value-of select="local:trim-date(@notBefore)"/>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                attested as early as <xsl:value-of select="local:trim-date(@notBefore)"/>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                    </xsl:when>
                                    <!-- process @notAfter dates -->
                                    <xsl:when test="./@notAfter">
                                        <xsl:if test="./@notBefore">, </xsl:if>as late as <xsl:value-of select="local:trim-date(@notAfter)"/>
                                    </xsl:when>
                                    <xsl:otherwise/>
                                </xsl:choose>
                            </xsl:for-each>)
                        </xsl:when>
                        <!-- If not attestation information -->
                        <xsl:otherwise> 
                            (no attestations yet recorded)
                        </xsl:otherwise>
                    </xsl:choose>
                    <!-- Add refs if they exist -->
                    <xsl:if test="@source">
                        <xsl:sequence select="local:do-refs(@source,'eng')"/>
                    </xsl:if>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise> 
                <!-- Checks for children with attestation information -->
                <xsl:variable name="child-id" select="string-join(descendant-or-self::t:item/@xml:id,' ')"/>
                   <!-- Find the first child with a match  -->
                <xsl:for-each select="$place-data//t:state[@type='confession' and contains($child-id,substring-after(@ref,'#'))][1]">
                    <xsl:for-each select="$place-data//t:state[@type='confession' and contains($child-id,substring-after(@ref,'#'))][1]">
                            <!-- Build ref id to find attestations -->
                        <xsl:variable name="ref-id" select="concat('#',@xml:id)"/>
                            <!-- Find attestations with matching confession-id in link/@target  -->
                        <xsl:if test="//t:event[@type='attestation' and child::*[contains(@target,$ref-id)]]">
                                    <!-- If there is a match process dates -->
                                    (<xsl:for-each select="//t:event[@type='attestation' and t:link[contains(@target,$ref-id)]]">
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
                                            <xsl:when test="position() = 1">
                                                        attested around <xsl:value-of select="local:trim-date(@notBefore)"/>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                        attested as early as <xsl:value-of select="local:trim-date(@notBefore)"/>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                    </xsl:when>
                                            <!-- process @notAfter dates -->
                                    <xsl:when test="./@notAfter">
                                        <xsl:if test="./@notBefore">, </xsl:if>as late as <xsl:value-of select="local:trim-date(@notAfter)"/>
                                    </xsl:when>
                                    <xsl:otherwise/>
                                </xsl:choose>
                            </xsl:for-each>)
                                </xsl:if>
                    </xsl:for-each>
                        <!-- Add refs if they exist -->
                    <xsl:if test="@source">
                        <xsl:sequence select="local:do-refs(@source,'eng')"/>
                    </xsl:if>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- Template to print out confession section -->
    <xsl:template match="t:state[@type='confession']">
        <!-- Get all ancesors of current confession (but only once) -->
        <xsl:variable name="confessions" select="document('/db/apps/srophe/data/confessions/tei/confessions.xml')//t:body/t:list"/>
        <xsl:variable name="id" select="substring-after(@ref,'#')"/>
        <li>
            <xsl:value-of select="$id"/>: 
            <xsl:for-each select="$confessions//t:item[@xml:id = $id]/ancestor-or-self::*/t:label">
                <xsl:value-of select="."/>
            </xsl:for-each>
        </li>
    </xsl:template>
    
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
        Related Places templates 
        matches the following structure generated by record.xql: 
                <related-items xmlns="http://www.w3.org/1999/xhtml">
                     <relation id="876" 
                             uri="http://syriaca.org/place/876" 
                             varient="passive" 
                             name="contains" 
                             active="#place-602" 
                             passive="http://syriaca.org/place/876 http://syriaca.org/place/1947 http://syriaca.org/place/666 http://syriaca.org/place/507" 
                             source="#bib602-2">
                                <placeName xmlns="http://www.tei-c.org/ns/1.0" xml:id="name876-1" xml:lang="en" syriaca-tags="#syriaca-headword" source="#bib876-1 #bib876-2">Trichur</placeName>
                            </relation>
                            <relation id="1947" uri="http://syriaca.org/place/1947" varient="passive" name="contains" active="#place-602" passive="http://syriaca.org/place/876 http://syriaca.org/place/1947 http://syriaca.org/place/666 http://syriaca.org/place/507" source="#bib602-2">
                                <placeName xmlns="http://www.tei-c.org/ns/1.0" xml:id="name1947-1" xml:lang="en" syriaca-tags="#syriaca-headword" source="#bib1947-1">Kottayam</placeName>
                            </relation>                
                   </related-items> 
  
    ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="relation">
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
        <xsl:variable name="currentPlace" select="//t:place/t:placeName[1]"/>
        <xsl:choose>
            <xsl:when test="@id=concat('#place-',$placenum)"/>
            <xsl:when test="@varient='active'">
                <li>
                    <a href="{concat('place.html?id=',@id)}">
                        <xsl:value-of select="t:placeName"/>
                    </a>
                    <xsl:text> </xsl:text>
                    <xsl:value-of select="$name-string"/>
                    <xsl:text> </xsl:text>
                    <xsl:value-of select="$currentPlace"/>
                    <xsl:text> </xsl:text>
                    <xsl:value-of select="local:do-dates(.)"/>
                    <xsl:text> </xsl:text>
                    <!-- If footnotes exist call function do-refs pass footnotes and language variables to function -->
                    <xsl:if test="@source">
                        <xsl:sequence select="local:do-refs(@source,@xml:lang)"/>
                    </xsl:if>
                </li>
            </xsl:when>
            <xsl:when test="@varient='passive'">
                <li>
                    <xsl:value-of select="$currentPlace"/>
                    <xsl:text> </xsl:text>
                    <xsl:value-of select="$name-string"/>
                    <xsl:text> </xsl:text>
                    <a href="{concat('place.html?id=',@id)}">
                        <xsl:value-of select="t:placeName"/>
                    </a>
                    <xsl:text> </xsl:text>
                    <xsl:value-of select="local:do-dates(.)"/>
                    <xsl:text> </xsl:text>
                    <!-- If footnotes exist call function do-refs pass footnotes and language variables to function -->
                    <xsl:if test="@source">
                        <xsl:sequence select="local:do-refs(@source,@xml:lang)"/>
                    </xsl:if>
                </li>
            </xsl:when>
            <xsl:when test="@varient='mutual'">
                <li>
                    <xsl:value-of select="$currentPlace"/>
                    <xsl:choose>
                        <xsl:when test="count(mutual) = 1"> and </xsl:when>
                        <xsl:when test="count(mutual) &gt; 1">, </xsl:when>
                        <xsl:otherwise/>
                    </xsl:choose>
                    <xsl:for-each select="mutual">
                        <xsl:if test="child::*">
                            <a href="{concat('place.html?id=',@id)}">
                                <xsl:value-of select="t:placeName"/>
                            </a>
                            <xsl:choose>
                                <xsl:when test="count(following-sibling::*) = 1">, and </xsl:when>
                                <xsl:when test="count(following-sibling::*) &gt; 1">, </xsl:when>
                            </xsl:choose>
                        </xsl:if>
                    </xsl:for-each>
                    <xsl:text> </xsl:text>
                    <xsl:value-of select="replace(child::*[1]/@name,'-',' ')"/>
                    <xsl:value-of select="local:do-dates(child::*[1])"/>
                    <xsl:text> </xsl:text>
                    <!-- If footnotes exist call function do-refs pass footnotes and language variables to function -->
                    <xsl:if test="child::*[1]/@source">
                        <xsl:sequence select="local:do-refs(child::*[1]/@source,@xml:lang)"/>
                    </xsl:if>
                </li>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="t:location[@type='geopolitical' or @type='relative']">
        <li>
            <xsl:apply-templates/>
            <xsl:sequence select="local:do-refs(@source,ancestor::t:*[@xml:lang][1])"/>
        </li>
    </xsl:template>
       
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++  
     handle standard output of 'nested' locations 
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:location[@type='nested']">
        <li>Within 
            <xsl:for-each select="t:*">
                <xsl:apply-templates select="."/>
                <xsl:if test="following-sibling::t:*">
                    <xsl:text> within </xsl:text>
                </xsl:if>
            </xsl:for-each>
            <xsl:text>.</xsl:text>
            <xsl:sequence select="local:do-refs(@source,'eng')"/>
        </li>
    </xsl:template>
    <xsl:template match="t:location[@type='gps' and t:geo]">
        <li>Coordinates: 
            <ul class="unstyled offset1">
                <li>
                    <xsl:value-of select="concat('Lat. ',tokenize(t:geo,' ')[1],'°')"/>
                </li>
                <li>
                    <xsl:value-of select="concat('Long. ',tokenize(t:geo,' ')[2],'°')"/>
                    <!--            <xsl:value-of select="t:geo"/>-->
                    <xsl:sequence select="local:do-refs(@source,'eng')"/>
                </li>
            </ul>
        </li>
    </xsl:template>
    <xsl:template match="t:offset | t:measure">
        <xsl:apply-templates select="." mode="out-normal"/>
    </xsl:template>
    
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     Description templates 
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <!-- Descriptions without list elements or paragraph elements -->
    <xsl:template match="t:desc" mode="plain">
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="t:label" mode="plain">
        <xsl:apply-templates/>
    </xsl:template>
    <!-- Descriptions for place abstract  added template for abstracts, handles quotes and references.-->
    <xsl:template match="t:desc[starts-with(@xml:id, 'abstract-en')]" mode="abstract">
        <p>
            <xsl:apply-templates/>
        </p>
    </xsl:template>
    
    <!-- General descriptions within the body of the place element, uses lists -->
    <xsl:template match="t:desc[not(starts-with(@xml:id, 'abstract-en'))]">
        <li>
            <xsl:call-template name="langattr"/>
            <xsl:apply-templates/>
        </li>
    </xsl:template>
    
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     handle standard output of a listBibl element 
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:listBibl">
        <ul class="listBibl">
            <xsl:for-each select="t:bibl">
                <li>
                    <xsl:apply-templates select="." mode="biblist"/>
                    <xsl:text>.</xsl:text>
                </li>
            </xsl:for-each>
        </ul>
    </xsl:template>
    
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     handle standard output of a note element 
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:note">
        <xsl:variable name="xmlid" select="@xml:id"/>
        <xsl:choose>
            <!-- Adds definition list for depreciated names -->
            <xsl:when test="@type='deprecation'">
                <dl>
                    <dt>
                        <xsl:apply-templates select="../t:link[contains(@target,$xmlid)]"/>
                    </dt>
                    <dd>
                        <xsl:apply-templates/>
                        <!-- Check for ending punctuation, if none, add . -->
                        <xsl:if test="not(ends-with(.,'.'))">
                            <xsl:text>.</xsl:text>
                        </xsl:if>
                    </dd>
                </dl>
            </xsl:when>
            <xsl:when test="@type='corrigenda' or @type='incerta'">
                <li>
                    <xsl:apply-templates/>
                </li>
            </xsl:when>
            <xsl:otherwise>
                <p>
                    <xsl:apply-templates/>
                    <!-- Check for ending punctuation, if none, add . -->
                    <xsl:if test="not(ends-with(.,'.'))">
                        <xsl:text>.</xsl:text>
                    </xsl:if>
                </p>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- Handles t:link elements for deperciated notes, pulls value from matching element, output element and footnotes -->
    <xsl:template match="t:link">
        <xsl:variable name="elementID" select="substring-after(substring-before(@target,' '),'#')"/>
        <xsl:for-each select="/descendant-or-self::*[@xml:id=$elementID]">
            <xsl:apply-templates select="."/>
            <!-- NOTE: position last is not working? -->
            <!--   <xsl:if test="not(../preceding-sibling::*[@xml:id=$elementID])"><xsl:text>, </xsl:text></xsl:if>-->
            <xsl:text> </xsl:text>
        </xsl:for-each>
    </xsl:template>

    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     handle standard output of a p element 
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:p">
        <p>
            <xsl:call-template name="langattr"/>
            <xsl:apply-templates/>
        </p>
    </xsl:template>
    <xsl:template match="t:quote">
        <xsl:text>“</xsl:text>
        <xsl:apply-templates/>
        <xsl:text>”</xsl:text>
        <xsl:sequence select="local:do-refs(@source,ancestor::t:*[@xml:lang][1])"/>
    </xsl:template>
    <xsl:template match="t:placeName | t:region | t:settlement">
        <xsl:choose>
            <xsl:when test="@ref">
                <xsl:choose>
                    <xsl:when test="string-length(@ref) &lt; 1"/>
                    <xsl:when test="starts-with(@ref, $uribase)">
                        <xsl:text> </xsl:text>
                        <a class="placeName" href="?id={substring-after(@ref, $uribase)}">
                            <xsl:call-template name="langattr"/>
                            <xsl:apply-templates mode="cleanout"/>
                        </a>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text> </xsl:text>
                        <a class="placeName" href="{@ref}">
                            <xsl:call-template name="langattr"/>
                            <xsl:apply-templates mode="cleanout"/>
                        </a>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <!-- NOTE: added footnotes to all placeNames if available. Uses local do-refs function -->
                <span class="placeName">
                    <xsl:call-template name="langattr"/>
                    <xsl:apply-templates mode="cleanout"/>
                    <xsl:sequence select="local:do-refs(@source,@xml:lang)"/>
                </span>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="t:placeName" mode="list">
        <xsl:variable name="nameID" select="concat('#',@xml:id)"/>
        <xsl:choose>
            <!-- Suppress depreciated names here -->
            <xsl:when test="/descendant-or-self::t:link[substring-before(@target,' ') = $nameID][contains(@target,'deprecation')]"/>
            <!-- Output all other names -->
            <xsl:otherwise>
                <li dir="ltr">
                    <!-- write out the placename itself, with appropriate language and directionality indicia -->
                    <span class="placeName">
                        <xsl:call-template name="langattr"/>
                        <xsl:apply-templates select="." mode="out-normal"/>
                    </span>
                    <xsl:sequence select="local:do-refs(@source,ancestor::t:*[@xml:lang][1])"/>
                </li>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     handle standard output of the licence element in the tei header
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:licence">
        <xsl:if test="@target">
            <xsl:variable name="licenserev" select="tokenize(@target, '/')[last()-1]"/>
            <xsl:variable name="licensetype" select="tokenize(substring-before(@target, $licenserev), '/')[last()-1]"/>
            <a rel="license" href="{@target}">
                <img alt="Creative Commons License" style="border-width:0" src="http://i.creativecommons.org/l/{$licensetype}/{$licenserev}/80x15.png"/>
            </a>
        </xsl:if>
        <xsl:apply-templates/>
    </xsl:template>
    
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     handle standard output of the ref element
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:ref">
        <a href="{@target}">
            <xsl:apply-templates/>
        </a>
    </xsl:template>
    <xsl:template name="get-headword-ele" as="element()*">
        <xsl:choose>
            <xsl:when test="./descendant-or-self::t:listPlace/t:place/t:placeName[@syriaca-tags='#syriaca-headword']">
                <xsl:sequence select="./descendant-or-self::t:listPlace/t:place/t:placeName[@syriaca-tags='#syriaca-headword']"/>
            </xsl:when>
            <xsl:otherwise>
<!--                <xsl:message>WARNING: placepage.xsl unable to find placeName tagged with '#syriaca-headword' in <xsl:value-of select="document-uri(.)"/></xsl:message>-->
                <xsl:sequence select="./descendant-or-self::t:listPlace/t:place/t:placeName[1]"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- NOTE: where is this used? Seems to be an issue with syrac text-->
    <xsl:template name="get-description-ele" as="element()*">
        <xsl:choose>
            <xsl:when test="./descendant-or-self::t:listPlace/t:place/t:desc[starts-with(@xml:id, 'abstract-en')]">
                <xsl:sequence select="./descendant-or-self::t:listPlace/t:place/t:desc[starts-with(@xml:id, 'abstract-en')]"/>
            </xsl:when>
            <xsl:otherwise>
<!--                <xsl:message>WARNING: placepage.xsl unable to find desc with id that starts with 'abstract-en' in <xsl:value-of select="document-uri(.)"/></xsl:message>-->
                <xsl:sequence select="./descendant-or-self::t:listPlace/t:place/t:desc[1]"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="t:placeName[local-name(..)='desc']" mode="cleanout">
        <xsl:apply-templates select="."/>
    </xsl:template>
    <xsl:template match="text()" mode="cleanout">
        <xsl:value-of select="."/>
    </xsl:template>
    <xsl:template match="t:*" mode="cleanout">
        <xsl:apply-templates mode="cleanout"/>
    </xsl:template>
    
    <!-- ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||| -->
    <!-- |||| match=t:*: suppress all TEI elements not otherwise handled -->
    <!-- ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||| -->
    <xsl:template match="t:*"/>
</xsl:stylesheet>