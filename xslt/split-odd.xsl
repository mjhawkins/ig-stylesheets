<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:cudl="http://cudl.lib.cam.ac.uk/xtf/" 
    xmlns:json="http://www.w3.org/2005/xpath-functions"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="#all">
    
    <xsl:output method="xml" indent="no" encoding="UTF-8"/>
    
    <xsl:mode on-no-match="shallow-copy"/>
    
    <xsl:param name="output.dir" />
    
    <xsl:template match="/tei:TEI">
        
        <xsl:result-document href="{string-join((replace($output.dir,'/$',''),'element-reference.xml'),'/')}">
            <xsl:apply-templates select="." mode="odd"/>
        </xsl:result-document>
        <xsl:copy>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="tei:div[tei:schemaSpec]">
        <div xml:id="element-reference"></div>
    </xsl:template>
    
    <xsl:template match="tei:div[not(.//tei:schemaSpec)]" mode="odd"/>
    
    <xsl:template match="@*|node()" mode="#all">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>