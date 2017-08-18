//GRS87 JOB CLASS=U,NOTIFY=&SYSUID.,                                    00001000
//          MSGLEVEL=(1,1),LINES=200000,                                00020000
//          SYSTEM=*                                                    00021000
//*                                                                     00030000
//********************************************************************/ 00030100
//* Copyright 2017 IBM Corp.                                         */ 00030200
//*                                                                  */ 00030300
//* Licensed under the Apache License, Version 2.0 (the "License");  */ 00030400
//* you may not use this file except in compliance with the License. */ 00030500
//* You may obtain a copy of the License at                          */ 00030600
//*                                                                  */ 00030700
//* http://www.apache.org/licenses/LICENSE-2.0                       */ 00030800
//*                                                                  */ 00030900
//* Unless required by applicable law or agreed to in writing,       */ 00031000
//* software distributed under the License is distributed on an      */ 00031100
//* "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,     */ 00031200
//* either express or implied. See the License for the specific      */ 00031300
//* language governing permissions and limitations under the         */ 00031400
//* License.                                                         */ 00031500
//********************************************************************/ 00031600
//*-------------------------------------------------------------------- 00040000
//* ==> SET SMFOUT TO SMF WORK DATASET NAME                             00050000
//* ==> SET REPOUT TO REPORT DATASET NAME                               00060000
//*-------------------------------------------------------------------- 00070000
//       EXPORT SYMLIST=(SMFOUT,REPOUT)                                 00071000
//SET1    SET  SMFOUT=SMF87.WORK                                        00080000
//SET2    SET  REPOUT=SMF87.RPT.TXT                                     00090000
//*-------------------------------------------------------------------- 00100000
//* ==> DELETE WORK AND REPORT DATASETS                                 00110000
//*-------------------------------------------------------------------- 00120000
//KILL01   EXEC PGM=IDCAMS                                              00130000
//SYSPRINT DD SYSOUT=*                                                  00140000
//SYSIN DD *,SYMBOLS=JCLONLY                                            00141000
 DELETE &SMFOUT.                                                        00150000
 DELETE &REPOUT.                                                        00160000
 SET MAXCC=0                                                            00170000
/*                                                                      00180000
//*-------------------------------------------------------------------- 00190000
//* ==> START ISPF AND EXECUTE THE REXX                                 00200000
//*-------------------------------------------------------------------- 00210000
//READSMF   EXEC  PGM=IKJEFT01,REGION=0M                                00220000
//*                                                                     00230000
//ISPPROF  DD UNIT=SYSDA,SPACE=(TRK,(9,1,4)),                           00240000
//  DCB=(LRECL=80,BLKSIZE=3120,RECFM=FB,DSORG=PO),                      00250000
//  DISP=(NEW,PASS)                                                     00260000
//*                                                                     00270000
//*-------------------------------------------------------------------- 00280000
//ISPMLIB  DD DISP=SHR,DSN=SYS1.ISP.SISPMENU                            00290000
//         DD DISP=SHR,DSN=SYS1.ISF.SISFMLIB                            00300000
//ISPPLIB  DD DISP=SHR,DSN=SYS1.ISP.SISPPENU                            00310000
//         DD DISP=SHR,DSN=SYS1.ISF.SISFPLIB                            00320000
//ISPSLIB  DD DISP=SHR,DSN=SYS1.ISP.SISPSENU                            00330000
//*        DD DISP=SHR,DSN=SYS1.ISF.SISFSLIB                            00340000
//ISPTLIB  DD DISP=SHR,DSN=SYS1.ISP.SISPTENU                            00350000
//         DD DISP=SHR,DSN=SYS1.ISF.SISFTLIB                            00360000
//ISPLOG   DD DUMMY                                                     00370000
//* ---------------------------------------------------------------     00380000
//* ==> DUMPIN: SMF DATASET                                             00390000
//* ==> SYSIN:  RECORD TYPE, DAY AND TIME SELECTION                     00400000
//* ---------------------------------------------------------------     00410000
//DUMPIN1  DD DISP=SHR,DSN=SMF87.SMFDUMP,                               00420000
//  DCB=(LRECL=32756,BLKSIZE=32760,RECFM=VB,DSORG=PS)                   00420100
//DUMPOUT   DD    DISP=(,PASS),SPACE=(CYL,(800,200)),UNIT=SYSDA,        00430000
//          DSN=&&DP                                                    00440000
//SYSIN     DD    *                                                     00450000
INDD(DUMPIN1,OPTIONS(DUMP))                                             00460000
OUTDD(DUMPOUT,TYPE(87(2)))                                              00470000
/*                                                                      00471000
//*                                                                     00472000
//* DATE(2013334,2013334)                                               00480000
//* START(0000)                                                         00490000
//* END(0100)                                                           00500000
//*-------------------------------------------------------------------- 00520000
//SYSEXEC   DD    DISP=SHR,DSN=SMF87.EXEC                               00530000
//WORKSMF   DD    DSN=&SMFOUT,                                          00540000
//  DCB=(LRECL=32756,BLKSIZE=32760,RECFM=VB,DSORG=PS),                  00550000
//  DISP=(NEW,CATLG),                                                   00560000
//  STORCLAS=SCTEMP,                                                    00570000
//  SPACE=(CYL,(800,200),RLSE)                                          00580000
//OUTDS     DD    DSN=&REPOUT,                                          00590000
//  DCB=(LRECL=800,BLKSIZE=31200,RECFM=FB,DSORG=PS),                    00600000
//  DISP=(NEW,CATLG),                                                   00610000
//  STORCLAS=SCLARGE,                                                   00620000
//  SPACE=(CYL,(2500,250),RLSE),VOL=(,,,8),DSNTYPE=EXTPREF              00630000
//SYSTSPRT  DD    SYSOUT=*                                              00640000
//SYSPRINT  DD    SYSOUT=*                                              00650000
//*-------------------------------------------------------------------- 00660000
//* OPTIONS FOR GRS87RPT EXEC INCLUDE TEST, TIMES, DLM(,) AND SCOPE(S)  00661000
//*    WHERE DLM(C) SETS A DELIMITER CHAR BETWEEN COLS AND              00662000
//*      AND SCOPE(S) FILTERS ON SCOPE STEP, SYSTEM, SYSTEMS            00663000
//SYSTSIN   DD    *                                                     00670000
  EX 'SMF87.EXEC(GRS87RPT)' 'TIMES DLM(,)'                              00680000
/*                                                                      00690000
