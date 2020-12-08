/* REXX */
/***********************************************************************
   Author: Bill Schoen <wjs@us.ibm.com>

   Title: BPXGET
          Edit macro to copy a file in the HFS into the edit session
   Notes: Install this where REXX execs can be found.
          The concatenations for ISHELL are required.
   Usage: A destination line must be marked using the conventional
          A (after) or B (before) in the line prefix area.  On the
          command line enter   bpxget   followed by an optional
          pathname.  If a pathname is not entered, you are prompted.

   PROPERTY OF IBM
   COPYRIGHT IBM CORP. 1997
***********************************************************************/
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
