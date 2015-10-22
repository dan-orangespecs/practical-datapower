<?xml version="1.0"?>
<!-- 

Incoming URIs follow the format /in/<domain_name>/[optional:<serviceName>]


 -->
<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:str="http://exslt.org/strings"
	xmlns:dp="http://www.datapower.com/extensions"
	extension-element-prefixes="dp"
	exclude-result-prefixes="dp str">
	
	<xsl:output indent="yes" method="xml"/>
	
	<xsl:variable name="lowercase" select="'abcdefghijklmnopqrstuvwxyz'" />
    <xsl:variable name="uppercase" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'" />

	<xsl:template match="/">
	
		<xsl:variable name="req_uri" select="/container/mapped-resource/resource/item[@type = 'original-url']/text()"/>
		<xsl:variable name="req_uri_components" select="str:tokenize($req_uri,'/')"/>
		<xsl:variable name="req_domain" select="$req_uri_components[2]"/>
		<xsl:variable name="req_service" select="$req_uri_components[3]"/>
		
		<xsl:variable name="domain_config_path" select="concat('./',$req_domain, '/config.xml')"/>
		<xsl:variable name="domain_config_xml" select="document($domain_config_path)"/>
		
		<xsl:variable name="client_DN" select="/container/identity/entry[@type='client-ssl']/dn/text()"/>
		<xsl:variable name="client_CN" select="str:tokenize(str:tokenize($client_DN,'/')[6],'CN=')[1]"/>
		
		<xsl:variable name="client_issuer_DN"  select="/container/identity/entry[@type='client-ssl']/issuer/text()"/>
		
		<xsl:variable name="client_issuer_ID">
			<xsl:call-template name="getIssuerIdentifier">
				<xsl:with-param name="issuer_dn" select="$client_issuer_DN"/>
				<xsl:with-param name="client_dn" select="$client_DN"/>
			</xsl:call-template>
		</xsl:variable>
	
		<xsl:message dp:priority="debug">
			Requested URI     : <xsl:value-of select="$req_uri"/>
			Requested Domain  : <xsl:value-of select="$req_domain"/>
			Configuration XML : <xsl:value-of select="$domain_config_path"/>
			Client DN         : <xsl:value-of select="$client_DN"/>
			Client CN         : <xsl:value-of select="$client_CN"/>
			Client Issuer DN  : <xsl:value-of select="$client_issuer_DN"/>
			Client Issuer ID  : <xsl:value-of select="$client_issuer_ID"/>
		</xsl:message>
		<xsl:variable name="svc_allow_list" select="$domain_config_xml/Services/Service[(@URL = $req_uri)]/allow"/>		
		
		<xsl:variable name="dn_match" select="boolean($svc_allow_list[not(@issuer) or (@issuer and translate(@issuer, $uppercase, $lowercase) = $client_issuer_ID)]/DN[text() = $client_DN])"/>
		<xsl:variable name="cn_match" select="boolean($svc_allow_list[not(@issuer) or (@issuer and translate(@issuer, $uppercase, $lowercase) = $client_issuer_ID)]/CN[text() = $client_CN])"/>
		
		<xsl:message dp:priority="debug">
			DN Match: <xsl:copy-of select="$dn_match"/>
			CN Match: <xsl:copy-of select="$cn_match"/>
		</xsl:message>
		
		<xsl:variable name="fullURIStatusCode">
			<xsl:call-template name="getMatchStatusCode">
				<xsl:with-param name="config_xml" select="$domain_config_xml"/>
				<xsl:with-param name="uri" select="$req_uri"/>
				<xsl:with-param name="dn" select="$client_DN"/>
				<xsl:with-param name="cn" select="$client_CN"/>
				<xsl:with-param name="issuer_ID" select="$client_issuer_ID"/>			
			</xsl:call-template>	
		</xsl:variable>
		
		<xsl:variable name="domainLevelURIStatusCode">
			<xsl:call-template name="getMatchStatusCode">
				<xsl:with-param name="config_xml" select="$domain_config_xml"/>
				<xsl:with-param name="uri" select="concat('/',$req_uri_components[1],'/', $req_uri_components[2])"/>
				<xsl:with-param name="dn" select="$client_DN"/>
				<xsl:with-param name="cn" select="$client_CN"/>
				<xsl:with-param name="issuer_ID" select="$client_issuer_ID"/>			
			</xsl:call-template>	
		</xsl:variable>
		
		<xsl:variable name="statusCode">
			<xsl:choose>
				<xsl:when test="not($domain_config_xml)">500</xsl:when>
				<xsl:when test="$topLevelURIStatusCode = 200 or $domainLevelURIStatusCode = 200">200</xsl:when>
				<xsl:otherwise>404</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		
		<xsl:variable name="statusMessage">
			<xsl:choose>
				<xsl:when test="$statusCode = '500'">Domain Configuration file not found.</xsl:when>
				<xsl:when test="$statusCode = '404'">No certificate DN or CN match in domain configuration file.</xsl:when>
				<xsl:when test="$statusCode = '200'">OK</xsl:when>
				<xsl:otherwise>Unknown Error</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		
		<xsl:choose>
			<xsl:when test="not($statusCode = 200)">
				<rejected>
					<error>
						<code><xsl:value-of select="$statusCode"/></code>
						<message><xsl:value-of select="$statusMessage"/></message>
					</error>
					<uri><xsl:value-of select="$req_uri"/></uri>
					<domain><xsl:value-of select="$req_domain"/></domain>
					<config><xsl:value-of select="$domain_config_path"/></config>
					<clientDN><xsl:value-of select="$client_DN"/></clientDN>
					<clientCN><xsl:value-of select="$client_CN"/></clientCN>
					<issuerDN><xsl:value-of select="$client_issuer_DN"/></issuerDN>
					<issuerId><xsl:value-of select="$client_issuer_ID"/></issuerId>
					<svcAllowList><xsl:copy-of select="$svc_allow_list"/></svcAllowList>
				</rejected>
			</xsl:when>	
			<xsl:when test="$statusCode = 200">
				<approved />
			</xsl:when>
		</xsl:choose>
	</xsl:template>
	
	
	<xsl:template name="getMatchStatusCode">
		<xsl:param name="config_xml"/>
		<xsl:param name="uri"/>
		<xsl:param name="dn"/>
		<xsl:param name="cn"/>
		<xsl:param name="issuer_ID"/>
		
		<xsl:variable name="allow_list" select="$config_xml/Services/Service[(@URL = $uri)]/allow"/>		
		
		<xsl:variable name="dn_match" select="boolean($allow_list[not(@issuer) or (@issuer and translate(@issuer, $uppercase, $lowercase) = $issuer_ID)]/DN[text() = $dn])"/>
		<xsl:variable name="cn_match" select="boolean($allow_list[not(@issuer) or (@issuer and translate(@issuer, $uppercase, $lowercase) = $issuer_ID)]/CN[text() = $cn])"/>
		
		<xsl:message dp:priority="debug">
			URI: <xsl:value-of select="$uri"/>
			DN Match: <xsl:copy-of select="$dn_match"/>
			CN Match: <xsl:copy-of select="$cn_match"/>
		</xsl:message>
	
		<xsl:choose>
			<xsl:when test="not($config_xml)">500</xsl:when>
			<xsl:when test="not($dn_match or $cn_match)">404</xsl:when>				
			<xsl:otherwise>200</xsl:otherwise>
		</xsl:choose>
	
	</xsl:template>
	
	<!--  
		Returns an identifier for a certificate's issuer, this is used to condense the various signer certificates
		into a single id that can be used in the domain config.xml.
		
		This template can be beefed up depending on the requirements
		
		Example: 'verisign' or 'self-signed'
	 -->
	
	<xsl:template name="getIssuerIdentifier">
		<xsl:param name="issuer_dn"/>
		<xsl:param name="client_dn"/>
		
		<xsl:choose>
			<xsl:when test="contains($issuer_dn,'VeriSign')">verisign</xsl:when>
			<xsl:when test="$issuer_dn = $client_dn">self-signed</xsl:when>
			<xsl:otherwise>unknown</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	
	
</xsl:stylesheet>
