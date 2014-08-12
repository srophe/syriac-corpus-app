<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs" version="2.0">
    <xsl:template name="langattr">
        <xsl:if test="@xml:lang">
            <xsl:copy-of select="@xml:lang"/>
            <xsl:attribute name="lang">        
                <xsl:value-of select="@xml:lang"/>        
            </xsl:attribute>
        </xsl:if>
    </xsl:template>
</xsl:stylesheet>