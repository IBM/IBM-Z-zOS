//SGCPTES2 JOB ,
//         MSGCLASS=H,MSGLEVEL=(1,1),
//         REGION=0M,
//         NOTIFY=&SYSUID
//*********************************************************************/
//*                                                                   */
//* USER KEY COMMON AREA ANALYZER                                     */
//*                                                                   */
//* AUTHOR : SHIVANG SHARMA AND UTKARSH GOSWAMI                       */
//* LICENSE: APACHE-2.0 (APACHE LICENSE 2.0)                          */
//*                                                                   */
//* URL: HTTPS://WWW.APACHE.ORG/LICENSES/LICENSE-2.0                  */
//*                                                                   */
//*********************************************************************/
//* COPYRIGHT 2020 IBM CORP.                                          */
//*                                                                   */
//* LICENSED UNDER THE APACHE LICENSE, VERSION 2.0 (THE "LICENSE");   */
//* YOU MAY NOT USE THIS FILE EXCEPT IN COMPLIANCE WITH THE LICENSE.  */
//* YOU MAY OBTAIN A COPY OF THE LICENSE AT                           */
//*                                                                   */
//* HTTP://WWW.APACHE.ORG/LICENSES/LICENSE-2.0                        */
//*                                                                   */
//* UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING,        */
//* SOFTWARE DISTRIBUTED UNDER THE LICENSE IS DISTRIBUTED ON AN       */
//* "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,      */
//* EITHER EXPRESS OR IMPLIED. SEE THE LICENSE FOR THE SPECIFIC       */
//* LANGUAGE GOVERNING PERMISSIONS AND LIMITATIONS UNDER THE LICENSE. */
//*                                                                   */
//*********************************************************************/
//* INSTRUCTIONS :
//* 1)REPLACE THE LIB DATASET WITH THE LIBRARY OF THE REXX EXEC       */
//* 2)REPLACE THE SMF DATASET WITH INPUT SMF 30 DATASET               */
//STEPNAME EXEC PGM=IKJEFT1B,PARM='%SMF30RPT'
//SYSPROC  DD DSN=<LIB DATASET>,DISP=SHR
//SYSTSPRT DD SYSOUT=*
//SYSTSIN  DD DUMMY
//SMFIN DD DSN=<SMF DATASET>,DISP=SHR
