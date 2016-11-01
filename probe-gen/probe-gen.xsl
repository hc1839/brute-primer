<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
   version="1.0"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:local="urn:local"
   exclude-result-prefixes="local">

<xsl:output method="xml" indent="yes"/>

<xsl:template match="/">

<probe-candidates>
   <xsl:for-each select="local:probeIds()">
      <xsl:variable name="probeId" select="string(.)"/>

      <probe>
         <name><xsl:value-of select="local:probeName($probeId)"/></name>
         <sequence><xsl:value-of select="local:probeSequence($probeId)"/></sequence>
         <region-start><xsl:value-of select="local:probeRegionStart($probeId)"/></region-start>
         <sense><xsl:value-of select="local:probeSense($probeId)"/></sense>
      </probe>
   </xsl:for-each>
</probe-candidates>

</xsl:template>

</xsl:stylesheet>
