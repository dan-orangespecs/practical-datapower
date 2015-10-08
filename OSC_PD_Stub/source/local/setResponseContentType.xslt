<!--- 

	@author: Dan Zrobok
	@company: Orange Specs Consulting (www.orangespecs.com)

	To load both JSON and XML stubs, the fetch action has a binary result. 
	The side effect is that it sets the Content-Type header to 'application/octet-stream' for the response.
	This XSLT sets it back to the request's Content-Type.

-->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:dp="http://www.datapower.com/extensions"
extension-element-prefixes="dp"
>
  <xsl:template match="/">
 
	<dp:set-http-request-header name="'Content-Type'" value="dp:variable('var://context/stub/content-type')"/>

  </xsl:template>
 
</xsl:stylesheet>