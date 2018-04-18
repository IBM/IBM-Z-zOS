//BPXREALT JOB 'XXXXXX,D75,B7078','JOEUSER',CLASS=A,
//     MSGCLASS=A,MSGLEVEL=(1,1),NOTIFY=JOEUSER
//********************************************************************/
//* Copyright 2017 IBM Corp.                                         */
//*                                                                  */
//* Licensed under the Apache License, Version 2.0 (the "License");  */
//* you may not use this file except in compliance with the License. */
//* You may obtain a copy of the License at                          */
//*                                                                  */
//* http://www.apache.org/licenses/LICENSE-2.0                       */
//*                                                                  */
//* Unless required by applicable law or agreed to in writing,       */
//* software distributed under the License is distributed on an      */
//* "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,     */
//* either express or implied. See the License for the specific      */
//* language governing permissions and limitations under the         */
//* License.                                                         */
//********************************************************************/
//* Notes:  Run SMF Realtime sample program via BPXBATCH             */
//*                                                                  */
//********************************************************************/
//*  STEP 1 - Run test case                                          */
//*                                                                  */
//*    Note1: Change the /u/joeuser... in the PARM= parameters to be */
//*           the directory where you downloaded the smfreal.c       */
//*           source.                                                */
//*    Note2: for PARM= parameters to the shell, you must use an     */
//*           asterick on column 72 to properly continue the line.   */
//*           The continuation on the next line should start in      */
//*           column 16.                                             */
//*    Note3: The PARM= data is a max of 100 characters!             */
//********************************************************************/
//RUNTEST  EXEC PGM=BPXBATCH,TIME=NOLIMIT,REGION=0M,
// PARM='SH cd /u/joeuser/zAnalytics/smfreal; ./smfreal'
//*            Xcontinuation-starts-here'
//*
//STDOUT   DD   PATH='/tmp/ifaSmfreal.out',
//         PATHOPTS=(OWRONLY,OCREAT,OTRUNC),
//         PATHMODE=(SIRWXU)
//STDERR   DD   PATH='/tmp/ifaSmfreal.err',
//         PATHOPTS=(OWRONLY,OCREAT,OTRUNC),
//         PATHMODE=(SIRWXU)
//CEEDUMP  DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//SYSMDUMP DD SYSOUT=*
//********************************************************************/
//*  STEP 3 - Copy stdout back to joblog                             */
//********************************************************************/
//STEP3    EXEC PGM=IEBGENER
//SYSPRINT DD SYSOUT=*
//SYSUT1   DD   PATH='/tmp/ifaSmfreal.out',
//          FILEDATA=TEXT,PATHOPTS=ORDONLY,
//          LRECL=160,BLKSIZE=640,RECFM=FB
//SYSUT2   DD SYSOUT=*,
//          DCB=(RECFM=FB,LRECL=160,BLKSIZE=640)
//SYSIN    DD DUMMY
//********************************************************************/
//*  STEP 4 - Copy stderr back to joblog                             */
//********************************************************************/
//STEP4    EXEC PGM=IEBGENER
//SYSPRINT DD SYSOUT=*
//SYSUT1   DD   PATH='/tmp/ifaSmfreal.err',
//          FILEDATA=TEXT,PATHOPTS=ORDONLY,
//          LRECL=160,BLKSIZE=640,RECFM=FB
//SYSUT2   DD SYSOUT=*,
//          DCB=(RECFM=FB,LRECL=160,BLKSIZE=640)
//SYSIN    DD DUMMY
