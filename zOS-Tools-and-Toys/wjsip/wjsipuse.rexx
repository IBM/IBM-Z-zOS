/** REXX **************************************************************
**                                                                   **
** Copyright 2013-2021 IBM Corp.                                     **
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
/* WJSIPUSE:  show file system usage for function shipping clients    */
/*                                                                    */
/*    This tool will run under IPCS or on a live system.              */
/*    You must be a superuser to run on a live system.                */
/*    This will search for file systems that are function shipping    */
/*    to another system and have significant local access.  Use this  */
/*    to help evaluate wheer users and file systems should reside.    */
/*    File systems with less than 10,000 requests are skipped.        */
/*                                                                    */
/*   Syntax:                                                          */
/*    wjsipuse <-i | -i interval> <-o> <-l>                           */
/*      if no options are specified, the number of file system        */
/*      requests is shown.                                            */
/*      -i    is specified when running against a live system, the    */
/*            tool will collect the data, wait an interval, recollect */
/*            the data and show the activity in that interval.  If an */
/*            interval is not specified 10 seconds is used.           */
/*            Interval is in seconds.                                 */
/*      -l    forces the tool to run on the live system even if       */
/*            running with ipcs.                                      */
/*      -o    organizes the report by owning system and includes      */
/*            locally mounted file systems.                           */
/*                                                                    */
/*    Return codes:                                                   */
/*       0    did not run successfully                                */
/*       4    nothing found                                           */
/*       8    one or more file systems may have significant           */
/*            function shipping                                       */
/*                                                                    */
/* PROPERTY OF IBM                                                    */
/* COPYRIGHT IBM CORP. 2007,2021                                      */
/*                                                                    */
/* Bill Schoen    wjs@us.ibm.com   9/24/07                            */
/*  Change activity:                                                  */
/*    11/9/07  added sysnames, interval                               */
/*   11/12/08  added mountpoint, enabled for shell and sysrexx        */
/*   04/24/09  usage in K units, added -o option                      */
/*   03/07/16  restructured for vfs changes, added threshold          */
/*   02/24/21  seteuid 0 on live system                               */
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
myeuid=-1
address mvs 'subcom IPCS'
if rc then
   do
   address syscall 'geteuid'
   if retval>0 then
      do
      myeuid=retval
      address syscall 'seteuid 0'
      end
   end
signal wjsidinit
/* help information goes immediately below signal wjsidinit
*** USE ***

Options:  -i [<interval>]  is specified when running against a live system, the
                        tool will collect the data, wait an interval, recollect
                        the data and show the activity in that interval.  If an
                        interval is not specified 10 seconds is used.
                        Interval is in seconds.
          -l    forces the tool to run on the live system even if
                running with ipcs.
          -o    organizes the report by owning system and includes
                locally mounted file systems.
          -t <threshold>  specify minimum level of activity to report
                          Default: 10000
*/
wjsidstart:
if myeuid>0 then
   address syscall 'seteuid (myeuid)'

call parseopts 'i o l t'
if opt.!l=1 then
   ipcs=0
if opt.!o=1 then
   showowners=1
 else
   showowners=0
threshold=opt.!t
if threshold='' | datatype(threshold,'W')=0 then
   threshold=10000
interval=opt.!i
if interval='' | datatype(interval,'W')=0 then
   interval=10
if ipcs then
   do
   interval=''
   signal on syntax
   call wjsifast 'q'
   syntax:
   signal off syntax
   end
exit start()

start:
gotone=0
gotone.=0
call main
if gotone=0 then
   do
   call say 'nothing found'
   return 4
   end
if interval<>'' then
   do
   say interval 'second interval wait...'
   address syscall 'sleep 10'
   say
   count=gotone
   call main
   gotone.0=count
   end
call say '  Usage(K) Owner    PFS     ' left('File system name',44),
         'Mountpoint'
call say
rv=4
do i=1 to gotone.0
   if gotone.i.4=1 then iterate /* skip locals */
   fsname=gotone.i
   count=format(gotone.fsname/1000,,0)
   if count=0 then iterate
   if gotone.fsname.1=0 & interval<>'' then iterate
   if length(count)<10 then
      count=right(count,10)
   if showowners=0 then
      call say count left(gotone.i.1,8),
            gotone.i.2 left(fsname,44) gotone.i.3
   rv=8
end
if showowners then
   do
   do sn=1 to 32
      if sn=sysid then iterate
      if sysnames.sn='' then iterate
      sysname=sysnames.sn
      call say 'Client to owner:' sysname
      call say
      call report
      call say
   end
   call say 'Local mounts owned by this system'
   call say 'Note: these counts may include both local and client',
            'requests'
   sysname=sysnames.sysid
   call report 1
   call say
   call say 'Local mounts owned by other systems'
   call report 2
   call say
   end
return rv

report:
   do i=1 to gotone.0
      local= gotone.i.4=1
      owner=left(gotone.i.1,8)
      fsname=gotone.i
      pfs=gotone.i.2
      mountpoint=gotone.i.3
      if arg(1)='' & local then iterate
      if arg(1)='' & owner<>sysname then iterate
      if arg(1)=1 & owner<>sysname then iterate
      if fsname='' then iterate
      gotone.i=''
      count=format(gotone.fsname/1000,,0)
      if count=0 then iterate
      if gotone.fsname.1=0 & interval<>'' then iterate
      if length(count)<10 then
         count=right(count,10)
      call say count owner pfs left(fsname,44) mountpoint
   end
return

main:
if ipcs=0 then
   do
   address syscall 'geteuid'
   myeuid=retval
   address syscall 'seteuid 0'
   end
call getsysnames
i=0
lsetnm='SYS.BPX.A000.FSLIT.FILESYS.LSN '

/*
for each gfs
   for each active vfs
      if function shipping
         get latch
         show counts
*/
call rungfs
if ipcs=0 then
   address syscall 'seteuid (myeuid)'
return

gfsexit:
   call runvfs
   return 0

vfsexit:
   if vfsavail | vfsdead | vfsperm then return 0
   local = client=0
   if local & showowners<>1 then return 0
   fsowner=x2d(getstor(xadd(vfs@,'194'),1,kasid,fds))
   fspath=x2c(getstor(xadd(vfs@,'a0'),16,kasid,fds))
   owner=sysnames.fsowner
   flcb@=getstor(xadd(vfs@,'1c'),4,kasid,fds)
   latnum=x2d(getstor(xadd(flcb@,'04'),4,kasid,fds))
   latch=findlatch(lsetnm,latnum)
   fast=x2d(extr(latch,'10',4))
   slow=x2d(extr(latch,'14',4))
   obtains=fast+slow
   if obtains<threshold then return 0
   gotone=gotone+1
   gotone.0=gotone
   if gotone.vfsname=0 then
      do
      gotone.gotone=vfsname
      gotone.vfsname=obtains
      gotone.gotone.1=owner
      gotone.gotone.2=gfsname
      gotone.gotone.3=fspath
      gotone.gotone.4=local
      end
    else
      do
      gotone.vfsname=obtains-gotone.vfsname
      gotone.vfsname.1=1
      end
   return 0

findlatch:
   arg setname,latchnum
   lset@=getstor(d2x(x2d(ocve)+64),4,kasid)
   do while lset@<>0
      lset=getstor(lset@,128,kasid)
      name=x2c(extr(lset,'30',48))
      if name=setname then leave
      lset@=extr(lset,'0c',4)
   end
   if lset@=0 then
      do
      say 'error locating latch' latchnum 'in' setname
      return ''
      end
   lsetver=x2d(extr(lset,'70',2))
   if lsetver=0 then
      lsetlen=128
    else
      lsetlen=256
   latlen=32
   lat@=d2x(x2d(lset@)+lsetlen+latlen*latchnum)
   latch=getstor(lat@,latlen,kasid)
   return latch

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

