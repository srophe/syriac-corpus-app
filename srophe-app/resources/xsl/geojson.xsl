<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:s="http://syriaca.org" xmlns:saxon="http://saxon.sf.net/" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs t s saxon" version="2.0">
    <xsl:output method="text" encoding="UTF-8" media-type="text/plain"/>
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     top-level logic and instructions for creating the browse listing page
    ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="/">
        [<xsl:for-each select="//features">
                {
                "type": "Feature",  
                "geometry": {
                    "type": "Point",
                    "coordinates": [<xsl:value-of select="geometry/coordinates[1]"/>, <xsl:value-of select="geometry/coordinates[2]"/>]
                },
                "properties": {
                "uri": "<xsl:value-of select="properties/uri"/>",
                "type": "<xsl:value-of select="properties/type"/>",
                "name": "<xsl:value-of select="properties/name"/>"
                }}<xsl:if test="following-sibling::*">,</xsl:if>
        </xsl:for-each>];
    </xsl:template>
</xsl:stylesheet>