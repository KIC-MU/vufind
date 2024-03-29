<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:marc="http://www.loc.gov/MARC21/slim"
  >
  <xsl:output omit-xml-declaration="yes" indent="yes"/>
  <xsl:strip-space elements="*"/>

  <xsl:template match="node() | @*" name="identity">
    <xsl:copy>
      <xsl:apply-templates select="node() | @*"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="//marc:datafield[@tag = 'M06' and .//marc:subfield[@code = 'a' and text() = 'Article']]"/>

  <xsl:template match="//marc:datafield[@tag = 'M06' and .//marc:subfield[@code = 'a' and not(text() = 'Article')]]">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:attribute name="tag">995</xsl:attribute>
      <xsl:copy-of select="node()"/>
    </xsl:copy>
  </xsl:template>
</xsl:stylesheet>
