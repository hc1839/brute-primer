<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
   version="1.0"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:local="urn:local"
   exclude-result-prefixes="local">

<xsl:output method="xml" indent="yes"/>

<xsl:template match="/">

<tntblast-primers>
   <xsl:for-each select="local:primerPairRecordIds()">
      <xsl:variable name="primerPairRecordId" select="string(.)"/>

      <primer-pair>
         <name><xsl:value-of select="local:primerPairName($primerPairRecordId)"/></name>
         <region-start><xsl:value-of select="local:ampliconRegionStart($primerPairRecordId)"/></region-start>
         <region-length><xsl:value-of select="local:ampliconRegionLength($primerPairRecordId)"/></region-length>
         <melting-temperature-fwd><xsl:value-of select="local:fwdPrimerMeltingTemperature($primerPairRecordId)"/></melting-temperature-fwd>
         <melting-temperature-rev><xsl:value-of select="local:revPrimerMeltingTemperature($primerPairRecordId)"/></melting-temperature-rev>
      </primer-pair>

   </xsl:for-each>
</tntblast-primers>

</xsl:template>

</xsl:stylesheet>
