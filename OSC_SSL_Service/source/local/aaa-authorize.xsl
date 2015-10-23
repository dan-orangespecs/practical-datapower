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
	
		<xsl:variable name="req_uri" select="/container/mapped-resource/resource/item[@type = 'original-url']/text()"/>
		<xsl:variable name="req_uri_components" select="str:tokenize($req_uri,'/')"/>
		<xsl:variable name="req_config_id" select="$req_uri_components[2]"/>
		<xsl:variable name="req_service" select="$req_uri_components[3]"/>
		
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
	=== SSL Service Info ===
			TID                : <xsl:value-of select="$tid"/> 
			ENV                : <xsl:value-of select="$dp_env"/>
			URI                : <xsl:value-of select="$req_uri"/>
			Config ID          : <xsl:value-of select="$req_config_id"/>
			Service            : <xsl:value-of select="$req_service"/>
			Config File        : <xsl:value-of select="$config_file_path"/>
			DN                 : <xsl:value-of select="$client_dn"/>
			CN                 : <xsl:value-of select="$client_cn"/>
			Issuer DN          : <xsl:value-of select="$client_issuer_dn"/>
			Issuer ID          : <xsl:value-of select="$client_issuer_id"/>
	===
		</xsl:message>
		
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
		
		<xsl:variable name="domainLevelURIStatusCode">
			<xsl:call-template name="getMatchStatusCode">
				<xsl:with-param name="env" select="$dp_env"/>
				<xsl:with-param name="config_xml" select="$config_file_xml"/>
				<xsl:with-param name="uri" select="concat('/',$req_uri_components[1],'/', $req_uri_components[2])"/>
				<xsl:with-param name="dn" select="$client_dn"/>
				<xsl:with-param name="cn" select="$client_cn"/>
				<xsl:with-param name="issuer_id" select="$client_issuer_id"/>
				<xsl:with-param name="tid" select="$tid"/>			
			</xsl:call-template>	
		</xsl:variable>
		
		<xsl:variable name="statusCode">
			<xsl:choose>
				<xsl:when test="not($config_file_xml)">500</xsl:when>
				<xsl:when test="$fullURIStatusCode = 200 or $domainLevelURIStatusCode = 200">200</xsl:when>
				<xsl:otherwise>404</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		
		<xsl:variable name="statusMessage">
			<xsl:choose>
				<xsl:when test="$statusCode = '500'">Domain Configuration file not found.</xsl:when>
				<xsl:when test="$statusCode = '404'">No DN or CN match for client certificate in domain configuration file.</xsl:when>
				<xsl:when test="$statusCode = '200'">Transaction Authorized</xsl:when>
				<xsl:otherwise>Unknown Error</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		
		<xsl:message dp:priority="debug">
	=== SSL Service - result
			TID         : <xsl:value-of select="$tid"/>
			Status Code : <xsl:value-of select="$statusCode"/>
			Status Msg  : <xsl:value-of select="$statusMessage"/>
	===
		</xsl:message>
		
		<xsl:choose>
			<xsl:when test="not($statusCode = 200)">
				<rejected>
					<error>
						<code><xsl:value-of select="$statusCode"/></code>
						<message><xsl:value-of select="$statusMessage"/></message>
					</error>
					<uri><xsl:value-of select="$req_uri"/></uri>
					<configID><xsl:value-of select="$req_config_id"/></configID>
					<service><xsl:value-of select="$req_service"/></service>
					<configPath><xsl:value-of select="$config_file_path"/></configPath>
					<clientDN><xsl:value-of select="$client_dn"/></clientDN>
					<clientCN><xsl:value-of select="$client_cn"/></clientCN>
					<issuerDN><xsl:value-of select="$client_issuer_dn"/></issuerDN>
					<issuerID><xsl:value-of select="$client_issuer_id"/></issuerID>
					<tid><xsl:value-of select="$tid"/></tid>
				</rejected>
			</xsl:when>	
			<xsl:when test="$statusCode = 200">
				<approved />
			</xsl:when>
		</xsl:choose>
	</xsl:template>
	
	<!-- 
		Compares a URL to the whitelist for a CN and DN and returns a code. 200 for success, 404 for no match and 500 for an error. 
	 -->
	<xsl:template name="getMatchStatusCode">
		<xsl:param name="env"/>
		<xsl:param name="config_xml"/>
		<xsl:param name="uri"/>
		<xsl:param name="dn"/>
		<xsl:param name="cn"/>
		<xsl:param name="issuer_id"/>
		<xsl:param name="tid"/>
		
		<xsl:variable name="allow_list" select="$config_xml/Services/Service[(@URL = $uri) and ((@env = $env) or not(@env))]/allow"/>		
		
		<xsl:variable name="dn_match" select="boolean($allow_list[not(@issuer) or (@issuer and translate(@issuer, $uppercase, $lowercase) = $issuer_id)]/DN[text() = $dn])"/>
		<xsl:variable name="cn_match" select="boolean($allow_list[not(@issuer) or (@issuer and translate(@issuer, $uppercase, $lowercase) = $issuer_id)]/CN[text() = $cn])"/>
		
		<xsl:message dp:priority="debug">
	=== SSL Service - getMatchStatusCode
			TID      : <xsl:value-of select="$tid"/>
			ENV      : <xsl:value-of select="$dp_env"/>
			URI      : <xsl:value-of select="$uri"/>
			DN       : <xsl:value-of select="$dn"/>
			CN       : <xsl:value-of select="$cn"/>
			DN Match : <xsl:copy-of select="$dn_match"/>
			CN Match : <xsl:copy-of select="$cn_match"/>
	===
		</xsl:message>
	
		<xsl:choose>
			<xsl:when test="not($config_xml)">500</xsl:when>
			<xsl:when test="not($dn_match or $cn_match)">404</xsl:when>				
			<xsl:otherwise>200</xsl:otherwise>
		</xsl:choose>
	
	</xsl:template>
	
	<!--  
		Returns an identifier for a certificate's issuer, this is used to condense the many signer certificates
		into a single id that can be referenced by the domain config.xml
		
		This template can be beefed up depending on the requirements
		
		Example: 'verisign' or 'self-signed'
	 -->
	
	<xsl:template name="getIssuerIdentifier">
		<xsl:param name="issuer_dn"/>
		<xsl:param name="dn"/>
		
		<xsl:choose>
			<xsl:when test="contains($issuer_dn,'VeriSign')">verisign</xsl:when>
			<xsl:when test="string-length($issuer_dn) > 0 and  $issuer_dn = $dn">self-signed</xsl:when>
			<xsl:otherwise>unknown</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
</xsl:stylesheet>
