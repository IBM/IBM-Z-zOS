//*===============================================================*
//* COMPILE CEEUOPT, COMPILE LE COBOL, LINK TO CREATE ACIF EXIT   *
//*===============================================================*
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
