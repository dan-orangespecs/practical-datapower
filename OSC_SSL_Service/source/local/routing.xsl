<?xml version="1.0"?>
<!-- 

Incoming URIs follow the format /dp/<config_id>/[optional:<serviceName>]/.../

 -->
<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:str="http://exslt.org/strings"
	xmlns:dp="http://www.datapower.com/extensions"
	extension-element-prefixes="dp"
	exclude-result-prefixes="dp str">
	
	<xsl:output indent="yes" method="xml" omit-xml-declaration="yes"/>
	
	<xsl:include href="./environment.xsl"/>
	
	<xsl:variable name="dp_env">
		<xsl:call-template name="getCurrentEnvironment"/>
	</xsl:variable>

	<xsl:variable name="lowercase" select="'abcdefghijklmnopqrstuvwxyz'" />
    <xsl:variable name="uppercase" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'" />
	
	<xsl:template match="/">
	
		<xsl:variable name="tid" select="dp:variable('var://service/transaction-id')"/>
	
		<xsl:variable name="req_uri" select="dp:variable('var://service/URI')"/>
		<xsl:variable name="req_uri_components" select="str:tokenize($req_uri,'/')"/>
		<xsl:variable name="req_config_id" select="$req_uri_components[2]"/>
		<xsl:variable name="req_service" select="$req_uri_components[3]"/>
		
		<xsl:variable name="config_file_path" select="concat('./',$req_config_id, '/config.xml')"/>
		<xsl:variable name="config_file_xml" select="document($config_file_path)"/>
		
		<xsl:variable name="domainLevelURI" select="concat('/',$req_uri_components[1],'/', $req_uri_components[2])"/>
		
		<xsl:variable name="domain_level_endpoint" select="$config_file_xml/Services/Service[(@URL = $domainLevelURI) and ((@env = $dp_env) or not(@env))]/endpoint"/>			
		<xsl:if test="$domain_level_endpoint">
			<dp:xset-target host="$domain_level_endpoint/hostname" port="$domain_level_endpoint/port" ssl="false()" sslid=""/>
		</xsl:if>
		
		<xsl:variable name="svc_level_endpoint" select="$config_file_xml/Services/Service[(@URL = $req_uri) and ((@env = $dp_env) or not(@env))]/endpoint"/>
		<xsl:if test="$svc_level_endpoint">
			<dp:xset-target host="$svc_level_endpoint/hostname" port="$svc_level_endpoint/port" ssl="false()" sslid=""/>
  		</xsl:if>
	
		<xsl:choose>
			<xsl:when test="not($domain_level_endpoint) and not($svc_level_endpoint)">
				<dp:reject>No routing information for the request was found.</dp:reject>
			</xsl:when>
		</xsl:choose>
	
		<xsl:message dp:priority="debug">
		=== SSL Service Routing 
			Selected <xsl:choose><xsl:when test="$domain_level_endpoint">Domain</xsl:when><xsl:when test="$svc_level_endpoint">Service</xsl:when></xsl:choose> level routing. 
    	    Routing to: <xsl:value-of select="dp:variable('var://service/routing-url')"/>
    	===
		</xsl:message>
	
	</xsl:template>
	
	
	
</xsl:stylesheet>