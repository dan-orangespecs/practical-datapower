<!-- 
	@author: Dan Zrobok
	@company: Orange Specs Consulting (www.orangespecs.com)
	
	This stylesheet returns an error response (XML or JSON) dependent on the type of stub requested. 
	
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
    <xsl:template match="/">

        <xsl:variable name="content-type" select="dp:variable('var://service/original-content-type')"/>

        <xsl:choose>
            <xsl:when test="contains($content-type,'json')">
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