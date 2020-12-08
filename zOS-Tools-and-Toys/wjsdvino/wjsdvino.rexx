/* REXX */
/**********************************************************************/
/* WJSDVINO:  find a pathname given device and inode numbers          */
/*                                                                    */
/*   Syntax:  wjsdvino <devno> <ino>                                  */
/*                                                                    */
/*   Usage:  Place this where you can run a rexx program              */
/*           This can run from the shell, TSO, or sysrexx             */
/*                                                                    */
/* PROPERTY OF IBM                                                    */
/* COPYRIGHT IBM CORP. 2014                                           */
/*                                                                    */
/* Bill Schoen    wjs@us.ibm.com    6/13/2014                         */
/*                                                                    */
/**********************************************************************/
parse arg devno ino
numeric digits 12
if datatype(devno,'W')=0 | datatype(ino,'W')=0 then
   do
   call say 'devno and ino required'
   exit 1
   end
call syscalls 'ON'
address syscall 'getmntent mnt.' devno
if retval=-1 | mnt.mnte_path.1='' then
   do
   call say 'file system for devno' devno 'not found'
   exit 2
   end
rv=bpxwunix('find' mnt.mnte_path.1 '-xdev -inum' ino,,out.,err.)
if out.0=0 then
   do
   call say 'file with inode number' ino 'not found in' mnt.mnte_fsname.1
   do i=1 to err.0
      say err.i
   end
   exit 3
   end
do i=1 to out.0
   say out.i
end
return 0

/**********************************************************************/
say:
   parse source . . . . . . . rxenv .
   if rxenv='AXR' then
      call axrwto arg(1)
    else
      say arg(1)
   return

