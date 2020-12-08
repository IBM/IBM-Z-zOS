# fsview

View file system mount topology and information

Author: Bill Schoen <wjs@us.ibm.com>

Property of IBM
Copyright IBM Corp. 1997

## Syntax
    
    fsview

This lists all mounts on the root file system and prompts for more detail and mount information for for those file systems.  This utility can be used by ordinary users or superusers.  Ordinary users may not be able to view the full hierarchy.


## Installation

Place fsview in a directory where you keep executable programs.  Make sure the permission bits are set to 0555 (or at least 0500)  so that you can execute it.  If you would like it to be useable by anyone, set the permissions to 0555 for universal read/execute.  This can also be installed in a PDS where you keep REXX execs.  fsview is capable of running in TSO or under the z/OS UNIX shell.

.
