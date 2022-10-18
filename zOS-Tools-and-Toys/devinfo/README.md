# devinfo

List the DASD device connections for all systems in a sysplex.

Author: Kevin Miner <keminer@us.ibm.com>

## Syntax

    devinfo <device address>

    devinfo <device address> botprint

The first form of this command will generate a summary of connection status for all systems in a sysplex by issuing and parsing several z/OS commands.

The second form attempts to limit the generated summary information to 78 characters in length by rearranging the generated output.  This is an optional parameter.

## Example

    devinfo d8d0

    devinfo d8d0 botprint

This will summarize the DASD device connections for device D8D0 for all systems in the sysplex in two different formats.

## Installation Information

Place `devinfo` in a data set that is part of your SYSPROC or SYSEXEC DD concatenation.  This exec uses the `TSO CONSOLE` command so it must be executed under a TSO address space.

If you obtain this program via FTP, this program is a Rexx exec in source form.  Transfer it in text mode to your z/OS system.
