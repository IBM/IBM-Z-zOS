/* REXX */
/**********************************************************************/
/* Show file system mounts                                            */
/*                                                                    */
/* PROPERTY OF IBM                                                    */
/* COPYRIGHT IBM CORP. 1997                                           */
/*                                                                    */
/* Bill Schoen (SCHOEN at KGNVMC, schoen@vnet.ibm.com)  10/27/97      */
/**********************************************************************/
parse source . how . . . . . omvs .
if omvs<>"OMVS" then
   call syscalls 'ON'
lines=0
do i=1 to __environment.0
   if substr(__environment.i,1,6)='LINES=' then
      parse var __environment.i '=' lines
end
if lines<10 then lines=999999
items=lines % 4
address syscall
'getmntent m.'
root=-1
mp.=0
mnts.=0
modes.=''
modes.mnt_mode_rdwr='R/W'
modes.mnt_mode_rdonly='READ-ONLY'
 
say 'Total file systems:' m.0
do i=1 to m.0
  if m.mnte_path.i='/' then
     do
     root=m.mnte_dev.i
     mp.i=root
     end
   else
     do
     p=substr(m.mnte_path.i,1,lastpos('/',strip(m.mnte_path.i,'T','/')))
     st.=0
     'stat (p) st.'
     mp.i=x2d(st.st_dev)
     if mp.i=0 then
        do
        say 'Cannot access' m.mnte_fsname.i
        end
     end
  j=m.mnte_dev.i
  mnts.j.1=i
end
if root<0 then
   do
   say 'Unable to access root file system information'
   exit 1
   end
do i=1 to m.0
   d=mp.i
   mnts.d=mnts.d+1
end
'sleep 3'
nxt=show(root)
do forever
   if nxt='' then
      do
      say 'Enter device number to view file system mounts',
          'and information, Q to Quit'
      pull dev .
      end
    else
      dev=nxt
   if substr(dev,1,1)='Q' then leave
   if datatype(dev,'W') then
      nxt=show(dev)
end
return 0

show:
   parse arg dev .
   do i=1 to m.0
      if m.mnte_dev.i=dev then leave
   end
   if i>m.0 then
      do
      say 'Device number' dev 'not found'
      return ''
      end
   fs=m.mnte_fsname.i
   f.='Not available'
   'statfs (fs) f.'
   say esc_f
   say 'File system:' strip(m.mnte_fsname.i)
   say 'Mount point:' m.mnte_path.i
   j=mp.i
   j=mnts.j.1
   if m.mnte_path.i<>'/' then
      say 'Mounted on: ' m.mnte_fsname.j
   say 'Dev number: ' m.mnte_dev.i,
       ' Free:' f.stfs_avail,
       ' In-use:' f.stfs_inuse,
       ' Mode:' value('modes.'m.mnte_mode.i)
   do j=1 to m.0
      if mp.i=m.mnte_dev.j then leave
   end
   qx=0
   do j=1 to m.0
      d=m.mnte_dev.j
      if mp.j=m.mnte_dev.i & m.mnte_dev.j<>m.mnte_dev.i then
         call q esc_n ||,
                ' Name:' m.mnte_fsname.j esc_n ||,
                ' Path:' m.mnte_path.j   esc_n ||,
                ' Dev: ' m.mnte_dev.j ' Mountpoints:' mnts.d
   end
   if qx=0 then
      say 'File system contains no mount points'
     else
      do
      say 'File system contains' qx 'mount points:'
      k=2
      do j=1 to qx
         k=k+1
         do while length(ql.j)>0
            parse var ql.j l '15'x ql.j
            say l
         end
         if k>items then
            do
            k=1
            say
            say 'Press Enter for more or enter device number or Q'
            pull stop .
            if stop<>'' then return stop
            say esc_f
            end
      end
      end
   return ''
q:
   qx=qx+1
   ql.qx=arg(1)
   return
