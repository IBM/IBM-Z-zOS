//*===============================================================*
//* COMPILE CEEUOPT, COMPILE LE COBOL, LINK TO CREATE ACIF EXIT   *
//*===============================================================*
//LIBS     JCLLIB ORDER=(SYS1.PROCLIB,IGY.SIGYPROC,ASM.SASMSAM1,
//         CEE.SCEEPROC)
//*------- ---- -------------------------------------------------------
//*-TEST FOR LE --   NORENT,RMODE(AUTO),REUS=SERIAL
//USEREXIT EXEC PROC=IGYWCL,LNGPRFX='IGY',
//         PGMLIB='<my>.LIBRARY',GOPGM=NULLEXIT,
//         PARM.COBOL=(APOST,MAP,NORENT,TRUNC(BIN),CP(1140),
//         X,DYNAM,RMODE(24),LIST,S,NOOFF,DATA(24),
//         TEST(SOURCE)),
//         PARM.LKED=(CASE(UPPER),COMPAT(CURR),LIST,LET,MAP,XREF,
//         REUS(SERIAL))
//COBOL.SYSPRINT DD DSN=<my>.COMPILE.LISTINGS(&GOPGM),DISP=SHR
//COBOL.SYSIN  DD DSNAME=<my>.COBOL(&GOPGM),DISP=SHR
//COBOL.SYSLIB DD DSNAME=<my>.COBOL,DISP=SHR
//LKED.SYSLIN  DD
//             DD DSNAME=&&OBJ,DISP=SHR
//             DD DDNAME=SYSIN
//LKED.SYSLMOD  DD  DSNAME=&PGMLIB(&GOPGM),DISP=SHR
