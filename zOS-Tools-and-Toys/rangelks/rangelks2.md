# rangelks2

Authors:
* Bill Schoen <wjs@us.ibm.com>
* Mike Cox    <mccox1@us.ibm.com>

Syntax: `rangelks2`

This lists the processes holding byte range locks and the files
that are locked.   This is an update to rangelks.  For z/OS 1.6
and above, rangelks2 will also list byte range lock waiters as well
as backup locks in a system.

## Install Information

Place rangelks2 in a directory where you keep executable programs
or in a PDS where you keep REXX execs.

If placed in a directory in the HFS:
Make sure the permission bits are set to 0555 (or at least 0500)
so that a superuser can execute it.  If you would like it to be
useable by anyone, set the permissions to 04555 to make it a
setuid program.  The file owner must be uid 0.

If you obtain this program via FTP, the program is a REXX program
in source form.  Transfer it in text mode.  As a reminder, the
filename is rangelks2.txt.
