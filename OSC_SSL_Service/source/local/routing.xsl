<?xml version="1.0"?>
<!-- 
	@author: Dan Zrobok
	@company: Orange Specs Consulting (www.orangespecs.com)
	
	This styleshee routes authorized requests to the backend service specified
	in the config.xml for the URI. 
	
	It is assumed this backend service is exposed as another DataPower service over
	HTTP (preferably, 127.0.0.1).  
	
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
		
		<xsl:variable name="config_file_path" select="concat('./',$req_config_id, '/config.xml')"/>
		<xsl:variable name="config_file_xml" select="document($config_file_path)"/>
		
		<xsl:variable name="generic_uri" select="concat('/',$req_uri_components[1],'/', $req_uri_components[2])"/>
		
		<xsl:variable name="generic_endpoint" select="$config_file_xml/services/service[(@url = $generic_uri) and ((@env = $dp_env) or not(@env))]"/>			
		<xsl:variable name="full_svc_endpoint" select="$config_file_xml/services/service[(@url = $req_uri) and ((@env = $dp_env) or not(@env))]"/>

		<xsl:choose>
			<xsl:when test="$full_svc_endpoint/endpoint">
				<dp:xset-target host="$full_svc_endpoint/endpoint/hostname" port="$full_svc_endpoint/endpoint/port" ssl="false()" sslid=""/>
			</xsl:when>
			<xsl:when test="not($full_svc_endpoint) and $generic_endpoint/endpoint">
				<dp:xset-target host="$generic_endpoint/endpoint/hostname" port="$generic_endpoint/endpoint/port" ssl="false()" sslid=""/>
			</xsl:when>
			<xsl:otherwise>
				<dp:reject>No routing information for the URI '<xsl:value-of select="$req_uri"/>' was found.</dp:reject>
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