/** REXX **************************************************************
**                                                                   **
** Copyright 2014-2020 IBM Corp.                                     **
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
**                                                                   **
**********************************************************************/

/**********************************************************************/
/* WJSDVINO:  find a pathname given device and inode numbers          */
/*                                                                    */
/*   Syntax:  wjsdvino <devno> <ino>                                  */
/*                                                                    */
/*   Usage:  Place this where you can run a rexx program              */
/*           This can run from the shell, TSO, or sysrexx             */
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

