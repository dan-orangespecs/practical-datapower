# practical-datapower

Practical DataPower is a set of articles on introducing immediate productivity into the IBM DataPower Gateway environment. 

More information on the series can be found at Orange Specs Consulting: http://www.orangespecs.com/category/practical-datapower

## IBM DataPower Gateway HTTPS Authorization Proxy Service

This is an implementation of the HTTPS authorization proxy service, a cornerstone of a DataPower environment. 
It authenticated and authorizes clients via TLS certificates against an XML whitelist of accepted CN/DN/Signer/Environment pairs.

### Installation

A domain export of the service can be found in the export folder. The Domain is named 'OSC_PD_SSLService'.

https://github.com/dan-orangespecs/practical-datapower/raw/master/OSC_SSL_Service/export/OSC_PD_SSLService_Domain.zip


### Tests

#### Test Certificates

Test certificates used in the sample configuration can be found here:

https://github.com/dan-orangespecs/practical-datapower/tree/master/OSC_SSL_Service/tls

#### Test Cases

Test cases are provided as a JSON file that can be imported into DHC ( https://dhc.restlet.com/ )

https://github.com/dan-orangespecs/practical-datapower/raw/master/OSC_SSL_Service/tests/OSC_PD_SSLService_Test_DHC.json



## IBM DataPower Gateway Stub Service

This is an implementation of a stub service for the IBM DataPower Gateway appliance. It returns
pre-canned responses to request messages. This is useful when the project has a dependency on 
a service that has isn't own internal development schedule and is not ready to consume messages. In 
lieu of the real service, point the client to the stub and have the stub return a valid response.

More information on the stub service can be found at http://www.orangespecs.com/datapower-stub-service/ 

### Installation

A domain export of the service can be found in the export folder. The Domain is named 'OSC_PD_Stub'.

https://github.com/dan-orangespecs/practical-datapower/blob/master/OSC_PD_Stub/export/OSC_PD_Stub.zip?raw=true


### Tests

Tests are provided as a JSON file that can be imported into DHC ( https://dhc.restlet.com/ )

https://github.com/dan-orangespecs/practical-datapower/blob/master/OSC_PD_Stub/tests/DHC-OSC-PD-Stub-Tests.json





