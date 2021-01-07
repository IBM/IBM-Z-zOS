# auditid

List audit ids for a path or locate a file given an audit id

Author: Bill Schoen <wjs@us.ibm.com>

## Syntax
      auditid <pathname>
      auditid <32 character audit id (FID)>

  The first form of this command lists each name in the path along with
  its audit id.  The second form searches the file system for a file
  with the specified audit id.  This command can be useful to find the
  file or directory which is causing an access failure due to
  permission bit settings.

  The second form of the command will only work for HFS file systems.

  ## Example

      auditid 01D6D4E5E2F0F10020040002DF230000

  This will find the file that has this audit id.

  ## Install Information

  Place auditid in a directory where you keep executable programs.
  Make sure the permission bits are set to 0555.

  If you obtain this program via FTP, the program is a REXX program
  in source form.  Transfer it in text mode.  As a reminder, the
  filename is auditid.rexx.
