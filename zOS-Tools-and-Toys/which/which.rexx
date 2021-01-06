/** REXX **************************************************************
**                                                                   **
** Copyright 2018-2020 IBM Corp.                                     **
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


/*
 Author: Andrew Mattingly: <andrew_mattingly@au1.ibm.com>

 This exec implements the UNIX "which" functionality for z/OS as a
 System REXX procedure.  If you add it to the SYS1.SAXREXEC on your system,
 you can invoke it thus:

 F AXR,WHICH procname [procnn]

 Or, assuming "@" is defined as the CPF in AXR00 in SYS1.PARMLIB

 @WHICH procname [procnn]

 For example, on my system:

 @WHICH TYRONE
 TYRONE not found in PROCLIB concatenation PROC00
 @WHICH TYRONE PROC01
 TYRONE not found in PROCLIB concatenation PROC01
 @WHICH LISTMEM PROC01
 ADCDMST.EXEC(LISTMEM)
 @WHICH HLASMC
 HLA.SASMSAM1(HLASMC)

*/

parse upper arg lookfor procnn .
if procnn = "" then procnn = "PROC00"
cmd = "$D PROCLIB("procnn"),DD=(DSNAME)"
x = AXRCMD(cmd,var.,5)
found = 0
i = 1
do while (found = 0) & (i <= var.0)
  parse var var.i . "DSNAME="proclib")" .
  if proclib <> "" then do
    if ISMEMBER(proclib,lookfor) then do
      x = AXRWTO(proclib"("lookfor")")
      found = 1
    end
  end
  i = i + 1
end
myrc = 0
if found = 0 then do
  x = AXRWTO(lookfor" not found in PROCLIB concatenation "procnn)
  myrc = 8
end
exit myrc

ISMEMBER: PROCEDURE
arg proc,mem
x = outtrap("var.")
ADDRESS TSO "LISTDS '"proc"' MEMBERS"
x = outtrap("off")
foundmlist = 0
foundmem = 0
i = 1
do while (i <= var.0) & (foundmem = 0)
  if var.i = "--MEMBERS--" then do
    foundmlist = 1
  end
  else do
    if var.i = "THE FOLLOWING ALIAS NAMES EXIST WITHOUT TRUE NAMES" then do
      say "*** there are DUDS in the list"
      foundmlist = 0
    end
    else if foundmlist = 1 then do
      parse var var.i memname . "ALIAS("alias")" .
      if memname = mem then foundmem = 1
      if alias <> "" then do
        rest = alias
        do while rest <> ""
          parse var rest memname","rest
          if memname = mem then foundmem = 1
        end
      end
    end
  end
  i = i + 1
end
return foundmem
