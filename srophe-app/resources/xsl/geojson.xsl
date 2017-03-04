<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:x="http://www.w3.org/1999/xhtml" xmlns:saxon="http://saxon.sf.net/" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:local="http://syriaca.org/ns" exclude-result-prefixes="xs t x saxon local" version="2.0">
    <xsl:output method="text" encoding="UTF-8" media-type="text/plain"/>
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     deprecated
    ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="/">
        <xsl:if test="count(//features) &gt; 1">
            [    
        </xsl:if>
        <xsl:for-each select="//features">
                {
                "type": "Feature",  
                "geometry": {
                    "type": "Point",
                    "coordinates": [<xsl:value-of select="geometry/coordinates[1]"/>, <xsl:value-of select="geometry/coordinates[2]"/>]
                },
                "properties": {
                "uri": "<xsl:value-of select="properties/uri"/>",<xsl:if test="properties/placeType">"type": "<xsl:value-of select="properties/placeType"/>",</xsl:if>
            <xsl:if test="properties/type">"type": "<xsl:value-of select="properties/type"/>",</xsl:if>
            <xsl:if test="properties/placeRelation">"relation": "<xsl:value-of select="properties/placeRelation"/>",</xsl:if>"name": "<xsl:value-of select="properties/name"/>"
                }}<xsl:if test="following-sibling::*">,</xsl:if>
        </xsl:for-each>
        <xsl:choose>
            <xsl:when test="count(//features) &gt; 1">
                <xsl:text>]</xsl:text>
            </xsl:when>
            <xsl:otherwise>;</xsl:otherwise>
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>