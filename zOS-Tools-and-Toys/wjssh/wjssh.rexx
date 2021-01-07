/** REXX **************************************************************
**                                                                   **
** Copyright 2012-2020 IBM Corp.                                     **
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
**                                                                   **
**********************************************************************/

/**********************************************************************/
/* Run a shell command from tso or sysrexx                            */
/*                                                                    */
/* Syntax:  wjssh <command line>                                      */
/*                                                                    */
/* Notes:                                                             */
/*   To run from TSO, save this to a PDS in your sysproc or sysexec   */
/*   concatenation                                                    */
/*   To run from sysrexx, save this to a PDS in your sysrexx search   */
/*   list as specified in parmlib AXRnn.  To use this you must be     */
/*   logged onto the console with a userid that is properly setup to  */
/*   use z/OS UNIX services.  Beware <command line> is case sensitive,*/
/*   you will probably need to quote it.                              */
/*                                                                    */
/* Bill Schoen  8/25/2008   wjs@us.ibm.com                            */
/*                                                                    */
/**********************************************************************/
parse arg cmd
parse source . . me . . . . where .
if syscalls('ON')>4 then
   do
   say 'Cannot initialize as a unix process'
   if where='AXR' then
      say 'Logon to the console with userid that can access z/OS UNIX'
   return
   end
env.0=1
env.1='PATH=/bin:/usr/bin:/usr/sbin:.'
out.0=0
err.0=0
rr=bpxwunix(cmd,,out.,err.,env.)
if rr<>0 then
   say 'RC('rr')'
call brstem out.
call brstem err.
return

brstem:
   arg stem
   if where<>'ISPF' then
      do
      do i=1 to value(stem'0')
         if where='AXR' then
            do
            wtomsg=value(stem||i)
            if wtomsg='' then
               wtomsg='.'
            call axrwto wtomsg
            end
          else
            say value(stem||i)
      end
      return
      end
   address ispexec
   brc=value(arg(1)"0")
   if brc=0 then
      return
   brlen=250
   do bri=1 to brc
      if brlen<length(value(arg(1) || bri)) then
         brlen=length(value(arg(1) || bri))
   end
   brlen=brlen+4
   call bpxwdyn "alloc rtddn(bpxpout) reuse new",
                "recfm(v,b) lrecl("brlen") msg(wtp)"
   address tso "execio" brc "diskw" bpxpout "(fini stem" arg(1)
   'LMINIT DATAID(DID) DDNAME('BPXPOUT')'
   'VIEW   DATAID('did') PROFILE(WJSC) MACRO(RESET)'
   'LMFREE DATAID('did')'
   call bpxwdyn 'free dd('bpxpout')'
   return

