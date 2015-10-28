<!-- 
	@author: Dan Zrobok
	@company: Orange Specs Consulting (www.orangespecs.com)
	
	This stylesheet returns an error response (XML or JSON) dependent on the Content-Type of the original request. 
	
	Copyright (c) 2015, Dan Zrobok, Orange Specs Consulting Inc, http://orangespecs.com

	Permission to use, copy, modify, and/or distribute this software for any
	purpose with or without fee is hereby granted, provided that the above
	copyright notice and this permission notice appear in all copies.

	THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
	WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
	MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
	ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
	WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
	ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
	OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 -->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:dp="http://www.datapower.com/extensions" extension-element-prefixes="dp">

	<xsl:include href="./environment.xsl"/>

    <xsl:variable name="orig_content_type" select="dp:variable('var://service/original-content-type')"/>
    
	<xsl:variable name="dp_env">
		<xsl:call-template name="getCurrentEnvironment"/>
	</xsl:variable>	
	
	<xsl:variable name="error_msg">
		<xsl:choose>
			<xsl:when test="not($dp_env = 'PROD') and (dp:variable('var://service/error-subcode') = '0x01d30002' or dp:variable('var://service/error-subcode') ='0x01d30001')"><xsl:value-of select="dp:variable('var://service/error-message')"/> [<xsl:value-of select="dp:variable('var://service/error-code')"/>-<xsl:value-of select="dp:variable('var://service/error-subcode')"/>]</xsl:when>
			<xsl:when test="not($dp_env = 'PROD')">Error connecting to URL '<xsl:value-of select="dp:variable('var://service/URL-out')"/>: '<xsl:value-of select="dp:variable('var://service/error-message') "/>' [<xsl:value-of select="dp:variable('var://service/error-code')"/>-<xsl:value-of select="dp:variable('var://service/error-subcode')"/>]</xsl:when>
			<xsl:otherwise>This request could not be completed.</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>

    <xsl:template match="/">
        <xsl:choose>
            <xsl:when test="contains($orig_content_type,'json')">
          	    <json:object xmlns:json="http://www.ibm.com/xmlns/prod/2009/jsonx">
          			 <json:string name="error" xmlns:json="http://www.ibm.com/xmlns/prod/2009/jsonx">
           	    		 <xsl:value-of select="$error_msg"/>
					</json:string>
                </json:object>   
           </xsl:when>
            <xsl:otherwise>
				<error>
                	<xsl:value-of select="$error_msg"/>
                </error>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
</xsl:stylesheet>