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
 Copyright IBM Corp. 2018

This is an "IPA crawler" which can find out where an initialization
parameter is set.  Load it into your SYS1.SAXREXEC and give it a whirl.
It takes the name of a IEASYSxx parameter (or the corresponding PARMLIB
member prefix) as a parameter, and reports the value detected at
initialization, where it was set, and where to find the referenced
PARMLIB datasets, if the value is a suffix or list of suffices.  It
also takes some "special parameters" for the "early stuff":
LOAD, IODF, {IEASYS|SYS|SYSPARM},{IEASYM|SYM} and NUCLST.

For example:

@WHERE LOAD
LOAD = AL
SYS1.IPLPARM(LOADAL)
@WHERE IODF
IODF = 99
SYS1.IODF99
@WHERE SYS
SYSPARM = AL
ADCD.Z21S.PARMLIB(IEASYSAL)
@WHERE IEASYM
IEASYM = 00
ADCD.Z21S.PARMLIB(IEASYM00)
@WHERE NUCLST
NUCLST = 00
SYS1.IPLPARM(NUCLST00)
@WHERE OMVS
OMVS = (00,BP,IZ,CI,DB,IM,WA)
Source: IEASYSAL
ADCD.Z21S.PARMLIB(BPXPRM00)
ADCD.Z21S.PARMLIB(BPXPRMBP)
ADCD.Z21S.PARMLIB(BPXPRMIZ)
ADCD.Z21S.PARMLIB(BPXPRMCI)
ADCD.Z21S.PARMLIB(BPXPRMDB)
ADCD.Z21S.PARMLIB(BPXPRMIM)
ADCD.Z21S.PARMLIB(BPXPRMWA)
@WHERE SQA
SQA = (15,128)
Source: IEASYSAL
@WHERE VATLST
VAL = DB
Source: IEASYSAL
ADCD.Z21S.PARMLIB(VATLSTDB)

This REXX is somewhat imperfect - it doesn't cope with all the nuances of
z/OS parameter configuration (but catches most of them).

*/

numeric digits 20

parse upper arg parm .

/* chain of control blocks */
psa         = 0     /* absolute address of PSA              */
psa_cvt     = 16    /* psa->cvt   see: SYS1.MACLIB(IHAPSA)  */
cvt_ecvt    = 140   /* cvt->ecvt  see: SYS1.MACLIB(CVT)     */
ecvt_ipa    = 392   /* ecvt->ipa  see: SYS1.MODGEN(IHAECVT) */

/* Initialization Parameter Area */
ipa_lparm   =   20  /* LOADxx suffix                        */
ipa_lpdsn   =   48  /* LOADxx dataset name                  */
ipa_iodf    =   96  /* IODFxx suffix                        */
ipa_iohlq   =   99  /* IODFxx high-level qualifier          */
ipa_sys     =  160  /* IEASYSxx suffices                    */
ipa_sym     =  288  /* IEASYMxx suffices                    */
ipa_plib    =  416  /* PARMLIBs at IPL                      */
ipa_plnumx  = 2134  /* number of PARMLIBs in concatenation  */
ipa_nuc     = 2144  /* NUCLSTxx suffix                      */
ipa_pde     = 2152  /* start of PDEs                        */

/* parameter descriptor elements */
pde.0 = 99
pde.1.name   = "ALLOC"
pde.1.alt    = ""
pde.2.name   = "IEAAPF"
pde.2.alt    = "APF"
pde.3.name   = "APG"
pde.3.alt    = "?"
pde.4.name   = "BLDL"
pde.4.alt    = "?"
pde.5.name   = "BLDLF"
pde.5.alt    = "?"
pde.6.name   = "CLOCK"
pde.6.alt    = ""
pde.7.name   = "CLPA"
pde.7.alt    = "*"
pde.8.name   = "CMB"
pde.8.alt    = "*"
pde.9.name   = "COMMND"
pde.9.alt    = "CMD"
pde.10.name   = "CONSOL"
pde.10.alt    = "CON"
pde.11.name   = "CONT"
pde.11.alt    = "?"
pde.12.name   = "COUPLE"
pde.12.alt    = ""
pde.13.name   = "CPQE"
pde.13.alt    = "?"
pde.14.name   = "CSA"
pde.14.alt    = "*"
pde.15.name   = "CSCBLOC"
pde.15.alt    = "*"
pde.16.name   = "CVIO"
pde.16.alt    = "*"
pde.17.name   = "DEVSUP"
pde.17.alt    = ""
pde.18.name   = "DIAG"
pde.18.alt    = ""
pde.19.name   = "DUMP"
pde.19.alt    = "*"
pde.20.name   = "DUPLEX"
pde.20.alt    = "?"
pde.21.name   = "EXIT"
pde.21.alt    = ""
pde.22.name   = "IEAFIX"
pde.22.alt    = "FIX"
pde.23.name   = "GRS"
pde.23.alt    = "*"
pde.24.name   = "GRSCNF"
pde.24.alt    = ""
pde.25.name   = "GRSRNL"
pde.25.alt    = ""
pde.26.name   = "ICS"
pde.26.alt    = "?"
pde.27.name   = "IECIOS"
pde.27.alt    = "IOS"
pde.28.name   = "IPS"
pde.28.alt    = "?"
pde.29.name   = "LNKLST"
pde.29.alt    = "LNK"
pde.30.name   = "LNKAUTH"
pde.30.alt    = "*"
pde.31.name   = "LOGCLS"
pde.31.alt    = "*"
pde.32.name   = "LOGLMT"
pde.32.alt    = "*"
pde.33.name   = "LOGREC"
pde.33.alt    = "*"
pde.34.name   = "LPALST"
pde.34.alt    = "LPA"
pde.35.name   = "MAXCAD"
pde.35.alt    = "*"
pde.36.name   = "MAXUSER"
pde.36.alt    = "*"
pde.37.name   = "IEALPA"
pde.37.alt    = "MLPA"
pde.38.name   = "MSTJCL"
pde.38.alt    = "MSTRJCL"
pde.39.name   = "NONVIO"
pde.39.alt    = "*"
pde.40.name   = "NSYSLX"
pde.40.alt    = "*"
pde.41.name   = "NUCMAP"
pde.41.alt    = "?"
pde.42.name   = "BPXPRM"
pde.42.alt    = "OMVS"
pde.43.name   = "OPI"
pde.43.alt    = "*"
pde.44.name   = "IEAOPT"
pde.44.alt    = "OPT"
pde.45.name   = "PAGEO"
pde.45.alt    = "?"
pde.46.name   = "PAGE"
pde.46.alt    = "*"
pde.47.name   = "PAGNUM"
pde.47.alt    = "?"
pde.48.name   = "PAGTOTL"
pde.48.alt    = "*"
pde.49.name   = "IEAPAK"
pde.49.alt    = "PAK"
pde.50.name   = "PLEXCFG"
pde.50.alt    = "*"
pde.51.name   = "IFAPRD"
pde.51.alt    = "PROD"
pde.52.name   = "PROG"
pde.52.alt    = ""
pde.53.name   = "PURGE"
pde.53.alt    = "?"
pde.54.name   = "RDE"
pde.54.alt    = "*"
pde.55.name   = "REAL"
pde.55.alt    = "*"
pde.56.name   = "RER"
pde.56.alt    = "*"
pde.57.name   = "RSU"
pde.57.alt    = "*"
pde.58.name   = "RSVNONR"
pde.58.alt    = "*"
pde.59.name   = "RSVSTRT"
pde.59.alt    = "*"
pde.60.name   = "SCHED"
pde.60.alt    = "SCH"
pde.61.name   = "SMFPRM"
pde.61.alt    = "SMF"
pde.62.name   = "IGDSMS"
pde.62.alt    = "SMS"
pde.63.name   = "SQA"
pde.63.alt    = "*"
pde.64.name   = "IEFSSN"
pde.64.alt    = "SSN"
pde.65.name   = "IEASVC"
pde.65.alt    = "SVC"
pde.66.name   = "SWAP"
pde.66.alt    = "?"
pde.67.name   = "SYSNAME"
pde.67.alt    = "*"
pde.68.name   = "SYSP"
pde.68.alt    = "*"
pde.69.name   = "VATLST"
pde.69.alt    = "VAL"
pde.70.name   = "VIODSN"
pde.70.alt    = "*"
pde.71.name   = "VRREGN"
pde.71.alt    = "*"
pde.72.name   = "RTLS"
pde.72.alt    = "?"
pde.73.name   = "CUNUNI"
pde.73.alt    = "UNI"
pde.74.name   = "ILM"
pde.74.alt    = "?"
pde.75.name   = "ILMOD"
pde.75.alt    = "?"
pde.76.name   = "IKJTSO"
pde.76.alt    = "TSO"
pde.77.name   = "LICENSE"
pde.77.alt    = "*"
pde.78.name   = "filler"
pde.78.alt    = "?"
pde.79.name   = "VSHAR"
pde.79.alt    = "?"
pde.80.name   = "ILM"
pde.80.alt    = "?"
pde.81.name   = "DRMODE"
pde.81.alt    = "*"
pde.82.name   = "CEEPRM"
pde.82.alt    = "CEE"
pde.83.name   = "PRESCPU"
pde.83.alt    = "*"
pde.84.name   = "LFAREA"
pde.84.alt    = "*"
pde.85.name   = "CEAPRM"
pde.85.alt    = "CEA"
pde.86.name   = "VCOMM"
pde.86.alt    = "?"
pde.87.name   = "AXR"
pde.87.alt    = ""
pde.88.name   = "ZAAPZIIP"
pde.88.alt    = "*"
pde.89.name   = "IQPPRM"
pde.89.alt    = "IQP"
pde.90.name   = "CPCR"
pde.90.alt    = "?"
pde.91.name   = "DDM"
pde.91.alt    = "?"
pde.92.name   = "AUTOR"
pde.92.alt    = "*"
pde.93.name   = "IGGCAT"
pde.93.alt    = "CATALOG"
pde.94.name   = "IXGCNF"
pde.94.alt    = ""
pde.95.name   = "PAGESCM"
pde.95.alt    = "*"
pde.96.name   = "WARNUND"
pde.96.alt    = "*"
pde.97.name   = "HZSPRM"
pde.97.alt    = "HZS"
pde.98.name   = "GTZPRM"
pde.98.alt    = "GTZ"
pde.99.name   = "HZSPROC"
pde.99.alt    = "*"

/* chain to IPA control block */
cvt   = c2d(storage(d2x( psa +  psa_cvt),4))
ecvt  = c2d(storage(d2x( cvt + cvt_ecvt),4))
ipa   = c2d(storage(d2x(ecvt + ecvt_ipa),4))

/* get active PARMLIBs */
plnumx = c2d(storage(d2x(ipa + ipa_plnumx),2))
parmlib.0 = 0
do i = 1 to plnumx
  lib = strip(storage(d2x(ipa + ipa_plib + 64 * (i-1)),44))
  flag = storage(d2x(ipa + ipa_plib + 64 * (i-1) + 63),1)
  if c2d(bitand(flag, '80'x)) > 0 then do
    parmlib.0 = parmlib.0 + 1
    x = parmlib.0
    parmlib.x = lib
  end
end

select
  when parm = "LOAD" then
    do
      value = storage(d2x(ipa + ipa_lparm),2)
      dsn = strip(storage(d2x(ipa + ipa_lpdsn),44))
      connect = 'FIRSTLINE'
      x = AXRMLWTO("LOAD = "value,'CONNECT','C')
      x = AXRMLWTO(dsn"(LOAD"value")",'CONNECT','D')
      x = AXRMLWTO(,'CONNECT','E')
    end
  when parm = "IODF" then
    do
      value = storage(d2x(ipa + ipa_iodf),2)
      hlq = strip(storage(d2x(ipa + ipa_iohlq),8))
      connect = 'FIRSTLINE'
      x = AXRMLWTO("IODF = "value,'CONNECT','C')
      x = AXRMLWTO(hlq".IODF"value,'CONNECT','D')
      x = AXRMLWTO(,'CONNECT','E')
    end
  when (parm = "IEASYS") | (parm = "SYS") | (parm = "SYSPARM") then
    do
      value = strip(storage(d2x(ipa + ipa_sys),63))
      connect = 'FIRSTLINE'
      x = AXRMLWTO("SYSPARM = "value,'CONNECT','C')
      call findem "IEASYS",value
      x = AXRMLWTO(,'CONNECT','E')
    end
  when (parm = "IEASYM") | (parm = "SYM") then
    do
      value = strip(storage(d2x(ipa + ipa_sym),63))
      connect = 'FIRSTLINE'
      x = AXRMLWTO("IEASYM = "value,'CONNECT','C')
      call findem "IEASYM",value
      x = AXRMLWTO(,'CONNECT','E')
    end
  when parm = "NUCLST" then
    do
      value = storage(d2x(ipa + ipa_nuc),2)
      dsn = strip(storage(d2x(ipa + ipa_lpdsn),44))
      connect = 'FIRSTLINE'
      x = AXRMLWTO("NUCLST = "value,'CONNECT','C')
      x = AXRMLWTO(dsn"(NUCLST"value")",'CONNECT','D')
      x = AXRMLWTO(,'CONNECT','E')
    end
  otherwise
    do
      connect = 'FIRSTLINE'
      /* look for a PDE */
      found = 0
      i = 1
      do while (found = 0) & (i <= pde.0)
        if (parm = pde.i.name) | (parm = pde.i.alt) then do
          found = 1
        end
        else i = i + 1
      end
      if found = 1 then do
        vaddr = c2d(storage(d2x(ipa + ipa_pde + 8 * (i-1)),4))
        vlen  = c2d(storage(d2x(ipa + ipa_pde + 8 * (i-1) + 4),2))
        vsrc  = storage(d2x(ipa + ipa_pde + 8 * (i-1) + 6),2)
        if c2d(vsrc) = 0 then do
          source = "Default"
        end
        else do
          if c2d(vsrc) = 65535 then do
            source = "Operator"
          end
          else do
            source = "IEASYS"vsrc
          end
        end
        if vaddr > 0 then do
          value = storage(d2x(vaddr),vlen)
        end
        else do
          value = "*** unspecified ***"
          source = ""
        end
        if (pde.i.alt = "*") | (pde.i.alt = "?") then do
          x = AXRMLWTO(parm" = "value,'CONNECT','C')
          if source <> "" then do
            x = AXRMLWTO("Source: "source,'CONNECT','D')
          end
        end
        else do
          if pde.i.alt = "" then do
            x = AXRMLWTO(pde.i.name" = "value,'CONNECT','C')
          end
          else do
            x = AXRMLWTO(pde.i.alt" = "value,'CONNECT','C')
          end
          if source <> "" then do
            x = AXRMLWTO("Source: "source,'CONNECT','D')
          end
          call findem pde.i.name, value
        end
      end
      else do
        x = AXRMLWTO("*** "parm" not recognised ***",'CONNECT','C')
      end
      x = AXRMLWTO(,'CONNECT','E')
    end
  end

exit 0

findem:
arg prefix,suffices
if length(suffices) = 2 then do  /* single suffix */
  fmfound = 0
  fmi = 1
  do while (fmfound = 0) & (fmi <= parmlib.0)
    if ismember(parmlib.fmi,prefix||suffices) then do
      x = AXRMLWTO(parmlib.fmi"("prefix||suffices")",'CONNECT','D')
      fmfound = 1
    end
    fmi = fmi + 1
  end
end
else do
  parse var suffices "("rest")" .
  do while rest <> ""
    parse var rest suffix","rest
    if length(suffix) = 2 then do  /* because CON=xx,xx,NOJES3 */
      fmfound = 0
      fmi = 1
      do while (fmfound = 0) & (fmi <= parmlib.0)
        if ismember(parmlib.fmi,prefix||suffix) then do
          x = AXRMLWTO(parmlib.fmi"("prefix||suffix")",'CONNECT','D')
          fmfound = 1
        end
        fmi = fmi + 1
      end
    end
  end
end
return

ismember: procedure
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
      /* say "*** there are DUDS in the list" */
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
