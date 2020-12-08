# wjssh

Author: Bill Schoen  <wjs@us.ibm.com>

PROPERTY OF IBM

COPYRIGHT IBM CORP. 2008,2012

## Purpose

This is a simple to use tool that lets you run a shell command from an
operator console.  It must be run through SYSREXX from an operator
logged onto the console with a userid that is properly setup to access
z/OS UNIX services.  If the operator is not setup or logged on, this
program will issue a reminder message about this requirement and end.

To use from SYSREXX, this program must be copied to either
SYS1.SAXREXEC or another library that has been added to the SYSREXX
libraries using the REXXLIB parmlib statement in your AXRxx parmlib.

When entering shell commands, be sure to enclose the string in quotes so
that the modify command does not uppercase your command.  For example,
assume you configure the SYSREXX CPF for `/`, the ls command might be entered as
`/wjssh 'ls -l /etc/'`

Things to be aware of when using sysrexx:

There is a 30 second time limit which you can and should override
on the command line.  To disable the timer, enter the above example
as:  `/wjssh,t=0 'ls -l /etc/'`
If single quotes need to be entered on the shell command, read the
SYSREXX documentation for quote rules very carefully.
As an example, the command `cp "//'wjs.rexx(file)'" /tmp/file`
can be entered as `/wjssh,t=0 'cp "//''wjs.rexx(file)''"' '/tmp/file'`

This tool can also be used from TSO and ISPF and run as you would any
REXX exec.  This program should be copied to a library in your SYSEXEC
or SYSPROC concatenation.

## Syntax

`wjssh <command>`

