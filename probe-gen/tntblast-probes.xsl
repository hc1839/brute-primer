<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
   version="1.0"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:local="urn:local"
   exclude-result-prefixes="local">

<xsl:output method="xml" indent="yes"/>

<xsl:template match="/">

<tntblast-probes>
   <xsl:for-each select="local:probeRecordIds()">
      <xsl:variable name="probeRecordId" select="string(.)"/>

      <probe>
         <name><xsl:value-of select="local:probeName($probeRecordId)"/></name>
         <region-start><xsl:value-of select="local:probeRegionStart($probeRecordId)"/></region-start>
         <region-length><xsl:value-of select="local:probeRegionLength($probeRecordId)"/></region-length>
         <sense><xsl:value-of select="local:probeSense($probeRecordId)"/></sense>
         <melting-temperature><xsl:value-of select="local:probeMeltingTemperature($probeRecordId)"/></melting-temperature>
      </probe>

   </xsl:for-each>
</tntblast-probes>

</xsl:template>

</xsl:stylesheet>
