README 

** Beginning of Copyright and License **

Copyright 2017 IBM Corp.                                           
                                                                    
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

PURPOSE

This tool can be used to format SMF 87 subtype 2 records, into a table/CSV file where each
row represents either an ENQ or a DEQ request.

INSTRUCTIONS 
 
1) Customize the GRS87 driver JCL so that the data sets correspond with the locations of 
the GRS87RPT REXX exec (SYSEXEC and SYSTSIN DDs) and input, output, and work data sets 
(SMFOUT and REPOUT symbols and DUMPIN1 DD). Ensure the data set High-Level Qualifiers are 
appropriate for your security access.
2) If desired, customize input parameters to GRS87RPT.
3) Ensure the Job Card in the JCL meets any standards for your installation.
4) Submit the JCL.

INPUT/OUTPUT DDs FOR GRS87:
DUMPIN1 - input smf data sets
SMFOUT - working data set for just SMF 87-2 records
REPOUT - output report data set. This contains the table/csv file.

INPUT PARAMETERS TO GRS87RPT:

1) TEST - include test ENQs. Default: they are not included.
2) TIMES - include ENQ start and end times. Default: they are not included.
3) SCOPE(x) - only return ENQ/DEQs with SCOPE x where x can be STEP, SYSTEM, or SYSTEMS. 
   Only one value supported. Default: return all scopes.
4) DLM(d) - d is a character which delimits columns. Default: single space. 