/** REXX **************************************************************
**                                                                   **
** Copyright 2016-2020 IBM Corp.                                     **
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
** Title: jobwait                                                    **
** Syntax:  jobwait [-t time] jobid                                  **
** Options:                                                          **
**   t <time>  set maximum wait time in seconds                      **
**                                                                   **
** Install this in a directory where you can run programs.           **
** Set permissions to read+execute                                   **
**                                                                   **
** Bill Schoen <wjs@us.ibm.com>  1/26/2016                           **
**                               5/3/2019 allow jobid piping, fix cc **
**********************************************************************/

parse arg '-t' wt jobid .
if jobid='' then
   parse arg jobid .
if jobid='' then
   jobid=linein()
if jobid='' then
   do
   say 'Usage:  jobwait [-t time] jobid'
   exit 1
   end
jobid=translate(jobid)
call time 'E'
call isfcalls 'on'
isfprefix='*'
isfowner=userid()
notfound=0
do forever
   address sdsf 'ISFEXEC ST'
   if rc<>0 then
      do
      say 'probably some error...rc='rc
      exit 1
      end
   do i=1 to jobid.0
      if jobid.i<>jobid then iterate  /* not the specified job */
      if queue.i<>'PRINT' then leave  /* job not done yet */
      parse var retcode.i . cc .
      if cc=0 then
         exit 0
      exit 8
   end
   if i>jobid.0 then
      if notfound then
         do
         say 'Job' jobid 'not found'
         exit 2
         end
       else
         notfound=1
   if wt<>'' then
      do
      parse value time('E') with s '.'
      if s>wt then
         do
         say 'wait time exceeded'
         exit 2
         end
      end
   address syscall 'sleep 5'
end
