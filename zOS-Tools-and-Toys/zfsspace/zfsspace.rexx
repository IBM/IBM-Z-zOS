/* REXX */
/**********************************************************************/
/* Show number of small files in a zFS file system                    */
/*                                                                    */
/* Purpose:  Scan for small files in a zFS file system to help        */
/*           determine if an existing file system may need more space */
/*                                                                    */
/*          Use zfsspace to scan zFS file systems for small files     */
/*          to help determine if an existing file system might need   */
/*          more DASD storage when migrating to z/OS 1.3.             */
/*          A file system with a large number of small files and high */
/*          space utilization may require more space.                 */
/*                                                                    */
/* Syntax:                                                            */
/*    zfsspace <pathname>                                             */
/* Example:                                                           */
/*    zfsspace /tmp/                                                  */
/* Install:                                                           */
/*    Place this program in a place where you can run rexx execs.     */
/*    This will run under the shell, TSO, and SYSREXX                 */
/*                                                                    */
/* PROPERTY OF IBM                                                    */
/* COPYRIGHT IBM CORP. 2011                                           */
/*                                                                    */
/* Bill Schoen (wjs@us.ibm.com)                                       */
/**********************************************************************/
sz=3
parse arg path .
call syscalls 'ON'
numeric digits 10
z1='00'x
z4='00000000'x
pl=32
address syscall 'stat (path) st.'
if rc<>0 | retval=-1 then
   do
   say 'error resolving' path ':' rc errno errnojr
   return 1
   end

mnt.=''
devno=x2d(st.st_dev)
address syscall 'getmntent mnt.' devno
zfs=strip(mnt.mnte_fsname.1)
if zfs='' then
   do
   say 'cannot locate filesystem with devno' devno
   return 1
   end
if mnt.mnte_path.1<>'' then
   path=mnt.mnte_path.1

call outtrap info.
address tso "LISTCAT ENTRIES('"zfs"') allocation"
do i=1 to info.0
   parse var info.i 'SPACE-SEC' sec .
   if sec<>'' then leave
end
sec=strip(sec,'b','-')

call zfsgetaggr
do i=1 to agid.0
   parse var agid.i +6 agnm '00'x
   if agnm=zfs then leave
end
if agnm<>zfs then
   do
   say 'cannot locate aggregate' zfs
   return 1
   end
call zfsgetstat i
if agst.i.5=z1 then
   grow='no'
 else
   grow='yes'
if sec<>'' & sec<>0 then
   ext='yes'
 else
   ext='no'

xx=bpxwunix('find' path '-size -'sz '-type f -xdev | wc -l',,out.,err.)
count=strip(out.1)

say zfs
say '  small files:' count
say '  extents....:' ext
say '  aggrgrow...:' grow
say
 
do i=1 to err.0
   say err.i
end
return 0

pfsctl:
   pctcmd=x2d('40000005')
   address syscall 'pfsctl ZFS' pctcmd 'pctbf' length(pctbf)
   return

zfsgetstat:
procedure expose opts z1 z4 pl agid. agst.
   arg k
   agidsz=length(agid.k)
   agst.k=''
   agst='AGST' || '00000100'x || copies(z1,164)
   agst=overlay(d2c(length(agst),2),agst,5)
   pctbf=d2c(137,4) ||,                     /* stats op      */
         d2c(pl,4)  ||,                     /* p0: ofs agrid */
         d2c(pl+agidsz,4) ||,               /* p1: ofs buff  */
         z4         ||,                     /* p2:           */
         z4||z4||z4||z4||,                  /* p3-p6     */
         agid.k || agst
   call pfsctl 1
   if substr(pctbf,pl+agidsz+1,4)<>'AGST' then return
   agst.k=substr(pctbf,agidsz+pl+1)
   flag=substr(agst.k,19,1)
   agst.k.5=bitand(flag,'08'x)         /* dynamic grow           */
   return

zfsgetaggr:
procedure expose opts z1 z4 pl agid. agst. e2big

/* query buffer size */
pctbf=d2c(135,4) ||,                     /* list op       */
      z4                     ||,         /* p0: bufsz     */
      z4          ||,                    /* p1: buf offs  */
      d2c(pl,4)                ||,       /* p2: sz offs   */
      z4||z4||z4||z4||,                  /* p3-p6     */
      z4                                 /* returned size */
call pfsctl
if retval=-1 & errno<>e2big then
   do
   say 'list aggregate query failed' errno errnojr
   exit 1
   end
aglistsz=c2d(substr(pctbf,pl+1,4))
if aglistsz=0 then
   do
   aglistsz=3800    /* for old rx support */
   end

/* get aggr list */
aglist=copies(z1,aglistsz)
pctbf=d2c(135,4) ||,                     /* list op       */
      d2c(aglistsz,4)  ||,               /* p0: bufsz     */
      d2c(pl,4)   ||,                    /* p1: buf offs  */
      d2c(pl+aglistsz,4) ||,             /* p2: sz offs   */
      z4||z4||z4||z4||,                  /* p3-p6     */
      aglist || z4
call pfsctl
if retval=-1 then
   do
   say 'list aggregates failed' errno errnojr
   exit 1
   end
j=0
do i=pl+1 by 0
   if substr(pctbf,i,4)<>'AGID' then leave
   agidsz=c2d(substr(pctbf,i+4,1))
   agid=substr(pctbf,i,agidsz)
   j=j+1
   agid.j=agid
   i=i+agidsz
   nop
end
agid.0=j
return
