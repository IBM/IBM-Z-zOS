/* REXX */
/**********************************************************************/
/* FSQ  file system query                                             */
/*                                                                    */
/*  Property of IBM                                                   */
/*  Copyright IBM Corp. 2007, 2012                                    */
/*                                                                    */
/* Syntax:  fsq [-v | -t template] [-f] pattern | path                */
/*  options:                                                          */
/*      -v   verbose:   show long form of output                      */
/*      -t   template is the name of an output format                 */
/*      -f   pattern is a file system name.  note: if that file       */
/*           system is quiesced, fsq may suspend until unquiesced     */
/*  argument:                                                         */
/*      path     show information for file system containing path     */
/*               pathname must start with . or /                      */
/*      pattern  this is a case insensitive string used to match file */
/*               system names.  Use * as a wildcard.  If no * is used */
/*               the pattern form will be *pattern*                   */
/*               If the -f option is used pattern is treated as a     */
/*               file system name, not a pattern.  File system names  */
/*               are mixed case.  This will search for a file system  */
/*               using the name as entered and if not found, the name */
/*               upper-cased.                                         */
/*      template this is the name of an output template:              */
/*               short    default without -v                          */
/*               verbose  equivalent to -v                            */
/*               quiesced show names of quiesced file systems         */
/*  Return values:                                                    */
/*      0   at least one file system was found                        */
/*      1   no file systems were found                                */
/*     >4   error                                                     */
/*                                                                    */
/* Install:                                                           */
/*  Place this where a rexx exec can be run in the environment you    */
/*  want to run it.  This can run under TSO, ISPF, shell, and sysrexx.*/
/*  If run under the shell, you must have read+execute permission     */
/*  If run under sysrexx, you must log onto the console               */
/*                                                                    */
/* Change activity:                                                   */
/*     2/15/11   zfs owner, view in ispf, show all, sysrexx           */
/*     2/21/11   added -f, compress line prefix, -pfs in template,    */
/*               filetag, changed * to ~ in template, rmv synconly,   */
/*               added norm/excep status lines                        */
/*     8/05/11   added -t quiesced, &var=val in template, rtn codes   */
/*     2/22/12   added path, added fragment space                     */
/*                                                                    */
/* Bill Schoen  <wsj@us.ibm.com> 10/24/2007                           */
/**********************************************************************/
if 0 then
   do
   syntax:
     say 'internal error on line' sigl
     say sourceline(sigl)
     exit 16
   novalue:
     say 'uninitialized variable in line' sigl
     say sourceline(sigl)
     trace ?i
     nop
     exit 12
   halt:
     exit 20
   end
signal on novalue
numeric digits 12
parse source . . me . . . tso where .
if where<>'OMVS' then
   do
   /* if not running under the shell parse out arg and build __argv. */
   __argv.1=me
   parse arg args
   do i=2 by 1 while args<>''
      parse var args __argv.i args
   end
   __argv.0=i-1
   __environment.0=0
   end

sx=0
parse value 'v   V   t   f   ' with,
             lcv ucv lct lcf .
argx=getopts('vVf','t')
if __argv.0<argx then
   do
   say 'Syntax: fsq [-v] [-f] pattern'
   return 20
   end
fsn=__argv.argx
if opt.ucv<>'' then
   opt.lcv=opt.ucv
if opt.lcv='' & opt.lct='' then tplname='short'
if opt.lcv<>'' then tplname='verbose'
if opt.lct<>'' then tplname=opt.lct
if syscalls('ON')>4 then
   do
   say 'Cannot initialize as a unix process'
   if where='AXR' then
      say 'Logon to the console with userid that can access z/OS UNIX'
   return 20
   end
pl=32
z1='00'x
z4='00000000'x
count=0
if fsn='' then
   fsn='*'
if substr(fsn,1,1)<>'.' & substr(fsn,1,1)<>'/' then
 if pos('*',fsn)=0 & opt.lcf='' then
   fsn='*'fsn'*'
pattern= pos('*',fsn)<>0

call loadtemplate tplname
mt.=''
call zfsgetaggr
tfsn=translate(fsn)
if substr(fsn,1,1)='.' | substr(fsn,1,1)='/' then
   do
   address syscall 'statvfs (fsn) stfs.'
   if retval=-1 then
      do
      say fsn 'not found'
      return 1
      end
   address syscall 'getmntent mt.' stfs.stfs_fsid
   tfsn=strip(translate(mt.mnte_fsname.1))
   pattern=0
   end
else
if opt.lcf='' then
   address syscall 'getmntent mt.'
 else
   do
   address syscall 'statfs (fsn) stfs.'
   if retval=-1 then
      address syscall 'statfs (tfsn) stfs.'
   if retval=-1 then
      do
      say fsn 'not found'
      return 1
      end
   address syscall 'getmntent mt.' stfs.stfs_fsid
   pattern=0
   end

do fx=1 to mt.0
   ucfsn=strip(translate(mt.mnte_fsname.fx))
   if pattern=0 & tfsn=ucfsn then
      call processfs
   else
   if patmatch(tfsn,ucfsn) then
      call processfs
end
if count=0 then
   call say 'no file systems found matching' fsn
if where='ISPF' then
   do
   say.0=sx
   call brstem 'say.'
   end
if count=0 then return 1
return 0

brstem:
   arg stem
   parse source . . . . . . . isp .
   address ispexec
   brc=value(arg(1)"0")
   if brc=0 then
      return
   brlen=250
   do bri=1 to brc
      if brlen<length(value(arg(1) || bri)) then
         brlen=length(value(arg(1) || bri))
   end
   brlen=brlen+4
   call bpxwdyn "alloc rtddn(bpxpout) reuse new",
                "recfm(v,b) lrecl("brlen") msg(wtp)"
   address tso "execio" brc "diskw" bpxpout "(fini stem" arg(1)
   'LMINIT DATAID(DID) DDNAME('BPXPOUT')'
   'VIEW   DATAID('did') PROFILE(WJSC) MACRO(RESET)'
   'LMFREE DATAID('did')'
   call bpxwdyn 'free dd('bpxpout')'
   return

patmatch: procedure
   arg pat,str
   ofs=1
   opat=pat
   do forever
      parse var pat pre '*' suf
      if pre<>'' then
         do
         i=pos(pre,substr(str,ofs))
         if i=0 then return 0
         ofs=ofs+i+length(pre)-1
         end
      if suf='' then
         do
         if substr(opat,length(opat))='*' then
            return 1
         if length(str)<ofs then
               return 1
         return 0
         end
      pat=suf
   end
   return 0  /* should not get here */


processfs:
   count=count+1
   st.=''
   call getlfsinfo
   if st.mnte_fstype='ZFS' then
      do
      call zfsgetfsstat ucfsn
      call zfsgetagstat ucfsn
      call value 'st.$zfsowner',agid.ucfsn
      j=value('st.$blocks')*value('st.$fragsize')/1048576
      call value 'st.$totalmeg',    format(j,,3)
      totalmeg=value('st.$totalmeg')
      j=value('st.$realfree')
      call value 'st.$freemeg',     format(j/1024,,3)
      freemeg=value('st.$freemeg')
      usedmeg=totalmeg-freemeg
      call value 'st.$usedmeg',     usedmeg
      call value 'st.$fragmeg',,
                  format(st.$freefrags*(st.$fragsize/1024)/1024,,3)
      call value 'st.$utilization', format(usedmeg*100/totalmeg,,1)
      sysk=value('st.$inodetbl')+value('st.$directlog')+,
           value('st.$fstbl')+value('st.$indirectlog')+,
           value('st.$bitmap')
      call value 'st.$sysmeg', format(sysk/1024,,3)
      if value(st.$disabled)=1 then
         call value 'st.$status','zFS Disabled'
      else
      if value(st.$quiesced)=1 then
         call value 'st.$status','zFS Quiesced'
      end
   else
   if st.mnte_fstype='HFS' then
      do
      call queryhfs ucfsn
      call value 'st.$sysmeg',format(value('st.$systemspacek')/1024,,3)
      call value 'st.$requests',value('st.$seqio')+,
                             value('st.$randomio')+value('st.$lookups')
      totalmeg=value('st.$totalspacek')/1024
      call value 'st.$totalmeg',      format(totalmeg,,3)
      call value 'st.$fragmeg', 'n/a'
      usedmeg=value('st.$usedspacek')/1024+value('st.$sysmeg')
      if usedmeg>totalmeg then
         usedmeg=totalmeg
      call value 'st.$usedmeg',       format(usedmeg,,3)
      freemeg=max(0,totalmeg-usedmeg)
      call value 'st.$freemeg',       format(freemeg,,3)
      if totalmeg<>0 then
         call value 'st.$utilization',,
                   min(100.0,format(usedmeg*100/totalmeg,,1))
      if value('st.$hfssyncerror')=1 then
         call value 'st.$status','HFS Sync error'
      else
      if value('st.$writeprotecterror')=1 then
         call value 'st.$status','HFS Write protect error'
      else
      if value('st.$syncnospace')=1 then
         call value 'st.$status','HFS Sync no space error'
      end
   else
      do
      /* no other info supported for other filesys types */
      end
   call printinfo
   return

getlfsinfo:
   do i=1 to 40    /* set at least to max vars returned by getmntent */
      st.i=mt.i.fx
   end
   cmode=d2c(st.mnte_mode,4)
   if bitand(cmode,'00000002'x)=z4 then setid=''; else setid='No setid'
   if bitand(cmode,'00000004'x)=z4 then exp=''; else exp='Exported'
   if bitand(cmode,'00000008'x)=z4 then
      nosec=''; else nosec='No security'
   if bitand(cmode,'00000010'x)=z4 then
      am='Automove'; else am='No automove'
   if bitand(cmode,'00000040'x)<>z4 then am='Automove(unmount)'
   if bitand(cmode,'00000020'x)=z4 then cln=''; else cln='Client'
   if bitand(cmode,'00000080'x)=z4 then acl=''; else acl='ACLs'
   if bitand(cmode,'00000100'x)=z4 then syn=''; else syn='SyncOnly'
   if st.mnte_syslist<>'' then
      do
      /* syslist: 2 byte count, 2 byte type, 8 byte names */
      if bitand('0001'x,substr(st.mnte_syslist,3,2))='0000'x then
         am='Include'
       else
         am='Exclude'
      end
   if bitand(cmode,'00000001'x)=z4 then ro='R/W'; else ro='R/O'
   call value 'st.$automove',am
   call value 'st.$mountmode',ro
   call value 'st.$nosetid',setid
   call value 'st.$exported',exp
   call value 'st.$nosecurity',nosec
   call value 'st.$client',cln
   call value 'st.$acls',acl
   call value 'st.$sync',syn
   j=st.mnte_status
   select
      when j=0 then status= 'Available'
      when j=1 then status= 'Not Active'
      when j=2 then status= 'Reset in progress'
      when j=4 then status= 'Unmount drain in progress'
      when j=8 then status= 'Unmount force in progress'
      when j=16 then status='Unmount immediate in progress'
      when j=32 then status='Unmount in progress'
      when j=64 then status='Pending unmount reset or force'
      when j=128 then
         do
         status='Quiesced by',
                strip(st.mnte_qjobname)'('st.mnte_qpid')'
         call value 'st.$quiesced',1
         end
      when j=130 then status='Mount in progress'
      otherwise
         status='Status='j
   end
   call value 'st.$status',status
   call value 'st.$ccsid',c2d(substr(st.mnte_filetag,1,2))
   if bitand(substr(st.mnte_filetag,3,2),'80'x)='80'x then
      call value 'st.$text','ON'
    else
      call value 'st.$text','OFF'
   return

/**********************************************************************/
printinfo:
   do i=1 to tps.0
      key=tps.i
      ukey=translate(key)
      if tps.key.1='=' then
         if translate(st.ukey)=translate(tps.key.2) then
            nop
          else
            return
      else
      if tps.key.1='<' then
         if translate(st.ukey)<translate(tps.key.2) then
            nop
          else
            return
      else
      if tps.key.1='>' then
         if translate(st.ukey)>translate(tps.key.2) then
            nop
          else
            return
      else
         return
   end
   pfs=''
   compress=0
   do i=1 to tpl.0
      ln=tpl.i
      parse upper var ln '<' pfstp '>'
      if length(pfstp)>0 then
         do
         pfs=pfstp
         if substr(pfstp,1,1)='/' then
            pfs=''
         iterate
         end
      if substr(pfs,1,1)='-' then
         do
         if substr(pfs,2)=st.mnte_fstype then
            iterate
         end
      else
      if substr(pfs,1,1)='&' then
         do
         parse var pfs '&' varname '=' varval
         if value('st.$'varname)<>varval then
            iterate
         end
      else
      if pfs<>'' & pfs<>st.mnte_fstype then
         iterate
      outln=''
      do forever
         parse var ln pre '&' var '.' ln
         if var='' then leave
         width=length(var)+2
         var=strip(var)
         if substr(var,1,5)='mnte_' then
            var=value(var)
          else
            var='$'translate(var)
         outln=outln || pre || left(st.var,width)
      end
      ln=outln || pre

      outln=''
      do forever
         if substr(ln,1,1)='-' then
            do
            compress=1
            ln=substr(ln,2)
            end
           else
            compress=0
         parse var ln pre '~' var '.' ln
         if var='' then leave
         width=length(var)+2
         var=strip(var)
         prompt=tpp.var
         var=tpv.var
         if substr(var,1,5)='mnte_' then
            var=value(var)
          else
            var='$'translate(var)
         var=st.var
         if var<>'' & prompt<>'' then
            var=prompt var
         outln=outln || pre || left(var,width)
      end
      ln=outln || pre

      outln=''
      do forever
         parse var ln pre '@' var '.' ln
         if var='' then leave
         width=length(var)+2
         var=strip(var)
         if substr(var,1,5)='mnte_' then
            var=value(var)
          else
            var='$'translate(var)
         outln=outln || pre || right(st.var,width)
      end
      ln=outln || pre

      outln=''
      do forever
         parse var ln pre '!' var '.' ln
         if var='' then leave
         width=length(var)+2
         var=strip(var)
         var=tpv.var
         if substr(var,1,5)='mnte_' then
            var=value(var)
          else
            var='$'translate(var)
         outln=outln || pre || right(st.var,width)
      end
      ln=outln || pre
      if compress then
         ln=space(ln)
      if ln<>'' then
         if ln='.' then
            call say
          else
            call say ln
   end
   return

/**********************************************************************/
say:
   sx=sx+1
   if where='ISPF' then
      say.sx=arg(1)
    else
      say strip(arg(1),'t')
   return

/**********************************************************************/
zfsgetaggr:
procedure expose opts z1 z4 pl agid. e2big

/* query buffer size */
pctbf=d2c(140,4) ||,                     /* list op       */
      z4                     ||,         /* p0: bufsz     */
      z4          ||,                    /* p1: buf offs  */
      d2c(pl,4)                ||,       /* p2: sz offs   */
      z4||z4||z4||z4||,                  /* p3-p6     */
      z4                                 /* returned size */
call zfspfsctl 1,e2big
aglistsz=c2d(substr(pctbf,pl+1,4))
if aglistsz=0 then
   do
   aglistsz=3800    /* for old rx support */
   end

/* get aggr list */
aglist=copies(z1,aglistsz)
pctbf=d2c(140,4) ||,                     /* list op       */
      d2c(aglistsz,4)  ||,               /* p0: bufsz     */
      d2c(pl,4)   ||,                    /* p1: buf offs  */
      d2c(pl+aglistsz,4) ||,             /* p2: sz offs   */
      z4||z4||z4||z4||,                  /* p3-p6     */
      aglist || z4
call zfspfsctl 1
j=0
agid.=''
do i=pl+1 by 0
   if substr(pctbf,i,4)<>'AGID' then leave
   agidsz=c2d(substr(pctbf,i+4,1))
   agnm=substr(pctbf,i+4+1+1,45)
   parse var agnm agnm '00'x
   agsys=substr(pctbf,i+4+1+1+45,9)
   parse var agsys agsys '00'x
   agid.agnm=agsys
   i=i+agidsz
end
return

/**********************************************************************/
/**********************************************************************/
/* build an AGID structure from the aggr name */
makeagid: procedure expose z1
   arg fsname
   return 'AGID' || '5401'x || left(fsname,45,z1) || copies(z1,33)

/**********************************************************************/
zfsgetfsstat:
   procedure expose opts z1 z4 pl st. e2big enodev enoent,
                 tm_hour tm_min tm_sec tm_mon tm_mday tm_year
   arg fsname
   agfs=getfsid(fsname)
   if agfs='' then return 1
   fsst='FSST' || '00000100'x || copies(z1,388)
   fsst=overlay(d2c(length(fsst),2),fsst,5)
   pctbf=d2c(142,4) ||,                     /* fs stat       */
         d2c(pl,4)  ||,                     /* p0:           */
         d2c(pl+length(agfs),4) ||,         /* p1:           */
         z4         ||,                     /* p2:           */
         z4||z4||z4||z4||,                  /* p3-p6     */
         agfs || fsst
   call zfspfsctl 2
   if pctbf='' then return ''
   fsst=substr(pctbf,pl+length(agfs)+1)
   call value 'st.$clonetime',      epoc(c2d(substr(fsst,17,4)))
   call value 'st.$createtime',     epoc(c2d(substr(fsst,25,4)))
   call value 'st.$updatetime',     epoc(c2d(substr(fsst,33,4)))
   call value 'st.$accesstime',     epoc(c2d(substr(fsst,41,4)))
   call value 'st.$alloclimit',     c2d(substr(fsst,49,4))
   call value 'st.$allocusage',     c2d(substr(fsst,53,4))
   call value 'st.$visquotalimit',  c2d(substr(fsst,57,4))
   call value 'st.$visquotausage',  c2d(substr(fsst,61,4))
   call value 'st.$accerror',       c2d(substr(fsst,65,4))
   call value 'st.$accstatus',      c2d(substr(fsst,69,4))
   flag=bitand(substr(fsst,73,4),'00030000'x)
   call value 'st.$fstyperw',       flag='00010000'x
   call value 'st.$fstypebk',       flag='00030000'x
   call value 'st.$nodemax',        c2d(substr(fsst,77,4))
   call value 'st.$minquota',       c2d(substr(fsst,81,4))
   call value 'st.$type',           c2d(substr(fsst,85,4))
   call value 'st.$threshold',      c2d(substr(fsst,89,1))
   call value 'st.$increment',      c2d(substr(fsst,90,1))
   call value 'st.$mountstate',     c2d(substr(fsst,91,1))
   skip=92+1+128+45+3+12
   call value 'st.$inodetbl',       c2d(substr(fsst,skip,4))
   call value 'st.$requests',       c2d(substr(fsst,skip+4,8))
   return 0

epoc:
   parse arg etime
   if etime=0 then return ''
   address syscall 'gmtime' etime 'tm.'
   return right(tm.tm_hour,2,0)':'right(tm.tm_min,2,0)':' ||,
          right(tm.tm_sec,2,0) right(tm.tm_mon,2,0)'/' ||,
          right(tm.tm_mday,2,0)'/'right(tm.tm_year,4,0)
/**********************************************************************/
/* get fs list in aggr to find the FSID for rqsted filesys  */
getfsid:
procedure expose opts z1 z4 pl e2big enodev enoent
   arg fsname
   agid=makeagid(fsname)
   agidsz=length(agid)
   pctbf=d2c(138,4) ||,                     /* list fs       */
         d2c(pl,4)  ||,                     /* p0: ofs agrid */
         d2c(0,4) ||,                       /* p1: sz buff   */
         d2c(0,4) ||,                       /* p2: ofs buff  */
         d2c(pl+agidsz,4) ||,               /* p3: ofs sz    */
         z4||z4||z4||,                      /* p4-p6     */
         agid || z4 || z4
   call zfspfsctl 1,e2big
   if pctbf='' then return ''
   sz=c2d(substr(pctbf,pl+agidsz+1,4))+1000
   agfs=copies(z1,sz)
   pctbf=d2c(138,4) ||,                     /* list fs       */
         d2c(pl,4)  ||,                     /* p0: ofs agrid */
         d2c(length(agfs),4) ||,            /* p1: sz buff   */
         d2c(pl+agidsz,4) ||,               /* p2: ofs buff  */
         d2c(pl+agidsz+length(agfs),4) ||,  /* p3: ofs sz    */
         z4||z4||z4||,                      /* p4-p6     */
         agid || agfs || z4
   call zfspfsctl 1
   if pctbf='' then return ''
   i=pl+agidsz+1
   do forever
      if substr(pctbf,i,4)<>'FSID' then leave
      inc=c2d(substr(pctbf,i+4,1))
      fsid=substr(pctbf,i,inc)
      fsidname=strip(substr(fsid,17,44),,z1)
      if fsidname=fsname then
         return fsid
      i=i+inc
   end
   return ''

/**********************************************************************/
/* get aggr info           */
zfsgetagstat:
procedure expose opts z1 z4 pl st. enodev enoent
   arg fsname
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
   call zfspfsctl 1
   if pctbf='' then return ''
   if substr(pctbf,pl+agidsz+1,4)<>'AGST' then return ''
   agst=substr(pctbf,agidsz+pl+1)
   call value   'st.$nfilesystems',c2d(substr(agst,13,4))
   call value   'st.$threshold',   c2d(substr(agst,17,1))
   call value   'st.$increment',   c2d(substr(agst,18,1))
   flag=                               substr(agst,19,1)
   call value   'st.$monitor',     bitand(flag,'80'x)<>z1
   call value   'st.$ro',          bitand(flag,'40'x)<>z1
   call value   'st.$nbs',         bitand(flag,'20'x)<>z1
   call value   'st.$compat',      bitand(flag,'10'x)<>z1
   call value   'st.$grow',        bitand(flag,'08'x)<>z1
   call value   'st.$dynamicmove', bitand(flag,'04'x)<>z1
   call value   'st.$quiesced',    bitand(flag,'01'x)<>z1
   flag=                               substr(agst,20,1)
   call value   'st.$disabled',    bitand(flag,'80'x)<>z1
   call value   'st.$blocks',      c2d(substr(agst,21,4))
   call value   'st.$fragsize',    c2d(substr(agst,25,4))
   call value   'st.$blocksize',   c2d(substr(agst,29,4))
   call value   'st.$totalusable', c2d(substr(agst,33,4))
   call value   'st.$realfree',    c2d(substr(agst,37,4))
   call value   'st.$minfree',     c2d(substr(agst,41,4))
   call value   'st.$moveinterval',c2d(substr(agst,45,4))
   call value   'st.$movepercent', c2d(substr(agst,49,4))
   call value   'st.$movemin',     c2d(substr(agst,53,4))
   call value   'st.$freeblocks',  c2d(substr(agst,57,4))
   call value   'st.$freefrags',   c2d(substr(agst,61,4))
   call value   'st.$directlog',   c2d(substr(agst,65,4))
   call value   'st.$indirectlog', c2d(substr(agst,69,4))
   call value   'st.$fstbl',       c2d(substr(agst,73,4))
   call value   'st.$bitmap',      c2d(substr(agst,77,4))
   call value   'st.$diskformatmajorversion', c2d(substr(agst,81,4))
   call value   'st.$diskformatminorversion', c2d(substr(agst,85,4))
   call value   'st.$auditfid',    substr(agst,89,10)

   return agst

/**********************************************************************/
/* get filesys info from HFS */
queryhfs: procedure expose st. stfs_inuse stfs_total stfs_avail
   arg fsn
   numeric digits 20
   pctfstat=4
   hfsqfsbfsz=228
   if fsn='' then return
   buf=left(fsn,44) || copies('00'x,hfsqfsbfsz-44)

   call hfspfsctl pctfstat,buf
   call value 'st.$totalspacek',   fmt(069,4,10)*4
   call value 'st.$usedspacek',    fmt(073,4,10)*4
   call value 'st.$systemspacek',  fmt(077,4,10)*4
   call value 'st.$cachedpages',   fmt(185,4,10)
   call value 'st.$seqio',         fmt(081,8,20)
   call value 'st.$randomio',      fmt(089,8,20)
   call value 'st.$lookups',       fmt(097,8,20)+fmt(105,8,20)
   call value 'st.$indexreads',    fmt(153,8,20)+fmt(161,8,20)
   call value 'st.$indexwrites',   fmt(169,8,20)+fmt(177,8,20)
   call value 'st.$hfsflags',      fmtx(46,1,20)
   call value 'st.$hfssyncerror',  fmtx(47,1,20)
   errflags=substr(buf,47,1)
   call value 'st.$writeprotecterror',bitand('20'x,errflags)<>'00'x
   call value 'st.$syncnospace',   bitand('10'x,errflags)<>'00'x
   call value 'st.$highformatrfn', fmtx(189,4,20)
   call value 'st.$membercount',   fmt(193,4,20)
   call value 'st.$syncinterval',  fmt(65,2,20)
   call value 'st.$apmcount',      fmt(197,4,20)                                            /*@0 CA*/
   if value('st.$quiesced')=1 then return
   address syscall 'statfs (fsn) stfs.'
   if rc=0 & retval<>-1 then
      do
      rsvd=(stfs.stfs_total-stfs.stfs_avail-stfs.stfs_inuse)*4
      rsvd=rsvd+value(st.$systemspacek)
      call value 'st.$systemspacek',  rsvd
      end
   return
fmt: /* bufoffset,datalength,fieldwidth */
   return c2d(substr(buf,arg(1),arg(2)))
fmtx: /* bufoffset,datalength,fieldwidth */
   return d2x(c2d(substr(buf,arg(1),arg(2))))
/**********************************************************************/
hfspfsctl:
   numeric digits 10                                           /*@07A*/
   parse arg cmdcd,pct
   pcterr=0
   address syscall "pfsctl HFS" cmdcd "pct"
   prc=rc
   rv=retval
   buf=pct
   if prc<0 | rv=-1 then
       do
       say 'Error issuing PFSCTL: RC='prc 'ERRNO='errno 'REASON='errnojr
        SELECT
         WHEN (errnojr) = 5B360101 THEN                        /*@07A*/
          say ' Establish recovery failed for PFSCTL service'  /*@07A*/
         WHEN (errnojr) = 5B360102 THEN                        /*@07A*/
          say ' Unsupported option'                            /*@07A*/
         WHEN (errnojr) = 5B360103 THEN                        /*@07A*/
          say ' Data area address is zero'                     /*@07A*/
         WHEN (errnojr) = 5B360104 THEN                        /*@07A*/
          say ' Data area size too small to complete request'  /*@07A*/
         WHEN (errnojr) = 5B360105 THEN                        /*@07A*/
          say ' HFS is not mounted on this system/LPAR'        /*@08C*/
         OTHERWISE                                             /*@07A*/
          say ' Unexpected error encountered'                  /*@07A*/
        END                                                    /*@07A*/
       call dump pct
        cc=1                                                   /*@04A*/
        pcterr=1                                               /*@04A*/
       end                                                     /*@04A*/
   return


/**********************************************************************/
/* pfsctl:  issue the pfsctl command and handle errors                */
/*          command is in variable PCTBF                              */
/*          arg(1) is 1 for aggr op, 2 for filesys op                 */
/*          arg(2) is optional errno that is not treated as an error  */
/**********************************************************************/

zfspfsctl:
   if arg(1)=1 then              /* aggr op */
      pctcmd=x2d('40000005')
   else
      pctcmd=x2d('40000004')     /* filesys op */
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

/**********************************************************************/
loadtemplate:
   parse arg tplname
   do i=1 to sourceline()
      parse value sourceline(i) with key val .
      if key='//template' & val=tplname then leave
   end
   j=0
   rawtpl.0=0
   if i>sourceline() then
      call externaltpl
    else
      do i=i+1 to sourceline()
         j=j+1
         rawtpl.j=sourceline(i)
         rawtpl.0=j
      end
   if rawtpl.0=0 then
      do
      say 'Report template' tplname 'not found'
      exit
      end
   j=0
   do i=1 to rawtpl.0
      j=j+1
      tpl.j=rawtpl.i
      if tpl.j='<variables>' then leave
   end
   tpl.0=j-1
   tpv.=''
   tpp.=''
   do i=i+1 to rawtpl.0
      j=j+1
      parse var rawtpl.i key var prompt
      if key='' then iterate
      if key='<select>' then leave
      tpv.key=var
      tpp.key=strip(prompt)
   end
   j=0
   tps.=''
   do i=i+1 to rawtpl.0
      parse var rawtpl.i var op val .
      if var='' then iterate
      if var='<end>' then leave
      j=j+1
      tps.j=var
      tps.var.1=op
      tps.var.2=val
   end
   tps.0=j
   return

externaltpl:
   rawtpl.0=0
   return

/**********************************************************************/
/* formatted dump utility                                             */
/**********************************************************************/
dump:
   procedure
   parse arg dumpbuf
   say
   sk=0
   prev=''
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
   say
   return

/**********************************************************************/
/*  Function: GETOPTS                                                 */
/*  Example:                                                          */
/*    parse value 'a   b   c   d' with,                               */
/*                 lca lcb lch lcd .                                  */
/*    argx=getopts('ab','cd',start)                                   */
/*    if argx=0 then exit 1                                           */
/*    if opt.0=0 then                                                 */
/*       say 'No options were specified'                              */
/*     else                                                           */
/*       do                                                           */
/*       if opt.lca<>'' then say 'Option a was specified'             */
/*       if opt.lcb<>'' then say 'Option b was specified'             */
/*       if opt.lch<>'' then say 'Option c was specified as' opt.lch  */
/*       if opt.lcd<>'' then say 'Option d was specified as' opt.lcd  */
/*       end                                                          */
/*    if __argv.0>=argx then                                          */
/*       say 'Files were specified:'                                  */
/*     else                                                           */
/*       say 'Files were not specified'                               */
/*    do i=argx to __argv.0                                           */
/*       say __argv.i                                                 */
/*    end                                                             */
/**********************************************************************/
getopts: procedure expose opt. __argv. errmsg
   parse arg arg0,arg1,start
   argc=__argv.0
   opt.=''
   opt.0=0
   optn=0
   if start='' then
      start=2
   do i=start to argc
      if substr(__argv.i,1,1)<>'-' then leave
      if __argv.i='--' then
         do
         i=i+1
         leave
         end
      opt=substr(__argv.i,2)
      do j=1 to length(opt)
         op=substr(opt,j,1)
         if pos(op,arg0)>0 then
            do
            opt.op=1
            optn=optn+1
            end
         else
         if pos(op,arg1)>0 then
            do
            if substr(opt,j+1)<>'' then
               do
               if opt.op='' then
                  do
                  opt.op=substr(opt,j+1)
                  opt.op.1=substr(opt,j+1)
                  opt.op.0=1
                  end
                else
                  do
                  optmp=opt.op.0
                  optmp=optmp+1
                  opt.op.optmp=substr(opt,j+1)
                  opt.op.0=optmp
                  end
               j=length(opt)
               end
             else
               do
               i=i+1
               if i>argc then
                  do
                  errmsg='Option' op 'requires an argument'
                  return 0
                  end
               if opt.op='' then
                  do
                  opt.op=__argv.i
                  opt.op.1=__argv.i
                  opt.op.0=1
                  end
                else
                  do
                  optmp=opt.op.0
                  optmp=optmp+1
                  opt.op.optmp=__argv.i
                  opt.op.0=optmp
                  end
               end
            optn=optn+1
            end
         else
            do
            errmsg='Invalid option =' op
            return 0
            end
      end
   end
   opt.0=optn
   return i

/*
//template short
&mnte_fsname                               . &status                       .
&mnte_path                                                             .
~parm                                                                  .
<zfs>
~1 . ~2. Owner: ~5     . ZFS owner: ~6     . Devno: &mnte_dev  .
</zfs>
<-zfs>
~1 . ~2. Owner: ~5     .                     Devno: &mnte_dev  .
</-zfs>
-&automove       .&exported.&nosetid.&nosecurity.&client.&acls.
&mnte_pfsstatusnormal                                                  .
&mnte_pfsstatusexcp                                                    .
Space(MB): Total: &totalmeg  . Frag: &fragmeg   . Utilization:!4  .%
           Free:  &freemeg   . Used: &usedmeg   . System use : &sysmeg  .
.
<variables>
1 mnte_fstype
2 mountmode
4 utilization
5 mnte_sysname
6 zfsowner
parm mnte_parm Mount parm:
<select>
<end>

//template verbose
&mnte_fsname                               . &status                       .
&mnte_path                                                             .
~parm                                                                  .
<zfs>
~1 . ~2. Owner: ~5     . ZFS owner: ~6     . Devno: &mnte_dev  .
</zfs>
<-zfs>
~1 . ~2. Owner: ~5     .                     Devno: &mnte_dev  .
</-zfs>
Filetag: T=~7. Codeset=&ccsid.
-&automove       .&exported.&nosetid.&nosecurity.&client.&acls.
&mnte_pfsstatusnormal                                                  .
&mnte_pfsstatusexcp                                                    .
Space(MB): Total: &totalmeg  . Frag: &fragmeg   . Utilization:!4  .%
           Free:  &freemeg   . Used: &usedmeg   . System use : &sysmeg  .
Activity:  &requests          .
<zfs>
Created:   &createtime         .
Updated:   &updatetime         .
Accessed:  &accesstime         .
@nfilesystems           . nfilesystems
@threshold              . threshold
@increment              . increment
@monitor                . monitor
@ro                     . ro
@nbs                    . nbs
@compat                 . compat
@grow                   . grow
@dynamicmove            . dynamicmove
@quiesced               . quiesced
@disabled               . disabled
@blocks                 . blocks
@fragsize               . fragsize
@blocksize              . blocksize
@totalusable            . totalusable
@realfree               . realfree
@minfree                . minfree
@moveinterval           . moveinterval
@movepercent            . movepercent
@movemin                . movemin
@freeblocks             . freeblocks
@freefrags              . freefrags
@directlog              . directlog
@indirectlog            . indirectlog
@fstbl                  . fstbl
@bitmap                 . bitmap
@diskformatmajorversion . diskformatmajorversion
@diskformatminorversion . diskformatminorversion
@auditfid               . auditfid
@clonetime              . clonetime
@createtime             . createtime
@updatetime             . updatetime
@accesstime             . accesstime
@alloclimit             . alloclimit
@allocusage             . allocusage
@visquotalimit          . visquotalimit
@visquotausage          . visquotausage
@accerror               . accerror
@accstatus              . accstatus
@fstyperw               . fstyperw
@fstypebk               . fstypebk
@nodemax                . nodemax
@minquota               . minquota
@type                   . type
@threshold              . threshold
@increment              . increment
@mountstate             . mountstate
@inodetbl               . inodetbl
@requests               . requests
</zfs>
<hfs>
@totalspacek            . totalspacek
@usedspacek             . usedspacek
@utilization            . utilization
@systemspacek           . systemspacek
@cachedpages            . cachedpages
@seqio                  . seqio
@randomio               . randomio
@lookups                . lookups
@indexreads             . indexreads
@indexwrites            . indexwrites
@hfsflags               . hfsflags
@hfssyncerror           . hfssyncerror
@writeprotecterror      . writeprotecterror
@syncnospace            . syncnospace
@highformatrfn          . highformatrfn
@membercount            . membercount
@syncinterval           . syncinterval
@apmcount               . apmcount
</hfs>
.
<variables>
1 mnte_fstype
2 mountmode
3 automove
4 utilization
5 mnte_sysname
6 zfsowner
7 text
<select>
<end>

//end

//template quiesced
<&quiesced=1>
&mnte_fsname                               . &status                       .
</>
<select>
<end>

 */
