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
       bibliography.xsl
       
       This XSLT provides templates for output of bibliographic material. 
       
       parameters:
       
       assumptions and dependencies:
        + transform has been tested with Saxon PE 9.4.0.6 with initial
          template (-it) option set to "do-index" (i.e., there is no 
          single input file)
        
       code by:
        + Winona Salesky (http://www.wsalesky.com) 
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
    
    
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     generate a footnote for the matched bibl entry; if it contains a 
     pointer, try to look up the master bibliography file and use that
     
     assumption: you want the footnote in a list item (li) element
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:bibl" mode="footnote">
        <xsl:param name="footnote-number">-1</xsl:param>
        <xsl:variable name="thisnum">
            <!-- Isolates footnote number in @xml:id-->
            <xsl:choose>
                <xsl:when test="$footnote-number='-1'">
                    <xsl:value-of select="substring-after(@xml:id, '-')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$footnote-number"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <!-- When ptr is available, use full bibl record (indicated by ptr) -->
        <xsl:choose>
            <!-- NOTE: unclear what use case this handles.  -->
            <xsl:when test="descendant::t:ptr[@target and starts-with(@target, '#')]">
                <xsl:variable name="target" select="substring-after(descendant::t:ptr/@target,'#')"/>
                <xsl:apply-templates select="/t:body/t:back/descendant::t:bibl[@xml:id = $target]" mode="footnote"/>
            </xsl:when>
            <!-- Main footnote display, used by "Sources" portion of Syriaca.org pages -->
            <xsl:otherwise>
                <li id="{@xml:id}">
                    <span class="anchor"/>
                    <!-- Display footnote number -->
                    <span class="footnote-tgt">
                        <xsl:value-of select="$thisnum"/>
                    </span>
                    <xsl:text> </xsl:text>
                    <span class="footnote-content">
                        <xsl:choose>
                            <xsl:when test="t:ptr[@target and starts-with(@target, concat($base-uri,'/bibl/'))]">
                                <!-- Find file path for bibliographic record -->
                                <xsl:variable name="biblfilepath">
                                    <xsl:value-of select="concat($data-root,'/bibl/tei/',substring-after(t:ptr/@target, concat($base-uri,'/bibl/')),'.xml')"/>
                                </xsl:variable>
                                <xsl:variable name="citedRange">
                                    <xsl:if test="t:citedRange">
                                        <xsl:text>, </xsl:text>
                                        <xsl:for-each select="t:citedRange">
                                            <xsl:apply-templates select="." mode="footnote"/>
                                        </xsl:for-each>
                                    </xsl:if>
                                </xsl:variable>
                                <!-- Check if record exists in db with doc-available function -->
                                <xsl:if test="doc-available($biblfilepath)">
                                    <!-- Process record as a footnote -->
                                    <xsl:for-each select="document($biblfilepath)/descendant::t:biblStruct[1]">
                                        <xsl:apply-templates mode="footnote"/>
                                        <!-- Process all citedRange elements as footnotes -->
                                        <xsl:sequence select="$citedRange"/>
                                        <span class="footnote-links">
                                            <xsl:apply-templates select="descendant::t:idno" mode="links"/>
                                            <xsl:apply-templates select="descendant::t:ref[not(ancestor::note)]" mode="links"/>
                                        </span>
                                    </xsl:for-each>
                                </xsl:if>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:apply-templates mode="footnote"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </span>
                </li>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     Main footnote templates.  
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:biblStruct" mode="footnote">
        <xsl:apply-templates mode="footnote"/>
    </xsl:template>

    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     handle a bibllist entry for a book
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:biblStruct[t:monogr and not(t:analytic)]" mode="biblist">
        <!-- this is a monograph/book -->
        <xsl:apply-templates select="t:monogr" mode="footnote"/>
    </xsl:template>
    
    <!-- Structure of analytic section.  -->
    <xsl:template match="t:analytic" mode="footnote">
        <!-- Display authors/editors -->
        <xsl:call-template name="persons"/>
        <!-- Analytic title(s) -->
        <xsl:apply-templates select="t:title" mode="footnote"/>
        
        <!-- If monograph is level='m' include 'in' -->
        <xsl:if test="following-sibling::t:monogr/t:title[1][@level='m']">
            <xsl:text> in</xsl:text>
        </xsl:if>
        <!-- Space if followed by monograph -->
        <xsl:if test="following-sibling::t:monogr">
            <xsl:text> </xsl:text>
        </xsl:if>
    </xsl:template>
    
    <!-- Structure of monograph section.  -->
    <xsl:template match="t:monogr" mode="footnote">
        <!-- Display authors/editors -->
        <!-- Suppress duplicate authors for records with multiple t:monogr elements -->
        <xsl:choose>
            <xsl:when test="preceding-sibling::t:monogr">
                <xsl:choose>
                    <xsl:when test="deep-equal(t:editor | t:author, preceding-sibling::t:monogr/t:editor | preceding-sibling::t:monogr/t:author )"/>
                    <xsl:otherwise>
                        <xsl:call-template name="persons"/>
                    </xsl:otherwise>
                </xsl:choose>
                <!-- Check authors against preceding, suppress if equivalent -->
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="persons"/>
            </xsl:otherwise>
        </xsl:choose>
        <!-- Titles -->
        <xsl:apply-templates select="t:title" mode="footnote"/>
        <!-- handle translator, if present -->
        <xsl:if test="count(t:editor[@role='translator']) &gt; 0">
            <xsl:text>, trans. </xsl:text>
            <!-- Process translator using local function in helper-functions.xsl local:emit-responsible-persons -->
            <xsl:sequence select="local:emit-responsible-persons(t:editor[@role='translator'],'footnote',3)"/>
        </xsl:if>
        <!-- Add edition  -->
        <xsl:if test="t:edition">
            <xsl:text> </xsl:text>
            <xsl:apply-templates select="t:edition" mode="footnote"/>
            <xsl:text> </xsl:text>
        </xsl:if>
        <!-- Add vol  -->
        <xsl:if test="t:biblScope[@unit='vol']">
            <xsl:text> </xsl:text>
            <xsl:apply-templates select="t:biblScope[@unit='vol']" mode="footnote"/>
            <xsl:text> </xsl:text>
        </xsl:if>
        <xsl:choose>
            <xsl:when test="following-sibling::t:series">
                <xsl:apply-templates select="t:series" mode="footnote"/>
            </xsl:when>
            <xsl:when test="following-sibling::t:monogr">
                <xsl:text>, </xsl:text>
            </xsl:when>
            <xsl:when test="preceding-sibling::t:monogr">
                <xsl:apply-templates select="preceding-sibling::t:monogr/t:imprint" mode="footnote"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="t:imprint" mode="footnote"/>
                <xsl:if test="following-sibling::t:monogr">
                    <xsl:text>, </xsl:text>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     Series output
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:series" mode="footnote">
        <xsl:text> (</xsl:text>
        <xsl:if test="preceding-sibling::t:monogr/t:title[@level='j']">
            <xsl:text>=</xsl:text>
        </xsl:if>
        <xsl:apply-templates select="t:title" mode="footnote"/>
        <xsl:if test="t:biblScope">
            <xsl:text>, </xsl:text>
            <xsl:for-each select="t:biblScope[@unit='series'] | t:biblScope[@unit='vol']">
                <xsl:apply-templates select="." mode="footnote"/>
                <xsl:if test="position() != last()">
                    <xsl:text>, </xsl:text>
                </xsl:if>
            </xsl:for-each>
        </xsl:if>
        <xsl:if test="preceding-sibling::t:monogr/t:imprint">
            <xsl:variable name="impring-string">
                <xsl:apply-templates select="preceding-sibling::t:monogr/t:imprint" mode="footnote"/>
            </xsl:variable>
            <xsl:text>; </xsl:text>
            <xsl:value-of select="substring-before(substring-after($impring-string,'('),')')"/>
        </xsl:if>
        <xsl:text>)</xsl:text>
    </xsl:template>
    
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     Template ouputs authors and editors for analytic and monograph sections
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template name="persons">
        <!-- If edited -->
        <xsl:variable name="edited" select="if (t:editor[not(@role) or @role!='translator']) then true() else false()"/>
        <!-- count editors/authors  -->
        <xsl:variable name="rcount">
            <xsl:choose>
                <xsl:when test="t:author">
                    <xsl:value-of select="count(t:author)"/>
                </xsl:when>
                <xsl:when test="$edited">
                    <xsl:value-of select="count(t:editor[not(@role) or @role!='translator'])"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="count(t:author)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="bookAuth">
            <!-- Process editors/authors using local function in helper-functions.xsl local:emit-responsible-persons -->
            <xsl:choose>
                <xsl:when test="t:author">
                    <xsl:choose>
                        <xsl:when test="t:author/t:persName">
                            <xsl:sequence select="local:emit-responsible-persons(t:author/t:persName[not(contains(@xml:lang,'Latn-iso9r95'))],'footnote',3)"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:sequence select="local:emit-responsible-persons(t:author,'footnote',3)"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:when test="$edited">
                    <xsl:choose>
                        <xsl:when test="t:editor[not(@role) or @role!='translator']/t:persName">
                            <xsl:sequence select="local:emit-responsible-persons(t:editor[not(@role) or @role!='translator']/t:persName[not(contains(@xml:lang,'Latn-iso9r95'))],'footnote',3)"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:sequence select="local:emit-responsible-persons(t:editor[not(@role) or @role!='translator'],'footnote',3)"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:choose>
                        <xsl:when test="t:author/t:persName">
                            <xsl:sequence select="local:emit-responsible-persons(t:author/t:persName[not(contains(@xml:lang,'Latn-iso9r95'))],'footnote',3)"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:sequence select="local:emit-responsible-persons(t:author,'footnote',3)"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:if test="not(t:author)">
                <xsl:if test="$edited">
                    <xsl:choose>
                        <xsl:when test="$rcount = 1">
                            <xsl:text> (ed.)</xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:text> (eds.)</xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:if>
            </xsl:if>
        </xsl:variable>
        <xsl:value-of select="normalize-space($bookAuth)"/>
        <xsl:choose>
            <xsl:when test="self::t:monogr and not(preceding-sibling::t:analytic)">
                <xsl:text>. </xsl:text>
            </xsl:when>
            <xsl:when test="$bookAuth != ''">
                <xsl:text>, </xsl:text>
            </xsl:when>
        </xsl:choose>
    </xsl:template>

    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     generate a bibl list entry for the matched bibl; if it contains a 
     pointer, try to look up the master bibliography file and use that
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:bibl" mode="biblist">
        <xsl:choose>
            <xsl:when test="t:ptr">
                <xsl:apply-templates select="t:ptr" mode="biblist"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates mode="biblist"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>  

    
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     handle a ptr inside a bibl: try to look up the corresponding item
     internally or externally and process that
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:ptr[ancestor::t:*[1]/self::t:bibl]" mode="biblist">
        <xsl:if test="starts-with(@target, '#')">
            <xsl:variable name="thistarget" select="substring-after(@target, '#')"/>
            <xsl:apply-templates select="/descendant::t:bibl[@xml:id=$thistarget]" mode="biblist"/>
        </xsl:if>
        <xsl:if test="starts-with(@target, concat($base-uri,'/bibl/'))">
            <xsl:variable name="biblfilepath">
                <xsl:value-of select="concat($data-root,'/bibl/tei/',substring-after(@target, concat($base-uri,'/bibl/')),'.xml')"/>
            </xsl:variable>
            <xsl:if test="doc-available($biblfilepath)">
                <xsl:apply-templates select="document($biblfilepath)/descendant::t:biblStruct[1]" mode="biblist"/>
            </xsl:if>
        </xsl:if>
    </xsl:template>
    
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     handle name components in the context of a footnote
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:forename | t:addName | t:surname" mode="footnote" priority="1">
        <xsl:if test="preceding-sibling::t:*">
            <xsl:text> </xsl:text>
        </xsl:if>
        <xsl:apply-templates mode="footnote"/>
    </xsl:template>

    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     handle date, publisher, place of publication, placenames and foreign
     tags (i.e., language+script changes) in footnote context (the main
     reason for this is to capture language and script changes at these
     levels)
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:date | t:publisher | t:pubPlace | t:placeName | t:foreign" mode="footnote" priority="1">
        <xsl:if test="preceding-sibling::* and not(self::t:pubPlace)">
            <xsl:text> </xsl:text>
        </xsl:if>
        <span class="{local-name()}">
            <xsl:call-template name="langattr"/>
            <xsl:apply-templates mode="footnote"/>
        </span>
    </xsl:template>
   
    
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     handle personal names in the context of a footnote
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:persName | t:name" mode="footnote">
        <span class="{local-name()}">
            <xsl:call-template name="langattr"/>
            <xsl:choose>
                <xsl:when test="t:*">
                    <xsl:apply-templates select="t:*" mode="footnote"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates mode="footnote"/>
                </xsl:otherwise>
            </xsl:choose>
        </span>
    </xsl:template>

    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     handle personal names last-name first
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:persName" mode="lastname-first">
        <span class="persName">
            <xsl:call-template name="langattr"/>
            <xsl:choose>
                <xsl:when test="t:surname and t:forename">
                    <xsl:apply-templates select="t:surname" mode="footnote"/>
                    <xsl:text>, </xsl:text>
                    <xsl:apply-templates select="t:*[local-name()!='surname']" mode="footnote"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="t:*" mode="footnote"/>
                </xsl:otherwise>
            </xsl:choose>
        </span>
    </xsl:template>    
    
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     handle authors and editors in the context of a footnote
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:author | t:editor | t:principal | t:person" mode="footnote biblist" priority="1">
        <xsl:choose>
            <xsl:when test="@ref and starts-with(@ref, $editoruriprefix)">
                <xsl:variable name="sought" select="substring-after(@ref, $editoruriprefix)"/>
                <xsl:apply-templates select="document($editorssourcedoc)/descendant::t:body/t:listPerson[1]/t:person[@xml:id=$sought][1]" mode="footnote"/>
            </xsl:when>
            <xsl:otherwise>
                <span class="{local-name()}">
                    <xsl:choose>
                        <xsl:when test="t:persName[starts-with(@xml:lang,'en')]">
                            <xsl:apply-templates select="t:persName[starts-with(@xml:lang,'en')][1]" mode="footnote"/>
                        </xsl:when>
                        <xsl:when test="t:persName">
                            <xsl:apply-templates select="t:persName[1]" mode="footnote"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates mode="footnote"/>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:text> </xsl:text>
                </span>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     handle authors and editors in the context of a footnote
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:author | t:editor | t:principal | t:person" mode="lastname-first" priority="1">
        <xsl:choose>
            <!-- if @ref exists use external editors.xml document from database -->
            <xsl:when test="@ref and starts-with(@ref, $editoruriprefix)">
                <xsl:variable name="sought" select="substring-after(@ref, $editoruriprefix)"/>
                <!-- grab editors.xml and process appropriate elements based in ref # -->
                <xsl:apply-templates select="document($editorssourcedoc)/descendant::t:body/t:listPerson[1]/t:person[@xml:id=$sought][1]" mode="lastname-first"/>
            </xsl:when>
            <!-- otherwise processes name as exists in place page -->
            <xsl:otherwise>
                <span class="{local-name()}">
                    <xsl:choose>
                        <xsl:when test="t:persName">
                            <xsl:apply-templates select="t:persName[1]" mode="lastname-first"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates mode="footnote"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </span>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     handle the imprint component of a biblScope
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:edition" mode="footnote">
        <xsl:text>(</xsl:text>
        <xsl:value-of select="local:ordinal(text())"/>
        <xsl:text>)</xsl:text>
    </xsl:template>
    
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     handle the imprint component of a biblScope
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:biblScope" mode="footnote">
        <xsl:variable name="unit">
            <xsl:choose>
                <xsl:when test="@unit = 'vol'">
                    <xsl:value-of select="concat(@unit,'.')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="@unit"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="matches(text(),'^\d')">
                <xsl:value-of select="concat($unit,' ',text())"/>
            </xsl:when>
            <xsl:when test="not(text()) and (@to or @from)">
                <xsl:choose>
                    <xsl:when test="@to = @from">
                        <xsl:value-of select="concat($unit,' ',@to)"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="concat($unit,' ',@from,' - ',@to)"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>TEST
                <xsl:value-of select="text()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     handle the imprint component of a biblStruct
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:imprint" mode="footnote biblist" priority="1">
        <xsl:if test="preceding-sibling::t:title">
            <xsl:text> </xsl:text>
        </xsl:if>
        <xsl:text>(</xsl:text>
        <xsl:choose>
            <xsl:when test="t:pubPlace[starts-with(@xml:lang,'en')]">
                <xsl:apply-templates select="t:pubPlace[starts-with(@xml:lang,'en')]" mode="footnote"/>
            </xsl:when>
            <xsl:when test="t:pubPlace">
                <xsl:apply-templates select="t:pubPlace[1]" mode="footnote"/>
            </xsl:when>
        </xsl:choose>
        <xsl:if test="t:pubPlace and t:publisher">
            <xsl:text>: </xsl:text>
        </xsl:if>
        <xsl:choose>
            <xsl:when test="t:publisher[starts-with(@xml:lang,'en')]">
                <xsl:apply-templates select="t:publisher[starts-with(@xml:lang,'en')]" mode="footnote"/>
            </xsl:when>
            <xsl:when test="t:publisher">
                <xsl:apply-templates select="t:publisher[1]" mode="footnote"/>
            </xsl:when>
        </xsl:choose>
        <!-- For Monographs only -->
        <xsl:if test="not(t:pubPlace) and not(t:publisher) and t:title[@level='m']">
            <abbr title="no publisher">n.p.</abbr>
        </xsl:if>
        <xsl:if test="t:date/preceding-sibling::*">
            <xsl:text>, </xsl:text>
        </xsl:if>
        <xsl:choose>
            <xsl:when test="t:date">
                <xsl:apply-templates select="t:date" mode="footnote"/>
            </xsl:when>
            <xsl:otherwise>
                <abbr title="no date of publication">n.d.</abbr>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:if test="following-sibling::t:biblScope[@unit='series']">
            <xsl:text>, </xsl:text>
            <xsl:apply-templates select="../t:biblScope[@unit='series']" mode="footnote"/>
        </xsl:if>
        <xsl:text>)</xsl:text>
    </xsl:template>
    
    
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     handle cited ranges in the context of a footnote
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:citedRange[ancestor::t:bibl or ancestor::t:biblStruct]" mode="footnote" priority="1">
        <xsl:choose>
            <xsl:when test="@unit = preceding-sibling::*/@unit"/>
            <xsl:when test="@unit='ff'"/>
            <xsl:otherwise>
                <xsl:value-of select="concat(@unit,': ')"/>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:choose>
            <xsl:when test="@target">
                <a href="{@target}">
                    <xsl:choose>
                        <xsl:when test="@unit='ff'">
                            <xsl:text>, f. </xsl:text>
                            <xsl:apply-templates select="." mode="out-normal"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates select="." mode="out-normal"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </a>
            </xsl:when>
            <xsl:otherwise>
                <xsl:choose>
                    <xsl:when test="@unit='ff'">
                        <xsl:text>, f. </xsl:text>
                        <xsl:apply-templates select="." mode="out-normal"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates select="." mode="out-normal"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:for-each select="t:note[not(@type='flag')]">
            <xsl:text> (</xsl:text>
            <xsl:value-of select="."/>
            <xsl:text>) </xsl:text>
        </xsl:for-each>
        <xsl:choose>
            <xsl:when test="following-sibling::*[not(self::t:ptr)]">, </xsl:when>
            <xsl:otherwise>.</xsl:otherwise>
        </xsl:choose>
    </xsl:template>


    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     handle bibliographic titles in the context of a footnote
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:title" mode="footnote biblist allbib" priority="1">
        <xsl:if test="not(contains(@xml:lang,'Latn-'))">
            <xsl:if test="parent::t:analytic">
                <xsl:text>"</xsl:text>
            </xsl:if>
            <span>
                <xsl:attribute name="class">
                    <xsl:text>title</xsl:text>
                    <xsl:choose>
                        <xsl:when test="@level='a'">
                            <xsl:text>-analytic</xsl:text>
                        </xsl:when>
                        <xsl:when test="@level='m'">
                            <xsl:text>-monographic</xsl:text>
                        </xsl:when>
                        <xsl:when test="@level='j'">
                            <xsl:text>-journal</xsl:text>
                        </xsl:when>
                        <xsl:when test="@level='s'">
                            <xsl:text>-series</xsl:text>
                        </xsl:when>
                        <xsl:when test="@level='u'">
                            <xsl:text>-unpublished</xsl:text>
                        </xsl:when>
                    </xsl:choose>
                </xsl:attribute>
                <xsl:for-each select="./node()">
                    <xsl:if test="not(self::text()) or string-length(normalize-space(.))&gt;0 or count(following-sibling::node())=0">
                        <bdi>
                            <xsl:for-each select="ancestor-or-self::t:*[@xml:lang][1]">
                                <xsl:attribute name="dir">
                                    <xsl:call-template name="getdirection"/>
                                </xsl:attribute>
                                <xsl:call-template name="langattr"/>
                            </xsl:for-each>
                            <xsl:apply-templates select="." mode="text-normal"/>
                        </bdi>
                    </xsl:if>
                </xsl:for-each>
            </span>
            <xsl:if test="parent::t:analytic">
                <xsl:if test="not(ends-with(.,'.|:|,'))">,</xsl:if>
                <xsl:text>"</xsl:text>
            </xsl:if>
        </xsl:if>
    </xsl:template>
    
    <!-- Templates for adding links and icons to uris -->
    <xsl:template match="t:idno | t:ref" mode="links">
        <xsl:variable name="ref">
            <xsl:choose>
                <xsl:when test="self::t:ref">
                    <xsl:value-of select="@target"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="text()"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <span class="footnote-icon">
            <xsl:choose>
                <xsl:when test="@type='zotero'"/>
                <xsl:when test="starts-with($ref,$base-uri)">
                    <a href="{replace($ref,$base-uri,$nav-base)}" title="Link to Syriaca.org Bibliographic Record" data-toggle="tooltip" data-placement="top">
                        <img src="{$nav-base}/resources/img/icons-syriaca-sm.png" alt="Link to Syriaca.org Bibliographic Record"/>
                    </a>
                </xsl:when>
                <!-- glyphicon glyphicon-book -->
                <xsl:when test="starts-with($ref,'http://www.worldcat.org/')">
                    <a href="{$ref}" title="Link to Worldcat Bibliographic record" data-toggle="tooltip" data-placement="top">
                        <span class="glyphicon glyphicon-book" aria-hidden="true"/>
                    </a>
                </xsl:when>
                <xsl:when test="starts-with($ref,'http://catalog.hathitrust.org/')">
                    <a href="{$ref}" title="Link to HathiTrust Bibliographic record" data-toggle="tooltip" data-placement="top">
                        <span class="glyphicon glyphicon-book" aria-hidden="true"/>
                    </a>
                </xsl:when>
                <xsl:when test="starts-with($ref,'http://digitale-sammlungen.ulb.uni-bonn.de')">
                    <a href="{$ref}" title="Link to UniversitätBonn Bibliographic record" data-toggle="tooltip" data-placement="top">
                        <span class="glyphicon glyphicon-book" aria-hidden="true"/>
                    </a>
                </xsl:when>
                <xsl:when test="starts-with($ref,'https://archive.org')">
                    <a href="{$ref}" title="Link to Archive.org Bibliographic record" data-toggle="tooltip" data-placement="top">
                        <span class="glyphicon glyphicon-book" aria-hidden="true"/>
                    </a>
                </xsl:when>
                <xsl:otherwise>
                    <a href="{$ref}" data-toggle="tooltip" data-placement="top" title="{$ref}">
                        <span class="glyphicon glyphicon-book"/>
                    </a>
                </xsl:otherwise>
            </xsl:choose>
        </span>
    </xsl:template>
    
    <!-- Templates for full bibl display -->
    <xsl:template match="t:biblStruct" mode="full">
        <xsl:apply-templates mode="full"/>
    </xsl:template>
    <xsl:template match="t:analytic" mode="full">
        <h4>Article</h4>
        <xsl:apply-templates mode="full"/>
    </xsl:template>
    <xsl:template match="t:monogr" mode="full">
        <h4>Monograph/Journal</h4>
        <xsl:apply-templates mode="full"/>
    </xsl:template>
    <xsl:template match="t:series" mode="full">
        <h4>Series</h4>
        <xsl:apply-templates mode="full"/>
    </xsl:template>
    <xsl:template match="t:ref" mode="full">
        <p class="indent">
            <span class="srp-label">
                <xsl:value-of select="concat(upper-case(substring(name(.),1,1)),substring(name(.),2))"/>: </span>
            <xsl:choose>
                <xsl:when test="@target">
                    <xsl:value-of select="@target"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates mode="footnote"/>
                </xsl:otherwise>
            </xsl:choose>
        </p>
    </xsl:template>
    <xsl:template match="*" mode="full">
        <p class="indent">
            <span class="srp-label">
                <xsl:value-of select="concat(upper-case(substring(name(.),1,1)),substring(name(.),2))"/>: </span>
            <xsl:apply-templates mode="footnote"/>
        </p>
    </xsl:template>
    
    
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     suppress otherwise unhandled descendent nodes and attibutes of bibl or 
     biblStruct in the context of a footnote 
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:* | @*" mode="footnote"/>
   
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     suppress otherwise unhandled descendent nodes of bibl or biblStruct
     in the context of a bibliographic list 
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:*" mode="biblist"/>
    
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     suppress otherwise unhandled descendent nodes of bibl or biblStruct
     in universal bibliographic context 
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:*" mode="allbibl"/>
    
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     suppress otherwise unhandled descendent nodes of bibl or biblStruct
     in universal bibliographic context 
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:*" mode="lastname-first"/>
    
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     emit the footnote number for a bibl
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:bibl" mode="footnote-ref">
        <xsl:param name="footnote-number">1</xsl:param>
        <span class="footnote-ref">
            <a href="#{@xml:id}">
                <xsl:value-of select="$footnote-number"/>
            </a>
        </span>
    </xsl:template>
</xsl:stylesheet>