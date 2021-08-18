## README 
```
** Beginning of Copyright and License **

Copyright 2021 IBM Corp.                                           
                                                                    
Licensed under the Apache License, Version 2.0 (the "License");    
you may not use this file except in compliance with the License.   
You may obtain a copy of the License at                            
                                                                    
http://www.apache.org/licenses/LICENSE-2.0                         
                                                                   
Unless required by applicable law or agreed to in writing, software 
distributed under the License is distributed on an "AS IS" BASIS,  
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  
See the License for the specific language governing permissions and  
limitations under the License.                    

** End of Copyright and License **        
```

## Overview

These Java classes provide formatting support for selected WebSphere
Application Server on z/OS SMF records.  WebSphere uses the
Type 120 record.  Support is provided for the following subtypes

- 9 - written for each request processed by a servant region 
- 10 - written for a WOLA outbound request from a servant region
- 11 - written for an HTTP request processed by Liberty
- 12 - written for end of job, step, split, and flow of a Java Batch job running inside Liberty

More information about these records can be found in the WebSphere documentation as well
as in these whitepapers

- [https://www.ibm.com/support/pages/node/6355123](https://www.ibm.com/support/pages/node/6355123)  (120-9 and 120-10)
- [https://www.ibm.com/support/pages/node/6355589](https://www.ibm.com/support/pages/node/6355589)  (120-11)
- [https://www.ibm.com/support/pages/node/6355595](https://www.ibm.com/support/pages/node/6355595)  (120-12)

Support for older WebSphere SMF subtypes (less than 9) may still be available
via the original "SMF Browser" which may still be found here:
[https://www14.software.ibm.com/webapp/iwm/web/preLogin.do?source=zosos390](https://www14.software.ibm.com/webapp/iwm/web/preLogin.do?source=zosos390).

The following system properties  can act as filters on the records processed.

**com.ibm.ws390.smf.smf1209.matchServer** – for 120-9 records, only records from the named server will be processed

**com.ibm.ws390.smf.smf1209.matchSystem** – for 120-9 records, only records from the named z/OS image will be processed

**com.ibm.ws390.smf.smf1209.excludeInternal** – set to true, some reports will ignore 120-9 records for internal requests

**com.ibm.ws390.smf.smf1209.RespRatioMin** - specifies a minimum WLM response ratio in the 120-9 or 120-11 records


Compilation and execution of these classes requires the SMF_CORE project from this
same github repository.  See the readme for that project for information about invocation syntax.



