*/****************************************************************/     00010000
*/* LICENSED MATERIALS - PROPERTY OF IBM                         */     00020000
*/*                                                              */     00030000
*/* 5650-ZOS                                                     */     00040000
*/*                                                              */     00050000
*/*     COPYRIGHT IBM CORP. 1991, 2012                           */     00060000
*/*                                                              */     00070000
*/* US GOVERNMENT USERS RESTRICTED RIGHTS - USE,                 */     00080000
*/* DUPLICATION OR DISCLOSURE RESTRICTED BY GSA ADP              */     00090000
*/* SCHEDULE CONTRACT WITH IBM CORP.                             */     00100000
*/*                                                              */     00110000
*/* STATUS = HLE7790                                             */     00120000
*/****************************************************************/     00130000
CEEUOPT  CSECT                                                          00180000
CEEUOPT  AMODE ANY                                                      00190000
CEEUOPT  RMODE ANY                                                      00200000
         CEEXOPT ENVAR=('_BPXK_AUTOCVT=ON','_TAG_REDIR_ERR=TXT',' _TAG_X00340000
               REDIR_IN=TXT','_TAG_REDIR_OUT=TXT'),                    X00341000
               FILETAG=(AUTOCVT,AUTOTAG),                              X00375000
               POSIX=(ON),                                             X00570000
               XPLINK=(ON)                                              00780000
         END                                                            00800000
