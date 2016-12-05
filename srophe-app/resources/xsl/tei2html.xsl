<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:x="http://www.w3.org/1999/xhtml" xmlns:saxon="http://saxon.sf.net/" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:local="http://syriaca.org/ns" exclude-result-prefixes="xs t x saxon local" version="2.0">

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
        + Winona Salesky for use with eXist-db
          
       funding provided by:
        + National Endowment for the Humanities (http://www.neh.gov). Any 
          views, findings, conclusions, or recommendations expressed in 
          this code do not necessarily reflect those of the National 
          Endowment for the Humanities.
       
       ================================================================== -->
 <!-- =================================================================== -->
 <!-- import component stylesheets for HTML page portions -->
 <!-- =================================================================== -->
    <xsl:import href="helper-functions.xsl"/>
    <xsl:import href="link-icons.xsl"/>
    <xsl:import href="srophe.xsl"/>
    <xsl:import href="manuscripts.xsl"/>
    <xsl:import href="spear.xsl"/>
    <xsl:import href="citation.xsl"/>
    <xsl:import href="bibliography.xsl"/>
    <xsl:import href="json-uri.xsl"/>
    <xsl:import href="langattr.xsl"/>
    <xsl:import href="collations.xsl"/>
    
 <!-- =================================================================== -->
 <!-- set output so we get (mostly) indented HTML -->
 <!-- =================================================================== -->
    <xsl:output name="html" encoding="UTF-8" method="xhtml" indent="no" omit-xml-declaration="yes"/>

 <!-- =================================================================== -->
 <!--  initialize top-level variables and transform parameters -->
 <!--  sourcedir: where to look for XML files to summarize/link to -->
 <!--  description: a meta description for the HTML page we will output -->
 <!--  name-app: name of the application (for use in head/title) -->
 <!--  name-page-short: short name of the page (for use in head/title) -->
 <!--  colquery: constructed variable with query for collection fn. -->
 <!-- =================================================================== -->
    
    <!-- Parameters passed from global.xqm (set in config.xml) default values if params are empty -->
    <!-- eXist data app root for gazetteer data -->
    <xsl:param name="data-root" select="'/db/apps/srophe-data'"/>
    <!-- eXist app root for app deployment-->
    <xsl:param name="app-root" select="'/db/apps/srophe'"/>
    <!-- Root of app for building dynamic links. Default is eXist app root -->
    <xsl:param name="nav-base" select="'/db/apps/srophe'"/>
    <!-- Base URI for identifiers in app data -->
    <xsl:param name="base-uri" select="'/db/apps/srophe'"/>
    <!-- Hard coded values-->
    <xsl:param name="normalization">NFKC</xsl:param>
    <xsl:param name="editoruriprefix">http://syriaca.org/documentation/editors.xml#</xsl:param>
    <xsl:variable name="editorssourcedoc" select="concat($app-root,'/documentation/editors.xml')"/>
    <!-- Resource id -->
    <xsl:variable name="resource-id">
        <xsl:choose>
            <xsl:when test="string(/*/@id)">
                <xsl:value-of select="string(/*/@id)"/>
            </xsl:when>
            <xsl:when test="/descendant::t:idno[@type='URI'][starts-with(.,$base-uri)][not(ancestor::t:seriesStmt)]">
                <xsl:value-of select="replace(replace(/descendant::t:idno[@type='URI'][not(ancestor::t:seriesStmt)][starts-with(.,$base-uri)][1],'/tei',''),'/source','')"/>
            </xsl:when>
            <!-- Temporary fix for SPEAR -->
            <xsl:otherwise>
                <xsl:text>http://syriaca.org/0000</xsl:text>
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
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="t:TEI">
        <!-- Header -->
        <xsl:call-template name="h1"/>
        <!-- MSS display -->
        <xsl:if test="descendant::t:sourceDesc/t:msDesc">
            <xsl:apply-templates select="descendant::t:sourceDesc/t:msDesc"/>
        </xsl:if>
        <!-- Body -->
        <xsl:apply-templates select="descendant::t:body/child::*"/>
        <!-- Citation Information -->
        <xsl:call-template name="citationInfo"/>
    </xsl:template>
   

    <!-- Generic title formating -->
    <xsl:template match="t:title">
        <xsl:choose>
            <xsl:when test="@ref">
                <a href="{@ref}">
                    <xsl:apply-templates/>
                    [<xsl:value-of select="@ref"/>]
                </a>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
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
    <xsl:template match="t:event">
        <!-- There are several desc templates, this 'plain' mode ouputs all the child elements with no p or li tags -->
        <xsl:apply-templates select="child::*" mode="plain"/>
        <!-- Adds dates if available -->
        <xsl:sequence select="local:do-dates(.)"/>
        <!-- Adds footnotes if available -->
        <xsl:if test="@source">
            <xsl:sequence select="local:do-refs(@source,ancestor::t:*[@xml:lang][1])"/>
        </xsl:if>
    </xsl:template>
    <xsl:template match="t:orig | t:sic">
        <xsl:text> (</xsl:text>
        <xsl:apply-templates/>
        <xsl:text>) </xsl:text>
    </xsl:template>
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
    
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     handle standard output of a listBibl element 
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:listBibl">
        <ul class="listBibl">
            <xsl:for-each select="t:bibl">
                <li>
                    <xsl:if test="@xml:id">
                        <xsl:attribute name="id">
                            <xsl:value-of select="@xml:id"/>
                        </xsl:attribute>
                    </xsl:if>
                    <xsl:apply-templates mode="biblist"/>
                    <xsl:text>.</xsl:text>
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
    
    <!-- suppress bibl -->
    <xsl:template match="t:bibl" mode="title"/>
    <xsl:template match="t:bibl">
        <xsl:choose>
            <xsl:when test="@type=('lawd:Edition','lawd:Translation','lawd:WrittenWork')">
                <li>
                    <xsl:if test="descendant::t:lang/text()">
                        <span class="srp-label">
                            <xsl:value-of select="local:expand-lang(descendant::t:lang/text(),'lawd:Edition')"/>:
                        </span>
                    </xsl:if>
                    <span>
                        <xsl:call-template name="langattr"/>
                        <xsl:apply-templates select="self::*" mode="inline"/>
                        <xsl:if test="@type=('lawd:Edition','lawd:Translation') and t:listRelation/t:relation">
                            <xsl:variable name="parent" select="ancestor::t:body/t:bibl"/>
                            <xsl:variable name="bibl-type">
                                <xsl:choose>
                                    <xsl:when test="@type='lawd:Translation'">Translation</xsl:when>
                                    <xsl:otherwise>
                                        <xsl:text>Edition</xsl:text>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:variable>
                            <xsl:for-each select="t:listRelation/t:relation">
                                <xsl:variable name="bibl-rel">
                                    <xsl:variable name="bibl-id" select="tokenize(@passive,' ')[1]"/>
                                    <xsl:variable name="type" select="$parent/t:bibl[@xml:id = substring-after($bibl-id,'#')]/@type"/>
                                    <xsl:choose>
                                        <xsl:when test="$type = 'lawd:Edition'">
                                            Edition<xsl:if test="contains(@passive,' ')">
                                                <xsl:text>s</xsl:text>
                                            </xsl:if>
                                        </xsl:when>
                                        <xsl:when test="$type ='lawd:WrittenWork'">
                                            Syriac Manuscript Witnesse<xsl:if test="contains(@passive,' ')">
                                                <xsl:text>s</xsl:text>
                                            </xsl:if>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:value-of select="string($type)"/>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:variable>
                                <xsl:text> (</xsl:text>
                                <xsl:value-of select="$bibl-type"/>
                                <xsl:text> from  </xsl:text>
                                <xsl:value-of select="$bibl-rel"/>
                                <xsl:choose>
                                    <xsl:when test="contains(@passive,' ')">
                                        <xsl:for-each select="tokenize(@passive,' ')">
                                            <xsl:variable name="rel" select="substring-after(.,'#')"/>
                                            <xsl:for-each-group select="$parent/t:bibl" group-by="@type">
                                                <xsl:for-each select="current-group()">
                                                    <xsl:if test="@xml:id = $rel">
                                                        <xsl:text> </xsl:text>
                                                        <xsl:value-of select="position()"/>
                                                    </xsl:if>
                                                </xsl:for-each>
                                            </xsl:for-each-group>
                                            <xsl:if test="position() != last()">, </xsl:if>
                                        </xsl:for-each>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:variable name="rel" select="substring-after(@passive,'#')"/>
                                        <xsl:for-each-group select="$parent/t:bibl" group-by="@type">
                                            <xsl:for-each select="current-group()">
                                                <xsl:if test="@xml:id = $rel">
                                                    <xsl:text> </xsl:text>
                                                    <xsl:value-of select="position()"/>
                                                </xsl:if>
                                            </xsl:for-each>
                                        </xsl:for-each-group>
                                    </xsl:otherwise>
                                </xsl:choose>
                                <xsl:text>. See below.)</xsl:text>
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
    <xsl:template match="t:listPerson">
        <ul>
            <xsl:apply-templates/>
        </ul>
    </xsl:template>
    <xsl:template match="t:biblScope"/>
    <xsl:template match="t:biblStruct">
        <xsl:choose>
            <xsl:when test="parent::t:body">
                <div class="well preferred-citation">
                    <h4>Preferred Citation</h4>
                    <xsl:apply-templates select="self::*" mode="bibliography"/>.
                </div>
                <h3>Full Citation Information</h3>
                <div class="section indent">
                    <xsl:apply-templates mode="full"/>
                </div>
            </xsl:when>
            <xsl:otherwise>
                <span class="section indent">
                    <xsl:apply-templates mode="footnote"/>
                </span>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="t:listRelation">
        <xsl:apply-templates/>
    </xsl:template>
    <!-- Template to print out confession section -->
    <xsl:template match="t:state[@type='confession']">
        <!-- Get all ancesors of current confession (but only once) -->
        <xsl:variable name="confessions" select="document(concat($app-root,'/documentation/confessions.xml'))//t:body/t:list"/>
        <xsl:variable name="id" select="substring-after(@ref,'#')"/>
        <li>
            <xsl:value-of select="$id"/>: 
            <xsl:for-each select="$confessions//t:item[@xml:id = $id]/ancestor-or-self::*/t:label">
                <xsl:value-of select="."/>
            </xsl:for-each>
        </li>
    </xsl:template>

    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++  
     handle  output of  locations 
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
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
    <xsl:template match="t:offset | t:measure | t:source | t:choice">
        <xsl:if test="preceding-sibling::*">
            <xsl:text> </xsl:text>
        </xsl:if>
        <xsl:apply-templates select="." mode="plain"/>
    </xsl:template>
    
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     Description templates 
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <!-- Descriptions without list elements or paragraph elements -->
    <xsl:template match="t:desc | t:label" mode="plain">
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
            <xsl:apply-templates/>
        </li>
    </xsl:template>
    <xsl:template match="t:state | t:birth | t:death | t:floruit | t:sex | t:langKnowledge">
        <span class="srp-label">
            <xsl:choose>
                <xsl:when test="self::t:birth">Birth:</xsl:when>
                <xsl:when test="self::t:death">Death:</xsl:when>
                <xsl:when test="self::t:floruit">Floruit:</xsl:when>
                <xsl:when test="self::t:sex">Sex:</xsl:when>
                <xsl:when test="self::t:langKnowledge">Language Knowledge:</xsl:when>
                <xsl:when test="@role">
                    <xsl:value-of select="concat(upper-case(substring(@role,1,1)),substring(@role,2))"/>:
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat(upper-case(substring(@type,1,1)),substring(@type,2))"/>:        
                </xsl:otherwise>
            </xsl:choose>
        </span>
        <xsl:text> </xsl:text>
        <xsl:choose>
            <xsl:when test="count(t:date) &gt; 1">
                <xsl:for-each select="t:date">
                    <xsl:apply-templates/>
                    <xsl:sequence select="local:do-refs(@source,ancestor::t:*[@xml:lang][1])"/>
                    <xsl:if test="position() != last()"> or </xsl:if>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates mode="plain"/>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:sequence select="local:do-refs(@source,ancestor::t:*[@xml:lang][1])"/>
    </xsl:template>
    <xsl:template match="t:langKnown">
        <xsl:apply-templates/>
        <xsl:sequence select="local:do-refs(@source,ancestor::t:*[@xml:lang][1])"/>
    </xsl:template>

    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     handle standard output of a note element 
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:note">
        <xsl:variable name="xmlid" select="@xml:id"/>
        <xsl:choose>
            <xsl:when test="ancestor::t:choice">
                <xsl:text> (</xsl:text>
                <span>
                    <xsl:call-template name="langattr"/>
                    <xsl:apply-templates/>
                </span>
                <xsl:text>) </xsl:text>
                <xsl:if test="@source">
                    <xsl:sequence select="local:do-refs(@source,@xml:lang)"/>
                </xsl:if>
            </xsl:when>
            <!-- Adds definition list for depreciated names -->
            <xsl:when test="@type='deprecation'">
                <li>
                    <span>
                        <xsl:apply-templates select="../t:link[contains(@target,$xmlid)]"/>:
                            <xsl:apply-templates/>
                            <!-- Check for ending punctuation, if none, add . -->
                            <!-- NOTE not working -->
                    </span>
                    <xsl:if test="@source">
                        <xsl:sequence select="local:do-refs(@source,@xml:lang)"/>
                    </xsl:if>
                </li>
            </xsl:when>
            <xsl:when test="@type='ancientVersion'">
                <li class="note">
                    <xsl:if test="descendant::t:lang/text()">
                        <span class="srp-label">
                            <xsl:value-of select="local:expand-lang(descendant::t:lang/text(),'ancientVersion')"/>:
                        </span>
                    </xsl:if>
                    <span>
                        <xsl:call-template name="langattr"/>
                        <xsl:apply-templates/>
                    </span>
                    <xsl:if test="@source">
                        <xsl:sequence select="local:do-refs(@source,@xml:lang)"/>
                    </xsl:if>
                </li>
            </xsl:when>
            <xsl:when test="@type='modernTranslation'">
                <li>
                    <xsl:if test="descendant::t:lang/text()">
                        <span class="srp-label">
                            <xsl:value-of select="local:expand-lang(descendant::t:lang/text(),'modernTranslation')"/>:
                        </span>
                    </xsl:if>
                    <span>
                        <xsl:call-template name="langattr"/>
                        <xsl:apply-templates/>
                    </span>
                    <xsl:if test="@source">
                        <xsl:sequence select="local:do-refs(@source,@xml:lang)"/>
                    </xsl:if>
                </li>
            </xsl:when>
            <xsl:when test="@type='editions'">
                <li>
                    <span>
                        <xsl:call-template name="langattr"/>
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
                    <xsl:if test="@source">
                        <xsl:sequence select="local:do-refs(@source,@xml:lang)"/>
                    </xsl:if>
                </li>
            </xsl:when>
            <xsl:otherwise>
                <li>
                    <xsl:choose>
                        <xsl:when test="t:quote">
                            <xsl:apply-templates/>
                        </xsl:when>
                        <xsl:otherwise>
                            <span>
                                <xsl:call-template name="langattr"/>
                                <xsl:apply-templates/>
                                <!-- Check for ending punctuation, if none, add . -->
                                <!-- Do not have this working -->
                            </span>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:if test="@source">
                        <xsl:sequence select="local:do-refs(@source,@xml:lang)"/>
                    </xsl:if>
                </li>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="t:note" mode="abstract">
        <p>
            <xsl:apply-templates/>
            <xsl:if test="@source">
                <xsl:sequence select="local:do-refs(@source,@xml:lang)"/>
            </xsl:if>
        </p>
    </xsl:template>
    <!-- Handles t:link elements for deperciated notes, pulls value from matching element, output element and footnotes -->
    <xsl:template match="t:link">
        <xsl:variable name="elementID" select="substring-after(substring-before(@target,' '),'#')"/>
        <xsl:for-each select="/descendant-or-self::*[@xml:id=$elementID]">
            <xsl:apply-templates select="."/>
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
                <span dir="ltr">
                    <xsl:text> “</xsl:text>
                </span>
                <span>
                    <xsl:attribute name="dir">
                        <xsl:call-template name="getdirection"/>
                    </xsl:attribute>
                    <xsl:call-template name="langattr"/>
                    <xsl:apply-templates/>
                </span>
                <span dir="ltr">
                    <xsl:text>”  </xsl:text>
                </span>
            </xsl:when>
            <xsl:when test="parent::*/@xml:lang">
                <!-- Quotes need to be outside langattr for Syriac and arabic characters to render correctly.  -->
                <span dir="ltr">
                    <xsl:text> “</xsl:text>
                </span>
                <span class="langattr">
                    <xsl:attribute name="dir">
                        <xsl:choose>
                            <xsl:when test="parent::*[@xml:lang='en']">ltr</xsl:when>
                            <xsl:when test="parent::*[@xml:lang='syr' or @xml:lang='ar' or @xml:lang='syc' or @xml:lang='syr-Syrj']">rtl</xsl:when>
                            <xsl:otherwise>ltr</xsl:otherwise>
                        </xsl:choose>
                    </xsl:attribute>
                    <xsl:attribute name="lang">
                        <xsl:value-of select="parent::*/@xml:lang"/>
                    </xsl:attribute>
                    <xsl:apply-templates/>
                </span>
                <span dir="ltr">
                    <xsl:text>”  </xsl:text>
                </span>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text> “</xsl:text>
                <xsl:apply-templates/>
                <xsl:text>” </xsl:text>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:if test="@source or parent::*/@source">
            <span class="langattr">
                <xsl:attribute name="dir">
                    <xsl:choose>
                        <xsl:when test="parent::t:desc[@xml:lang='en']">ltr</xsl:when>
                        <xsl:when test="parent::t:desc[@xml:lang='syr' or @xml:lang='ar' or @xml:lang='syc' or @xml:lang='syr-Syrj']">rtl</xsl:when>
                        <xsl:otherwise>ltr</xsl:otherwise>
                    </xsl:choose>
                </xsl:attribute>
                <xsl:if test="@source">
                    <xsl:sequence select="local:do-refs(@source,ancestor::t:*[@xml:lang][1])"/>
                </xsl:if>
            </span>
        </xsl:if>
    </xsl:template>
    <xsl:template match="t:persName | t:region | t:settlement | t:placeName | t:author | t:editor">
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
                            <xsl:call-template name="langattr"/>
                            <xsl:apply-templates/>
                        </span>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text> </xsl:text>
                        <a class="{local-name(.)}" href="{@ref}">
                            <xsl:call-template name="langattr"/>
                            <xsl:apply-templates/>
                        </a>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <span class="{local-name(.)}">
                    <xsl:call-template name="langattr"/>
                    <xsl:apply-templates/>
                    <xsl:sequence select="local:do-refs(@source,@xml:lang)"/>
                </span>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="t:persName" mode="title">
        <span class="persName">
            <xsl:call-template name="langattr"/>
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
                        <xsl:call-template name="langattr"/>
                        <xsl:apply-templates/>
                    </span>
                    <xsl:sequence select="local:do-refs(@source,ancestor::t:*[@xml:lang][1])"/>
                </span>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="t:persName" mode="plain">
        <span class="persName">
            <xsl:call-template name="langattr"/>
            <xsl:apply-templates/>
        </span>
    </xsl:template>
    <xsl:template match="t:roleName">
        <xsl:apply-templates mode="plain"/>
        <xsl:text> </xsl:text>
    </xsl:template>
    <xsl:template match="t:forename | t:addName">
        <xsl:if test="preceding-sibling::*">
            <xsl:text> </xsl:text>
        </xsl:if>
        <xsl:apply-templates mode="plain"/>
        <xsl:if test="following-sibling::*">
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
                        <xsl:call-template name="langattr"/>
                        <xsl:apply-templates select="." mode="plain"/>
                    </span>
                    <xsl:sequence select="local:do-refs(@source,ancestor::t:*[@xml:lang][1])"/>
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
    
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     handle standard output of the licence element in the tei header
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:licence">
        <xsl:if test="@target">
            <a rel="license" href="{@target}">
                <img alt="Creative Commons License" style="border-width:0" src="{$nav-base}/resources/img/cc.png" height="18px"/>
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
    <xsl:template match="t:relation">
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
                            Relation
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
    </xsl:template>
    <!-- NOTE: would really like to get rid of mode=cleanout -->
    <xsl:template match="t:placeName[local-name(..)='desc']" mode="cleanout">
        <xsl:apply-templates select="."/>
    </xsl:template>
    <!-- NOTE: For SPEAR, could cause issues in the future.  -->
    <xsl:template match="t:div">
        <xsl:apply-templates select="*[not(self::t:bibl)]"/>
    </xsl:template>
    <xsl:template match="t:*" mode="inline" xml:space="preserve">
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="t:*" mode="plain" xml:space="preserve">
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="text()" mode="cleanout">
        <xsl:value-of select="."/>
    </xsl:template>
    <xsl:template match="t:*" mode="cleanout">
        <xsl:apply-templates mode="cleanout"/>
    </xsl:template>
    <xsl:template name="getdirection">
        <xsl:choose>
            <xsl:when test="@xml:lang='en'">ltr</xsl:when>
            <xsl:when test="@xml:lang='syr' or @xml:lang='ar' or @xml:lang='syc' or @xml:lang='syr-Syrj'">rtl</xsl:when>
            <xsl:when test="not(@xml:lang)">
                <xsl:text/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||| -->
    <!-- |||| match=t:*: suppress all TEI elements not otherwise handled -->
    <!-- ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||| -->
    <!--<xsl:template match="t:*"/>-->
    
</xsl:stylesheet>