# DLOG Formatter

## Function
This program is an example of how to use the services of the MVS System Logger to retrieve and delete records from the Operations Log stream.  In response to parameters, it can read the records created in a given time span, convert them from Message Data Block (MDB) format to Hard-copy Log format (JES3 DLOG), mapped by DSECT DLOGLINE, and write the DLOG-format records to a file; and/or it can delete all the records from the stream that were created prior to a given date.

It is assumed the Operations Log (Operlog) contains JES2-generated records.  Running this program against JES3-generated records will produce incompatible format for JES3 Global-generated messages.

## Parameters
The parameters are as follows:
```
COPY([start_date][,end_date]), DELETE(date)
    (>nnn)                           (>nnn)
```
`COPY`:  Records are to be copied to the DLOG-format file. If COPY is not specified, no records are copied.
* `start_date`,`end_date`: The starting and ending dates of the time span, both in the format YYYYDDD.  `start_date` must not be later than `end_date`.  end_date must not be later than today, the day the program runs.  The default for `start_date` is the date of the oldest record in the log stream, and for `end_date` is yesterday, the day before the program runs.  If both `start_date` and `end_date` are allowed to default, the parentheses after `COPY` may be omitted. If you specify a start date of today, you must also specify the end date of today, otherwise the program will assume an end date of yesterday and abend.
* `>nnn`: Indicates that records dated more than `nnn` days\ before today are to be copied.  The time span will start with the date of the oldest record in the log stream and end `nnn+1` days before today (that is, records dated more than nnn days before today will be copied. `nnn` is a number between zero and 999. For example, if the program is run on May 25, specifying `COPY(>3)` will copy records dated up to and including May 21.  Note that `>0` corresponds to yesterday.  To copy today's records, you must use the `[start_date][,end_date]` form and specify today as the end date.

`DELETE`:  Records are to be deleted.  If `DELETE` is not specified, no records are deleted.
* `date`:  The date of the newest record to be deleted from the log stream.  All records dated on or before that date will be deleted.  The date must not be later than today.  If the date specified is today, all records in the log stream will be deleted.
* `>nnn`: Indicates that records dated more than nnn days before today are to be deleted.  nnn is a number between zero and 999.  For example, if the program is run on July 15, specifying `DELETE(>5)` will delete records dated up to and including July 9.  Note that 0 corresponds to yesterday.  To delete today's records, you must use the "date" form and specify today as the date.
You may specify either `COPY` or `DELETE` or both.  If you specify both they must be separated by a comma and may appear in either order.  However, regardless of the order in which the parameters are specified, the copy operation will always occur before the delete.

`HCFORMAT`: Specifies whether the output records (in JES3 DLOG format) should have a 2-digit or a 4-digit date.
* `YEAR`: A 2-digit year will appear in the output records. The DLOGLINE mapping will be used to map the JES3 DLOG format output records. If the `HCFORMAT` keyword is not specified `HCFORMAT(YEAR)` is the default.
* `CENTURY`: A 4-digit year will appear in the output records. The DLOGLINE mapping will be used to map the JES3 DLOG format output records.

An optional DD - JES3IN - can be used in the JCL to allow for a more customized format.  (It is assumed that the customer will use the same set of processors in JES2 as were used in JES3.)  Two JES3 Initialization statements are supported:
* `MAINPROC`
* `MSGROUTE`

Other statements, if provided, are ignored.  No error messages for extranous statements or syntax errors found are issued.

The `MAINPROC` is used to extract the format of the Receive id for each processor defined in the configuration. The `MSGROUTE` is used to determine what JES3 Destination code and/or console name should be displayed on the output line based on the routing code. If neither statement is provided, the receive id will be the same as system name.  The routing code will be used to display the JES3 Destination class with no further changes.

## Warnings
When copying records, this program detects the end of a day's records when it either reads the first record for the next day or attempts to read past the newest record in the log stream.  This means that, if `end_date` is today and the log stream is being written at the time this program runs, the records that are copied may not be predictable.  In particular, if both `COPY` with an ending date of today and `DELETE` with a date of today are specified, there may be more records deleted than copied.

When the `>nnn` form of the `COPY` or `DELETE` parameter is specified, program converts it to a date by subtracting `nnn` days from the date the program is run. The calculation is done once, at the beginning of the program.  If the program is run shortly before midnight, so that the calculation occurs before midnight and the actual copying or deletion of records occurs after midnight, the records copied or deleted will not reflect the number of days specified.  To prevent this, you should avoid running the program close to midnight with the `>nnn` form.

Note that if the program is run regularly after midnight with the parameter `COPY(>0)`,`DELETE(>1)`, it will copy records from the previous day and earlier, and will delete from the records from two days ago, leaving something over 24 hours' worth of records in the log each time.

## Limitations
The selection of records uses the internal timestamp of log stream records, which corresponds to the time of the request to write the record to the stream.  It is possible for records to be out of sequence in the log, in which case the records ostensibly for a given day may include some from the previous or next day.  Moreover, the timestamp in an MDB is not necessarily the same as that of the internal log stream record. Therefore the selection by date is no better than an approximation. However, the set of records selected for a given day will be unique.

Records could be missing based on prior activities. In these cases, a message will be written to the output file with a unique format to identify it. This will be done for record gaps or deletions found at the beginning or end of the data, or any place in the middle. If the special messages would interfere with any applications using the output, adjust or remove the code as appropriate.

## Operation

#### Initialization
1. If `COPY` was specified, get end and start dates or calculate defaults, yesterday and "oldest" respectively.
2. If `DELETE` was specified, get delete date.
3. If `HCFORMAT` was specified, set the appropriate flags to indicate if `HCFORMAT(YEAR)` or `HCFORMAT(CENTURY)` was
specified.
4. Open the JES3IN DD, if present, and parse the `MAINPROC` and `MSGROUTE` initialization statements.  Build tables to be used during output formatting.
5. Obtain a buffer area for logger record and set up its base
6. Connect to the log stream
#### Copy
If `COPY` was specified:
1. Start a log stream browse session and position the log stream to first record in the range
2. Copy loop:
   1. Read successive records from the stream, starting with the earliest record bearing the start date and ending with the latest record on or before the end date
   2. If the return and reason code indicates a gap in records or deleted records, show this by adding a special message to the output file.
   3. For each record (MDB) that is read:
   4. Get the general and CP objects
   5. Extract the fixed info
   6. For every line (text object) in the message:
   7. Write a DLOG-format line to the output file
   8. If line was too long, also write a continuation line
3. End the log stream browse session
4. Close the output file
#### Delete
If `DELETE` was specified:
1. Start a log stream browse session and position the log stream to oldest record to be kept
2. Delete all records prior to that position
3. End the log stream browse session
#### HCFORMAT
If `HCFORMAT` was specified:
1. If `HCFORMAT(CENTURY)` was specified the output records will have a 4-digit date and the HCR mapping will be used to map the records, otherwise the output records will have a 2-digit date and the HCL mapping will be used to map the records.

#### Cleanup
1. Disconnect from the log stream
2. Free the buffer area
3. Exit

## Samples
Using YYYYDDD format parameters, and having a 2-digit year in the output records. This example job will copy records created between July 1, 2021, and "yesterday", inclusive, and will delete from the log stream any records created on or before June 30, 2021. The date part of the output records will have a 2-digit year.
```
//jjj     JOB  ...
//sss     EXEC PGM=IEAMDBL3,
//        PARM='COPY(2021182),DELETE(2021181),HCFORMAT(YEAR)'
//DLOG    DD   DSN=ALL.DLOGS(+1),
//             DISP=(NEW,CATLG,DELETE),
//             DCB=BLKSIZE=22880
//JES3IN  DD   DSN=JES3.INIT.STREAM,DISP=SHR
```
Using `>nnn` format parameters, and having a 4-digit year in the output records. Assuming it is run on July 15, this example job will copy records created on or before July 9, and will delete from the log stream any records created on or before July 6. The date part of the output records will have a 4-digit year.
```
//jjj     JOB  ...
//sss     EXEC PGM=IEAMDBL3,
//             PARM='COPY(>5),DELETE(>8),HCFORMAT(CENTURY)'
//DLOG    DD   DSN=ALL.DLOGS(+1),
//             DISP=(NEW,CATLG,DELETE),
//             DCB=BLKSIZE=22880
//JES3IN  DD   DSN=JES3.INIT.STREAM,DISP=SHR
```
## Recovery
This program make no attempt to recover from failures. The caller's recovery environment, if any, will remain in effect. For any abend other than one of the user abends issued normally by this program, you should check the output file for any additional information.

If additional levels of recovery are needed for particular environments, the program must be modified and reassembled.

## Build information
This program makes use of logger service routines. Changes to these service routines (e.g. new return or reason codes) may necessitate changes to this program.

This program must be link edited as Non-Reentrant, since this program uses global variables which allow for it to modify its own storage. To make the link edit job Non-Reentrant remove RENT from the PARM= statement. Sample JCL for linkediting the program:
```
//*----------------------------------------------------
//LNKLPA  EXEC PGM=linkproc,PARM='MAP,LET,LIST,NORENT'
//SYSLMOD DD   DSN=linked.userlib,DISP=SHR
//SYSUT1  DD   UNIT=SYSDA,SPACE=(CYL,(3,2)),DSN=&SYSUT1
//SYSPRINT DD  SYSOUT=*,DCB=(RECFM=FB,BLKSIZE=3509)
//DR1     DD   DSN=assem.ieamdbl3.obj,DISP=SHR
//SYSLIN  DD   *
*******************************************************
*       IEAMDBL3 Sample program
*******************************************************
  INCLUDE DR1(IEAMDBL3)
  ENTRY IEAMDBL3
  NAME IEAMDBL3(R) RC=0
```
## Messages
The following messages are displayed on the issuing console.
>MLG001I INVALID OR MISSING PARAMETER

The parameter on the EXEC statement statement could not be parsed.  The program will abend with completion code U0001.  Correct the parameter and rerun the step.
>MLG002I ERROR DURING SYSTEM LOGGER rrrrrrrr-n,RETURN CODE xxx, REASON CODE yyyy

A request to a System Logger service failed.  The program will abend with completion code `U002`. The failing service is identified by `rrrrrrrr`, which may be "IXGCONN", "IXGBRWSE", or "IXGDELET". If there is more than one invocation of the service, the invocation that failed is indicated by `-n`, where `n` is a number that identifies the instance. `xxx` is the return code and `yyyy` the reason code. See the documentation of the system logger services, correct the problem, and rerun the step.
>MLG003I NO RECORDS IN RANGE

There were no records in the operations log stream created between the starting and ending dates, inclusive.  The program will continue.  Any records in the log stream that are eligible for deletion will be deleted.  The output file will be empty.
>MLG004I LOG STREAM IS EMPTY

The return from IXGBRWSE has indicated that there are no records in the log stream.
>ILG0001 RECORDS NOT AVAILABLE. IXGxxxxx-nn RETURN CODE nnn,REASON CODE nnnn

The return and reason codes from a log stream service routine indicate that data may be missing. The `-nn` at the end of the service routine name identifies the specific instance of the routine invoked at which point the unavailable records were detected.

If the service routine is IXGCONN, then the service routine has indicated that data may be
missing.
If the service routine is IXGBRWSE, then one of the following has probably occurred.
* A gap has been found in records immediately prior to the first record found meeting selection criteria.
* Records had previously been deleted immediately prior to the first record found meeting selection criteria.
* There was a gap or deleted records between two records within selection criteria.
* A gap or deleted records immediately follow the last record meeting criteria. This routine then either encountered end of file, or the next record was out of selection criteria.
* Records could be permanently missing from the log stream.
In all cases, check the return and reason codes of the indicated logger service routine for additional information.
## Abend codes
`U0001`: The parameter on the EXEC statement could not be parsed.  Message MLG001I is issued.  See the description of message MLG001I for more information.

`U0002`: A request for a system logger service failed. Message MLG002I is issued.  See the description of message MLG002I for more information.

`U0003`: A request to open the output file failed.  Messages about the failure are issued by DPF. See the desription of those messages for more information.
