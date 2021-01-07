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
** List audit ids for a path or find the file that has a specific id **
**                                                                   **
** Bill Schoen (wjs@us.ibm.com)                         4/15/98      **
**    10/9/07   fix for HFS root inode number (Robert Hering)        **
**                                                                   **
***********************************************************************/

parse arg id .
if id='' then signal help
address syscall
'stat (id) st.'
if rc=0 & retval<>-1 then
   call showpath
 else
   call findfid
return
showpath:
   'realpath (id) path'
   if rc<>0 | retval=-1 then
     do
     say 'Unable to resolve path for' id
     return
     end
   say path
   pp=''
   do while path<>''
      parse var path p '/' path
      pp=pp || '/' || p
      'stat (pp) st.'
      say c2x(st.st_auditid) pp
      if pp='/' then pp=''
   end
   return
findfid:
   if length(id)<>32 then
      signal help
   'getmntent mnt.'
   do i=1 to mnt.0
      'stat (mnt.mnte_path.i) st.'
      if substr(id,1,20)=substr(c2x(st.st_auditid),1,20) then
         leave
   end
   if i>mnt.0 then
      do
      say 'Audit id' id 'not found'
      return
      end
   path=mnt.mnte_path.i
   numeric digits 12
   ino=x2d(substr(id,21,8))
   if ino=0 & mnt.mnte_fstype.i="HFS" then /* fix HFS root dir inode */
      ino = 3                              /* fix HFS root dir inode */
   'pipe p.'
   cmd='find "'path'" -xdev -inum' ino '>/dev/fd'p.2 '2>/dev/null'
   address sh cmd
   'close' p.2
   address mvs 'execio * diskr' p.1 '(stem s.'
   st.=''
   if s.0<>0 then
      'stat (s.1) st.'
   if id=c2x(st.st_auditid) then
      say s.1
    else
      say 'Audit id' id 'not found'
   return

help:
   say 'Syntax:  auditid <pathname>'
   say '     or  auditid <32 character audit id (FID)>'
   exit

