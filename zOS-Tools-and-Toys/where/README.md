Author: Andrew Mattingly: <andrew_mattingly@au1.ibm.com>

Copyright IBM Corp. 2018

This is an "IPA crawler" which can find out where an initialization parameter is set.  Load it into your `SYS1.SAXREXEC` and give it a whirl.  It takes the name of a `IEASYSxx` parameter (or the corresponding PARMLIB member prefix) as a parameter, and reports the value detected at
initialization, where it was set, and where to find the referenced PARMLIB datasets, if the value is a suffix or list of suffices.  It also takes some "special parameters" for the "early stuff":  
* LOAD
* IODF
* {IEASYS|SYS|SYSPARM}
* {IEASYM|SYM}
* NUCLST.

For example:

```
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
```

This REXX is somewhat imperfect - it doesn't cope with all the nuances of z/OS parameter configuration (but catches most of them).

