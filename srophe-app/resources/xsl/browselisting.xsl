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
            <xsl:when test="/t:TEI/@browse-lang = 'en'">
                <xsl:call-template name="do-list-en"/>
            </xsl:when>
            <xsl:when test="/t:TEI/@browse-lang = 'syr'">
                <xsl:call-template name="do-list-syr"/>
            </xsl:when>
            <xsl:when test="/t:TEI/@browse-lang = 'type'">
                <xsl:call-template name="do-list-type"/>
            </xsl:when>
            <xsl:when test="/t:TEI/@browse-lang = 'map'">
                <xsl:call-template name="do-map"/>
            </xsl:when>
            <!-- @deprecated             
            <xsl:when test="/t:TEI/@browse-lang = 'num'">
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
                    <a href="browse.html?lang=en&amp;sort=A">English</a>
                </li>
                <li>
                    <a href="browse.html?lang=syr&amp;sort=ܐ" xml:lang="syr" lang="syr" dir="ltr" title="syriac">ܠܫܢܐ ܣܘܪܝܝܐ</a>
                </li>
                <li>
                    <a href="browse.html?lang=type">Type</a>
                </li>
                <li>
                    <a href="browse.html?lang=map">Map</a>
                </li>
            </ul>
            <div class="tab-content">
                <div class="tab-pane active" id="english" dir="ltr">
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
                    <a href="browse.html?lang=en&amp;sort=A">English</a>
                </li>
                <li class="active">
                    <a href="browse.html?lang=syr" xml:lang="syr" lang="syr" dir="ltr" title="syriac">ܠܫܢܐ ܣܘܪܝܝܐ</a>
                </li>
                <li>
                    <a href="browse.html?lang=type">Type</a>
                </li>
                <li>
                    <a href="browse.html?lang=map">Map</a>
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
                        <span lang="syr" dir="rtl">
                            <xsl:choose>
                                <xsl:when test="/t:TEI/@browse-sort != ''">
                                    <xsl:value-of select="/t:TEI/@browse-sort"/>
                                </xsl:when>
                                <xsl:otherwise>ܐ</xsl:otherwise>
                            </xsl:choose>
                        </span>
                    </h3>
                    <ul style="margin-right:7em; margin-top:1em;">
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
     named template: do-list-en
     
     Sorts results using collation.xsl rules. 
     Builds place names with links to place pages.
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template name="do-list-type">
        <div class="tabbable">
            <!-- Tabs -->
            <ul class="nav nav-tabs" id="nametabs">
                <li>
                    <a href="browse.html?lang=en&amp;sort=A">English</a>
                </li>
                <li>
                    <a href="browse.html?lang=syr&amp;sort=ܐ" xml:lang="syr" lang="syr" dir="ltr" title="syriac">ܠܫܢܐ ܣܘܪܝܝܐ</a>
                </li>
                <li class="active">
                    <a href="browse.html?lang=type">Type</a>
                </li>
                <li>
                    <a href="browse.html?lang=map">Map</a>
                </li>
            </ul>
            <div class="tab-content">
                <div class="tab-pane active" id="english" dir="ltr">
                    <!-- Letter heading. Uses parameter passed from xquery, if no letter, default value is A -->
                    <div class="row-fluid">
                        <div class="span4">
                            <ul style="margin-left:0; width: 15em;" class="nav nav-tabs nav-stacked">
                                <li>
                                    <xsl:if test="/t:TEI/@browse-type = 'building'">
                                        <xsl:attribute name="class">active</xsl:attribute>
                                    </xsl:if>
                                    <a href="?lang=type&amp;type=building">building</a>
                                </li>
                                <li>
                                    <xsl:if test="/t:TEI/@browse-type = 'church'">
                                        <xsl:attribute name="class">active</xsl:attribute>
                                    </xsl:if>
                                    <a href="?lang=type&amp;type=church">church</a>
                                </li>
                                <li>
                                    <xsl:if test="/t:TEI/@browse-type = 'diocese'">
                                        <xsl:attribute name="class">active</xsl:attribute>
                                    </xsl:if>
                                    <a href="?lang=type&amp;type=diocese">diocese</a>
                                </li>
                                <li>
                                    <xsl:if test="/t:TEI/@browse-type = 'fortification'">
                                        <xsl:attribute name="class">active</xsl:attribute>
                                    </xsl:if>
                                    <a href="?lang=type&amp;type=fortification">fortification</a>
                                </li>
                                <li>
                                    <xsl:if test="/t:TEI/@browse-type = 'island'">
                                        <xsl:attribute name="class">active</xsl:attribute>
                                    </xsl:if>
                                    <a href="?lang=type&amp;type=island">island</a>
                                </li>
                                <li>
                                    <xsl:if test="/t:TEI/@browse-type = 'madrasa'">
                                        <xsl:attribute name="class">active</xsl:attribute>
                                    </xsl:if>
                                    <a href="?lang=type&amp;type=madrasa">madrasa</a>
                                </li>
                                <li>
                                    <xsl:if test="/t:TEI/@browse-type = 'monastery'">
                                        <xsl:attribute name="class">active</xsl:attribute>
                                    </xsl:if>
                                    <a href="?lang=type&amp;type=monastery">monastery</a>
                                </li>
                                <li>
                                    <xsl:if test="/t:TEI/@browse-type = 'mosque'">
                                        <xsl:attribute name="class">active</xsl:attribute>
                                    </xsl:if>
                                    <a href="?lang=type&amp;type=mosque">mosque</a>
                                </li>
                                <li>
                                    <xsl:if test="/t:TEI/@browse-type = 'mountain'">
                                        <xsl:attribute name="class">active</xsl:attribute>
                                    </xsl:if>
                                    <a href="?lang=type&amp;type=mountain">mountain</a>
                                </li>
                                <li>
                                    <xsl:if test="/t:TEI/@browse-type = 'open-water'">
                                        <xsl:attribute name="class">active</xsl:attribute>
                                    </xsl:if>
                                    <a href="?lang=type&amp;type=open-water">open-water</a>
                                </li>
                                <li>
                                    <xsl:if test="/t:TEI/@browse-type = 'parish'">
                                        <xsl:attribute name="class">active</xsl:attribute>
                                    </xsl:if>
                                    <a href="?lang=type&amp;type=parish">parish</a>
                                </li>
                                <li>
                                    <xsl:if test="/t:TEI/@browse-type = 'province'">
                                        <xsl:attribute name="class">active</xsl:attribute>
                                    </xsl:if>
                                    <a href="?lang=type&amp;type=province">province</a>
                                </li>
                                <li>
                                    <xsl:if test="/t:TEI/@browse-type = 'quarter'">
                                        <xsl:attribute name="class">active</xsl:attribute>
                                    </xsl:if>
                                    <a href="?lang=type&amp;type=quarter">quarter</a>
                                </li>
                                <li>
                                    <xsl:if test="/t:TEI/@browse-type = 'region'">
                                        <xsl:attribute name="class">active</xsl:attribute>
                                    </xsl:if>
                                    <a href="?lang=type&amp;type=region">region</a>
                                </li>
                                <li>
                                    <xsl:if test="/t:TEI/@browse-type = 'river'">
                                        <xsl:attribute name="class">active</xsl:attribute>
                                    </xsl:if>
                                    <a href="?lang=type&amp;type=river">river</a>
                                </li>
                                <li>
                                    <xsl:if test="/t:TEI/@browse-type = 'settlement'">
                                        <xsl:attribute name="class">active</xsl:attribute>
                                    </xsl:if>
                                    <a href="?lang=type&amp;type=settlement">settlement</a>
                                </li>
                                <li>
                                    <xsl:if test="/t:TEI/@browse-type = 'state'">
                                        <xsl:attribute name="class">active</xsl:attribute>
                                    </xsl:if>
                                    <a href="?lang=type&amp;type=state">state</a>
                                </li>
                                <li>
                                    <xsl:if test="/t:TEI/@browse-type = 'synagogue'">
                                        <xsl:attribute name="class">active</xsl:attribute>
                                    </xsl:if>
                                    <a href="?lang=type&amp;type=synagogue">synagogue</a>
                                </li>
                                <li>
                                    <xsl:if test="/t:TEI/@browse-type = 'temple'">
                                        <xsl:attribute name="class">active</xsl:attribute>
                                    </xsl:if>
                                    <a href="?lang=type&amp;type=temple">temple</a>
                                </li>
                                <li>
                                    <xsl:if test="/t:TEI/@browse-type = 'unknown'">
                                        <xsl:attribute name="class">active</xsl:attribute>
                                    </xsl:if>
                                    <a href="?lang=type&amp;type=unknown">unknown</a>
                                </li>
                            </ul>
                        </div>
                        <xsl:if test="/t:TEI/@browse-type != ''">
                            <div class="span8 well" style="background-color:white; margin:0; padding:.25em .5em;">
                                <h3>
                                    <xsl:value-of select="concat(upper-case(substring(/t:TEI/@browse-type,1,1)),substring(/t:TEI/@browse-type,2))"/>
                                </h3>
                                <xsl:if test="count(//t:place) = 0">
                                    <p>No places of this type yet. </p>
                                </xsl:if>
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
                        </xsl:if>
                    </div>
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
    
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     named template: do-map
     
     Builds english browse links 
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template name="do-map">
        <div class="tabbable">
            <!-- Tabs -->
            <ul class="nav nav-tabs" id="nametabs">
                <li>
                    <a href="browse.html?lang=en&amp;sort=A">English</a>
                </li>
                <li>
                    <a href="browse.html?lang=syr" xml:lang="syr" lang="syr" dir="ltr" title="syriac">ܠܫܢܐ ܣܘܪܝܝܐ</a>
                </li>
                <li>
                    <a href="browse.html?lang=type">Type</a>
                </li>
                <li class="active">
                    <a href="browse.html?lang=map">Map</a>
                </li>
            </ul>
            <div class="tab-content" id="map">
                <div class="tab-pane active">
                    <div class="progress progress-striped active" align="center">
                        <div class="bar" style="width: 40%;"/>
                    </div>
                    <div id="map" style="height: auto;"/>
                    <script type="text/javascript">
                        var terrain = L.tileLayer(
                        'http://api.tiles.mapbox.com/v3/sgillies.map-ac5eaoks/{z}/{x}/{y}.png', 
                        {attribution: "ISAW, 2012"});
                        
                        /* Not added by default, only through user control action */
                        var streets = L.tileLayer(
                        'http://api.tiles.mapbox.com/v3/sgillies.map-pmfv2yqx/{z}/{x}/{y}.png', 
                        {attribution: "ISAW, 2012"});
                        
                        var imperium = L.tileLayer(
                        'http://pelagios.dme.ait.ac.at/tilesets/imperium//{z}/{x}/{y}.png', {
                        attribution: 'Tiles: &lt;a href="http://pelagios-project.blogspot.com/2012/09/a-digital-map-of-roman-empire.html"&gt;Pelagios&lt;/a&gt;, 2012; Data: NASA, OSM, Pleiades, DARMC',
                        maxZoom: 11 });
                        
                        
                        $.getJSON('/exist/apps/srophe/modules/geojson.xql',function(data){
                        var geojson = L.geoJson(data, {
                        onEachFeature: function (feature, layer){
                        var popupContent = "&lt;a href='" + feature.properties.uri + "'&gt;" +
                        feature.properties.name + " - " + feature.properties.type + "&lt;/a&gt;";
                        
                        layer.bindPopup(popupContent);
                        }
                        }) 
                        
                        var map = L.map('map').fitBounds(geojson.getBounds());
                        
                        terrain.addTo(map);
                        
                        L.control.layers({
                        "Terrain (default)": terrain,
                        "Streets": streets,
                        "Imperium": imperium }).addTo(map);
                        
                        geojson.addTo(map);
                        });     
                        
                        //resize
                        $('#map').height(function(){
                        return $(window).height() * 0.6;
                        });
                    </script>
                </div>
            </div>
            <div class="pull-right caveat" style="margin-top:1em;">
                <xsl:copy-of select="//t:count-geo"/>
            </div>
        </div>
    </xsl:template>
</xsl:stylesheet>