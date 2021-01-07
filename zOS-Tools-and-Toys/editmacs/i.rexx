/** REXX **************************************************************
**                                                                   **
** Copyright 1994-2020 IBM Corp.                                     **
**                                                                   **
**  Licensed under the Apache License, Version 2.0 (the "License");  **
**  you may not use this file except in compliance with the License. **
**  You may obtain a copy of the License at                          **
**                                                                   **
**     http://www.apache.org/licenses/LICENSE-2.0                    **
**                                                                   **
**  Unless required by applicable law or agreed to in writing,       **
**  software distributed under the License is distributed on an      **
**  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,     **
**  either express or implied. See the License for the specific      **
**  language governing permissions and limitations under the         **
**  License.                                                         **
**                                                                   **
** ----------------------------------------------------------------- **
**                                                                   **
** Disclaimer of Warranties:                                         **
**                                                                   **
**   The following enclosed code is sample code created by IBM       **
**   Corporation.  This sample code is not part of any standard      **
**   IBM product and is provided to you solely for the purpose       **
**   of assisting you in the development of your applications.       **
**   The code is provided "AS IS", without warranty of any kind.     **
**   IBM shall not be liable for any damages arising out of your     **
**   use of the sample code, even if they have been advised of       **
**   the possibility of such damages.                                **
**                                                                   **
** ----------------------------------------------------------------- **
**                                                                   **
** Author: Bill Schoen <wjs@us.ibm.com>                              **
**                                                                   **
** Title: I and ISU                                                  **
**        Invoke ISPF from TSO, ISPF, or OMVS optionally with euid=0 **
**                                                                   **
** Notes: Install this where REXX execs can be found as I and ISU.   **
**        Either copy it twice or make a member alias.               **
**                                                                   **
** Usage: Enter   i  to invoke/reinvoke ISPF.  An ISPF option can be **
**        entered following i (e.g., i 3.4).  From OMVS, enter i on  **
**        the command line and use PF6 to run the command.           **
**                                                                   **
**        isu is the same as i however an attempt will be made to set**
**        your effective uid to 0.  On exit it will attempt to reset **
**        your effective uid to your real uid.                       **
**                                                                   **
***********************************************************************/

parse source . . mac .
if syscalls('ON')>4 then
   do
   say 'Unable to establish syscall environment'
   exit
   end
address syscall
if sysvar(sysispf)<>'ACTIVE' then
   do
   call su
   address tso 'ispf'
   end
 else
   do
   address ispexec 'VGET (ZAPPLID)'
   if zapplid='ZAPPLID' then
      do
      address ispexec 'SELECT CMD('mac arg(1)') NEWAPPL(ISR)'
      return
      end
   call su
   arg n .
   if n='' then
      opt=''
    else
      opt='OPT('n')'
   address ispexec 'SELECT PANEL(ISR@PRIM)' opt
   end
if pos('SU',translate(mac))=0 then
   return
halt:
'getuid'
uid=retval
'seteuid' uid
'geteuid'
say 'Effective uid is now' retval
return

su:
   if pos('SU',translate(mac))=0 then
      return
   'geteuid'
   uid=retval
   if uid=0 then
      do
      say 'Effective uid was already 0'
      exit
      end
   signal on halt
   'seteuid 0'
   if retval=-1 then
      signal nosu
   say 'Effective UID was changed from' uid 'to' 0
   return

nosu:
   say 'Cannot set effctive uid to 0'
   exit
