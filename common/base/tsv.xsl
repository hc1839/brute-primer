<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
   version="1.0"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:local="urn:local"
   exclude-result-prefixes="local">

<xsl:output method="text"/>

<xsl:template match="/">

<xsl:for-each select="local:records()">
   <xsl:variable name="cells" select="local:cells(.)"/>

   <xsl:for-each select="$cells[position() &lt; last()]">
      <xsl:value-of select="string(.)"/>
      <xsl:text>&#x09;</xsl:text>
   </xsl:for-each>

   <xsl:value-of select="string($cells[last()])"/>
   <xsl:text>&#x0a;</xsl:text>
</xsl:for-each>

</xsl:template>

</xsl:stylesheet>
