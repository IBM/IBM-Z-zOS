/** REXX **************************************************************
**                                                                   **
** Copyright 2010-2020 IBM Corp.                                     **
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
/* mailedit      edit macro to email your current file or section of  */
/*               the file as an email attachment                      */
/*                                                                    */
/* Syntax:       mailedit user@domain  or  mailedit user              */
/*                                                                    */
/* Description:  This uses sendmail to package and send an email      */
/*               attachment of your current edit session.  If an      */
/*               edit range is specified, that range is sent,         */
/*               otherwise the entire file is sent.                   */
/*               The last domain used is remembered and is used on    */
/*               on subsequent command invocations if not specified.  */
/*                                                                    */
/* Notes:        sendmail must be properly configured on your system. */
/*               You must be properly setup to use z/OS UNIX services */
/*                                                                    */
/* Bill Schoen 12/28/2010   wjs@us.ibm.com                            */
/*                                                                    */
/**********************************************************************/
address ispexec 'CONTROL ERRORS RETURN'
address isredit
'MACRO (PARM) NOPROCESS'
if rc>0 then
   call sayout 'mailedit must be run as an edit macro'
'PROCESS RANGE C'
'(FIRST) = LINENUM .ZFRANGE'
'(LAST) = LINENUM .ZLRANGE'
'(DSN) = DATASET'
'(MEM) = MEMBER'
if mem<>'' then
   dsn=dsn'('strip(mem)')'
dsn="'"dsn"'"
parse var parm mailaddr '@' domain
if mailaddr='' then call sayout 'missing email address'
if domain='' then
   do
   address ispexec 'vget (wjsmedo) profile'
   if wjsmedo<>'' then
      domain=wjsmedo
    else
      call sayout 'missing email domain (user@domain)'
   end
wjsmedo=domain
address ispexec 'vput (wjsmedo) profile'
txt=0
do tix=first to last by 1
   '(LN) = LINE' tix
   if rc<>0 then leave
   txt=txt+1
   txt.txt=strip(ln,'T')
end
txt.0=txt
cmd='iconv -f IBM-1047 -t ISO8859-1 | uuencode' dsn
call sayd cmd
call bpxwunix cmd,'txt.','out.','err.'
do i=1 to err.0
   say err.0
end
if err.0>0 then call sayout 'error building attachment'
msg.=''
msg.1='Subject:' dsn
msg.3='Attached file is lines' first+0'-'last+0 'in' dsn
mx=4
do i=1 to out.0
   mx=mx+1
   msg.mx=out.i
end
msg.0=mx+1
cmd='sendmail -i' mailaddr'@'domain
call sayd cmd
call bpxwunix cmd,'msg.','out.','err.'
do i=1 to out.0
   say out.i
end
do i=1 to err.0
   say err.0
end
if err.0>0 then call sayout 'email error'
call sayout 'Sent lines' first+0 'to' last+0 'to' mailaddr'@'domain
sayout:
   zedlmsg=arg(1)
   address ispexec "SETMSG MSG(ISRZ000)"
   exit
sayd:
   zedlmsg=arg(1)
   address ispexec "SETMSG MSG(ISRZ000)"
   address ispexec "CONTROL DISPLAY LOCK"
   address ispexec "DISPLAY"
   return
