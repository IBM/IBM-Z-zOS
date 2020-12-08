# colonies

List colony address space names.

Author: Bill Schoen <wjs@us.ibm.com>

## Syntax

```shell
colonies
```

This lists the name of any colony address spaces. This utility can be useful to determine the names of colony address spaces if you need to terminate them.

## Installation

Place colonies in a directory where you keep executable programs. Make sure the permission bits are set to 0555 (or at least 0500) so that a superuser can execute it.  If you would like it to be useable by anyone, set the permissions to 04555 to make it a setuid program.  The file owner must be uid 0.

If you obtain this program via FTP, the program is a REXX program in source form.  Transfer it in text mode.  As a reminder, the filename is colonies.rexx.
