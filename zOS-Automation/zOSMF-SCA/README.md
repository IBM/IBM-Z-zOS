# README

## Before you import the descriptor files

Before importing the descriptor files into z/OSMF Security Configuration Assistant you might want to change some or all of the variables in the files, statically.

This might be even necessary, when you want to use certain reserved characters such as asterisk `*` or dot `.` as variable values as the Security Configuration Assistant doesn't allow to enter these in the Edit dialog.

To statically substitute variables with a new value you can edit the descriptor files with a tool of choice and perform the changes manually. 

Alternatively, you can use the included utility `scamod.sh`, a shell script, and the associated command file `cmds.txt` to prepare and execute the change automatically.

**Note**: The script `scamod.sh` requires `sed` to be installed on UNIX System Services or on your Linux or Mac.

1. Edit `cmds.txt` and change the substitution value for those variables that you want to change.

2. Run `scamod.sh`. If you don't specify any parameter, it uses `cmds.txt` as command file. 
   ```
   ./scamod.sh
   ```

   If you created your own command file, you can pass it as a parameter to the `scamod.sh`. If the name of your command file is MY_FILE, the invocation looks like this:
   ```
   ./scamod.sh MY_FILE
   ```

## Validation of IDs

Currently, the z/OSMF Security Configuration Assistant requires that any ID you want to validate has READ access to the `IZUDFLT` resource profile in class `APPL`.

Since you want to validate the authorization against human operators but also auto-operators required by NetView and System Automation, the recommendation is to create a single group, for instance `IZUGSTS` (read as IZU guests) and assign the operators to this group. That group is then granted access to `IZUDFLT` similar as it is done for the standard z/OSMF ID `IZUGUEST`:

1. Define a profile in class `APPL`, if not already done so during setup of z/OSMF:
   ```
   RDEFINE APPL IZUDFLT UACC(NONE) 
   ```

2. Add group, for instance `IZUGSTS`:
   ```
   ADDGROUP IZUGSTS OMVS(AUTOGID)
   ```

3. Permit READ access to resource profile `IZUDFLT`:
   ```
   PERMIT IZUDFLT CLASS(APPL) ID(IZUGSTS) ACCESS(READ)
   ```

Note: z/OSMF also provides a group for unauthenticated users, called `IZUUNGRP` which seems was created with the very same intention.  By default, only the user `IZUGUEST` is a member of that group. However, the samples don't suggest to permit the whole group access to `IZUDFLT` but rather only for `IZUGUEST`.  Hence the proposal to create a special group `IZUGSTS` for the purpose herein.