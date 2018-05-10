//SMF84FMT JOB MSGLEVEL=(1,1),NOTIFY=&SYSUID
//********************************************************************/
//* SMF84FMT                                                         */
//*   Author: Nick Becker                                            */
//*   Created: 12 March, 2018                                        */
//*   License: apache-2.0 (Apache License 2.0)                       */
//*     URL: https://www.apache.org/licenses/LICENSE-2.0             */
//********************************************************************/
//* Beginning of Copyright and License                               */
//*                                                                  */
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
//* either express or implied.  See the License for the specific     */
//* language governing permissions and limitations under the License.*/
//*                                                                  */
//* End of Copyright and License                                     */
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
