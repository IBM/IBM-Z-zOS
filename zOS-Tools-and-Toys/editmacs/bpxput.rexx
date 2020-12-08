/* REXX */
/***********************************************************************
   Author: Bill Schoen <wjs@us.ibm.com>

   Title: BPXPUT
          Edit macro to save the file or a range as a file in the HFS
   Notes: Install this where REXX execs can be found.
          The concatenations for ISHELL are required.
   Usage: Enter   bpxput    on the command line optionally followed by
          the pathname to the destination file.  If a pathname is not
          entered you will be prompted.  If the file does not already
          exist you will be prompted for file permissions.  All
          directories in the path must already exist.

   PROPERTY OF IBM
   COPYRIGHT IBM CORP. 1997
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
