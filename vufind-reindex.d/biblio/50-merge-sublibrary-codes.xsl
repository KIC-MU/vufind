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

  <xsl:template match="//marc:subfield[../marc:datafield[@tag = '994'] and @code = '1' and (text() = 'FFHUD' or text() = 'FFJZV' or text() = 'FF-K' or text() = 'FF-S' or text() = 'FFUHV')]">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:text>FF</xsl:text>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="//marc:subfield[../marc:datafield[@tag = '994'] and @code = '1' and (text() = 'PRIMA' or text() = 'PRI-S')]">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:text>PRIF</xsl:text>
    </xsl:copy>
  </xsl:template>
</xsl:stylesheet>
