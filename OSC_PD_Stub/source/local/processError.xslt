<!-- 
	@author: Dan Zrobok
	@company: Orange Specs Consulting (www.orangespecs.com)
	
	This stylesheet returns an error response (XML or JSON) dependent on the type of stub requested. 

 -->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:dp="http://www.datapower.com/extensions" extension-element-prefixes="dp">
    <xsl:template match="/">

        <xsl:variable name="stubType" select="dp:variable('var://context/stub/type')"/>

        <xsl:choose>
            <xsl:when test="contains($stubType,'json')">
                <json:object xmlns:json="http://www.ibm.com/xmlns/prod/2009/jsonx">
                    <json:string name="error" xmlns:json="http://www.ibm.com/xmlns/prod/2009/jsonx">
                        <xsl:value-of select="dp:variable('var://service/error-message')"/>
                    </json:string>
                </json:object>
            </xsl:when>
            <xsl:otherwise>
                <error>
                    <xsl:value-of select="dp:variable('var://service/error-message')"/>
                </error>
            </xsl:otherwise>
        </xsl:choose>

    </xsl:template>
</xsl:stylesheet>