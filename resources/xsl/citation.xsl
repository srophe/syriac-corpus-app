<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:saxon="http://saxon.sf.net/" xmlns:local="http://syriaca.org/ns" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:x="http://www.w3.org/1999/xhtml" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs t x saxon local" version="2.0">
    
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
       citation.xsl
       
       This XSLT provides templates for output of citation guidance. 
       
       parameters:
       
       assumptions and dependencies:
        + transform has been tested with Saxon PE 9.4.0.6 with initial
          template (-it) option set to "do-index" (i.e., there is no 
          single input file)
        
       code by: 
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
    <xsl:variable name="uri" select="replace(//t:publicationStmt/t:idno[@type='URI'][1],'/tei','')"/>
    
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     generate a footnote for the matched titleStmt element
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:titleStmt" mode="cite-foot">
        <!-- creator(s) of the entry -->
        <!-- Process editors/authors using local function in helper-functions.xsl local:emit-responsible-persons -->
        <xsl:sequence select="local:emit-responsible-persons(t:author[not(@role='anonymous')],'footnote',1)"/>
        <xsl:if test="t:author[not(@role='anonymous')]">
            <xsl:text>, </xsl:text>            
        </xsl:if>

        
        <!-- title of the entry -->
        <xsl:text>“</xsl:text>
        <xsl:apply-templates select="t:title[@level='a']" mode="footnote"/>
        <xsl:text>,”</xsl:text>
        
        <!-- fileDesc/editionStmt/respStmt/resp] -->
        <xsl:text> </xsl:text>
        <xsl:value-of select="//t:fileDesc/t:editionStmt/t:respStmt[1]/t:resp"/>
        <xsl:text> </xsl:text>
        <xsl:call-template name="responsibility"/>
        <xsl:text>, </xsl:text>
        
        <!-- monographic title -->
        <xsl:text> </xsl:text>
        <xsl:apply-templates select="t:title[@level='s'][position()=last()]" mode="footnote"/>
        <xsl:text>, </xsl:text>

        <!-- publication date statement -->
        <xsl:text> last modified </xsl:text>
        <xsl:for-each select="../../t:revisionDesc/t:change[1]">
            <xsl:choose>
                <xsl:when test="@when castable as xs:date">
                    <xsl:value-of select="format-date(xs:date(@when), '[MNn] [D], [Y]')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="@when"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
        <xsl:text>,</xsl:text>
        
        <!-- project -->
        <!--
        <xsl:text> </xsl:text>
        <xsl:value-of select="t:sponsor[1]"/>
        <xsl:text>, ed. </xsl:text>
        <xsl:sequence select="local:emit-responsible-persons(t:principal,'footnote',2)"/>
        <xsl:if test="following-sibling::t:principal">
            <xsl:text>, </xsl:text>
        </xsl:if>
        <xsl:text>.</xsl:text>
        -->
        <xsl:text> </xsl:text>
        <a href="{$uri}">
            <xsl:value-of select="$uri"/>
        </a>
        <xsl:text>.</xsl:text>
    </xsl:template>
    
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     generate a bibliographic entry for the matched titleStmt element
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:titleStmt" mode="cite-biblist">
        <!-- creator(s) of the entry -->
        <!-- Process editors/authors using local function in helper-functions.xsl local:emit-responsible-persons -->
        <xsl:sequence select="local:emit-responsible-persons(t:author[not(@role='anonymous')],'footnote',1)"/>
        <xsl:if test="t:author[not(@role='anonymous')]">
            <xsl:text>. </xsl:text>            
        </xsl:if>
        
        <!-- title of the entry -->
        <xsl:text>“</xsl:text>
        <xsl:apply-templates select="t:title[@level='a']" mode="footnote"/>
        <xsl:text>.”</xsl:text>
        
        <!-- fileDesc/editionStmt/respStmt/resp] -->
        <xsl:text> </xsl:text>
        <xsl:variable name="resp" select="//t:fileDesc/t:editionStmt/t:respStmt[1]/t:resp"/>
        <xsl:value-of select="concat(upper-case(substring($resp,1,1)),substring($resp, 2))"/>
        <xsl:text> </xsl:text>
        <xsl:call-template name="responsibility"/>
        <xsl:text>. </xsl:text>
        
        <!-- monographic title -->
        <xsl:text> </xsl:text>
        <xsl:apply-templates select="t:title[@level='s'][position()=last()]" mode="footnote"/>
        <xsl:text>. </xsl:text>
        
        <!-- publication date statement -->
        <xsl:text> Last modified </xsl:text>
        <xsl:for-each select="../../t:revisionDesc/t:change[1]">
            <xsl:choose>
                <xsl:when test="@when castable as xs:date">
                    <xsl:value-of select="format-date(xs:date(@when), '[MNn] [D], [Y]')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="@when"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
        <xsl:text>.</xsl:text>
        
        <xsl:text> </xsl:text>
        <a href="{$uri}">
            <xsl:value-of select="$uri"/>
        </a>
        <xsl:text>.</xsl:text>
    </xsl:template>
    
    <!-- Named template to output responsibility statement -->
    <xsl:template name="responsibility">
        <xsl:choose>
            <xsl:when test="//t:fileDesc/t:editionStmt/t:respStmt/t:name/t:ptr"> 
                <xsl:variable name="source" select="replace(string(//t:fileDesc/t:editionStmt/t:respStmt/t:name/t:ptr/@target),'#','')"/>
                <xsl:choose>
                    <xsl:when test="//t:sourceDesc[@xml:id = $source]">
                        <xsl:for-each select="//t:sourceDesc[@xml:id = $source]">
                            <xsl:choose>
                                <xsl:when test="t:biblStruct">
                                    <xsl:apply-templates select="t:biblStruct" mode="footnote"/>
                                </xsl:when>
                                <xsl:when test="t:msDesc">
                                    <xsl:value-of select="t:msDesc/t:msIdentifier/t:altIdentifier[@type='preferred']/t:idno/text()"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:apply-templates/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:for-each>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:for-each select="//t:teiHeader/t:fileDesc/t:sourceDesc[1]">
                            <xsl:choose>
                                <xsl:when test="t:biblStruct">
                                    <xsl:apply-templates select="t:biblStruct" mode="footnote"/>
                                </xsl:when>
                                <xsl:when test="t:msDesc">
                                    <xsl:value-of select="t:msDesc/t:msIdentifier/t:altIdentifier[@type='preferred']/t:idno/text()"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:apply-templates/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:for-each>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise> 
                <xsl:text> </xsl:text>
                <xsl:value-of select="/t:teiHeader/t:fileDesc/t:editionStmt/t:respStmt/t:name"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     generate an "about this entry" section for the matched titleStmt element
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:titleStmt" mode="about">
        <xsl:if test="../t:publicationStmt/t:date[1]">
            <p>
                <span class="heading-inline">Publication Date: </span>
                <xsl:text> </xsl:text>
                <xsl:for-each select="../t:publicationStmt/t:date[1]">
                    <xsl:choose>
                        <xsl:when test=". castable as xs:date">
                            <xsl:value-of select="format-date(xs:date(.), '[MNn] [D], [Y]')"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="."/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>
            </p>
        </xsl:if>
        <div>
            <h4>Editorial Responsibility:</h4>
            <ul>
                <xsl:for-each select="t:editor">
                    <li>
                        <xsl:sequence select="local:emit-responsible-persons-all(.,'footnote')"/>
                    </li>
                </xsl:for-each>
            </ul>
        </div>
        <!--
        <xsl:if test="t:respStmt">
            <div>
                <h4>Additional Credit:</h4>
                <ul>
                    <xsl:for-each select="t:respStmt">
                        <li>
                            <xsl:value-of select="t:resp"/>
                            <xsl:text> </xsl:text>
                            <xsl:apply-templates select="t:name" mode="footnote"/>
                        </li>
                    </xsl:for-each>
                </ul>
            </div>
        </xsl:if>
        -->
        <xsl:if test="t:funder and not(empty(t:funder/node()))">
            <div>
                <h4>Funder:</h4>
                <ul>
                    <xsl:for-each select="t:funder">
                        <li>
                            <xsl:value-of select="."/>
                        </li>
                    </xsl:for-each>
                </ul>
            </div>
        </xsl:if>
    </xsl:template>
    <xsl:template match="t:titleStmt" mode="about-bibl">
        <xsl:variable name="entry-title" select="t:title[@level='a'][1]"/>
        <p>
            <span class="heading-inline">Date Entry Added: </span>
            <xsl:text> </xsl:text>
            <xsl:for-each select="../t:publicationStmt/t:date[1]">
                <xsl:choose>
                    <xsl:when test=". castable as xs:date">
                        <xsl:value-of select="format-date(xs:date(.), '[MNn] [D], [Y]')"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="."/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </p>
        <div>
            <h4>Editorial Responsibility:</h4>
            <ul>
                <li>
                    <!-- Process editors/authors using local function in helper-functions.xsl local:emit-responsible-persons -->
                    <xsl:sequence select="local:emit-responsible-persons-all(t:principal,'footnote')"/>
                    <xsl:text>, general editor</xsl:text>
                    <xsl:if test="count(t:principal) &gt; 1">s</xsl:if>
                    <xsl:text>, </xsl:text>
                    <xsl:value-of select="t:sponsor[1]"/>
                </li>
                <li>
                    <!-- Process editors/authors using local function in helper-functions.xsl local:emit-responsible-persons -->
                    <xsl:sequence select="local:emit-responsible-persons-all(t:editor[@role='general'],'footnote')"/>
                    <xsl:text>, editor</xsl:text>
                    <xsl:if test="count(t:editor[@role='general'])&gt; 1">s</xsl:if>
                    <xsl:text>, </xsl:text>
                    <em>Syriaca.org Works Cited</em>
                </li>
                <xsl:for-each select="t:editor[@role= ('creator','contributor')]">
                    <li>
                        <xsl:sequence select="local:emit-responsible-persons-all(.,'biblist')"/>
                        <xsl:text>, entry contributor</xsl:text>
                        <xsl:text>, </xsl:text>
                        <xsl:text>“</xsl:text>
                        <xsl:value-of select="//t:titleStmt/t:title[1]"/>
                        <xsl:text>”</xsl:text>
                    </li>
                </xsl:for-each>
            </ul>
        </div>
        <xsl:if test="t:respStmt">
            <div>
                <h4>Additional Credit:</h4>
                <ul>
                    <xsl:for-each select="t:respStmt">
                        <li>
                            <xsl:value-of select="t:resp"/>
                            <xsl:text> </xsl:text>
                            <xsl:apply-templates select="t:name" mode="footnote"/>
                        </li>
                    </xsl:for-each>
                </ul>
            </div>
        </xsl:if>
    </xsl:template>
</xsl:stylesheet>