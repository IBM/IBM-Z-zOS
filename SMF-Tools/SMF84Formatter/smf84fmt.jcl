//SMF84FMT JOB MSGLEVEL=(1,1),NOTIFY=&SYSUID
//********************************************************************/
//* SMF84FMT                                                         */
//*   Author: Nick Becker                                            */
//*   Created: 12 March, 2018                                        */
//*   License: apache-2.0 (Apache License 2.0)                       */
//*     URL: https://www.apache.org/licenses/LICENSE-2.0             */
//********************************************************************/
//*        The library that contains the SMF84FMT program            */
//         SET STEPLIB=<YOUR.LIBRARY.HERE>
//*------------------------------------------------------------------*/
//*        The dataset that contains the SMF records to be formatted */
//*        (i.e. output from the IFASMFDP program)                   */
//         SET SMFIN=<YOUR.DATASET.HERE>
//********************************************************************/
//*        Supported options for SMF84FMT are:                       */
//*          HEADER GENERAL PRODUCT JES2                             */
//*          CSV JSON                                                */
//FORMAT   EXEC PGM=SMF84FMT,PARM='HEADER MEMORY RESOURCE CSV'
//*------------------------------------------------------------------*/
//STEPLIB  DD DSN=&STEPLIB,DISP=SHR
//SMF84IN  DD DSN=&SMFIN,DISP=(OLD,KEEP)
//SMF84OUT DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//********************************************************************/
/*
