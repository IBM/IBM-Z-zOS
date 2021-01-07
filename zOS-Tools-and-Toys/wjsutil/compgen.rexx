/** REXX **************************************************************
**                                                                   **
** Copyright 2015-2020 IBM Corp.                                     **
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

/*********************************************************************/
/* edit macro:  compgen <n>                                          */
/* Description: compare the current member you are editing with a    */
/*              prior generation (version) of that member            */
/*              using ISPF EDIT and PDSE V2 with generations         */
/* Args:                                                             */
/*       n is the relative generation number (default 1)             */
/* ex:  compgen     compare session with the prior generation        */
/*      compgen 3   compare session with 3rd oldest generation       */
/*                                                                   */
/* Bill Schoen  4/17/2015   wjs@us.ibm.com                           */
/*********************************************************************/
address ispexec 'control errors return'
ADDRESS ISREDIT 'MACRO (PARM) NOPROCESS'
if rc<>0 then call out 'must be run as an edit macro'
parse var parm gen internal .
if gen='' then gen=1
address isredit '(mem) = member'
address isredit '(dsn) = dataset'
address ispexec "dsinfo dataset('"dsn"')"
cdsn="'"sysvar('syspref')".wjscg.tempdsn'"
if gen=0 then call out 'no generations defined for the data set'

if internal='/load' then      /* re-entered as a macro from view */
   do
   /* create a temp data set for the compare */
   call outtrap 'ON'
   address tso 'del' cdsn
   call outtrap 'OFF'
   recfm=''
   do i=1 by 1 while substr(zdsrf,i,1)<>''
      recfm=recfm','substr(zdsrf,i,1)
   end
   dyn=bpxwdyn("alloc rtddn(ddn) new da("cdsn") catalog msg(wtp)",
               "recfm("substr(recfm,2)") lrecl("strip(zdslrec)")",
               "blksize("strip(zdsblk)") space(1,2) cyl")
   if dyn<>0 then return
   call bpxwdyn 'free dd('ddn')'
   address isredit 'replace' cdsn '.zfirst .zlast'
   address isredit 'can'      /* end the view session */
   return
   end

if gen='' | datatype(gen,'W')=0 then
   call out 'compgen <n>'

/* invoke view for this member and specified generation          */
/* reentry of the macro will copy the view session to a data set */
dsn="'"dsn"("strip(mem)")'"
macprm=gen '/load'
parse source . . me .
address ispexec 'view dataset('dsn') gen(-'gen') macro('me') parm(macprm)'
if rc>4 then  /* if error then generation does not exist */
   call out 'generation' gen 'not found.  Maxgens is' strip(zdsngen)
/* got the data set, now compare then delete the data set */
address isredit 'compare' cdsn 'x'
CALL OUTTRAP 'ON'
address tso 'del' cdsn
call outtrap 'OFF'
return

out:
   zedlmsg=arg(1)
   address ispexec "SETMSG MSG(ISRZ000)"
   exit
