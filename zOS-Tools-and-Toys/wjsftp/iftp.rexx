/* REXX */
/**********************************************************************/
/* IFTP  Full screen ISPF FTP client for z/OS UNIX files              */
/*                                                                    */
/* Description:  shows your local ftp directory in the left column    */
/*               and the current remote ftp directory in the right    */
/*               column.  Select an entry with an action code or /    */
/*               to run a command.  / will prompt for the command and */
/*               show the corresponding action code.                  */
/*                                                                    */
/* Notes:        FTP commands may also be entered on the ftp command  */
/*               line.  You can enter 1 or 2 commands.  Separate 2    */
/*               commands with ;                                      */
/*               Some commands may cause the host directory list to   */
/*               be lost or corrupted.  an explicit cd command will   */
/*               usually restore it.                                  */
/*                                                                    */
/* PROPERTY OF IBM                                                    */
/* COPYRIGHT IBM CORP. 2010                                           */
/*                                                                    */
/* Notes:                                                             */
/*   Run from TSO.  Save this to a PDS in your sysproc or sysexec     */
/*   concatenation.  To use this you must be properly setup to        */
/*   use z/OS UNIX services.                                          */
/*                                                                    */
/* Bill Schoen 12/28/2010   wjs@us.ibm.com                            */
/*                                                                    */
/**********************************************************************/
call syscalls 'ON'
call buildpan
loglines=10
address ispexec 'display panel(hostinfo)'
if rc<>0 then return
rv=ftpapi(ftp.,'create')
if rv<>0 then signal ftperr
rv=ftpapi(ftp.,'init')
if rv<>0 then signal ftperr
parse var host host '/' cd
if ftp('scmd','open' host,,2)<0 then return
if ftp('scmd','user' user,,2)<0 then return
if ftp('scmd','pass',pass,2)<0 then return
if cd<>'' then
   if ftp('scmd','cd' cd,,2)<0 then return
address syscall 'getcwd lcd'
cmd=''
refresh=0
call showdirs
trace o
address ispexec 'control errors return'
address ispexec 'tbend ftpout'
call ftp 'term'
call cleanup
return

setlcd:
   parse arg newlcd
   quiet=2
   if substr(newlcd,1,1)<>'/' then
      newlcd=lcd'/'newlcd
   address syscall 'realpath (newlcd) reallcd'
   if retval=-1 then
      do
      call say 'cannot resolve path' newlcd
      return
      end
   cmd='lcd' newlcd
   if ftp('scmd',cmd,,1)>=0 then
      lcd=reallcd
   return

showdirs:
   do forever
   address ispexec "tbcreate ftpdir nowrite replace",
                   "names(s t lname hname)"
   cmds=''
   dir.=''
   rdir.=''
   dir.0=0
   call ftp 'scmd','ls -a',,1
   j=4 /* output seems to have 4 lines of junk before directory list */
   do i=1 by 1
      j=j+1
      rdir.i=ln.j
      if j>ln.0-3 then leave
   end
   rdir.0=i
   call sortstem 'rdir.'
   address syscall 'readdir (lcd) dir.'
   call sortstem 'dir.'
   s=''
   t=''
   do i=1 by 1
      lname=dir.i
      hname=rdir.i
      if hname='' & lname='' then leave
      address ispexec 'tbadd ftpdir'
   end
   do while refresh<>1
      address ispexec 'tbtop ftpdir'
      address ispexec 'tbdispl ftpdir panel(ftpdir)'
      if rc>4 then leave
      call processtab
   end
   address ispexec 'tbend ftpdir'
   if refresh<>1 then leave
   refresh=0
   end
   return

processtab:
   sels=ztdsels
   lfile=0
   hfile=0
   cmds=cmd
   do ftj=1 to sels
      address ispexec "tbcreate ftpout nowrite replace",
                      "names(s lineout)"
      if s<>'' then
         do
         lfile=lfile+1
         lfile.lfile.1=s
         lfile.lfile.2=lname
         end
      if t<>'' then
         do
         hfile=hfile+1
         hfile.hfile.1=t
         hfile.hfile.2=hname
         end
      if ftj=sels then leave
      address ispexec 'tbdispl ftpdir'
   end
   if cmds<>'' then
      do
      call runcmds
      refresh=1
      end
   do ftj=1 to lfile
      call localfile lfile.ftj.1 lfile.ftj.2
   end
   do ftj=1 to hfile
      call hostfile hfile.ftj.1 hfile.ftj.2
   end
   return

localfile:
   parse arg opcmd lname
   cmds=''
   do while cmds=''
      refresh=1
      if opcmd='c' then
         cmds='ascii;put' lname
      else
      if opcmd='r' then
         do
         refresh=0
         cmds='ascii;get' lname '(replace'
         end
      else
      if opcmd='cb' then
         cmds='binary;put' lname
      else
      if opcmd='rb' then
         do
         refresh=0
         cmds='binary;get' lname '(replace'
         end
      else
      if opcmd='i' then
         do
         cmds='ls -al' lname
         call bpxwunix cmds,,out.,err.
         quiet=0
         do i=1 to out.0
            call say out.i
         end
         do i=1 to err.0
            call say err.i
         end
         refresh=0
         end
      else
      if opcmd='cd' then
         do
         call setlcd lname
         return
         end
      else
      if opcmd='b' then
         do
         address tso 'obrowse' lcd'/'lname
         refresh=0
         return
         end
      else
      if opcmd='e' then
         do
         address tso 'oedit' lcd'/'lname
         refresh=0
         return
         end
      else
         do
         address ispexec 'display panel(lfileop)'
         if rc<>0 then return
         end
   end
   call runcmds
   return

hostfile:
   parse arg opcmd hname
   cmds=''
   do while cmds=''
      refresh=1
      if opcmd='c' then
         do
         cmds='ascii;get' hname '(replace'
         end
      else
      if opcmd='r' then
         cmds='ascii;put' hname
      else
      if opcmd='rb' then
         cmds='binary;put' hname
      else
      if opcmd='cb' then
         do
         cmds='binary;get' hname '(replace'
         end
      else
      if opcmd='d' then
         cmds='delete' hname
      else
      if opcmd='i' then
         do
         cmds='dir' hname
         refresh=0
         address ispexec "control nondispl enter"
         end
      else
      if opcmd='cd' then
         do
         call ftp 'scmd','cd' hname,,1
         return
         end
      else
      if opcmd='b' then
         do
         refresh=0
         call ftp 'scmd','ascii'
         call ftp 'scmd','get' hname 'iftp.tmp.'hname '(replace'
         address tso 'obrowse' lcd'/iftp.tmp.'hname
         address syscall 'unlink' lcd'/iftp.tmp.'hname
         return
         end
      else
      if opcmd='e' then
         do
         refresh=0
         call ftp 'scmd','ascii'
         call ftp 'scmd','get' hname 'iftp.tmp.'hname '(replace'
         address tso 'oedit' lcd'/iftp.tmp.'hname
         address syscall 'unlink' lcd'/iftp.tmp.'hname
         return
         end
      else
         do
         address ispexec 'display panel(hfileop)'
         if rc<>0 then return
         end
   end
   call runcmds
   return

runcmds:
   if cmds<>'' then
      do
      parse var cmds cmd1 ';' cmd2
      address ispexec 'control display lock'
      address ispexec 'tbdispl ftpout panel(ftpcmd)'
      if rc>4 then return
      if cmd2<>'' then
         do
         if translate(word(cmd1,1))='LCD' then
            do
            call setlcd word(cmd1,2)
            return
            end
          else
            if ftp('scmd',cmd1,,1)<0 then return
         cmd1=cmd2
         end
      if translate(word(cmd1,1))='LCD' then
         do
         call setlcd word(cmd1,2)
         return
         end
       else
         call ftp 'scmd',cmd1,,0
      end
   do forever
      address ispexec 'tbdispl ftpout panel(ftpcmd)'
      if rc>4 then leave
   end
   return

ftp:
   parse arg type,fcmd,cmdarg,quiet
   address ispexec "tbcreate ftpout nowrite replace",
                   "names(s lineout)"
   ln.0=0
   if type<>'scmd' then
      wait=''
    else
      do
      wait='w'
      call say fcmd
      end
   rv=ftpapi(ftp.,type,fcmd cmdarg,wait)
ftperr:
   if rv<0 then
      call say 'fpt error codes:' rv ftp.FCAI_Result FCAI_Result_ie,
                             ftp.FCAI_ie
   rm=ftpapi(ftp.,'getl_copy','ln.')
   if rm<0 then
      call say 'get text error:' rv ftp.FCAI_Result FCAI_Result_ie,
                             ftp.FCAI_ie
   do i=1 to ln.0
      call say ln.i
   end
   address ispexec 'tbtop ftpout'
   return rv

say:
   parse arg lineout
   if quiet=2 then
      say lineout
    else
    if quiet=0 then
       address ispexec 'tbadd ftpout'
   return

sortstem:
   arg sst,sscol
   ssm=value(sst||0)
   do ssi=1 to ssm
      do ssj=ssi+1 to ssm
         if sscol<>'' then
          do
          if substr(value(sst||ssi),sscol)>>,
             substr(value(sst||ssj),sscol) then
            do
            ssx=value(sst||ssi,value(sst||ssj))
            ssx=value(sst||ssj,ssx)
            end
          end
         else
         if value(sst||ssi)>>value(sst||ssj) then
            do
            ssx=value(sst||ssi,value(sst||ssj))
            ssx=value(sst||ssj,ssx)
            end
      end
   end
   return

/**********************************************************************/
/**********************************************************************/
/* panel build utility */
/**********************************************************************/

buildpan:
   needcleanup=1
   address tso
   if keep=1 then
      pandsn='da(wjsez.pan)'
    else
      pandsn=''
   if keep=1 then 'del wjsez.pan'
   call bpxwdyn 'alloc rtddn(wjsezpan) unit(sysallda) new reuse',
       'dir(5) space(1,1) msg(wtp)',
       'tracks dsorg(po) recfm(f,b) lrecl(80) blksize(3280)' pandsn
   address ispexec 'LMINIT DATAID(PANID) DDNAME('WJSEZPAN')'
   srcx=1
   do forever
      call getsrc '//pan'
      if src.0=0 then leave
      call mkmem srcmem
   end
   address ispexec 'LMFREE DATAID('PANID')'
   address ispexec 'LIBDEF ISPPLIB LIBRARY ID('WJSEZPAN') STACK'
   return

mkmem:
   address ispexec
   'LMOPEN DATAID('PANID') OPTION(OUTPUT)'
   do i=1 to src.0
      ln=left(src.i,80)
      'LMPUT DATAID('PANID') DATALOC(LN) MODE(INVAR) DATALEN(80)'
   end
   'LMMADD DATAID('PANID') MEMBER('translate(arg(1))')'
   'LMCLOSE DATAID('PANID')'
   return

getsrc:
   parse arg key
   k=0
   j=sourceline()
   src.0=0
   do i=srcx to j
      if word(sourceline(i),1)=key then leave
   end
   srcx=i
   if i>j then return
   srcmem=word(sourceline(i),2)
   if srcmem='' then return
   do i=i+1 to j
      k=k+1
      src.k=strip(sourceline(i),'T')
      if word(src.k,1)='//end' then leave
   end
   srcx=i
   src.0=k-1
   return

cleanup:
   if needcleanup<>1 then return
   address ispexec 'LIBDEF ISPPLIB'
   address tso
   call bpxwdyn 'free fi('wjsezpan')'
   if keep=1 then 'del wjsez.pan'
   needcleanup=0
   return

/**********************************************************************/
/* panels
************************************************************************
//pan hostinfo
)ATTR
   % TYPE(TEXT)   INTENS(HIGH)                skip(on)
   + TYPE(TEXT)   INTENS(LOW)
   $ TYPE(TEXT)   INTENS(LOW)                 COLOR(turquoise)
   _ TYPE(INPUT)  INTENS(HIGH) padc('_')      CAPS(OFF)  JUST(LEFT)
   ~ TYPE(INPUT)  INTENS(NON)  padc('_')      CAPS(OFF)  JUST(LEFT)
   ? TYPE(output) INTENS(low)  caps(off)      COLOR(turquoise)
)BODY
$------------------------------%IFTP$-----------------------------------
%Command ===>_ZCMD                                                             +
%
%Select user/host:_u%
%Host Password   :~pass                +
+
+Enter userids and host addresses.  The host address can be
+suffixed with a / followed by your initial directory, eg:
+  anonymous        public.dhe.ibm.com/s390/zos/tools/
+
%1_iftpusr1        _iftpnm1                                                    +
%2_iftpusr2        _iftpnm2                                                    +
%3_iftpusr3        _iftpnm3                                                    +
%4_iftpusr4        _iftpnm4                                                    +
%5_iftpusr5        _iftpnm5                                                    +
+
)INIT
&ZCMD = ' '
.cursor = u
vget (iftpnm1 iftpusr1) profile
vget (iftpnm2 iftpusr2) profile
vget (iftpnm3 iftpusr3) profile
vget (iftpnm4 iftpusr4) profile
vget (iftpnm5 iftpusr5) profile
&host = ''
&user = ''
&pass = ''
)PROC
ver(&u nb range 1,5)
if (&u = 1)
   &host = &iftpnm1
   &user = &iftpusr1
if (&u = 2)
   &host = &iftpnm2
   &user = &iftpusr2
if (&u = 3)
   &host = &iftpnm3
   &user = &iftpusr3
if (&u = 4)
   &host = &iftpnm4
   &user = &iftpusr4
if (&u = 5)
   &host = &iftpnm5
   &user = &iftpusr5
ver(&host nb)
ver(&user nb)
ver(&pass nb)
vput (iftpnm1 iftpusr1) profile
vput (iftpnm2 iftpusr2) profile
vput (iftpnm3 iftpusr3) profile
vput (iftpnm4 iftpusr4) profile
vput (iftpnm5 iftpusr5) profile
)END
//end

************************************************************************
//pan lfileop
)ATTR
   % TYPE(TEXT)   INTENS(HIGH)
   + TYPE(TEXT)   INTENS(LOW)
   $ TYPE(TEXT)   INTENS(LOW)                 COLOR(turquoise)
   _ TYPE(INPUT)  INTENS(HIGH) padc('_')      CAPS(OFF)  JUST(LEFT)
   ~ TYPE(INPUT)  INTENS(NON)  padc('_')      CAPS(OFF)  JUST(LEFT)
   ? TYPE(output) INTENS(low)  caps(off)      COLOR(turquoise)
)BODY
$------------------------------%IFTP$-----------------------------------
%Command ===>_ZCMD                                                             +
%
%Local file?lname
%Select operation:_op+
+   %1+cb copy file to host as binary
+   %2+c  copy file to host as text
+   %3+rb replace file from host file as binary
+   %4+r  replace file from host file as text
+   %5+i  list file information
+   %6+cd change directory
+   %7+b  browse
+   %8+e  edit
+
+
)INIT
&ZCMD = ' '
.cursor = op
)PROC
ver(&op nb range 1,8)
&opcmd=trans (&op 1,cb 2,c 3,rb 4,r 5,i 6,cd 7,b 8,e)
)END
//end

************************************************************************
//pan hfileop
)ATTR
   % TYPE(TEXT)   INTENS(HIGH)
   + TYPE(TEXT)   INTENS(LOW)
   $ TYPE(TEXT)   INTENS(LOW)                 COLOR(turquoise)
   _ TYPE(INPUT)  INTENS(HIGH) padc('_')      CAPS(OFF)  JUST(LEFT)
   ~ TYPE(INPUT)  INTENS(NON)  padc('_')      CAPS(OFF)  JUST(LEFT)
   ? TYPE(output) INTENS(low)  caps(off)      COLOR(turquoise)
)BODY
$------------------------------%IFTP$-----------------------------------
%Command ===>_ZCMD                                                             +
%
%Host file?hname
%Select operation:_op+
+   %1+cb copy file from host as binary
+   %2+c  copy file from host as text
+   %3+rb replace host file as binary
+   %4+r  replace host file as text
+   %5+i  list file information
+   %6+cd change directory
+   %7+d  delete file
+   %8+b  browse
+   %9+e  browse in an edit session
+
+
)INIT
&ZCMD = ' '
.cursor = op
)PROC
ver(&op nb range 1,8)
&opcmd=trans (&op 1,cb 2,c 3,rb 4,r 5,i 6,cd 7,d 8,b)
)END
//end

************************************************************************
//pan ftpcmd
)ATTR
   % TYPE(TEXT)   INTENS(HIGH)
   + TYPE(TEXT)   INTENS(LOW)
   $ TYPE(TEXT)   INTENS(LOW)                 COLOR(turquoise)
   _ TYPE(INPUT)  INTENS(HIGH) padc('_')      CAPS(OFF)  JUST(LEFT)
   ~ TYPE(INPUT)  INTENS(NON)  padc('_')      CAPS(OFF)  JUST(LEFT)
   ? TYPE(output) INTENS(low)  caps(off)      COLOR(turquoise)
)BODY
$------------------------------%IFTP$-----------------------------------
%Command ===>_ZCMD                                                             +
%
+Enter%END(PF3)+to return
+
?cmd1
?cmd2
+
)MODEL
?lineout
)INIT
&ZCMD = ' '
)PROC
)END
//end

************************************************************************
//pan ftpdir
)ATTR
   % TYPE(TEXT)   INTENS(HIGH)
   + TYPE(TEXT)   INTENS(LOW)
   $ TYPE(TEXT)   INTENS(LOW)                 COLOR(turquoise)
   _ TYPE(INPUT)  INTENS(HIGH) padc('_')      CAPS(OFF)  JUST(LEFT)
   ? TYPE(output) INTENS(low)  caps(off)      COLOR(turquoise)
   ~ TYPE(output) INTENS(high) caps(off)      color(white)
)BODY expand(!!) width(&zscreenw)
$------------------------------%IFTP$-----------------------------------
%Command ===>_ZCMD                                                %Scroll:_amt +
%
%Local directory :?lcd
+Select a file with%/+or action code to perform an operation on that file
+or directly enter an FTP command
%FTP command:_cmd
+  Local files                             Host files
)MODEL
_s ?lname                               _t ?hname
)INIT
&zcmd = ' '
&cmd = ''
)PROC
)FIELD
FIELD(lname)
FIELD(hname)
)END
//end

*/
