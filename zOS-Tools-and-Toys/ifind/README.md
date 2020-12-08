# ifind

Copyright 1994, IBM Corporation

All rights reserved

## Description

ifind is a tool that can be used to find files in a filesystem that share the same data.  A file can be known by several different links (sometimes called a "hard link" to distinguish them from "symbolic links) and they all point to the same "inode" - a number which uniquely identifies the file in the filesystem.  You can search for files by specifying the name of one of the links to the file or by specifying the inode as a decimal number.  If you specify the inode, ifind assumes you mean you want to search the filesystem containing the current working directory.  Since ifind assumes a decimal number is an inode, if you want to search for a file by its name which is composed of only digits (such as "1"), you must specify it in a way that it is unambiguous ("./1" for instance).

## Example

    $ ifind /bin/kill
    searching for links of /bin/kill (inode 406) in /
    /bin/cd
    /bin/command
    /bin/getopts
    /bin/read
    /bin/wait
    /bin/IBM/FSUMSSHB

