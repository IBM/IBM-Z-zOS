# MSGL610

The `MSGLG610` program and the accompanying `IPLMERG4` program can be used to analyze z/OS SYSLOG data sets. Reports include the most frequently occurring message IDs, the most frequently occurring commands, actions taken on messages by the Message Processing Facility (MPF) and Message Flood Automation, as well information about message rates. The IPLMERG4 program can compare events in one SYSLOG relative to events in another SYSLOG and is especially useful in understanding z/OS start-up events.

Consult the [MSGL610 user guide](guide160.html) on how to use the program.

The [stdjes2.jcl](stdjes2.jcl) and [stdjes3.jcl](stdjes3.jcl) files are text files and should be uploaded in
**ASCII** text format to your z/OS system and placed into a fixed-block (FB)
partitioned data set (PDS) that has a logical record length (LRECL) of 80
bytes. These files contain sample z/OS job control language (JCL) for running
the Message Analysis Program.

The msglg610.obj file is the Message Analysis Program in z/OS object deck
format. It must be uploaded to your z/OS system in **BINARY** form and placed into
a fixed-block (FB) partitioned data set (PDS) that has a logical record length
(LRECL) of 80 bytes. (For example, using ISPF option 3.2 create data set
`MAP.OBJ` with a blocksize of 16000, a logical record length of 80 and 10
directory blocks. Upload msglg610.obj and place it as member MSGLG610 in the
`MAP.OBJ` data set). Once on your z/OS system, the MSGLG610 object deck must be
link-edited or bound into a load library using the z/OS linkage editor or
binder before you can run it. You can do this by using ISPF option 4.7 which
allows you to invoke the z/OS binder or linkage-editor programs under TSO. From
the example above, just specify `MAP.OBJ(MSGLG610)` on the "Other Partitioned
Data Set: Data Set Name" line. Specify `LET,LIST,MAP` on the "Linkage
editor/binder options" line and press ENTER. You will be shown the results of
the binding/linkage-editing step and the output of the process will be placed
into a LOAD data set which may have the name `MAP.LOAD` or `userid.LOAD` depending
on your installation's options. You should then alter the `STDJES2` or `STDJES3`
job control language data sets to point to this LOAD library and then you
should be ready to run the program.

The [abendtbl.txt](abendtbl.txt), [compid.txt](compid.txt), [msgids.txt](msgids.txt) and
[msgtype2.txt](msgtype2.txt) files are text files and must be uploaded to your z/OS system in
**ASCII** text format. All four of the files should be placed into an z/OS fixed-block
(FB) partitioned dataset with an LRECL of 80. It is critical that the member names
used be `ABENDTBL`, `COMPID`, `MSGIDS`, and `MSGTYPE2`.

[Here is the user guide](iplmerg4.html) for the `IPLMERG4` program which can be used
to compare events occurring in two SYSLOGs.

The iplmerg4.obj file is the `IPLMERG4` program in z/OS object deck format. Upload
it in the same way that you uploaded the msglg610.obj file. Use the binder or
linkage-editor to create the `IPLMERG4` load module in the same way that you
created the `MSGLG610` load module. See the [iplmerg4.html](iplmerg4.html) documentation for
information on how to use this program.
