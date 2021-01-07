# cksparse

A sparse file scanner.

This scans a file system starting at a specified directory for any files that are sparse in terms of having full pages within the file not backed.

## Syntax

```shell
      cksparse <pathname>
```

_\<pathname\>_ can be a directory or a regular file.  This should be run from a superuser to ensure nothing is missed.

## Install

Place this where REXX execs can be found.  It can be in a PDS and run from TSO or in the HFS.
