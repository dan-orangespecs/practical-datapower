<!--  
	@author: Dan Zrobok
	@company: Orange Specs Consulting (www.orangespecs.com)
	
	This stylesheet will process a stub request message, set the following context variables:
	
		var://context/stub/type
		var://context/stub/url
		var://context/stub/content-type
		
	It also checks for existence of the STUBID HTTP Header and that the requested stub could be loaded. 
		If it could not be loaded, the transaction will be rejected. 
		
 -->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:dp="http://www.datapower.com/extensions" extension-element-prefixes="dp">
 
  <xsl:template match="/">
  
	<xsl:variable name="stubId" select="translate(dp:http-request-header('STUBID'), 'abcdefghijklmnopqrstuvwxyz' , 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' )"/>
	<dp:remove-http-request-header name="STUBID"/>

    <xsl:variable name="type">
    	<xsl:choose>
    		<xsl:when test="contains(dp:http-request-header('Content-Type'), 'json')">json</xsl:when>
    		<xsl:otherwise>xml</xsl:otherwise>
    	</xsl:choose>
    </xsl:variable>
    
	<xsl:variable name="stubURL" select="concat('local:///responses/',$stubId,'.', $type)"/>
	
	<xsl:variable name="stubFileResponseCode"> 
		<dp:url-open target="{$stubURL}" timeout="1" response="responsecode-binary" http-method="get"/>
	</xsl:variable>
	
	<dp:set-variable name="'var://context/stub/type'" value="string($type)"/>
	<dp:set-variable name="'var://context/stub/url'" value="string($stubURL)"/>
	<dp:set-variable name="'var://context/stub/content-type'" value="string(dp:http-request-header('Content-Type'))"/>
 	
	<xsl:message dp:priority="debug">
		Stub ID: <xsl:value-of select="$stubId"/>
		Stub Type: <xsl:value-of select="$type"/>
		Stub URL: <xsl:value-of select="dp:variable('var://context/stub/url')"/>
		Stub Loading Response Code: <xsl:copy-of select="$stubFileResponseCode"/>
	</xsl:message>
	
	<xsl:choose>
		<xsl:when test="not($stubId)">
			<dp:reject>Error: HTTP Header 'STUBID' was missing from request message.</dp:reject>
		</xsl:when>
		<xsl:when test="count($stubFileResponseCode/result/headers/header[@name = 'x-dp-local-file']) = 0">
			<dp:reject>Error: The stub file '<xsl:value-of select="$stubURL"/>' was not found in the filesystem.</dp:reject>
		</xsl:when>
	</xsl:choose>
		
  </xsl:template>
</xsl:stylesheet>