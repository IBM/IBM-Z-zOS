/** REXX **************************************************************
**                                                                   **
** Copyright 2009-2020 IBM Corp.                                     **
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
** sdsfout   print output from a job to stdout                       **
**                                                                   **
** Syntax:  sdsfout <jobname | jobid>                                **
**                                                                   **
** Install this in a directory where you can run programs.           **
** Set permissions to read+execute                                   **
**                                                                   **
** Bill Schoen  1/22/2009                                            **
***********************************************************************/
arg jname
call isfcalls 'ON'
jname.=''
address sdsf 'ISFEXEC ST'
if rc<>0 then
   do
   call sayerr 'SDSF error.  RC='rc
   return
   end
do s=1 to jname.0
   if jname=jname.s then leave
   if jname=jobid.s then leave
end
if jname.s='' then
   do
   call sayerr 'jobname or jobid missing or not found'
   return
   end
call sayerr 'Printing JobName='jname.s 'JobID='jobid.s 'Owner='ownerid.s 'Queue='queue.s
address sdsf "ISFACT ST TOKEN('"token.s"') PARM(NP SA)"
do i=1 to isfddname.0
   do forever
      address mvs 'execio 1000 diskr' isfddname.i '(stem st.'
      if st.0=0 then leave
      do j=1 to st.0
         say st.j
      end
   end
   address mvs 'execio 0 diskr' isfddname.i '(fini'
end
return

sayerr:
   parse arg msg
   msg=msg'15'x
   address syscall 'write 2 msg'
   return
