<?xml version="1.0"?>
<!-- 

Incoming URIs follow the format /dp/<config_id>/....

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
	
		<xsl:variable name="req_uri" select="/container/mapped-resource/resource/item[@type = 'original-url']/text()"/>
		<xsl:variable name="req_uri_components" select="str:tokenize($req_uri,'/')"/>
		<xsl:variable name="req_config_id" select="$req_uri_components[2]"/>
		
		<xsl:variable name="config_file_path" select="concat('./',$req_config_id, '/config.xml')"/>
		<xsl:variable name="config_file_xml" select="document($config_file_path)"/>
		
		<xsl:variable name="client_dn" select="/container/identity/entry[@type='client-ssl']/dn/text()"/>
		
		<xsl:variable name="client_cn">
			<xsl:for-each select="str:tokenize($client_dn, '/')">
				<xsl:if test="starts-with(., 'CN=')">
					<xsl:value-of select="substring(.,4)"/>
				</xsl:if>
			</xsl:for-each>
		</xsl:variable>
		 
		<xsl:variable name="client_issuer_dn"  select="/container/identity/entry[@type='client-ssl']/issuer/text()"/>
		
		<xsl:variable name="client_issuer_id">
			<xsl:call-template name="getIssuerIdentifier">
				<xsl:with-param name="issuer_dn" select="$client_issuer_dn"/>
				<xsl:with-param name="dn" select="$client_dn"/>
			</xsl:call-template>
		</xsl:variable>
	
		<xsl:message dp:priority="debug">
=== SSL Service - Request Info ===
	TID                : <xsl:value-of select="$tid"/> 
	ENV                : <xsl:value-of select="$dp_env"/>
	URI                : <xsl:value-of select="$req_uri"/>
	Config ID          : <xsl:value-of select="$req_config_id"/>
	Config File        : <xsl:value-of select="$config_file_path"/>
	DN                 : <xsl:value-of select="$client_dn"/>
	CN                 : <xsl:value-of select="$client_cn"/>
	Issuer DN          : <xsl:value-of select="$client_issuer_dn"/>
	Issuer ID          : <xsl:value-of select="$client_issuer_id"/>
	URI Components	   : <xsl:value-of select="count($req_uri_components)"/>
===
		</xsl:message>
		
		<xsl:variable name="generic_config_uri" select="concat('/',$req_uri_components[1],'/', $req_uri_components[2])"/>
		
		<xsl:variable name="fullURIStatusCode">
			<xsl:call-template name="getMatchStatusCode">
				<xsl:with-param name="env" select="$dp_env"/>
				<xsl:with-param name="config_xml" select="$config_file_xml"/>
				<xsl:with-param name="uri" select="$req_uri"/>
				<xsl:with-param name="dn" select="$client_dn"/>
				<xsl:with-param name="cn" select="$client_cn"/>
				<xsl:with-param name="issuer_id" select="$client_issuer_id"/>
				<xsl:with-param name="tid" select="$tid"/>			
			</xsl:call-template>	
		</xsl:variable>
		
		<xsl:variable name="genericURIStatusCode">
			<xsl:call-template name="getMatchStatusCode">
				<xsl:with-param name="env" select="$dp_env"/>
				<xsl:with-param name="config_xml" select="$config_file_xml"/>
				<xsl:with-param name="uri" select="$generic_config_uri"/>
				<xsl:with-param name="dn" select="$client_dn"/>
				<xsl:with-param name="cn" select="$client_cn"/>
				<xsl:with-param name="issuer_id" select="$client_issuer_id"/>
				<xsl:with-param name="tid" select="$tid"/>			
			</xsl:call-template>	
		</xsl:variable>
		
		<!--  Only look atthe generic URL code if the specific URL doesn't exist (code 404.1) -->
		
		<xsl:variable name="statusCode">
			<xsl:choose>
				<xsl:when test="string-length($client_dn) = 0">400</xsl:when>
				<xsl:when test="(count($req_uri_components) &lt; 2) or not($req_uri_components[1] = 'dp')">400.1</xsl:when>
				<xsl:when test="not($config_file_xml)">500</xsl:when>
				<xsl:when test="$fullURIStatusCode = 200   or ($fullURIStatusCode = 404.1 and $genericURIStatusCode = 200)">200</xsl:when>
				<xsl:when test="$fullURIStatusCode = 403   or ($fullURIStatusCode = 404.1 and $genericURIStatusCode = 403)">403</xsl:when>
				<xsl:when test="$fullURIStatusCode = 404.3 or ($fullURIStatusCode = 404.1 and $genericURIStatusCode = 404.3)">404.3</xsl:when>
				<xsl:when test="$fullURIStatusCode = 404.2 or ($fullURIStatusCode = 404.1 and $genericURIStatusCode = 404.2)">404.2</xsl:when>
   				<xsl:when test="$fullURIStatusCode = 404.1 or $genericURIStatusCode = 404.1">404.1</xsl:when>
				<xsl:otherwise>500</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		
		<xsl:variable name="statusMessage">
			<xsl:choose>
				<xsl:when test="$statusCode = 500">DataPower configuration file '<xsl:value-of select="$config_file_path"/>' not found.</xsl:when>
				<xsl:when test="$statusCode = 400">Client did not present a certificate.</xsl:when>
				<xsl:when test="$statusCode = 400.1">Client's request URI '<xsl:value-of select="$req_uri"/>' does not follow platform standard of '/dp/*'.</xsl:when>
				<xsl:when test="$statusCode = 404.1">No configuration found for URI '<xsl:value-of select="$req_uri"/>' or '<xsl:value-of select="$generic_config_uri"/>' found in configuration file '<xsl:value-of select="$config_file_path"/>'.</xsl:when>
				<xsl:when test="$statusCode = 404.2">No '<xsl:value-of select="$dp_env"/>' environment defined for URI '<xsl:value-of select="$req_uri"/>' in configuration file '<xsl:value-of select="$config_file_path"/>'.</xsl:when>
				<xsl:when test="$statusCode = 404.3">No Match for certificate signer '<xsl:value-of select="$client_issuer_id"/>' in '<xsl:value-of select="$dp_env"/>' environment for URI '<xsl:value-of select="$req_uri"/>' in configuration file '<xsl:value-of select="$config_file_path"/>'.</xsl:when>
				<xsl:when test="$statusCode = 403">No match for client certificate '<xsl:value-of select="$client_dn"/>' issued by '<xsl:value-of select="$client_issuer_id"/>' in '<xsl:value-of select="$dp_env"/>' environment for URI '<xsl:value-of select="$req_uri"/>' in configuration file '<xsl:value-of select="$config_file_path"/>'.</xsl:when>
				<xsl:when test="$statusCode = 200">Transaction Authorized</xsl:when>
				<xsl:otherwise>Unknown Error.</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		
		<xsl:message dp:priority="debug">
=== SSL Service - result
	TID         : <xsl:value-of select="$tid"/>
	Status Code : <xsl:value-of select="$statusCode"/>
	Message     : <xsl:value-of select="$statusMessage"/>
===
		</xsl:message>
		
		<xsl:choose>
			<xsl:when test="not($statusCode = 200)">
				<declined><xsl:value-of select="$statusMessage"/></declined>
				
				<xsl:message dp:priority="error">
=== SSL Service - Rejected Transaction
	Code        : <xsl:value-of select="$statusCode"/>
	Message     : <xsl:value-of select="$statusMessage"/>
	URI         : <xsl:value-of select="$req_uri"/>
	ConfigID    : <xsl:value-of select="$req_config_id"/>
	ConfigPath  : <xsl:value-of select="$config_file_path"/>
	ClientDN    : <xsl:value-of select="$client_dn"/>
	ClientCN    : <xsl:value-of select="$client_cn"/>
	IssuerDN    : <xsl:value-of select="$client_issuer_dn"/>
	IssuerID    : <xsl:value-of select="$client_issuer_id"/>
	TID         : <xsl:value-of select="$tid"/>
===
				</xsl:message>
			</xsl:when>	
			<xsl:when test="$statusCode = 200">
				<approved />
			</xsl:when>
		</xsl:choose>
	</xsl:template>
	
	<!-- 
		Compares a URL to the whitelist for a CN and DN and returns a code. 200 for success, other codes for various scenarios. 
	 -->
	<xsl:template name="getMatchStatusCode">
		<xsl:param name="env"/>
		<xsl:param name="config_xml"/>
		<xsl:param name="uri"/>
		<xsl:param name="dn"/>
		<xsl:param name="cn"/>
		<xsl:param name="issuer_id"/>
		<xsl:param name="tid"/>
		
		<xsl:variable name="svc_config" select="$config_xml/services/service[(@url = $uri)]"/>
		<xsl:variable name="svc_config_env" select="$svc_config[((@env = $env) or not(@env))]"/>
		<xsl:variable name="allow_list" select="$svc_config_env/allow"/>		
		
		<xsl:variable name="allow_list_issuer" select="$allow_list[not(@issuer) or (@issuer and translate(@issuer, $uppercase, $lowercase) = $issuer_id)]"/>
		
		<xsl:variable name="dn_match" select="boolean($allow_list_issuer/dn[text() = $dn])"/>
		<xsl:variable name="cn_match" select="boolean($allow_list_issuer/cn[text() = $cn])"/>
	
		<xsl:variable name="result">
			<xsl:choose>
				<xsl:when test="not($config_xml)">500</xsl:when>
				<xsl:when test="not($svc_config)">404.1</xsl:when>
				<xsl:when test="not($svc_config_env)">404.2</xsl:when>
				<xsl:when test="not($allow_list_issuer)">404.3</xsl:when>
				<xsl:when test="not($dn_match or $cn_match)">403</xsl:when>				
				<xsl:otherwise>200</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
	
		<xsl:value-of select="$result"/>
	
		<xsl:message dp:priority="debug">
=== SSL Service - getMatchStatusCode
	TID        : <xsl:value-of select="$tid"/>
	Env        : <xsl:value-of select="$dp_env"/>
	URI        : <xsl:value-of select="$uri"/>
	DN         : <xsl:value-of select="$dn"/>
	CN         : <xsl:value-of select="$cn"/>
	Issuer Id  : <xsl:value-of select="$issuer_id"/>
	Code	   : <xsl:copy-of select="$result"/>
===
		</xsl:message>
	
	</xsl:template>
	
	<!--  
		Returns an identifier for a certificate's issuer, this is used to condense the many 
		intermediate signer certificates into a single id that can be referenced by the ./config_id/config.xml
		while allowing each organization to determine how thorough the check is (1:1 or n:1). 
		
		The key to security is that the TLS Server Profile verifies that the signer DN is valid
		before arriving at this point. 
		
		Example: 'verisign', 'orangespecs' or 'self-signed'
	 -->
	
	<xsl:template name="getIssuerIdentifier">
		<xsl:param name="issuer_dn"/>
		<xsl:param name="dn"/>
		
		<xsl:choose>
			<xsl:when test="contains($issuer_dn,'VeriSign')">verisign</xsl:when>
			<xsl:when test="contains($issuer_dn, 'Orange Specs Incorporated SSL Test Intermediate CA')">orangespecs</xsl:when>
			<xsl:when test="string-length($issuer_dn) > 0 and  $issuer_dn = $dn">self-signed</xsl:when>
			<xsl:otherwise>unknown</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
</xsl:stylesheet>
