<xsl:stylesheet  
    xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:t="http://www.tei-c.org/ns/1.0" 
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:x="http://www.w3.org/1999/xhtml"  
    xmlns:saxon="http://saxon.sf.net/" 
    xmlns:xs="http://www.w3.org/2001/XMLSchema" 
    xmlns:local="http://syriaca.org/ns" 
    exclude-result-prefixes="xs t x saxon local" version="3.0">

 <!-- ================================================================== 
      Adapted for eGedsh - generateBrowseL.xsl
       
       Generate Static Browse HTML pages 
       
       code by: 
        + Winona Salesky (wsalesky@gmail.com)
          
       
       ================================================================== -->

    <xsl:output name="html" encoding="UTF-8" method="xhtml" indent="no" omit-xml-declaration="yes"/>    
 
    <!-- =================================================================== -->
    <!-- Parameters for tei2HTML -->
    <!-- =================================================================== -->
    
    <!--
    Examples for converting the syriaca application to Gaddel    
    <xsl:param name="applicationPath" select="'/Users/wsalesky/syriaca/syriaca/syriaca'"/>
    <xsl:param name="staticSitePath" select="'/Users/wsalesky/syriaca/syriaca/syriacaStatic'"/>
    <xsl:param name="dataPath" select="'/Users/wsalesky/syriaca/syriaca/syriaca-data-test/data/'"/>
    <xsl:param name="applicationPath" select="'../../'"/>
    <xsl:param name="staticSitePath" select="'../../'"/>
    <xsl:param name="convert" select="'true'"/>
    -->
    
    <xsl:param name="applicationPath" select="'/Users/wsalesky/syriaca/gedsh/e-gedsh-app/'"/>
    <xsl:param name="staticSitePath" select="'/Users/wsalesky/syriaca/gedsh/e-gedsh-app-temp/'"/>
    <xsl:param name="dataPath" select="'/Users/wsalesky/syriaca/gedsh/e-gedsh/data/tei/articles/tei'"/>
    <!-- Find repo-config to find collection style values and page stubs -->
    <xsl:variable name="configPath">
        <xsl:choose>
            <xsl:when test="$applicationPath != ''">
                <xsl:value-of select="concat($staticSitePath, '/siteGenerator/components/repo-config.xml')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="'../components/repo-config.xml'"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    
    <!-- Get configuration file.  -->
    <xsl:variable name="config">
        <xsl:if test="doc-available(xs:anyURI($configPath))">
            <xsl:sequence select="document(xs:anyURI($configPath))"/>
        </xsl:if>
    </xsl:variable>
   
    <xsl:variable name="collectionValues" select="$config/descendant::*:collection[1]"/>        
    <xsl:variable name="collectionTemplate">
        <xsl:message>Find generic page.html template</xsl:message>
        <xsl:variable name="templatePath" select="replace(concat($staticSitePath,'/siteGenerator/components/page.html'),'//','/')"/>
        <xsl:if test="doc-available(xs:anyURI($templatePath))">
            <xsl:sequence select="document(xs:anyURI($templatePath))"/>
        </xsl:if>
    </xsl:variable>
    <xsl:variable name="collection" select="$collectionValues/@name"/>
    
    <xsl:variable name="template">
        <xsl:choose>
            <xsl:when test="$collectionTemplate/child::*">
                <xsl:sequence select="$collectionTemplate"/> 
            </xsl:when>
            <xsl:otherwise>
                <xsl:message>Error Can not find matching template for HTML page </xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <xsl:template match="/">
        <xsl:result-document href="{concat($staticSitePath,'/browse.html')}">
            <html xmlns="http://www.w3.org/1999/xhtml">
                <!-- Header -->
                <xsl:choose>
                    <xsl:when test="$template/descendant::*:head">
                        <xsl:copy-of select="$template/descendant::*:head"/>
                    </xsl:when>
                    <xsl:otherwise><xsl:message>No template found for html:head element</xsl:message></xsl:otherwise>
                </xsl:choose>
                <body id="body">
                    <xsl:choose>
                        <xsl:when test="not(empty($template))">
                            <xsl:choose>
                                <xsl:when test="$template/descendant::html:nav">
                                    <xsl:copy-of select="$template/descendant::html:nav"/>
                                </xsl:when>
                                <xsl:when test="$template/descendant::html:div[@role='navigation']">
                                    <xsl:copy-of select="$template/descendant::div[@role='navigation']"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:message>No template found for html:nav element</xsl:message>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:message>No template found for html:head element</xsl:message>
                        </xsl:otherwise>
                    </xsl:choose>
                    
                    <div class="interior-content section">
                        <h1>Browse Entries</h1>
                        <!-- Browse Content -->
                                <div class="container">
                                        <div class="float-container">
                                            <div class="browse-alpha">
                                                <ul class="nav nav-tabs">
                                                    <li><a data-toggle="tab" href="#tabFront">Front Matter</a></li>
                                                    <li><a data-toggle="tab" href="#tabA">A</a></li>
                                                    <li><a data-toggle="tab" href="#tabB">B</a></li>
                                                    <li><a data-toggle="tab" href="#tabC">C</a></li>
                                                    <li><a data-toggle="tab" href="#tabD">D</a></li>
                                                    <li><a data-toggle="tab" href="#tabE">E</a></li>
                                                    <li><a data-toggle="tab" href="#tabF">F</a></li>
                                                    <li><a data-toggle="tab" href="#tabG">G</a></li>
                                                    <li><a data-toggle="tab" href="#tabH">H</a></li>
                                                    <li><a data-toggle="tab" href="#tabI">I</a></li>
                                                    <li><a data-toggle="tab" href="#tabJ">J</a></li>
                                                    <li><a data-toggle="tab" href="#tabK">K</a></li>
                                                    <li><a data-toggle="tab" href="#tabL">L</a></li>
                                                    <li><a data-toggle="tab" href="#tabM">M</a></li>
                                                    <li><a data-toggle="tab" href="#tabN">N</a></li>
                                                    <li><a data-toggle="tab" href="#tabO">O</a></li>
                                                    <li><a data-toggle="tab" href="#tabP">P</a></li>
                                                    <li><a data-toggle="tab" href="#tabQ">Q</a></li>
                                                    <li><a data-toggle="tab" href="#tabR">R</a></li>
                                                    <li><a data-toggle="tab" href="#tabS">S</a></li>
                                                    <li><a data-toggle="tab" href="#tabT">T</a></li>
                                                    <li><a data-toggle="tab" href="#tabU">U</a></li>
                                                    <li><a data-toggle="tab" href="#tabV">V</a></li>
                                                    <li><a data-toggle="tab" href="#tabW">W</a></li>
                                                    <li><a data-toggle="tab" href="#tabX">X</a></li>
                                                    <li><a data-toggle="tab" href="#tabY">Y</a></li>
                                                    <li><a data-toggle="tab" href="#tabZ">Z</a></li>
                                                    <li><a data-toggle="tab" href="#tabBack">Back Matter</a></li>
                                                </ul>
                                            </div>
                                        </div>
                                    <div class="tab-content" xmlns="http://www.w3.org/1999/xhtml">
                                            <xsl:variable name="browseList">
                                                <xsl:for-each select="collection(concat($dataPath,'/.?select=*.xml'))//t:TEI">
                                                    <xsl:variable name="sort">
                                                        <xsl:choose>
                                                            <xsl:when test="descendant::t:idno[@type='front']">frontMatter</xsl:when>
                                                            <xsl:when test="descendant::t:idno[@type='back']">backMatter</xsl:when>
                                                            <xsl:otherwise>
                                                                <xsl:value-of select="replace(translate(translate(translate(translate(replace(normalize-space(descendant::t:div[@type='entry']/t:head[1]),'ʿ',''),'Ṭ','T'),'Ṣ','S'),'Ç ','C'),'Ḥ','H'),' ','')"/>
                                                            </xsl:otherwise>
                                                        </xsl:choose>
                                                    </xsl:variable>
                                                    <xsl:variable name="sortGroup">
                                                        <xsl:choose>
                                                            <xsl:when test="$sort = 'frontMatter'">Front</xsl:when>
                                                            <xsl:when test="$sort = 'front'">Front</xsl:when>
                                                            <xsl:when test="$sort = 'backMatter'">Back</xsl:when>
                                                            <xsl:when test="$sort = 'back'">Back</xsl:when>
                                                            <xsl:otherwise>
                                                                <xsl:value-of select="upper-case(substring($sort,1,1))"/>
                                                            </xsl:otherwise>
                                                        </xsl:choose>
                                                    </xsl:variable>
                                                    <xsl:choose>
                                                        <xsl:when test="$sortGroup = 'Front'">
                                                            <xsl:for-each select="descendant-or-self::t:div[@type='section']">
                                                                <xsl:variable name="title" select="t:head[1]"/>
                                                                <xsl:variable name="uri" select="tokenize(t:ab/t:idno[@type='URI'],'/')[last()]"/>
                                                                <div xmlns="http://www.w3.org/1999/xhtml" sort="{$sortGroup}" sortTitle="{$sort}" class="results-list {if(descendant::t:div[@type = ('subsection','subSubsection')]) then 'indent' else ()}">
                                                                    <span class="sort-title">  
                                                                        <a href="/entry/{normalize-space($uri)}.html"><xsl:value-of select="$title"/></a>
                                                                        <span class="type">&#160;<xsl:value-of select="descendant::t:ab[@type='infobox']"/></span>
                                                                    </span>
                                                                    <xsl:if test="descendant::t:byline">
                                                                        <span class="results-list-desc sort-title">
                                                                            <span>Contributor: </span>
                                                                            <i><xsl:value-of select="descendant::t:byline/t:persName"/></i>
                                                                        </span>
                                                                    </xsl:if>
                                                                    <span class="results-list-desc uri">
                                                                        <span class="srp-label">URI: </span>
                                                                        <a href="/entry/{normalize-space($uri)}.html"><xsl:value-of select="descendant::t:ab/t:idno[@type='URI']"/></a>
                                                                    </span>
                                                                </div>
                                                            </xsl:for-each>
                                                        </xsl:when>
                                                        <xsl:when test="$sortGroup = 'Back'">
                                                            <xsl:for-each select="descendant-or-self::t:div[@type='section']">
                                                                <xsl:variable name="title" select="t:head[1]"/>
                                                                <xsl:variable name="uri" select="tokenize(t:ab/t:idno[@type='URI'],'/')[last()]"/>
                                                                <div xmlns="http://www.w3.org/1999/xhtml" sort="{$sortGroup}" sortTitle="{$sort}" class="results-list {if(descendant::t:div[@type = ('subsection','subSubsection')]) then 'indent' else ()}">
                                                                    <span class="sort-title">  
                                                                        <a href="/entry/{normalize-space($uri)}.html"><xsl:value-of select="$title"/></a>
                                                                        <span class="type">&#160;<xsl:value-of select="t:ab[@type='infobox']"/></span>
                                                                    </span>
                                                                    <xsl:if test="t:byline">
                                                                        <span class="results-list-desc sort-title">
                                                                            <span>Contributor: </span>
                                                                            <i><xsl:value-of select="t:byline/t:persName"/></i>
                                                                        </span>
                                                                    </xsl:if>
                                                                    <span class="results-list-desc uri">
                                                                        <span class="srp-label">URI: </span>
                                                                        <a href="/entry/{normalize-space($uri)}.html"><xsl:value-of select="t:ab/t:idno[@type='URI']"/></a>
                                                                    </span>
                                                                    <xsl:for-each select="t:div[@type='subsection']">
                                                                        <xsl:variable name="title" select="t:head[1]"/>
                                                                        <xsl:variable name="uri">
                                                                            <xsl:choose>
                                                                                <xsl:when test="contains(t:ab/t:idno[@type='URI'],'/map')">
                                                                                    <xsl:value-of select="concat('map/',tokenize(t:ab/t:idno[@type='URI'],'/')[last()])"/>
                                                                                </xsl:when>
                                                                                <xsl:otherwise>
                                                                                    <xsl:value-of select="tokenize(t:ab/t:idno[@type='URI'],'/')[last()]"/>
                                                                                </xsl:otherwise>
                                                                            </xsl:choose>
                                                                        </xsl:variable>
                                                                        
                                                                        <xsl:if test="$title != ''">
                                                                            <div xmlns="http://www.w3.org/1999/xhtml" sort="{$sortGroup}" sortTitle="{$sort}" class="results-list {if(@type = ('subsection','subSubsection')) then 'indent' else ()}">
                                                                                <span class="sort-title">  
                                                                                    <a href="/entry/{normalize-space($uri)}.html"><xsl:value-of select="$title"/></a>
                                                                                    <span class="type">&#160;<xsl:value-of select="t:ab[@type='infobox']"/></span>
                                                                                </span>
                                                                                <xsl:if test="t:byline">
                                                                                    <span class="results-list-desc sort-title">
                                                                                        <span>Contributor: </span>
                                                                                        <i><xsl:value-of select="t:byline/t:persName"/></i>
                                                                                    </span>
                                                                                </xsl:if>
                                                                                <span class="results-list-desc uri">
                                                                                    <span class="srp-label">URI: </span>
                                                                                    <a href="/entry/{normalize-space($uri)}.html"><xsl:value-of select="t:ab/t:idno[@type='URI']"/></a>
                                                                                </span>
                                                                            </div> 
                                                                        </xsl:if>
                                                                    </xsl:for-each>
                                                                </div>
                                                            </xsl:for-each>
                                                        </xsl:when>
                                                        <xsl:otherwise>
                                                            <xsl:variable name="title" select="descendant::t:div[@type='entry']/t:head[1]"/>
                                                            <xsl:variable name="uri" select="tokenize(descendant::t:ab/t:idno[@type='URI'],'/')[last()]"/>
                                                            <div xmlns="http://www.w3.org/1999/xhtml" sort="{$sortGroup}" sortTitle="{$sort}" class="results-list {if(descendant::t:div[@type = ('subsection','subSubsection')]) then 'indent' else ()}">
                                                                <span class="sort-title">  
                                                                    <a href="/entry/{normalize-space($uri)}.html"><xsl:value-of select="$title"/></a>
                                                                    <span class="type">&#160;<xsl:value-of select="descendant::t:ab[@type='infobox']"/></span>
                                                                </span>
                                                                <xsl:if test="descendant::t:byline">
                                                                    <span class="results-list-desc sort-title">
                                                                        <span>Contributor: </span>
                                                                        <i><xsl:value-of select="descendant::t:byline/t:persName"/></i>
                                                                    </span>
                                                                </xsl:if>
                                                                <span class="results-list-desc uri">
                                                                    <span class="srp-label">URI: </span>
                                                                    <a href="/entry/{normalize-space($uri)}.html"><xsl:value-of select="descendant::t:ab/t:idno[@type='URI']"/></a>
                                                                </span>
                                                            </div>
                                                        </xsl:otherwise>
                                                    </xsl:choose>
                                                </xsl:for-each>
                                            </xsl:variable>
                                            <xsl:for-each-group select="$browseList/child::*" group-by="@sort">
                                                <xsl:sort select="current-grouping-key()"/>
                                                <div xmlns="http://www.w3.org/1999/xhtml" id="tab{current-grouping-key()}" class="tab-pane {if(current-grouping-key() = 'A') then 'in active' else ()} fade">
                                                    <h3 class="label" xmlns="http://www.w3.org/1999/xhtml"><xsl:value-of select="current-grouping-key()"/></h3>
                                                    <xsl:for-each select="current-group()">
                                                        <xsl:sort select="@sortTitle"/>
                                                        <xsl:sequence select="."/>
                                                    </xsl:for-each>
                                                </div>
                                            </xsl:for-each-group>
                                        </div>
                                </div>
                    </div>
                    <xsl:if test="doc-available(xs:anyURI(concat($staticSitePath,'/siteGenerator/components/footer.html')))">
                        <xsl:copy-of select="document(xs:anyURI(concat($staticSitePath,'/siteGenerator/components/footer.html')))"/>
                    </xsl:if>
                </body>
            </html>
        </xsl:result-document>
    </xsl:template>
    
    <xsl:template name="recSummary">
        <xsl:param name="nodes"/>
        
    </xsl:template>
</xsl:stylesheet>
