//IZBSSYSA JOB 'xxxxxx,?',                                              00001000
//  'KEVIN KELLEY',REGION=0M,                                           00002000
//  MSGLEVEL=(1,1),CLASS=B,NOTIFY=KKELLEY,                              00003000
//  MSGCLASS=I                                                          00004000
//* ******************************************************************* 00005000
//* IZB Informatik-Zentrum           System SYSA IPL                  * 00006000
//*                                  z/OS R8                          * 00006100
//*                                  2094   6 CPs                     * 00006201
//*                                  2008/07/26  08208                * 00006301
//* ******************************************************************* 00006400
/*JOBPARM LINES=200                                                     00006500
//* ******************************************************************* 00006800
//*-------------------------------------------------------------------* 00006900
//* FORM, FONT, PAGEDEF AND WIDTH DEFINITIONS.                        * 00007000
//*-------------------------------------------------------------------* 00008000
//*                 FORM:     NAR           STD            WIDE       * 00009000
//*                       9.5" X 11"      12" X 8.5"   14.88" X 11"   * 00010000
//* FONT              WIDTH  PAGEDEF  WIDTH  PAGEDEF  WIDTH  PAGEDEF  * 00020000
//* GT10 - 10 CHAR/INCH  85  P108080    110  P108081    140  P1L08080 * 00030000
//* GT12 - 12 CHAR/INCH 102  P108080    132  P108081    168  P1L08080 * 00040000
//* GT13 - 13 CHAR/INCH 110  P108080    143  P108081    182  P1L08080 * 00050000
//* GT15 - 15 CHAR/INCH 127  P1100A0    165  P1100A1    210  P1L100A0 * 00060000
//* GT18 - 18 CHAR/INCH 153  P1100A0    198  P1100A1    252  P1L100A0 * 00070000
//* GT20 - 20 CHAR/INCH 170  P1120C0    220  P1100A1*   280  P1L120C0 * 00071000
//*-------------------------------------------------------------------* 00072000
//STDOUT   OUTPUT CLASS=I,FORMS=STD,JESDS=ALL,COPIES=1,                 00073000
//             CHARS=CR15,PAGEDEF=100A1                                 00073100
//SMALLOUT OUTPUT CLASS=I,FORMS=STD,COPIES=1,                           00073200
//             CHARS=GT20,PAGEDEF=L120C0                                00073300
//MSGRATE   EXEC PGM=MSGLG610,REGION=8M                                 00073400
//STEPLIB   DD DSN=KKELLEY.MSGLGPGM.LOAD,DISP=SHR                       00073500
//OPTIN     DD *                                                        00073600
TITLE: IZB Informatik-Zentrum system SYSA IPL                           00073701
* KKELLEY.IZB.SYSA.SYSLOG                                               00073801
OFFSET(1)    - shift record rightward to add carriage control           00073901
YEAR4        - compensate for 4-digit year field
SAMPLSTR(08209012904)       -- start of IPL                             00074501
* SAMPLEND(08209012904)     -- end of IPL (guess)                       00075001
REPORT(ALL)
IPLSTATS                                                                00075200
* RATEMSGS(ALL)                                                         00075500
* IMSGINTV(5)                         1 hour intervals                  00075600
* IMSGSCAL(RELATIVE)                                                    00075700
//*-------------------------------------------------------------------* 00075800
//*  INPUT DATA                                                       * 00075900
//*-------------------------------------------------------------------* 00076000
//DATA     DD DSN=KKELLEY.IZB.SYSA.SYSLOG,DISP=SHR                      00076101
//TTLLIB   DD DSN=KKELLEY.MSGRTDB.TBLS,DISP=SHR                         00076200
//SYSPRINT DD SYSOUT=(,),OUTPUT=(*.STDOUT)                              00076300
//*-------------------------------------------------------------------* 00076400
//*  IF USED, THE FOLLOWING DD'S SHOULD HAVE:  OUTPUT=(*.STDOUT)      * 00076500
//*-------------------------------------------------------------------* 00076600
//PRNTOUT  DD SYSOUT=(,),OUTPUT=(*.STDOUT)                              00076700
//COMPRATE DD SYSOUT=(,),OUTPUT=(*.SMALLOUT)                            00076800
//COMPMSG  DD SYSOUT=(,),OUTPUT=(*.SMALLOUT)                            00076900
//IPLST    DD SYSOUT=(,),OUTPUT=(*.STDOUT)                              00077000
//IPLSQ    DD SYSOUT=(,),OUTPUT=(*.STDOUT)
//UNKNOWN  DD DUMMY                                                     00077100
//PREVIEW  DD DUMMY                                                     00077200
//IMSGRATE DD SYSOUT=(,),OUTPUT=(*.SMALLOUT)                            00077300
//BURST    DD DUMMY                                                     00077400
//*-------------------------------------------------------------------* 00077500
//*  The following DD's are used to dump internal tables for reuse.   * 00077600
//*  All of them are: RECFM=F,LRECL=240                               * 00077700
//*  ----> IF USED, 'DUMPRATE' -MUST- HAVE A DISP OF 'MOD' <----      * 00077800
//*-------------------------------------------------------------------* 00077900
//DUMPCNT   DD DUMMY                                                    00078000
//DUMPMSG   DD DSN=&&DBMSGIN,UNIT=SYSDA,                                00078100
//             DCB=(RECFM=F,LRECL=240,BLKSIZE=240),                     00078200
//             SPACE=(TRK,(25,5)),DISP=(NEW,PASS)                       00078300
//DUMPCMD   DD DUMMY                                                    00078400
//DUMPRATE  DD DSN=&&DBRTIN,UNIT=SYSDA,                                 00078500
//             DCB=(RECFM=F,LRECL=240,BLKSIZE=240),                     00078600
//             SPACE=(TRK,(50,25)),DISP=MOD                             00078700
//DUMPIPLS  DD DSN=&&DBIPLIN,UNIT=SYSDA,                                00078800
//             DCB=(RECFM=F,LRECL=240,BLKSIZE=240),                     00078900
//             SPACE=(TRK,(25,5)),DISP=(NEW,PASS)                       00079000
//OUT       DD DUMMY                                                    00079100
