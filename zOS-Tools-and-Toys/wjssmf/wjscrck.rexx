/* REXX */
/*******************************************************************/
/* wjscrck  analyze unix file create operations                    */
/*                                                                 */
/* PROPERTY OF IBM                                                 */
/* COPYRIGHT IBM CORP. 2016                                        */
/*                                                                 */
/* Syntax:                                                         */
/*      1.    wjscrck START <pathname>                             */
/*               <pathname> defaults to /dev/console               */
/*      2.    wjscrck STOP                                         */
/*                                                                 */
/* Bill Schoen  4/22/16 (wjs@us.ibm.com)                           */
/* Primary contact: Mike Spiegel (mspiegel@us.ibm.com)             */
/*                                                                 */
/*******************************************************************/
parse arg cmd figparm
parse source . . . . . . . env .
qname='WSXT'
ofd=-1
quiet=0
call syscalls 'ON'
address syscall 'seteuid 0'
address syscall 'geteuid'
if retval<>0 then
   do
   call say 'must run as superuser'
   exit 1
   end
msg=''
if cmd='server' then
   call server figparm
else
if translate(cmd)='STOP' then
   call stop figparm
else
if translate(cmd)='START' then
   call start figparm
else
   do
   call say 'wjscrck START <pathname>          '
   call say 'wjscrck STOP'
   end
return

/*******************************************************************/

/*******************************************************************/
/*******************************************************************/
start:
   parse arg figparm
   do i=1 to sourceline()
      pgm.i=sourceline(i)
   end
   pgm.0=i-1
   address syscall 'writefile /var/wjscrck 777 pgm.'
   if rc>4 then
      do
      call say 'error creating exec in /var' errno errnojr
      return
      end
   xx=bpxwunix('PATH=/var/ wjscrck server >/tmp/wjscrck.out "',
                qname figparm'"',,,,,1,1)
   if xx<>0 then
      do
      say 'error' xx 'starting wjscrck'
      exit
      end
   return

/*******************************************************************/
/*******************************************************************/
stop:
   address syscall
   'msgget' qname '0'
   qid=retval
   if qid=-1 then
      do
      call say 'already stopped'
      return
      end
   type='00000003'x
   'msgsnd' qid 'msg' length(msg) '1 type'
   call ckerr 'msgsnd'
   call say 'wjscrck stopping'
   'sleep 3'
   'msgrmid' qid
   return

/*******************************************************************/
say:
   if quiet then return
   if env='AXR' then
      do
      wtomsg=arg(1)
      if wtomsg='' then
         wtomsg='.'
      call axrwto wtomsg
      end
   else
   if ofd<>-1 then
      do
      lineout=arg(1)'15'x
      address syscall 'write (ofd) lineout'
      end
    else
      say arg(1)
   return

/***************************************************/
/***************************************************/
/***************************************************/
/***************************************************/
server:
parse arg qname figparm
if substr(translate(figparm),1,2)='-D' then
   do
   diag=1
   parse var figparm . figparm
   end
 else
   diag=0
address syscall
'open /dev/console' o_wronly
ofd=retval
fd=-1
dfd=-1
types=''
'creat /var/wjssmf.ctl 700'
cfd=retval
call ckerr 'create control file'
lk.l_len=1
lk.l_start=0
lk.l_type=f_wrlck
lk.l_whence=seek_set
address syscall 'f_setlk' cfd 'lk.'
if retval=-1 then
   do
   call say 'wjscrck already started'
   exit 1
   end
/* create message queus */
'msgget' qname
qid=retval
call ckerr 'msgget'
/* create a node generate a message to make sure exit is active */
tmpname='/tmp/'userid()'.'time()
address syscall 'mkdir (tmpname) 700'
address syscall 'rmdir (tmpname)'
'msgrcv' qid 'input 30000 1'
if retval=-1 then
   do
   call say 'exit IRRSXT00 not installed'
   exit 1
   end
call config figparm
/* clear any other old messages in queue */
do forever
   'msgrcv' qid 'input 30000 1'
   if retval=-1 then leave
end
call say 'queue' qname 'ready'
numeric digits 20
call say 'wjscrck started'

/* msg mapping */
MsgFixedLen =   1
MsgVersion  =   3
MsgFunction =   5
MsgSysCall  =   9
MsgPathLen  =  13
MsgPathOffs =  15
MsgFspO     =  17
MsgFspD     =  81
MsgJobName  = 145
MsgUserName = 153
MsgMode     = 161

/* functions (irrpfc) */
irrsmf00#   =   3

do forever
   mtype='00000000'x
   'msgrcv' qid 'input 30000 0 mtype'
   call ckerr 'msgrcv'
   call dump mtype || input
   tp=c2d(mtype)
   if tp=1 then call gotrecord   /* got an input record */
   if tp=3 then leave            /* stop   */
end
call say 'wjscrck stopped'
return

/* get common fields and route to function */
gotrecord:
   version=c2d(substr(input,msgversion,2))
   function=c2d(substr(input,msgfunction,4))
   jobname=substr(input,msgjobname,8)
   username=substr(input,msgusername,8)
   if function=irrsmf00# then call fsp
   else
      call put 'not fsp'
   return

fsp:
   pother=substr(input,msgfspd+18,1)
   po$x = bitand(pother,'01'x)='01'x     /* parent o-x */
   po$w = bitand(pother,'02'x)='02'x     /* parent o-w */
   po$r = bitand(pother,'04'x)='04'x     /* parent o-r */
   pissticky = bitand(substr(input,msgfspd+23,1),'04'x)='04'x
   other=substr(input,msgfspo+18,1)
   o$w = bitand(other,'02'x)='02'x       /* new file o-w */
   o$x = bitand(other,'01'x)='01'x       /* new file o-x */
   /* isdir = bitand(substr(input,msgfspo+20,1),'80'x)='80'x */
   issticky = bitand(substr(input,msgfspo+23,1),'04'x)='04'x
   pathlen=c2d(substr(input,msgpathlen,2))
   pathoffs=c2d(substr(input,msgpathoffs,2))+1
   path=substr(input,pathoffs,pathlen)
   nodetype=substr(input,msgmode,1)
   isdir=nodetype='01'x
   isreg=nodetype='03'x
   call put o$w isdir isreg issticky po$x po$w pissticky path
   /* if rwx for parent are off, ok */
   if po$r=0 & po$w=0 & po$x=0 then
      return
   /* if dir and sticky then ok */
   if isdir & issticky then
      return
   /* rule 1: directory with o-wx and not sticky & parent o-rx   */
   if isdir & o$w & o$x & issticky=0 & po$r & po$x then
      call rpt '1' jobname username path
   /* rule 2: file with o-w and parent o-rx */
   if isreg & o$w & po$r & po$x then
         call rpt '2' jobname username path
   /* rule 3: file or dir with parent o-wx and not sticky */
   if (isreg | isdir) & po$w & po$x & pissticky=0 then
         call rpt '3' jobname username 'parent exception for' path
   return

ckerr:
if retval<>-1 then return
call say 'error on' arg(1)
call say retval errno errnojr
call bpxmtext errnojr
if qid<>-1 then
   'msgrmid' qid
exit

/* open output files */
config:
   parse arg file .
   if file='' then
      file='/dev/console'
   if diag then
      do
      'creat /tmp/'qname'.recs 700'
      dfd=retval
      end
   oflags=o_append+o_wronly+o_creat
   'open' file oflags 666
   fd=retval
   if fd=-1 then
      do
      call say 'terminating: open error for' file 'errno='errno 'rsn='errnojr
      exit 1
      end
   call say 'output to' file
   'fstat (fd) st.'
   if st.st_size=0 then
      do
      call rpt 'rule 1: directory with other w+x, not sticky',
                        'and parent with other r+x'
      call rpt 'rule 2: file with other write and parent other r+x'
      call rpt 'rule 3: file or directory with parent other w+x and not sticky'
     end
   return

/* write to diagnostic file  */
put:
   if dfd=-1 then return
   parse arg out
   out=out'15'x
   'write' dfd 'out' length(out)
   return

/* write to exception report */
rpt:
   parse arg out
   if fd<>-1 then
      do
      out='WJSCRCK' out'15'x
      'write' fd 'out' length(out)
      end
   return

/**********************************************************************/
/* formatted dump utility                                             */
/**********************************************************************/
dump:
   procedure expose fd dfd
   parse arg dumpbuf
   call put
   sk=0
   prev=''
   do ofs=0 by 16 while length(dumpbuf)>0
      parse var dumpbuf 1 ln 17 dumpbuf
      prt=c2x(substr(ln,1,4)) c2x(substr(ln,5,4)),
          c2x(substr(ln,9,4)) c2x(substr(ln,13,4)),
          "'"translate(ln,,xrange('00'x,'40'x))"'"
      if prev=prt then
         sk=sk+1
       else
         do
         if sk>0 then call put '...'
         sk=0
         prev=prt
         call put right(ofs,6)'('d2x(ofs,4)')' prt
         end
   end
   call put
   return

