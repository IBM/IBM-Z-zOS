/** REXX **************************************************************
**                                                                   **
** Copyright 1998-2020 IBM Corp.                                     **
**                                                                   **
**  Licensed under the Apache License, Version 2.0 (the "License");  **
**  you may not use this file except in compliance with the License. **
**  You may obtain a copy of the License at                          **
**                                                                   **
**     http://www.apache.org/licenses/LICENSE-2.0                    **
**                                                                   **
**  Unless required by applicable law or agreed to in writing,       **
**  software distributed under the License is distributed on an      **
**  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,     **
**  either express or implied. See the License for the specific      **
**  language governing permissions and limitations under the         **
**  License.                                                         **
**                                                                   **
** ----------------------------------------------------------------- **
**                                                                   **
** Disclaimer of Warranties:                                         **
**                                                                   **
**   The following enclosed code is sample code created by IBM       **
**   Corporation.  This sample code is not part of any standard      **
**   IBM product and is provided to you solely for the purpose       **
**   of assisting you in the development of your applications.       **
**   The code is provided "AS IS", without warranty of any kind.     **
**   IBM shall not be liable for any damages arising out of your     **
**   use of the sample code, even if they have been advised of       **
**   the possibility of such damages.                                **
**                                                                   **
** ----------------------------------------------------------------- **
** Author: Bill Schoen <wjs@us.ibm.com>
**
** Title: cksparse:  sparse file scanner
**        This scans a file system starting at a specified directory
**        for any files that are sparse in terms of having full pages
**        within the file not backed.
**
** Syntax: cksparse <pathname>
**    <pathname> can be a directory or a regular file
**    This should be run from a superuser to ensure nothing is missed.
**
** Install:  Place this where REXX execs can be found.  It can be in
**           a PDS and run from TSO or in the HFS.
**
** Last revision: 10/15/98
***********************************************************************/
call syscalls on
numeric digits 12
devs.=''

parse arg path .
apath=path
rpath='00'x
path=path'/.'
address syscall 'realpath (path) rpath'
address syscall 'lstat (rpath)' st.
if st.st_type<>s_isdir then
   do
   address syscall 'lstat (apath)' st.
   dpath=apath
   if st.st_type=s_isreg then
      call processname
    else
      say apath': Not a regular file or directory'
   return
   end
devs.0=st.st_dev
address syscall 'getmntent mnt. ' x2d(devs.0)
say 'Scanning for sparse files in file system:' strip(mnt.mnte_fsname.1)
if rpath<>mnt.mnte_path.1 then
   say 'Starting at directory:' rpath
devs.0.2=0             /* total sparse */
devs.0.3=0             /* total files  */
call rdir rpath

say 'Total files scanned:' devs.0.3
say 'Total sparse files :' devs.0.2

return

rdir: procedure expose types calltp fds pfs pctcmd devs.
   call syscalls on
   parse arg path
   d.0=0
   address syscall 'readdir (path) d.'
   do i=1 to d.0
      dpath=path'/'d.i
      address syscall 'lstat (dpath)' st.
      if st.st_dev<>devs.0 & d.i<>'..' then
         iterate                               /* stop at mountpoints */
      if st.st_type=s_isdir & d.i<>'.' & d.i<>'..' then
         call rdir dpath
      if d.i<>'.' & d.i<>'..' then
         call processname dpath
   end
   return

processname:
   if st.st_type<>s_isreg  then return
   dev=x2d(st.st_dev)
   if devs.dev='' then
      do
      devs.0.1=devs.0.1 dev  /* dev list */
      devs.0.2=0             /* total sparse */
      devs.0.3=0             /* total files  */
      devs.dev=1
      devs.dev.1=0
      devs.dev.2=0
      end
   devs.dev.1=devs.dev.1+1  /* total files in fs */
   devs.0.3=devs.0.3+1      /* total files  */
   hwm=st.st_blocks*st.st_blksize
   if hwm>=st.st_size then
      return

   if devs.0.2=0 then
      say 'The following files are sparse:'
   say dpath
   devs.0.2=devs.0.2+1
   devs.dev.2=devs.dev.1+1
   return

