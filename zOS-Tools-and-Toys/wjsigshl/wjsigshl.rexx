/* REXX */
/**********************************************************************/
/* WJSIGSHL:  show shared library information                         */
/*                                                                    */
/*    This will show information on currently loaded shared libs.     */
/*    This tool will run under IPCS or on a live system.              */
/*    You must be a superuser to run on a live system or be           */
/*    permitted to SUPERUSER.FILESYS.PFSCTL in the UNIXPRIV class.    */
/*                                                                    */
/*   Syntax:                                                          */
/*    wjsigshl [-p]                                                   */
/*                                                                    */
/* PROPERTY OF IBM                                                    */
/* COPYRIGHT IBM CORP. 2008,2015                                      */
/*                                                                    */
/* Bill Schoen    wjs@us.ibm.com   4/17/08                            */
/*  Change activity:                                                  */
/*     5/2/08  enabled to also run in the shell                       */
/*    8/17/15  option -p to find full pathnames on live system        */
/*                                                                    */
/**********************************************************************/
/* REXX */
/* Prolog for WJSID diagnostic skeletons */
if 0 then
   do
   novalue:
     say 'uninitialized variable in line' sigl
     say sourceline(sigl)
   halt:
     exit 0
  end
signal on novalue
signal on halt
call syscalls 'ON'
parse arg parm
if parm='STACK' then
   do
   do i=1 to sourceline()
      queue sourceline(i)
   end
   return
   end
numeric digits 12
call setglobals
 
parm=''
/* REXX */
/**********************************************************************/
/* WJSIGSHL:  show shared library information                         */
/*                                                                    */
/*    This will show information on currently loaded shared libs.     */
/*    This tool will run under IPCS or on a live system.              */
/*    You must be a superuser to run on a live system or be           */
/*    permitted to SUPERUSER.FILESYS.PFSCTL in the UNIXPRIV class.    */
/*                                                                    */
/*   Syntax:                                                          */
/*    wjsigshl [-p]                                                   */
/*                                                                    */
/* PROPERTY OF IBM                                                    */
/* COPYRIGHT IBM CORP. 2008,2015                                      */
/*                                                                    */
/* Bill Schoen    wjs@us.ibm.com   4/17/08                            */
/*  Change activity:                                                  */
/*     5/2/08  enabled to also run in the shell                       */
/*    8/17/15  option -p to find full pathnames on live system        */
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
 
arg prm
findpaths= ipcs=0 & pos('-P',prm)>0
 
call say right('Usage',5) right('Meg',4),
         'Used-Unused-Pgs' 'Pathname'
shlb=getstor(xadd(ocve,'d8'),4,kasid)
shlba=getstor(xadd(shlb,'1c'),4,kasid,kds)
totalstor=0
totalmod=0
totalunused=0
totalcount=0
do i=0 to 255
   shlm=getstor(xadd(shlba,d2x(i*4)),4,kasid,kds)
   call runshlm
end
call say right('Total Storage (Meg)  ',22) right(totalstor,12)
call say right('Total Module (Pages) ',22) right(totalmod,12)
call say right('Total Unused (Pages) ',22) right(totalunused,12)
call say right('Total Module Count   ',22) right(totalcount,12)
return
 
runshlm:
   do while shlm<>0
      shlmusecnt=x2d(getstor(xadd(shlm,'14'),4,kasid,kds))
      shlmpath=x2c(getstor(xadd(shlm,'24'),64,kasid,kds))
      shlmino=x2d(getstor(xadd(shlm,'1c'),4,kasid,kds))
      shlmdev=x2d(getstor(xadd(shlm,'20'),4,kasid,kds))
      shlmmtime=getstor(xadd(shlm,'18'),4,kasid,kds)
      shlmmodlen=x2d(getstor(xadd(shlm,'6c'),4,kasid,kds))
      shlmstorlen=x2d(getstor(xadd(shlm,'70'),4,kasid,kds))
      sizem=shlmstorlen/1048576
      modpages=(shlmmodlen+4095)%4096
      modunused=(256-modpages//256)//256
      totalmod=totalmod+modpages
      totalunused=totalunused+modunused
      totalstor=totalstor+sizem
      totalcount=totalcount+1
      if findpaths then
         do
         out.=''
         mnt.=''
         address syscall 'getmntent mnt.' shlmdev
         if mnt.7.1<>'' then
            do
            call bpxwunix 'find' mnt.7.1 '-xdev -inum' shlmino,,'out.','err.'
            if out.1<>'' then
               shlmpath=out.1
            end
         end
      call say right(shlmusecnt,5) right(sizem,4),
               right(modpages,7) right(modunused,7),
               shlmmtime strip(shlmpath,'T')
      shlm=getstor(xadd(shlm,'0c'),4,kasid,kds)
   end
   return
 
/* REXX */
/**********************************************************************/
/*       general utilities                                            */
/*                                                                    */
/* setglobals                                                         */
/*    alet. cvt, ecvt, ocvt, kasid, fds, asvt, ascb, assb, stok, ocve */
/*    symx, ipcs                                                      */
/* getsysnames                                                        */
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
setglobals:
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
   parse source . . . . . . . rxenv .
   alet.=''
   cvtecvt=140
   ecvtocvt=240
   ocvtocve=8
   z4='00000000'x
   z1='00'x
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
   return
 
/**********************************************************************/
getsysnames:
   sysnames.=''
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
getstor: procedure expose ipcs pfs  alet. kasid
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
getstor64: procedure expose ipcs pfs  alet. kasid
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
   procedure expose ipcs
   parse arg dumpbuf
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
         call say right(ofs,6)'('d2x(ofs,4)')' out
         end
   end
   return
 
