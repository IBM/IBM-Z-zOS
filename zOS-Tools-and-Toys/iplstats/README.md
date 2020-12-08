# iplstats

IPLSTATX.OBJ -- writes the IPL start-up statistics to a SYSOUT data set
IPLSTATZ.OBJ -- writes the IPL start-up statistics as WTOs to SYSLOG

The *.OBJ files contain the IPL start-up statistics program in MVS object deck
format. It must be uploaded to your MVS system in -BINARY- form and placed into
a fixed-block (FB) partitioned data set (PDS) that has a logical record length
(LRECL) of 80 bytes. (For example, using ISPF option 3.2, create data set
IPLSTATS.OBJ with a blocksize of 16000, a logical record length of 80 and 10
directory blocks. Upload IPLSTATX.OBJ and place it as member IPLSTATX in the
IPLSTATS.OBJ data set). Once on your MVS system, the IPLSTATX object deck must
be link-edited or bound into a load library using the MVS linkage editor or
binder before you can run it. You can do this by using ISPF option 4.7 which
allows you to invoke the MVS binder or linkage-editor programs under TSO. From
the example above, just specify IPLSTATS.OBJ(IPLSTATX) on the "Other
Partitioned Data Set: Data Set Name" line. Specify LET,LIST,MAP on the "Linkage
editor/binder options" line and press ENTER. You will be shown the results of
the binding/linkage-editing step and the output of the process will be placed
into a LOAD data set which may have the name IPLSTATS.LOAD or userid.LOAD
depending on your installation's options.

Either program can be run as a batch job or started task or you can run the
program under TSO. Both programs run in problem program state and neither uses
any authorized services or requires any special security considerations.

The IPLSTATX program writes its report to a standard SYSOUT data set. For
batch and started tasks, you will need a
//OUTPUT DD SYSOUT=A,DCB=(RECFM=FB,LRECL=133)
specification.

If you run the program under TSO, issue ALLOC FI(OUTPUT) DS(*) before invoking
the program. (Or alternatively, you could have the output go to a data set).

The IPLSTATZ program writes its report to the SYSLOG using WTOs with
hardcopy-only specified (the WTOs will not appear on any console). Each line
of the report is written as a single-line WTO and each WTO is prefaced by an
IPLSTnnnI message ID.

Either program can be run at any time after the first TCP/IP stack comes up
(not all of the start-up statistics are considered complete until the first
TCP/IP stack comes up).  The start-up statistics persist until the next IPL,
so you can run the report programs long after the IPL has occurred.

Originally by Kevin Kelley

## License

Copyright 1998-2020 IBM Corp.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

[www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing,
software distributed under the License is distributed on an
"AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
either express or implied. See the License for the specific
language governing permissions and limitations under the
License.

Disclaimer of Warranties:

The following enclosed code is sample code created by IBM
Corporation.  This sample code is not part of any standard
IBM product and is provided to you solely for the purpose
of assisting you in the development of your applications.
The code is provided "AS IS", without warranty of any kind.
IBM shall not be liable for any damages arising out of your
use of the sample code, even if they have been advised of
the possibility of such damages.
