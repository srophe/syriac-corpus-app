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
      Adapted for Hugoye - generateBrowseL.xsl
       
       Generate Static Browse HTML pages 
       Generated pages: 
            /current-issue.html
            /volumes.html
            /authors.html
       
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
    
    <xsl:param name="applicationPath" select="'../hugoye-app/'"/>
    <xsl:param name="staticSitePath" select="'../hugoye-app/'"/>
    <xsl:param name="dataPath" select="'../hugoye-data/data/tei'"/>
    <!-- Find repo-config to find collection style values and page stubs -->
    <xsl:variable name="configPath">
        <xsl:choose>
            <xsl:when test="$applicationPath != ''">
                <xsl:value-of select="concat($applicationPath, '/siteGenerator/components/repo-config.xml')"/>
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
        <xsl:variable name="templatePath" select="replace(concat($applicationPath,'/siteGenerator/components/page.html'),'//','/')"/>
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
    <xsl:function name="local:persNames">
        <xsl:param name="nodes"/>
        <xsl:choose>
            <xsl:when test="$nodes/@role='anonymous'"/>
            <xsl:when test="$nodes/t:name">
                <xsl:value-of select="string-join($nodes/t:name,' ')"/>
            </xsl:when>
            <xsl:otherwise><xsl:value-of select="string-join($nodes/text(),' ')"/></xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:template match="/">
        <xsl:call-template name="volumeBrowse"/>
        <!-- Author Browse may make sense to do dynamically -->
<!--        <xsl:call-template name="authorBrowse"/>-->
    </xsl:template>
    
    <xsl:template name="volumeBrowse">
        <!-- sourceDesc/ biblScope type="vol" n="10" -->
        <!-- one page for each volume -->
        <xsl:for-each-group select="collection(concat($dataPath,'/.?select=*.xml'))//t:TEI[descendant-or-self::t:sourceDesc/descendant::t:biblScope[@type='vol']]" group-by="descendant-or-self::t:sourceDesc/descendant::t:biblScope[@type='vol']">
            <xsl:variable name="vol" select="descendant-or-self::t:sourceDesc/descendant::t:biblScope[@type='vol'][1]"/>
            <xsl:variable name="sortOption">
                <xsl:choose>
                    <xsl:when test="$vol castable as xs:integer"><xsl:value-of select="xs:integer($vol)"/></xsl:when>
                    <xsl:otherwise>0</xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:variable name="date" select="descendant-or-self::t:publicationStmt/descendant-or-self::t:date"/>
            <xsl:variable name="label" select="concat('Volume ',current-grouping-key(), ' (',$date[1],')')"/>
            <!-- output a page for each volume -->
            <xsl:variable name="articles">
                <xsl:for-each select="current-group()">
                    <xsl:variable name="date" select="descendant-or-self::t:publicationStmt/t:date"/>
                    <xsl:variable name="type">
                        <xsl:choose>
                            <xsl:when test="descendant::t:text/@type = 'introduction'">Introduction</xsl:when>
                            <xsl:when test="descendant::t:text/@type = 'obituary'">In Memoriam</xsl:when>
                            <xsl:when test="descendant::t:text/@type = 'article'">Articles</xsl:when>
                            <xsl:when test="descendant::t:text/@type = 'shortArticle'">Short Articles</xsl:when>
                            <xsl:when test="descendant::t:text/@type = 'bibliography'">Bibliographies</xsl:when>
                            <xsl:when test="descendant::t:text/@type = 'report'">Reports</xsl:when>
                            <xsl:when test="descendant::t:text/@type = 'review,bookReview'">Reviews</xsl:when>
                            <xsl:when test="descendant::t:text/@type = 'review'">Reviews</xsl:when>
                            <xsl:when test="descendant::t:text/@type = 'bookReview'">Reviews</xsl:when>
                            <xsl:when test="descendant::t:text/@type = 'announcement'">Announcements</xsl:when>
                        </xsl:choose>
                    </xsl:variable>
                    <xsl:variable name="typeOrder">
                        <xsl:choose>
                            <xsl:when test="descendant::t:text/@type = 'introduction'">1</xsl:when>
                            <xsl:when test="descendant::t:text/@type = 'obituary'">2</xsl:when>
                            <xsl:when test="descendant::t:text/@type = 'article'">3</xsl:when>
                            <xsl:when test="descendant::t:text/@type = 'shortArticle'">4</xsl:when>
                            <xsl:when test="descendant::t:text/@type = 'bibliography'">5</xsl:when>
                            <xsl:when test="descendant::t:text/@type = 'report'">6</xsl:when>
                            <xsl:when test="descendant::t:text/@type = 'review,bookReview'">7</xsl:when>
                            <xsl:when test="descendant::t:text/@type = 'review'">7</xsl:when>
                            <xsl:when test="descendant::t:text/@type = 'bookReview'">7</xsl:when>
                            <xsl:when test="descendant::t:text/@type = 'announcement'">8</xsl:when>
                            <xsl:otherwise>9</xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <xsl:variable name="issue" select="descendant-or-self::t:sourceDesc/descendant::t:biblScope[@type='issue'][1]"/>
                    <xsl:variable name="n">
                        <xsl:choose>
                            <xsl:when test="descendant::t:sourceDesc/descendant::t:biblScope[@type='order']">
                                <xsl:value-of select="descendant::t:sourceDesc/descendant::t:biblScope[@type='order']/@n"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="descendant::t:sourceDesc/descendant::t:biblScope[@type='pp']/@from"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <xsl:variable name="sort">
                        <xsl:choose>
                            <xsl:when test="$n castable as xs:integer"><xsl:value-of select="xs:integer($n)"/></xsl:when>
                            <xsl:otherwise>0</xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <article sort="{$sort}" type="{$type}" issue="{$issue}" typeOrder="{$typeOrder}">
                        <div class="indent" style="border-bottom:1px dotted #eee; padding:1em" 
                            date="{$date}" 
                            sort="{$sort}" 
                            type="{$type}" 
                            issue="{$issue}" 
                            typeOrder="{$typeOrder}">
                            <xsl:call-template name="recSummary">
                                <xsl:with-param name="nodes" select="root(.)"/>
                            </xsl:call-template>
                        </div>
                    </article>
                </xsl:for-each>
            </xsl:variable>
            <xsl:result-document href="{concat($staticSitePath,'/volume/',$vol,'.html')}">
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
                                    <xsl:when test="$template/descendant::html:div[@class[contains(.,'navbar ')]]">
                                        <xsl:copy-of select="$template/descendant::html:div[@class[contains(.,'navbar ')]][1]"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:message>No template found for html:head element</xsl:message>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:message>No template found for html:head element</xsl:message>
                            </xsl:otherwise>
                        </xsl:choose>
                        <div class="banner-interior" data-template="app:fix-links">
                            <div class="hugoye-banner">
                                <img src="/resources/img/hugoye_banner.png" />
                            </div>
                        </div>
                        <h1 class="banner indent">Volume Index</h1>
                        <div class="issue indent">
                            <div class="results-panel">
                                <h2>Volume <xsl:value-of select="$vol"/></h2>
                                <xsl:for-each-group select="$articles/child::*" group-by="@issue">
                                    <xsl:sort select="current-grouping-key()"/>
                                    <h3>Issue <xsl:value-of select="current-grouping-key()"/></h3>
                                    <xsl:for-each-group select="current-group()" group-by="@type">
                                        <xsl:sort select="@typeOrder"/>
                                        <h3><xsl:value-of select="current-grouping-key()"/></h3>
                                        <xsl:for-each select="current-group()">
                                            <xsl:sort select="@n"/>
                                            <xsl:copy-of select="child::*"/>
                                        </xsl:for-each>
                                    </xsl:for-each-group>
                                    <!--
                                    <xsl:for-each select="current-group()">
                                        <xsl:for-each-group select="current-group()" group-by="@type">
                                            <xsl:sort select="@typeOrder"/>
                                            <div>
                                                <h3><xsl:value-of select="current-grouping-key()"/></h3>
                                                <xsl:for-each select="current-group()">
                                                    <xsl:sort select="@n"></xsl:sort>
                                                    <xsl:copy-of select="child::*"/>    
                                                </xsl:for-each>
                                            </div>
                                        </xsl:for-each-group>
                                    </xsl:for-each>
                                    -->
                                </xsl:for-each-group>
                            </div>
                        </div>
                    </body>
                </html>
            </xsl:result-document>
        </xsl:for-each-group> 
        <!-- browse all volumes -->
        <xsl:result-document href="{concat($staticSitePath,'/volumes.html')}">
            <xsl:variable name="volumes">
                <xsl:for-each-group select="collection(concat($dataPath,'/.?select=*.xml'))//t:teiHeader[descendant-or-self::t:sourceDesc/descendant::t:biblScope[@type='vol']]" group-by="descendant-or-self::t:sourceDesc/descendant::t:biblScope[@type='vol']">
                    <xsl:variable name="vol" select="descendant-or-self::t:sourceDesc/descendant::t:biblScope[@type='vol'][1]"/>
                    <xsl:variable name="sortOption">
                        <xsl:choose>
                            <xsl:when test="$vol castable as xs:integer"><xsl:value-of select="xs:integer($vol)"/></xsl:when>
                            <xsl:otherwise>0</xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <xsl:variable name="date" select="descendant-or-self::t:publicationStmt/descendant-or-self::t:date"/>
                    <xsl:variable name="label" select="concat('Volume ',current-grouping-key(), ' (',$date[1],')')"/>
                    <xsl:for-each-group select="." group-by="$sortOption">
                        <xsl:sort select="$sortOption" order="descending"/>
                        <volume n="{current-grouping-key()}">
                            <div class="indent" xmlns="http://www.w3.org/1999/xhtml" style="margin-bottom:1em;">
                                <a href="{concat('/volume/',current-grouping-key())}"> <xsl:value-of select="$label"/> </a>&#160; 
                            </div>
                        </volume>
                    </xsl:for-each-group>
                </xsl:for-each-group>   
            </xsl:variable>
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
                                <xsl:when test="$template/descendant::html:div[@class[contains(.,'navbar ')]]">
                                    <xsl:copy-of select="$template/descendant::html:div[@class[contains(.,'navbar ')]][1]"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:message>No template found for html:head element</xsl:message>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:message>No template found for html:head element</xsl:message>
                        </xsl:otherwise>
                    </xsl:choose>
                    <div class="banner-interior" data-template="app:fix-links">
                        <div class="hugoye-banner">
                            <img src="/resources/img/hugoye_banner.png" />
                        </div>
                    </div>
                    <h1 class="banner indent">Volume Index</h1>
                    <div class="results-panel">
                        <div class="indent volumes-list">
                        <xsl:for-each select="$volumes/*:volume">
                            <xsl:sort select="xs:integer(@n)" order="descending"/>
                            <xsl:copy-of select="child::*"/>
                        </xsl:for-each>
                        </div>
                    </div>
                </body>
            </html>
        </xsl:result-document>
    </xsl:template>
    
    <xsl:template name="authorBrowse">
        <xsl:result-document href="{concat($staticSitePath,'/authors.html')}">
            <xsl:for-each-group select="collection(concat($dataPath,'/.?select=*.xml'))//t:titleStmt/t:author/t:name" group-by="t:surname">
                <xsl:sort select="current-grouping-key()"/>
                <xsl:variable name="authorFacet" select="replace(current-grouping-key(),'\s|\.|, ','')"/>
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
                                    <xsl:when test="$template/descendant::html:div[@class[contains(.,'navbar ')]]">
                                        <xsl:copy-of select="$template/descendant::html:div[@class[contains(.,'navbar ')]][1]"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:message>No template found for html:head element</xsl:message>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:message>No template found for html:head element</xsl:message>
                            </xsl:otherwise>
                        </xsl:choose>
                        <div class="banner-interior" data-template="app:fix-links">
                            <div class="hugoye-banner">
                                <img src="/resources/img/hugoye_banner.png" />
                            </div>
                        </div>
                        <h1 class="banner indent">Author Index</h1>
                        <div class="indent" xmlns="http://www.w3.org/1999/xhtml" style="margin-bottom:1em;">
                            <a href="#show{$authorFacet}" class="togglelink text-info" 
                                data-toggle="collapse" 
                                data-target="#show{$authorFacet}"
                                data-text-swap=" - {$authorFacet}">
                                <xsl:value-of select="string-join(descendant::text(),' ')"/> (<xsl:value-of select="count(current-group())"/>)
                            </a>
                            <div class="indent collapse" style="background-color:#F7F7F9;" id="show{$authorFacet}">
                                <xsl:for-each select="current-group()">
                                    <xsl:sort select="root(.)/descendant::t:publicationStmt/t:date"/>
                                    <xsl:variable name="date" select="root(.)/descendant::t:publicationStmt/t:date[1]"/>
                                    <xsl:variable name="id" select="replace(root(.)/descendant::t:idno[@type='URI'][1],'/tei','')"/>
                                    <div class="indent" style="border-bottom:1px dotted #eee; padding:1em">
                                        <xsl:call-template name="recSummary">
                                            <xsl:with-param name="nodes" select="root(.)"/>
                                        </xsl:call-template>
                                    </div>
                                </xsl:for-each>
                            </div>
                        </div>
                    </body>
                </html>
            </xsl:for-each-group> 
        </xsl:result-document>
    </xsl:template>
    
    <xsl:template name="recSummary">
        <xsl:param name="nodes"/>
        <xsl:variable name="id" select="replace(root(.)/descendant::t:idno[@type='URI'][1],'/tei','')"/>
        <xsl:variable name="title">
                <xsl:if test="$nodes/descendant-or-self::t:title[@type='main']"><xsl:apply-templates select="$nodes/descendant-or-self::t:title[@type='main']"></xsl:apply-templates></xsl:if>
            <xsl:if test="$nodes/descendant-or-self::t:title[@type='sub']//text() != ''">
                <xsl:text>: </xsl:text><xsl:value-of select="$nodes/descendant-or-self::t:title[@type='sub']"/>
            </xsl:if>            
        </xsl:variable>
        <div class="short-rec-view" xmlns="http://www.w3.org/1999/xhtml">
            <a href="{$id}"><xsl:sequence select="$title"/></a><br/>
            <xsl:if test="$nodes/descendant::t:titleStmt/t:author">
                <xsl:text>By </xsl:text><xsl:call-template name="responsiblePersons"><xsl:with-param name="persons" select="$nodes/descendant::t:titleStmt/t:author"/><xsl:with-param name="limit"/></xsl:call-template>
            </xsl:if>
        </div>
        <!-- 
            <div class="short-rec-view">
            <a href="{replace($id,$global:base-uri,$global:nav-base)}" dir="ltr">{$title}</a> 
            {if($nodes/descendant::tei:titleStmt/tei:author) then 
                (:(' by ', tei2html:tei2html($nodes/descendant::tei:titleStmt/tei:author/tei:name)):)
                <span class="results-list-desc desc" dir="ltr" lang="en">
                {(' By ', bibl2html:emit-responsible-persons($nodes/descendant::tei:titleStmt/tei:author,10))}
                </span>
            else ()}
            {if($nodes/descendant::tei:biblStruct) then 
                <span class="results-list-desc desc" dir="ltr" lang="en">
                    <label>Source: </label> {bibl2html:citation($nodes/descendant::tei:sourceDesc/descendant::tei:monogr)}
                </span>
            else ()}
            {if($nodes[//@xml:id = '^abstract']) then 
                for $abstract in $nodes/descendant::*[@xml:id = '^abstract']
                let $string := string-join($abstract/descendant-or-self::*/text(),' ')
                let $blurb := 
                    if(count(tokenize($string, '\W+')[. != '']) gt 25) then  
                        concat(string-join(for $w in tokenize($string, '\W+')[position() lt 25]
                        return $w,' '),'...')
                     else $string 
                return 
                    <span class="results-list-desc desc" dir="ltr" lang="en">{
                        if($abstract/descendant-or-self::tei:quote) then concat('"',normalize-space($blurb),'"')
                        else $blurb
                    }</span>
            else()}
            {if($nodes/descendant::*:match) then
              <div>
                <span class="results-list-desc srp-label">Matches:</span>
                {
                 for $r in $nodes/descendant::*:match/parent::*[1]
                 return   
                    if(position() lt 8) then 
                        <span class="results-list-desc container">
                            <span class="srp-label">
                                {concat(position(),'. (', name(.),') ')}
                            </span>
                            {tei2html:tei2html(.)}
                            {if(position() = 8) then <span class="results-list-desc container">more ...</span> else()}
                        </span>
                    else ()
                }
              </div>
            else()}
            {
            if($id != '') then 
            <span class="results-list-desc uri"><span class="srp-label">URI: </span><a href="{replace($id,$global:base-uri,$global:nav-base)}">{$id}</a></span>
            else()
            }
        </div>    -->
    </xsl:template>
    <xsl:template name="responsiblePersons">
        <xsl:param name="persons"/>
        <xsl:param name="limit"/>
        <xsl:variable name="limit">
            <xsl:choose>
                <xsl:when test="$limit = ''">0</xsl:when>
                <xsl:when test="$limit castable as xs:integer"><xsl:value-of select="xs:integer($limit)"/></xsl:when>
                <xsl:otherwise>0</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>    
        <xsl:variable name="count" select="count($persons)"/>
        <xsl:variable name="num">
            <xsl:choose>
                <xsl:when test="$limit &lt; $count"><xsl:value-of select="$limit"/></xsl:when>
                <xsl:otherwise><xsl:value-of select="$count"/></xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="personString">
            <xsl:choose>
                <xsl:when test="$count = 1">
                    <xsl:value-of select="local:persNames($persons)"/>
                </xsl:when>
                <xsl:when test="$count = 2">
                    <xsl:value-of select="local:persNames($persons[1])"/><xsl:text> and </xsl:text><xsl:value-of select="local:persNames($persons[2])"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:for-each select="$persons[position() &lt; $limit]">
                        <xsl:choose>
                            <xsl:when test="position() = ($limit - 1)">
                                <xsl:value-of select="local:persNames($persons[1])"/><xsl:text> and </xsl:text>
                            </xsl:when>
                            <xsl:when test="position() = $limit">
                                <xsl:value-of select="concat(normalize-space(local:persNames($persons)),' ')"/>
                            </xsl:when>
                            <xsl:otherwise><xsl:value-of select="concat(normalize-space(local:persNames($persons)),', ')"/></xsl:otherwise>
                        </xsl:choose>
                    </xsl:for-each>
                </xsl:otherwise>
            </xsl:choose>    
        </xsl:variable>
        <xsl:value-of select="replace(string-join($personString),'\s+$','')"/>
    </xsl:template>
</xsl:stylesheet>
