## README 
```
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
```
This is a simple example application to use the SMF Real-Time          
services using a C program.                                            
```                                                                       
Files:                                                                 
       smfrealc      (application)                                     
       smfrealh      (header, mappings)                                
       buildtst      (sample compile and link-edit USS script)         
       BPXREALT      (JCL sample to run smfreal in batch)              
       $OUTPUT       (output from a run collecting 50 records)         
```                                                                       
This is an `as-is` type sample to demonstrate usage of                 
SMF data through this interface. This example will obtain SMF 30 
type records from an in-memory real-time resource and then do       
something with those records.              
                                                                       
Before getting started, modify the program if necessary.               
For example, the program is hard-coded to collect SMF records from     
the `IFASMF.INMEM` resource. You can change this in the program to     
match your existing SMF 30 in-memory resource name, or set up     
one on your system. Additionally, the `main()` function could be      
altered to accept parms, such as a resource name, which will prevent   
the need to change it in the program code.                             
                                                    
The remainder of this `README` contains two sets of instructions for
compiling and running this sample:  One set of instructions that
uses a UNIX System Services (USS) file system, and one set that 
works exclusively with MVS data sets. Use the set that is more
appropriate to your installation and experience.													
                                                                       
To build and run this sample in USS:
                                                                       
  1) Create a USS directory and load all the above files into it.        
                                                                       
       o Ensure you rename SMFREALC to smfreal.c                         
       o SMFREALH to smfreal.h                                           
       o BUILDTST to buildTst                                            
       o Note the USS and C environments are case sensitive              
                                                                      
  2) Issue a `chmod 755 buildTst`. This will make the compile          
     script executable.                                                  
                                                                       
  3) Run `buildTst` (by typing `buildTst`) to compile and link             
     the smfreal program.                                                
                                                                       
  4) Check the listings for errors.  I suggest you check `smfreal_2.lst`   
     first, as this will just show errors.  The compile and link should  
     complete without errors.                                            
                                                                      
      o Note:  The IFAIMxxx services in SYS1.CSSLIB should be in         
               the linklist or equivalent.                               
                                                                       
  5) Ensure that you have the smfreal program now in your directory.     
                                                                       
  6) Execute the program either via command line (just type `smfreal`)     
     or via batch job (example provided).                                
                     
					 
					 
To build and run this sample using MVS data sets:
																	   
SMF Realtime C Sample Program

1) Store the Code
2) Compile / Bind JCL
3) Run and Results


1: Store the code in an MVS PDS or PDSE data set, such as the following:
```
		JOEUSER.SMFREAL.CSAMP(SMFREALC) 
		JOEUSER.SMFREAL.CSAMP(SMFREALH) 
```
2: Compile / Bind JCL
```
//BINDC64  JOB NOTIFY=????????,                                          
// REGION=0M,MSGLEVEL=1,MSGCLASS=H                                      
//*                                                                     
//* LOCATION OF SAMPLE SOURCE AND OUTPUT DATASETS.                      
//  SET SRC=SMFREALC                               < INPUT ... REQUIRED       
//  SET TARGET=SMFREALC                            < TARGET NAME              
//  SET SRCLIB=JOEUSER.SMFREAL.CSAMP               < INPUT SRC LIBRARY        
//  SET LOADLIB=JOEUSER.PDSE.LOAD                  < OUTPUT LOAD MODULE       
//  SET LISTLIB=JOEUSER.LISTCPP                    < OUTPUT LISTING           
//* C COMPILER OPTIONS                                                  
//  SET CRUN=                                                           
//  SET CPARM='SSCOM,LIS,LO,RENT,DLL,LP64,XPLINK'                       
//* BINDER OPTIONS.                                                     
//  SET BPARM='AMODE=64,RENT,MAP,DYNAM=DLL,CASE=MIXED,LIST=NOIMP'       
//* LOCATION OF C LIBRARIES REQUIRED FOR COMPILE, PRE-LINK AND LINK.    
//  SET LIBPRFX='SYS1.CEE'                                         < PREFIX FOR LIBRARY DSN   
//  SET LNGPRFX='SYS1.CBC'                                         < PREFIX FOR LANGUAGE DSN  
//* DATASET ATTRIBUTES FOR TEMPORARY FILES.                             
//  SET SYSLBLK='3200'                                             < BLOCKSIZE FOR &&LOADSET  
//  SET DCB80='(RECFM=FB,LRECL=80,BLKSIZE=3200)' <DCB FOR LRECL 80      
//  SET DCB3200='(RECFM=FB,LRECL=3200,BLKSIZE=12800)' < DCB LRECL 3200  
//  SET TUNIT='SYSDA'                                               < UNIT FOR TEMPORARY FILES
//  SET TSPACE='(32000,(30,30))'                                    < SIZE FOR TEMPORARY FILES
//*-------------------------------------------------------------------  
//*  COMPILE STEP:                                                      
//*-------------------------------------------------------------------  
//COMPILE EXEC PGM=CCNDRVR,                                             
//    PARM=('&CRUN/&CPARM'),COND=(8,LT)                                 
//*                                                                     
//* STEPLIB DD SPECIFIES THE LOCATION OF THE COMPILER AND RUNTIME       
//* LIBRARIES.                                                          
//*                                                                     
//STEPLIB  DD  DSN=&LIBPRFX..SCEERUN2,DISP=SHR                          
//         DD  DSN=&LNGPRFX..SCCNCMP,DISP=SHR                           
//         DD  DSN=&LIBPRFX..SCEERUN,DISP=SHR                           
//*                                                                                                                                                                                                 
//SYSLIB   DD  DSN=JOEUSER.SMFREAL.CSAMP(SMFREALH),DISP=SHR                                       
//*                                                                     
//* SYSIN DD SPECIFIES THE SOURCE MEMBER TO BE COMPILED.                
//*                                                                     
//SYSIN    DD  DSN=&SRCLIB(&SRC),DISP=SHR                               
//*                                                                     
//* SYSLIN DD SPECIFIES THE OUTPUT LOCATION OF THE OBJECT MODULE        
//* GENERATED BY THE COMPILE STEP.                                      
//*                                                                     
//SYSLIN   DD  DSN=&&LOADSET,UNIT=&TUNIT.,                              
//             DISP=(MOD,PASS),SPACE=(TRK,(3,3)),                       
//             DCB=(RECFM=FB,LRECL=80,BLKSIZE=&SYSLBLK)                 
//SYSPRINT DD  SYSOUT=*                                                 
//SYSCPRT  DD  DSN=&LISTLIB(&SRC),DISP=SHR                              
//*                                                                     
//*-------------------------------------------------------------        
//* BINDER STEP:                                                        
//*-------------------------------------------------------------        
//BIND  EXEC PGM=IEWL,PARM='&BPARM'                                     
//SYSLIB   DD  DSN=&LIBPRFX..SCEEBND2,DISP=SHR                          
//         DD  DSN=&LIBPRFX..SCEERUN2,DISP=SHR                          
//         DD  DSN=&LIBPRFX..SCEERUN,DISP=SHR                           
//         DD  DSN=SYS1.CSSLIB,DISP=SHR                                 
//SYSLIN   DD  DSN=*.COMPILE.SYSLIN,DISP=(MOD,DELETE)                   
//         DD  DSN=&LIBPRFX..SCEELIB(CELQSCPP),DISP=SHR                 
//         DD  DSN=&LIBPRFX..SCEELIB(CELQS003),DISP=SHR                 
//         DD  DSN=&LNGPRFX..SCLBSID(IOSX64),DISP=SHR                   
//         DD  DSN=&LNGPRFX..SCLBSID(IOSTREAM),DISP=SHR                 
//SYSLMOD  DD  DSN=&LOADLIB(&TARGET),DISP=SHR                           
//SYSPRINT DD  SYSOUT=*                                                 
```
It is worth mentioning that `SMFREALTIME` requires code to be compiled
in 64 bit mode. When working with 64 bit code, you must invoke the 
Binder (IEWL) instead of link editing. The output loadlib must be a 
PDSE.

3: Run and results
	Submit JCL to execute the program SMFREALC. Ensure that your 
	system is configured to generate the SMF records being defined 
	as collected by your SMFPRMXX member, as the SMFREALC program 
	will make blocking get requests. This will appear to hang the 
	program until 49 records are retrieved from the INMEM resource.
```
--------- SMFREAL start ---------
Initialize RC=0                               
CONNECT attempt to IFASMF.INMEM begins now...
CONNECT attempt made.                         
Connect RC=0000 RSN=0000                      
Validating connect token, RC=0                
GET attempt begins now...                     
GET attempt made.                             
Get RC=0000 RSN=0000                          
Record(0) was retrieved:                      
  Record Length: 36, Record Type: 127         
GET attempt begins now...                     
GET attempt made.                             
Get RC=0000 RSN=0000
...                          
Record(49) was retrieved:             
  Record Length: 36, Record Type: 127
DISCONNECT attempt begins now...      
DISCONNECT attempt made.              
Disconnect RC=0000 RSN=0000           
--------- SMFREAL end -----------   
```													   
