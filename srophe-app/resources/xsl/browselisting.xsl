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
       
       This XSLT loops through all places/people passed by the browse.xql.
        
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
    <xsl:variable name="collection" select="/t:TEI/@browse-coll"/>
    <xsl:variable name="collection-param" select="concat('&amp;coll=',$collection)"/>
    
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     top-level logic and instructions for creating the browse listing page
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++  -->
    <xsl:template match="/">
        <!-- Selects named template based on parameter passed by xquery into xml results -->
        <xsl:choose>
            <xsl:when test="/t:TEI/@browse-view = 'en'">
                <xsl:call-template name="do-list-en"/>
            </xsl:when>
            <xsl:when test="/t:TEI/@browse-view = 'syr'">
                <xsl:call-template name="do-list-syr"/>
            </xsl:when>
            <xsl:when test="/t:TEI/@browse-view = 'type'">
                <xsl:call-template name="do-list-type"/>
            </xsl:when>
            <xsl:when test="/t:TEI/@browse-view = 'map'">
                <xsl:call-template name="do-map"/>
            </xsl:when>
            <xsl:when test="/t:TEI/@browse-view = 'date'">
                <xsl:call-template name="do-list-date"/>
            </xsl:when>
            <!-- @deprecated             
            <xsl:when test="/t:TEI/@browse-view = 'num'">
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
        <div id="english" dir="ltr" class="col-md-12">
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
                <xsl:call-template name="name-en"/>
            </ul>
        </div>
    </xsl:template>
    
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     named template: do-list-syr
     
     Sorts results using collation.xsl rules. 
     Builds place names with links to place pages.
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template name="do-list-syr">
        <div id="syriac" dir="rtl" class="col-md-12">
                    <!-- Calls ABC menu for browsing. -->
            <div class="browse-alpha-syr tabbable">
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
                <xsl:for-each select="//t:browse">
                    <!-- Sorts on syriac name  -->
                    <xsl:sort collation="{$mixed}" select="child::*[@xml:lang='syr'][@syriaca-tags='#syriaca-headword'][1]"/>
                    <li>
                        <xsl:choose>
                            <xsl:when test="t:persName">
                                <xsl:variable name="persnum" select="substring-after(@xml:id,'person-')"/>
                                <a href="person.html?id={$persnum}">
                                    <!-- Syriac name -->
                                    <bdi dir="rtl" lang="syr" xml:lang="syr">
                                        <xsl:value-of select="string-join(t:persName[@xml:lang='syr'][@syriaca-tags='#syriaca-headword']/child::*/text(),' ')"/>
                                    </bdi> -   
                                    <!-- English name -->
                                    <bdi dir="ltr" lang="en" xml:lang="en">
                                        <xsl:value-of select="string-join(t:persName[starts-with(@xml:lang,'en')][@syriaca-tags='#syriaca-headword']/child::*/text(),' ')"/>
                                        <!-- ana if exists -->
                                        <xsl:if test="@ana != ''">
                                            <bdi dir="ltr" lang="en" xml:lang="en"> (<xsl:value-of select="substring-after(@ana,'#syriaca-')"/>)</bdi>
                                        </xsl:if>
                                    </bdi>
                                </a>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:variable name="placenum" select="substring-after(@xml:id,'place-')"/>
                                <a href="/place/{$placenum}.html">
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
                            </xsl:otherwise>
                        </xsl:choose>
                    </li>
                </xsl:for-each>
            </ul>
        </div>
    </xsl:template>
    
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     named template: name-en
     
     Builds english place names
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template name="name-en">
        <xsl:for-each select="//t:browse">
            <!-- Sort places by mixed collation in collation.xsl -->
            <xsl:sort collation="{$mixed}" select="@sort-title"/>
            <li>
                <xsl:choose>
                    <xsl:when test="t:persName">
                        <xsl:variable name="persnum" select="substring-after(@xml:id,'person-')"/>
                        <!-- Active link for production site
                            <a href="/person/{$persnum}.html">
                        -->
                        <a href="person.html?id={$persnum}">
                            <!-- English name -->
                            <bdi dir="ltr" lang="en" xml:lang="en">
                                <xsl:value-of select="string-join(t:persName[starts-with(@xml:lang,'en')][@syriaca-tags='#syriaca-headword']/descendant-or-self::*/text(),' ')"/>
                            </bdi>
                            <!-- ana if exists -->
                            <xsl:if test="@ana != ''">
                                <bdi dir="ltr" lang="en" xml:lang="en"> (<xsl:value-of select="substring-after(@ana,'#syriaca-')"/>)</bdi>
                            </xsl:if>
                            <!-- Type if exists -->
                            <xsl:if test="@type != ''">
                                <bdi dir="ltr" lang="en" xml:lang="en"> (<xsl:value-of select="@type"/>)</bdi>
                            </xsl:if>
                            <bdi dir="ltr" lang="en" xml:lang="en">
                                <span> -  </span>
                            </bdi>
                            <!-- Syriac name if available -->
                            <xsl:choose>
                                <xsl:when test="t:persName[@xml:lang='syr'][@syriaca-tags='#syriaca-headword']">
                                    <bdi dir="rtl" lang="syr" xml:lang="syr">
                                        <xsl:value-of select="string-join(t:persName[@xml:lang='syr'][@syriaca-tags='#syriaca-headword']/descendant-or-self::*/text(),' ')"/>
                                    </bdi>
                                </xsl:when>
                                <xsl:otherwise>
                                    <bdi dir="ltr">[ Syriac Not Available ]</bdi>
                                </xsl:otherwise>
                            </xsl:choose>
                        </a>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:variable name="placenum" select="substring-after(@xml:id,'place-')"/>
                        <a href="/place/{$placenum}.html">
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
                    </xsl:otherwise>
                </xsl:choose>
            </li>
        </xsl:for-each>
    </xsl:template>
    
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     named template: do-list-en
     
     Sorts results using collation.xsl rules. 
     Builds place names with links to place pages.
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template name="do-list-type">
        <xsl:if test="/t:TEI/@browse-type = ''">
            <div class="col-md-8">
                <div class="section">
                    <h3>Please select a type</h3>
                </div>
            </div>
        </xsl:if>
        <xsl:if test="/t:TEI/@browse-type != ''">
            <div class="col-md-8">
                <div class="section type">
                    <xsl:variable name="type">
                        <xsl:choose>
                            <xsl:when test="contains(/t:TEI/@browse-type,'syriaca-')">
                                <xsl:value-of select="concat(upper-case(substring(substring-after(/t:TEI/@browse-type,'syriaca-'),1,1)),substring(substring-after(/t:TEI/@browse-type,'syriaca-'),2))"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="concat(upper-case(substring(/t:TEI/@browse-type,1,1)),substring(/t:TEI/@browse-type,2))"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <h3>
                        <xsl:value-of select="$type"/>
                    </h3>
                    <xsl:if test="count(descendant::t:geo) &gt; 1">
                        <a href="#" id="show-map-btn">View map</a>
                    </xsl:if>
                    <xsl:if test="count(//t:browse) = 0">
                        <p>No places of this type yet. </p>
                    </xsl:if>
                    <div id="map-div" style="display:none;">
                        <div id="map" class="map" style="height:400px"/>
                        <div id="map-caveat" class="map pull-right caveat" style="margin-top:1em;">
                            <xsl:value-of select="count(//t:browse[descendant::t:geo])"/> of 
                        <xsl:value-of select="count(//t:browse)"/> 
                        places have coordinates and are shown on this map. 
                        
                        <button class="btn btn-link" data-toggle="modal" data-target="#map-selection" id="mapFAQ">Read more...</button>
                        </div>
                        <div>
                            <div class="modal fade" id="map-selection" tabindex="-1" role="dialog" aria-labelledby="map-selectionLabel" aria-hidden="true">
                                <div class="modal-dialog">
                                    <div class="modal-content">
                                        <div class="modal-header">
                                            <button type="button" class="close" data-dismiss="modal">
                                                <span aria-hidden="true"> x </span>
                                                <span class="sr-only">Close</span>
                                            </button>
                                        </div>
                                        <div class="modal-body">
                                            <div id="popup" style="border:none; margin:0;padding:0;margin-top:-2em;"/>
                                        </div>
                                        <div class="modal-footer">
                                            <a class="btn" href="../documentation/faq.html" aria-hidden="true">See all FAQs</a>
                                            <button type="button" class="btn btn-default" data-dismiss="modal">Close</button>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <script type="text/javascript">
                            
                                $('#mapFAQ').click(function(){
                                        $('#popup').load( '../documentation/faq.html #map-selection',function(result){
                                        $('#map-selection').modal({show:true});
                                    });
                                 });   
                             </script>
                        <br style="clear-fix"/>
                    </div>
                    <xsl:variable name="geojson-uri">
                        <xsl:text>/exist/apps/srophe/modules/geojson.xql?type=</xsl:text>
                        <xsl:value-of select="/t:TEI/@browse-type"/>
                    </xsl:variable>
                    <script>
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
                    
                    function initMap(){
                        $.getJSON('<xsl:value-of select="$geojson-uri"/>',function(data){
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
                    };
                    $("#show-map-btn").click(function(e){
                        e.preventDefault();
                        $(this).text($(this).text() == 'View map' ? 'Hide map' : 'View map'); 
                        $("#map-div").toggle(function(){initMap();});
                        
                    });    
                </script>
                    <xsl:choose>
                        <xsl:when test="/t:TEI/@browse-type-map='true'">
                            <xsl:call-template name="map"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <ul style="margin-left:4em; padding-top:1em;">
                            <!-- for each place build title and links -->
                                <xsl:call-template name="name-en"/>
                            </ul>
                        </xsl:otherwise>
                    </xsl:choose>
                </div>
            </div>
        </xsl:if>
    </xsl:template>
    <xsl:template name="do-list-date">
        <div class="col-md-8 well" style="background-color:white; margin:0; padding:.25em 1em;">
            <h3>
                <xsl:choose>
                    <xsl:when test="/t:TEI = 'Date'">Select a Date Range</xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="/t:TEI//*:browse[1]/@date"/>
                    </xsl:otherwise>
                </xsl:choose>
            </h3>
            <ul style="margin-left:4em; padding-top:1em;">
                <!-- for each place build title and links -->
                <xsl:call-template name="name-en"/>
            </ul>
        </div>
    </xsl:template>
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     named template: letter-menu-syr
     
     Builds syriac browse links 
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template name="letter-menu-syr">
        <!-- Uses unique values passed from xquery into tei menu element as string -->
        <ul class="list-inline" style="padding-right: 2em;">
            <!-- Uses tokenize to split string and iterate through each character in the list below to check for matches with $letterBrowse variable -->
            <xsl:for-each select="tokenize('ܐ ܒ ܓ ܕ ܗ ܘ ܙ ܚ ܛ ܝ ܟ ܠ ܡ ܢ ܣ ܥ ܦ ܩ ܪ ܫ ܬ', ' ')">
                <li lang="syr" dir="rtl">
                    <a href="?view=syr&amp;sort={current()}">
                        <xsl:value-of select="current()"/>
                    </a>
                </li>
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
        <ul class="list-inline">
        <!-- For each character in the list below check for matches in $letterBrowse variable -->
            <xsl:for-each select="tokenize('A B C D E F G H I J K L M N O P Q R S T U V W X Y Z', ' ')">
                <li>
                    <a href="?view=en&amp;sort={current()}">
                        <xsl:value-of select="current()"/>
                    </a>
                </li>
            </xsl:for-each>
        </ul>
    </xsl:template>

    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     named template: do-map
     
     Builds english browse links 
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template name="do-map">
        <div id="map" class="col-md-10 col-md-offset-1">
            <div class="section">
                <div class="progress progress-striped active" align="center">
                    <div class="bar" style="width: 40%;"/>
                </div>
                <xsl:call-template name="map"/>
            </div>
        </div>
        <div class="pull-right caveat" style="margin-top:1em;">
            <xsl:copy-of select="//t:count-geo"/>
            <!-- Modal for FAQ -->
            <div style="width: 750px; margin-left: -280px;" id="map-selection" class="modal hide fade" tabindex="-1" role="dialog" aria-labelledby="faq-label" aria-hidden="true">
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
                $('#map-selection').on('shown', function () {
                    $( "#popup" ).load( "../documentation/faq.html #map-selection" );
                })
            </script>
        </div>
    </xsl:template>
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     named template: map
     
     Javascript for leafletjs maps
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template name="map">
        <div id="map" style="height: auto;"/>
        <script type="text/javascript" src="/exist/apps/srophe/resources/js/mapjson.js"/>
    </xsl:template>
</xsl:stylesheet>