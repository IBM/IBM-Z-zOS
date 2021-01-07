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
** List colony address spaces                                        **
**                                                                   **
** Bill Schoen <wjs@us.bm.com> 4/9/98                                **
***********************************************************************/
numeric digits 12
pctcmd=-2147483647
pfs='KERNEL'
parse source . how . . . . . omvs .
if omvs<>"OMVS" then
   call syscalls 'ON'
address syscall
catd=-1

z4='00000000'x
cvtecvt=140
ecvtocvt=240
ocvtocve=8
ocvtfds='58'
ofsb='1000'
ofsbgfs='08'
ofsbcab='fc'
ofsblen='200'
cabname='08'
cabnext='14'

cvt=c2x(storage(10,4))
ecvt=c2x(storage(d2x(x2d(cvt)+cvtecvt),4))
ocvt=c2x(storage(d2x(x2d(ecvt)+ecvtocvt),4))

fds=storage(d2x(x2d(ocvt)+x2d(ocvtfds)),4)

if fetch(fds,'00001000'x,ofsblen) then
   do
   say 'Kernel is unavailable or at the wrong level',
                  'for this function or you are not a superuser'
   exit 1
   end
cab=ofs(ofsbcab,4)
cnt=0
if cab=z4 then
   say 'No colony address spaces'
 else
   say 'Colony address spaces:'
do while cab<>z4
   if fetch(fds,cab,'20')=0 then
      do
      cnt=cnt+1
      say ofs(cabname,8)
      cab=ofs(cabnext,4)
      end
end
return

/**********************************************************************/
ofs:
   arg ofsx,ln
   return substr(buf,x2d(ofsx)+1,ln)

/**********************************************************************/
fetch:
   parse arg alet,addr,len,eye  /* char: alet,addr  hex: len */
   len=x2c(right(len,8,0))
   dlen=c2d(len)
   buf=alet || addr || len
   'pfsctl' pfs pctcmd 'buf' max(dlen,12)
   if rc<>0 | retval=-1 then
      return 1
   if eye<>'' then
      if substr(buf,1,length(eye))<>eye then
         return 1
   if dlen<12 then
      buf=substr(buf,1,dlen)
   return 0
