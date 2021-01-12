//KKELLEYD  JOB 'Y4004P,Y40,?','KEVIN KELLEY',                          00010004
//             CLASS=B,MSGLEVEL=(1,1),NOTIFY=KKELLEY                    00020000
//* ******************************************************************* 00030000
//*            E.I. DUPONT                                            * 00040000
//*                                          8 DAYS                   * 00050000
//*            MVS/XA 2.1.7 8606 LEVEL                                * 00060000
//*            JES3   2.1.5 8603 LEVEL                                * 00070000
//*                                                                   * 00080000
//*            SY2  3090-200  JES3 GLOBAL, CICS                       * 00090000
//*            SY3  3090-200  BACK-UP, BATCH, TEST                    * 00100000
//*            SY4  3090-200  TSO                                     * 00110000
//*            SY8  3090-200  IMS                                     * 00120000
//*                                                                   * 00130000
//* ******************************************************************* 00140000
/*JOBPARM LINES=200                                                     00150000
/*SETUP    TAPE=PJ2355                                                  00160000
/*SETUP    TAPE=ZOW21A                                                  00170000
/*MESSAGE  TAPE 'PJ2355' IS NOT A MYERS CORNERS CARTRIDGE               00180000
/*MESSAGE  TAPE 'ZOW21A' IS NOT A MYERS CORNERS CARTRIDGE               00190000
//*                                                                     00200000
//* ******************************************************************* 00210000
//*            ALL MESSAGES.                                          * 00220000
//* ******************************************************************* 00230000
//STDOUT   OUTPUT CLASS=I,FORMS=STD,JESDS=ALL,                          00240003
//             CHARS=GT20,FCB=STDC,COPIES=1                             00241007
//MSGRATE   EXEC PGM=MSGLG212,REGION=5000K                              00250000
//STEPLIB   DD DSN=KKELLEY.MSGLGPGM.LOAD,DISP=SHR                       00260000
//OPTIN     DD *                                                        00270000
TITLE: E.I. DUPONT   4-WAY 3090-200 JES3 COMPLEX                        00280000
LOGTYPE(DLOG)                                                           00290000
REPORT(ALL)                                                             00300000
RATEMSGS(ALL)                                                           00310000
//*-------------------------------------------------------------------* 00320000
//*   'DUMPTBL(MSG,RATE)' SHOULD BE SPECIFIED AS AN OPTION IF         * 00330000
//*   STATISTICAL DATA IS BEING COLLECTED FOR RETURN TO IBM.          * 00340000
//*-------------------------------------------------------------------* 00350000
//DATA     DD UNIT=3480,VOL=SER=PJ2355,LABEL=(1,SL),                    00360000
//            DSN=XDCK.SYSLOG.HISTORY,                                  00370000
//            DCB=(RECFM=FB,LRECL=133,BLKSIZE=13300),                   00380000
//            DISP=OLD                                                  00390000
//         DD UNIT=3480,VOL=SER=ZOW21A,LABEL=(1,SL),                    00400000
//            DSN=XDCK.SYSLOG.HISTORY,                                  00410000
//            DCB=(RECFM=FB,LRECL=133,BLKSIZE=13300),                   00420000
//            DISP=OLD                                                  00430000
//TTLLIB    DD DSN=KKELLEY.MSGLGTBL.TEXT,DISP=SHR                       00431006
//SYSUDUMP  DD SYSOUT=(I,,WIDE),CHARS=DUMP                              00440003
//SYSPRINT  DD SYSOUT=(,),OUTPUT=(*.STDOUT)                             00450000
//*-------------------------------------------------------------------* 00460000
//*  IF USED, THE FOLLOWING DD'S SHOULD HAVE:  OUTPUT=(*.STDOUT)      * 00470000
//*-------------------------------------------------------------------* 00480000
//PRNTOUT   DD SYSOUT=(,),OUTPUT=(*.STDOUT)                             00490000
//COMPRATE  DD SYSOUT=(,),OUTPUT=(*.STDOUT)                             00500000
//COMPMSG   DD SYSOUT=(,),OUTPUT=(*.STDOUT)                             00510000
//UNKNOWN   DD DUMMY                                                    00520000
//PREVIEW   DD SYSOUT=(,),OUTPUT=(*.STDOUT)                             00530000
//IMSGRATE  DD DUMMY                                                    00540000
//BURST     DD DUMMY                                                    00550000
//*-------------------------------------------------------------------* 00560000
//*  THE FOLLOWING DD'S ARE USED TO DUMP INTERNAL TABLES FOR REUSE.   * 00570000
//*                                                                   * 00580000
//*  ----> IF USED, 'DUMPRATE' -MUST- HAVE A DISP OF 'MOD' <----      * 00590000
//*                                                                   * 00600000
//*  THE 'DUMPMSG' DD AND 'DUMPRATE' DD SHOULD BE SPECIFIED IF        * 00610000
//*  STATISTICAL DATA IS BEING COLLECTED FOR RETURN TO IBM.           * 00620000
//*-------------------------------------------------------------------* 00630000
//DUMPCNT   DD DUMMY                                                    00640000
//DUMPMSG   DD DUMMY                                                    00650000
//DUMPCMD   DD DUMMY                                                    00660000
//DUMPRATE  DD DUMMY                                                    00670000
//OUT       DD DUMMY                                                    00680000
