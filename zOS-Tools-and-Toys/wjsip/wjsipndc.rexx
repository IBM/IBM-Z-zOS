/* REXX */
/**********************************************************************/
/* WJSIPNDC:  show zfs file systems without the name cache enabled    */
/*                                                                    */
/*   Syntax:                                                          */
/*    wjsipndc                                                        */
/*                                                                    */
/*   Install:                                                         */
/*     Copy this text file to a place where you can run a REXX program*/
/*     This is enabled to run under TSO, the shell, or using sysrexx  */
/*     (with apar OA26802 on R9 and R10)                              */
/*                                                                    */
/*   Notes:                                                           */
/*     The LFS name directory cache is a very small name cache per    */
/*     directory.  A sysplex aware PFS would typically disable this   */
/*     in order to maintain name space integrity.                     */
/*                                                                    */
/*     Send questions or comments to Bill Schoen at wjs@us.ibm.com    */
/*                                                                    */
/* PROPERTY OF IBM                                                    */
/* COPYRIGHT IBM CORP. 2009                                           */
/*                                                                    */
/* Bill Schoen    wjs@us.ibm.com  06/26/09                            */
/*  Change activity:                                                  */
/*   8/20/09   only zfs clients, special treatment for sysplex root   */
/*   8/25/09   omit all zfs sysplex aware file systems                */
/*   8/27/09   reword messages                                        */
/*                                                                    */
/**********************************************************************/
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
parse arg stack
if stack='STACK' then
   do
   do i=1 to sourceline()
      queue sourceline(i)
   end
   return
   end
 
counts=0
gfs@=getstor('1008',4,kasid,fds)   
rootrw=0
rootlla=1
rootcl=0
nolla=0
do while gfs@<>0
   ln=gfs@
   gfsname=strip(x2c(getstor(xadd(gfs@,'18'),8,kasid,fds)))
   vfs@=getstor(xadd(gfs@,'0c'),4,kasid,fds)
   gfs@=getstor(xadd(gfs@,'08'),4,kasid,fds)
   if gfsname<>'ZFS' then iterate
 
   do while vfs@<>0
      vfsname=strip(x2c(getstor(xadd(vfs@,'38'),44,kasid,fds)))
      path=x2c(getstor(xadd(vfs@,'a0'),64,kasid,fds))   
      owner=x2c(getstor(xadd(vfs@,'240'),8,kasid,fds))  
      vnod@=getstor(xadd(vfs@,'2c'),4,kasid,fds)
      flags=x2c(getstor(xadd(vfs@,'34'),4,kasid,fds))
      call setflags
      if vfsavail=0 & vfsdead=0 & vfsperm=0 then
         do
         flags=x2c(getstor(xadd(vfs@,'1f0'),1,kasid,fds))
         lla=bitand(flags,'08'x)<>'08'x
         if path='/' then  
            do
            rootrw=rw
            rootlla=lla
            rootcl=client
            end
         if client & lla=0 & sysplexaware=0 then
            do
            if nolla=0 then
               do
               say 'zFS file systems with',                      
                   'a z/OS directory cache exception'
               end
            nolla=nolla+1
            call say vfsname               
            end
         end
      vfs@=getstor(xadd(vfs@,'08'),4,kasid,fds)
   end
end
if nolla=0 then
   do
   say 'No exceptions found'                                         
   end
 else
   do
   say
   say 'If a zFS file system was once read-write and sysplex aware but'
   say 'is no longer sysplex aware due to moving ownership to a zFS'   
   say 'sysplex=off system or migrating back to sysplex=off from'      
   say 'sysplex=on, the z/OS UNIX System Services directory cache'     
   say 'will be disabled for that file system.  It is possible'        
   say 'performance of that file system can be improved by unmounting'
   say 'that file system and mounting it back.'
   end
say
if rootrw & rootlla=0 & client then
   do
   say 'The sysplex root is mounted in read-write mode and has'     
   say 'its directory cache disabled.  This can significantly'    
   say 'impact performance.  Remount the root as read-only or replace'
   say 'the root file system using the NEWROOT support.'
   end
/*
else
if rootrw then
   do
   say 'The sysplex root is mounted in read-write mode.'
   say 'It is possible that performance can be improved if it is'
   say 'remounted to read-only mode.'
   end
*/
 
return
 
setflags:
   ro=bitand('80000000'x,flags)=='80000000'x
   rw=bitand('40000000'x,flags)=='40000000'x
   unmnt=bitand('10000000'x,flags)=='10000000'x
   vfsavail=bitand('00800000'x,flags)=='00800000'x
   vfsdead=bitand('00400000'x,flags)=='00400000'x
   quiesced=bitand('00040000'x,flags)=='00040000'x
   vfsperm=bitand('00004000'x,flags)=='00004000'x 
   client=bitand('00000002'x,flags)=='00000002'x
   agst=zfsgetagstat(vfsname)
   flag=substr(agst,20,1)                               
   sysplexaware=bitand(flag,'40'x)<>z1                   
   return      
 
/**********************************************************************/
/* build an AGID structure from the aggr name */
makeagid: procedure          
   arg fsname
   return 'AGID' || '5401'x || left(fsname,45,'00'x) || copies('00'x,33)
 
/* get aggr info           */
zfsgetagstat:
procedure expose opts pl st.                    
   arg fsname
   z1='00'x
   z4='00000000'x
   pl=32
   agid=makeagid(fsname)
   agidsz=length(agid)  
   agstsz=172
   agst='AGST' || '00000200'x || copies(z1,agstsz-8)
   agst=overlay(d2c(length(agst),2),agst,5)
   pctbf=d2c(146,4) ||,                     /* stats op      */
         d2c(pl,4)  ||,                     /* p0: ofs agrid */
         d2c(pl+agidsz,4) ||,               /* p1: ofs buff  */
         z4         ||,                     /* p2:           */
         z4||z4||z4||z4||,                  /* p3-p6     */
         agid || agst  
   pctcmd=x2d('40000005')   
   address syscall 'pfsctl ZFS' pctcmd 'pctbf' length(pctbf)
   if rc<0 | retval=-1 then return ''
   if pctbf='' then return ''
   if substr(pctbf,pl+agidsz+1,4)<>'AGST' then return ''
   agst=substr(pctbf,agidsz+pl+1)  
   return agst
 
/**********************************************************************/
/* pfsctl:  issue the pfsctl command and handle errors                */
/*          command is in variable PCTBF                              */
/*          arg(1) is 1 for aggr op, 2 for filesys op                 */
/*          arg(2) is optional errno that is not treated as an error  */
/**********************************************************************/
 
zfspfsctl:
   pctcmd=x2d('40000005')   
   address syscall 'pfsctl ZFS' pctcmd 'pctbf' length(pctbf)
   if rc>=0 & retval<>-1 then return
   if errno=arg(2) then return
   if errno=enodev | errno=enoent | errno=ebusy then
      do
      return
      end
   pcter=errno      
   pctrs=errnojr      
   err.=''      
   address syscall 'strerror' pcter pctrs 'err.'      
   errno=pcter      
   errnojr=pctrs      
   eno=errno'x'      
   if err.1<>'' then      
      eno=eno strip(err.1)'.'      
   rsn='  Reason='errnojr'x'      
   if err.4<>'' & err.2<>'' then      
      rsn=rsn strip(err.2)      
   say eno                     
   say rsn      
   rc=0      
   retval=-1      
      call dump pctbf      
   trace ?i;nop      
   return
 
 
/* REXX */
/**********************************************************************/
/*       general utilities                                            */
/*                                                                    */
/* setglobals                                                         */
/*    alet. cvt, ecvt, ocvt, kasid, fds, asvt, ascb, assb, stok, ocve */
/* getsysnames                                                        */
/* getstor                                                            */
/* extr                                                               */
/* say                                                                */
/* gettod                                                             */
/* toddiff                                                            */
/* e2tod                                                              */
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
      ipcs=0
    else
      ipcs=1
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
   return 0
 
/**********************************************************************/
extr:
   return substr(arg(1),x2d(arg(2))*2+1,arg(3)*2)
 
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
   pl=translate(arg(1),,"'"xrange('00'x,'3f'x))
   if ipcs then
      address ipcs "NOTE '"pl"' ASIS"
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
 
