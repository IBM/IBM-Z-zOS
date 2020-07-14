
# User Key Common Area Analyzer

** Beginning of Copyright and License **

Copyright 2020 IBM Corp.

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

** End of Copyright and License **

## PURPOSE

Allowing programs to obtain user key (8-15) common storage creates a security risk. Even if fetch protected, the storage can be modified or referenced by any unauthorized program from any address space. Therefore, it is recommended that you eliminate all use of user key common storage in z/OS V2R3. The allocating, obtaining, or changing common areas of virtual storage, such that the storage is in user key (8-15), will not be supported after z/OS V2R3.

The following DIAGxx parmlib statements will not be supported after z/OS V2R3:

1. VSM ALLOWUSERKEYCSA(YES)
   This setting is not recommended for z/OS V2R3. Specify NO or accept the default of NO.

2. ALLOWUSERKEYCADS(YES)
   This setting is the current default for z/OS V2R3. After z/OS V2R3, only the following setting will be allowed: ALLOWUSERKEYCADS(NO).

3. NUCLABEL ENABLE(IARXLUK2)
   This setting is the current default for z/OS V2R3. After z/OS V2R3, only the following setting will be allowed: NUCLABEL DISABLE(IARXLUK2).

The SMF30 formatter will provide assistance in migration to z/OS V2R4 by identifying address spaces accessing these areas.
The Formatter reads the SMF30 subtype 2 and subtype 3 to format the following fields :

1. SMF30_UserKeyCsaUsage
2. SMF30_UserKeyChangKeyUsage
3. SMF30_UserKeyCadsUsage

## INSTRUCTIONS

1. Download the file USER_KEY_COMMON_AREA.TRS and FTP with LRECL 1024 and FB

2. Unterse ths USER_KEY_COMMON_AREA.TRS <br> 

   Sample JCL to Unterse : <br>
<br> //UNTERPDS EXEC PGM=TRSMAIN,PARM=UNPACK
<br> //SYSPRINT DD SYSOUT=*
<br> //INFILE   DD DSN=<USER_KEY_COMMON_AREA.TRS>,
<br> //            DISP=SHR
<br> //OUTFILE  DD DSN=<UNTERSED PDS>,
<br> //            DISP=(NEW,CATLG),
<br> //            SPACE=(CYL,(10,10,10))

3. Upon Untersing you will receive the following 2 members :
   - SMF30RPT
   - SMF30JCL

4. Collect the SMF data to be formatted using IFASMFDP.

5. Tailoring the SMF30JCL Member :
   - Replace the LIB DATASET with the Dataset where the REXX Exec resides. 
   - Replace the SMF DATASET with the Dump Dataset containing SMF30 Subtype 2 and 3. <br>
   <br> //STEPNAME EXEC PGM=IKJEFT1B,PARM='%SMF30RPT'
   <br> //SYSPROC  DD DSN=LIB DATASET,DISP=SHR
   <br> //SYSTSPRT DD SYSOUT=*
   <br> //SYSTSIN  DD DUMMY
   <br> //SMFIN DD DSN=SMF DATASET,DISP=SHR

6. Submit SMF30JCL
