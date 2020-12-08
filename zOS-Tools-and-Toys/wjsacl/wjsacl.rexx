/* REXX */
/**********************************************************************/
/* WJSACL: set ACLs for a directory and everything underneath         */
/*         show ACLs for a file or directory                          */
/*                                                                    */
/*   See help at bottom for syntax                                    */
/*   Enter wjsacl with no arguments to print help information         */
/*                                                                    */
/*   Usage:  Place this where you can run a rexx program              */
/*           This can run from the shell, TSO, or sysrexx             */
/*                                                                    */
/*   Note:   You must be superuser or own the files to add the ACL    */
/*                                                                    */
/* PROPERTY OF IBM                                                    */
/* COPYRIGHT IBM CORP. 2012,2014                                      */
/*                                                                    */
/* Bill Schoen    wjs@us.ibm.com    4/19/2012                         */
/*                                                                    */
/*  Change Activity:                                                  */
/*    2/21/2014   add options, enable shell, sysrexx, add help        */
/*                                                                    */
/**********************************************************************/
parse arg opts
parse var opts opts '--'  paths
call syscalls 'ON'
if opts='' | opts='?' | opts='-h' then
   signal help

parse upper value optflag('-p',1) with opt_p perm
parse upper value optflag('-f',1) with opt_f fperm
opt_q=optflag('-q')
verbose=optflag('-v')
opt_d=optflag('-d')
parse upper value optflag('-u',1) with opt_u userlist
parse upper value optflag('-g',1) with opt_g grouplist
parse value optflag('-c',1) with opt_c sourcepath
/* any option flags left over are invalid. give error and exit */
do forever
   parse var opts  '-' opt rest
   if opt='' then leave
   call say 'option flag -'opt 'is not valid'
   signal help
end
/* anything left over is the command argument */
if paths='' & opts<>'' then
   paths=strip(opts)

do i=1 to words(paths)
   path.i=word(paths,i)
end
path.0=i-1
if path.0=0 then signal help

if opt_q then
   do
   call listacls
   exit 0
   end

if opt_c=0 & opt_p=0 & opt_f=0 & opt_d=0 then signal help
if opt_p then
   if translate(perm,'   ','RWX')<>'' then signal help
if opt_f then
   do
   if translate(fperm,'   ','RWX')<>'' then signal help
   end
 else
   fperm=perm

userlist=translate(userlist,' ',',')
do i=1 to words(userlist)
   user=word(userlist,i)
   u.=''
   address syscall 'getpwnam (user) u.'
   if u.pw_uid='' then
      do
      call say 'Cannot access uid for user' user
      exit 1
      end
   uid.i=u.pw_uid
end
uid.0=i-1
grouplist=translate(grouplist,' ',',')
do i=1 to words(grouplist)
   group=word(grouplist,i)
   u.=''
   address syscall 'getgrnam (group) u.'
   if u.gr_gid='' then
      do
      call say 'Cannot access gid for group' group
      exit 1
      end
   gid.i=u.gr_gid
end
gid.0=i-1

address syscall 'geteuid'
if retval=0 then
   useropt=''
 else
   useropt='-user' userid()
count=0
do px=1 to path.0
   path=path.px
   if verbose then call say 'processing' path

   out.0=0
   st.=''
   address syscall 'stat (path) st.'
   if retval=-1 then
      do
      call say 'cannot access' path
      iterate
      end
   if st.st_type=s_isdir then
      do
      call bpxwunix 'cd' path'; find . -xdev -type d' useropt,,out.,err.
      if err.0>0 then call say err.1
      end
   if verbose then call say out.0 'directories in' path
   dirs=out.0
   if opt_d & uid.0=0 & gid.0=0 then
      do j=1 to out.0
         p=path'/'out.j
         if verbose then call say p
         address syscall 'acldelete (p)' acl_type_access
         address syscall 'acldelete (p)' acl_type_filedefault
         address syscall 'acldelete (p)' acl_type_dirdefault
         count=count+3
      end
   else
   if opt_c then
      call copyacl
    else
      do
      do j=1 to uid.0
         call setdir acl_entry_user,uid.j
      end
      do j=1 to gid.0
         call setdir acl_entry_group,gid.j
      end
      end

   if st.st_type=s_isdir then
      do
      call bpxwunix 'cd' path'; find . -xdev -type f' useropt,,out.
      if err.0>0 then call say err.1
      end
    else
      do
      out.0=1
      out.1=''
      end
   if verbose then call say out.0 'files in' path
   files=out.0
   if opt_d & uid.0=0 & gid.0=0 then
      do j=1 to out.0
         if length(out.j)=0 then
            p=path
          else
            p=path'/'out.j
         if verbose then call say p
         address syscall 'acldelete (p)' acl_type_access
         count=count+1
      end
   else
   if opt_c then
      call copyacl
    else
      do
      do j=1 to uid.0
         call setfile acl_entry_user,uid.j
      end
      do j=1 to gid.0
         call setfile acl_entry_group,gid.j
      end
      end
end
if opt_d then
   call say count 'ACLs deleted on' dirs+files 'objects'
 else
   call say count 'ACLs set on' dirs+files 'objects'
exit 0

/**********************************************************************/
/* output msg, immediate if running sysrexx */
say:
   parse source . . . . . . . rxenv .
   if rxenv='AXR' then
      call axrwto arg(1)
    else
      say arg(1)
   return

/**********************************************************************/
optflag:
   parse arg opt,str
   optstr=''
   if pos(opt,opts)=0 then
      return 0
   parse var opts start (opt) rest
   rest=strip(rest)
   if str=1 & substr(rest,1,1)<>'-' then
      parse var rest optstr rest
   opts=start rest
   return strip(1 optstr)


/**********************************************************************/
setdir:
do i=1 to out.0
   p=path'/'out.i
   if verbose then call say p
   address syscall 'aclinit acl'
   address syscall 'aclget acl (p)' acl_type_access
   acl.acl_entry_type=arg(1)
   acl.acl_id=arg(2)
   acl.acl_delete=0
   if opt_d then
      address syscall 'acldeleteentry acl acl.'
    else
      do
      acl.acl_read=pos('R',perm)>0
      acl.acl_write=pos('W',perm)>0
      acl.acl_execute=pos('X',perm)>0
      address syscall 'aclupdateentry acl acl.'
      end
   address syscall 'aclset acl (p)' acl_type_access
   count=count+1
   address syscall 'aclset acl (p)' acl_type_dirdefault
   count=count+1
   if opt_d=0 then
      do
      acl.acl_read=pos('R',fperm)>0
      acl.acl_write=pos('W',fperm)>0
      acl.acl_execute=pos('X',fperm)>0
      address syscall 'aclupdateentry acl acl.'
      end
   address syscall 'aclset acl (p)' acl_type_filedefault
   address syscall 'aclfree acl'
   count=count+1
end
return

/**********************************************************************/
setfile:
do i=1 to out.0
   if length(out.i)=0 then
      p=path
    else
      p=path'/'out.i
   if verbose then call say p
   address syscall 'aclinit acl'
   address syscall 'aclget acl (p)' acl_type_access
   if opt_d then
      address syscall 'acldeleteentry acl acl.'
    else
      do
      acl.acl_entry_type=arg(1)
      acl.acl_id=arg(2)
      acl.acl_read=pos('R',fperm)>0
      acl.acl_write=pos('W',fperm)>0
      acl.acl_execute=pos('X',fperm)>0
      acl.acl_delete=0
      address syscall 'aclupdateentry acl acl.'
      end
   address syscall 'aclset acl (p)' acl_type_access
   address syscall 'aclfree acl'
   count=count+1
end
return

/**********************************************************************/
copyacl:
   address syscall 'stat (sourcepath) st.'
   if retval=-1 then
      do
      call say 'cannot access' sourcepath
      exit 1
      end
   address syscall 'aclinit acldd'
   address syscall 'aclinit aclfd'
   address syscall 'aclinit aclac'
   if st.st_type=s_isdir then
      do
      address syscall 'aclget acldd (sourcepath)' acl_type_dirdefault
      address syscall 'aclget aclfd (sourcepath)' acl_type_filedefault
      end
    else
      address syscall 'aclget aclfd (sourcepath)' acl_type_access
   address syscall 'aclget aclac (sourcepath)' acl_type_access
   do i=1 to out.0
      if length(out.i)=0 then
         p=path
       else
         p=path'/'out.i
      if verbose then call say p
      pst.=''
      address syscall 'stat (p) pst.'
      if retval=-1 then
         do
         call say 'cannot access' path
         iterate
         end
      if st.st_type=s_isdir & pst.st_type=s_isdir then
         do
         address syscall 'aclset acldd (p)' acl_type_dirdefault
         count=count+1
         address syscall 'aclset aclfd (p)' acl_type_filedefault
         count=count+1
         end
      address syscall 'aclset aclac (p)' acl_type_access
      count=count+1
   end
   address syscall 'aclfree acldd'
   address syscall 'aclfree aclfd'
   address syscall 'aclfree aclac'
   return

/**********************************************************************/
listacls:
   address syscall
   do p=1 to path.0
      path=path.p
      'stat (path) st.'
      if retval=-1 then
         do
         call say 'cannot access' path
         iterate
         end
      call say path
      didlist=0
      call listacl acl_type_access,'   Access:'
      call listacl acl_type_filedefault,'   File default:'
      call listacl acl_type_dirdefault,'   Directory default:'
      if didlist=0 then
         call say '   no ACLs'
   end
   return

/**********************************************************************/
listacl:
   'aclinit acl'
   'aclget acl (path)' arg(1)
   needhdr=1
   do i=1 by 1
      'aclgetentry acl acl.' i
      if rc<0 | retval=-1 then leave
      parse value '- - -' with pr pw px
      if acl.acl_read=1 then pr=R
      if acl.acl_write=1 then pw=W
      if acl.acl_execute=1 then px=X
      aclid=acl.acl_id
      if acl.acl_entry_type=acl_entry_user then
         do
         type='user='
         u.=''
         'getpwuid (aclid) u.'
         if u.pw_name<>'' then
            aclid=u.pw_name
         end
      else
      if acl.acl_entry_type=acl_entry_group then
         do
         type='group='
         g.=''
         'getgrgid (aclid) g.'
         if g.gr_name<>'' then
            aclid=g.gr_name
         end
       else 'type=???='
      if needhdr then call say arg(2)
      needhdr=0
      didlist=1
      call say '     ' pr || pw || px type || aclid
   end
   'aclfree acl'
   return

/**********************************************************************/
help:
   call say 'Syntax:'
   call say '   Add ACLs for users and/or groups on directories and',
               'everything in them'
   call say '      wjsacl -p [rwx] [-f [rwx]] [-u userlist] [-g grouplist]',
                       '[-v] pathname...'
   call say ' '
   call say '   Delete all ACLs or ACLS for users and/or groups on directories',
               'and everything in them'
   call say '      wjsacl -d [-u userlist] [-g grouplist] [-v] pathname...'
   call say ' '
   call say '   Copy the ACLs from a file or directory to directories',
               'and everything in them'
   call say '      wjsacl -c sourcepath [-v] pathname...'
   call say ' '
   call say '   Display the ACLs for files and directories'
   call say '      wjsacl -q pathname...'
   call say ' '
   call say '  userlist and grouplist are one or more userids or group names'
   call say '  separated by commas'
   call say ' '
   call say '  pathname... is one or more pathnames separated by spaces'
   call say ' '
   call say '  rwx is for read, write, and execute permissions.  If any or all'
   call say '  are not specified, those permissions are not granted'
   call say ' '
   call say '  you must be superuser or own the files for the ACL to be added',
            'or deleted'
   call say ' '
   call say 'Examples:'
   call say '  Give frodo and bilbo and group hobbit rwx access to directory'
   call say '  /mide/shire and its subdirectories and rw access to the files'
   call say '     wjsacl -p rwx -f rw -u frodo,bilbo -g hobbit /mide/shire  '
   call say '                                                               '
   call say '  Add gandalf to those access lists with read access'
   call say '     wjsacl -p rx -f r -u gandalf /mide/shire    '
   call say '                                                               '
   call say '  Add an ACL for saruman denying all access'
   call say '     wjsacl -p -u saruman /mide/shire    '
   call say '                                                               '
   call say '  Remove gandalf'
   call say '     wjsacl -d -u gandalf /mide/shire    '
   call say '                                                               '
   call say '  Copy the access lists to /mide/mtdoom and all it subdirectories'
   call say '  and files'
   call say '     wjsacl -c /mide/shire /mide/mtdoom                        '
   call say '                                                               '
   call say '  Remove all access lists from /mide/mtdoom                   '
   call say '     wjsacl -d /mide/mtdoom                                    '
   call say '                                                               '
   call say '  Show the access lists for /mide/shire                    '
   call say '     wjsacl -q /mide/shire                                     '
   call say '                                                               '
   exit

