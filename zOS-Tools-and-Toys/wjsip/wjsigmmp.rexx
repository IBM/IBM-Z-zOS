/* REXX */
/**********************************************************************/
/* WJSIGMMP:  show mmap information                                   */
/*                                                                    */
/*    This will show information on mmaped files.                     */
/*    This tool will run under IPCS or on a live system.              */
/*    You must be a superuser to run on a live system                 */
/*                                                                    */
/*   Syntax:                                                          */
/*    wjsigmmp [-p]                                                   */
/*                                                                    */
/* PROPERTY OF IBM                                                    */
/* COPYRIGHT IBM CORP. 2008,2019                                      */
/*                                                                    */
/* Bill Schoen    wjs@us.ibm.com   5/21/2019                          */
/*  Change activity:                                                  */
/*  5/22/2019 cache paths with -p                                     */
/*                                                                    */
/**********************************************************************/
parse arg stack
if stack='STACK' then
   do
   do i=1 to sourceline()
      queue sourceline(i)
   end
   return
   end
signal wjsidinit
/* help information goes immediately below signal wjsidinit
*** MMP ***
Show information on mmaped files

Options: -p    find full path names (only valid on a live system)
*/
wjsidstart:

call parseopts 'p'
findpaths= ipcs=0 & opt.!p=1

ocvegyab='78'
gyabgyvf='24'
gyvfnext='08'
gyvfgyvr='20'
gyvfdev ='0C'
gyvfino ='14'
gyvfpath='2C'   /* 64 */
gyvrnext='08'
gyvrgyac='2C'
gyvrrngs='1C'
gyacnext='08'
gyacgymm='10'
gymmnext='08'
gymmmapl='10'
gymmpid ='14'
gymmdev ='30'
gymmfid ='34'   /* 8 */
gymmino ='38'   /* 4 */
gymmtype='40'   /* 1 */
gyab=getstor(xadd(ocve,ocvegyab),4,kasid)
if gyab=0 then
   do
   call say 'no mmap anchor found'
   return
   end
gyvf=getstor(xadd(gyab,gyabgyvf),4,kasid)
if gyvf=0 then
   do
   call say 'no mapped files found'
   return
   end
if ipcs then
   ps.0=0
 else
   address syscall 'getpsent ps.'
call say right('Pages',8) right('PID',10) right('User',8) '(dev/ino)Pathname'
totalmapl=0
totalpages=0
path.=''
do while gyvf<>0
   gyvr=getstor(xadd(gyvf,gyvfgyvr),4,kasid)
   vfino=x2d(getstor(xadd(gyvf,gyvfino),4,kasid))
   vfdev=x2d(getstor(xadd(gyvf,gyvfdev),4,kasid))
   path=x2c(getstor(xadd(gyvf,gyvfpath),64,kasid))
   path=translate(path,' ',xrange('00'x,'3f'x))
   if findpaths & path.vfdev.vfino='' then
      do
      out.=''
      mnt.=''
      address syscall 'getmntent mnt.' vfdev
      if mnt.7.1<>'' then
         do
         call bpxwunix 'find' mnt.7.1 '-xdev -inum' vfino,,'out.','err.'
         if out.1<>'' then
            path.vfdev.vfino=out.1
         end
      end
   if path.vfdev.vfino<>'' then
      path=path.vfdev.vfino
   call rungyvr
   gyvf=getstor(xadd(gyvf,gyvfnext),4,kasid)
end
call say 'Total mmap pages' totalpages
return

rungyvr:
   do while gyvr<>0
      vrrngs=x2d(getstor(xadd(gyvr,gyvrrngs),4,kasid))
      vrrngs=(vrrngs+4095)%4096   /* size in pages */
      totalpages=totalpages+vrrngs
      gyac=getstor(xadd(gyvr,gyvrgyac),4,kasid)
      call rungyac
      gyvr=getstor(xadd(gyvr,gyvrnext),4,kasid)
   end
   return

rungyac:
   do while gyac<>0
      gymm=getstor(xadd(gyac,gyacgymm),4,kasid)
      gyac=getstor(xadd(gyac,gyacnext),4,kasid)
      if gymm=0 then
         iterate
      mapl=x2d(getstor(xadd(gymm,gymmmapl),4,kasid))
      totalmapl=totalmapl+mapl
      pid =x2d(getstor(xadd(gymm,gymmpid),4,kasid))
      dev =x2d(getstor(xadd(gymm,gymmdev),4,kasid))
      ino =x2d(getstor(xadd(gymm,gymmino),4,kasid))
      type=getstor(xadd(gymm,gymmtype),1,kasid)
      /*  use size from vr
      k=1024
      m=k*1024
      g=m*1024
      if mapl<=k then
         mapl=mapl' '
      else
      if mapl<=m then
         mapl=(mapl+k-1)%k'K'
      else
      if mapl<g then
         mapl=(mapl+m-1)%m'M'
      else
         mapl=(mapl+g-1)%g'G'
      */
      user=''
      do i=1 to ps.0
         if pid<>ps.i.ps_pid then iterate
         pw.=''
         address syscall 'getpwuid' ps.i.ps_euid 'pw.'
         if pw.pw_name<>'' then
            user=pw.pw_name
         leave
      end
      call say right(vrrngs,8) right(pid,10) right(strip(user),8) '('dev'/'ino')'path
      rngs=''
   end
   return

/* REXX */
/**********************************************************************/
/*       general utilities                                            */
/*                                                                    */
/* setglobals                                                         */
/*    alet. cvt, ecvt, ocvt, kasid, fds, asvt, ascb, assb, stok, ocve */
/*    symx, ipcs, asfsds                                              */
/* getsysnames                                                        */
/* formatcb                                                           */
/* rungfs     (see below for doc)                                     */
/* runvfs     (see below for doc)                                     */
/* runvnod    (see below for doc)                                     */
/* getstor                                                            */
/* extr                                                               */
/* say                                                                */
/* gettod                                                             */
/* toddiff                                                            */
/* e2tod                                                              */
/* tod2e                                                              */
/* xadd                                                               */
/* dump                                                               */
/* fixaddr                                                            */
/*                                                                    */
/**********************************************************************/
parse arg parm
if parm='STACK' then
   do
   do i=1 to sourceline()
      queue sourceline(i)
   end
   return
   end

novalue:
   say 'uninitialized variable in line' sigl
   say sourceline(sigl)
halt:
   exit 0

wjsidinit:
   helpline=sigl+2
   signal on novalue
   signal on halt
   call syscalls 'ON'
   parse arg parms
   parm=parms
   parse source . . . . . . . rxenv .
   address mvs 'subcom IPCS'
   if rc then
      do
      ipcs=0
      symx=''
      end
    else
      do
      ipcs=1
      address ipcs 'evalsym x rexx(address(symx))'
      end
   if wordpos('?',parms)>0 then
      signal parseoptshelp
   numeric digits 12
   call setglobals
   signal wjsidstart

setglobals:
   alet.=''
   cvtecvt=140
   ecvtocvt=240
   ocvtocve=8
   z4='00000000'x
   z1='00'x
   formatop=''
   viewop=''
   cvt=getstor(10,4,1)
   ecvt=getstor(d2x(x2d(cvt)+cvtecvt),4,1)
   ocvt=fixaddr(getstor(d2x(x2d(ecvt)+ecvtocvt),4,1))
   kasid=x2d(getstor(d2x(x2d(ocvt)+x2d('18')),2,1))
   fds=getstor(d2x(x2d(ocvt)+x2d('58')),4,1)
   alet.fds='SYSZBPX2'
   kds=getstor(d2x(x2d(ocvt)+x2d('48')),4,1)
   alet.kds='SYSZBPX1'
   asvt=getstor(d2x(x2d(cvt)+556),4,kasid)
   ascb=getstor(d2x(x2d(asvt)+528+kasid*4-4),4,kasid)
   assb=getstor(d2x(x2d(ascb)+x2d('150')),4,kasid)
   stok=getstor(d2x(x2d(assb)+48),8,kasid)
   ocve=getstor(d2x(x2d(ocvt)+ocvtocve),4,kasid)
   asfsds='asid('kasid') dspname(syszbpx2)'
   return

/**********************************************************************/
getsysnames:
   sysnames.=''
   sysid=''
   nxab=getstor(d2x(x2d(ocve)+x2d('84')),4,kasid)
   if nxab=0 then return
   nxmb=getstor(d2x(x2d(nxab)+x2d('14')),4,kasid)
   nxar=getstor(d2x(x2d(nxmb)+x2d('30')),4,kasid)
   sysid=x2d(getstor(d2x(x2d(nxmb)+x2d('c')),1,kasid))
   nxarl=32*x2d(getstor(d2x(x2d(nxmb)+x2d('18')),4,kasid))
   nxarray=getstor(nxar,nxarl,kasid)
   sysnames.=''
   do i=0 by 32 to nxarl-1
      nxent=extr(nxarray,d2x(i),32)
      entid=x2d(extr(nxent,0,1))
      if entid=0 then iterate
      entname=x2c(extr(nxent,8,8))
      sysnames.entid=entname
   end
   return

/**********************************************************************/
/* options parser                                                     */
/**********************************************************************/
parseopts:
   goodopts=translate(arg(1)) '#F #V'
   if wordpos('?',parms)>0 then
      do
      parseoptshelp:
      do i=helpline to sourceline()
         src=sourceline(i)
         if substr(src,1,1)='*' & substr(src,2,1)='/' then leave
         call say src
      end
      exit
      end
   opts=translate(parms)
   opt.=''
   opt.0=0
   opti=0
   do while opts<>''
      parse var opts pre '-' opt opts
      if pre='' & opt<>'' & wordpos(opt,goodopts)=0 then
         pre=opt
      if pre<>'' then
         do
         call say pre 'is not a valid option'
         signal parseoptshelp
         end
      if opt='' then leave
      opts=strip(opts)
      optval=''
      if substr(opts,1,1)<>'-' then
         parse var opts optval opts
      if optval='' then
         optval=1
      opti=opti+1
      opt.0=opti
      opt.opti=opt
      call value 'OPT.!'opt,optval
   end
   formatop=opt.!#f
   viewop=opt.!#v
   if rxenv='ISPF' then
      do
      address ispexec 'vget (wjsifmt wjsiview) profile'
      if formatop='' | formatop=1 then
         formatop = wjsifmt
      if viewop='' | viewop=1 then
         viewop=wjsiview
      end
   return

/**********************************************************************/
/* this formats or dumps a control block                              */
/*    args:  data to format (only used if non-ipcs)                   */
/*           cbgen formatter name                                     */
/*           address if ipcs                                          */
/*           ipcs formatter name                                      */
/*                                                                    */
/**********************************************************************/
formatcb:
   parse arg cb,cbgen,ipaddr,ipformat,ipsetdef
   if symbol('getvar@')='LIT' then   /* first call initialization */
      do
      getvar@=wjsib@ad()      /* see if wjsrx@ is available 1=no 0=yes */
      cbgen.=0
      end
   if ipsetdef<>'' & ipcs then
      address ipcs 'setdef local' ipsetdef
   if formatop='I' then
      if ipformat<>'' then
         do
         address ipcs 'cbf' ipaddr ipformat
         return
         end
   if (ipaddr='' | ipcs=0) & getvar@=0 then
      ipaddr=c2x(wjsrx@('CB'))
   if (ipcs | getvar@=0) & cbgen.cbgen=0 then
      do
      cbrc=wjsib@ca(cbgen ipaddr)
      if cbrc>1 then signal halt
      if cbrc=1 then
         do
         cbgen.cbgen=1
         call say '** cbgen formatter' cbgen 'not found **'
         end
       else
         return
      end
   if ipcs & ipformat<>'' then
      address ipcs 'cbf' ipaddr ipformat
    else
      call dump cb
   return

/**********************************************************************/
/* this runs the gfs chain and calls an exit routine for each gfs     */
/* gfsexit  the routine name that gets control for each gfs           */
/*          preset variables:  gfs@    address of gfs                 */
/*                             gfsname name of the pfs                */
/*          return 1 do not run the vfs chain                         */
/*          return 0 run the vfs chain                                */
/*                                                                    */
/**********************************************************************/
rungfs:
   gfs@@=getstor('1008',4,kasid,fds)
   do while gfs@@<>0
      gfs@=gfs@@
      gfs@@=getstor(xadd(gfs@,'08'),4,kasid,fds)
      gfsname=x2c(getstor(xadd(gfs@,'18'),8,kasid,fds))
      if gfsexit() then return 1
   end
   return 0

/**********************************************************************/
/* this runs the vfs chain and calls an exit routine for each vfs     */
/* for the current gfs                                                */
/* vfsexit  the routine name that gets control for each vfs           */
/*          preset variables:  vfs@    address of vfs                 */
/*                             vfsname name of the file system        */
/*          flags are also set: ro, rw, unmnt, vfsavail, vfsdead,     */
/*                              quiesced, vfsperm, client,            */
/*                              sfmsg: text line for flag bits        */
/*                                                                    */
/**********************************************************************/
runvfs:
   vfs@@=getstor(xadd(gfs@,'0c'),4,kasid,fds)
   do while vfs@@<>0
      vfsid=x2c(getstor(xadd(vfs@@,'00'),4,kasid,fds))
      if vfsid='VFSQ' then
         do
         vfs@=getstor(xadd(vfs@@,'10'),4,kasid,fds)
         vfs@@=getstor(xadd(vfs@@,'08'),4,kasid,fds)
         if vfs@=0 then iterate
         end
       else
         do
         vfs@=vfs@@
         vfs@@=getstor(xadd(vfs@@,'08'),4,kasid,fds)
         end
      vfsname=x2c(getstor(xadd(vfs@,'38'),44,kasid,fds))
      flags=x2c(getstor(xadd(vfs@,'34'),4,kasid,fds))
      call setflags
      if vfsexit() then return 1
   end
   return 0

setflags:
   sfmsg=''
   ro=bitand('80000000'x,flags)=='80000000'x
   rw=bitand('40000000'x,flags)=='40000000'x
   unmnt=bitand('10000000'x,flags)=='10000000'x
   vfsavail=bitand('00800000'x,flags)=='00800000'x
   vfsdead=bitand('00400000'x,flags)=='00400000'x
   quiesced=bitand('00040000'x,flags)=='00040000'x
   vfsperm=bitand('00004000'x,flags)=='00004000'x
   client=bitand('00000002'x,flags)=='00000002'x
   if ro then sfmsg='R/O'
   if rw then sfmsg='R/W'
   if client then sfmsg=sfmsg 'Client'
     else         sfmsg=sfmsg 'Local '
   if unmnt then sfmsg=sfmsg 'Unmount'
   if quiesced then sfmsg=sfmsg 'Quiesced'
   return sfmsg

/**********************************************************************/
/* this runs the vnod chain and calls an exit routine for each vnod   */
/* for the current vfs                                                */
/* vnodexit the routine name that gets control for each vnod          */
/*          preset variables:  vnod@   address of vnod                */
/*                                                                    */
/**********************************************************************/
runvnod:
   parse arg vnod@@
   if vnod@@='' then
      vnod@@=getstor(xadd(vfs@,'2c'),4,kasid,fds)
   do while vnod@@<>0
      vnod@=vnod@@
      vnod@@=getstor(xadd(vnod@,'88'),4,kasid,fds)
      if vnodexit() then return 1
   end
   return 0

/**********************************************************************/
getstor: procedure expose ipcs rxenv  alet. kasid
   arg $adr,$len,$asid,$alet
   if $asid='' then
      $asid=kasid
   $dspname=alet.$alet
   $c1=x2d(substr($adr,1,1))
   if length($adr)>7 & $c1>7 then
      do
      $c1=$c1-8
      $adr=$c1 || substr($adr,2)
      end
   if $asid='' then
      do
      say 'missing asid'
      i=1/0 /* get traceback */
      end
   opts='asid('$asid')'
   if $dspname<>'' then
      opts=opts 'DSPNAME('$dspname')'
   call $fetch$ $adr,$len,$alet,opts
   return cbx

/**********************************************************************/
getstor64: procedure expose ipcs rxenv alet. kasid
   arg $adr,$len,$asid
   if $asid='' then
      $asid=kasid
   $adr=right($adr,16,0)
   if $asid='' then
      do
      say 'missing asid'
      i=1/0 /* get traceback */
      end
   opts='asid('$asid')'
   call $fetch$ $adr,$len,0,opts
   return cbx

/**********************************************************************/
$fetch$:
   arg addr,cblen,alet,opts
   addr=fixaddr(addr)
   cbx=''
   if ipcs then
      do while cblen>0
         if cblen>512 then
            i=512
          else
            i=cblen
         address ipcs 'EVALUATE' addr'. LENGTH('i') REXX(STORAGE(CBS))',
               translate(opts)
         if rc<>0 then
            do
            call say 'Storage not available, addr:' addr ' len:' i
            return 1
            end
         cbx=cbx||cbs
         drop cbs
         cblen=cblen-i
         addr=d2x(x2d(addr)+i)
      end
    else
    if length(addr)<16 then
      do
      len=d2c(right(cblen,8,0),4)
      addrc=d2c(x2d(addr),4)
      aletc=d2c(x2d(alet),4)
      cbs=aletc || addrc || len
      address syscall 'pfsctl KERNEL -2147483647 cbs' max(cblen,12)
      if retval=-1 then
         do
         call say 'Error' errno errnojr 'getting storage at' arg(1),
                  'for length' cblen
         exit
         end
      cbx=c2x(substr(cbs,1,cblen))
      end
    else
      do
      len=d2c(right(cblen,8,0),4)
      addrc=d2c(x2d(addr),8)
      cbs=addrc || len
      address syscall 'pfsctl KERNEL -2147483646 cbs' max(cblen,12)
      if retval=-1 then
         do
         call say 'Error' errno errnojr 'getting storage64 at' arg(1),
                  'for length' cblen
         exit
         end
      cbx=c2x(substr(cbs,1,cblen))
      end
   return 0

/**********************************************************************/
extr:
   return substr(arg(1),x2d(arg(2))*2+1,arg(3)*2)

/**********************************************************************/
fixaddr: procedure
   if length(arg(1))>8 then return arg(1)
   fa=right(arg(1),8,0)
   fa1=x2d(substr(fa,1,1))
   if fa1>7 then
      do
      fa1=fa1-8
      fa=fa1 || substr(fa,2)
      end
   return fa

/**********************************************************************/
say:
   trace o
   pl=translate(arg(1),,"'"xrange('00'x,'3f'x))
   if ipcs then
      address ipcs "NOTE '"pl"' ASIS"
    else
      if rxenv='AXR' then
         call axrwto pl
       else
         say pl
   return

/**********************************************************************/
gettod:
   numeric digits 20
   tz=x2d(getstor(d2x(x2d(cvt)+x2d(130)),4),4)
   tz=format(tz*1.04852,,0)*4096000000
   if ipcs then
      do
      address ipcs "EVALUATE 48. LENGTH(8) REXX(STORAGE(LOCTOD)) HEADER"
      gmt=d2x(x2d(loctod)-tz)
      end
    else
      do
      address syscall 'time'
      gmt=e2tod(retval)
      end
   return gmt

/**********************************************************************/
tod2e:
   numeric digits 22
   arg htod
   tod1970=9048018124800000000
   todsec=4096000000
   pt=x2d(htod'00000000')-tod1970
   if pt<0 then return 0
   return format(pt/todsec,,0)

/**********************************************************************/
toddiff:
   numeric digits 22
   parse arg new,old
   diff=x2d(new)-x2d(old)
   return format((diff%4096000)/1000,,3)

/**********************************************************************/
e2tod: procedure
   arg etime
   numeric digits 20
   i=etime*2*x2d('7A120000')
   i=i+x2d('7D91048BCA000000')
   tod=d2x(i)
   return tod

/**********************************************************************/
xadd: procedure
   return d2x(x2d(arg(1))+x2d(arg(2)))

/**********************************************************************/
/* formatted dump utility                                             */
/**********************************************************************/
dump:
   procedure expose ipcs rxenv
   parse arg dumpbuf,start
   sk=0
   prev=''
   do ofs=0 by 16 while length(dumpbuf)>0
      parse var dumpbuf 1 ln 17 dumpbuf
      out=c2x(substr(ln,1,4)) c2x(substr(ln,5,4)),
          c2x(substr(ln,9,4)) c2x(substr(ln,13,4)),
          "*"ln"*"
      if prev=out then
         sk=sk+1
       else
         do
         if sk>0 then call say '...'
         sk=0
         prev=out
         if start='' then
            pref=''
          else
            pref=xadd(start,d2x(ofs))
         call say pref right(ofs,6)'('d2x(ofs,4)')' out
         end
   end
   return

