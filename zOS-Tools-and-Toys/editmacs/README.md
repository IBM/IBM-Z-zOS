# editmacs

ISPF edit macros for working with HFS files.

Author: Bill Schoen <wjs@us.ibm.com>

## bpxget

In an ISPF edit session, use bpxget to copy an HFS file into your current edit session. It works similarly to the EDIT COPY command. See the macro prolog for installation and usage information.

## bpxput

In an ISPF edit session, use bpxput to create or replace an HFS file from your current edit session with an entire file or range of lines in a file. It works similarly to the EDIT CREATE or EDIT REPLACE commands. See the macro prolog for installation and usage information.

## bpxwtabs

In an ISPF edit session, use bpxwtabs to convert tab characters in your file to a proper number of spaces or spaces to tabs. See the macro prolog for installation and usage information.

## i and isu

Use this as a TSO command entered with F6 from OMVS to re-enter ISPF, optionally with your effective UID set to 0. See the utility prolog for installation and usage information.
