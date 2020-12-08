/* REXX */
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
/* COPYRIGHT IBM CORP. 2007,2009                                      */
/*                                                                    */
/* Bill Schoen    wjs@us.ibm.com   9/24/07                            */
/*  Change activity:                                                  */
/*    11/9/07  added sysnames, interval                               */
/*   11/12/08  added mountpoint, enabled for shell and sysrexx        */
/*   04/24/09  usage in K units, added -o option                      */
/*                                                                    */
/**********************************************************************/
signal on novalue
signal on halt
call syscalls 'ON'
address mvs 'subcom IPCS'
if rc then
   ipcs=0
 else
   ipcs=1
arg prms
interval=''
if pos('-L',prms)>0 then
   do
   parse var prms pre '-L' post
   prms=pre post
   ipcs=0
   end
if pos('-O',prms)>0 then
   do
   parse var prms pre '-O' post
   prms=pre post
   showowners=1
   end
 else
   showowners=0
if pos('-I',prms)>0 then
   do
   parse var prms pre '-I' interval post
   prms=pre post
   if interval='' | datatype(interval,'W')=0 then
      interval=10
   end
if ipcs then interval=''
if prms<>'' then
   do
   call say 'syntax: wjsipuse <-i | -i interval>'
   exit
   end
if ipcs then
   do
   signal on syntax
   call wjsifast 'q'
   syntax:
   signal off syntax
   end
exit start()

novalue:
  say 'uninitialized variable in line' sigl
  say sourceline(sigl)
halt:
  exit 0

start:
gotone=0
gotone.=0
numeric digits 12
call initialize
call main
if gotone=0 then return 4
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
numeric digits 20
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

initialize:
   opts=''
   fdsn='SYSZBPX2'
   pfs='KERNEL'
   pctcmd=-2147483647
   z4='00000000'x
   z1='00'x

   cvtecvt=140
   ecvtocvt=240
   ocvtocve=8
   return

main:
cvt=getstor(10,4,1)
ecvt=getstor(d2x(x2d(cvt)+cvtecvt),4,1)
ocvt=getstor(d2x(x2d(ecvt)+ecvtocvt),4,1)
kasid=x2d(getstor(d2x(x2d(ocvt)+x2d('18')),2,1))
fds=getstor(d2x(x2d(ocvt)+x2d('58')),4,1)

asvt=getstor(d2x(x2d(cvt)+556),4,kasid)
ascb=getstor(d2x(x2d(asvt)+528+kasid*4-4),4,kasid)
assb=getstor(d2x(x2d(ascb)+x2d('150')),4,kasid)
stok=getstor(d2x(x2d(assb)+48),8,kasid)

ocve=getstor(d2x(x2d(ocvt)+ocvtocve),4,kasid)
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
threshold=10000
gfs@=getstor('1008',4,kasid,fds,fdsn)
gfsvfs='0c'
vfsnm='38'
vfscnt=0
numeric digits 20
do while gfs@<>0
   gfs=getstor(gfs@,48,kasid,fds,fdsn)
   gfs@=extr(gfs,'08',4)
   vfs@=extr(gfs,gfsvfs,4)
   gfsname=x2c(extr(gfs,'18',8))
   do while vfs@<>0
      vfscnt=vfscnt+1
      vfs=getstor(vfs@,500,kasid,fds,fdsn)
      vfs@=extr(vfs,'08',4)
      flags=x2c(extr(vfs,'35',1))
      if bitand(flags,'c0'x)<>z1 then
         iterate           /* skip dead and available */
      flags=x2c(extr(vfs,'36',1))
      if bitand(flags,'40'x)<>z1 then
         iterate           /* skip permanent */
      flags=x2c(extr(vfs,'37',1))
      local = bitand(flags,'02'x)=z1
      if local & showowners<>1 then
         iterate           /* skip locally mounted */
      fsname=x2c(extr(vfs,'38',44))
      fsowner=x2d(extr(vfs,'194',1))
      fspath=x2c(extr(vfs,'a0',16))
      owner=sysnames.fsowner
      flcb@=extr(vfs,'1c',4)
      flcb=getstor(flcb@,8,kasid,fds,fdsn)
      latnum=x2d(extr(flcb,'04',4))
      latch=findlatch(lsetnm,latnum)
      fast=x2d(extr(latch,'10',4))
      slow=x2d(extr(latch,'14',4))
      obtains=fast+slow
      if obtains<threshold then iterate
      gotone=gotone+1
      if gotone.fsname=0 then
         do
         gotone.gotone=fsname
         gotone.fsname=obtains
         gotone.gotone.1=owner
         gotone.gotone.2=gfsname
         gotone.gotone.3=fspath
         gotone.gotone.4=local
         end
       else
         do
         gotone.fsname=obtains-gotone.fsname
         gotone.fsname.1=1
         end
   end
end
gotone.0=gotone

return

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
   do i=0 by 32 to nxarl-1
      nxent=extr(nxarray,d2x(i),32)
      entid=x2d(extr(nxent,0,1))
      if entid=0 then iterate
      entname=x2c(extr(nxent,8,8))
      sysnames.entid=entname
   end
   return

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

/**********************************************************************/
getstor: procedure expose ipcs pfs pctcmd
   arg $adr,$len,$asid,$alet,$dspname
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
   call fetch $adr,$len,$alet,opts
   return cbx

/**********************************************************************/
extr:
   return substr(arg(1),x2d(arg(2))*2+1,arg(3)*2)

/**********************************************************************/
fetch:
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
      do
      len=d2c(right(cblen,8,0),4)
      addrc=d2c(x2d(addr),4)
      aletc=d2c(x2d(alet),4)
      cbs=aletc || addrc || len
      retval=-1
      address syscall 'pfsctl' pfs pctcmd 'cbs' max(cblen,12)
      if retval=-1 then
         do
         call say 'Error' errno errnojr 'getting storage at' arg(1),
                  'for length' cblen
         exit
         end
      cbx=c2x(substr(cbs,1,cblen))
      end
   return 0

/**********************************************************************/
fixaddr: procedure
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
   parse arg pl
   if ipcs then
      address ipcs "NOTE '"pl"' ASIS"
    else
      say pl
   return


/**********************************************************************/
/* formatted dump utility                                             */
/**********************************************************************/
dump:
   procedure expose ipcs
   parse arg dumpbuf
   sk=0
   prev=''
   do ofs=0 by 16 while length(dumpbuf)>0
      parse var dumpbuf 1 ln 17 dumpbuf
      out=c2x(substr(ln,1,4)) c2x(substr(ln,5,4)),
          c2x(substr(ln,9,4)) c2x(substr(ln,13,4)),
          "*"translate(ln,,xrange('00'x,'40'x))"*"
      if prev=out then
         sk=sk+1
       else
         do
         if sk>0 then call say '...'
         sk=0
         prev=out
         call say right(ofs,6)'('d2x(ofs,4)')' out
         end
   end
   return

