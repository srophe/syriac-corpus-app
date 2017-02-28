<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs" version="2.0">
    <xsl:template name="boilerplate-badbrowser">
        <xsl:text disable-output-escaping="yes">
   
    &lt;!--[if lt IE 7]&gt;
            &lt;p class="chromeframe"&gt;You are using an &lt;strong&gt;outdated&lt;/strong&gt; browser. Please &lt;a href="http://browsehappy.com/"&gt;upgrade your browser&lt;/a&gt; or &lt;a href="http://www.google.com/chromeframe/?redirect=true"&gt;activate Google Chrome Frame&lt;/a&gt; to improve your experience.&lt;/p&gt;
        &lt;![endif]--&gt;
   </xsl:text>
    </xsl:template>
</xsl:stylesheet>