<xsl:stylesheet  
    xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:t="http://www.tei-c.org/ns/1.0"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:x="http://www.w3.org/1999/xhtml" 
    xmlns:srophe="https://srophe.app" 
    xmlns:saxon="http://saxon.sf.net/" 
    xmlns:xs="http://www.w3.org/2001/XMLSchema" 
    xmlns:local="http://syriaca.org/ns" 
    exclude-result-prefixes="xs t x saxon local" version="3.0">
    
    <!-- ================================================================== 
      json.xsl
       
       Generate openSearch index data as json
       Uses /siteGenerator/components/repo-config.xml to build fields. If fields are not specified in repo-config.xml it will not be transformed. 
      
       code by: 
        + Winona Salesky (wsalesky@gmail.com)
          
       funding provided by:
        + National Endowment for the Humanities (http://www.neh.gov). Any 
          views, findings, conclusions, or recommendations expressed in 
          this code do not necessarily reflect those of the National 
          Endowment for the Humanities.
       
       ================================================================== -->
    
    <xsl:output method="text" encoding="utf-8"/>
    
    <xsl:param name="applicationPath" select="'/Users/wsalesky/syriaca/SyriacCorpus/syriac-corpus-app'"/>
    <xsl:param name="staticSitePath" select="'/Users/wsalesky/syriaca/SyriacCorpus/syriac-corpus-app'"/>
    <xsl:param name="dataPath" select="'/Users/wsalesky/syriaca/SyriacCorpus/syriac-corpus'"/>
    <xsl:param name="configPath" select="concat($staticSitePath, '/siteGenerator/components/repo-config.xml')"/>
    <xsl:variable name="config">
        <xsl:if test="doc-available(xs:anyURI($configPath))">
            <xsl:sequence select="document(xs:anyURI($configPath))"/>
        </xsl:if>
    </xsl:variable>
    <xsl:variable name="resource-path" select="substring-after(document-uri(.),':')"/>
    <xsl:function name="local:sortStringEn">
        <xsl:param name="string"/>
        <xsl:variable name="title" select="normalize-space($string)"/>
        <xsl:value-of select="replace($title,'^[tT]he\s+|^\s+|^[‘|ʻ|ʿ|ʾ]|^[tT]he\s+[^\p{L}]+|^[dD]e\s+|^[dD]e-|^[oO]n\s+[aA]\s+|^[oO]n\s+|^[aA]l-|^[aA]n\s|^[aA]\s+|^\d*\W|^[^\p{L}]','')"/>
    </xsl:function>
    <xsl:function name="local:sortStringAr">
        <xsl:param name="string"/>
        <xsl:value-of select="replace(
            replace(
            replace(
            replace(
            replace($string[1],'^\s+',''), 
            '[ً-ٖ]',''), 
            '(^|\s)(ال|أل|ٱل)',''), 
            'آ|إ|أ|ٱ','ا'), 
            '^(ابن|إبن|بن)','')"/>
    </xsl:function>
    <xsl:function name="local:buildDate">
        <xsl:param name="element" as="node()"/>
        <xsl:if test="$element/@when or $element/@notBefore or $element/@notAfter or $element/@from or $element/@to">
            <xsl:choose>
                <!-- Formats to and from dates -->
                <xsl:when test="$element/@from">
                    <xsl:choose>
                        <xsl:when test="$element/@to">
                            <xsl:value-of select="local:trim-date($element/@from)"/>-<xsl:value-of select="local:trim-date($element/@to)"/>
                        </xsl:when>
                        <xsl:otherwise>from <xsl:value-of select="local:trim-date($element/@from)"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:when test="$element/@to">to <xsl:value-of select="local:trim-date($element/@to)"/>
                </xsl:when>
            </xsl:choose>
            <!-- Formats notBefore and notAfter dates -->
            <xsl:if test="$element/@notBefore">
                <!-- Adds comma if there are other dates -->
                <xsl:if test="$element/@to or $element/@from">, </xsl:if>not before <xsl:value-of select="local:trim-date($element/@notBefore)"/>
            </xsl:if>
            <xsl:if test="$element/@notAfter">
                <!-- Adds comma if there are other dates -->
                <xsl:if test="$element/@to or $element/@from or $element/@notBefore">, </xsl:if>not after <xsl:value-of select="local:trim-date($element/@notAfter)"/>
            </xsl:if>
            <!-- Formats when, single date -->
            <xsl:if test="$element/@when">
                <!-- Adds comma if there are other dates -->
                <xsl:if test="$element/@to or $element/@from or $element/@notBefore or $element/@notAfter">, </xsl:if>
                <xsl:value-of select="local:trim-date($element/@when)"/>
            </xsl:if>
        </xsl:if>
    </xsl:function>
    
    <!-- Date function to remove leading 0s -->
    <xsl:function name="local:trim-date">
        <xsl:param name="date"/>
        <xsl:choose>
            <!-- NOTE: This can easily be changed to display BCE instead -->
            <!-- removes leading 0 but leaves -  -->
            <xsl:when test="starts-with($date,'-0')">
                <xsl:value-of select="concat(substring($date,3),' BCE')"/>
            </xsl:when>
            <!-- removes leading 0 -->
            <xsl:when test="starts-with($date,'0')">
                <xsl:value-of select="local:trim-date(substring($date,2))"/>
            </xsl:when>
            <!-- passes value through without changing it -->
            <xsl:otherwise>
                <xsl:value-of select="$date"/>
            </xsl:otherwise>
        </xsl:choose>
        <!--  <xsl:value-of select="string(number($date))"/>-->
    </xsl:function>
    
    <xsl:template match="/">
        <xsl:variable name="doc">
            <xsl:sequence select="."/>
        </xsl:variable>
        <xsl:variable name="id" select="replace($doc/descendant::tei:publicationStmt/tei:idno[@type='URI'][1],'/tei','')"/>
        <xsl:variable name="xml">
            <map xmlns="http://www.w3.org/2005/xpath-functions">
                <xsl:for-each select="$config/descendant::*:searchFields/*:fields">
                    <xsl:choose>
                        <xsl:when test="@function != ''">
                            <xsl:variable name="function" select="@function"/>
                                <xsl:apply-templates select=".[@function = $function]">
                                    <xsl:with-param select="$doc" name="doc"/>
                                    <xsl:with-param select="$id" name="id"/>
                                </xsl:apply-templates>
                        </xsl:when>
                        <xsl:when test="@xpath != ''">
                            <string key="{.}" xmlns="http://www.w3.org/2005/xpath-functions">Test xpath function</string> 
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:message>Incorrect field formatting</xsl:message>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>
            </map>
        </xsl:variable>
        <xsl:variable name="filename" select="replace(tokenize($resource-path,'/')[last()],'.xml','.json')"/>
        <xsl:message>Path: <xsl:value-of select="concat($staticSitePath,'/data/json/',$filename)"/></xsl:message>
        <xsl:message>Config: <xsl:value-of select="$configPath"/></xsl:message>
        <xsl:result-document href="{concat($staticSitePath,'/data/json/',$filename)}">
            <xsl:value-of select="xml-to-json($xml, map { 'indent' : true() })"/>
        </xsl:result-document>
    </xsl:template>
    
    <!-- Named functions, should match search fields in repo-config.xml -->
    <xsl:template match="*:fields[@function = 'fullText']">
        <xsl:param name="doc"/>
        <xsl:variable name="field">
            <xsl:value-of select="normalize-space(string-join($doc/descendant::tei:text/descendant::text(),' '))"/>
        </xsl:variable>
        <xsl:if test="$field != ''">
            <string key="{.}" xmlns="http://www.w3.org/2005/xpath-functions">
                <xsl:value-of select="$field"/>
            </string>    
        </xsl:if> 
    </xsl:template>
    
    <xsl:template match="*:fields[@function = 'title']">
        <xsl:param name="doc"/>
        <array key="{.}" xmlns="http://www.w3.org/2005/xpath-functions">     
            <xsl:for-each select="$doc/descendant::tei:titleStmt/tei:title">
                <string xmlns="http://www.w3.org/2005/xpath-functions">
                    <xsl:value-of select="string-join(.,' ')"/>
                </string>
            </xsl:for-each>
        </array>
    </xsl:template>
    
    <xsl:template match="*:fields[@function = 'displayTitleEnglish']">
        <xsl:param name="doc"/>
        <xsl:variable name="field">
            <xsl:for-each select="$doc/descendant::tei:titleStmt/tei:title">
                <string xmlns="http://www.w3.org/2005/xpath-functions">
                    <xsl:value-of select="local:sortStringEn(string-join(.,' '))"/>
                </string>
            </xsl:for-each>
        </xsl:variable>
        <xsl:if test="$field != ''">
            <string key="{.}" xmlns="http://www.w3.org/2005/xpath-functions">
                <xsl:value-of select="normalize-space($field)"/>
            </string>    
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="*:fields[@function = 'idno']">
        <xsl:param name="doc"/>
        <xsl:variable name="field">
        <xsl:value-of select="replace($doc/descendant::tei:publicationStmt/tei:idno[@type='URI'][1],'/tei','')"/>
        </xsl:variable>
        <xsl:if test="$field != ''">
            <string key="{.}" xmlns="http://www.w3.org/2005/xpath-functions">
                <xsl:value-of select="$field"/>
            </string>    
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="*:fields[@function = 'author']">
        <xsl:param name="doc"/>
        <xsl:if test="$doc/descendant::tei:author">
            <array key="{.}" xmlns="http://www.w3.org/2005/xpath-functions">      
                <xsl:for-each-group select="$doc/descendant::tei:author" group-by=".">
                    <xsl:variable name="lastNameFirst">
                        <xsl:choose>
                            <xsl:when test="tei:surname">
                                <xsl:value-of select="concat(tei:surname, ' ', tei:forename)"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="normalize-space(string-join(descendant-or-self::text(),' '))"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <string xmlns="http://www.w3.org/2005/xpath-functions">
                        <xsl:choose>
                            <xsl:when test="starts-with(@xml:lang,'sy')">
                                &lt;span lang="syr" dir="rtl"&gt;<xsl:value-of select="$lastNameFirst"/>&lt;/span&gt;
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="$lastNameFirst"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </string>
                </xsl:for-each-group>
            </array>
        </xsl:if>
    </xsl:template>
    <xsl:template match="*:fields[@function = 'sectionNo']">
        <xsl:param name="doc"/>
        <xsl:param name="id"/>
        <xsl:if test="$doc/descendant::tei:div[@type='section'][@n != ''] | $doc/descendant::tei:div2/tei:head"> 
            <array key="{.}" xmlns="http://www.w3.org/2005/xpath-functions"> 
                <xsl:for-each select="$doc/descendant::tei:div[@type='section'][@n != ''] | $doc/descendant::tei:div2/tei:head">
                    <string xmlns="http://www.w3.org/2005/xpath-functions">
                        <xsl:choose>
                            <xsl:when test="@n"><xsl:value-of select="@n"/></xsl:when>
                            <xsl:otherwise><xsl:value-of select="."/></xsl:otherwise>
                        </xsl:choose>
                    </string>
                </xsl:for-each>
            </array>
        </xsl:if>
    </xsl:template>
    <xsl:template match="*:fields[@function = 'syriacaURI']">
        <xsl:param name="doc"/>
        <xsl:param name="id"/>
        <xsl:if test="$doc/descendant::tei:titleStmt/tei:title[@ref != '']"> 
            <xsl:if test="$doc/descendant::tei:titleStmt/tei:title[@ref != '']"> 
                <string key="{.}" xmlns="http://www.w3.org/2005/xpath-functions">
                    <xsl:value-of select="$doc/descendant::tei:titleStmt/tei:title/@ref"/>
                </string>
            </xsl:if>
        </xsl:if>
    </xsl:template>
    <xsl:template match="*:fields[@function = 'textID']">
        <xsl:param name="doc"/>
        <xsl:param name="id"/>
        <xsl:if test="$doc/descendant::tei:div1[@n != '']"> 
            <array key="{.}" xmlns="http://www.w3.org/2005/xpath-functions"> 
                <xsl:for-each-group select="$doc/descendant::tei:div1[@n != '']" group-by="@n">
                    <string xmlns="http://www.w3.org/2005/xpath-functions">
                        <xsl:apply-templates select="current-grouping-key()"/>
                    </string>
                </xsl:for-each-group>
            </array>
        </xsl:if>
    </xsl:template>
    <xsl:template match="*:fields[@function = 'dateStart']">
        <xsl:param name="doc"/>
        <xsl:param name="id"/>
        <xsl:if test="$doc/descendant::tei:origDate"> 
            <string key="{.}" xmlns="http://www.w3.org/2005/xpath-functions">
            <xsl:choose>
                <xsl:when test="$doc/descendant::tei:origDate/@from"><xsl:value-of select="local:trim-date($doc/descendant::tei:origDate/@from)"/></xsl:when>
                <xsl:when test="$doc/descendant::tei:origDate/@when"><xsl:value-of select="local:trim-date($doc/descendant::tei:origDate/@when)"/></xsl:when>
                <xsl:otherwise><xsl:value-of select="local:trim-date(.)"/></xsl:otherwise>
            </xsl:choose>
            </string>
        </xsl:if>
    </xsl:template>
    <xsl:template match="*:fields[@function = 'dateEnd']">
        <xsl:param name="doc"/>
        <xsl:param name="id"/>
        <xsl:if test="$doc/descendant::tei:origDate"> 
            <string key="{.}" xmlns="http://www.w3.org/2005/xpath-functions">
                <xsl:choose>
                    <xsl:when test="$doc/descendant::tei:origDate/@to"><xsl:value-of select="local:trim-date($doc/descendant::tei:origDate/@to)"/></xsl:when>
                    <xsl:when test="$doc/descendant::tei:origDate/@when"><xsl:value-of select="local:trim-date($doc/descendant::tei:origDate/@when)"/></xsl:when>
                    <xsl:otherwise><xsl:value-of select="local:trim-date(.)"/></xsl:otherwise>
                </xsl:choose>
            </string>
        </xsl:if>
    </xsl:template>
   
    <xsl:template match="*:fields"/>
      
    <xsl:template match="t:TEI" mode="fullText">
        <xsl:value-of select="normalize-space(string-join(descendant::tei:text/descendant::text(),' '))"/>
    </xsl:template>
    <xsl:template match="t:TEI" mode="title">
        <xsl:choose>
            <xsl:when test="descendant::t:title"><xsl:value-of select="descendant::t:title[1]"/></xsl:when>
        </xsl:choose>
    </xsl:template>
    <!-- Match everything, output lang tags.  -->
    <xsl:template match="*" mode="xmlLang">
        <xsl:choose>
            <xsl:when test="starts-with(@xml:lang,'sy')"> &lt;span lang="syr" dir="rtl"&gt;<xsl:apply-templates mode="xmlLang"/>&lt;/span&gt;</xsl:when>
            <xsl:otherwise><xsl:text> </xsl:text><xsl:apply-templates mode="xmlLang"/><xsl:text> </xsl:text></xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="text()" mode="xmlLang">
        <xsl:value-of select="normalize-space(string-join(.,' '))"/>
    </xsl:template>
    <!-- Output Data as json for OpenSearch  -->
    <!-- Indexes, use facet-config files -->
    <xsl:template name="docJSON">
        <xsl:param name="doc"/>
        <xsl:variable name="xml">
            <map xmlns="http://www.w3.org/2005/xpath-functions">
                <xsl:for-each select="$config/descendant::*:searchFields/*:fields">
                    <xsl:choose>
                        <xsl:when test="@fuenction != ''">Function
                        <string key="{.}" xmlns="http://www.w3.org/2005/xpath-functions">Test Function here</string>
                        </xsl:when>
                        <xsl:when test="@xpath != ''">
                            <string key="{.}" xmlns="http://www.w3.org/2005/xpath-functions">
                                <xsl:variable name="xpath" select="string(@xpath)"/>
<!--                                <xsl:evaluate xpath="$xpath"/>-->
                                <xsl:apply-templates select="$doc" mode="index">
                                    <xsl:with-param name="xpath" select="$xpath"></xsl:with-param>
                                </xsl:apply-templates>
                                <!--
                                <xsl:for-each select="$doc/descendant-or-self::t:TEI">
                                    <xsl:evaluate xpath="$xpath"/>
                                    <xsl:value-of select="local-name(.)"/> :: <xsl:value-of select="local-name(child::*[1])"/>
                                </xsl:for-each>
                                -->
                            </string> 
                        </xsl:when>
                        <xsl:otherwise>
                              <xsl:message>Incorrect field formatting</xsl:message>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>
            </map>
            <!-- 
                <map xmlns="http://www.w3.org/2005/xpath-functions">
                    <map key="mappings">
                        <map key="properties">
                            <xsl:for-each select="$config/descendant::*:searchFields/*:fields">
                                <map key="{.}">
                                    <string key="type">
                                        <xsl:choose>
                                            <xsl:when test="@type"><xsl:value-of select="string(@type)"/></xsl:when>
                                            <xsl:otherwise>text</xsl:otherwise>
                                        </xsl:choose>
                                    </string>
                                </map>
                            </xsl:for-each>
                        </map>
                    </map>
                </map>
            -->
        </xsl:variable>
        <xsl:value-of select="xml-to-json($xml, map { 'indent' : true() })"/>
    </xsl:template>
    
    <xsl:template mode="index" match="/t:TEI">
        <xsl:param name="xpath"></xsl:param>
        <xsl:variable name="string">    
            <xsl:evaluate xpath="$xpath"/>
        </xsl:variable>
        <xsl:value-of select="$string"/>
    </xsl:template>
    
</xsl:stylesheet>
