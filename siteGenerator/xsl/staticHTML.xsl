<xsl:stylesheet  
    xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:t="http://www.tei-c.org/ns/1.0" 
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:x="http://www.w3.org/1999/xhtml" 
    xmlns:srophe="https://srophe.app" 
    xmlns:saxon="http://saxon.sf.net/" 
    xmlns:xs="http://www.w3.org/2001/XMLSchema" 
    xmlns:local="http://syriaca.org/ns" 
    exclude-result-prefixes="xs t x saxon local" version="3.0">

 <!-- ================================================================== 
      staticHTML.xsl
       
       Generate Static HTML pages for TEI display 
       Code can be used to convert from an old Srophe based application. Or to start an entierly new application.
       
       To convert an existing Srophe application:
       1. Include the path to the existing application under @applicationPath
       2. Include path to new app location, to copy @staticSitePath
       3. Set @convert parameter to 'true'
       
       To start a new application:
       1. Set @convert parameter to 'false'
       2. Run TEI through xslt. Make sure there are matching HTML templates in the ../components directory 
          for each collection that has been declared in your repo-config.xml 
       
       
       
        
       code by: 
        + Winona Salesky (wsalesky@gmail.com)
          
       funding provided by:
        + National Endowment for the Humanities (http://www.neh.gov). Any 
          views, findings, conclusions, or recommendations expressed in 
          this code do not necessarily reflect those of the National 
          Endowment for the Humanities.
       
       ================================================================== -->
 <!-- =================================================================== -->
 <!-- import component stylesheets for HTML page portions -->
 <!-- =================================================================== -->
    <xsl:import href="tei2html.xsl"/>
<!--    <xsl:import href="helper-functions.xsl"/>-->
    <xsl:import href="maps.xsl"/>
<!--    <xsl:import href="json.xsl"/>-->
<!--    <xsl:import href="relationships.xsl"/>-->
    
 <!-- =================================================================== -->
 <!-- set output so we get (mostly) indented HTML -->
 <!-- =================================================================== -->
    <xsl:output name="html" encoding="UTF-8" method="xhtml" indent="no" omit-xml-declaration="yes"/>    
    
    <!-- 
    Step 1: 
    create HTML page outline
        include header
        include nav for submodule
        transform HTML
        Add Footer
        
        Add dynamic (javascript calls to RDF or other related items)
        
        -->
 
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
    
    <xsl:param name="applicationPath" select="'/Users/wsalesky/syriaca/SyriacCorpus/syriac-corpus-app'"/>
    <xsl:param name="staticSitePath" select="'/Users/wsalesky/syriaca/SyriacCorpus/syriac-corpus-app-temp'"/>
    <xsl:param name="dataPath" select="'/Users/wsalesky/syriaca/SyriacCorpus/syriac-corpus'"/>
    <!-- <xsl:param name="dataPath" select="'/Users/wsalesky/syriaca/syriaca/syriaca-data/data/'"/> -->
    
    <!-- Example: generate new index.html page for places collection -->
    <xsl:param name="convert" select="'true'"/>
    <xsl:param name="outputFile" select="''"/>
    <xsl:param name="outputCollection" select="''"/>
    
    <!-- Generate new TEI page, run over any TEI. 
    <xsl:param name="outputFile" select="''"/>
    <xsl:param name="outputCollection" select="''"/>
    -->
    
    <!-- Find repo-config to find collection style values and page stubs -->
    <xsl:variable name="configPath">
        <xsl:choose>
            <xsl:when test="$staticSitePath != ''">
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
      
    <!-- Root of app for building dynamic links. Default is eXist app root -->
    <!-- Not needed? -->
    <xsl:variable name="nav-base" select="'/'"/>
    
    <!-- Base URI for identifiers in app data -->
    <xsl:variable name="base-uri">
        <xsl:choose>
            <xsl:when test="$config/descendant::*:base_uri">
                <xsl:value-of select="$config/descendant::*:base_uri"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="'http://syriaca.org'"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    
    <!-- Hard coded values-->
    <xsl:param name="normalization">NFKC</xsl:param>
    
    <!-- Variables for building HTML from TEI records -->
    <!-- Repository Title -->
    <xsl:variable name="repository-title">
        <xsl:choose>
            <xsl:when test="$config/child::*">
                <xsl:value-of select="$config/descendant::*:title[1]"/>
            </xsl:when>
            <xsl:otherwise>The Gaddel Application</xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="collection-title">
        <xsl:choose>
            <xsl:when test="$config/child::*">
                <xsl:choose>
                    <xsl:when test="$config/descendant::*:collection[@name=$collection]">
                        <xsl:value-of select="$config/descendant::*:collection[@name=$collection]/@title"/>
                    </xsl:when>
                    <xsl:when test="$config/descendant::*:collection[@title=$collection]">
                        <xsl:value-of select="$config/descendant::*:collection[@title=$collection]/@title"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$repository-title"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$repository-title"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    
    <!-- Resource title -->
    <xsl:variable name="resource-title">
        <xsl:choose>
            <xsl:when test="/descendant::t:text/t:body[descendant::*[@srophe:tags = '#syriaca-headword']]">
                <xsl:apply-templates select="/descendant::t:text/t:body[descendant::*[@srophe:tags = '#syriaca-headword']][@xml:lang = 'en']/text()"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="/descendant-or-self::t:titleStmt/t:title[1]"/>                
            </xsl:otherwise>            
        </xsl:choose>
    </xsl:variable>
    
    <!-- Resource id -->
    <xsl:variable name="resource-path" select="substring-after(document-uri(.),':')"/>
        
    
    <!-- Figure out if document is HTML or TEI -->
    <xsl:template match="/">
        <xsl:variable name="documentURI" select="document-uri(.)"/>
        <!-- File type for conversion or creation -->
        <xsl:variable name="fileType">
            <xsl:choose>
                <xsl:when test="$convert = 'false' and $outputFile != ''">HTML</xsl:when>
                <xsl:when test="/html:div[@data-template-with]">HTML</xsl:when>
                <xsl:when test="/t:TEI">TEI</xsl:when>
                <xsl:when test="/rdf:RDF">RDF</xsl:when>
                <xsl:otherwise>OTHER: <xsl:value-of select="name(root(.))"/></xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <!-- Filename for new HTML file -->
        <xsl:variable name="filename">
            <xsl:choose>
                <!-- For generating a new file using the templates defined in the components directory.  -->
                <xsl:when test="$convert = 'false' and $outputFile != ''">
                    <xsl:variable name="collectionPath">
                        <xsl:if test="$outputCollection != ''">
                            <xsl:value-of select="$config/descendant::*:collection[@name = $outputCollection]/@app-root"/>
                        </xsl:if>
                    </xsl:variable>
                    <xsl:choose>
                        <xsl:when test="$outputCollection != ''">
                            <xsl:value-of select="concat($config/descendant::*:collection[@name = $outputCollection]/@app-root,'',$outputFile)"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="concat('/',$outputFile)"/>        
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="replace(tokenize($documentURI,'/')[last()],'.xml','.html')"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="path">
            <xsl:choose>
                <xsl:when test="$convert = 'false' and $outputFile != '' and $fileType = 'HTML'">
                    <path><xsl:value-of select="concat($staticSitePath,'/',$filename)"/></path>
                </xsl:when>
                <xsl:when test="$fileType = 'HTML'">
                    <!--<path idno=""><xsl:value-of select="concat($staticSitePath,replace($resource-path,$applicationPath,''))"/></path>-->
                    <path><xsl:value-of select="concat($staticSitePath,replace($resource-path,$applicationPath,''))"/></path>
                </xsl:when>
                <xsl:when test="$fileType = 'TEI'">
                    <xsl:variable name="idno" select="replace(descendant::t:publicationStmt/t:idno[@type='URI'],'/tei','')"/>
                    <path idno="{$idno}"><xsl:value-of select="concat(replace($idno,$base-uri,concat($staticSitePath,'/data')),'.html')"/></path>
                </xsl:when>
                <xsl:when test="$fileType = 'RDF'">
                    <!-- Output a page for each rdf:Description (with http://syriaca.org/taxonomy/) -->
                    <xsl:for-each select="//rdf:Description[starts-with(@rdf:about,'http://syriaca.org/taxonomy/')]">
                        <xsl:if test="replace(@rdf:about,'http://syriaca.org/taxonomy/','') != ''">
                            <xsl:variable name="idno" select="@rdf:about"/>
                            <xsl:choose>
                                <xsl:when test="$idno = 'http://syriaca.org/taxonomy/syriac-taxonomy'">
                                    <path idno="{$idno}"><xsl:value-of select="concat($staticSitePath,'/taxonomy/browse.html')"/></path>
                                </xsl:when>
                                <xsl:otherwise>
                                    <path idno="{$idno}"><xsl:value-of select="concat(replace($idno,$base-uri,concat($staticSitePath,'entry/')),'.html')"/></path>        
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:if>
                    </xsl:for-each>                    
                </xsl:when>
                <xsl:otherwise><xsl:message>Unrecognizable file type <xsl:value-of select="$fileType"/> [<xsl:value-of select="$documentURI"/>]</xsl:message></xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="nodes" select="//t:TEI | //rdf:RDF | *"/>
        <xsl:for-each-group select="$path/child::*" group-by=".">
            <xsl:message>Path: <xsl:value-of select="$path"/></xsl:message>
            <xsl:result-document href="{replace(.,'.xml','.html')}">
                <xsl:choose>
                    <xsl:when test="$fileType = 'HTML'">
                        <xsl:call-template name="htmlPage">
                            <xsl:with-param name="pageType" select="'HTML'"/>
                            <xsl:with-param name="nodes" select="$nodes"/>
                            <xsl:with-param name="idno" select="''"/>
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:when test="$fileType = 'TEI'">
                        <xsl:call-template name="htmlPage">
                            <xsl:with-param name="pageType" select="'TEI'"/>
                            <xsl:with-param name="nodes" select="$nodes"/>
                            <xsl:with-param name="idno" select="@idno"/>
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:when test="$fileType = 'RDF'">
                        <xsl:call-template name="htmlPage">
                            <xsl:with-param name="pageType" select="'RDF'"/>
                            <xsl:with-param name="nodes" select="$nodes"/>
                            <xsl:with-param name="idno" select="@idno"/>
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:message>Unrecognizable file type <xsl:value-of select="$fileType"/></xsl:message>
                    </xsl:otherwise>    
                </xsl:choose>
            </xsl:result-document>
        </xsl:for-each-group>
    </xsl:template>
    
    <xsl:template name="htmlPage">
        <xsl:param name="pageType"/>
        <xsl:param name="nodes"/>
        <xsl:param name="idno"/>
        <xsl:variable name="root">
            <xsl:choose>
                <xsl:when test="$nodes/descendant::t:idno[@type='front'] or $nodes/descendant::t:idno[@type='back']">
                    <xsl:sequence select="$nodes/descendant-or-self::t:idno[@type='URI'][. = $idno]/parent::t:ab/parent::t:div[@type][1]"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:sequence select="$nodes"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <!-- Collection variables from repo-config -->
        <xsl:variable name="collectionURIPattern">
            <xsl:if test="$idno != ''">
                <xsl:for-each select="tokenize($idno,'/')">
                    <xsl:if test="position() != last()"><xsl:value-of select="concat(.,'/')"/></xsl:if>
                </xsl:for-each>
            </xsl:if>
        </xsl:variable>
<!--        <xsl:variable name="collectionValues" select="concat($staticSitePath,'/siteGenerator/components/page.html')"/>        -->
        <xsl:variable name="collectionTemplate">
            <xsl:message>Find generic page.html template</xsl:message>
            <xsl:variable name="templatePath" select="concat($staticSitePath,'/siteGenerator/components/page.html')"/>
            <xsl:if test="doc-available(xs:anyURI($templatePath))">
                <xsl:sequence select="document(xs:anyURI($templatePath))"/>
            </xsl:if>
        </xsl:variable>
<!--        <xsl:variable name="collection" select="$collectionValues/@name"/>-->
        <!-- <xsl:apply-templates/> -->
        <html xmlns="http://www.w3.org/1999/xhtml">
            <!-- HTML Header, use templates as already estabilished, if no template exists, use generic 'page.html' -->
            <xsl:variable name="template">
                <xsl:choose>
                    <xsl:when test="$pageType = 'HTML'">
                        <xsl:choose>
                            <xsl:when test="$collectionTemplate/child::*">
                                <xsl:sequence select="$collectionTemplate"/> 
                            </xsl:when>
                            <xsl:otherwise><xsl:message>Error Can not find matching template for HTML page </xsl:message></xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:when test="$pageType = 'TEI'">
                        <xsl:choose>
                            <xsl:when test="$collectionTemplate/child::*">
                                <xsl:sequence select="$collectionTemplate"/> 
                            </xsl:when>
                            <xsl:otherwise><xsl:message>Error Can not find matching template for TEI page </xsl:message></xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:when test="$pageType = 'RDF'">
                        <xsl:choose>
                            <xsl:when test="$collectionTemplate/child::*">
                                <xsl:sequence select="$collectionTemplate"/> 
                            </xsl:when>
                            <xsl:otherwise><xsl:message>Error Can not find matching template for TEI page </xsl:message></xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                </xsl:choose>
            </xsl:variable>
                <xsl:choose>
                    <xsl:when test="$template/descendant::*:head">
                        <xsl:choose>
                            <xsl:when test="$template/descendant::*:head">
                                <xsl:choose>
                                    <xsl:when test="$pageType = 'TEI'">
                                            <!--<xsl:sequence select="$collectionTemplate"/>-->
                                            <head xmlns="http://www.w3.org/1999/xhtml">
                                                <!--<xsl:sequence select="$collectionTemplate"/>-->
                                                <xsl:for-each select="$collectionTemplate/descendant::*:head/child::*">
                                                    <xsl:choose>
                                                        <xsl:when test="local-name() = 'title'">
                                                            <title xmlns="http://www.w3.org/1999/xhtml">
                                                                <xsl:choose>
                                                                    <xsl:when test="$nodes/descendant::t:body[descendant::*[@srophe:tags = '#syriaca-headword']]">
                                                                        <xsl:value-of select="$nodes/descendant::t:body/descendant::*[@srophe:tags = '#syriaca-headword'][@xml:lang = 'en']"/>
                                                                    </xsl:when>
                                                                    <xsl:otherwise>
                                                                       <xsl:value-of select="$nodes/descendant-or-self::t:titleStmt/t:title[1]"/>                
                                                                    </xsl:otherwise>            
                                                                </xsl:choose> 
                                                            </title> 
                                                        </xsl:when>
                                                        <xsl:otherwise>
                                                            <xsl:copy-of select="."/>
                                                        </xsl:otherwise>
                                                    </xsl:choose>
                                                </xsl:for-each>
                                            </head> 
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:copy-of select="$template/descendant::*:head"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:when>
                            <xsl:otherwise><xsl:message>Error in template, check template for html:head </xsl:message></xsl:otherwise>
                        </xsl:choose>
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
                                <xsl:copy-of select="$template/descendant::html:div[@role='navigation']"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:message>No template found for html:nav element 3</xsl:message>
                                <xsl:call-template name="genericNav"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:message>No template found for html:head element</xsl:message>
                        <xsl:call-template name="genericNav"/>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:choose>
                    <xsl:when test="$pageType = 'HTML'">
                        <xsl:copy-of select="$nodes"/>
                    </xsl:when>
                    <xsl:when test="$pageType = 'RDF'">
                        <xsl:apply-templates select="$nodes/rdf:Description[@rdf:about = $idno]"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:choose>
                            <xsl:when test="$collectionTemplate">
                                <div class="main-content-block" xmlns="http://www.w3.org/1999/xhtml">
                                    <div class="interior-content">
                                        <div class="interior-content" style="margin-left:1%; margin-right:1%;">
                                            <xsl:for-each select="$nodes/ancestor-or-self::t:TEI">
                                                <xsl:call-template name="h1"/>    
                                            </xsl:for-each>
                                        </div>
                                        <div class="row row-centered top-padding">
                                            <xsl:variable name="toc">
                                                <xsl:call-template name="toc">
                                                    <xsl:with-param name="node" select="$nodes/descendant::t:body/child::*"/>
                                                </xsl:call-template>
                                            </xsl:variable>
                                                
                                            <div class="col-md-2 noprint" xmlns="http://www.w3.org/1999/xhtml">
                                                    <xsl:if test="$nodes/descendant::t:body/descendant::*[@n][not(@type='section') and not(@type='part')]">
                                                        <div class="panel panel-default">
                                                            <div class="panel-heading"><a href="#" data-toggle="collapse" data-target="#toggleText">Show  </a>
                                                                <span class="glyphicon glyphicon-question-sign text-info moreInfo" aria-hidden="true" data-toggle="tooltip" 
                                                                    title="Toggle the text display to show line numbers, section numbers and other structural divisions"></span>
                                                            </div>
                                                            <div class="panel-body collapse in" id="toggleText">
                                                                <xsl:variable name="types" select="distinct-values($nodes/descendant::t:body/descendant::t:div[@n]/@type)"/>
                                                                <xsl:for-each select="$types">
                                                                    <xsl:sort select="."/>
                                                                    <xsl:choose>
                                                                        <xsl:when test=". = ('part','text','rubric','heading','title')"></xsl:when>
                                                                        <xsl:otherwise>
                                                                            <div class="toggle-buttons">
                                                                                <span class="toggle-label"><xsl:value-of select="."/> : </span>
                                                                                <input class="toggleDisplay" type="checkbox" id="toggle{.}" data-element="{concat('tei-',.)}" checked="if. = 'section') then 'checked' else()"/>
                                                                                <label for="toggle{.}"><xsl:value-of select="."/></label>
                                                                            </div>
                                                                        </xsl:otherwise>
                                                                    </xsl:choose>
                                                                </xsl:for-each>
                                                                <xsl:if test="$nodes/descendant::t:body/descendant::t:ab[not(@type) and not(@subtype)][@n]">
                                                                    <div class="toggle-buttons">
                                                                        <span class="toggle-label"> ab : </span>
                                                                        <input class="toggleDisplay" type="checkbox" id="toggleab" data-element="tei-ab"/>
                                                                        <label for="toggleab">ab</label>
                                                                    </div>
                                                                </xsl:if>
                                                                <xsl:if test="$nodes/descendant::t:body/descendant::t:ab[@type][@n]">
                                                                    <div class="toggle-buttons">
                                                                        <span class="toggle-label"> ab : </span>
                                                                        <input class="toggleDisplay" type="checkbox" id="toggleab" data-element="tei-ab"/>
                                                                        <label for="toggleab">ab</label>
                                                                    </div>
                                                                </xsl:if>
                                                                <xsl:if test="$nodes/descendant::t:body/descendant::t:l">
                                                                    <div class="toggle-buttons">
                                                                        <span class="toggle-label"> line : </span>
                                                                        <input class="toggleDisplay" type="checkbox" id="togglel" data-element="tei-l" checked="checked"/>
                                                                        <label for="togglel">line</label>
                                                                    </div>
                                                                </xsl:if>
                                                                <xsl:if test="$nodes/descendant::t:body/descendant::t:lb">
                                                                    <div class="toggle-buttons">
                                                                        <span class="toggle-label"> line break : </span>
                                                                        <input class="toggleDisplay" type="checkbox" id="togglelb" data-element="tei-lb"/>
                                                                        <label for="togglelb">line break</label>
                                                                    </div>
                                                                </xsl:if>
                                                                <xsl:if test="$nodes/descendant::t:body/descendant::t:lg">
                                                                    <div class="toggle-buttons">
                                                                        <span class="toggle-label"> line group : </span>
                                                                        <input class="toggleDisplay" type="checkbox" id="togglelg" data-element="tei-lg"/>
                                                                        <label for="togglelg">line group</label>
                                                                    </div>    
                                                                </xsl:if>
                                                                <xsl:if test="$nodes/descendant::t:body/descendant::t:pb">
                                                                    <div class="toggle-buttons">
                                                                        <span class="toggle-label"> page break : </span>
                                                                        <input class="toggleDisplay" type="checkbox" id="togglepb" data-element="tei-pb"/>
                                                                        <label for="togglepb">page break</label>
                                                                    </div>    
                                                                </xsl:if>
                                                                <xsl:if test="$nodes/descendant::t:body/descendant::t:cb">
                                                                    <div class="toggle-buttons">
                                                                        <span class="toggle-label"> column break : </span>
                                                                        <input class="toggleDisplay" type="checkbox" id="togglecb" data-element="tei-cb"/>
                                                                        <label for="togglecb">column break</label>
                                                                    </div>   
                                                                </xsl:if>
                                                                <xsl:if test="$nodes/descendant::t:body/descendant::t:milestone[not(@type) and not(@subtype) and not(@unit='SyrChapter')]">
                                                                    <div class="toggle-buttons">
                                                                        <span class="toggle-label"> milestone : </span>
                                                                        <input class="toggleDisplay" type="checkbox" id="togglemilestone" data-element="tei-milestone"/>
                                                                        <label for="togglemilestone">milestone</label>
                                                                    </div>  
                                                                </xsl:if>
                                                                <xsl:if test="$nodes/descendant::t:body/descendant::t:note[@place = ('foot','footer','footnote')]">
                                                                    <div class="toggle-buttons">
                                                                        <span class="toggle-label"> footnote : </span>
                                                                        <input class="toggleDisplay" type="checkbox" id="togglemilestone" data-element="tei-footnote" checked="checked"/>
                                                                        <label for="togglemilestone">footnote</label>
                                                                    </div>   
                                                                </xsl:if>
                                                            </div>
                                                        </div>
                                                    </xsl:if>
                                                    <xsl:if test="$toc/child::*[. = '']">
                                                    <div class="panel panel-default">
                                                        <div class="panel-heading"><a href="#" data-toggle="collapse" data-target="#showToc">Table of Contents  </a>
                                                        </div>
                                                        <div class="panel-body collapse in" id="showToc">
                                                            <xsl:copy-of select="$toc"/>
                                                        </div>
                                                    </div> 
                                                    </xsl:if>    
                                            </div>
                                            
                                            <div class="col-md-6 entry">
                                                <xsl:apply-templates select="$nodes/ancestor-or-self::t:TEI">
                                                    <xsl:with-param name="collection" select="$collection"/>
                                                    <xsl:with-param name="idno" select="$idno"/>
                                                </xsl:apply-templates>
                                            </div>
                                            <div class="col-md-4 right-menu">
                                                <div id="rightCol" class="noprint">
                                                    <div id="sedraDisplay" class="sedra panel panel-default">
                                                        <div class="panel-body">
                                                            <span style="display:block;text-align:center;margin:.5em;">
                                                                <a href=" http://sedra.bethmardutho.org" title="SEDRA IV">SEDRA IV</a>
                                                            </span>
                                                            <img src="/resources/images/sedra-logo.png" title="Sedra logo" width="100%"/>
                                                            <h3>Syriac Lexeme</h3>
                                                            <div id="sedraContent">
                                                                <div class="content"/>
                                                            </div>
                                                        </div>
                                                    </div>
                                                </div>
                                                <div class="panel panel-default">
                                                    <div class="panel-heading"><a href="#" data-toggle="collapse" data-target="#aboutDigitalText">About This Digital Text </a></div>
                                                    <div class="panel-body collapse in" id="aboutDigitalText">
                                                        <xsl:if test="$nodes/descendant::t:publicationStmt/t:idno[@type='URI']">
                                                            <div>
                                                                <h5>Corpus Text ID:</h5>
                                                                <span><xsl:value-of select="$nodes/descendant::t:publicationStmt/t:idno[@type='URI']"/></span>
                                                            </div>
                                                        </xsl:if>
                                                        <xsl:if test="$nodes/descendant::t:fileDesc/t:titleStmt/t:title[1]/@ref">
                                                            <div>
                                                                <h5>NHSL Work ID(s):</h5>
                                                                <xsl:for-each select="$nodes/descendant::t:fileDesc/t:titleStmt/t:title[@ref]">
                                                                    <span><a href="{string(@ref)}"><xsl:value-of select="@ref"/></a><br/></span>
                                                                </xsl:for-each>
                                                            </div>
                                                        </xsl:if>
                                                        <div>
                                                            <h5>Source: </h5>
                                                            <xsl:apply-templates select="$nodes/descendant::t:sourceDesc"/>
                                                            <xsl:if test="$nodes/descendant::t:sourceDesc/descendant::t:idno[starts-with(., 'http://syriaca.org/bibl')]">
                                                                <span class="footnote-links">
                                                                    <span class="footnote-icon"> 
                                                                        <a href="{$nodes/descendant::t:sourceDesc/descendant::t:idno[starts-with(., 'http://syriaca.org/bibl')][1]/text()}" title="Link to Syriaca.org Bibliographic Record" data-toggle="tooltip" data-placement="top" class="bibl-links">
                                                                            <img src="/resources/images/icons-syriaca-sm.png" alt="Link to Syriaca.org Bibliographic Record" height="18px"/>
                                                                        </a>
                                                                    </span>
                                                                </span>
                                                            </xsl:if>
                                                        </div>
                                                        <div style="margin-top:1em;">
                                                            <span class="h5-inline">Type of Text: 
                                                            </span>
                                                            <span>
                                                                <xsl:variable name="string" select="$nodes/descendant::t:text[1]/@type"/>
                                                                <xsl:variable name="title" select="concat(substring($string[1],1,1),replace(substring($string[1],2),'(\p{Lu})',concat(' ', '$1')))"/>
                                                                <xsl:variable name="title2" select="concat(upper-case(substring($title,1,1)),substring($title,2))"/>
                                                                <xsl:value-of select="$title2"/>
                                                            </span>
                                                            &#160;<a href="/documentation/wiki.html?wiki-page=/Types-of-Text-in-the-Digital-Syriac-Corpus&amp;wiki-uri=https://github.com/srophe/syriac-corpus/wiki"><span class="glyphicon glyphicon-question-sign text-info moreInfo"></span></a>
                                                        </div>
                                                        <div style="margin-top:1em;">
                                                            <span class="h5-inline">Status: 
                                                            </span>
                                                            <span>
                                                                <xsl:variable name="string" select="$nodes/descendant::t:revisionDesc[1]/@status"/>
                                                                <xsl:variable name="title" select="concat(substring($string[1],1,1),replace(substring($string[1],2),'(\p{Lu})',concat(' ', '$1')))"/>
                                                                <xsl:variable name="title2" select="concat(upper-case(substring($title,1,1)),substring($title,2))"/>
                                                                <xsl:value-of select="$title2"/>
                                                                </span>
                                                            &#160;<a href="/documentation/wiki.html?wiki-page=/Status-of-Texts-in-the-Digital-Syriac-Corpus&amp;wiki-uri=https://github.com/srophe/syriac-corpus/wiki"><span class="glyphicon glyphicon-question-sign text-info moreInfo"></span></a>
                                                        </div>
                                                        <div style="margin-top:1em;">
                                                            <span class="h5-inline">Publication Date: </span>
                                                            <xsl:value-of select="format-date(xs:date($nodes/descendant::t:revisionDesc/t:change[1]/@when), '[MNn] [D], [Y]')"/>
                                                        </div>
                                                        <div>
                                                            <h5>Preparation of Electronic Edition:</h5>
                                                            TEI XML encoding by James E. Walters. <br/>
                                                            Syriac text transcribed by <xsl:value-of select="$nodes/descendant::t:titleStmt/descendant::t:respStmt[t:resp[. = 'Syriac text transcribed by']]/t:name/text()"/>.
                                                        </div>
                                                        <div>
                                                            <h5>Open Access and Copyright:</h5>
                                                            <div class="small">
                                                                <xsl:apply-templates select="$nodes/descendant::t:teiHeader/t:fileDesc/t:publicationStmt/t:availability/t:ab[1]/t:note[1]/text()"/>
                                                                <div id="showMoreAccess" class="collapse">
                                                                    <xsl:apply-templates select="$nodes/descendant::t:teiHeader/t:fileDesc/t:publicationStmt/t:availability/t:ab[2]/t:note[1]/text()"/>
                                                                    <xsl:if test="$nodes/descendant::t:teiHeader/t:fileDesc/t:publicationStmt/t:availability/t:licence[contains(@target, 'http://creativecommons.org/licenses/')]">
                                                                        <p>
                                                                            <a rel="license" href="{$nodes/descendant::t:teiHeader/t:fileDesc/t:publicationStmt/t:availability/t:licence/@target}">
                                                                                <img alt="Creative Commons License" style="border-width:0;display:inline;" src="/resources/images/cc.png" height="18px"/>
                                                                            </a>
                                                                        </p>
                                                                    </xsl:if>                  
                                                                </div>
                                                                <a href="#" class="togglelink" data-toggle="collapse" data-target="#showMoreAccess" data-text-swap="Hide details">See details...</a>
                                                            </div>
                                                        </div>
                                                    </div>
                                                </div>  
                                                <!-- NOTE: More toggle does not work -->
                                                <xsl:apply-templates select="$nodes/descendant::t:teiHeader"/>
                                                <!-- RDF functions-->
                                                <xsl:if test="$nodes/descendant::*/@ref[contains(.,'http://syriaca.org/') and not(contains(.,'http://syriaca.org/persons.xml'))] or $nodes/descendant::t:idno[@type='URI']">
                                                    <div class="panel panel-default" style="margin-top:1em;" xmlns="http://www.w3.org/1999/xhtml">
                                                        <div class="panel-heading">
                                                            <a href="#" data-toggle="collapse" data-target="#showLinkedData">Linked Data  </a>
                                                            <span class="glyphicon glyphicon-question-sign text-info moreInfo" aria-hidden="true" data-toggle="tooltip" title="This sidebar provides links via Syriaca.org to additional resources beyond this record. We welcome your additions, please use the e-mail button on the right to contact Syriaca.org about submitting additional links."></span>
                                                            <button class="btn btn-default btn-xs pull-right" data-toggle="modal" data-target="#submitLinkedData" style="margin-right:1em;"><span class="glyphicon glyphicon-envelope" aria-hidden="true"></span></button>
                                                        </div>
                                                        <div class="panel-body collapse in" id="showLinkedData">
                                                            <xsl:variable name="otherResources" select="distinct-values($nodes/descendant::*/@ref[contains(.,'http://syriaca.org/') and not(contains(.,'http://syriaca.org/person.xml'))] | $nodes/descendant::t:idno[@type='URI'])"/>
                                                            <xsl:variable name="count" select="count($otherResources)"/>
                                                            <div class="other-resources" xmlns="http://www.w3.org/1999/xhtml">
                                                                <div class="collapse in" id="getRDF">
                                                                    <form class="form-inline hidden" action="https://sparql.vanderbilt.edu/sparql" method="get" id="lod1">
                                                                        <input type="hidden" name="format" id="format" value="json"/>
                                                                        <textarea id="query" class="span9" rows="15" cols="150" name="query" type="hidden">
                                                                            <xsl:text disable-output-escaping="yes">
                                                                                prefix rdfs: &lt;http://www.w3.org/2000/01/rdf-schema#&gt;
                                                                                prefix lawd: &lt;http://lawd.info/ontology/&gt;
                                                                                prefix skos: &lt;http://www.w3.org/2004/02/skos/core#&gt;
                                                                                prefix dcterms: &lt;http://purl.org/dc/terms/&gt;
                                                                                SELECT ?uri (SAMPLE(?l) AS ?label) (SAMPLE(?uriSubject) AS ?subjects) (SAMPLE(?uriCitations) AS ?citations)
                                                                                {
                                                                                ?uri rdfs:label ?l
                                                                                FILTER (?uri IN ( </xsl:text><xsl:for-each select="$otherResources"><xsl:text disable-output-escaping="yes">&lt;</xsl:text><xsl:value-of select="."/><xsl:text disable-output-escaping="yes">&gt;</xsl:text><xsl:if test="position() != last()">, </xsl:if></xsl:for-each><xsl:text disable-output-escaping="yes">)).
                                                                                FILTER ( langMatches(lang(?l), 'en')).
                                                                                OPTIONAL{{SELECT ?uri ( count(?s) as ?uriSubject ) { ?s dcterms:relation ?uri } GROUP BY ?uri }  }
                                                                                OPTIONAL{{SELECT ?uri ( count(?o) as ?uriCitations ) { ?uri lawd:hasCitation ?o OPTIONAL{?uri skos:closeMatch ?o.}} GROUP BY ?uri }}           
                                                                                }
                                                                                GROUP BY ?uri 
                                                                            </xsl:text>
                                                                        </textarea>
                                                                    </form>
                                                                    <div id="showRDF"></div>
                                                                </div>
                                                            </div>
                                                        </div>
                                                    </div>
                                                </xsl:if>
                                            </div>
                                       </div>  
                                    </div>
                                    <!-- Floating footnotes display -->
                                    <div id="footnoteDisplay" class="footnote">
                                        <div class="content"/>  
                                    </div>
                                    <!-- Modal email form-->
                                    <div data-template="app:contact-form" data-template-collection="bhse"/>
                                    <div data-template="app:contact-form-linked-data"/>
                                    <!-- Modal faq popup -->
                                    <div class="modal fade" id="selection" tabindex="-1" role="dialog" aria-labelledby="selectionLabel" aria-hidden="true">
                                        <div class="modal-dialog">
                                            <div class="modal-content">
                                                <div class="modal-header">
                                                    <button type="button" class="close" data-dismiss="modal">
                                                        <span aria-hidden="true"> x </span>
                                                        <span class="sr-only">Close</span>
                                                    </button>
                                                    <h2 class="modal-title" id="selectionLabel">Is this record complete?</h2>
                                                </div>
                                                <div class="modal-body">
                                                    <div>
                                                        <div id="recComplete" style="border:none; margin:0;padding:0;margin-top:-2em;">T</div>
                                                    </div>
                                                </div>
                                                <div class="modal-footer">
                                                    <a class="btn" href="../documentation/faq.html" aria-hidden="true">See all FAQs</a>
                                                    <button type="button" class="btn btn-default" data-dismiss="modal">Close</button>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                    <div class="modal fade" id="moreInfo" tabindex="-1" role="dialog" aria-labelledby="moreInfoLabel" aria-hidden="true">
                                        <div class="modal-dialog modal-lg">
                                            <div class="modal-content">
                                                <div class="modal-header">
                                                    <button type="button" class="close" data-dismiss="modal">
                                                        <span aria-hidden="true">x</span>
                                                        <span class="sr-only">Close</span>
                                                    </button>
                                                    <h2 class="modal-title" id="moreInfoLabel"/>
                                                </div>
                                                <div class="modal-body" id="modal-body">
                                                    <div id="moreInfo-box"/>
                                                    <br style="clear:both;"/>
                                                </div>
                                                <div class="modal-footer">
                                                    <button class="btn btn-default" data-dismiss="modal">Close</button>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                    <script type="text/javascript">
                                        $('html').click(function() {
                                        $('#footnoteDisplay').hide();
                                        $('#footnoteDisplay div.content').empty();
                                        })
                                        
                                        $('.footnote-ref a').click(function(e) {
                                        e.stopPropagation();
                                        e.preventDefault();
                                        var link = $(this);
                                        var href = $(this).attr('href');
                                        var content = $(href).html()
                                        $('#footnoteDisplay').css('display','block');
                                        $('#footnoteDisplay').css({'top':e.pageY-50,'left':e.pageX+25, 'position':'absolute'});
                                        $('#footnoteDisplay div.content').html( content );    
                                        });
                                        
                                    </script>
                                </div>  
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:call-template name="genericTEIPage">
                                    <xsl:with-param name="config" select="$config"></xsl:with-param>
                                    <xsl:with-param name="repository-title" select="$repository-title"/>
                                    <xsl:with-param name="collection-title" select="$collection-title"/>
                                </xsl:call-template>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:if test="doc-available(xs:anyURI(concat($staticSitePath,'/siteGenerator/components/footer.html')))">
                    <xsl:copy-of select="document(xs:anyURI(concat($staticSitePath,'/siteGenerator/components/footer.html')))"/>
                </xsl:if>
            </body>
            <xsl:if test="$template/child::*[1]/html:script">
                <xsl:copy-of select="$template/child::*[1]/html:script"/>
            </xsl:if>  
        </html>
    </xsl:template>
     
    <xsl:template name="toc">
        <xsl:param name="node"/>
        <xsl:choose>
            <xsl:when test="self::text()">
                <xsl:apply-templates/>
            </xsl:when>
            <xsl:when test="t:div">
                <xsl:call-template name="toc">
                    <xsl:with-param name="node" select="$node"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="t:div1">
                <xsl:call-template name="toc">
                    <xsl:with-param name="node" select="$node"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="t:div2">
                <span class="toc div2">
                    <xsl:call-template name="toc">
                        <xsl:with-param name="node" select="$node"/>
                    </xsl:call-template>
                </span>
            </xsl:when>
            <xsl:when test="t:div3">
                <span class="toc div3">
                    <xsl:call-template name="toc">
                        <xsl:with-param name="node" select="$node"/>
                    </xsl:call-template>
                </span>
            </xsl:when>
            <xsl:when test="t:div4">
                <span class="toc div4">
                    <xsl:call-template name="toc">
                        <xsl:with-param name="node" select="$node"/>
                    </xsl:call-template>
                </span>
            </xsl:when>
            <xsl:when test="t:head">
                <xsl:variable name="id">
                    <xsl:choose>
                        <xsl:when test="$node/@xml:id"><xsl:value-of select="$node/@xml:id"/></xsl:when>
                        <xsl:when test="$node/parent::*[1]/@n">
                            <xsl:value-of select="concat('Head-id.',string-join($node/ancestor::*[@n]/@n,'.'))"/>
                        </xsl:when>
                        <xsl:otherwise>'on-parent'</xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <a href="#{$id}" class="toc-item"><xsl:value-of select="string-join($node/descendant-or-self::text(),' ')"/></a><xsl:text> </xsl:text>
            </xsl:when>
        </xsl:choose>
    </xsl:template> 
    <xsl:template match="html:li">
        <xsl:choose>
            <xsl:when test="@data-template='app:shared-content'">
                <xsl:variable name="sharedContent" select="@data-template-path"/>
                <xsl:if test="doc-available(xs:anyURI(concat($staticSitePath,'/siteGenerator/components/',tokenize($sharedContent,'/')[last()])))">
                    <xsl:copy-of select="document(xs:anyURI(concat($staticSitePath,'/siteGenerator/components/',tokenize($sharedContent,'/')[last()])))"/>
                </xsl:if>
            </xsl:when>
            <xsl:otherwise>
                <xsl:element name="{name(.)}" namespace="http://www.w3.org/1999/xhtml">
                    <xsl:for-each select="@*">
                        <xsl:attribute name="{name(.)}"><xsl:value-of select="."/></xsl:attribute>
                    </xsl:for-each>
                    <xsl:apply-templates/>
                </xsl:element>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="html:span">
        <xsl:choose>
            <xsl:when test="@data-template='app:keyboard-select-menu'">
                <xsl:variable name="inputID" select="@data-template-input-id"/>
                <xsl:choose>
                    <xsl:when test="$config/descendant::*:keyboard-options/child::*">
                        <span class="keyboard-menu" xmlns="http://www.w3.org/1999/xhtml">
                            <button type="button" class="btn btn-default dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" title="Select Keyboard">
                                &#160;<span class="syriaca-icon syriaca-keyboard">&#160; </span><span class="caret"/>
                            </button>
                            <ul class="dropdown-menu">
                                <xsl:for-each select="$config/descendant::*:keyboard-options/*:option">
                                    <li xmlns="http://www.w3.org/1999/xhtml"><a href="#" class="keyboard-select" id="{@id}" data-keyboard-id="{$inputID}"><xsl:value-of select="."/></a></li>
                                </xsl:for-each>
                            </ul>
                        </span>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="generickeyboardSelect"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:element name="{name(.)}" namespace="http://www.w3.org/1999/xhtml">
                    <xsl:for-each select="@*">
                        <xsl:attribute name="{name(.)}"><xsl:value-of select="."/></xsl:attribute>
                    </xsl:for-each>
                    <xsl:apply-templates/>
                </xsl:element>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="html:link | html:script | html:a">
        <xsl:element name="{name()}">
            <!--<link rel="stylesheet" type="text/css" href="/resources/css/syr-icon-fonts.css"/>-->
            <xsl:copy-of select="@*[not(local-name() = 'href')]"/>
            <xsl:if test="@href">
                <xsl:variable name="href">
                    <xsl:choose>
                        <xsl:when test="starts-with(@href,'/')">
                            <xsl:value-of select="replace(@href,'/','/')"/>
                        </xsl:when>
                        <xsl:when test="not(starts-with(@href,'/'))">
                            <xsl:value-of select="concat('/',@href)"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="@href"/>
                        </xsl:otherwise>
                    </xsl:choose>    
                </xsl:variable>
                <xsl:attribute name="href" select="$href"/>
            </xsl:if>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="rdf:Description">
        <xsl:variable name="id" select="@rdf:about"/>
        <xsl:choose>
            <xsl:when test="child::*:hasTopConcept">
                <div class="main-content-block">
                    <div class="interior-content">
                        <h1>Browse Taxonomy</h1>
                        <ul class="list-unstyled indent">
                            <xsl:for-each select="*:hasTopConcept">
                                <xsl:sort select="@rdf:resource"/>
                                <xsl:variable name="id" select="@rdf:resource"/>
                                <xsl:for-each select="//rdf:Description[@rdf:about = $id]">
                                    <xsl:sort select="*:prefLabel[@xml:lang='en']"/>
                                    <li>
                                        <xsl:choose>
                                            <xsl:when test="*:narrower">
                                                <xsl:variable name="uID" select="tokenize(@rdf:about,'/')[last()]"/>
                                                <a href="#" type="button" class="expandTerms" data-toggle="collapse" data-target="#view{$uID}" style="display:inline-block;margin:.5em .75em;">
                                                    <span class="glyphicon glyphicon-plus-sign"></span>
                                                </a>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <a href="#" type="button" class="expandTerms" style="display:inline-block;margin:.5em 1.25em;">
                                                    &#160;
                                                </a>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                        <a href="{replace($id,$base-uri,concat($staticSitePath,'data'))}"><xsl:value-of select="*:prefLabel[@xml:lang='en']"/></a>
                                            <xsl:call-template name="narrowerTerms">
                                                <xsl:with-param name="node" select="."/>
                                            </xsl:call-template>
                                    </li>
                                </xsl:for-each>
                            </xsl:for-each>
                        </ul>
                    </div>
                </div>
            </xsl:when>
            <xsl:otherwise>
                <div class="main-content-block">
                    <div class="interior-content">
                        <div class="container otherFormats" xmlns="http://www.w3.org/1999/xhtml">
                            <a href="javascript:window.print();" type="button" class="btn btn-default btn-xs" id="teiBtn" data-toggle="tooltip" title="Click to send this page to the printer." >
                                <span class="glyphicon glyphicon-print" aria-hidden="true"></span>
                            </a><xsl:text>&#160;</xsl:text>
                            <!-- WS:NOTE needs work on the link. 
                            <a href="{concat($dataPath,'.rdf')}" class="btn btn-default btn-xs" id="teiBtn" data-toggle="tooltip" title="Click to view the RDF-XML data for this record." >
                                <span class="glyphicon glyphicon-download-alt" aria-hidden="true"></span> RDF/XML
                            </a><xsl:text>&#160;</xsl:text>
                            -->
                        </div>
                        <div class="row">
                            <div class="col-md-7 col-lg-8">
                                <div class="title">
                                    <h1><span id="title">
                                        <xsl:value-of select="*:prefLabel[@xml:lang='en']"/>
                                        <xsl:if test="*:prefLabel[@xml:lang='syr']">
                                            <xsl:text> - </xsl:text>
                                            <xsl:value-of select="*:prefLabel[@xml:lang='syr']"/>
                                        </xsl:if>
                                    </span></h1>
                                </div>
                                <div class="idno seriesStmt"
                                    style="margin:0; margin-top:.25em; margin-bottom: 1em; padding:1em; color: #999999;">
                                    <small><span class="uri"> <button type="button" class="btn btn-default btn-xs" 
                                        id="idnoBtn" data-clipboard-action="copy" data-clipboard-target="#syriaca-id">
                                        <span class="srp-label">URI</span></button> 
                                        <span id="syriaca-id"><xsl:value-of select="$id"/></span><script>
                                            var clipboard = new Clipboard('#idnoBtn');
                                            clipboard.on('success', function(e) {
                                            console.log(e);
                                            });
                                            
                                            clipboard.on('error', function(e) {
                                            console.log(e);
                                            });
                                        </script> 
                                    </span></small>
                                    <div>
                                        <xsl:if test="*:scopeNote[@xml:lang='en']">
                                            <h3>Scope Note</h3>
                                            <p class="indent"><xsl:apply-templates select="*:scopeNote[@xml:lang='en']"/></p>
                                        </xsl:if>
                                        <h3>Label(s)</h3>
                                        <xsl:for-each-group select="*:prefLabel" group-by="@xml:lang">
                                            <h4><xsl:value-of select="local:expand-lang(current-grouping-key(),'')"/></h4>
                                            <p class="indent"><xsl:for-each select="current-group()">
                                                <xsl:value-of select="."/><xsl:if test="position() != last()"><xsl:text>, </xsl:text></xsl:if>
                                            </xsl:for-each></p>
                                        </xsl:for-each-group>
                                        <xsl:if test="*:altLabel">
                                            <h3>Alternate Label(s)</h3>
                                            <xsl:for-each-group select="*:altLabel" group-by="@xml:lang">
                                                <h4><xsl:value-of select="local:expand-lang(current-grouping-key(),'')"/></h4>
                                                <p class="indent"><xsl:for-each select="current-group()">
                                                    <xsl:value-of select="."/><xsl:if test="position() != last()"><xsl:text>, </xsl:text></xsl:if>
                                                </xsl:for-each></p>
                                            </xsl:for-each-group>
                                        </xsl:if>
                                    </div> 
                                </div>
                            </div>
                            <div class="col-md-5 col-lg-4 right-menu">
                                <xsl:if test="*:broader">
                                    <h4>Broader</h4>
                                    <ul>
                                        <xsl:for-each select="*:broader">
                                            <xsl:variable name="broaderID" select="@rdf:resource"/>
                                            <xsl:for-each select="//rdf:Description[@rdf:about = $broaderID]">
                                                <li><a href="{concat(replace($broaderID,$base-uri,concat($staticSitePath,'data')),'.html')}"><xsl:value-of select="*:prefLabel[@xml:lang='en']"/></a></li>
                                            </xsl:for-each>
                                        </xsl:for-each>
                                    </ul>
                                </xsl:if>
                                <xsl:if test="*:narrower">
                                    <h4>Narrower</h4>
                                    <ul>
                                        <xsl:for-each select="*:narrower">
                                            <xsl:variable name="narrowerID" select="@rdf:resource"/>
                                            <xsl:for-each select="//rdf:Description[@rdf:about = $narrowerID]">
                                                <li><a href="{replace($narrowerID,$base-uri,concat($staticSitePath,'data'))}"><xsl:value-of select="*:prefLabel[@xml:lang='en']"/></a></li>
                                            </xsl:for-each>
                                        </xsl:for-each>
                                    </ul>
                                </xsl:if>
                                <xsl:if test="*:related">
                                    <h4>See also</h4>
                                    <ul>
                                        <xsl:for-each select="*:related">
                                            <xsl:variable name="relatedID" select="@rdf:resource"/>
                                            <xsl:for-each select="//rdf:Description[@rdf:about = $relatedID]">
                                                <li><a href="{replace($relatedID,$base-uri,concat($staticSitePath,'data'))}"><xsl:value-of select="*:prefLabel[@xml:lang='en']"/></a></li>
                                            </xsl:for-each>    
                                        </xsl:for-each>
                                    </ul>
                                </xsl:if>
                            </div>
                        </div>
                    </div>
                </div> 
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="narrowerTerms">
        <xsl:param name="node"/>
        <xsl:if test="$node/*:narrower">
            <xsl:variable name="uID" select="tokenize(@rdf:about,'/')[last()]"/>
            <ul class="collapse list-unstyled indent" id="view{$uID}">
                <xsl:for-each select="$node/*:narrower">
                    <xsl:sort select="@rdf:resource"/>
                    <xsl:variable name="termID" select="@rdf:resource"/>
                    <xsl:for-each select="//rdf:Description[@rdf:about = $termID]">
                        <li>
                            <xsl:choose>
                                <xsl:when test="*:narrower">
                                    <xsl:variable name="uID" select="tokenize(@rdf:about,'/')[last()]"/>
                                    <a href="#" type="button" class="expandTerms" data-toggle="collapse" data-target="#view{$uID}" style="display:inline-block;margin:.5em .75em;">
                                        <span class="glyphicon glyphicon-plus-sign"></span>
                                    </a>
                                </xsl:when>
                                <xsl:otherwise>
                                    <a href="#" type="button" class="expandTerms" style="display:inline-block;margin:.5em 1.25em;">
                                        &#160;
                                    </a>
                                </xsl:otherwise>
                            </xsl:choose>
                            <a href="{replace($termID,$base-uri,concat($staticSitePath,'data'))}"><xsl:value-of select="*:prefLabel[@xml:lang='en']"/></a>
                            <xsl:call-template name="narrowerTerms">
                                <xsl:with-param name="node" select="."/>
                            </xsl:call-template>
                        </li>
                    </xsl:for-each>
                </xsl:for-each>
            </ul>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="otherDataFormats">
        <xsl:param name="node"/>
        <xsl:param name="formats"/>
        <xsl:param name="idno"/>
        <xsl:variable name="shelfMark" select="$node/descendant::t:fileDesc/t:sourceDesc/t:msDesc/t:msIdentifier/t:altIdentifier/t:idno[@type='BL-Shelfmark']"/>
        <xsl:variable name="url" select="$node/descendant::t:fileDesc/t:sourceDesc/t:msDesc/t:msIdentifier/t:idno[@type='URI']"/>
        <xsl:variable name="teiRec" select="document-uri(root($node))"/>
        <xsl:variable name="dataPath" select="substring-before(concat($staticSitePath,'/data/',replace($resource-path,$dataPath,'')),'.xml')"></xsl:variable>
        <xsl:if test="$formats != ''">
            <div class="container otherFormats" xmlns="http://www.w3.org/1999/xhtml">
                <xsl:for-each select="tokenize($formats,',')">
                    <xsl:choose>
                        <!--                         
                    else if($f = 'rdf') then
                        (<a href="{concat(replace($id,$config:base-uri,$config:nav-base),'.rdf')}" data-toggle="tooltip" title="Click to view the RDF-XML data for this record." >
                            <img src="{$config:nav-base}/resources/images/sw-rdf-blue.png" height="26px"/>
                        </a>, '&#160;')
                        -->
                        <!--
                        <xsl:when test=". = 'geojson'">
                            <a href="{concat($dataPath,'.geojson')}" class="btn btn-default btn-xs" id="geojsonBtn" data-toggle="tooltip" title="Click to view the GeoJSON data for this record." >
                                <span class="glyphicon glyphicon-download-alt" aria-hidden="true"></span> GeoJSON
                            </a><xsl:text>&#160;</xsl:text>
                        </xsl:when>
                        <xsl:when test=". = 'json'">
                            <a href="{concat($dataPath,'.json')}" class="btn btn-default btn-xs" id="jsonBtn" data-toggle="tooltip" title="Click to view the GeoJSON data for this record." >
                                <span class="glyphicon glyphicon-download-alt" aria-hidden="true"></span> JSON-LD
                            </a><xsl:text>&#160;</xsl:text> 
                        </xsl:when>
                        <xsl:when test=". = 'kml'">
                            <xsl:if test="$node/descendant::t:location/t:geo">
                                <a href="{concat($dataPath,'.kml')}" class="btn btn-default btn-xs" id="kmmlBtn" data-toggle="tooltip" title="Click to view the KML data for this record." >
                                    <span class="glyphicon glyphicon-download-alt" aria-hidden="true"></span> KML
                                </a><xsl:text>&#160;</xsl:text>
                            </xsl:if>
                        </xsl:when>
                        -->
                        <xsl:when test=". = 'uri'">
                            <a class="btn btn-default btn-xs" id="copyBtn" 
                                data-toggle="tooltip" 
                                title="Copy URI to clipboard: {$idno}"
                                data-clipboard-action="copy" data-clipboard-text="{string($idno)}">
                                <span class="glyphicon glyphicon-copy" aria-hidden="true"></span> URI</a>&#160;
                            <script><![CDATA[new Clipboard('#copyBtn');]]></script>
                        </xsl:when>
                        <xsl:when test=". = 'print'">
                            <a href="javascript:window.print();" type="button" class="btn btn-default btn-xs" id="printBtn" data-toggle="tooltip" title="Click to send this page to the printer." >
                                <span class="glyphicon glyphicon-print" aria-hidden="true"></span>&#160;
                            </a><xsl:text>&#160;</xsl:text>
                        </xsl:when>
                        <!--
                        <xsl:when test=". = 'rdf'">
                            <a href="{concat($dataPath,'.rdf')}" class="btn btn-default btn-xs" id="rdfBtn" data-toggle="tooltip" title="Click to view the RDF-XML data for this record." >
                                <span class="glyphicon glyphicon-download-alt" aria-hidden="true"></span> RDF/XML
                            </a><xsl:text>&#160;</xsl:text>
                        </xsl:when>
                        -->
                        <xsl:when test=". = 'tei'">
                            <a href="{concat(tokenize($idno,'/')[last()],'.xml')}" class="btn btn-default btn-xs" id="teiBtn" data-toggle="tooltip" title="Click to view the TEI XML data for this record." >
                                <img src="/resources/images/TEI_Logo.png" height="18px"/>
                            </a><xsl:text>&#160;</xsl:text>
                        </xsl:when>
                        <xsl:when test=". = 'ghCode'">
                            <a href="{concat('https://github.com/srophe/britishLibrary-data/blob/main/data/tei/',tokenize($idno,'/')[last()],'.xml')}" target="_blank" class="btn btn-default btn-xs" id="openBtn" data-toggle="tooltip" title="Click to view the TEI XML data for this record.">
                                <img src="/resources/images/github-mark.png" height="18px"/>
                            </a><xsl:text>&#160;</xsl:text>
                        </xsl:when>
                        <xsl:when test=". = 'ghIssue'">
                            <a href="{concat('https://github.com/srophe/britishLibrary-data/issues/new?assignees=&amp;labels=community-submitted&amp;title=',$shelfMark,':',$url)}" target="_blank" id="issueBtn" data-toggle="tooltip" class="btn btn-default btn-xs" title="Click to file a data issue on GitHub (requires login).">
                                <span class="glyphicon glyphicon-record" aria-hidden="true"></span> Open
                            </a><xsl:text>&#160;</xsl:text>
                        </xsl:when>
                        <xsl:when test=". = 'email'">
                            <a href="mailto:bl.syriac.uk@gmail.com?subject=Shelf mark:{$shelfMark} Record URI: {$url}" type="button" class="btn btn-default btn-xs" data-toggle="tooltip" title="Click to report a correction via e-mail." >
                                <span class="glyphicon glyphicon-envelope" aria-hidden="true"></span> Corrections
                            </a><xsl:text>&#160;</xsl:text>
                        </xsl:when>
                        <!--
                        <xsl:when test=". = 'text'">
                            <a href="{concat($dataPath,'.txt')}" class="btn btn-default btn-xs" id="txtBtn" data-toggle="tooltip" title="Click to view the plain text data for this record." >
                                <span class="glyphicon glyphicon-download-alt" aria-hidden="true"></span> Text
                            </a><xsl:text>&#160;</xsl:text>
                        </xsl:when>
                        -->
                        <xsl:when test=". = 'citations'">
                            <xsl:variable name="zoteroGrp" select="$config/descendant::*:zotero/@group"/>
                            <xsl:if test="$zoteroGrp != ''">
                                (<a href="{concat('https://api.zotero.org/groups/',$zoteroGrp,'/items/',tokenize($idno,'/')[last()])}" class="btn btn-default btn-xs" id="citationsBtn" data-toggle="tooltip" title="Click for additional Citation Styles." >
                                    <span class="glyphicon glyphicon-th-list" aria-hidden="true"></span> Cite
                                </a><xsl:text>&#160;</xsl:text>
                            </xsl:if>
                        </xsl:when>
                    </xsl:choose>
                </xsl:for-each>
            </div>
        </xsl:if>
    </xsl:template>
    <xsl:template name="genericTEIPage">
        <xsl:param name="config"/>
        <xsl:param name="repository-title"/>
        <xsl:param name="collection-title"/>
        <xsl:param name="idno"/>
        <div xmlns="http://www.w3.org/1999/xhtml">
            <div class="main-content-block">
                <div class="interior-content">
                    <xsl:call-template name="otherDataFormats">
                        <xsl:with-param name="node" select="t:TEI"/>
                        <xsl:with-param name="idno" select="$idno"/>
<!--                        <xsl:with-param name="formats" select="'print,tei,rdf,text'"/>-->
                        <xsl:with-param name="formats" select="'print,tei'"/>
                    </xsl:call-template>
                    <div class="row">
                        <div class="col-md-7 col-lg-8">
                            <xsl:apply-templates select="t:TEI"/>
                            <!--
                            <xsl:apply-templates select="t:TEI">
                                <xsl:with-param name="config" select="$config"/>
                                <xsl:with-param name="repository-title" select="$repository-title"/>
                                <xsl:with-param name="collection-title" select="$collection-title"/>
                            </xsl:apply-templates>
                            -->
                        </div>
                        <div class="col-md-5 col-lg-4 right-menu">
                            <!-- Make dynamic -->
                            <!-- WS:ToDo Maps -->
                            <xsl:choose>
                                <xsl:when test="descendant::t:geo">
                                    <xsl:call-template name="leafletMap">
                                        <xsl:with-param name="nodes" select="/t:TEI"/>
                                    </xsl:call-template>
                                </xsl:when>
                                <!-- Maps for related places -->
                                
                            </xsl:choose>
                            <br/>
                            <!-- WS:Note need to wait for RDF, not sure how to resolve paths to files from URI, they are not dependable paths (NHSL for example) -->
                            <!-- 
                            <xsl:choose>
                                <xsl:when test="descendant::t:relation">
                                    <xsl:call-template name="leafletMap">
                                        <xsl:with-param name="nodes" select="/t:TEI"/>
                                    </xsl:call-template>
                                </xsl:when>
                            </xsl:choose>
                            -->
                            <!-- Relationsips listed in the TEI record  display: list/sentence -->
                            <!-- WS:ToDo Relationships -->
<!--                            <div data-template="app:internal-relationships" data-template-label="Internal Relationships"/>-->
                            <!-- Relationships referencing this TEI record -->
                            <!--                    <div data-template="app:external-relationships" data-template-label="External Relationships"/>    -->
                        </div>
                    </div>
                </div>
            </div>
            <!-- Modal email form-->
            <!-- WS:ToDo Contact form?  -->
<!--            <div data-template="app:contact-form" data-template-collection="places"/>-->
            <xsl:if test="t:TEI/descendant::t:geo">
                <script type="text/javascript" src="/resources/leaflet/leaflet.js"/>
                <script type="text/javascript" src="/resources/js/maps.js"/>                
            </xsl:if>
        </div>
    </xsl:template>
    <xsl:template name="genericHeader">
        <head xmlns="http://www.w3.org/1999/xhtml">
            <title>Generic Header: <xsl:value-of select="$resource-title"/></title>
            <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
            <meta name="DC.type" property="dc.type" content="Text"/>
            <meta name="DC.isPartOf" property="dc.ispartof" content="{$config/html:title[1]}"/>
            <link rel="shortcut icon" href="/resources/images/fav-icons/syriaca-favicon.ico"/>
            <!-- Bootstrap 3 -->
            <link rel="stylesheet" type="text/css" href="/resources/bootstrap/css/bootstrap.min.css"/>
            <link rel="stylesheet" type="text/css" href="/resources/css/sm-core-css.css"/>
            <!-- Srophe styles -->
            <link rel="stylesheet" type="text/css" href="/resources/css/syr-icon-fonts.css"/>
            <link rel="stylesheet" type="text/css" href="/resources/css/style.css"/>
            <link rel="stylesheet" type="text/css" href="/resources/css/syriaca.css"/>
            <link rel="stylesheet" type="text/css" href="/resources/css/slider.css"/>
            <link rel="stylesheet" type="text/css" href="/resources/css/lightslider.css"/>
            <link rel="stylesheet" type="text/css" media="print" href="/resources/css/print.css"/>
            <!-- Leaflet -->
            <link rel="stylesheet" href="/resources/leaflet/leaflet.css"/>
            <link rel="stylesheet" href="/resources/leaflet/leaflet.awesome-markers.css"/>
            <script defer="defer" data-domain="syriaca.org" src="https://plausible.io/js/plausible.js"/>
            <!-- JQuery -->
            <link href="/resources/jquery-ui/jquery-ui.min.css" rel="stylesheet"/>
            <script type="text/javascript" src="/resources/js/jquery.min.js"/>
            <script type="text/javascript" src="/resources/jquery-ui/jquery-ui.min.js"/>
            <script type="text/javascript" src="/resources/js/jquery.smartmenus.min.js"/>
            <script type="text/javascript" src="/resources/js/clipboard.min.js"/>
            <!-- Bootstrap -->
            <script type="text/javascript" src="/resources/bootstrap/js/bootstrap.min.js"/>
            <!-- ReCaptcha -->
            <script src="https://www.google.com/recaptcha/api.js" type="text/javascript" async="async" defer="defer"/>
            <!-- keyboard widget css & script -->
            <link href="/resources/keyboard/css/keyboard.min.css" rel="stylesheet"/>
            <link href="/resources/keyboard/css/keyboard-previewkeyset.min.css" rel="stylesheet"/>
            <link href="/resources/keyboard/syr/syr.css" rel="stylesheet"/>
            <script type="text/javascript" src="/resources/keyboard/syr/jquery.keyboard.js"/>
            <script type="text/javascript" src="/resources/keyboard/js/jquery.keyboard.extension-mobile.min.js"/>
            <script type="text/javascript" src="/resources/keyboard/js/jquery.keyboard.extension-navigation.min.js"/>
            <script type="text/javascript" src="/resources/keyboard/syr/jquery.keyboard.extension-autocomplete.js"/>
            <script type="text/javascript" src="/resources/keyboard/syr/keyboardSupport.js"/>
            <script type="text/javascript" src="/resources/keyboard/syr/syr.js"/>
            <script type="text/javascript" src="/resources/keyboard/layouts/ms-Greek.min.js"/>
            <script type="text/javascript" src="/resources/keyboard/layouts/ms-Russian.min.js"/>
            <script type="text/javascript" src="/resources/keyboard/layouts/ms-Arabic.min.js"/>
            <script type="text/javascript" src="/resources/keyboard/layouts/ms-Hebrew.min.js"/>
            <script type="text/javascript">
                <xsl:text disable-output-escaping="yes">
                    <![CDATA[
                $(document).ready(function () {
                $('[data-toggle="tooltip"]').tooltip({ container: 'body' })
                
                $('.keyboard').keyboard({
                openOn: null,
                stayOpen: false,
                alwaysOpen: false,
                autoAccept: true,
                usePreview: false,
                initialFocus: true,
                rtl : true,
                layout: 'syriac-phonetic',
                hidden: function(event, keyboard, el){
                //  keyboard.destroy();
                }
                });
                
                $('.keyboard-select').click(function () {
                var keyboardID = '#' + $(this).data("keyboard-id")
                var kb = $(keyboardID).getkeyboard();
                //var kb = $('#searchField').getkeyboard();
                // change layout based on link ID
                kb.options.layout = this.id
                // open keyboard if layout is different, or time from it last closing is &gt; 200 ms
                if (kb.last.layout !== kb.options.layout || (new Date().getTime() - kb.last.eventTime) < 200) {
                kb.reveal();
                }
                });
                //Change fonts
                $('.swap-font').on('click', function(){
                var selectedFont = $(this).data("font-id")
                $('.selectableFont').not('.syr').css('font-family', selectedFont);
                $("*:lang(syr)").css('font-family', selectedFont)
                });
                
                })]]>
                </xsl:text>
            </script>
        </head>
    </xsl:template>
    <xsl:template name="genericNav">
        <nav xmlns="http://www.w3.org/1999/xhtml" class="navbar navbar-default navbar-fixed-top" role="navigation">
            <div class="navbar-header">
                <button type="button" class="navbar-toggle" data-toggle="collapse" data-target="#navbar-collapse-1">
                    <span class="sr-only">Toggle navigation</span>
                    <span class="icon-bar"/>
                    <span class="icon-bar"/>
                    <span class="icon-bar"/>
                </button>
                <a class="navbar-brand banner-container" href="index.html"> 
                    <span class="syriaca-icon syriaca-syriaca banner-icon">
                        <span class="path1"/><span class="path2"/><span class="path3"/><span class="path4"/>
                    </span>
                    <span class="banner-text"><xsl:value-of select="$config/html:title[1]"/></span>
                </a>
            </div>
            <div class="navbar-collapse collapse pull-right" id="navbar-collapse-1">
                <ul class="nav navbar-nav">
                    <xsl:call-template name="syriacaSharedLinks"/>
                    <li class="dropdown">
                        <a href="#" class="dropdown-toggle lonely-caret" data-toggle="dropdown"> 
                            <span class="mobile-submenu">About</span>  <b class="caret"/>
                        </a>
                        <ul class="dropdown-menu pull-right">
                            <li>
                                <a href="/about-syriac.html">What is Syriac?</a>
                            </li>
                            <li role="presentation" class="divider"/>
                            <li>
                                <a href="/about-srophe.html">Project Overview</a>
                            </li>
                            <li role="presentation" class="divider"/>
                            <li>
                                <a href="/project-team.html">Project Team</a>
                            </li>
                            <li role="presentation" class="divider"/>
                            <li>
                                <a href="/project-partners.html">Project Partners</a>
                            </li>
                            <li role="presentation" class="divider"/>
                            <li>
                                <a href="/geo/index.html">
                                    <span class="icon-text">Gazetteer</span>
                                </a>
                            </li>
                            <li role="presentation" class="divider"/>
                            <li>
                                <a href="http://vu.edu/syriac">Support Our Work</a>
                            </li>
                            <li role="presentation" class="divider"/>
                            <li>
                                <a href="/contact-us.html">Contact Us</a>
                            </li>
                            <li role="presentation" class="divider"/>
                            <li>
                                <a href="/documentation/index.html">
                                    <span class="syriaca-icon syriaca-book icon-nav" style="color:red;"/>
                                    <span class="icon-text">Documentation</span>
                                </a>
                            </li>
                        </ul>
                    </li>
                    <li>
                        <a href="search.html" class="nav-text">Advanced Search</a>
                    </li>
                    <li>
                        <div id="search-wrapper">
                            <form class="navbar-form navbar-right search-box" role="search" action="search.html" method="get">
                                <div class="form-group">
                                    <input type="text" class="form-control keyboard" placeholder="search" name="keyword" id="keywordNav"/>
                                    <xsl:call-template name="keyboard-select-menu">
                                        <xsl:with-param name="inputID" select="'keywordNav'"></xsl:with-param>
                                    </xsl:call-template>
                                    <button class="btn btn-default search-btn" id="searchbtn" type="submit" title="Search">
                                        <span class="glyphicon glyphicon-search"/>
                                    </button>                                    
                                </div>
                            </form>
                        </div>
                    </li>
                    <li>
                        <div class="btn-nav">
                            <button class="btn btn-default navbar-btn" id="font" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" title="Select Font">
                                <span class="glyphicon glyphicon-font"/>
                            </button>  
                            <ul class="dropdown-menu dropdown-menu-right" id="swap-font">
                                <li>
                                    <a href="#" class="swap-font" id="DefaultSelect" data-font-id="EstrangeloEdessa">Default</a>
                                </li>
                                <li>
                                    <a href="#" class="swap-font" id="EstrangeloEdessaSelect" data-font-id="EstrangeloEdessa">Estrangelo Edessa</a>
                                </li>
                                <li>
                                    <a href="#" class="swap-font" id="EastSyriacAdiabeneSelect" data-font-id="EastSyriacAdiabene">East Syriac Adiabene</a>
                                </li>
                                <li>
                                    <a href="#" class="swap-font" id="SertoBatnanSelect" data-font-id="SertoBatnan">Serto Batnan</a>
                                </li>
                                <li>
                                    <a href="/documentation/wiki.html?wiki-page=/How-to-view-Syriac-script&amp;wiki-uri=https://github.com/srophe/syriaca-data/wiki">Help <span class="glyphicon glyphicon-question-sign"/>
                                    </a>
                                </li>
                            </ul>
                        </div>
                    </li>
                </ul>
            </div>
        </nav>
    </xsl:template>
    <xsl:template name="generickeyboardSelect">
        <span xmlns="http://www.w3.org/1999/xhtml" class="keyboard-menu">
            <button type="button" class="btn btn-default dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" title="Select Keyboard">
                &#160;<span class="syriaca-icon syriaca-keyboard">&#160; </span><span class="caret"/>
            </button>
            <ul class="dropdown-menu">
                <li><a href="#" class="keyboard-select" id="syriac-phonetic" data-keyboard-id="keywordNav">Syriac Phonetic</a></li>
                <li><a href="#" class="keyboard-select" id="syriac-standard" data-keyboard-id="keywordNav">Syriac Standard</a></li>
                <li> <a href="#" class="keyboard-select" id="ms-Arabic (101)" data-keyboard-id="keywordNav">Arabic Mod. Standard</a></li>
                <li><a href="#" class="keyboard-select" id="ms-Hebrew" data-keyboard-id="keywordNav">Hebrew</a></li>
                <li><a href="#" class="keyboard-select" id="ms-Russian" data-keyboard-id="keywordNav">Russian</a></li>
                <li><a href="#" class="keyboard-select" id="ms-Greek" data-keyboard-id="keywordNav">Greek</a></li>
                <li><a href="#" class="keyboard-select" id="qwerty" data-keyboard-id="keywordNav">English QWERTY</a></li>
            </ul>
        </span>
    </xsl:template>
    <xsl:template name="keyboard-select-menu">
        <xsl:param name="inputID"/>
        <xsl:if test="$config/descendant::*:keyboard-options/child::*">
            <span xmlns="http://www.w3.org/1999/xhtml" class="keyboard-menu">
                <button type="button" class="btn btn-default dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" title="Select Keyboard">
                    &#160;<span class="syriaca-icon syriaca-keyboard">&#160; </span><span class="caret"/>
                </button>
                <ul class="dropdown-menu">
                    <xsl:for-each select="$config/descendant::*:keyboard-options/*:option">
                        <li xmlns="http://www.w3.org/1999/xhtml">
                            <a href="#" class="keyboard-select" id="{@id}" data-keyboard-id="{$inputID}"><xsl:value-of select="."/></a>
                        </li>
                    </xsl:for-each>
                </ul>
            </span>
        </xsl:if>
    </xsl:template>
    <xsl:template name="syriacaSharedLinks">
        <xsl:if test="doc-available(concat($applicationPath,'/','templates/shared-links.html'))">
            <xsl:copy-of select="doc(concat($applicationPath,'/','templates/shared-links.html'))"/>
        </xsl:if>
    </xsl:template>
    
</xsl:stylesheet>