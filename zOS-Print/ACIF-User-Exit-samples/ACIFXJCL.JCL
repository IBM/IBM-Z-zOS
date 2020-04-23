//* Sample ACIF JCL for using exits *//
//APKSMAIN EXEC PGM=APKACIF,REGION=00M
//**************************************************************/  
//* Licensed under the Apache License, Version 2.0 (the        */  
//* "License"); you may not use this file except in compliance */  
//* with the License. You may obtain a copy of the License at  */  
//*                                                            */  
//* http://www.apache.org/licenses/LICENSE-2.0                 */  
//*                                                            */  
//* Unless required by applicable law or agreed to in writing, */  
//* software distributed under the License is distributed on an*/  
//* "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY     */  
//* KIND, either express or implied.  See the License for the  */  
//* specific language governing permissions and limitations    */  
//* under the License.                                         */  
//*------------------------------------------------------------*/  
//*                                                            */  
//*   COPYRIGHT (C) 1993,2007 IBM CORPORATION                  */  
//*   COPYRIGHT (C) 2007,2018 RICOH COMPANY, LTD               */  
//**************************************************************/
//*===============================================================*
//* RUN ACIF, CREATING OUTPUT AND A RESOURCE LIBRARY              *
//*===============================================================*
//INPUT DD  DISP=SHR,DSN=<my input file>
//SYSIN DD *
 /* ACIF user exit example */
 CC = YES                /*  carriage control used    */
 CCTYPE = A              /* carriage control type    */
 CPGID = 500             /* code page identifier     */
 EXTENSIONS = MVSICNV    /* initialize CEEPIPI environment for exits*/
 FDEFLIB= ...
 FONTLIB= ...
 FORMDEF  = F1xxxxx      /* formdef name              */
 INDEXDD= INDEX          /* index file ddname         */
 INPUTDD= INPUT          /* input file ddname         */
 MCF2REF= CF             /* codepage/charset or coded font */
 OUTPUTDD = OUTPUT       /* output file ddname        */
 OVLYLIB= ..
 PAGEDEF  = ...
 PDEFLIB= ...
 PSEGLIB= ...
 RESFILE = SEQ           /* resource file type        */
 RESEXIT = APKRSLST      /* use resource exit*/
 RESOBJDD = resdd        /* resource file ddname      */
 RESTYPE  = ALL          /* resource type selection   */
 /* other ACIF control statements as desired */
/*
//OUTPUT DD DSN=<my>.OUTPUT,DISP=(NEW,CATLG),
//         SPACE=(32760,(150,150),RLSE),UNIT=SYSDA,
//         DCB=(LRECL=32756,BLKSIZE=32760,RECFM=VBM,DSORG=PS)
//INDEX DD DSN=<my>.INDEX,DISP=(NEW,CATLG),
//         SPACE=(32760,(15,15),RLSE),UNIT=SYSDA,
//         DCB=(LRECL=32756,BLKSIZE=32760,RECFM=VBM,DSORG=PS)
//RESLIB DD DSN=<my>.RESLIB,DISP=(NEW,CATLG),
//         SPACE=(32760,(900,150),RLSE),UNIT=SYSDA,
//         DCB=(LRECL=32756,BLKSIZE=32760,RECFM=VBM,DSORG=PS)
//SYSPRINT DD SYSOUT=*,
//         DCB=(BLKSIZE=141,RECFM=VBA,DSORG=PS)
//SYSOUT   DD  SYSOUT=*             * FOR COBOL EXITS
//SYSABOUT DD  SYSOUT=*             * FOR COBOL EXITS
//SYSUDUMP DD  SYSOUT=*
//CEEDUMP  DD  SYSOUT=*
