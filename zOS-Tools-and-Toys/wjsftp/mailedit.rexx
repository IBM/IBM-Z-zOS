/* REXX */
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
/* PROPERTY OF IBM                                                    */
/* COPYRIGHT IBM CORP. 2010,2013                                      */
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
