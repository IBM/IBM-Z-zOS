/* REXX */
/**********************************************************************/
/* WJSCKMP: check if mountpoints are empty directories                */
/*                                                                    */
/*   This utility will look under mounted file systems to check       */
/*   that the mountpoint directory is empty.  Mountpoint directories  */
/*   cannot normally be accessed so they should be empty.             */
/*   This can be useful prior to implementing the BPXPRMxx option     */
/*   NONEMPTYMOUNTPT which will cause mounts over non-empty           */
/*   mountpoints to fail.                                             */
/*                                                                    */
/*   You must be superuser or permitted to BPX.SUPERUSER to run this  */
/*   This can run from TSO, shell, or sysrexx                         */
/*                                                                    */
/*   Syntax:  wjsckmp  <option> <mountpoint>                          */
/*                                                                    */
/*   Options:                                                         */
/*     -v           verbose.  lists the directories being checked     */
/*                  and any file names it finds in those directories  */
/*                                                                    */
/*   <mountpoint>   an optional argument to check a specific          */
/*                  mountpoint.  if omitted, all mountpoints are      */
/*                  checked.                                          */
/*                                                                    */
/* PROPERTY OF IBM                                                    */
/* COPYRIGHT IBM CORP. 2013                                           */
/*                                                                    */
/* Bill Schoen    wjs@us.ibm.com  11/22/13                            */
/*  Change activity:                                                  */
/*                                                                    */
/**********************************************************************/
parse source . . . . . . . rxenv .
call syscalls 'ON'
address syscall
address syscall 'geteuid'    /* try to switch to uid 0 if not already */
if retval<>0 then
   address syscall 'seteuid 0'
'v_reg 1 WJSCKMP'                /* register as a file server         */
if retval=-1 then
   do
   call say 'v_reg error:' errno errnojr
   exit 2
   end
verbose=0
path=''
parse arg args
do i=1 to words(args)
   opt=word(args,i)
   if substr(opt,1,1)='-' then
      do
      opt=translate(substr(opt,2))
      if opt='V' then verbose=1
      end
    else
      do
      path=opt
      leave
      end
end
if path<>'' then
   do
   mnt.0=1
   'realpath (path) mnt.mnte_path.1'
   st.=''
   stp.=''
   'stat (path) st.'
   pathp=path'/..'
   'stat (pathp) stp.'
   if st.st_dev='' | stp.st_dev='' then
      do
      call say 'cannot locate directory' path
      exit 2
      end
   if st.st_dev=stp.st_dev then
      do
      call say 'not a mountpoint' path
      exit 2
      end
   end
 else
   'getmntent mnt.'
total=0
do m=1 to mnt.0
   call readdir mnt.mnte_path.m
end
if total=0 then
   call say 'no non-empty mountpoints found'
 else
   call say 'non-empty mountpoints found:' total
return

readdir:
parse arg dir                    /* take directory path as argument   */
if dir='' then return
if verbose then call say 'checking' dir
i=lastpos('/',dir)
if i=0 then return
name=substr(dir,i+1)
dir=substr(dir,1,i)
if name='' then return
'v_rpn (dir) vfs vnp mnt. st.'    /* resolve the directory pathname    */
if retval=-1 then
   do
   call say 'error resolving path' dir '- error codes:' errno errnojr
   return
   end
'v_lookup vnp (name) st. vn'
if retval=-1 then
   do
   call say 'error resolving name' name'- error codes:' errno errnojr
   return
   end
i=1                              /* next dir entry to read is 1       */
j=0
do forever                       /* loop reading directory            */
   'v_readdir vn d.' i           /* read starting at next entry       */
   if retval=-1 then
      do
      call say 'error reading directory - error codes:' errno errnojr
      leave
      end
   if d.0=0 then leave           /* if nothing returned then done     */
   if verbose then
      do d=1 to d.0
         if d.d='.' & d.0>2 then
            call say 'Names in' dir||name
         if d.d<>'.' & d.d<>'..' then
            call say ' ' d.d
      end
   j=j+d.0
   i=i+d.0                       /* set index to next entry           */
end
if j>2 then
   do
   total=total+1
   call say 'non-empty mountpoint:' dir||name
   end
'v_rel vn'                       /* release the directory vnode       */
'v_rel vnp'                      /* release the parent vnode          */
return

/* output msg, immediate if running sysrexx */
say:
    if rxenv='AXR' then
         call axrwto arg(1)
      else
         say arg(1)
    return

