<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:s="http://syriaca.org" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:x="http://www.w3.org/1999/xhtml" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:saxon="http://saxon.sf.net/" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:local="http://syriaca.org/ns" exclude-result-prefixes="xs t s saxon" version="2.0">

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
       spear.xsl
       
       This XSLT transforms tei.xml to html for SPEAR content.
       
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
 <!-- TEMPLATES -->
 <!-- =================================================================== -->

    <!-- Manuscript templates -->
    <!-- used by spear pages not real tei element -->
    <xsl:template match="t:factoid">
        <xsl:if test="not(empty(.))">
            <!-- Output elements without links -->
            <div class="panel panel-default">
                <div class="panel-heading clearfix">
                    <h4 class="panel-title pull-left" style="padding-top: 7.5px;">Factoid(s)</h4>
                </div>
                <div class="panel-body">    
                    <xsl:apply-templates/>
                </div>
            </div>
        </xsl:if>
    </xsl:template>
    <xsl:template match="t:person[ancestor::t:factoid]">
        <xsl:apply-templates/>
    </xsl:template>
    <!-- Not real tei element -->
    <xsl:template match="t:pers-group">
        <h4>Person</h4>
        <xsl:apply-templates select="*[not(t:listPerson/t:person/t:persName)]"/>
    </xsl:template>
    <xsl:template match="t:spear-citation">
        <xsl:if test="t:bibl">
            <div class="well">
                <!-- Sources -->
                <div id="sources">
                    <h3>Sources</h3>
                    <p>
                        <small>Any information without attribution has been created following the Syriaca.org <a href="http://syriaca.org/documentation/">editorial guidelines</a>.</small>
                    </p>
                    <ul>
                        <xsl:apply-templates select="t:bibl" mode="footnote"/>
                    </ul>
                </div>
            </div>            
        </xsl:if>
    </xsl:template>
</xsl:stylesheet>