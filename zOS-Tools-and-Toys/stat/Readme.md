# stat

Copyright 1994, IBM Corporation
All rights reserved

Distribute freely, except: don't remove my name from the source or
documentation (don't take credit for my work), mark your changes
(don't get me blamed for your possible bugs), don't alter or
remove this notice.  No fee may be charged if you distribute the
package (except for such things as the price of a disk or tape,
postage, etc.).  No warranty of any kind, express or implied, is
included with this software; use at your own risk, responsibility
for damages (if any) to anyone resulting from the use of this
software rests entirely with the user.

Send me bug reports, bug fixes, enhancements, requests, flames,
etc.  I can be reached as follows:

John Pfuntner      <pfuntner@pobox.com>

## Description

stat is a tool to display information about files you specify on
the command line.  It basically reports all the information
that the stat() function returns:

    $ stat stat.c ~
    Info for 'stat.c':
      The absolute pathname is '/u/pfuntnr/external/stat/stat.c'
      It is a regular file
      inode: 12044, device id: 7 (OMVS.HFS.PFUNTNR)
      Permissions: User: RW, Group: R, Other: R
      There are 1 links to this file
      Owning user: PFUNTNR (3)    Owning group POSIX (1)
      The file has 6644 bytes
      Created:  Sat Jul 30 1994 10:30:24 AM EDT
      Accessed: Sat Jul 30 1994 10:30:24 AM EDT
      ctime:    Sat Jul 30 1994 10:30:24 AM EDT
      mtime:    Sat Jul 30 1994 10:30:24 AM EDT

    Info for '/u/pfuntnr':
      The absolute pathname is '/u/pfuntnr'
      It is a directory
      inode: 0, device id: 7 (OMVS.HFS.PFUNTNR)
      Permissions: User: RWS, Group: RS, Other: RS
      Owning user: PFUNTNR (3)    Owning group POSIX (1)
      Created:  Mon May 23 1994 02:39:06 PM EDT
      Accessed: Sat Jul 30 1994 11:28:20 AM EDT
      ctime:    Sat Jul 30 1994 10:33:42 AM EDT
      mtime:    Sat Jul 30 1994 10:33:42 AM EDT

