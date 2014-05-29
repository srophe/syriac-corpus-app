<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:s="http://syriaca.org" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:saxon="http://saxon.sf.net/" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:local="http://syriaca.org/ns" xmlns:x="http://www.w3.org/1999/xhtml" exclude-result-prefixes="xs t s saxon" version="2.0">

 <!-- ================================================================== 
       Copyright 2013 New York University
       
       The Syriac Reference Portal Persons Application is free software: 
       you can redistribute it and/or modify it under the terms of the GNU 
       General Public License as published by the Free Software Foundation, 
       either version 3 of the License, or (at your option) any later 
       version.
       
       The Syriac Reference Portal Persons Application is distributed in 
       the hope that it will be useful, but WITHOUT ANY WARRANTY; without 
       even the implied warranty of MERCHANTABILITY or FITNESS FOR A 
       PARTICULAR PURPOSE.  See the GNU General Public License for more 
       details.
       
       You should have received a copy of the GNU General Public License
       along with the Syriac Reference Portal Persons Application.  If not,
       see (http://www.gnu.org/licenses/).
       
       ================================================================== --> 
 
 <!-- ================================================================== 
       personspage.xsl
       
       This XSLT transforms perons tei xml (TEI) files to HTML. It builds the
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
   <!-- NOTE: WS: should change to title-std used by place and persons-->
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
    <xsl:param name="xmlbase">/db/apps/srophe/data/persons/tei/xml/</xsl:param>
    <xsl:param name="editoruriprefix">http://syriaca.org/editors.xml#</xsl:param>
    <xsl:variable name="editorssourcedoc">/db/apps/srophe/documentation/editors.xml</xsl:variable>
    <xsl:param name="uribase">http://syriaca.org/persons/</xsl:param>
    <xsl:variable name="resource-id" select="substring-after(/descendant::*/t:person[1]/@xml:id,'person-')"/>
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
                    <h1 class="span8">
                        <!-- Format title, calls template in place-title-std.xsl -->
                        <xsl:call-template name="rec-title-std">
                            <xsl:with-param name="rec" select="//t:person"/>
                        </xsl:call-template>
                        <span class="get-syriac noprint">
                            <xsl:if test="//t:person/child::*[@xml:lang ='syr']">
                                <a href="../documentation/view-syriac.html">
                                    <img src="../resources/img/faq.png" alt="The Google Maps icon"/>&#160;Don't see Syriac?</a>
                            </xsl:if>
                        </span>
                    </h1>
                    <xsl:call-template name="link-icons"/>  
     <!-- End Title -->
                </div>
                <!-- Main paersons page content -->
                <xsl:apply-templates select="//t:person"/>
            </div>
        </div>
  <!-- End main content section -->
  <!-- Citations section -->
        <div class="row-fluid">
            <xsl:variable name="htmluri" select="concat('?id=',$resource-id)"/>
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
                        <span class="pull-right">
                            <a id="lessInfo">Hide citation information...</a>
                        </span>
                    </div>
                </div>
                <script type="text/javascript">
                    // Toggle for citation
                    $( "#moreInfo" ).click(function() {
                        $( "#citation" ).toggle( "slow", function() {
                            $( "#moreInfo" ).toggle();
                        });
                    });
                    
                    $( "#lessInfo" ).click(function() {
                        $( "#citation" ).toggle( "slow", function() {
                            $( "#moreInfo" ).toggle();
                        });
                    });
                </script>
            </div>
        </div>
        <xsl:if test="//t:geo">
            <script type="text/javascript" src="/exist/apps/srophe/resources/js/map.js"/>
        </xsl:if>
        <script type="text/javascript" src="/exist/apps/srophe/resources/js/main.js"/>
        <script type="text/javascript" src="/exist/apps/srophe/resources/js/jquery.validate.min.js"/>
    </xsl:template>
    
<!-- ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||| -->
<!-- |||| Person templates -->
<!-- ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||| -->
    <xsl:template match="t:person">
        <!-- Start person content -->
        <div class="row-fluid">
            <!-- Main content -->
            <!-- Change to span10 when RDF is added back in -->
            <div class="span12">
                <div class="row-fluid">
                    <div class="span12 main">
                        <!-- Person URI and Abstract -->
                        <div class="row-fluid">
                            <div class="span12">
                                <!-- emit person URI and associated help links -->
                                <xsl:for-each select="t:idno[contains(.,'syriaca.org')]">
                                    <div style="margin:0 1em 1em; color: #999999;">
                                        <small>
                                            <a href="../documentation/terms.html#person-uri" title="Click to read more about Person URIs" class="no-print-link">
                                                <div class="helper circle noprint">
                                                    <p>i</p>
                                                </div>
                                            </a>
                                            <p>
                                                <span class="srp-label">Person URI</span>
                                                <xsl:text>: </xsl:text>
                                                <xsl:value-of select="."/>
                                            </p>
                                        </small>
                                    </div>
                                </xsl:for-each>
                                <xsl:apply-templates select="t:desc[@type='abstract' or starts-with(@xml:id, 'abstract-en')][1] | t:note[@type='abstract']" mode="abstract"/>
                            </div>
                        </div>
                        <!-- End abstract row -->
                        <!-- Start of two column content -->
                        <div class="row-fluid">
                            <!-- Column 1 -->
                            <div class="span8 column1">
                                <xsl:call-template name="col1"/>
                                <div style="margin-bottom:1em;">  
                                <!-- Button to trigger modal -->
                                    <!--<a href="#report-errors" role="button" class="btn" data-toggle="modal">Corrections/Additions?</a>-->
                                    <a href="/geo/howtoadd.html" class="btn">Corrections/Additions?</a>
                                    <xsl:text> </xsl:text>
                                    <a href="#selection" role="button" class="btn" data-toggle="modal">Is this record complete?</a>
                                    
                                <!-- Modal 
                                    <div id="report-errors" class="modal hide fade" tabindex="-1" role="dialog" aria-labelledby="report-errors-label" aria-hidden="true">
                                        <div class="modal-header">
                                            <button type="button" class="close" data-dismiss="modal" aria-hidden="true">×</button>
                                            <h3 id="report-errors-label">Corrections/Additions?</h3>
                                        </div>
                                        <form action="/exist/apps/srophe/modules/email.xql" method="post" id="email">
                                            <div class="modal-body" id="modal-body">
                                                <label>Name:</label>
                                                <input type="text" name="name"/>
                                                <label>e-mail address:</label>
                                                <input type="text" name="email"/>
                                                <label>Subject:</label>
                                                <input type="text" name="subject"/>
                                                <label>Comments:</label>
                                                <textarea name="comments" id="comments" rows="8" class="span9"/>
                                                <input type="hidden" name="id" value="{$resource-id}"/>
                                                <input type="hidden" name="person" value="{string(t:personName[1])}"/>
                                            </div>
                                            <div class="modal-footer">
                                                <button class="btn" data-dismiss="modal" aria-hidden="true">Close</button>
                                                <input id="email-submit" type="submit" value="Send e-mail" class="btn"/>
                                            </div>
                                        </form>
                                    </div>-->
                                    <!-- Modal for FAQ  NOT working, woul have to change faq structure-->
                                    <div style="width: 750px; margin-left: -280px;" id="selection" class="modal hide fade" tabindex="-1" role="dialog" aria-labelledby="faq-label" aria-hidden="true">
                                        <div class="modal-header" style="height:15px !important;">
                                            <button type="button" class="close" data-dismiss="modal" aria-hidden="true"> × </button>
                                        </div>
                                        <div class="modal-body">
                                            <div id="popup" style="border:none; margin:0;padding:0;margin-top:-2em;"/>
                                        </div>
                                        <div class="modal-footer">
                                            <a class="btn" href="../documentation/faq.html" aria-hidden="true">See all FAQs</a>
                                            <button class="btn" data-dismiss="modal" aria-hidden="true">Close</button>
                                        </div>
                                    </div>
                                    <script>
                                        $('#selection').on('shown', function () {
                                        $( "#popup" ).load( "../documentation/faq.html #selection" );
                                        })
                                    </script>
                                </div>
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
            <!--<div class="span2">
                <h3>RDF Results</h3>
                <div>
                    Results
                </div>
            </div>-->
        </div>
    </xsl:template>
    <!-- Person content is split into two columns -->
    <xsl:template name="col1">
        <!-- NOTE, for map do well with map in half and type and location in other half, force better proportions -->
        <div class="well">
            <ul class="unstyled">
                <xsl:apply-templates select="t:birth | t:death | t:floruit | t:sex | t:langKnowledge"/>
                <xsl:if test="t:state[@type='martyred']/t:label = 'Yes'">
                    <li>Martyred <xsl:sequence select="local:do-refs(../@source,ancestor::t:*[@xml:lang][1])"/>
                    </li>
                </xsl:if>
            </ul>
        </div>
        <xsl:if test="t:location[@type='gps'and t:geo]">
            <div class="well">
                <div class="row-fluid">
                        <!-- The map widget -->
                    <div class="span7">
                            <!-- If map data exists generate location link for use by map.js -->
                        <xsl:if test="t:location/t:geo[1]">
                            <xsl:apply-templates select="t:location[t:geo][1]/t:geo[1]" mode="json-uri"/>
                        </xsl:if>
                        <div id="map" class="map-small"/>
                    </div>
                    <div class="span5" style="padding-left:1em;padding-top:.5em;">
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
        </xsl:if>
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
            <!-- NOTE: very odd display, need to have a chat about how these relate -->
            <xsl:if test="t:state[not(@type='attestation') and not(@type='martyred')]">
                <xsl:for-each-group select="t:state[not(@type='attestation') and not(@type='martyred')]" group-by="@type">
                    <div class="state">
                        <h3>
                            <xsl:value-of select="current-grouping-key()"/>
                        </h3>
                        <ul>
                            <xsl:for-each select="current-group()">
                                <xsl:apply-templates/>
                            </xsl:for-each>
                        </ul>
                    </div>
                </xsl:for-each-group>
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
            <xsl:if test="t:note[not(@type='abstract')]">
                <xsl:for-each-group select="t:note[not(@type='abstract')]" group-by="@type">
                    <div class="state">
                        <h3>
                            <xsl:value-of select="current-grouping-key()"/>
                        </h3>
                        <ul>
                            <xsl:for-each select="current-group()">
                                <xsl:apply-templates/>
                            </xsl:for-each>
                        </ul>
                    </div>
                </xsl:for-each-group>
            </xsl:if>
        </div>
    </xsl:template>
    <xsl:template name="col2">
        <div id="persnames" class="well">
            <h3>Names</h3>
            <xsl:apply-templates select="t:persName[@syriaca-tags='#syriaca-headword' and @xml:lang='syr']" mode="list">
                <xsl:sort lang="syr" select="."/>
            </xsl:apply-templates>
            <xsl:apply-templates select="t:persName[@syriaca-tags='#syriaca-headword' and @xml:lang='en']" mode="list">
                <xsl:sort collation="{$mixed}" select="."/>
            </xsl:apply-templates>
            <xsl:apply-templates select="t:persName[(not(@syriaca-tags) or @syriaca-tags!='#syriaca-headword') and starts-with(@xml:lang, 'syr')]" mode="list">
                <xsl:sort lang="syr" select="."/>
            </xsl:apply-templates>
            <xsl:apply-templates select="t:persName[starts-with(@xml:lang, 'ar')]" mode="list">
                <xsl:sort lang="ar" select="."/>
            </xsl:apply-templates>
            <xsl:apply-templates select="t:persName[(not(@syriaca-tags) or @syriaca-tags!='#syriaca-headword') and not(starts-with(@xml:lang, 'syr') or starts-with(@xml:lang, 'ar'))]" mode="list">
                <xsl:sort collation="{$mixed}" select="."/>
            </xsl:apply-templates>
        </div>
        <!-- NOTE: commented out for now
            Build related places and people if they exist -->
        <xsl:if test="../t:relation">
            <div id="relations" class="well">
                <h3>Related People</h3>
                <ul>
                    <xsl:apply-templates select="../t:relation"/>
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
    
    <!-- Children of person element -->
    <xsl:template match="t:relation">
        <xsl:apply-templates select="t:desc"/>
    </xsl:template>
    <xsl:template match="t:state | t:note[not(@type='abstract')]">
        <li>
            <xsl:apply-templates/>
        </li>
    </xsl:template>
    <xsl:template match="t:state[@type='martyred']"/>
    <xsl:template match="t:birth">
        <li>
            <span class="srp-label">Birth:</span>
            <xsl:text> </xsl:text>
            <xsl:apply-templates/>
            <xsl:sequence select="local:do-refs(@source,ancestor::t:*[@xml:lang][1])"/>
        </li>
    </xsl:template>
    <xsl:template match="t:death">
        <li>
            <span class="srp-label">Death:</span>
            <xsl:text> </xsl:text>
            <xsl:apply-templates/>
            <xsl:sequence select="local:do-refs(@source,ancestor::t:*[@xml:lang][1])"/>
        </li>
    </xsl:template>
    <xsl:template match="t:floruit">
        <li>
            <span class="srp-label">floruit:</span>
            <xsl:text> </xsl:text>
            <xsl:apply-templates/>
            <xsl:sequence select="local:do-refs(@source,ancestor::t:*[@xml:lang][1])"/>
        </li>
    </xsl:template>
    <xsl:template match="t:sex">
        <li>
            <span class="srp-label">Sex:</span>
            <xsl:text> </xsl:text>
            <xsl:apply-templates/>
            <xsl:sequence select="local:do-refs(@source,ancestor::t:*[@xml:lang][1])"/>
        </li>
    </xsl:template>
    <xsl:template match="t:langKnowledge">
        <li>
            <span class="srp-label">langKnowledge:</span>
            <xsl:text> </xsl:text>
            <xsl:apply-templates/>
        </li>
    </xsl:template>
    <xsl:template match="t:langKnown">
        <xsl:apply-templates/>
        <xsl:sequence select="local:do-refs(@source,ancestor::t:*[@xml:lang][1])"/>
    </xsl:template>
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
    <xsl:template match="t:location[@type='geopolitical' or @type='relative']">
        <li>
            <xsl:choose>
                <xsl:when test="@subtype='quote'">"<xsl:apply-templates/>"</xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates/>
                </xsl:otherwise>
            </xsl:choose>
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
        <xsl:if test="preceding-sibling::*">
            <xsl:text> </xsl:text>
        </xsl:if>
        <xsl:apply-templates select="." mode="out-normal"/>
    </xsl:template>
    
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     Description templates 
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <!-- Descriptions without list elements or paragraph elements -->
    <xsl:template match="t:desc" mode="plain">
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="t:label">
        <span class="syr-label">
            <xsl:apply-templates/>
        </span>
    </xsl:template>
    <xsl:template match="t:label" mode="plain">
        <xsl:apply-templates/>
    </xsl:template>
    <!-- Descriptions for person abstract  added template for abstracts, handles quotes and references.-->
    <xsl:template match="t:desc[starts-with(@xml:id, 'abstract-en')] | t:note[@type='abstract']" mode="abstract">
        <p>
            <xsl:apply-templates/>
        </p>
    </xsl:template>
    
    <!-- General descriptions within the body of the person element, uses lists -->
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
                <li>
                    <xsl:apply-templates select="../t:link[contains(@target,$xmlid)]"/>:
                        <xsl:apply-templates/>
                        <!-- Check for ending punctuation, if none, add . -->
                    <xsl:if test="not(ends-with(.,'.'))">
                        <xsl:text>.</xsl:text>
                    </xsl:if>
                </li>
            </xsl:when>
            <xsl:when test="@type='corrigenda' or @type='incerta' or @type ='errata'">
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
        <xsl:choose>
            <xsl:when test="@xml:lang">
                <xsl:text>“</xsl:text>
                <bdi>
                    <xsl:attribute name="dir">
                        <xsl:call-template name="getdirection"/>
                    </xsl:attribute>
                    <xsl:call-template name="langattr"/>
                    <xsl:apply-templates/>
                </bdi>
                <xsl:text>”</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>“</xsl:text>
                <xsl:apply-templates/>
                <xsl:text>”</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:sequence select="local:do-refs(@source,ancestor::t:*[@xml:lang][1])"/>
    </xsl:template>
    <xsl:template match="t:date">
        <xsl:apply-templates/>
    </xsl:template>
    <!-- NOTE: When persons are populated add back to this template for now, t:persName template, no link -->
    <xsl:template match="t:persName | t:region | t:settlement">
        <xsl:choose>
            <xsl:when test="@ref">
                <xsl:choose>
                    <xsl:when test="string-length(@ref) &lt; 1"/>
                    <xsl:when test="starts-with(@ref, $uribase)">
                        <xsl:text> </xsl:text>
                        <a class="persName" href="/person/{substring-after(@ref, $uribase)}.html">
                            <xsl:call-template name="langattr"/>
                            <xsl:apply-templates mode="cleanout"/>
                        </a>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text> </xsl:text>
                        <a class="persName" href="{@ref}">
                            <xsl:call-template name="langattr"/>
                            <xsl:apply-templates mode="cleanout"/>
                        </a>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <!-- NOTE: added footnotes to all persName if available. Uses local do-refs function -->
                <span class="persName">
                    <xsl:call-template name="langattr"/>
                    <xsl:apply-templates mode="cleanout"/>
                    <xsl:sequence select="local:do-refs(@source,@xml:lang)"/>
                </span>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="t:persName" mode="list">
        <xsl:variable name="nameID" select="concat('#',@xml:id)"/>
        <xsl:choose>
            <!-- Suppress depreciated names here -->
            <xsl:when test="/descendant-or-self::t:link[substring-before(@target,' ') = $nameID][contains(@target,'deprecation')]"/>
            <!-- Output all other names -->
            <xsl:otherwise>
                <li dir="ltr">
                    <!-- write out the persName itself, with appropriate language and directionality indicia -->
                    <span class="persName"> 
                        <xsl:call-template name="langattr"/>
                        <xsl:apply-templates/>
                    </span>
                    <xsl:sequence select="local:do-refs(@source,ancestor::t:*[@xml:lang][1])"/>
                </li>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!--
    <xsl:template match="t:persName">
        <xsl:call-template name="langattr"/>
        <xsl:apply-templates mode="cleanout"/>
    </xsl:template>
    -->
    <xsl:template match="t:roleName">
        <xsl:apply-templates mode="out-normal"/>
        <xsl:text> </xsl:text>
    </xsl:template>
    <xsl:template match="t:forename">
        <xsl:apply-templates mode="out-normal"/>
        <xsl:text> </xsl:text>
    </xsl:template>
    <xsl:template match="t:addName">
        <xsl:apply-templates mode="out-normal"/>
        <xsl:text> </xsl:text>
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
            <xsl:when test="./descendant-or-self::t:listPerson/t:person/t:persName[@syriaca-tags='#syriaca-headword']">
                <xsl:sequence select="./descendant-or-self::t:listPerson/t:person/t:persName[@syriaca-tags='#syriaca-headword']"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="./descendant-or-self::t:listPerson/t:person/t:persName[1]"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- NOTE: where is this used? Seems to be an issue with syrac text-->
    <xsl:template name="get-description-ele" as="element()*">
        <xsl:choose>
            <xsl:when test="./descendant-or-self::t:listPerson/t:person/t:desc[starts-with(@xml:id, 'abstract-en')]">
                <xsl:sequence select="./descendant-or-self::t:listPerson/t:person/t:desc[starts-with(@xml:id, 'abstract-en')]"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="./descendant-or-self::t:listPerson/t:person/t:desc[1]"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="t:persName[local-name(..)='desc']" mode="cleanout">
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