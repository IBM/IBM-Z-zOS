/* REXX */
/**********************************************************************/
/* WJSISSHM: show shared memory information                           */
/*                                                                    */
/*    This will show information on shared memory segments.           */
/*    This tool will run under IPCS or on a live system.              */
/*    You must be a superuser to run on a live system or be           */
/*    permitted to SUPERUSER.FILESYS.PFSCTL in the UNIXPRIV class.    */
/*                                                                    */
/*   Syntax:                                                          */
/*    wjsigshm [-v]                                                   */
/*   Options: -v   include address information                        */
/*                                                                    */
/* PROPERTY OF IBM                                                    */
/* COPYRIGHT IBM CORP. 2011                                           */
/*                                                                    */
/* Bill Schoen    wjs@us.ibm.com  11/04/11                            */
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
/* WJSISSHM: show shared memory information                           */
/*                                                                    */
/*    This will show information on shared memory segments.           */
/*    This tool will run under IPCS or on a live system.              */
/*    You must be a superuser to run on a live system or be           */
/*    permitted to SUPERUSER.FILESYS.PFSCTL in the UNIXPRIV class.    */
/*                                                                    */
/*   Syntax:                                                          */
/*    wjsigshm [-v]                                                   */
/*   Options: -v   include address information                        */
/*                                                                    */
/* PROPERTY OF IBM                                                    */
/* COPYRIGHT IBM CORP. 2011                                           */
/*                                                                    */
/* Bill Schoen    wjs@us.ibm.com  11/04/11                            */
/**********************************************************************/
parse arg stack
if stack='STACK' then
   do
   do i=1 to sourceline()
      queue sourceline(i)
   end
   return
   end

arg opts
verbose=pos('-V',opts)>0
z1='00'x
call syscalls 'ON'
ppra=getstor(xadd(ocve,'08'),4)
ipcm=getstor(xadd(ocve,'24'),4)
ipcmshmspage=x2d(getstor(xadd(ipcm,'e0'),4))
ipcmshmbig64=getstor(xadd(ipcm,'e8'),8)
ipcmshmexcsp=x2d(getstor(xadd(ipcm,'f0'),4))
ipcmshmidc=x2d(getstor(xadd(ipcm,'100'),4))
ipcma=xadd(ipcm,'108')
ipcmlen=getstor(xadd(ipcm,'5'),3)
ipcmend=xadd(ipcm,ipcmlen)
if verbose then
   call say 'IPCM@                 ' ipcm
/* call say 'Number of pages:      ' ipcmshmspage    seems to be 0 */
call say 'Max segment allocated:' dw(ipcmshmbig64)
call say 'Max exceeded:         ' ipcmshmexcsp
call say 'ID count:             ' ipcmshmidc
call say
if verbose then
   hdr=left('IPCMA@',8) left('ISHM@',8) left('Seg Address',17)' '
 else
   hdr=''
hdr=hdr || left('Size',17) left('Owner',8) left('Key',8),
           right('Id',8) 'Flags'
call say hdr
/* ipcma='1D151050' */
owner.=0
owners=''
pid.=''
user.=''
do until getipcma()
   ipcc=getstor(xadd(ipcma,'c'),4)
   ipcf=x2c(substr(ipcc,1,2))
   if bitand(ipcf,'80'x)='80'x then iterate
   if x2c(getstor(ipcc,4))<>'ISHM' then iterate
   shma=getstor(xadd(ipcc,'110'),4)
   uid=getstor(xadd(ipcc,'b0'),4)
   segsz=getstor(xadd(ipcc,'c4'),4)
   if segsz=0 then
      segsz=getstor(xadd(ipcc,'f0'),8)
   if owner.uid.1=0 then
      owners=owners uid
   owner.uid.1=owner.uid.1+1
   owner.uid.2=owner.uid.2+x2d(segsz)
   key=getstor(xadd(ipcc,'80'),4)
   id=x2d(getstor(xadd(ipcc,'84'),4))
   segadr=getstor(xadd(ipcc,'114'),4)
   if segadr=0 then
      segadr=getstor(xadd(ipcc,'e8'),8)
   if substr(segsz,1,8)=0 then
      segsz=substr(segsz,9)
   flags=getstor(xadd(ipcc,'124'),1)
   flag=x2c(flags)
   if bitand(flag,'40'x)<>z1 then
      flags=flags 'Rm'
   if bitand(flag,'20'x)<>z1 then
      flags=flags 'Mega'
   if bitand(flag,'10'x)<>z1 then
      flags=flags 'MegaRO'
   if bitand(flag,'08'x)<>z1 then
      flags=flags 'Giga'
   if bitand(flag,'04'x)<>z1 then
      flags=flags '64RO'
   if bitand(flag,'02'x)<>z1 then
      flags=flags 'ShrAS'
   if bitand(flag,'01'x)<>z1 then
      flags=flags 'Auth'
   if verbose then
      ln=ipcma ipcc dw(segadr)' '
    else
      ln=''
   call say ln || dw(segsz) uid key right(id,8) flags
   do while shma<>0
      pid=getstor(xadd(shma,'20'),4)
      if pid.pid='' then
       if ipcs then
         do
         pprp=getpprp(pid)
         ousp=getstor(xadd(pprp,'20'),4)
         uid=''
         if ousp<>0 then
            do
            idinfo=getstor(xadd(ousp,'04'),18)
            uid=substr(idinfo,1,8)
            user=strip(translate(substr(x2c(idinfo),11,8),' ','00'x))
            pid.pid=user'('uid')'
            user.uid=user
            end
         end
      flag=x2c(getstor(xadd(shma,'05'),1))
      flags=''
      if bitand(flag,'80'x)='80'x then
         flags='RO'
      call say '   pid='pid pid.pid flags
      shma=getstor(xadd(shma,'8'),4)
   end
end
call say
call say left('Owner',18) right('Count',8) 'Total'
do while owners<>''
   parse var owners uid owners
   if ipcs=0 then
      do
      pw.=''
      address syscall 'getpwuid' x2d(uid) 'pw.'
      if pw.pw_name<>'' then
         user.uid=strip(pw.pw_name)'('uid')'
      end
   if user.uid='' then
      user.uid=uid
   call say left(user.uid,18) right(owner.uid.1,8),
            right(d2x(owner.uid.2),8,0)
end

return

getipcma:
   ipcma=xadd(ipcma,'10')
   return ipcma=ipcmend

dw: procedure
   return substr(arg(1),1,8) substr(arg(1),9,8)

getpprp:
   parse arg pid
   pidx=x2d(substr(pid,5))-1
   pidx=d2x(pidx*8)
   ppraa=xadd(ppra,'30')
   ppraslot=xadd(ppraa,pidx)
   return getstor(xadd(ppraslot,'04'),4)
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
   address tso 'subcom IPCS'
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

