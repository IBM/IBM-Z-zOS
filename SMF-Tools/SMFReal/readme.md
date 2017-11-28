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

This is a simple example application to use the SMF Real-Time          
services using a C program.                                            
                                                                       
Files:                                                                 
       smfrealc      (application)                                     
       smfrealh      (header, mappings)                                
       buildtst      (sample compile and link-edit USS script)         
       BPXREALT      (JCL sample to run smfreal in batch)              
       $OUTPUT       (output from a run collecting 50 records)         
                                                                       
This is an "as-is" type sample to demonstrate usage of                 
SMF data through this interface.   The customer that requested         
this example specifically requested that we obtain SMF 30 type         
records from an in-memory real-time resouce and then do something      
with those records.  So this example reflects that request.            
                                                                       
Before getting started, modify the program if necessary.               
For example, the program is hard-coded to collect SMF records from     
the "IFASMF.INMEM" resource. You can change this in the program to     
match your existing SMF 30 in-memory resource name, or just set up     
one on your system.    Additionally, the main() function could be      
altered to accept parms, such as a resource name, which will prevent   
the need to change it in the program code.                             
                                                                       
                                                                       
To build and run this sample:                                          
                                                                       
1) Create a USS directory and load all the above files into it.        
                                                                       
     o Ensure you rename SMFREALC to smfreal.c                         
     o SMFREALH to smfreal.h                                           
     o BUILDTST to buildTst                                            
     o Note the USS and C environments are case sensitive              
                                                                       
2) Issue a "chmod 755 buildTst".   This will make the compile          
   script executable.                                                  
                                                                       
3) Run buildTst (by typing "buildTst") to compile and link             
   the smfreal program.                                                
                                                                       
4) Check the listings for errors.  I suggest you check smfreal_2.lst   
   first, as this will just show errors.  The compile and link should  
   complete without errors.                                            
                                                                       
    o Note:  The IFAIMxxx services in SYS1.CSSLIB should be in         
             the linklist or equivelent.                               
                                                                       
5) Ensure that you have the smfreal program now in your directory.     
                                                                       
6) Execute the program either via command line (just type smfreal)     
   or via batch job (example provided).                                
                                                                       