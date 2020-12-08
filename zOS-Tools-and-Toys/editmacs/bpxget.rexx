/** REXX **************************************************************
**                                                                   **
** Copyright 1997-2020 IBM Corp.                                     **
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
** Title: BPXGET                                                     **
**        Edit macro to copy a file in the HFS into the edit session **
**                                                                   **
** Notes: Install this where REXX execs can be found.                **
**        The concatenations for ISHELL are required.                **
**                                                                   **
** Usage: A destination line must be marked using the conventional   **
**        A (after) or B (before) in the line prefix area.  On the   **
**        command line enter   bpxget   followed by an optional      **
**        pathname.  If a pathname is not entered, you are prompted. **
**                                                                   **
**********************************************************************/

call syscalls on
msgid='ISRZ000'
address ispexec 'CONTROL ERRORS RETURN'
address isredit
'MACRO (PARM) NOPROCESS'
'PROCESS DEST'
if rc<>0 then
   call err 'Destination not set'
'(WIDTH) = LRECL'
'(FIRST) = LINENUM .ZDEST'
if parm='' then
   do
   address syscall 'getcwd parm'
   call makevpath parm
   vtext='RP'
   address ispexec
   "ADDPOP"
   "DISPLAY PANEL(BPXWP19)"
   src=rc
   "REMPOP"
   address
   if src<>0 then
      call err
   parm=makepath()
   end
f.0=0
address syscall 'readfile (parm) f.'
if f.0=0 then
   call err 'File empty or unable to read file:' parm
trunc=0
do i=1 to f.0
   ln=f.i
   if length(ln)>width then
      trunc=trunc+1
   'LINE_AFTER' first '= (LN)'
   first=first+1
end
address syscall 'realpath (parm) fn'
if retval<>-1 then
   parm=fn
if trunc>0 then
   call msg trunc 'lines truncated,' f.0 'lines copied from:' parm
 else
   call msg f.0 'lines copied from:' parm
return 0

err:
   parse arg m
   msgid='ISRZ001'
   if m<>'' then
      call msg m
   exit 8

msg:
   zedsmsg=''
   zedlmsg=arg(1)
   address ispexec 'SETMSG MSG('msgid')'
   return

makepath:
   retpath=''
   quote="'"
   do i=1 to 20
      tpath=value('vpath' || right(i,2,0))
      if tpath='' then
         leave
      if substr(tpath,1,1)=quote then
         tpath=substr(tpath,2)
      if length(tpath)=0 then
         iterate
      if substr(tpath,length(tpath),1)=quote then
         tpath=substr(tpath,1,length(tpath)-1)
      retpath=retpath || tpath
   end
   return retpath

makevpath:
   parse arg fullpath
   quote="'"
   do i=1 to 20
      parse var fullpath tpath 63 fullpath
      if length(tpath)=0 then
         leave
      if substr(tpath,1,1)=quote | substr(tpath,1,1)==' ' then
         tpath=quote || tpath
      if substr(tpath,length(tpath),1)=quote |,
           substr(tpath,length(tpath),1)==' ' then
         tpath=tpath || quote
      xx=value('vpath' || right(i,2,0),tpath)
   end
   do i=i to 20
      xx=value('vpath' || right(i,2,0),'')
   end
   return
