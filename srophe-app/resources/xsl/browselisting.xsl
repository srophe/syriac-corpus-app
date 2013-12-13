<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:s="http://syriaca.org" xmlns:saxon="http://saxon.sf.net/" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs t s saxon" version="2.0">
    
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
       browselisting.xsl
       
       This XSLT loops through all places passed by the browse.xql.
        
       code by: 
        + Winona Salesky (wsalesky@gmail.com) 
          for the Institute for the Study of the Ancient World, New York
          University, under contract to Vanderbilt University for the
          NEH-funded Syriac Reference Portal project.
          
       funding provided by:
        + National Endowment for the Humanities (http://www.neh.gov). Any 
          views, findings, conclusions, or recommendations expressed in 
          this code do not necessarily reflect those of the National 
          Endowment for the Humanities.
       
       ================================================================== -->
    <xsl:import href="collations.xsl"/>
    <xsl:import href="langattr.xsl"/>
    <xsl:import href="helper-functions.xsl"/>
    <xsl:output encoding="UTF-8" method="html" indent="yes"/>
    <xsl:param name="normalization">NFKC</xsl:param>
    
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     top-level logic and instructions for creating the browse listing page
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="/">
        <!-- Selects named template based on parameter passed by xquery into xml results -->
        <xsl:choose>
            <xsl:when test="/t:TEI/@browse-type = 'en'">
                <xsl:call-template name="do-list-en"/>
            </xsl:when>
            <xsl:when test="/t:TEI/@browse-type = 'syr'">
                <xsl:call-template name="do-list-syr"/>
            </xsl:when>
            <!-- @deprecated             
            <xsl:when test="/t:TEI/@browse-type = 'num'">
                <xsl:call-template name="do-list-num"/>
            </xsl:when>
            -->
            <xsl:otherwise>
                <xsl:call-template name="do-list-en"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
     
    
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     named template: do-list-en
     
     Sorts results using collation.xsl rules. 
     Builds place names with links to place pages.
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template name="do-list-en">
        <div class="tabbable">
            <!-- Tabs -->
            <ul class="nav nav-tabs" id="nametabs">
                <li class="active">
                    <a href="?lang=en&amp;sort=A" data-toggle="tab">English</a>
                </li>
                <li>
                    <a href="?lang=syr&amp;sort=ܐ" data-toggle="tab" xml:lang="syr" lang="syr" dir="ltr" title="syriac">ܠܫܢܐ ܣܘܪܝܝܐ</a>
                </li>
            </ul>
            <div class="tab-content">
                <div class="tab-pane active" id="english">
                    <!-- Calls ABC menu for browsing. -->
                    <div class="browse-alpha tabbable">
                        <xsl:call-template name="letter-menu-en"/>
                    </div>
                    <!-- Letter heading. Uses parameter passed from xquery, if no letter, default value is A -->
                    <h3 class="label">
                        <xsl:choose>
                            <xsl:when test="/t:TEI/@browse-sort != ''">
                                <xsl:value-of select="/t:TEI/@browse-sort"/>
                            </xsl:when>
                            <xsl:otherwise>A</xsl:otherwise>
                        </xsl:choose>
                    </h3>
                    <!-- List -->
                    <ul style="margin-left:4em; padding-top:1em;">
                        <!-- for each place build title and links -->
                        <xsl:for-each select="//t:place">
                            <!-- Sort places by mixed collation in collation.xsl -->
                            <xsl:sort collation="{$mixed}" select="t:placeName[@xml:lang='en'][1]"/>
                            <xsl:variable name="placenum" select="substring-after(@xml:id,'place-')"/>
                            <li>
                                <a href="place.html?id={$placenum}">
                                    <!-- English name -->
                                    <bdi dir="ltr" lang="en" xml:lang="en">
                                        <xsl:value-of select="t:placeName[@xml:lang='en'][@syriaca-tags='#syriaca-headword']"/>
                                    </bdi>
                                    <!-- Type if exists -->
                                    <xsl:if test="@type">
                                        <bdi dir="ltr" lang="en" xml:lang="en"> (<xsl:value-of select="@type"/>)</bdi>
                                    </xsl:if>
                                    <bdi dir="ltr" lang="en" xml:lang="en">
                                        <span> -  </span>
                                    </bdi>
                                    <!-- Syriac name if available -->
                                    <xsl:choose>
                                        <xsl:when test="t:placeName[@xml:lang='syr'][@syriaca-tags='#syriaca-headword']">
                                            <bdi dir="rtl" lang="syr" xml:lang="syr">
                                                <xsl:value-of select="t:placeName[@xml:lang='syr'][@syriaca-tags='#syriaca-headword']"/>
                                            </bdi>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <bdi dir="ltr">[ Syriac Not Available ]</bdi>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </a>
                            </li>
                        </xsl:for-each>
                    </ul>
                </div>
            </div>
        </div>
    </xsl:template>
    
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     named template: do-list-syr
     
     Sorts results using collation.xsl rules. 
     Builds place names with links to place pages.
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template name="do-list-syr">
        <div class="tabbable">
            <!-- Tabs -->
            <ul class="nav nav-tabs" id="nametabs">
                <li>
                    <a href="?lang=en&amp;sort=A" data-toggle="tab">English</a>
                </li>
                <li class="active">
                    <a href="?lang=syr" data-toggle="tab" xml:lang="syr" lang="syr" dir="ltr" title="syriac">ܠܫܢܐ ܣܘܪܝܝܐ</a>
                </li>
            </ul>
            <div class="tab-content">
                <div class="tab-pane active" id="syriac" dir="rtl">
                    <!-- Calls ABC menu for browsing. -->
                    <div class="browse-alpha-syr tabbable" style="font-size:.75em">
                        <xsl:call-template name="letter-menu-syr"/>
                    </div>
                    <!-- Letter heading. Uses parameter passed from xquery, if no letter, default value is ܐ -->
                    <h3 class="label syr">
                        <xsl:choose>
                            <xsl:when test="/t:TEI/@browse-sort != ''">
                                <xsl:value-of select="/t:TEI/@browse-sort"/>
                            </xsl:when>
                            <xsl:otherwise>ܐ</xsl:otherwise>
                        </xsl:choose>
                    </h3>
                    <ul style="margin-right:5em; margin-top:1em;">
                        <!-- For each place build title and links -->
                        <xsl:for-each select="//t:place">
                            <!-- Sorts on syriac name  -->
                            <xsl:sort collation="{$mixed}" select="t:placeName[@xml:lang='syr'][@syriaca-tags='#syriaca-headword']"/>
                            <xsl:variable name="placenum" select="substring-after(@xml:id,'place-')"/>
                            <li>
                                <a href="place.html?id={$placenum}">
                                    <!-- Syriac name -->
                                    <bdi dir="rtl" lang="syr" xml:lang="syr">
                                        <xsl:value-of select="t:placeName[@xml:lang='syr'][@syriaca-tags='#syriaca-headword']"/>
                                    </bdi> -   
                                    <!-- English name -->
                                    <bdi dir="ltr" lang="en" xml:lang="en">
                                        <xsl:value-of select="t:placeName[@xml:lang='en'][@syriaca-tags='#syriaca-headword']"/>
                                        <xsl:if test="@type"> (<xsl:value-of select="@type"/>)</xsl:if>
                                    </bdi>
                                </a>
                            </li>
                        </xsl:for-each>
                    </ul>
                </div>
            </div>
        </div>
    </xsl:template>
    
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     named template: do-list-num
     Sorted by place number 
      @deprecated 
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template name="do-list-num">
        <div class="tabbable">
            <ul class="nav nav-tabs" id="nametabs">
                <li>
                    <a href="?lang=en&amp;sort=A" data-toggle="tab">English</a>
                </li>
                <li>
                    <a href="?lang=syr" data-toggle="tab" xml:lang="syr" lang="syr" dir="ltr" title="syriac">ܠܫܢܐ ܣܘܪܝܝܐ</a>
                </li>
                <li class="active">
                    <a href="?lang=num" data-toggle="tab">Syriac gazetteer number</a>
                </li>
            </ul>
            <div class="tab-content">
                <div class="tab-pane active" id="num">
                    <ul>
                        <xsl:for-each select="//t:place">
                            <xsl:sort select="xs:integer(substring-after(@xml:id,'place-'))"/>
                            <xsl:variable name="placenum" select="substring-after(@xml:id,'place-')"/>
                            <li>
                                <a href="place.html?id={$placenum}">
                                    <xsl:value-of select="$placenum"/>:
                                    <bdi dir="ltr" lang="en" xml:lang="en">
                                        <xsl:value-of select="t:placeName[@xml:lang='en'][@syriaca-tags='#syriaca-headword']"/>
                                    </bdi>
                                    <xsl:if test="@type">
                                        <bdi dir="ltr" lang="en" xml:lang="en"> (<xsl:value-of select="@type"/>)</bdi>
                                    </xsl:if>
                                    <bdi dir="ltr" lang="en" xml:lang="en">
                                        <span> -  </span>
                                    </bdi>
                                    <xsl:choose>
                                        <xsl:when test="t:placeName[@xml:lang='syr'][@syriaca-tags='#syriaca-headword']">
                                            <bdi dir="rtl" lang="syr" xml:lang="syr">
                                                <xsl:value-of select="t:placeName[@xml:lang='syr'][@syriaca-tags='#syriaca-headword']"/>
                                            </bdi>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <bdi dir="ltr">[ Syriac Not Available ]</bdi>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </a>
                            </li>
                        </xsl:for-each>
                    </ul>
                </div>
            </div>
        </div>
    </xsl:template>
    
    
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     named template: letter-menu-syr
     
     Builds syriac browse links 
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template name="letter-menu-syr">
        <!-- Uses unique values passed from xquery into tei menu element as string -->
        <xsl:variable name="letterBrowse" select="/t:TEI/t:menu"/>
        <ul class="inline" style="padding-right: 2em;">
            <!-- Uses tokenize to split string and iterate through each character in the list below to check for matches with $letterBrowse variable -->
            <xsl:for-each select="tokenize('ܐ ܒ ܓ ܕ ܗ ܘ ܙ ܚ ܛ ܝ ܟ ܠ ܡ ܢ ܣ ܥ ܦ ܩ ܪ ܫ ܬ', ' ')">
                <xsl:choose>
                    <!-- If there is a match, create link to character results -->
                    <xsl:when test="contains($letterBrowse,current())">
                        <li lang="syr" dir="rtl">
                            <a href="?lang=syr&amp;sort={current()}">
                                <xsl:value-of select="current()"/>
                            </a>
                        </li>
                    </xsl:when>
                    <!-- Otherwise, no links -->
                    <xsl:otherwise>
                        <li lang="syr" dir="rtl">
                            <xsl:value-of select="current()"/>
                        </li>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </ul>
    </xsl:template>
    
    
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     named template: letter-menu-en
     
     Builds english browse links 
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template name="letter-menu-en">
        <!-- Uses tokenize to split string and iterate through each character in the list below to check for matches with $letterBrowse variable -->
        <xsl:variable name="letterBrowse" select="/t:TEI/t:menu"/>
        <ul class="inline">
        <!-- For each character in the list below check for matches in $letterBrowse variable -->
            <xsl:for-each select="tokenize('A B C D E F G H I J K L M N O P Q R S T U V W X Y Z', ' ')">
                <xsl:choose>
                <!-- If there is a match, create link to character results -->
                    <xsl:when test="contains($letterBrowse,current())">
                        <li>
                            <a href="?lang=en&amp;sort={current()}">
                                <xsl:value-of select="current()"/>
                            </a>
                        </li>
                    </xsl:when>
                <!-- Otherwise, no links -->
                    <xsl:otherwise>
                        <li>
                            <xsl:value-of select="current()"/>
                        </li>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </ul>
    </xsl:template>
</xsl:stylesheet>