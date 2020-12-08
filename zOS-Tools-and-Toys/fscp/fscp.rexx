/* REXX */
/**********************************************************************/
/* Copy or compare file systems                                       */
/*                                                                    */
/* Property of IBM                                                    */
/* Copyright IBM Corp. 2008                                           */
/*                                                                    */
/* Syntax:  fscp copy    <-sutv> <source> <dest>                      */
/*          fscp newfs   <-sutv> <source> <dest>                      */
/*          fscp check   <-sev>  <source> <dest>                      */
/*          fscp compare <-sev>  <source> <dest>                      */
/*          fscp space   <-sv>   <source> <dest>                      */
/*                                                                    */
/*           -s    switch to uid=0                                    */
/*           -u    do not preserve uid and gid                        */
/*           -t    use copytree rather than pax                       */
/*           -e    continue if errors                                 */
/*           -v    verbose                                            */
/*    <source>     source file system or mountpoint                   */
/*    <dest>       destination or compare to file system or mountpoint*/
/*                                                                    */
/* Notes:                                                             */
/*  - source and dest can be entered as upper or lower case if using  */
/*    a file system name.  These are case sensitive if pathnames.     */
/*  - dest must be an empty and already created file system for copy  */
/*    or a new file system name for newfs                             */
/*  - newfs will create a new file system of the same type and similar*/
/*    size to the original.  This function will not work on releases  */
/*    prior to z/OS 1.10.  The new file system will be allocated with */
/*    one primary extent about the same size as the entire old file   */
/*    system and is allocated to general disk (sysallda).             */
/*  - if source or dest are not mounted they will be mounted          */
/*      for the operation then unmounted                              */
/*  - if source or dest are not mounted, use a file system name       */
/*  - both check and compare check names and attributes but compare   */
/*    also checks the content of files                                */
/*  - only a few attributes are checked: size, type, links, symlinks, */
/*    extended attributes, file mode                                  */
/*                                                                    */
/* Bill Schoen  8/25/2008   <wjs@us.ibm.com>                          */
/*                                                                    */
/**********************************************************************/
  paxcmd  = "/bin/pax -rw -peW -XCM"  
  paxcmd2 = "/bin/pax -rw -ppAxW -XCM"     
  paxenv  = '_CEE_RUNOPTS="HEAP(128K,512K,ANYWHERE,FREE,16K,16K)"'      
  findcmd = '/bin/find . -xdev -name "*"'
  cptcmd  = '/samples/copytree -a'
 
  parse arg func prm
  parse source . . . . . . . isp .
  sayx=0
 
  if syscalls('ON')<>0 then
     do
     say 'cannot access UNIX services'
     exit 1
     end
  address syscall 'getpid'
  pid=retval
  func=translate(func)
  cc=0
  select
  when func='COPY' then call copyfs
  when func='NEWFS' then call newcopy
  when func='CHECK' then call compfs    
  when func='COMPARE' then call compfs  
  when func='SPACE'  then call compspace
  otherwise
     help:
     say 'fscp copy [-sut] fromfilesys tofilesys' 
     say 'fscp newfs [-sut] fromfilesys tofilesys'
     say 'fscp check [-se] filesys1 filesys2'  
     say 'fscp compare [-se] filesys1 filesys2'  
     say 'fscp space filesys1 filesys2'  
     exit 1
  end
  signal exit
 
/* make a new file system then copy the old to new */
newcopy:
  wc      = words(prm)
  if wc<2 then signal help 
  dest    = word(prm,wc)           
  prm     = delword(prm,wc)
  source  = word(prm,wc-1)           
  opts    = delword(prm,wc-1)
 
  if pos('-',source dest) > 0 | source = dest then signal help
 
  if pos('s',opts) > 0 then
    call su
 
  call getsrcfs
  dest=translate(dest)
  address syscall
  /* calc size of filesys in K bytes */
  'stat (sourcep) srcst.'
  'getmntent srcmnt.' x2d(srcst.st_dev)
  'statfs (source) srcstfs.'
  type=strip(srcmnt.mnte_fstype.1)                  
  blocks=srcstfs.stfs_total                     
  blockkb=srcstfs.stfs_blocksize%1024           
 
  /* make a new filesys same type as old in KB allocation units */
  if mkfs(type,blocks,blockkb) then       
     do
     cc=8
     return
     end
  delonerror=1
 
  /* make a mountpoint */
  destp='/tmp/fscp.'userid()'.'pid   
  if pos('v',opts) > 0 then say 'mkdir' destp
  'mkdir (destp) 700'
  if retval=-1 then
     do
     say errno errnojr 'error creating mountpoint' destp
     cc=8
     return
     end
  if pos('v',opts) > 0 then say 'mounting' dest 'at' destp
  'mount (destp) (dest) (type)' mtm_rdwr
  if retval=-1 then
     do
     say errno errnojr 'error mounting filesystem'      
     'rmdir (destp)'
     cc=8
     return
     end
  mounteddest=1
  delonerror=0
 
  /* copy old to new */
  call docopy   
  return
 
mkfs:
  parse arg type,blocks,blockkb
  if type='HFS' then
     return mkhfs()
 
  if type='ZFS' then
     return mkzfs()
 
  say 'Filesystem type must be HFS or ZFS'
  return 1
 
mkhfs:
   alloc='alloc rtddn(dd) da('dest') unit(sysallda)',                  
         'dsntype(hfs) dir(1) avgrec(k) new catalog',  
         'space('blocks*blockkb+1') block(1) msg(msg.)'     
   if pos('v',opts) > 0 then say alloc
   msg.0=0  
   rv=bpxwdyn(alloc)  
   call bpxwdyn 'free fi('dd')'  
   if rv=0 then           
      return 0
 
   say 'alloc error' rv  
   do i=1 to msg.0  
      say msg.i  
   end  
   return 1  
 
mkzfs:
   numeric digits 10
   fsn=dest        
   perm=488           /* 0750*/
   fspri=blocks*blockkb+1
   fssec=0
   z1='00'x
   z2='0000'x
   z4='00000000'x
   address syscall 'getuid'      
   uid=retval      
   address syscall 'getgid'      
   gid=retval      
   pctcmd=x2d('40000005')
 
   alloc='alloc rtddn(dd) da('strip(fsn)') space('fspri') block(1)',
         'unit(sysallda) new catalog recorg(ls) avgrec(k) msg(msg.)'
   if pos('v',opts) > 0 then say alloc
 
   msgs.0=0
   dynrc=bpxwdyn(alloc)
   if dynrc<>0 then
      do
      say 'allocation error for' fsn 'RC='dynrc     
      do i=1 to msg.0 
         say msg.i      
      end
      return 1
      end
   call bpxwdyn 'free fi('dd')'
 
   agid= 'AGID'          ||,                  /* agid str  */
         z1              ||,                  /* length    */
         '01'x           ||,                  /* version   */
         left(fsn,45,z1) ||,                  /* fsn       */
         copies(z1,33)                        /* rsvd      */
   agid='AGID' || d2c(length(agid),1) || substr(agid,6)
 
   agfm= 'AGFM'        ||,                    /* agfm str  */
         z2            ||,                    /* length    */
         '01'x         ||,                    /* version   */
         z1            ||,                    /* rsvd      */
         z4            ||,                    /* fmt sz    */
         z4            ||,                    /* log sz    */
         d2c(1,4)      ||,                    /* init empty*/
         d2c(1,4)      ||,                    /* overwrite */
         d2c(1,4)      ||,                    /* hfs compat*/
         d2c(uid,4)    ||,                    /* uid       */
         d2c(1,4)      ||,                    /* uid set   */
         d2c(gid,4)    ||,                    /* gid       */
         d2c(1,4)      ||,                    /* gid set   */
         d2c(perm,4)   ||,                    /* mode bits */
         d2c(1,4)      ||,                    /* mode set  */
         d2c(fssec*700,4)  ||,                /* grow inc  */
         copies(z1,60)                        /* rsvd      */
   agfm='AGFM' || d2c(length(agfm),2) || substr(agfm,7)
 
   pl=32
   pctbf=d2c(134,4) ||,                       /* format op */
         d2c(pl,4)  ||,                       /* p0: id    */
         d2c(pl+length(agid),4) ||,           /* p1: fmt   */
         z4         ||,                       /* p2: 0     */
         z4||z4||z4||z4||,                    /* p3-p6     */
         agid       ||,
         agfm
   if pos('v',opts) > 0 then say 'formatting zfs' fsn
   address syscall 'pfsctl ZFS' pctcmd 'pctbf' length(pctbf)
   if retval=-1 then
      do
      address tso "del '"fsn"'"
      pcter=errno   
      pctrs=errnojr   
      err.=''   
      address syscall 'strerror' pcter pctrs 'err.'   
      if err.1<>'' then   
         eno=eno strip(err.1)'.'   
      rsn='  Reason='errnojr'x'   
      if err.4<>'' & err.2<>'' then   
         rsn=rsn strip(err.2)   
      say eno rsn   
      return 1
      end
   return 0  
 
/* compare space attributes between file systems */
compspace:
  wc      = words(prm)
  if wc<2 then signal help 
  dest    = word(prm,wc)           
  prm     = delword(prm,wc)
  source  = word(prm,wc-1)           
  opts    = delword(prm,wc-1)
 
  if pos('-',source dest) > 0 | source = dest then signal help
 
  if pos('s',opts) > 0 then
    call su
 
  call getsrcfs
  call getdstfs
  address syscall
  'stat (sourcep) srcst.'
  'stat (destp) dstst.'
  'getmntent srcmnt.' x2d(srcst.st_dev)
  'statfs (source) srcstfs.'
  'getmntent dstmnt.' x2d(dstst.st_dev)
  'statfs (dest) dststfs.'
  srcstfs.0=srcmnt.mnte_fstype.1
  dststfs.0=dstmnt.mnte_fstype.1
  diff=0
  if srcmnt.mnte_fstype.1<>dstmnt.mnte_fstype.1 then
     call smsg 'fstype',0
  if srcstfs.stfs_avail<>dststfs.stfs_avail then
     call smsg 'Available',stfs_avail
  if srcstfs.stfs_blocksize<>dststfs.stfs_blocksize then
     call smsg 'Block size',stfs_blocksize
  if srcstfs.stfs_inuse<>dststfs.stfs_inuse then
     call smsg 'In use',stfs_inuse
  if srcstfs.stfs_total<>dststfs.stfs_total then
     call smsg 'Total',stfs_total
  if diff=0 then
     say 'no differences found'
 
  return     
 
smsg:
   ix=arg(2)
   if diff=0 then
      call say 'Differences found:'
   diff=1
   call say left(arg(1),12) right(srcstfs.ix,12) right(dststfs.ix,12)
   return
 
/* compare two file systems */
compfs:
  wc      = words(prm)
  if wc<2 then signal help
  dest    = word(prm,wc)           
  prm     = delword(prm,wc)
  source  = word(prm,wc-1)           
  opts    = delword(prm,wc-1)
 
  if pos('-',source dest) > 0 then signal help                
 
  if pos('s',opts) > 0 then
    call su
 
  call getsrcfs
  call getdstfs
  say 'comparing' source 'on' sourcep                        
  say '     with' dest 'on' destp
  src.0=0  
  dst.0=0
 
  /* get all pathnames in both file systems */
  call bpxwunix 'cd' sourcep';'findcmd,,src.,srcerr.
  call bpxwunix 'cd' destp';'findcmd,,dst.,dsterr.
  if pos('v',opts) > 0 then
     say 'checking' max(src.0,dst.0) 'files'
  ix.=0 
  missing=0
  do i=1 to srcerr.0
     call say srcerr.i
  end
  do i=1 to dsterr.0
     call say dsterr.i
  end
  if pos('e',opts)=0 & (srcerr.0>0 | dsterr.0>0) then
     do
     cc=8
     return
     end
 
  /* for each pathname in dst, try to find the same name is src */
  k=0
  do i=1 to dst.0
     do j=1 to src.0
        if dst.i==src.j then
           do
           k=k+1
           /* save matching name to check attrs later */
           attr.k=dst.i
           dst.i=''
           src.j=''
           leave
           end
     end
     /* if name in dst not found in src do an access call to verify
        it is not really there.  find does not return mountpoints
        so it really might be there */
     if length(dst.i)>0 then
        do
        ckpath=sourcep'/'dst.i
        address syscall 'access (ckpath)' f_ok
        if retval=-1 then
           do
           if missing=0 then
              call say 'Files missing from' source
           missing=missing+1
           call say '  'dst.i
           end
         else
           do
           /* if found in source but not in list, add to attr check */
           k=k+1
           attr.k=dst.i
           end
        end
  end
 
  /* repeat above process looking through src for any names remaining */
  missing=0
  do i=1 to src.0
     if length(src.i)>0 then
        do
        /* note: find -xdev skips mountpoints */
        ckpath=destp'/'src.i
        address syscall 'access (ckpath)' f_ok
        if retval=-1 then
           do
           if missing=0 then
              call say 'Files missing from' dest
           missing=missing+1
           call say '  'src.i
           end
         else
           do
           /* if found in dest but not in list, add to attr check */
           k=k+1
           attr.k=src.i
           end
        end
  end
 
  diff=0
  szerr=0
  slnkerr=0
  lnkerr=0
  tperr=0
  xaterr=0
  mderr=0
  copnerr=0
  crderr=0
  ino.=0
  /* check each pathname for same attrs in both file systems */
  do i=1 to k
     fns=sourcep'/'attr.i
     address syscall 'lstat (fns) sat.'
     fnd=destp'/'attr.i
     address syscall 'lstat (fnd) dat.'
     ino=sat.st_ino
     if sat.st_type<>dat.st_type then                              
        do
        call tperr
        iterate
        end
     /* mode check verifies same base permissions and acl if ACLs
        are there.  ACL equivalence is not checked */
     if sat.st_mode<>dat.st_mode |,                                
        sat.st_setgid<>dat.st_setgid |,                            
        sat.st_setuid<>dat.st_setuid |,                            
        sat.st_sticky<>dat.st_sticky |,                            
        sat.st_accessacl<>dat.st_accessacl |,                      
        sat.st_dmodelacl<>dat.st_dmodelacl |,                      
        sat.st_fmodelacl<>dat.st_fmodelacl then                    
        do
        call mderr
        iterate
        end
     if sat.st_genvalue/==dat.st_genvalue then
        do
        call xaterr
        iterate
        end
     if sat.st_type=s_isdir then iterate                         
     if sat.st_type=s_issym then            
        do
        address syscall 'readlink (fns) lnks'
        address syscall 'readlink (fnd) lnkd'
        if lnks/==lnkd then
           do
           call slnkerr
           iterate
           end
        end
     if sat.st_nlink<>dat.st_nlink then     
        do
        call lnkerr
        iterate
        end
     if sat.st_type<>s_isreg then iterate
     if sat.st_size<>dat.st_size then       
        do
        call szerr
        iterate
        end
 
     /* if it is a regular file and a full compare was requested
        do the full compare on the two files */
     if func='COMPARE' then
        call compfile
  end
 
  /* everything checked, report errors */
 
  if tperr>0 then  
     call say 'Files with different types'
  do i=1 to tperr
     call say '  'tperr.i
  end
 
  if mderr>0 then  
     call say 'Files with different modes (permissions)'
  do i=1 to mderr
     call say '  'mderr.i
  end
 
  if szerr>0 then  
     call say 'Files with different sizes'
  do i=1 to szerr
     call say '  'szerr.i
  end
 
  if slnkerr>0 then
     call say 'Different symbolic links'
  do i=1 to slnkerr
     call say '  'slnkerr.i
  end
 
  if lnkerr>0 then 
     call say 'Files with different link counts'
  do i=1 to lnkerr
     call say '  'lnkerr.i
  end
 
  if xaterr>0 then 
     call say 'Files with different extended attributes'
  do i=1 to xaterr
     call say '  'xaterr.i
  end
 
  if copnerr>0 then
     call say 'Unable to open files'                    
  do i=1 to copnerr
     call say '  'copnerr.i
  end
 
  if crderr>0 then 
     call say 'Files with different data'               
  do i=1 to crderr
     call say '  'crderr.i
  end
 
  /* if no errors reported then report no differences */
  if sayx<>0 then     
     cc=8
   else
     say 'no differences found'                           
  return     
 
/* compare two files */
compfile:
   if ino.ino then return          /* skip additional hardlinks */
   ino.ino=1
   address syscall 'open (fns)' o_rdonly 000
   sfd=retval
   if sfd=-1 then
      do
      call copnerr errno errnojr
      return
      end
   address syscall 'open (fnd)' o_rdonly 000
   dfd=retval
   if dfd=-1 then
      do
      call copnerr errno errnojr
      address syscall 'close' sfd
      return
      end
   do forever
      address syscall 'read' sfd 'sbuf' 4096*16
      srv=retval
      seno=errno
      srsn=errnojr
      address syscall 'read' dfd 'dbuf' 4096*16
      drv=retval
      deno=errno
      drsn=errnojr
      if srv=-1 then
         do
         call crderr seno srsn
         leave
         end
      if drv=-1 then
         do
         call crderr deno drsn
         leave
         end
      if srv<>drv then              
         do
         call crderr
         leave
         end
      if srv=0 then leave  /* srv=drv=0, EOF */
      if sbuf/==dbuf then
         do
         call crderr  
         leave
         end
   end
   address syscall 'close' sfd
   address syscall 'close' dfd
   return
 
/* error collection routines */
 
copnerr:
   copnerr=copnerr+1
   copnerr.copnerr=attr.i arg(1)
   return
 
crderr:
   crderr=crderr+1
   crderr.crderr=attr.i arg(1)
   return
 
szerr:
  if ino.ino then return      /* skip additional hardlinks */
  ino.ino=1
  szerr=szerr+1
  szerr.szerr=attr.i
  return
 
tperr:
  if ino.ino then return      /* skip additional hardlinks */
  ino.ino=1
  tperr=tperr+1
  tperr.tperr=attr.i
  return
 
mderr:
  if ino.ino then return      /* skip additional hardlinks */
  ino.ino=1
  mderr=mderr+1
  mderr.mderr=attr.i
  return
 
slnkerr:
  if ino.ino then return      /* skip additional hardlinks */
  ino.ino=1
  slnkerr=slnkerr+1
  slnkerr.slnkerr=attr.i
  return
 
lnkerr:
  if ino.ino then return      /* skip additional hardlinks */
  ino.ino=1
  lnkerr=lnkerr+1
  lnkerr.lnkerr=attr.i
  return
 
xaterr:
  if ino.ino then return      /* skip additional hardlinks */
  ino.ino=1
  xaterr=xaterr+1
  xaterr.xaterr=attr.i
  return
 
/* try to switch to superuser */
su:
  address syscall 'geteuid'    
  myeuid = retval    
  if myeuid <> 0 then    
    do    
      address syscall 'getuid'    
      myuid = retval    
      address syscall 'setreuid 0 0'    
      lerrno = errno    
      lerrnojr = errnojr    
      address syscall 'geteuid'    
      if retval <> 0 then    
        do    
          say    
          say 'Unable to set UID to 0.'    
          say 'Errno='lerrno 'Reason='lerrnojr    
          cc=8
          myeuid=''
          signal exit
        end    
    end    
  return
 
/* get mount table and locate the source file system */
getsrcfs:
  if pos('v',opts) > 0 then say 'getting mount table'
  address syscall 'getmntent mnt.'
  smntpath=''
  address syscall 'realpath (source) smntpath'
  do i = 1 to mnt.0                                  
     if mnt.mnte_fsname.i=source then leave
     if translate(mnt.mnte_fsname.i)=translate(source) then leave
     if smntpath<>'' then
     if mnt.mnte_path.i=smntpath then leave
  end
 
  if i > mnt.0 then
    do
      sourcep = mountit(source)
      source=translate(source)
      mountedsource = 1
    end
  else
    do
      source=strip(mnt.mnte_fsname.i)
      sourcep = mnt.mnte_path.i
    end
  return
 
/* locate the dest file system */
getdstfs:
  address syscall 'realpath (dest) dmntpath'  
  do i = 1 to mnt.0                                  
     if mnt.mnte_fsname.i=dest then leave  
     if translate(mnt.mnte_fsname.i)=translate(dest) then leave
     if dmntpath<>'' then
        if mnt.mnte_path.i=dmntpath then leave
  end
 
  if translate(dest)=source then
     do
     cc=8
     say 'the two filesystems have the same name'
     signal exit
     end
 
  if i > mnt.0 then
    do
      destp = mountit(dest)
      dest=translate(dest)
      mounteddest = 1
    end
  else
    do
      dest=strip(mnt.mnte_fsname.i)
      destp = mnt.mnte_path.i
    end
  return
 
/* setup to copy one file system to another */
copyfs:
  wc      = words(prm)
  if wc<2 then
    do
      cc=8
      say 'must enter source and destination file system names'
      return
    end
  dest    = word(prm,wc)           
  prm     = delword(prm,wc)
  source  = word(prm,wc-1)           
  opts    = delword(prm,wc-1)
 
  if pos('-',source dest) > 0 then                         
    signal help
 
  if pos('u',opts) > 0 then
     paxcmd = paxcmd2                      
 
  if pos('s',opts) > 0 then
     call su
 
  call getsrcfs
  call getdstfs
  call docopy
  return
 
/* copy one file system to another using pax or copytree */
docopy:   
 
  address syscall 'readdir (destp) dir.'
 
  if retval = -1 then
    call scerr 'readdir'  
 
  if dir.0 > 2 then
    do
      say dest 'is not empty'
      cc=8
      return     
    end
 
  if pos('t',opts) > 0 then
     cmd=cptcmd sourcep destp     /* using copytree */
   else
    do
     /* using pax.  beware, pax may make nonsparse files sparse */
     /* need to look for any sparse files, if none use -D */
     call bpxwunix 'cd' sourcep';'findcmd,,src.,srcerr.
     do i=1 to srcerr.0
        say srcerr.i
     end
     if srcerr.0>0 & pos('e',opts)=0 then
        do
        cc=8
        return
        end
     do i=1 to src.0
        path=sourcep'/'src.i
        address syscall 'lstat (path) st.'
        if retval=-1 | st.st_type<>s_isreg then iterate
        if st.st_blocks*st.st_blksize<st.st_size then
           leave   /* found sparse file */
     end
     if i>src.0 then
        paxcmd=paxcmd '-D'
     cmd = "cd" sourcep";" paxcmd '.' destp
    end
 
  if pos('v',opts) > 0 then
     say cmd
  ev.0=1
  ev.1=paxenv
  cprc = bpxwunix(cmd,,'cpo.','cpe.','ev.')
 
  if cprc = 0 | cpe.0>0 then
    cc = 0  
  else
    do
      cc=8
      say 'copy return code='cprc
      say
      do i = 1 to cpo.0
         say cpo.i
      end
      do i = 1 to cpe.0
         say cpe.i
      end
    end
  return
 
/* common exit routine: cleanup and exit */
exit:
  address syscall
  if mountedsource = 1 then
    do
    if pos('v',opts) > 0 then say 'unmounting' source
    'unmount' source mtm_immed  
    'rmdir' sourcep  
    end
  if mounteddest = 1 then
    do
    if pos('v',opts) > 0 then say 'unmounting' dest
    'unmount' dest mtm_immed  
    'rmdir' destp  
    end
  if pos('-s',opts)>0 & myeuid<>'' then 
    do
    if pos('v',opts) > 0 then say 'resetting euid'
    address syscall 'seteuid' myeuid  
    end
  if delonerror=1 then
     do
     if pos('v',opts) > 0 then say 'deleting' dest
     call bpxwdyn "alloc rtddn(dd) da("dest") old delete"
     call bpxwdyn "free dd("dd") delete"
     end
  if sayx>0 then 
     do
     say.0=sayx
     call brstem 'say.'
     end
  say 'fscp exit code =' cc
  exit cc
 
brstem:    
   address ispexec
   brc=value(arg(1)"0")     
   if brc=0 then
      do
      return
      end
   brlen=250
   do bri=1 to brc
      if brlen<length(value(arg(1) || bri)) then
         brlen=length(value(arg(1) || bri))
   end
   brlen=brlen+4
   call bpxwdyn "alloc rtddn(bpxpout) reuse new",                     
                "recfm(v,b) lrecl("brlen") msg(wtp)"           
   address mvs "execio" brc "diskw" bpxpout "(fini stem" arg(1)
   'LMINIT DATAID(DID) DDNAME('BPXPOUT')'
   if arg(2)='' then
      'VIEW   DATAID('did') PROFILE(WJSC) MACRO(RESET)'
   else
      'VIEW   DATAID('did') PROFILE(WJSC)' arg(2)
   'LMFREE DATAID('did')'
   call bpxwdyn 'free dd('bpxpout')'
   return
 
mountit:
  address syscall
  parse arg fsn .
  if pos('/',fsn)>0 then
     do
     say 'Not a mountpoint:' fsn
     cc=8
     signal exit
     end
  fsn=translate(fsn)
 
  path = '/tmp/'fsn'.'pid   
  if pos('v',opts) > 0 then
     say 'mounting' fsn 'at' path
 
  'mkdir (path) 700'
  if retval = -1 then call scerr 'mkdir'
 
  'mount' path fsn 'HFS' mtm_rdwr
  if retval = -1 then call scerr 'mount'
  return path
 
scerr:
  say 'error on' arg(1)
  say errno errnojr
  address tso 'bpxmtext' errnojr
  cc=8
  signal exit
 
say:
  say arg(1)   
  if isp<>'ISPF' then
     sayx=-1
   else
     do
     sayx=sayx+1
     say.sayx=arg(1)
     end
  return
