Author: Andrew Mattingly: <andrew_mattingly@au1.ibm.com>

Copyright IBM Corp. 2018
 
This exec implements the UNIX "which" functionality for z/OS as a System REXX procedure.  If you add it to the SYS1.SAXREXEC on your system, you can invoke it thus:

`F AXR,WHICH procname [procnn]`

Or, assuming "@" is defined as the CPF in AXR00 in SYS1.PARMLIB

`@WHICH procname [procnn]`

For example, on my system:

```
 @WHICH TYRONE
 TYRONE not found in PROCLIB concatenation PROC00
 @WHICH TYRONE PROC01
 TYRONE not found in PROCLIB concatenation PROC01
 @WHICH LISTMEM PROC01
 ADCDMST.EXEC(LISTMEM)
 @WHICH HLASMC
 HLA.SASMSAM1(HLASMC)
``` 
