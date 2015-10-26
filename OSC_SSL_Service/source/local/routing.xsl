<?xml version="1.0"?>
<!-- 

	Routes the request to the appropriate endpoint for a matching URI from the config.xml file. 

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
	
	<xsl:template match="/">
	
		<xsl:variable name="tid" select="dp:variable('var://service/transaction-id')"/>
	
		<xsl:variable name="req_uri" select="dp:variable('var://service/URI')"/>
		<xsl:variable name="req_uri_components" select="str:tokenize($req_uri,'/')"/>
		<xsl:variable name="req_config_id" select="$req_uri_components[2]"/>
		<xsl:variable name="req_service" select="$req_uri_components[3]"/>
		
		<xsl:variable name="config_file_path" select="concat('./',$req_config_id, '/config.xml')"/>
		<xsl:variable name="config_file_xml" select="document($config_file_path)"/>
		
		<xsl:variable name="generic_uri" select="concat('/',$req_uri_components[1],'/', $req_uri_components[2])"/>
		
		<xsl:variable name="generic_endpoint" select="$config_file_xml/Services/Service[(@URL = $generic_uri) and ((@env = $dp_env) or not(@env))]/endpoint"/>			
		<xsl:variable name="full_svc_endpoint" select="$config_file_xml/Services/Service[(@URL = $req_uri) and ((@env = $dp_env) or not(@env))]/endpoint"/>

		<xsl:choose>
			<xsl:when test="$full_svc_endpoint">
				<dp:xset-target host="$full_svc_endpoint/hostname" port="$full_svc_endpoint/port" ssl="false()" sslid=""/>
			</xsl:when>
			<xsl:when test="$generic_endpoint">
				<dp:xset-target host="$generic_endpoint/hostname" port="$generic_endpoint/port" ssl="false()" sslid=""/>
			</xsl:when>
			<xsl:otherwise>
				<dp:reject>No routing information for the URI '<xsl:value-of select="$req_uri"/>' or '<xsl:value-of select="$generic_uri"/>' was found.</dp:reject>
			</xsl:otherwise>
		</xsl:choose>
	
		<xsl:message dp:priority="debug">
=== SSL Service Routing 
	Selected <xsl:choose><xsl:when test="$generic_endpoint">Generic</xsl:when><xsl:when test="$full_svc_endpoint">Service</xsl:when></xsl:choose> level routing. 
	Routing to: <xsl:value-of select="dp:variable('var://service/URL-out')"/>
===
		</xsl:message>
	
	</xsl:template>
	
</xsl:stylesheet>