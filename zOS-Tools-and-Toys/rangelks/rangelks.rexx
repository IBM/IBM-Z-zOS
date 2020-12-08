/* rexx */
/**********************************************************************/
/* List byte range lock holders                                       */
/*                                                                    */
/* PROPERTY OF IBM                                                    */
/* COPYRIGHT IBM CORP. 2005                                           */
/*                                                                    */
/* Bill Schoen (wjs@us.ibm.com)                                       */
/**********************************************************************/
arg diag
call syscalls on
address syscall

'v_reg 2 RxLocker'                /* register server as a lock server */

/**********************************************************************/
/* register locker                                                    */
/**********************************************************************/
lk.vl_serverpid=0                 /* use my pid as server pid         */
lk.vl_clientpid=1                 /* set client process id            */
'v_lockctl' vl_reglocker 'lk.'    /* register client as a locker      */
c1tok=lk.vl_lockertok             /* save client locker token         */

call runvnodes

/**********************************************************************/
/* unregister locker                                                  */
/**********************************************************************/
lk.vl_lockertok=c1tok             /* set client locker token          */
'v_lockctl' vl_unreglocker 'lk.'  /* unregister client as a locker    */

return

/**********************************************************************/
/**********************************************************************/
testlk:
   parse arg lkdev,lkfid,lkfsn,lkino         /* mcc */
   drop lk.
   lk.vl_lockertok=c1tok
   lk.vl_clienttid='thread1'
   lk.vl_objclass=0
   lk.vl_objid=right(lkdev||lkfid, 12, '00'x)
   lk.vl_objtok=obj1
   lk.l_len=0
   lk.l_start=0
   lk.l_whence=seek_set
   lk.l_type=f_wrlck
   'v_lockctl' vl_query 'lk.'
   if retval=-1 then
      do
      say 'Error testing lock on' lkfsn c2x(lkfid)':' errno errnojr
      return
      end
   if lk.l_pid<1 then return
   pid=lk.l_pid
   sysid=x2d(substr(right(d2x(pid),8,0),3,2))
   sysmsg=''
   do si=1 to maxsys
      if mems.si.1<>sysid then iterate
      sysmsg='on' mems.si.2
      leave
   end
   say 'File' c2x(lkfid) 'in' lkfsn 'locked by PID' lk.l_pid sysmsg
   ps.0=0
   if sysid=mysysid then
      'getpsent ps.'
   do lj=1 to ps.0
      if pid=ps.lj.ps_pid then
         do
         pw.=''
         'getpwuid' ps.lj.ps_ruid 'pw.'
         /* say right(ps.lj.ps_pid,12), */
         say '    'strip(pw.pw_name)'('ps.lj.ps_ruid')' ps.lj.ps_cmd
         end
   end
   numeric digits 12
   'getmntent lkmnt.' c2d(lkdev)
   if retval=-1 then return
   lkpath=lkmnt.mnte_path.1'/'
   cmd='find "'lkpath'" -xdev -inum' lkino'00'x
   if bpxwunix(cmd,,s.)=0 then
      say '    's.1
    else
      say '    path not found>>>'cmd
   return

/**********************************************************************/
/**********************************************************************/
runvnodes:

numeric digits 12
pctcmd=-2147483647
pfs='KERNEL'

z1='00'x
z2='0000'x
z4='00000000'x
laddr=0
lalet=0
llen=0
cvtecvt=140
ecvtocvt=240
ocvtocve=8
ocvtfds='58'
ocvtkds='48'
ocveppra='8'
ppralast='c'
ppraltok='10'
ppraelement='30'
pprapprp=4
ppraelementlen=8
pprpfupt='58'
fuptcwd='8'
fuptcrd='c'
fuptffdt='10'
fuptsab='70'
ffdtinuse=4
ffdtofte=12
ffdtnext='8'
ffdtlen='414'
ffdtents=64
ffdtentlen=16
ffdthdrlen=20
sabvdecount='40'
sabvdehead='44'
vdevnodeptr='8'
vdeforwardchain='18'
vdefreestate='14'
vdefreestatef='80'x
oftevnode='8'
vnodvfs='18'
ofsb='1000'
ofsbgfs='08'
ofsblen='200'
vfsnext='08'
vfsflags='34'
vfsfilesysname='38'
vfsstdev='6c'
vfsavailable='0080'x
vfslen='220'
vfsvnodhead='170'
gfsnext='08'
gfsvfs='0c'
gfspfs='10'
gfsname='18'
gfsflags='2c'
gfsdead='80'x
gfslen='80'
vnodlen='a0'
vnodino='48'
vnodfid='74'
vnodchain='88'
vnodbrlmregister='54' /* 1xxx xxxx */
vnodinuse='39' /* 1xxx xxxx */

cvt=c2x(storage(10,4))
ecvt=c2x(storage(d2x(x2d(cvt)+cvtecvt),4))
ocvt=c2x(storage(d2x(x2d(ecvt)+ecvtocvt),4))
ocve=c2x(storage(d2x(x2d(ocvt)+ocvtocve),4))

fds=storage(d2x(x2d(ocvt)+x2d(ocvtfds)),4)
kds=storage(d2x(x2d(ocvt)+x2d(ocvtkds)),4)

if fetch(fds,'00001000'x,'10') then
   do
   say 'Kernel is unavailable or at the wrong level',
                  'for this function or you are not a superuser'
   exit 1
   end
inuse=0
ix=0
call loadsysnames
call loadgfs
call loadvfs

do i=1 to gfs.0
   do j=1 to vfs.i.0
      buf=vfs.i.j
      vnodptr=ofs(vfsvnodhead,4)
      dev=ofs(vfsstdev,4)
      fsname=strip(ofs(vfsfilesysname,44))
      if fsname='' then iterate
      if mysysid>0 & mysysid<>c2d(ofs(194,1)) then
         do
         if pos('V',diag)>0 then
            say 'skipping' fsname
         iterate
         end
      if pos('V',diag)>0 then
         say 'scanning' fsname
      if pos('D',diag)>0 then
         call dump buf
      do while vnodptr<>z4
         call fetch fds,vnodptr,vnodlen
         vnodptr=ofs(vnodchain,4)
         if bitand(ofs(vnodinuse,1),'80'x)=z1 then        /* mcc */
            iterate                                       /* mcc */
         if bitand(ofs(vnodbrlmregister,1),'80'x)=z1 then
            iterate
         fid=ofs(vnodfid,8)
         ino=c2d(ofs(vnodino,4))
         call testlk dev,fid,fsname,ino
      end
   end
end

return

/**********************************************************************/
ofs:
   arg ofsx,ln
   return substr(buf,x2d(ofsx)+1,ln)

/**********************************************************************/
getofs:
   parse arg zbuf,ofsx,ln
   return substr(zbuf,x2d(ofsx)+1,ln)

/**********************************************************************/
loadgfs:
   call fetch fds,x2c(right(ofsb,8,0)),ofsblen
   ofsb.1=buf
   gfsptr=ofs(ofsbgfs,4)
   gi=0
   do while gfsptr<>z4
      call fetch fds,gfsptr,gfslen
      gfsptr=ofs(gfsnext,4)
      if bitand(ofs(gfsflags,1),gfsdead)<>z1 then
         iterate
      gi=gi+1
      gfs.gi=buf
   end
   gfs.0=gi
   return

/**********************************************************************/
loadsysnames:
   ocvenxab='84'
   nxabnxmb='14'
   nxmbmaxsys='18'
   nxmbmemar='30'
   nxmbarsysname='8'
   nxmbarsysnum='0'
   nxmbarstat='4'
   memarlen=32
   mysysid=0
   call fetch z4,x2c(ocve),140
   nxab=c2x(ofs(ocvenxab,4))
   if nxab=0 then
      do
      maxsys=0
      return
      end
   call fetch z4,x2c(nxab),32
   nxmb=c2x(ofs(nxabnxmb,4))
   call fetch z4,x2c(nxmb),56
   memar=c2x(ofs(nxmbmemar,4))
   maxsys=c2d(ofs(nxmbmaxsys,4))
   call fetch z4,x2c(memar),memarlen*maxsys
   do mems=1 to maxsys
      if bitand('80'x,ofs(nxmbarstat,1))=z1 then
         do
         mems.mems.1=0
         mems.mems.2='unknown'
         end
       else
         do
         mems.mems.1=c2d(ofs(nxmbarsysnum,1))
         mems.mems.2=ofs(nxmbarsysname,8)
         end
      buf=substr(buf,memarlen+1)
   end
   address syscall 'uname unm.'
   do si=1 to maxsys
      if unm.2<>mems.si.2 then iterate
      mysysid=mems.si.1
      say 'Looking for locks managed on' unm.2
      leave
   end
   return

/**********************************************************************/
loadvfs:
   do i=1 to gfs.0
      j=0
      vfsptr=getofs(gfs.i,gfsvfs,4)
      do while vfsptr<>z4
         call fetch fds,vfsptr,vfslen
         vfslast=vfsptr
         vfsptr=ofs(vfsnext,4)
         if bitand(ofs(vfsflags,2),vfsavailable)<>z2 then
            iterate
         j=j+1
         vfs.i.j=buf
         vfs.i.j.0=vfslast
      end
      vfs.i.0=j
   end
   vfs.0=gfs.0
   return
/**********************************************************************/
fetch:
   parse arg alet,addr,len,eye  /* char: alet,addr  hex: len */
   len=x2c(right(len,8,0))
   dlen=c2d(len)
   buf=alet || addr || len
   'pfsctl' pfs pctcmd 'buf' max(dlen,12)
   if retval=-1 then
      return 1
   if rc<>0 then
      do
      say 'buf:' c2x(buf)
      say 'len:' max(dlen,12)
      signal halt
      end
   if eye<>'' then
      if substr(buf,1,length(eye))<>eye then
         return 1
   if dlen<12 then
      buf=substr(buf,1,dlen)
   return 0

/**********************************************************************/
dump: procedure
   parse arg dumpbuf
   sk=0
   do ofs=0 by 16 while length(dumpbuf)>0
      parse var dumpbuf 1 ln 17 dumpbuf
      out=c2x(substr(ln,1,4)) c2x(substr(ln,5,4)),
          c2x(substr(ln,9,4)) c2x(substr(ln,13,4)),
          "'"translate(ln,,xrange('00'x,'40'x))"'"
      if prev=out then
         sk=sk+1
       else
         do
         if sk>0 then say '...'
         sk=0
         prev=out
         say right(ofs,6)'('d2x(ofs,4)')' out
         end
   end
   return
