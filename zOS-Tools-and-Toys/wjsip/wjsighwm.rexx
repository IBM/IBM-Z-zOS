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
/* WJSIGHWM:  show vnode high water mark for file systems             */
/*                                                                    */
/*    This tool will run under IPCS or on a live system.              */
/*    You must be a superuser to run on a live system or be           */
/*    permitted to SUPERUSER.FILESYS.PFSCTL in the UNIXPRIV class.    */
/*                                                                    */
/*   Syntax:                                                          */
/*    wjsighwm [-t <fstype>] [-c <count>]                             */
/*                                                                    */
/*      -t   use to filter by file system type (eg, hfs, zfs)         */
/*           by default all file system types are shown               */
/*      -c   use to filter by high water mark count                   */
/*           by default hwm must be > 1000                            */
/*                                                                    */
/* Bill Schoen    wjs@us.ibm.com   9/04/14                            */
/*  Change activity:                                                  */
/*                                                                    */
/**********************************************************************/
parse arg stack
if stack='STACK' then
   do
   do i=1 to sourceline()
      queue sourceline(i)
   end
   return
   end

arg '-C' hwmlow .
arg '-T' fstype .
if datatype(hwmlow,'W')=0 then
   hwmlow=1000
out=0
gfs@=getstor('1008',4,kasid,fds)
do while gfs@<>0
   ln=gfs@
   gfsname=x2c(getstor(xadd(gfs@,'18'),8,kasid,fds))
   vfs@=getstor(xadd(gfs@,'0c'),4,kasid,fds)
   gfs@=getstor(xadd(gfs@,'08'),4,kasid,fds)
   if fstype<>'' & gfsname<>fstype then iterate
   do while vfs@<>0
      vfsname=x2c(getstor(xadd(vfs@,'38'),44,kasid,fds))
      hwm=x2d(getstor(xadd(vfs@,'13c'),4,kasid,fds))
      flags=x2c(getstor(xadd(vfs@,'34'),4,kasid,fds))
      call setflags
      vfs@=getstor(xadd(vfs@,'08'),4,kasid,fds)
      if vfsavail=0 & vfsdead=0 & vfsperm=0 then
         if hwm>hwmlow then
            do
            out=out+1
            out.out=right(hwm,12) gfsname left(sfmsg,12) vfsname
            end
   end
end
out.0=out
call sortstem 'out.'
if out=0 then
   call say 'no high use file systems found'
 else
   do i=out to 1 by -1
      call say out.i
   end
return

setflags:
   sfmsg=''
   ro=bitand('80000000'x,flags)=='80000000'x
   rw=bitand('40000000'x,flags)=='40000000'x
   unmnt=bitand('10000000'x,flags)=='10000000'x
   vfsavail=bitand('00800000'x,flags)=='00800000'x
   vfsdead=bitand('00400000'x,flags)=='00400000'x
   quiesced=bitand('00040000'x,flags)=='00040000'x
   vfsperm=bitand('00004000'x,flags)=='00004000'x
   client=bitand('00000002'x,flags)=='00000002'x
   if ro then sfmsg='R/O'
   if rw then sfmsg='R/W'
   if client then sfmsg=sfmsg 'Client'
     else         sfmsg=sfmsg 'Local '
   if unmnt then sfmsg=sfmsg 'Unmount'
   if quiesced then sfmsg=sfmsg 'Quiesced'
   return sfmsg

sortstem:
   arg sst,sscol
   ssm=value(sst||0)
   do ssi=1 to ssm
      do ssj=ssi+1 to ssm
         if sscol<>'' then
          do
          if substr(value(sst||ssi),sscol)>>,
             substr(value(sst||ssj),sscol) then
            do
            ssx=value(sst||ssi,value(sst||ssj))
            ssx=value(sst||ssj,ssx)
            end
          end
         else
         if value(sst||ssi)>>value(sst||ssj) then
            do
            ssx=value(sst||ssi,value(sst||ssj))
            ssx=value(sst||ssj,ssx)
            end
      end
   end
   return

