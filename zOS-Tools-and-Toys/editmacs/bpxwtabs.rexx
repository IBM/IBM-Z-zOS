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
** Title: BPXWTABS                                                   **
**        Edit macro to expand and insert tabs                       **
**                                                                   **
** Notes: Install this where REXX execs can be found.                **
**                                                                   **
** Usage: Enter BPXWTABS on the command line.  If the file contains  **
**        tab characters, they are expanded, otherwise the file is   **
**        compressed with tab characters.                            **
**        This macro assumes a fixed tab interval of 8. The interval **
**        can be changed by entering a number from 2-9 as an         **
**        argument:                                                  **
**           bpxwtabs 4     will use a tab interval of 4.            **
**                                                                   **
***********************************************************************/
address ispexec "CONTROL ERRORS RETURN"
address isredit
"MACRO (PARM)"
if rc>8 then
   do
   say 'Must be run as an edit macro'
   return
   end
iv=8
if datatype(parm,'W') then
   if parm>1 & parm <10 then
      iv=parm
"(RECL)=LRECL"
"FIND X'05' FIRST"
if rc=0 then
   call exptabs
 else
   call instabs
address ispexec "SETMSG MSG(ISRZ000)"
return

exptabs:
   err=0
   do i=1 by 1
      "(LN) = LINE" i
      if rc<>0 then leave
      do forever
         parse var ln ln1 '05'x ln2
         ln=substr(ln1,1,((length(ln1)+iv)%iv)*iv)ln2
         if ln2='' then leave
      end
      ln=strip(ln,'T')
      if length(ln)>recl then
         do
         err=err+1
         end
       else
         "LINE" i "= (LN)"
   end
   zedsmsg=''
   if err>0 then
      do
      "EXCLUDE ALL"
      "FIND X'05' ALL"
      zedlmsg='Line length error, not all tabs expanded'
      end
    else
      zedlmsg='Tabs expanded'
   return

instabs:
   tab='05'x
   no='No '
   do i=1 by 1
      "(LN) = LINE" i
      if rc<>0 then leave
      rl=min(recl,length(strip(ln,'T')))
      change=0
      do j=(rl%iv)*iv to iv by -iv
         ss=strip(substr(ln,j-iv+1,iv),'T')
         if length(ss)<iv-1 then
            do
            ss=ss''tab
            ln=substr(ln,1,j-iv)ss''substr(ln,j+1)
            change=1
            no=''
            end
      end
      if change then
         "LINE" i "= (LN)"
   end
   zedlmsg=no'Tabs inserted'
   return
