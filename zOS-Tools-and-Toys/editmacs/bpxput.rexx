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
** Title: BPXPUT                                                     **
**        Edit macro to save the file or a range as a file in the    **
**        HFS.                                                       **
**                                                                   **
** Notes: Install this where REXX execs can be found.                **
**        The concatenations for ISHELL are required.                **
**                                                                   **
** Usage: Enter  bpxput  on the command line optionally followed by  **
**        the pathname to the destination file.  If a pathname is    **
**        not entered you will be prompted.  If the file does not    **
**        already exist you will be prompted for file permissions.   **
**        All directories in the path must already exist.            **
**                                                                   **
***********************************************************************/
call syscalls on
msgid='ISRZ000'
address ispexec 'CONTROL ERRORS RETURN'
address isredit
'MACRO (PARM) NOPROCESS'
'PROCESS RANGE C'
if rc>4 then
   call err 'Improper range'
'(FIRST) = LINENUM .ZFRANGE'
'(LAST) = LINENUM .ZLRANGE'
if parm='' then
   do
   address syscall 'getcwd parm'
   call makevpath parm
   vtext='CP'
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
txt=0
do tix=first to last by 1
   '(LN) = LINE' tix
   if rc<>0 then
      leave
   txt=txt+1
   txt.txt=strip(ln,'T')
end
txt.0=txt
vperm='000'
address syscall 'access (parm)' f_ok
if retval=-1 then
   do
   tperm='700'
   address ispexec
   "ADDPOP"
   "DISPLAY PANEL(BPXWP47)"
   src=rc
   "REMPOP"
   address
   if src<>0 then
      call err
   end
 else
   do
   address ispexec
   "ADDPOP"
   "DISPLAY PANEL(BPXWP18)"
   src=rc
   "REMPOP"
   address
   if src<>0 then
      call err
   end
address syscall 'writefile (parm)' vperm 'txt.'
if retval=-1 then
   call err 'Error' errno 'reason' errnojr 'writing file:' parm
address syscall 'realpath (parm) p'
if retval<>-1 then
   parm=p
call msg txt.0 'lines copied to:' parm
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
