* START OF SPECIFICATIONS  ******************************************** 00010000
*                                                                     * 00020000
*01* MEMBER-NAME: IEAMDBL3                                            * 00030000
*                                                                     * 00040000
*02* DESCRIPTIVE-NAME: Sample program to read records from an         * 00050000
*                      Operations Log stream and convert them to      * 00060000
*                      DLOG format, and to delete records from    @TTC* 00070000
*                      the stream.                                    * 00080000
*                                                                     * 00090000
*********************************************************************** 00100000
*                                                                     * 00110018
*01* COPYRIGHT =                                                      * 00220000
*                                                                     * 00220118
*    Beginning of Copyright and License                               * 00220200
*                                                                     * 00220300
*    Copyright 2019 IBM Corp.                                         * 00220400
*                                                                     * 00220500
*    Licensed under the Apache License, Version 2.0 (the "License");  * 00220600
*    you may not use this file except in compliance with the License. * 00220700
*    You may obtain a copy of the License at                          * 00220800
*                                                                     * 00220900
*    http://www.apache.org/licenses/LICENSE-2.0                       * 00221000
*                                                                     * 00222018
*    Unless required by applicable law or agreed to in writing,       * 00223018
*    software distributed under the License is distributed on an      * 00224018
*    "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,     * 00225018
*    either express or implied.  See the License for the specific     * 00226018
*    language governing permissions and limitations under the License.* 00227018
*                                                                     * 00228018
*    End of Copyright and License                                     * 00229018
*                                                                     * 00230018
*********************************************************************** 00230118
*                                                                     * 00230200
*01* DISCLAIMER =                                                     * 00230300
*                                                                     * 00230400
*    This sample source is provided for tutorial purposes only. A     * 00240000
*    complete handling of error conditions has not been shown or      * 00250000
*    attempted, and this source has not been submitted to formal IBM  * 00260000
*    testing. This source is distributed on an 'as is' basis          * 00270000
*    without any warranties either expressed or implied.              * 00280000
*                                                                     * 00290000
*01* FUNCTION:                                                        * 00300000
*                                                                     * 00310000
*      This program is an example of how to use the services of the   * 00320000
*      MVS System Logger to retrieve and delete records from the      * 00330000
*      Operations Log stream.  In response to parameters, it can  @D2A* 00340000
*      read the records created in a given time span, convert     @D2A* 00350000
*      them from Message Data Block (MDB) format to Hard-copy Log @D2A* 00360000
*      format (JES3 DLOG), mapped by DSECT DLOGLINE, and write    @TTC* 00370000
*      the DLOG-format records to a file; and/or it can delete    @TTC* 00380000
*      all the records from the stream that were created prior    @TTC* 00390000
*      to a given date.                                           @TTC* 00400000
*                                                                 @TTA* 00401000
*      It is assumed the Operations Log (Operlog) contains JES2-  @TTA* 00402000
*      generated records.  Running this program against JES3-     @TTA* 00403000
*      generated records will produce incompatible format for     @TTA* 00404000
*      JES3 Global-generated messages.                            @TTA* 00405000
*                                                                 @D2A* 00410000
*      The parameters are as follows:                             @D2A* 00420000
*                                                                 @D2A* 00430000
*        COPY([start_date][,end_date]), DELETE(date)              @D2A* 00440000
*            (>nnn)                           (>nnn)              @D2A* 00450000
*                                                                 @D2A* 00460000
*      COPY:  Records are to be copied to the DLOG-format file.   @TTC* 00470000
*      If COPY is not specified, no records are copied.           @D2A* 00480000
*                                                                 @D2A* 00490000
*        start_date,end_date: The starting and ending dates of    @D2A* 00500000
*          the time span, both in the format YYYYDDD.  start_date @D2A* 00510000
*          must not be later than end_date.  end_date must not be @D2A* 00520000
*          later than today, the day the program runs.  The       @D2A* 00530000
*          default for start_date is the date of the oldest       @D2A* 00540000
*          record in the log stream, and for end_date is          @D2A* 00550000
*          yesterday, the day before the program runs.  If both   @D2A* 00560000
*          start_date and end_date are allowed to default, the    @D2A* 00570000
*          parentheses after COPY may be omitted. If you          @01C* 00580000
*          specify a start date of today, you must also specify   @01A* 00590000
*          the end date of today, otherwise the program will      @01A* 00600000
*          assume an end date of yesterday and abend.             @01A* 00610000
*                                                                 @D2A* 00620000
*        >nnn: Indicates that records dated more than nnn days    @D2A* 00630000
*          before today are to be copied.  The time span will     @D2A* 00640000
*          start with the date of the oldest record in the log    @D2A* 00650000
*          stream and end nnn+1 days before today (that is,       @D2A* 00660000
*          records dated more than nnn days before today will     @D2A* 00670000
*          be copied.  nnn is a number between zero and 999.      @D2A* 00680000
*          For example, if the program is run on May 25,          @D2A* 00690000
*          specifying "COPY(>3)" will copy records dated up to    @D2A* 00700000
*          and including May 21.  Note that >0 corresponds to     @D2A* 00710000
*          yesterday.  To copy today's records, you must use the  @D2A* 00720000
*          "[start_date][,end_date]" form and specify today as    @D2A* 00730000
*          the end date.                                          @D2A* 00740000
*                                                                 @D2A* 00750000
*      DELETE:  Records are to be deleted.  If DELETE is not      @D2A* 00760000
*      specified, no records are deleted.                         @D2A* 00770000
*                                                                 @D2A* 00780000
*        date:  The date of the newest record to be deleted from  @D2A* 00790000
*          the log stream.  All records dated on or before that   @D2A* 00800000
*          date will be deleted.  The date must not be later than @D2A* 00810000
*          today.  If the date specified is today, all records in @D2A* 00820000
*          the log stream will be deleted.                        @D2A* 00830000
*                                                                 @D2A* 00840000
*        >nnn: Indicates that records dated more than nnn days    @D2A* 00850000
*          before today are to be deleted.  nnn is a number       @D2A* 00860000
*          between zero and 999.  For example, if the program is  @D2A* 00870000
*          run on July 15, specifying "DELETE(>5)" will delete    @D2A* 00880000
*          records dated up to and including July 9.  Note that   @D2A* 00890000
*          >0 corresponds to yesterday.  To delete today's        @D2A* 00900000
*          records, you must use the "date" form and specify      @D2A* 00910000
*          today as the date.                                     @D2A* 00920000
*                                                                 @D2A* 00930000
*        If DELETE is specified, either the date or ">nnn" must   @D2A* 00940000
*        be given.                                                @D2A* 00950000
*                                                                 @D2A* 00960000
*      You may specify either COPY or DELETE or both.  If you     @D2A* 00970000
*      specify both they must be separated by a comma and may     @D2A* 00980000
*      appear in either order.  However, regardless of the order  @D2A* 00990000
*      in which the parameters are specified, the copy operation  @D2A* 01000000
*      will always occur before the delete.                       @D2A* 01010000
*                                                                 @D2A* 01020000
*      HCFORMAT: Specifies whether the output records (in JES3    @TTC* 01030000
*      DLOG format) should have a 2-digit or a 4-digit date.      @TTC* 01040000
*                                                                 @04A* 01050000
*        YEAR: A 2-digit year will appear in the output records.  @04A* 01060000
*          The DLOGLINE mapping will be used to map the JES3 DLOG @TTC* 01070000
*          format output records. If the HCFORMAT keyword is      @04A* 01080000
*          not specified HCFORMAT(YEAR) is the default.           @04A* 01090000
*                                                                 @D2A* 01100000
*        CENTURY: A 4-digit year will appear in the output        @04A* 01110000
*          records. The DLOGLINE mapping will be used to map the  @TTC* 01120000
*          JES3 DLOG format output records.                       @TTC* 01130000
*                                                                 @D2A* 01140000
*      An optional DD - JES3IN - can be used in the JCL to allow  @TTA* 01140400
*      for a more customized format.  (It is assumed that the     @TTA* 01140800
*      customer will use the same set of processors in JES2 as    @TTA* 01141200
*      were used in JES3.)  Two JES3 Initialization statements    @TTA* 01141600
*      are supported:                                             @TTA* 01142000
*                                                                 @TTA* 01142400
*      - MAINPROC                                                 @TTA* 01142800
*      - MSGROUTE                                                 @TTA* 01143200
*                                                                 @TTA* 01143600
*      Other statements, if provided, are ignored.  No error      @TTA* 01144000
*      messages for extranous statements or syntax errors found   @TTA* 01144400
*      are issued.                                                @TTA* 01144800
*                                                                 @TTA* 01145200
*      The MAINPROC is used to extract the format of the Receive  @TTA* 01145600
*      id for each processor defined in the configuration.  The   @TTA* 01146000
*      MSGROUTE is used to determine what JES3 Destination code   @TTA* 01146400
*      and/or console name should be displayed on the output line @TTA* 01146800
*      based on the routing code.                                 @TTA* 01147200
*                                                                 @TTA* 01147600
*      If neither statement is provided, the receive id will be   @TTA* 01148000
*      the same as system name.  The routing code will be used    @TTA* 01148400
*      to display the JES3 Destination class with no further      @TTA* 01148800
*      changes.                                                   @TTA* 01149200
*                                                                 @TTA* 01149600
*      Warning:  When copying records, this program detects the   @D2A* 01150000
*      end of a day's records when it either reads the first      @D2A* 01160000
*      record for the next day or attempts to read past the       @D2A* 01170000
*      newest record in the log stream.  This means that, if      @D2A* 01180000
*      end_date is today and the log stream is being written at   @D2A* 01190000
*      the time this program runs, the records that are copied    @D2A* 01200000
*      may not be predictable.  In particular, if both COPY with  @D2A* 01210000
*      an ending date of today and DELETE with a date of today    @D2A* 01220000
*      are specified, there may be more records deleted than      @D2A* 01230000
*      copied.                                                    @D2A* 01240000
*                                                                 @D2A* 01250000
*      Warning:  When the ">nnn" form of the COPY or DELETE       @D2A* 01260000
*      parameter is specified, program converts it to a date by   @D2A* 01270000
*      subtracting nnn days from the date the program is run.     @D2A* 01280000
*      The calculation is done once, at the beginning of the      @D2A* 01290000
*      program.  If the program is run shortly before midnight,   @D2A* 01300000
*      so that the calculation occurs before midnight and the     @D2A* 01310000
*      actual copying or deletion of records occurs after         @D2A* 01320000
*      midnight, the records copied or deleted will not reflect   @D2A* 01330000
*      the number of days specified.  To prevent this, you should @D2A* 01340000
*      avoid running the program close to midnight with the       @D2A* 01350000
*      ">nnn" form.                                               @D2A* 01360000
*                                                                 @D2A* 01370000
*      Note that if the program is run regularly after midnight   @D2A* 01380000
*      with the parameter "COPY(>0),DELETE(>1)", it will copy     @D2A* 01390000
*      records from the previous day and earlier, and will delete @D2A* 01400000
*      from the records from two days ago, leaving something over @D2A* 01410000
*      24 hours' worth of records in the log each time.           @D2A* 01420000
*                                                                 @D2A* 01430000
*      Limitations:                                                   * 01440000
*                                                                     * 01450000
*      (1) The selection of records uses the internal timestamp of    * 01460000
*          log stream records, which corresponds to the time of the   * 01470000
*          request to write the record to the stream.  It is possible * 01480000
*          for records to be out of sequence in the log, in which     * 01490000
*          case the records ostensibly for a given day may include    * 01500000
*          some from the previous or next day.  Moreover, the         * 01510000
*          timestamp in an MDB is not necessarily the same as that of * 01520000
*          the internal log stream record.                            * 01530000
*                                                                     * 01540000
*          Therefore the selection by date is no better than an       * 01550000
*          approximation.                                             * 01560000
*                                                                     * 01570000
*          However, the set of records selected for a given day will  * 01580000
*          be unique.                                                 * 01590000
*                                                                     * 01600000
*      (2) Records could be missing based on prior                @01A* 01610000
*          activities. In these cases, a message will be          @01A* 01620000
*          written to the output file with a unique format to     @01A* 01630000
*          identify it. This will be done for record gaps         @01A* 01640000
*          or deletions found at the beginning or end of the      @01A* 01650000
*          data, or any place in the middle. If the special       @01A* 01660000
*          messages would interfere with any applications using   @01A* 01670000
*          the output, adjust or remove the code as appropriate.  @01A* 01680000
*                                                                 @01A* 01690000
*01* OPERATION:                                                       * 01700000
*                                                                     * 01710000
*********************************************************************** 01720000
*                                                                     * 01730000
* Initialization:                                                     * 01740000
*                                                                     * 01750000
*  If COPY was specified, get end and start dates or calculate    @D2A* 01760000
*  defaults, yesterday and "oldest" respectively.                 @D2A* 01770000
*                                                                 @D2A* 01780000
*  If DELETE was specified, get delete date.                      @D2A* 01790000
*                                                                     * 01800000
*  If HCFORMAT was specified, set the appropriate flags to        @04A* 01810000
*  indicate if HCFORMAT(YEAR) or HCFORMAT(CENTURY) was            @04A* 01820000
*  specified.                                                     @04A* 01830000
*                                                                     * 01840000
*  Open the JES3IN DD, if present, and parse the MAINPROC and     @TTA* 01842000
*  MSGROUTE initialization statements.  Build tables to be used   @TTA* 01844000
*  during output formatting.                                      @TTA* 01846000
*                                                                 @TTA* 01848000
*  Obtain a buffer area for logger record and set up its base         * 01850000
*                                                                     * 01860000
*  Connect to the log stream                                          * 01870000
*                                                                     * 01880000
*********************************************************************** 01890000
*                                                                     * 01900000
* Copy:                                                           @D2A* 01910000
*                                                                 @D2A* 01920000
*  If COPY was specified:                                         @D2A* 01930000
*                                                                 @D2A* 01940000
*   Start a log stream browse session and position the log stream @D2A* 01950000
*   to first record in the range                                  @D2A* 01960000
*                                                                 @D2A* 01970000
*   Copy loop:                                                    @D2A* 01980000
*                                                                     * 01990000
*    Read successive records from the stream, starting with the       * 02000000
*    earliest record bearing the start date and ending with the       * 02010000
*    latest record on or before the end date                          * 02020000
*                                                                 @01A* 02030000
*    If the return and reason code indicates a gap in records     @01A* 02040000
*    or deleted records, show this by adding a special message    @01A* 02050000
*    to the output file.                                          @01A* 02060000
*                                                                     * 02070000
*    For each record (MDB) that is read:                              * 02080000
*                                                                     * 02090000
*     Get the general and CP objects                                  * 02100000
*                                                                     * 02110000
*     Extract the fixed info                                          * 02120000
*                                                                     * 02130000
*     For every line (text object) in the message:                    * 02140000
*                                                                     * 02150000
*      Write a DLOG-format line to the output file                @TTC* 02160000
*                                                                     * 02170000
*      If line was too long, also write a continuation line           * 02180000
*                                                                     * 02190000
*   End the log stream browse session                                 * 02200000
*                                                                     * 02210000
*   Close the output file                                             * 02220000
*                                                                     * 02230000
*                                                               6#@TTD* 02231001
*                                                                     * 02240000
*********************************************************************** 02250000
* Delete:                                                         @D2A* 02260000
*                                                                 @D2A* 02270000
*  If delete was specified:                                       @D2A* 02280000
*                                                                 @D2A* 02290000
*   Start a log stream browse session and position the log stream @D2A* 02300000
*   to oldest record to be kept                                   @D2A* 02310000
*                                                                 @D2A* 02320000
*   Delete all records prior to that position                     @D2A* 02330000
*                                                                 @D2A* 02340000
*   End the log stream browse session                             @D2A* 02350000
*                                                                 @D2A* 02360000
*********************************************************************** 02370000
* HCFORMAT:                                                       @04A* 02380000
*                                                                 @04A* 02390000
*  If HCFORMAT was specified:                                     @04A* 02400000
*                                                                 @04A* 02410000
*  If HCFORMAT(CENTURY) was specified the output records will     @04A* 02420000
*  have a 4-digit date and the HCR mapping will be used to map    @04A* 02430000
*  the records, otherwise the output records will have a 2-digit  @04A* 02440000
*  date and the HCL mapping will be used to map the records.      @04A* 02450000
*                                                                     * 02460000
*********************************************************************** 02470000
*                                                                     * 02480000
* Cleanup:                                                            * 02490000
*                                                                     * 02500000
*  Disconnect from the log stream                                     * 02510000
*                                                                     * 02520000
*  Free the buffer area                                               * 02530000
*                                                                     * 02540000
*  Exit                                                               * 02550000
*                                                                     * 02560000
*********************************************************************** 02570000
*                                                                     * 02580000
* Sample Invocation Jobs:                                         @D2C* 02590000
*                                                                     * 02600000
* (1) Using YYYYDDD format parameters, and having a 2-digit year  @04C* 02610000
*     in the output records.                                      @04A* 02620000
*                                                                 @D2A* 02630000
*   //jjj     JOB  ...                                                * 02640000
*   //sss     EXEC PGM=IEAMDBL3,                                  @D2C* 02650000
*   //        PARM='COPY(2021182),DELETE(2021181),HCFORMAT(YEAR)' @TTC* 02660000
*   //DLOG    DD   DSN=ALL.DLOGS(+1),                             @TTC* 02670000
*   //             DISP=(NEW,CATLG,DELETE),                           * 02680000
*   //             DCB=BLKSIZE=22880                                  * 02690000
*   //JES3IN  DD   DSN=JES3.INIT.STREAM,DISP=SHR                  @TTA* 02695000
*                                                                     * 02700000
*   NOTE: This example job will copy records created between July @TTC* 02710000
*         1, 2021, and "yesterday", inclusive, and will delete    @TTC* 02720000
*         from the log stream any records created on or before        * 02730000
*         June 30, 2021. The date part of the output records will @TTC* 02740000
*         have a 2-digit year.                                    @TTC* 02750000
*                                                                 @D2A* 02760000
* (2) Using >nnn format parameters, and having a 4-digit year     @04C* 02770000
*     in the output records.                                      @04A* 02780000
*                                                                 @D2A* 02790000
*   //jjj     JOB  ...                                            @D2A* 02800000
*   //sss     EXEC PGM=IEAMDBL3,                                  @D2A* 02810000
*   //             PARM='COPY(>5),DELETE(>8),HCFORMAT(CENTURY)'   @04C* 02820000
*   //DLOG    DD   DSN=ALL.DLOGS(+1),                             @TTC* 02830000
*   //             DISP=(NEW,CATLG,DELETE),                       @D2A* 02840000
*   //             DCB=BLKSIZE=22880                              @D2A* 02850000
*   //JES3IN  DD   DSN=JES3.INIT.STREAM,DISP=SHR                  @TTA* 02855000
*                                                                 @D2A* 02860000
*   NOTE: Assuming it is run on July 15, this example job will    @D2A* 02870000
*         copy records created on or before July 9, and will      @D2A* 02880000
*         delete from the log stream any records created on or    @D2A* 02890000
*         before July 6. The date part of the output records      @04C* 02900000
*         will have a 4-digit year.                               @04A* 02910000
*                                                                     * 02920000
* ENTRY POINT      = IEAMDBL3                                         * 02930000
*   PURPOSE        = Copy records from an operations log stream to a  * 02940000
*                    sequential file in DLOG format, and delete   @TTC* 02950000
*                    records from the operations log.                 * 02960000
*   LINKAGE        = BRANCH                                           * 02970000
*   INPUT          = Whether records are to be copied, and if so  @D2A* 02980000
*                    the starting and ending dates of the         @D2C* 02990000
*                    interval of records to copy; and whether     @D2C* 03000000
*                    records are to be deleted, and if so the     @D2A* 03010000
*                    date of the newest record to delete.         @D2A* 03020000
*                                                                     * 03030000
*   REGISTERS SAVED= NONE                                             * 03040000
*   REGISTER USAGE = R1 - Address of a fullword pointer to the        * 03050000
*                         parameter area.  The parameter area is on a * 03060000
*                         halfword boundary, and consists of a        * 03070000
*                         halfword length of the parameter followed   * 03080000
*                         by the parameter.                       @D2C* 03090000
*                                                                     * 03100000
*                    R14 - Return address.                            * 03110000
*   REGISTERS RESTORED                                                * 03120000
*                  = NONE                                             * 03130000
*                                                                     * 03140000
*01* RECOVERY OPERATION:                                              * 03150000
*                                                                     * 03160000
*    None.  This program make no attempt to recover from failures.    * 03170000
*    The caller's recovery environment, if any, will remain in        * 03180000
*    effect. For any abend other than one of the user abends      @01C* 03190000
*    issued normally by this program, you should check the output @01A* 03200000
*    file for any additional information.                         @01A* 03210000
*                                                                     * 03220000
*    If additional levels of recovery are needed for particular       * 03230000
*    environments, the program must be modified and reassembled.      * 03240000
*                                                                     * 03250000
*01*  SYSTEM BUILD INFORMATION                                        * 03260000
*              LOAD MODULE               =  IEAMDBL3                  * 03270000
*              DISTRIBUTION LIBARY       =  SYS1.ASAMPLIB             * 03280000
*              SYSGEN MAC                =  none                      * 03290000
*              ALIAS NAME                =  none                      * 03300000
*              ENTRY POINT               =  IEAMDBL3                  * 03310000
*              PAGE BOUNDARY             =  NO                        * 03320000
*              TARGET LIBRARY            =  Any                       * 03330000
*              ASSEMBLER LIBRARIES       =  SYS1.MACLIB,              * 03340000
*                                           SYS1.AMODGEN              * 03350000
*              LINKAGE EDITOR ATTRIBUTES =  REUS                      * 03360000
*              AMODE                     =  31                        * 03370000
*              RMODE                     =  31                    @TTC* 03380000
*                                                                     * 03390000
*    NOTES     =                                                  @01A* 03400000
*                                                                 @01A* 03410000
*            - This program makes use of logger service routines. @01A* 03420000
*              Changes to these service routines (e.g. new return @01A* 03430000
*              or reason codes) may necessitate changes to this   @01A* 03440000
*              program.                                           @01A* 03450000
*                                                                     * 03460000
*            - This program must be link edited as Non-Reentrant, @PCA* 03461000
*              since this program uses global variables which     @PCA* 03463000
*              allow for it to modify its own storage. To make    @PCA* 03464000
*              the link edit job Non-Reentrant remove RENT from   @PCA* 03464100
*              the PARM= statement.                                     03464200
*              - Example JCL:                                     @PCA* 03465000
*                                                                 @PCA* 03465100
*         //*---------------------------------------------------- @PCA* 03465600
*         //LNKLPA  EXEC PGM=linkproc,PARM='MAP,LET,LIST,NORENT'  @PCA* 03465700
*         //SYSLMOD DD   DSN=linked.userlib,DISP=SHR              @PCA* 03465900
*         //SYSUT1  DD   UNIT=SYSDA,SPACE=(CYL,(3,2)),DSN=&SYSUT1 @PCA* 03466000
*         //SYSPRINT DD  SYSOUT=*,DCB=(RECFM=FB,BLKSIZE=3509)     @PCA* 03466100
*         //DR1     DD   DSN=assem.ieamdbl3.obj,DISP=SHR          @PCA* 03466200
*         //SYSLIN  DD   *                                        @PCA* 03466900
*         ******************************************************* @PCA* 03467000
*         *       IEAMDBL3 Sample program                         @PCA* 03467300
*         ******************************************************* @PCA* 03467500
*                      INCLUDE DR1(IEAMDBL3)                      @PCA* 03467700
*                      ENTRY IEAMDBL3                             @PCA* 03467800
*                     NAME IEAMDBL3(R) RC=0                       @PCA* 03467900
*                                                                 @PCA* 03468000
*                                                                     * 03469000
*01* MESSAGES  =                                                      * 03470000
*    The following messages are displayed on the issuing console  @01A* 03480000
*                                                                     * 03490000
*    MLG001I INVALID OR MISSING PARAMETER                         @D2C* 03500000
*                                                                     * 03510000
*      Meaning: The parameter on the EXEC statement statement could   * 03520000
*               not be parsed.  The program will abend with           * 03530000
*               completion code U0001.  Correct the parameter and     * 03540000
*               rerun the step.                                       * 03550000
*                                                                     * 03560000
*                                                                     * 03570000
*    MLG002I ERROR DURING SYSTEM LOGGER rrrrrrrr-n,               @P6C* 03580000
*            RETURN CODE xxx, REASON CODE yyyy                        * 03590000
*                                                                     * 03600000
*      Meaning: A request to a System Logger service failed.  The     * 03610000
*               program will abend with completion code U002.  The    * 03620000
*               failing service is identified by "rrrrrrrr", which    * 03630000
*               may be "IXGCONN", "IXGBRWSE", or "IXGDELET".          * 03640000
*               If there is more than one invocation of the       @P6C* 03650000
*               service, the invocation that failed is indicated  @P6C* 03660000
*               by "-n", where n is a number that identifies the  @P6C* 03670000
*               instance.                                         @P6C* 03680000
*               "xxx" is the return code and "yyyy" the reason code.  * 03690000
*               See the documentation of the system logger services,  * 03700000
*               correct the problem, and rerun the step.              * 03710000
*                                                                     * 03720000
*                                                                     * 03730000
*    MLG003I NO RECORDS IN RANGE                                      * 03740000
*                                                                     * 03750000
*      Meaning: There were no records in the operations log stream    * 03760000
*               created between the starting and ending dates,        * 03770000
*               inclusive.  The program will continue.  Any records   * 03780000
*               in the log stream that are eligible for deletion will * 03790000
*               be deleted.  The output file will be empty.           * 03800000
*                                                                 @01A* 03810000
*    MLG004I LOG STREAM IS EMPTY                                  @03A* 03820000
*                                                                 @03A* 03830000
*      Meaning: The return from IXGBRWSE has indicated that there @03A* 03840000
*               are no records in the log stream.                 @03A* 03850000
*                                                                     * 03860000
*    The following message is issued to the output file           @01A* 03870000
*                                                                 @01A* 03880000
*    ILG0001 RECORDS NOT AVAILABLE. IXGxxxxx-nn RETURN CODE nnn,  @01A* 03890000
*      REASON CODE nnnn                                           @01A* 03900000
*                                                                 @01A* 03910000
*      Meaning: The return and reason codes from a log stream     @01A* 03920000
*               service routine indicate that data may be missing @01A* 03930000
*                                                                 @01A* 03940000
*               the -nn at the end of the service routine name    @01A* 03950000
*               identifies the specific instance of the routine   @01A* 03960000
*               invoked at which point the unavailable records    @01A* 03970000
*               were detected.                                    @01A* 03980000
*                                                                 @01A* 03990000
*               If the service routine is IXGCONN, then the       @01A* 04000000
*               service routine has indicated that data may be    @01A* 04010000
*               missing.                                          @01A* 04020000
*                                                                 @01A* 04030000
*               If the service routine is IXGBRWSE, then one of   @01A* 04040000
*               the following has probably occurred.              @01A* 04050000
*                                                                 @01A* 04060000
*               - A gap has been found in records immediately     @01A* 04070000
*                 prior to the first record found meeting         @01A* 04080000
*                 selection criteria.                             @01A* 04090000
*               - Records had previously been deleted immediately @01A* 04100000
*                 prior to the first record found meeting         @01A* 04110000
*                 selection criteria.                             @01A* 04120000
*               - There was a gap or deleted records between two  @01A* 04130000
*                 records within selection criteria.              @01A* 04140000
*               - A gap or deleted records immediately follow     @01A* 04150000
*                 the last record meeting criteria. This routine  @01A* 04160000
*                 then either encountered end of file, or the     @01A* 04170000
*                 next record was out of selection criteria.      @01A* 04180000
*               - records could be permanently missing from the   @01A* 04190000
*                 log stream.                                     @01A* 04200000
*                                                                 @01A* 04210000
*               In all cases, check the return and reason codes   @01A* 04220000
*               of the indicated logger service routine for       @01A* 04230000
*               additional information.                           @01A* 04240000
*                                                                     * 04250000
*01* ABEND CODES =                                                    * 04260000
*                                                                     * 04270000
*    U0001      The parameter on the EXEC statement could not be      * 04280000
*               parsed.  Message MLG001I is issued.  See the          * 04290000
*               description of message MLG001I for more information.  * 04300000
*                                                                     * 04310000
*    U0002      A request for a system logger service failed.         * 04320000
*               Message MLG002I is issued.  See the description of    * 04330000
*               message MLG002I for more information.                 * 04340000
*                                                                     * 04350000
*    U0003      A request to open the output file failed.  Messages   * 04360000
*               about the failure are issued by DPF.  See the         * 04370000
*               desription of those messages for more information.    * 04380000
*                                                                     * 04390000
* *01*  CHANGE ACTIVITY =                                             * 04400000
*                                                                     * 04410000
* $MOD(IEAMDBLG), COMP(SC1CK): SAMPLE PROGRAM TO CONVERT OPERLOG RECS * 04420000
* $L0=OPLOG7DG HBB5520  940331  PDDG: ORIGINAL MODULE                 * 04430000
* $D1=DN70048  HBB5520  940603  PDDG: GET CONSNAME, MCSFLAGS FROM MDB * 04440000
* $P1=PN71025  HBB5520  940713  PDCM: USE LOCAL TIME, NOT GMT         * 04450000
* $P2=PN71000  HBB5520  940727  PDCM: PROLOG CLARIFICATIONS           * 04460000
* $P3=PN70702  HBB5520  940803  PDDG: REMOVE DMTI MACRO REFERENCE     * 04470000
* $D2=DN70103  HBB5520  941108  PDDG: SEPARATE COPY AND DELETE PARMS  * 04480000
* $P4=PN72038  HBB5520  941108  PDDG: ADD MULTILINE ID TO MAJOR LINE  * 04490000
* $P5=PN72143  HBB5520  941219  PDDG: MSG MLG002 HAS WRONG LENGTH     * 04500000
* $P6=PN72276  HBB5520  950105  PDDG: FAILS W/RC 403 FROM IXGBRWSE    * 04510000
* $01=OW12221  HBB5520  950221  PDCM: GAPS NOT INDICATED              * 04520000
* $02=OW13278  HBB5520  950511  PDCM: NO DELETE IF FULL DIRECTORY     * 04530000
* $03=OW14366  HBB5520  950718  PDCM: Issue OPEN before IXGCONN.      * 04540000
*                                     Don't abend on empty stream     * 04550000
* $04=OW18292  HBB5510  960215  PDHL: Year 2000 Support               * 04560000
* $P7=PQC0781  HBB6603  960905  PDCM: Fails w/RC 405 from IXGBRWSE    * 04570000
* $P8=PYM0069  HBB7706  010401  PDKP: Fix PUT interfaces              * 04580000
* $P9=PYV0223  HBB7707  011210  PDCM: Don't abend IXGBRWSE RC8 RS0804 * 04590000
* $L1=CNZ2A    HBB7730  040618  PDD0: 1-Byte Console Id Removal Part2 * 04600000
* $L2=DCRA990  HBB7730  050525  PDKX: Skip MDB if MDB has been sent   * 04601000
*                                     from USS                        * 04602000
* $PA=ME06901  HBB7740  060616  PDKP: Missing issuing console name    * 04603000
* $PB=ME07925  HBB7740  060925  PDSS: Correct copyright               * 04603100
* $05=OA29939  HBB7770  090930  PDSW: Multi-line WTO message problems * 04603200
*                                     when spanning more than one MDB * 04603300
* $PC=ME16085  HBB7770  090930  PDSW: IEAMDBLG Prolog updates         * 04603400
* $PD=ME17166  HBB7770  091015  PDSW: Character translation to convert* 04603500
*                                     unreadable characters to blanks * 04603600
*                                     and DBCS Shifts to either < or >* 04603700
* $06=OA47714  HBB7780  151113  PDHB: MLID formatting confusion.  @06A* 04603800
* $TT=W334216  HBB77C0  190731  PDPK: Replaced SYSLOG format by   @TTA* 04603918
*                                     DLOG                        @TTA* 04604000
*                                                                     * 04604100
****END OF SPECIFICATIONS********************************************** 04605000
*                                                                       04606000
* READCOK - (C) Use Local time instead of GMT for comparisons     @P1C* 04607000
* Prolog  - (c) Clarification of prolog to not use tool to get    @P2A* 04608000
*           today's output - results in U002 abend.               @P2A* 04609000
* CHKMCS  - (d) Remove code to address UCM and test for JES3      @P3A* 04610000
* Dsects  - (d) Remove mapping macro for UCM                      @P3A* 04620000
* Initialization - (c) Allow new parm format COPY(),DELETE()      @D2A* 04630000
* COPYLOOP - (c) Separate copy operation from delete              @D2A* 04640000
* NOTCOPY - (a) Position log browse session and delete records    @D2A* 04650000
* FIXDATE - (a) New subroutine for parsing parameters             @D2A* 04660000
* CONVSTCK - (a) New subroutine for parsing parameters            @D2A* 04670000
* CPRC    - (a) Save descriptor codes                             @P4A* 04680000
* WTLOK   - (c) Set RDW for WTL to correct length                 @P4A* 04690000
* TXTLP   - (c) Fix up split point                                @P4A* 04700000
* TXTDN   - (a) Add multiline ID to the text                      @P4A* 04710000
* PNOTCOPY- (c) Fix length on test for min. length (10)           @P5A* 04720000
* BADPMSG - (c) Add LOGRMSGD label to compute msg data length     @P5A* 04730000
* OPENOK  - (c) Allow for gap in IXGBRWSE START for COPY          @P6A* 04740000
* NOTCOPY - (c) Allow for gap in IXGBRWSE START for DELETE        @P6A* 04750000
* DPOINTOKL (c) Allow for gap in IXGBRWSE READCURSOR for DELETE   @P6A* 04760000
* LOGRMSGT  (c) Add footprint to logger service error msg         @P6A* 04770000
* IXGxxx macros (c) Test for good completion using IXGRETCODEOK   @P6A* 04780000
* OBJLP     (a) Handle gaps in records or deleted records         @01A* 04790000
* OPENOK    (c) Handle delete request when directory full occurs  @02A* 04800000
* GAPMSG    (a) Bypass issuing message to output file if there is @02A* 04810000
*               no output file (possible on DELETE request)       @02A* 04820000
* CONNOK    (c) Move OPEN of output file before IXGCONN-1. That   @03A* 04830000
*           way, if any recoverable errors are detected for a     @03A* 04840000
*           COPY request, they can be written to the output file. @03A* 04850000
* CONNOK    (a) If return from IXGBRWSE-1 indicates empty stream, @03A* 04860000
*           don't abend. Instead, issue message.                  @03A* 04870000
*           (a) Added support for the new HCFORMAT keyword. The   @04A* 04880000
*           output records will have a 4-digit year if            @04A* 04890000
*           HCFORMAT(CENTURY) is specified. The output records    @04A* 04900000
*           will have a 2-digit year if HCFORMAT(YEAR) is         @04A* 04910000
*           specified or if the HCFORMAT keyword is not specified @04A* 04920000
*           at all.                                               @04A* 04930000
* NOTCOPY   Tolerate IXGRsnCodeLossOfData reason code 405         @P7A* 04940000
* PUT macros (c) Change the PUT interfaces to run in 31 bit AMODE @P8A* 04950000
* DELDONE   On IXGBRWSE REQUEST=END, accept RC8 RS0804 (No block) @P9A* 04960000
*           and do not issue AbendU0002. This condition is        @P9A* 04970000
*           acceptable by logger as all data is older than the    @P9A* 04980000
*           specified time stamp.                                 @P9A* 04990000
* NOTINTL4, NOTINTL (D) Remove check for MDBMCSH (sent by QREG 0) @L1A* 05000000
* CPROK,CPROK4,NOTCMD,NOTCMD4    Add request type of U for        @L1A* 05010000
*           command echo from the unknown console id.             @L1A* 05020000
* NOTG      (a) Add support for USS Msg Integration to write      @L2A* 05030000
*           Messages to operlog.                                  @L2A* 05040000
* CPRSP,CPRSP4 (c) Incorrect branch instruction caused blanks to  @PAA* 05050000
*           go into HCLCONID (issuing console) for a command      @PAA* 05060000
*           response message for a command issued by an MCS       @PAA* 05070000
*           console.                                              @PAA* 05080000
* PROCLINE (A) Add an additional check to see if the current      @05A* 05081000
*           Message Line ID (MLID) is the same as the previous    @05A* 05082000
*           MLID.  If so, then make sure we do not skip over      @05A* 05082100
*           setting up the type correctly.                        @05A* 05083000
* PROCLINE (A) Add additional checks to the procedure to help     @05A* 05084000
*           verify when it is a multiline message with additional @05A* 05084100
*           connect lines to make sure the MLID is added to the   @05A* 05084200
*           end of the major line.                                @05A* 05084300
* PROLOG (A) Add additional comments to the prolog that will      @PCA* 05085000
*           describe the how a user can update the sample to      @PCA* 05086000
*           convert its format from OPERLOG to JES3 DLOG for      @PCA* 05087000
*           jobnames.                                             @PCA* 05087100
* OBJLP  (A) Add comments and code to indicate the field need to  @PCA* 05087200
*           convert the log stream into a SYSLOG format to        @PCA* 05087300
*           convert the log stream into a JES3 DLOG jobname       @PCA* 05087400
*           format. See eye catcher JES3Jobname.                  @PCA* 05087500
* PROLOG (A) Add additional comments to indicate that IEAMDBLG    @PCA* 05088000
*           must be setup as NON-REENTRANT (NORENT), otherwise    @PCA* 05089000
*           0C4-abend can occur.                                  @PCA* 05089100
* PUTREC (A) Add a translation step to translate unreadable chars @PDA* 05089200
*           to blanks and DBCS shift-out and shift-in to < and >. @PDA* 05089300
* PROCLINE (C) Rearranged the check added with OA29939 (@05) to avoid   05089400
*              erroneously 'merging' sequential message lines that      05089500
*              have the same Message Line ID (MLID) (usually from       05089600
*              different systems, possibly from the same).              05089700
*            - OA29939 overlooked identical MLIDs from different        05089800
*              systems in sequential order.                        @06A 05089900
*                                                                       05090000
*********************************************************************** 05091000
         SYSSTATE ARCHLVL=2        Allow macro jumpification       @TTA 05095000
IEAMDBL3 CSECT ,                                                        05100000
*                                                                     * 05110000
*                                                                     * 05130000
IEAMDBL3 AMODE 31                                                       05140000
IEAMDBL3 RMODE 31                                                  @TTC 05150000
MDBLGCOD LOCTR                     Start code segment              @TTA 05152000
MDBLGDAT LOCTR                     Start data segment              @TTA 05154000
         DC    0D'0',CL8'MDBLGDAT' Tag the storage                 @TTA 05156000
MDBLGCOD LOCTR                                                     @TTA 05158000
*********************************************************************** 05160000
* begin linkage                                                       * 05170000
*********************************************************************** 05180000
         BAKR  R14,0               Save registers                  @TTC 05190000
*                                                                  @TTD 05200000
         MODID ,                   Eye catcher and date            @TTC 05210000
         LARL  R12,MDBLGDAT        Data segment base               @TTA 05212000
         USING MDBLGDAT,R12        Set up data addressability      @TTA 05214000
         L     R9,0(R1,0)          save parm addr                       05220000
*                                                                7#@TTD 05230000
         LA    R13,SV              Point R13 to save area          @TTC 05300000
         MVC   4(4,R13),=C'F1SA'   set acro in save area                05310000
*********************************************************************** 05320000
* end linkage                                                         * 05330000
*********************************************************************** 05340000
         USING PSA,R0              Set up PSA addressability       @TTA 05345000
*                                                                       05350000
*********************************************************************** 05360000
* Begin initialization                                                * 05370000
*********************************************************************** 05380000
*                                                                       05390000
*********************************************************************** 05400000
*  If COPY was specified, get end and start dates or calculate    @D2A* 05410000
*  defaults, yesterday and "oldest" respectively.                 @D2A* 05420000
*                                                                 @D2A* 05430000
*  If DELETE was specified, get delete date.                      @D2A* 05440000
*  If HCFORMAT was specified, set the appropriate flag.           @04A* 05450000
*********************************************************************** 05460000
*                                                                       05470000
*  R9 -> parm                                                      @D2A 05480000
*                                                                       05490000
*  Results:                                                             05500000
*    PFLAGS -- DELETE flag set if DELETE was specified,            @D2A 05510000
*              COPY flag set if COPY was specified,                @D2A 05520000
*              HCFORMAT flag set if HCFORMAT was specified,        @04A 05530000
*              YEAR flag set if the HCFORMAT keyword was not       @04A 05540000
*                   specified (YEAR is the default), or if         @04A 05550000
*                   HCFORMAT(YEAR) was specified,                  @04A 05560000
*              CENTURY flag set if HCFORMAT(CENTURY) was specified @04A 05570000
*    MFLAGS - All flags initialized as off                         @01A 05580000
*    SDATE - If COPY is specified, the specified starting date or  @D2C 05590000
*            default to 1900001; otherwise zero                    @D2C 05600000
*    EDATE - If COPY is specified, the day after the specified     @D2C 05610000
*            ending date or default to today;otherwise zero        @D2C 05620000
*    DDATE - If DELETE is specified, the day after the deletion    @D2C 05630000
*            date; otherwise zero                                  @D2C 05640000
*    SSTCK, ESTCK, and DSTCK are the same dates in STCK format.         05650000
*    COPYDAYS - If COPY(>nnn) is specified, the number of days     @D2A 05660000
*            nnn; otherwise binary zero                            @D2A 05670000
*    DELDAYS  - If DELETE(>nnn) is specified, the number of days   @D2A 05680000
*            nnn; otherwise binary zero                            @D2A 05690000
*           ``                                                          05700000
*                                                                  @TTD 05710000
         MVI   PFLAGS,YEAR         Set the default flag if the     @TTC*05720000
                                   the HCFORMAT keyword is not         *05730000
                                   specified (YEAR is the default).    *05740000
                                                                   @04A 05750000
         MVI   MFLAGS,0            clear out miscellaneous flags   @01A 05760000
         XC    SDATE,SDATE         clear out start date                 05770000
         XC    EDATE,EDATE         clear out end date                   05780000
         XC    DDATE,DDATE         clear out del date                   05790000
         XC    COPYDAYS,COPYDAYS   clear out number of days        @D2A 05800000
         XC    DELDAYS,DELDAYS     clear out number of days        @D2A 05810000
         LH    R3,0(R9)            length of parm                  @D2A 05820000
         LA    R9,2(R9)            get past length                      05830000
         CHI   R3,0                is there a parm?                @TTC 05840000
         JE    BADPARM             no, error (parm is required)    @D2A 05850000
         CHI   R3,256              is it too long (for TRT)?       @TTC 05860000
         JNH   PLENOK              no, ok                          @D2A 05870000
BADPARM  LA    R2,BADPMSG          point to parm error msg              05880000
         JAS   R14,MESSR           display it                           05890000
         ABEND 1,DUMP              abend                                05900000
PLENOK   DS    0H                                                  @D2A 05910000
PLOOP    DS    0H                                                  @D2A 05920000
*        loop through parameter processing each entry              @D2A 05930000
*        r9 = address of remaining parm                            @D2A 05940000
*        r3 = length of remaining parm                             @D2A 05950000
         LR    R14,R9              initial starting point          @D2A 05960000
PLOOPR   DS    0H                                                  @D2A 05970000
*        resume the scan                                           @D2A 05980000
*        r14 = address of resume point                             @D2A 05990000
         LA    R1,0(R3,R9)         point past parm (in case there  @D2AX06000000
                                   is no comma)                    @D2A 06010000
         LR    R15,R1              end of parm + 1                 @D2A 06020000
         SR    R15,R14             subtract start addr to get len  @D2A 06030000
         BCTR  R15,0               subtract 1 to get machine len   @D2A 06040000
         SR    R2,R2               clear reg. for character found  @D2A 06050000
         EX    R15,TRT1            scan the parm; r1 will point to     X06060000
                                   comma or lt paren or end+1 of parm  X06070000
                                                                   @D2A 06080000
         C     R2,ZLPAREN          did it stop on left paren?      @D2A 06090000
         JNE   PSCANOK             no, ok                          @D2A 06100000
*        scan to right paren                                       @D2A 06110000
         LA    R15,0(R3,R9)        end of parm + 1                 @D2A 06120000
         SR    R15,R1              subtract start addr to get len  @D2A 06130000
         EX    R15,TRT2            scan to right paren             @D2A 06140000
         JZ    BADPARM             error if not found              @D2A 06150000
         LR    R14,R1              set resume address              @D2A 06160000
         J     PLOOPR              resume the scan                 @D2A 06170000
PSCANOK  DS    0H                                                  @D2A 06180000
         LR    R4,R1               save pointer to comma or end    @D2A 06190000
         SR    R4,R9               length of this parm entry       @D2A 06200000
*                                                                  @D2A 06210000
*        interpret and process a parm entry                        @D2A 06220000
*        r9 = address of parm entry                                @D2A 06230000
*        r4 = length of parm entry                                 @D2A 06240000
         CHI   R4,4                is length at least 4 ("COPY")?  @TTC 06250000
         JL    BADPARM             no, error                       @D2A 06260000
         CLC   =C'COPY',0(R9)      is it COPY?                     @D2A 06270000
         JNE   PNOTCOPY            no                              @D2A 06280000
         TM    PFLAGS,COPY         was COPY already processed?     @D2A 06290000
         JO    BADPARM             yes,error                       @D2A 06300000
         OI    PFLAGS,COPY         set COPY flag                   @D2A 06310000
         CHI   R4,5                is length 5?                    @TTC 06320000
         JL    PNEXT               length less than 5, must be 4,      X06330000
                                   'COPY', use defaults            @D2A 06340000
         JE    BADPARM             length 5, error                 @D2A 06350000
         CLI   4(R9),C'('          does it start with left paren?  @D2A 06360000
         JNE   BADPARM             no, error                       @D2A 06370000
         LA    R15,0(R4,R9)        end of parm + 1                 @D2A 06380000
         BCTR  R15,0               end of parm                     @D2A 06390000
         CLI   0(R15),C')'         does it end with right paren?   @D2A 06400000
         JNE   BADPARM             no, error                       @D2A 06410000
         CHI   R4,6                is it 'COPY()'                  @TTC 06420000
         JE    PNEXT               yes, use defaults               @D2A 06430000
         CHI   R4,21               are both dates given?           @TTC 06440000
         JNE   PNOTBOTH            no, keep checking               @D2A 06450000
         CLI   12(R9),C','         is there a comma?               @D2A 06460000
         JNE   BADPARM             no, error                       @D2A 06470000
         MVC   SDATE,5(R9)         save start date                 @D2A 06480000
         MVC   EDATE,13(R9)        save end date                   @D2A 06490000
         J     PNEXT               look for next entry             @D2A 06500000
PNOTBOTH CHI   R4,13               is it start all alone?          @TTC 06510000
         JE    PSTART              yes, so save it                      06520000
         CHI   R4,14               could it be one date w/comma?   @TTC 06530000
         JNE   PCOPYND             no, must be ">nnn"              @D2A 06540000
         CLI   12(R9),C','         does it end with comma?         @D2A 06550000
         JE    PSTART              yes, so it's "start_date,"           06560000
         CLI   5(R9),C','          does it start with comma?       @D2A 06570000
         JNE   BADPARM             no, error                            06580000
         MVC   EDATE,6(R9)         save end date                   @D2A 06590000
         J     PNEXT               look for next entry             @D2A 06600000
PSTART   MVC   SDATE,5(R9)         save start date                 @D2A 06610000
         J     PNEXT               look for next entry             @D2A 06620000
PCOPYND  DS    0H            must be COPY(>nnn)                    @D2A 06630000
         CHI   R4,8                is it too short?                @TTC 06640000
         JL    BADPARM             yes, error                      @D2A 06650000
         CHI   R4,10               is it too long?                 @TTC 06660000
         JH    BADPARM             yes, error                      @D2A 06670000
         CLI   5(R9),C'>'          does it start with >?           @D2A 06680000
         JNE   BADPARM             no, error                       @D2A 06690000
*        save number of days, n thru nnn                           @D2A 06700000
         MVC   COPYDAYS,=C'000'    initialize receiving field      @D2A 06710000
         LR    R14,R4              get length of entry             @D2A 06720000
         AHI   R14,-8              get length of number - 1        @TTC 06730000
         LA    R15,COPYDAYS+2      end of receiving field          @D2A 06740000
         SR    R15,R14             back up to correct position     @D2A 06750000
         EX    R14,MVCCOPY         move in number of days          @D2A 06760000
         J     PNEXT               look for next entry             @D2A 06770000
PNOTCOPY DS    0H                                                  @D2A 06780000
         CLC   =C'DELETE',0(R9)    is it DELETE?                   @D2A 06790000
         JNE   CHKFRMT             Check if HCFORMAT is specified  @04C 06800000
         TM    PFLAGS,DELETE       was DELETE already processed?   @D2A 06810000
         JO    BADPARM             yes,error                       @D2A 06820000
         OI    PFLAGS,DELETE       set DELETE flag                 @D2A 06830000
         CHI   R4,10               is length 10 (the minimum)?     @TTC 06840000
         JL    BADPARM             error if less than min          @D2A 06850000
         CLI   6(R9),C'('          does it start with left paren?  @D2A 06860000
         JNE   BADPARM             no, error                       @D2A 06870000
         LA    R15,0(R4,R9)        end of parm + 1                 @D2A 06880000
         BCTR  R15,0               end of parm                     @D2A 06890000
         CLI   0(R15),C')'         does it end with right paren?   @D2A 06900000
         JNE   BADPARM             no, error                       @D2A 06910000
         CHI   R4,15               is it "DELETE(yyyyddd)"         @TTC 06920000
         JNE   PDELND              no, must be ">nnn"              @D2A 06930000
         MVC   DDATE,7(R9)         save delete date                @D2A 06940000
         J     PNEXT               look for next entry             @D2A 06950000
PDELND   DS    0H            must be DELETE(>nnn)                  @D2A 06960000
*              we already checked for minimum length               @D2A 06970000
         CHI   R4,12               is it too long?                 @TTC 06980000
         JH    BADPARM             yes, error                      @D2A 06990000
         CLI   7(R9),C'>'          does it start with >?           @D2A 07000000
         JNE   BADPARM             no, error                       @D2A 07010000
*        save number of days, n thru nnn                           @D2A 07020000
         MVC   DELDAYS,=C'000'     initialize receiving field      @D2A 07030000
         LR    R14,R4              get length of entry             @D2A 07040000
         AHI   R14,-10             get length of number - 1        @TTC 07050000
         LA    R15,DELDAYS+2       end of receiving field          @D2A 07060000
         SR    R15,R14             back up to correct position     @D2A 07070000
         EX    R14,MVCDEL          move in number of days          @D2A 07080000
         J     PNEXT                                               @D2A 07090000
CHKFRMT  DS    0H                                                  @04A 07100000
         CLC   =C'HCFORMAT',0(R9)  is it HCFORMAT?                 @04A 07110000
         JNE   BADPARM             no, error                       @04A 07120000
         TM    PFLAGS,HCFORMAT     was HCFORMAT already processed? @04A 07130000
         JO    BADPARM             yes,error                       @04A 07140000
         OI    PFLAGS,HCFORMAT     set HCFORMAT flag               @04A 07150000
         CHI   R4,14               is length 14 (the minimum)?     @TTC 07160000
         JL    BADPARM             error if less than min          @04A 07170000
         CLI   8(R9),C'('          does it start with left paren?  @04A 07180000
         JNE   BADPARM             no, error                       @04A 07190000
         LA    R15,0(R4,R9)        end of parm + 1                 @04A 07200000
         BCTR  R15,0               end of parm                     @04A 07210000
         CLI   0(R15),C')'         does it end with right paren?   @04A 07220000
         JNE   BADPARM             no, error                       @04A 07230000
         CHI   R4,14               is it the right length for      @TTCX07240000
                                   "HCFORMAT(YEAR)"?               @04A 07250000
         JNE   CHKCENT             No, check for "HCFORMAT(CENTURY)"   X07260000
                                                                   @04A 07270000
         CLC   =C'YEAR',9(R9)      is it "HCFORMAT(YEAR)"          @04A 07280000
         JNE   BADPARM             no, error                       @04A 07290000
         J     PNEXT               look for next entry             @04A 07300000
CHKCENT  DS    0H                                                  @04A 07310000
         CHI   R4,17               is it the right length for      @TTCX07320000
                                   "HCFORMAT(CENTURY)"?            @04A 07330000
         JNE   BADPARM             no, error                       @04A 07340000
         CLC   =C'CENTURY',9(R9)   is it "HCFORMAT(CENTURY)"       @04A 07350000
         JNE   BADPARM             no, error                       @04A 07360000
         NI    PFLAGS,X'FF'-YEAR   Reset the default               @TTA 07365000
         OI    PFLAGS,CENTURY      Indicate that the output            *07370000
                                   should have a 4-digit year      @04A 07380000
MDBLGDAT LOCTR                                                     @TTC 07390000
TRT1     TRT   0(*-*,R14),TRTTAB1  scan parm for comma or l. paren @D2A 07400000
TRT2     TRT   0(*-*,R1),TRTTAB2   scan parm for r. paren          @D2A 07410000
MVCCOPY  MVC   0(*-*,R15),6(R9)    move in number of days          @D2A 07420000
MVCDEL   MVC   0(*-*,R15),8(R9)    move in number of days          @D2A 07430000
MDBLGCOD LOCTR                                                     @TTA 07435000
PNEXT    DS    0H                                                  @D2A 07440000
*        get to next parm entry                                    @D2A 07450000
         A     R4,=F'1'            add comma to len of this entry  @D2A 07460000
         AR    R9,R4               point to next entry             @D2A 07470000
         SR    R3,R4               calculate remaining length      @D2A 07480000
         JP    PLOOP               loop back until parm is done    @D2A 07490000
*                                                                       07500000
*                   see if defaults are needed                     @TTC 07510000
         TIME  ,                   get today's date                @D2A 07520000
         ST    1,DATEWORK          copy it                              07530000
         AP    DATEWORK(4),=P'1900000' add to correct the century       07540000
         UNPK  TDATE,DATEWORK      convert and save today's date   @D2A 07550000
         OI    TDATE+6,C'0'        fix sign                        @D2A 07560000
*                                                                  @D2A 07570000
*        check parameters                                          @D2A 07580000
*                                                                  @D2A 07590000
         TM    PFLAGS,COPY         was copy specified?             @D2A 07600000
         JNO   PVDELETE            no, so see if delete            @D2A 07610000
*                                                                  @D2A 07620000
*        check for valid copy days                                 @D2A 07630000
*                                                                  @D2A 07640000
         NC    COPYDAYS,COPYDAYS   was copy days given?            @D2A 07650000
         JZ    PNCOPYD             no, so check for dates          @D2A 07660000
         LA    R15,L'COPYDAYS      length of copydays field        @D2A 07670000
PCOPYDL  LA    R14,COPYDAYS-1(R15) position within copydays        @D2A 07680000
         CLI   0(R14),C'0'         is character less than 0?       @D2A 07690000
         JL    BADPARM             yes, error                      @D2A 07700000
         CLI   0(R14),C'9'         is character greater than 9?    @D2A 07710000
         JH    BADPARM             yes, error                      @D2A 07720000
         JCT   R15,PCOPYDL         loop to check all chars         @D2A 07730000
         PACK  DAYSWORK,COPYDAYS   convert to decimal              @D2A 07740000
         PACK  DATEWORK,TDATE      get today's date                @D2A 07750000
         SP    DATEWORK+2(2),DAYSWORK subtract days from today     @D2A 07760000
         JAS   R14,FIXDATE         adjust for the year             @D2A 07770000
         UNPK  EDATE,DATEWORK      save it as end date             @D2A 07780000
         OI    EDATE+6,C'0'        fix sign                        @D2A 07790000
         MVC   SDATE,=C'1900001'   set start date to earliest      @D2A 07800000
         J     PVDELETE            go see if delete was specified  @D2A 07810000
PNCOPYD  DS    0H   ">nnn" was not specified                       @D2A 07820000
*                                                                       07830000
*        see if start date was given, get default if not                07840000
*                                                                       07850000
         CLC   SDATE,=XL7'00'      was start date given?                07860000
         JE    PSTARTDF            no, so get default                   07870000
         LA    R9,SDATE            point to start date                  07880000
         JAS   R14,CHKDATE         see if it is valid                   07890000
         LTR   R15,R15             is date valid?                       07900000
         JNZ   BADPARM             error if not                         07910000
         J     PENDCK              check end date                  @D2A 07920000
*                                                                       07930000
*        get default start date of 1900001                         @D2A 07940000
*                                                                       07950000
PSTARTDF MVC   SDATE,=C'1900001'   Get default start date          @D2A 07960000
*                                                                       07970000
*        check for valid end date                                  @D2A 07980000
*                                                                  @D2A 07990000
PENDCK   CLC   EDATE,=XL7'00'      was end date given?             @D2A 08000000
         JE    PENDDEF             no, so get default              @D2A 08010000
         LA    R9,EDATE            point to end date               @D2A 08020000
         JAS   R14,CHKDATE         see if it is valid              @D2A 08030000
         LTR   R15,R15             is date valid?                  @D2A 08040000
         JNZ   BADPARM             error if not                    @D2A 08050000
         CLC   EDATE,TDATE         is it after today?              @D2A 08060000
         JH    BADPARM             yes, error                      @D2A 08070000
*                                                                  @D2A 08080000
*        recalculate end date as the day after the given date      @D2A 08090000
*                                                                  @D2A 08100000
         PACK  DATEWORK,EDATE      convert end date to decimal     @D2A 08110000
         AP    DATEWORK+2(2),=PL1'1' add 1 to day                  @D2A 08120000
         JAS   R14,FIXDATE         adjust for the year             @D2A 08130000
         UNPK  EDATE,DATEWORK      save it as end date             @D2A 08140000
         OI    EDATE+6,C'0'        fix sign                        @D2A 08150000
         J     PENDOK                                              @D2A 08160000
*                                                                  @D2A 08170000
*        set default end date as today                             @D2A 08180000
*                                                                  @D2A 08190000
PENDDEF  MVC   EDATE,TDATE         get today's date                @D2A 08200000
PENDOK   DS    0H                                                  @D2A 08210000
*                                                                       08220000
*                                                                       08230000
*                                                                       08240000
         CLC   SDATE,EDATE         see if start date < end date    @D2A 08250000
         JNL   BADPARM             error if not                         08260000
*                                                                  @D2A 08270000
*        see if DELETE was specified                               @D2A 08280000
*                                                                  @D2A 08290000
PVDELETE DS    0H                                                  @D2A 08300000
         TM    PFLAGS,DELETE       was delete specified?           @D2A 08310000
         JNO   PDELOK              no, ok                          @D2A 08320000
*                                                                  @D2A 08330000
*        check for valid delete days                               @D2A 08340000
*                                                                  @D2A 08350000
         NC    DELDAYS,DELDAYS     was delete days given?          @D2A 08360000
         JZ    PNDELD              no, so check the given date     @D2A 08370000
         LA    R15,L'DELDAYS       length of deldays field         @D2A 08380000
PDELDL   LA    R14,DELDAYS-1(R15)  position within deldays         @D2A 08390000
         CLI   0(R14),C'0'         is character less than 0?       @D2A 08400000
         JL    BADPARM             yes, error                      @D2A 08410000
         CLI   0(R14),C'9'         is character greater than 9?    @D2A 08420000
         JH    BADPARM             yes, error                      @D2A 08430000
         JCT   R15,PDELDL          loop to check all chars         @D2A 08440000
         PACK  DAYSWORK,DELDAYS    convert to decimal              @D2A 08450000
         PACK  DATEWORK,TDATE      get today's date                @D2A 08460000
         SP    DATEWORK+2(2),DAYSWORK subtract days from today     @D2A 08470000
         JAS   R14,FIXDATE         adjust for the year             @D2A 08480000
         UNPK  DDATE,DATEWORK      save it as delete date          @D2A 08490000
         OI    DDATE+6,C'0'        fix sign                        @D2A 08500000
         J     PDELOK              done with DELETE                @D2A 08510000
*                                                                  @D2A 08520000
*        check for valid delete date                               @D2A 08530000
*                                                                  @D2A 08540000
PNDELD   LA    R9,DDATE            point to delete date            @D2A 08550000
         JAS   R14,CHKDATE         see if it is valid              @D2A 08560000
         LTR   R15,R15             is date valid?                  @D2A 08570000
         JNZ   BADPARM             error if not                    @D2A 08580000
*                                                                  @D2A 08590000
*        recalculate delete date as the day after the given date   @D2A 08600000
*                                                                  @D2A 08610000
         PACK  DATEWORK,DDATE      convert delete date to decimal  @D2A 08620000
         AP    DATEWORK+2(2),=PL1'1' add 1 to day                  @D2A 08630000
         JAS   R14,FIXDATE         adjust for the year             @D2A 08640000
         UNPK  DDATE,DATEWORK      save it as delete date          @D2A 08650000
         OI    DDATE+6,C'0'        fix sign                        @D2A 08660000
PDELOK   DS    0H                                                  @D2A 08670000
*                                                                  @D2A 08680000
* convert dates to stck format                                     @D2A 08690000
*                                                                  @D2A 08700000
         LA    R3,SDATE            start date yyyyddd              @D2A 08710000
         LA    R4,SSTCK            field for stck form             @D2A 08720000
         JAS   R14,CONVSTCK        convert yyyyddd to stck format  @D2A 08730000
         LA    R3,EDATE            start date yyyyddd              @D2A 08740000
         LA    R4,ESTCK            field for stck form             @D2A 08750000
         JAS   R14,CONVSTCK        convert yyyyddd to stck format  @D2A 08760000
         LA    R3,DDATE            start date yyyyddd              @D2A 08770000
         LA    R4,DSTCK            field for stck form             @D2A 08780000
         JAS   R14,CONVSTCK        convert yyyyddd to stck format  @D2A 08790000
******************************************************************@TTA* 08791000
* Check if JES3IN is present and parse the statements             @TTA* 08792000
******************************************************************@TTA* 08793000
         JAS   R14,PARSINIT        Go parse the initialization     @TTA+08794000
                                     statements                    @TTA 08795000
*********************************************************************** 08800000
* Obtain a buffer area for logger record and set up its base          * 08810000
*********************************************************************** 08820000
         STORAGE OBTAIN,LENGTH=STRBUFFL,BNDRY=PAGE get storage for buff 08830000
         LR    R10,R1              save its address                     08840000
         USING STRBUFF,R10         addressability                       08850000
*********************************************************************** 08860000
*                                                                       08870000
*********************************************************************** 08880000
*  If COPY was specified, open the output file                     @03A 08890000
*  Connect to the log stream                                          * 08900000
*  If a recoverable error is detected, write it to the output file @03A 08910000
*********************************************************************** 08920000
         TM    PFLAGS,COPY         was copy specified?             @03A 08930000
         JNO   STARTCON            no, skip open, go to IXGCONN    @03A 08940000
*-----------------------------------------------------------------@TTA* 08941000
*        Obtain RMODE 24 storage for the output DCB               @TTA* 08942000
*-----------------------------------------------------------------@TTA* 08943000
         STORAGE OBTAIN,LENGTH=OFILDCBL,LOC=24  Get DCB storage    @TTA 08944000
         ST    R1,ODCBADDR         Save for later                  @TTA 08945000
         LR    R2,R1               Copy address to work reg.       @TTA 08946000
         MVC   0(OFILDCBL,R2),OFILE  Copy the DCB                  @TTA 08947000
         OPEN  ((R2),OUTPUT),      open the file                   @TTC+08950000
               MODE=31,                                            @TTA+08952000
               MF=(E,OPENLIST)                                     @TTA 08955000
         C     R15,=F'8'           see if open worked              @03M 08960000
         JL    OPENOK              continue if so                  @03M 08970000
         ABEND 3,DUMP                                              @03M 08980000
OPENOK   DS    0H                                                  @03M 08990000
         OI    MFLAGS,OPEN         Output file opened              @01A 09000000
STARTCON DS    0H                                                  @03A 09010000
         MVC   LOGRMSGT,=CL10'IXGCONN-1' insert in case of error   @P6C 09020000
         IXGCONN REQUEST=CONNECT,  connect to the log stream           X09030000
               AUTH=WRITE,                                             X09040000
               STREAMNAME=STRNAME,                                     X09050000
               STREAMTOKEN=STRTOKEN,                                   X09060000
               ANSAREA=ANSAREA,                                        X09070000
               ANSLEN=ANSLEN,                                          X09080000
               RETCODE=RETCODE,                                        X09090000
               RSNCODE=RSNCODE                                          09100000
         CLC   RETCODE,=AL4(IXGRETCODEOK) did it work ok?          @P6C 09110000
         JE    CONNOK              yes, continue                   @D2A 09120000
*                                                                       09130000
*        error during connect                                           09140000
*        see if it is "possible loss of data". If it is, write a   @01C 09150000
*        message to the output file.                               @01A 09160000
*                                                                  @D2A 09170000
*        IXGRSNCODECONNPOSSIBLELOSSOFDATA = possible loss of data  @D2A 09180000
*                                                                       09190000
         L     R14,RSNCODE         get reason code                 @D2A 09200000
         N     R14,=AL4(IXGRSNCODEMASK) AND it with logger mask    @D2A 09210000
*********************************************************************** 09220000
*        IXGRSNCODEWOWWARNING, IXGRSNCODEDIRECTORYFULLWARNING and  @TTC 09230000
*        IXGRSNCODEWARNINGLOSSOFDATA would be errors on an actual  @TTA 09235000
*        write to the operlog, but they are conditions that can    @TTC 09240000
*        be ignored for IEAMDBL3                                   @TTC 09250000
*********************************************************************** 09260000
         C     R14,=AL4(IXGRSNCODEWOWWARNING) Write warning?       @02A 09270000
         JE    CONNOK              Yes, ok, continue               @02A 09280000
         C     R14,=AL4(IXGRSNCODEDSDIRECTORYFULLWARNING)  Is the       09290000
*                                  directory full?                 @02A 09300000
         JE    CONNOK              Yes, continue                   @02A 09310000
         C     R14,=AL4(IXGRSNCODECONNPOSSIBLELOSSOFDATA) is it        X09320000
                                   possible loss of data?          @D2A 09330000
         JE    ISSGAPMS            Yes, continue                   @TTC 09340000
         C     R14,=AL4(IXGRSNCODEWARNINGLOSSOFDATA)  is it        @TTAX09342000
                                   possible loss of data?          @TTA 09344000
         JNE   LOGRERR             no, connect error, abend        @TTA 09346000
ISSGAPMS JAS   R14,GAPMSG          indicate data may be missing    @01A 09350000
         J     CONNOK              continue                        @01A 09360000
*********************************************************************** 09370000
*        LOGRERR is entered from several points in this module     @01A 09380000
*        to write an error message to the issuing console and      @01A 09390000
*        ABEND the program with a U0002 code.                      @01A 09400000
*********************************************************************** 09410000
LOGRERR  DS    0H   error return code from a system logger request      09420000
         UNPK  LOGRMRET(4),RETCODE+2(3) get return code                 09430000
         TR    LOGRMRET,HEXTAB     make it printable                    09440000
         MVI   LOGRMRET+3,C','     replace lost character               09450000
         UNPK  LOGRMRSN(5),RSNCODE+2(3) get reason code                 09460000
         TR    LOGRMRSN,HEXTAB     make it printable                    09470000
         MVI   LOGRMRSN+4,C' '     replace lost character               09480000
         LA    R2,LOGRMSG          point to error message               09490000
         JAS   R14,MESSR           display it                           09500000
         TM    MFLAGS,OPEN         output file opened?             @01A 09510000
         JNO   GODUMP              No, don't write to or close it  @01A 09520000
         L     R2,ODCBADDR         Get the DCB address             @TTA 09525000
         CLOSE ((R2)),             close output file               @TTC+09530000
               MODE=31,                                            @TTA+09533000
               MF=(E,CLOSLIST)                                     @TTA 09536000
         NI    MFLAGS,X'FF'-OPEN   indicate file now closed        @01A 09540000
GODUMP   DS    0H                                                       09550000
         ABEND 2,DUMP              abend                                09560000
*********************************************************************** 09570000
* End initialization                                                  * 09580000
*********************************************************************** 09590000
         EJECT ,                                                        09600000
*********************************************************************** 09610000
* Begin COPY                                                      @D2A* 09620000
*********************************************************************** 09630000
*                                                                 @D2A* 09640000
*  If COPY was specified:                                         @D2A* 09650000
*                                                                 @D2A* 09660000
*   Start a log stream browse session and position the log stream @D2A* 09670000
*   to first record in the range                                  @D2A* 09680000
*                                                                 @D2A* 09690000
*   Copy loop:                                                    @D2A* 09700000
*                                                                 @D2A* 09710000
*    Read successive records from the stream, starting with the   @D2A* 09720000
*    earliest record bearing the start date and ending with the   @D2A* 09730000
*    latest record on or before the end date. Indicate if there   @01C* 09740000
*    was a gap or deleted records immediately before the first    @01A* 09750000
*    record to be printed with a special message to the output    @01A* 09760000
*    file.                                                        @01A* 09770000
*                                                                 @D2A* 09780000
*    For each record (MDB) that is read:                          @D2A* 09790000
*                                                                 @D2A* 09800000
*     Get the general and CP objects                              @D2A* 09810000
*                                                                 @D2A* 09820000
*     Extract the fixed info                                      @D2A* 09830000
*                                                                 @D2A* 09840000
*     For every line (text object) in the message:                @D2A* 09850000
*                                                                 @D2A* 09860000
*      Write a DLOG-format line to the output file                @TTC* 09870000
*                                                                 @D2A* 09880000
*      If line was too long, also write a continuation line       @D2A* 09890000
*                                                                 @01A* 09900000
*      If IXGBRWSE indicated records were missing between the     @01A* 09910000
*      current and previous record (due to a gap or deleted       @01A* 09920000
*      records) write a special message to the output file.       @01A* 09930000
*                                                                 @D2A* 09940000
*   End the log stream browse session                             @D2A* 09950000
*                                                                 @D2A* 09960000
*   Close the output file                                         @D2A* 09970000
*                                                                 @D2A* 09980000
*                                                                 @D2A* 09990000
*********************************************************************** 10000000
CONNOK   DS    0H                                                  @01M 10010000
         TM    PFLAGS,COPY         was copy specified?             @D2A 10020000
         JNO   NOTCOPY             no, so skip it                  @D2A 10030000
*********************************************************************** 10040000
*        issue BROWSE START to get browse session going                 10050000
*        and position to first record in range                          10060000
*********************************************************************** 10070000
         XC    RECCOUNT,RECCOUNT   zero record count                    10080000
         MVC   LOGRMSGT,=CL10'IXGBRWSE-1' insert in case of error  @P6C 10090000
         IXGBRWSE REQUEST=START,                                       X10100000
               SEARCH=SSTCK,           start date                      X10110000
               GMT=NO,                 local time                      X10120000
               BROWSETOKEN=BRWTOKEN,                                   X10130000
               STREAMTOKEN=STRTOKEN,                                   X10140000
               ANSAREA=ANSAREA,                                        X10150000
               ANSLEN=ANSLEN,                                          X10160000
               RETCODE=RETCODE,                                        X10170000
               RSNCODE=RSNCODE                                          10180000
         CLC   RETCODE,=AL4(IXGRETCODEOK) did it work ok?          @P6C 10190000
         JE    FIRSTOK             yes, so we have starting position    10200000
*********************************************************************** 10210000
*        error in BROWSE START                                          10220000
*        see if it is just a gap in the stream, and continue if so @P6A 10230000
*        see if there are just no records in range                      10240000
*                                                                  @02A 10250000
*        If the return code was 8 or more, set flag to indicate    @02A 10260000
*        IXGBRWSE REQUEST=END should be bypassed                   @02A 10270000
*                                                                       10280000
*        IXGRSNCODEWARNINGGAP = request successful but data missing@P6A 10290000
*        IXGRSNCODEWARNINGDEL = request successful but records had @01A 10300000
*                               been previously deleted            @01A 10310000
*        IXGRSNCODEEOFGAP  = end of file due to gap                @01A 10320000
*        IXGRSNCODEEOFDELETE = end of file because all subsequent  @01A 10330000
*                              records previously deleted          @01A 10340000
*        IXGRSNCODENOBLOCK = block does not exist                       10350000
*        IXGRSNCODELOSSOFDATAGAP = a section of data is            @01A 10360000
*                               permanently missing                @01A 10370000
*        IXGRSNCODELOSSOFDATAEOF = premature end of file due to    @01A 10380000
*                               records permanently missing        @01A 10390000
*        IXGRSNCODEEMPTYSTREAM = no records in stream. Issue       @03A 10400000
*                            message MLG004I and exit program      @03A 10410000
*********************************************************************** 10420000
         CLC   RETCODE,=AL4(IXGRETCODEERROR) RC of 8 or more?      @02A 10430000
         JL    STARTOK             No,  REQUEST=START worked       @02A 10440000
         OI    MFLAGS,NOBREND      Yes. Do not do REQUEST=END      @02A 10450000
STARTOK  DS    0H                                                  @02A 10460000
         CLC   RETCODE,=AL4(IXGRETCODECOMPERROR) Logger error?     @02A 10470000
*                                  (Return code 12 or higher)      @02A 10480000
         JNL   LOGRERR             yes, close and return           @02A 10490000
         L     R14,RSNCODE         get reason code                      10500000
         N     R14,=AL4(IXGRSNCODEMASK) and it with logger mask         10510000
         C     R14,=AL4(IXGRSNCODEEMPTYSTREAM) empty log stream?   @03A 10520000
         JNE   NOTEMPTY            no, continue checking           @03A 10530000
         LA    R2,EMPTYSTM         point to info msg               @03A 10540000
         JAS   R14,MESSR           display it                      @03A 10550000
         J     COPYDONE            done with copy                  @03A 10560000
NOTEMPTY DS    0H                                                  @03A 10570000
         C     R14,=AL4(IXGRSNCODEWARNINGGAP) is it a gap?         @P6A 10580000
         JE    GAPORDEL            YES, write message to output    @01A 10590000
         C     R14,=AL4(IXGRSNCODEWARNINGDEL) records deleted?     @01A 10600000
         JE    GAPORDEL            Yes, write message and quit     @01A 10610000
         C     R14,=AL4(IXGRSNCODEEOFGAP) EOF because gap to end?  @01A 10620000
         JE    GAPEOF                                                   10630000
         C     R14,=AL4(IXGRSNCODELOSSOFDATAGAP) records permanently    10640000
*                                  missing?                        @01A 10650000
         JE    GAPORDEL            Yes, write message              @01A 10660000
         C     R14,=AL4(IXGRSNCODELOSSOFDATAEOF) premature end of file  10670000
*                                  records permanently missing?    @01A 10680000
         JE    GAPEOF              Yes, write message and quit     @01A 10690000
         C     R14,=AL4(IXGRSNCODEEOFDELETE) EOF because all       @01A 10700000
*                                  subsequent records deleted?     @01A 10710000
         JNE   OPENOK2             no, continue checking           @01A 10720000
GAPEOF   EQU   *                                                   @01A 10730000
         OI    MFLAGS,REACHEOF     indicate end of file reached    @01A 10740000
GAPORDEL EQU   *                                                   @01A 10750000
         JAS   R14,GAPMSG          Write record to sysout file     @01A 10760000
         TM    MFLAGS,REACHEOF     was end of file reached?        @01A 10770000
         JO    COPYDONE            yes, done                       @01A 10780000
         J     FIRSTOK             continue                        @01A 10790000
OPENOK2  EQU   *                                                   @01A 10800000
         C     R14,=AL4(IXGRSNCODENOBLOCK) is it block not found?       10810000
         JE    BLKNOFND            Yes, issue msg                  @TTA 10812000
         C     R14,=AL4(IXGRSNCODEWARNINGLOSSOFDATA) Records       @TTA+10814000
                                                      missing?     @TTA 10816000
         JNE   LOGRERR             no, display the error                10820000
         J     FIRSTOK                                             @TTA 10826000
*        no records in range                                            10830000
BLKNOFND LA    R2,EMPTYMSG         point to info msg               @TTC 10840000
         JAS   R14,MESSR           display it                           10850000
         J     COPYDONE            done with copy                  @D2C 10860000
FIRSTOK  DS    0H                                                       10870000
*                                                                       10880000
*********************************************************************** 10890000
* Begin copy loop                                                 @D2A* 10900000
*********************************************************************** 10910000
*                                                                       10920000
*********************************************************************** 10930000
*  Read successive records from the stream, starting with the         * 10940000
*  earliest record bearing the start date and ending with the         * 10950000
*  latest record on or before the end date                            * 10960000
*********************************************************************** 10970000
*                                                                       10980000
COPYLOOP DS    0H                                                  @D2C 10990000
*********************************************************************** 11000000
*********************************************************************** 11010000
*                                                                       11020000
* get next record from log stream                                       11030000
*                                                                       11040000
         MVC   LOGRMSGT,=CL10'IXGBRWSE-2' insert in case of error  @P6C 11050000
         IXGBRWSE REQUEST=READCURSOR, read next record                 X11060000
               BROWSETOKEN=BRWTOKEN,                                   X11070000
               BUFFER=STRBUFF,                                         X11080000
               BUFFLEN=STRBLEN,                                        X11090000
               DIRECTION=OLDTOYOUNG,                                   X11100000
               RETBLOCKID=CURRBLK,                                     X11110000
               TIMESTAMP=CURRSTCK,                                     X11120000
               STREAMTOKEN=STRTOKEN,                                   X11130000
               ANSAREA=ANSAREA,                                        X11140000
               ANSLEN=ANSLEN,                                          X11150000
               RETCODE=RETCODE,                                        X11160000
               RSNCODE=RSNCODE                                          11170000
         CLC   RETCODE,=AL4(IXGRETCODEOK) did it work ok?          @P6C 11180000
         JE    READCOK             yes, continue                        11190000
*********************************************************************** 11200000
*        error in BROWSE READCURSOR                                     11210000
*        see if it is just a gap in the stream, and continue if so      11220000
*        see if we reached EOF and end if so                       @D2A 11230000
*                                                                       11240000
*        IXGRSNCODEWARNINGGAP = request successful but data missing     11250000
*        IXGRSNCODEWARNINGDEL = request successful but records     @01A 11260000
*                               were previously deleted            @01A 11270000
*        IXGRSNCODEWARNINGLOSSOFDATA = request successful but data      11280000
*                               missing due to environment error   @02A 11290000
*        IXGRSNCODEEOFGAP     = EOF because all subsequent records @01A 11300000
*                               unavailable due to gap             @01A 11310000
*        IXGRSNCODEEOFDELETE  = reached EOF because subsequent     @01C 11320000
*                               records previously deleted         @01A 11330000
*        IXGRSNCODEENDREACHED = reached EOF                        @D2A 11340000
*        IXGRSNCODELOSSOFDATAGAP = records permanently missing     @01A 11350000
*        IXGRSNCODELOSSOFDATAEOF = premature end of file due to    @01A 11360000
*                               records permanenely missing        @01A 11370000
*********************************************************************** 11380000
         L     R14,RSNCODE         get reason code                      11390000
         N     R14,=AL4(IXGRSNCODEMASK) and it with logger mask         11400000
         C     R14,=AL4(IXGRSNCODEWARNINGGAP) is it a gap?              11410000
         JE    READCOKG            yes, note that                  @01C 11420000
         C     R14,=AL4(IXGRSNCODEWARNINGDEL) Records deleted?     @01A 11430000
         JE    READCOKG            yes, note that                  @01A 11440000
         C     R14,=AL4(IXGRSNCODEWARNINGLOSSOFDATA) Records deleted    11450000
*                                  due to environmental error?     @02A 11460000
         JE    READCOKG            yes, note that                  @02A 11470000
         C     R14,=AL4(IXGRSNCODEEOFGAP) is it EOF because        @01A 11480000
*                                  gap until end of file?          @01A 11490000
         JE    SETEOFLG            yes, note that                  @01A 11500000
         C     R14,=AL4(IXGRSNCODEEOFDELETE) is it EOF because     @01C 11510000
*                                  subsequent records deleted?     @01A 11520000
         JE    SETEOFLG            yes, note that                  @01C 11530000
         C     R14,=AL4(IXGRSNCODEENDREACHED) is it EOF?           @D2A 11540000
         JE    COPYDONE            yes, done                       @D2A 11550000
         C     R14,=AL4(IXGRSNCODELOSSOFDATAGAP) records permanently    11560000
*                                  missing?                        @01A 11570000
         JE    READCOKG            Yes, note that                  @01A 11580000
         C     R14,=AL4(IXGRSNCODELOSSOFDATAEOF) premature end of       11590000
*                                  file due to records permanently      11600000
*                                  missing?                        @01A 11610000
         JNE   LOGRERR             no, display the error           @01A 11620000
SETEOFLG EQU   *                                                   @01A 11630000
         OI    MFLAGS,REACHEOF     indicate EOF reached            @01A 11640000
READCOKG EQU   *                                                   @01A 11650000
         JAS   R14,GAPMSG          Write record to sysout file     @01A 11660000
         TM    MFLAGS,REACHEOF     EOF reached?                    @01A 11670000
         JNZ   COPYDONE            yes, done                       @01A 11680000
READCOK  DS    0H                                                       11690000
*                                                                       11700000
* readcursor worked; see if we are past the end date               @D2C 11710000
*                                                                       11720000
         CLC   CURRSTCK+8(8),ESTCK   are we at the end?            @P1C 11730000
         JL    NOTEND              no, ok                               11740000
         CLC   RECCOUNT,=F'0'      was this the first read?             11750000
         JNE   COPYDONE            no, so copy is done             @D2C 11760000
*                                                                       11770000
* show no records processed                                             11780000
*                                                                       11790000
         LA    R2,EMPTYMSG         point to info msg                    11800000
         JAS   R14,MESSR           display it                           11810000
         J     COPYDONE            done with copy                  @D2C 11820000
NOTEND   DS    0H                                                       11830000
*                                                                       11840000
* increment record count                                                11850000
*                                                                       11860000
         L     R15,RECCOUNT        get record count                     11870000
         A     R15,=F'1'           add 1                                11880000
         ST    R15,RECCOUNT        store new count                      11890000
*                                                                       11900000
*********************************************************************** 11910000
*  For each record (MDB) that is read:                                * 11920000
*     Get the general and CP objects                                  * 11930000
*     Extract the fixed info                                          * 11940000
*     For every line (text object) in the message                     * 11950000
*        Write a DLOG-format line to the output file              @TTC* 11960000
*        If line was too long, also write a continuation line         * 11970000
*********************************************************************** 11980000
         LR    R8,R10              point to mdb in buffer          @TTC 11990000
         USING MDB,R8                                                   12000000
         MVI   FLAGS1,0            clear processing flags               12010000
         MVC   LOGBUF,BLANKS       Clear out output buffer         @TTC 12020000
         LR    R6,R8               calc end of mdb in R6                12030000
         AH    R6,MDBLEN           start+mdblen in header               12040000
         LA    R7,MDBHLEN(0,R8)    address of first object              12050000
         CR    R7,R6               see if this is the end               12060000
         JNL   COPYLOOP            get another MDB if so (no           X12070000
                                   objects)                        @D2C 12080000
         DROP  R8                                                       12090000
         USING MDB,R7                                                   12100000
*                                                                       12110000
* scan MDB objects looking for general and CP objects, and              12120000
* save DLOG information from them                                  @TTC 12130000
*                                                                       12140000
OBJLP    DS    0H                  loop through the objects             12150000
         LH    R3,MDBTYPE          get type                             12160000
         CHI   R3,MDBGOBJ          check for general object        @TTC 12170000
         JNE   NOTG                not general object                   12180000
         TM    FLAGS1,FLAGGO       see if first general object          12190000
         JO    NXTOBJ              no, skip it                          12200000
         OI    FLAGS1,FLAGGO       show general object was found        12210000
         USING MDBG,R7             addressability to general object     12220000
*********************************************************************** 12230000
* Move general object fields into log record or save them               12240000
*                                                                 @TTA* 12240500
* Examples of typical DLOG records:                               @TTA* 12241000
*                                                                 @TTA* 12241500
* ----+----1----+----2----+----3----+----4----+----5-- ...        @TTA* 12242000
*      C3E0SY1  19163 1425262 -S TCAS                             @TTA* 12242500
* MLG           19163 1425276  SY1 R= LLA      IEF196I ...        @TTA* 12243000
* LOG           19163 1425276  IAT6100 ( DEMSEL ) JOB  ...        @TTA* 12243500
*               19163 1425277  SY1 R= LLA      IEF285I ...        @TTA* 12244000
*               AAAAA AAAAAAA                                     @TTA* 12244500
*                                                                 @TTA* 12245000
* GENINFO subroutine fills in the following fields (marked by     @TTA* 12245500
*         AAAAA above):                                           @TTA* 12246000
* - DLOGTIME - time message was issued                            @TTA* 12246500
* - DLOGDATE (DLOG4YDT) - julian date stamp (yyddd or yyyyddd)    @TTA* 12247000
*                                                                 @TTA* 12249500
*********************************************************************** 12250000
         JAS   R14,GENINFO         Fill in the appropriate fields      X12260000
                                   in the log record from the MDB      X12270000
                                   general object                  @04A 12280000
*                                                                9#@TTD 12281001
         MVC   SYSNAME,MDBGOSNM    Save system name                @TTC 12320000
         XR    R15,R15             clear a reg                     @TTC 12330000
         ICM   R15,7,MDBGSEQ       message sequence number         @TTC 12340000
         ST    R15,MLID            Save for later                  @TTC 12350000
         J     NXTOBJ              bump to next object                  12360000
*                                                                       12370000
NOTG     DS    0H                                                       12380000
         CHI   R3,MDBCOBJ          check for control prog object   @TTC 12390000
         JNE   NXTOBJ              not control prog object, get next    12400000
         TM    FLAGS1,FLAGCO       see if first control prog object     12410000
         JO    NXTOBJ              no, skip it                          12420000
         USING MDBSCP,R7           addressability to ctl prog object    12430000
         MVC   JOBNAME,MDBCOJBN    Save job name for JES 3 DLOG    @TTC 12430101
         MVC   MSGOFFST,MDBCTOFF2  Copy message text offset        @TTC+12430201
                                     to skip action characters     @TTC 12430301
*                                                                4#@TTD 12430601
         TM    MDBCMSC2,MDBCOPON   Has MDB been sent from USS ?    @L2A 12431000
         JO    COPYLOOP            skip MDB if it is               @L2A 12431100
         CLC   MDBCPNAM,=C'MVS '   make sure it is an MVS object        12431200
         JNE   NXTOBJ              if not, just skip cp object          12431300
         CLC   MDBCVER,=AL4(MDBCVER5) see if it's the right version     12431400
         JL    COPYLOOP            skip MDB if not                 @D2C 12431500
         OI    FLAGS1,FLAGCO       set processed control prog object    12431600
*********************************************************************** 12431700
* save console id, console name, MCS flags, and descriptors        @P4C 12431800
*********************************************************************** 12431900
         MVC   CONSID,MDBCCNID     save console id                      12432000
         MVC   CONSNAME,MDBCCNNM   save console name               @D1A 12433000
         MVC   MCSFLAGS,MDBCMCSF   save MCS flags                  @D1A 12434000
         MVC   DESCS,MDBCDESC      save descriptor codes           @P4A 12435000
*********************************************************************** 12436000
* Move control pgm object fields into log record or save them      @L1M 12437000
*                                                                  @L1M 12438000
* ----+----1----+----2----+----3----+----4----+----5-- ...        @TTA* 12438100
*      C3E0SY1  19163 1425262 -S TCAS                             @TTA* 12438200
* MLG           19163 1425276  SY1 R= LLA      IEF196I ...        @TTA* 12438300
* LOG           19163 1425276  IAT6100 ( DEMSEL ) JOB  ...        @TTA* 12438400
*               19163 1425277  SY1 R= LLA      IEF285I ...        @TTA* 12438500
* AAA  AAAAAAAA                AAAAAA                             @TTA* 12438600
*                                                                 @TTA* 12438700
* CPINFO subroutine fills in the following fields (marked by      @TTA* 12438800
*         AAAAA above):                                           @TTA* 12438900
* - DLOGCLAS - class of message                                   @TTC* 12439000
* - DLOGCONS (DLOG4YCN) - console to which message was issued     @TTA* 12439118
* - DLOGSPEC - special character: (*)=action                      @TTA* 12439200
*                                 (+)=JES3 command echo           @TTA* 12439318
*                                 (=)=MVS command echo            @TTA* 12439400
*                                 (b)=blank                       @TTA* 12439518
* - MPF suppression character (inserted between DLOGSPEC and      @TTA* 12439600
*     DLOGTEXT)                                                   @TTA* 12439718
* - DLOGSYS - message origin system name                          @TTA* 12439800
*                                                                 @TTA* 12439900
*********************************************************************** 12440000
         JAS   R14,CPINFO          Fill in the appropriate fields      X12450000
                                   in the log record from the MDB      X12460000
                                   CP object                       @L1M 12470000
*********************************************************************** 12480000
* remember whether this is a WTL                                        12490000
*********************************************************************** 12500000
         MVI   WTLFLAG,C'N'        assume not wtl                       12510000
         TM    MDBCMSC2,MDBCWTL    is it a wtl?                         12520000
         JNO   NXTOBJ              no, ok                               12530000
         MVI   WTLFLAG,C'Y'        show it's a wtl                      12540000
*********************************************************************** 12550000
NXTOBJ   DS    0H                  find next object                     12560000
*********************************************************************** 12570000
         TM    FLAGS1,FLAGGO+FLAGCO see if we found general and SCP     12580000
         JO    FNDTXT              got them, loop through text objs     12590000
         USING MDB,R7                                                   12600000
         AH    R7,MDBLEN           bump to next object                  12610000
         CR    R7,R6               see if this is the end               12620000
         JL    OBJLP               no, process this object              12630000
         J     COPYLOOP            missing necessary objects,          X12640000
                                   skip it                         @D2C 12650000
         DROP  R7                                                       12660000
*********************************************************************** 12670000
* find text objects, convert them to DLOG records                  @TTC 12680000
*********************************************************************** 12690000
FNDTXT   DS    0H                                                       12700000
         LA    R7,MDBHLEN(0,R8)    address of first object              12710000
         CR    R7,R6               see if this is the end               12720000
         JNL   COPYLOOP            get another MDB if so               X12730000
                                   objects)                        @D2C 12740000
         USING MDB,R7                                                   12750000
*                                                                       12760000
* scan MDB looking for text objects                                     12770000
*                                                                       12780000
*********************************************************************** 12790000
TOBJLP   CLC   MDBTYPE,=AL2(MDBTOBJ) check for text object              12800000
         JNE   NXTTOBJ             not text object, try next            12810000
*********************************************************************** 12820000
* text object - convert it to DLOG record and PUT it to the file   @TTC 12830000
*                                                                       12840000
*********************************************************************** 12850000
         USING MDBT,R7             addressability to text object        12860000
*********************************************************************** 12870000
* calculate length of text in R2                                        12880000
*********************************************************************** 12890000
         LH    R2,MDBTLEN          get text object length               12900000
         AHI   R2,-(MDBTMSGT-MDBTLEN)  subtract non-text size      @TTC 12910000
         JNP   NXTTOBJ             skip it if length is zero or less    12920000
         LA    R3,MDBTMSGT         get address of text                  12930000
         CLI   WTLFLAG,C'Y'        is it a wtl?                         12940000
         JNE   NOTWTL              no, skip to the non-wtl case         12950000
*********************************************************************** 12960000
*                                                                       12970000
* message came from a wtl                                               12980000
*                                                                       12990000
* PUT only the text (no control info) from the first line               13000000
*                                                                       13010000
*********************************************************************** 13020000
         CHI   R2,L'DLOGTEXT       does text length exceed max?    @TTC 13030000
         JNH   WTLLOK              no, ok                               13040000
         LA    R2,L'DLOGTEXT       set it to max                   @TTC 13050000
WTLLOK   AHI   R2,-1               subtract 1 for mvc              @TTC 13060000
         JM    COPYLOOP            skip it if negative (length < 1)@D2C 13070000
         L     R1,LOGCURTX         Get text pointer                @TTA 13075000
         EX    R2,WTLMV            move in the text                     13080000
MDBLGDAT LOCTR                     Resume data segment             @TTA 13082000
WTLMV    MVC   0(*-*,R1),0(R3)     executed above                  @TTA 13084000
MDBLGCOD LOCTR                     Resume code segment             @TTA 13086000
         LA    R2,5(0,R2)          add for RDW and get back the 1       13090000
         STH   R2,LOGBUFL          set record length               @P4C 13100000
*                                                                 3@P8D 13110000
         L     R2,ODCBADDR         Get the DCB address             @TTA 13115000
         PUT   (R2),LOGBUFP        PUT the WTL record              @TTC 13120000
*                                                                 4@P8D 13130000
         J     COPYLOOP            get next MDB                    @D2C 13140000
*                                                                       13160000
*********************************************************************** 13180000
* not a wtl                                                             13190000
*                                                                       13200000
*********************************************************************** 13210000
NOTWTL   TM    MFLAGS,SKIPSYS      Skip this system?               @TTA 13211000
         JO    NXTTOBJ             Yes, skip putting out the       @TTA+13212000
                                     line                          @TTA 13213000
         AH    R3,MSGOFFST         Skip past action char/blank     @TTA 13214000
         SH    R2,MSGOFFST         Reduce length too               @TTA 13215000
         JAS   R14,PROCLINE        Process text line               @04A 13220000
*                                                                       13230000
* bump to next object                                                   13240000
*                                                                       13250000
NXTTOBJ  DS    0H                                                       13260000
         USING MDB,R7                                                   13270000
         AH    R7,MDBLEN           bump to next object                  13280000
         CR    R7,R6               see if this is the end               13290000
         JL    TOBJLP              no, look at this object              13300000
         DROP  R7                                                       13310000
         J     COPYLOOP            done with this mdb; get next    @D2C 13320000
*                                                                       13330000
*********************************************************************** 13340000
* End copy loop                                                   @D2C* 13350000
*********************************************************************** 13360000
COPYDONE DS    0H                                                  @D2A 13370000
*********************************************************************** 13380000
*  If the return code from IXGBRWSE REQUEST=START had an error,    @02A 13390000
*  "do not perform REQUEST=END" bit will have been set.            @02A 13400000
*********************************************************************** 13410000
         TM    MFLAGS,NOBREND      Bypass REQUEST=END?             @02A 13420000
         JO    SHUTFILE            Yes, continue to shut file      @02A 13430000
*********************************************************************** 13440000
*  End the log stream browse session                                  * 13450000
*********************************************************************** 13460000
         MVC   LOGRMSGT,=CL10'IXGBRWSE-3' insert in case of error  @P6C 13470000
         IXGBRWSE REQUEST=END,                                         X13480000
               BROWSETOKEN=BRWTOKEN,                                   X13490000
               STREAMTOKEN=STRTOKEN,                                   X13500000
               ANSAREA=ANSAREA,                                        X13510000
               ANSLEN=ANSLEN,                                          X13520000
               RETCODE=RETCODE,                                        X13530000
               RSNCODE=RSNCODE                                          13540000
         CLC   RETCODE,=AL4(IXGRETCODEOK) did it work ok?          @P6C 13550000
         JNE   LOGRERR             no, display error                    13560000
*                                                                       13570000
*********************************************************************** 13580000
*  Close the output file                                              * 13590000
*********************************************************************** 13600000
SHUTFILE DS    0H                                                  @02A 13610000
         NI    MFLAGS,X'FF'-NOBREND  Reset bit for DELETE's use    @02A 13620000
         L     R2,ODCBADDR         Get DCB address                 @TTA 13625000
         CLOSE ((R2)),             Close the output file           @TTC+13630000
               MODE=31,                                            @TTA+13633000
               MF=(E,CLOSLIST)                                     @TTA 13636000
*********************************************************************** 13640000
* End COPY                                                        @D2A* 13650000
*********************************************************************** 13660000
NOTCOPY  DS    0H                                                  @D2A 13670000
*********************************************************************** 13680000
* Begin DELETE                                                    @D2A* 13690000
*********************************************************************** 13700000
*                                                                 @D2A* 13710000
*  If delete was specified:                                       @D2A* 13720000
*                                                                 @D2A* 13730000
*   Start a log stream browse session and position the log stream @D2A* 13740000
*   to oldest record to be kept                                   @D2A* 13750000
*                                                                 @D2A* 13760000
*   Delete all records prior to that position                     @D2A* 13770000
*                                                                 @D2A* 13780000
*   End the log stream browse session                             @D2A* 13790000
*                                                                 @D2A* 13800000
*********************************************************************** 13810000
         TM    PFLAGS,DELETE       was delete specified?           @D2A 13820000
         JNO   NOTDEL              no, skip                        @D2A 13830000
* start browse session                                             @D2A 13840000
         MVC   LOGRMSGT,=CL10'IXGBRWSE-4' insert in case of error  @P6C 13850000
         IXGBRWSE REQUEST=START,                                       X13860000
               SEARCH=DSTCK,           deletion date                   X13870000
               GMT=NO,                 local time                      X13880000
               BROWSETOKEN=BRWTOKEN,                                   X13890000
               STREAMTOKEN=STRTOKEN,                                   X13900000
               ANSAREA=ANSAREA,                                        X13910000
               ANSLEN=ANSLEN,                                          X13920000
               RETCODE=RETCODE,                                        X13930000
               RSNCODE=RSNCODE                                     @D2A 13940000
         CLC   RETCODE,=AL4(IXGRETCODEOK) did it work ok?          @P6C 13950000
         JE    DPOINTOK            yes, so we have deletion point  @D2A 13960000
*                                                                  @D2A 13970000
*        error in BROWSE START                                     @D2A 13980000
*        see if it is just a gap in the stream, and continue if so @P6A 13990000
*        see if there are just no records after deletion date      @D2A 14000000
*                                                                  @D2A 14010000
*        If the return code is 8 or more, set flag indicating      @02A 14020000
*        IXGBRWSE REQUEST=END should not be performed              @02A 14030000
*                                                                  @02A 14040000
*        IXGRSNCODEDIRECTGORYFULLWARNING = directory full          @02A 14050000
*        IXGRSNCODEEMPTYSTREAM = no records in log stream          @02A 14060000
*        IXGRSNCODEWARNINGGAP = request successful but data missing@P6A 14070000
*        IXGRSNCODEWARNINGDEL = records have been deleted          @01A 14080000
*        IXGRSNCODEEOFGAP = EOF because subsequent records not     @01A 14090000
*                           available due to gap                   @01A 14100000
*        IXGRSNCODEEOFDELETE = EOF because subsequent records      @01A 14110000
*                           previously deleted                     @01A 14120000
*        IXGRSNCODENOBLOCK = block does not exist                  @D2A 14130000
*        IXGRSNCODELOSSOFDATAGAP = records permanently missing     @01A 14140000
*        IXGRSNCODELOSSOFDATAEOF = premature end of file due to    @01A 14150000
*                             records permanently missing          @01A 14160000
*        IXGRSNCODEWARNINGLOSSOFDATA = loss of data situation      @P7A 14170000
*                                                                  @D2A 14180000
         CLC   RETCODE,=AL4(IXGRETCODEERROR) RC 8 or more?         @02A 14190000
         JL    STARTOKD            Yes, continue                   @02A 14200000
         OI    MFLAGS,NOBREND      No, do not do REQUEST=END       @02A 14210000
STARTOKD DS    0H                                                  @02A 14220000
         CLC   RETCODE,=AL4(IXGRETCODECOMPERROR) Logger error?     @02A 14230000
         JE    LOGRERR             Yes, close and return           @02A 14240000
         L     R14,RSNCODE         get reason code                 @D2A 14250000
         N     R14,=AL4(IXGRSNCODEMASK) and it with logger mask    @D2A 14260000
         C     R14,=AL4(IXGRSNCODEDSDIRECTORYFULLWARNING)  Is the       14270000
*                                  directory full?                 @02A 14280000
         JE    DPOINTOK            Yes, ok, we have deletion pt.   @02A 14290000
         C     R14,=AL4(IXGRSNCODEEMPTYSTREAM) Log stream empty?   @02A 14300000
         JE    DELDONE             Yes, nothing to delete          @02A 14310000
         C     R14,=AL4(IXGRSNCODEWARNINGGAP) is it a gap?         @P6A 14320000
         JE    DPOINTOK            yes, so we have deletion point  @P6A 14330000
         C     R14,=AL4(IXGRSNCODEWARNINGDEL) records deleted?     @01A 14340000
         JE    DPOINTOK            yes, so we have deletion point  @01A 14350000
         C     R14,=AL4(IXGRSNCODEEOFGAP) is it EOF because of a   @01A 14360000
*                                  gap in records to the end?      @01A 14370000
         JE    DELALL              yes, delete all records         @01A 14380000
         C     R14,=AL4(IXGRSNCODEEOFDELETE) is it EOF because of  @01A 14390000
*                                  deleted records?                @01A 14400000
         JE    DELALL              yes, delete all records         @01A 14410000
         C     R14,=AL4(IXGRSNCODELOSSOFDATAGAP) is it records          14420000
*                                  permanently lost?               @01A 14430000
         JE    DPOINTOK            yes, so we have deletion point  @01A 14440000
         C     R14,=AL4(IXGRSNCODELOSSOFDATAEOF) premature end of file  14450000
*                                  from records permanently lost?  @01A 14460000
         JE    DELALL              yes, delete all records         @01A 14470000
         C     R14,=AL4(IXGRSNCODEWARNINGLOSSOFDATA) loss of data? @P7A 14480000
         JE    DELALL              yes, delete all records         @P7A 14490000
         C     R14,=AL4(IXGRSNCODENOBLOCK) is it block not found?  @D2A 14500000
         JNE   LOGRERR             no, display the error           @D2A 14510000
*        no records after deletion date - delete them all          @D2A 14520000
DELALL   EQU   *                                                   @01A 14530000
         MVC   LOGRMSGT,=CL10'IXGDELET-1' insert in case of error  @P6C 14540000
         IXGDELET STREAMTOKEN=STRTOKEN, delete records                 X14550000
               BLOCKS=ALL,                                             X14560000
               ANSAREA=ANSAREA,                                        X14570000
               ANSLEN=ANSLEN,                                          X14580000
               RETCODE=RETCODE,                                        X14590000
               RSNCODE=RSNCODE                                     @D2A 14600000
         CLC   RETCODE,=AL4(IXGRETCODEOK) did it work ok?          @P6C 14610000
         JNE   LOGRERR             no, display error               @D2A 14620000
         J     DELDONE             done with delete                @D2A 14630000
*        delete by blockid                                         @D2A 14640000
DPOINTOK MVC   LOGRMSGT,=CL10'IXGBRWSE-5' insert in case of error  @P6C 14650000
         IXGBRWSE REQUEST=READCURSOR, get block id of next record      X14660000
               BROWSETOKEN=BRWTOKEN,                                   X14670000
               BUFFER=STRBUFF,                                         X14680000
               BUFFLEN=STRBLEN,                                        X14690000
               DIRECTION=OLDTOYOUNG,                                   X14700000
               RETBLOCKID=DELBLK,                                      X14710000
               STREAMTOKEN=STRTOKEN,                                   X14720000
               ANSAREA=ANSAREA,                                        X14730000
               ANSLEN=ANSLEN,                                          X14740000
               RETCODE=RETCODE,                                        X14750000
               RSNCODE=RSNCODE                                     @D2A 14760000
         CLC   RETCODE,=AL4(IXGRETCODEOK) did it work ok?          @P6C 14770000
         JE    DPOINTDL            yes, continue                   @P6A 14780000
         L     R14,RSNCODE         get reason code                 @P6A 14790000
         N     R14,=AL4(IXGRSNCODEMASK) and it with logger mask    @P6A 14800000
         C     R14,=AL4(IXGRSNCODEWARNINGGAP) is it a gap?         @P6A 14810000
         JE    DPOINTDL            yes, continue                   @01A 14820000
         C     R14,=AL4(IXGRSNCODEWARNINGLOSSOFDATA) Records lost due   14830000
*                                  to environmental error?         @02A 14840000
         JE    DPOINTDL            yes, continue                   @02A 14850000
         C     R14,=AL4(IXGRSNCODELOSSOFDATAGAP) records permanently    14860000
*                                  lost?                           @01A 14870000
         JE    DPOINTDL            yes, continue                   @01A 14880000
         C     R14,=AL4(IXGRSNCODEWARNINGDEL) records deleted?     @01A 14890000
         JNE   LOGRERR             no, display error               @D2A 14900000
DPOINTDL MVC   LOGRMSGT,=CL10'IXGDELET-2' insert in case of error  @P6C 14910000
         IXGDELET STREAMTOKEN=STRTOKEN, delete records                 X14920000
               BLOCKS=RANGE,                                           X14930000
               BLOCKID=DELBLK,                                         X14940000
               ANSAREA=ANSAREA,                                        X14950000
               ANSLEN=ANSLEN,                                          X14960000
               RETCODE=RETCODE,                                        X14970000
               RSNCODE=RSNCODE                                          14980000
         CLC   RETCODE,=AL4(IXGRETCODEOK) did it work ok?          @P6C 14990000
         JNE   LOGRERR             no, display error                    15000000
DELDONE  DS    0H                                                       15010000
         TM    MFLAGS,NOBREND        Bypass REQUEST=END?           @02A 15020000
         JO    NOTDEL                Yes                           @02A 15030000
         MVC   LOGRMSGT,=CL10'IXGBRWSE-6' insert in case of error  @P6C 15040000
         IXGBRWSE REQUEST=END,                                         X15050000
               BROWSETOKEN=BRWTOKEN,                                   X15060000
               STREAMTOKEN=STRTOKEN,                                   X15070000
               ANSAREA=ANSAREA,                                        X15080000
               ANSLEN=ANSLEN,                                          X15090000
               RETCODE=RETCODE,                                        X15100000
               RSNCODE=RSNCODE                                     @D2A 15110000
         CLC   RETCODE,=AL4(IXGRETCODEOK) did it work ok?          @P6C 15120000
         JE    NOTDEL              yes, begin cleanup              @P9C 15130000
*********************************************************************** 15140000
*        Check for acceptable nonzero return/reason code           @P9A 15150000
*        combinations, including                                   @P9A 15160000
*        RC8/RS0804 - IXGRSNCODENOBLOCK - no block identifier      @P9A 15170000
*********************************************************************** 15180000
         CLC   RETCODE,=AL4(IXGRETCODEERROR) Return Code 8?        @P9A 15190000
         JNE   LOGRERR             no, display error               @P9A 15200000
         CLC   RSNCODE,=AL4(IXGRSNCODENOBLOCK) no block id?        @P9A 15210000
         JE    NOTDEL              yes, this condition is ok       @P9A 15220000
         JNE   LOGRERR             no, display error               @D2A 15230000
*********************************************************************** 15240000
* End DELETE                                                      @D2A* 15250000
*********************************************************************** 15260000
NOTDEL   DS    0H                                                  @D2A 15270000
*********************************************************************** 15280000
* Begin Cleanup                                                   @D2A* 15290000
*********************************************************************** 15300000
*                                                                 @D2A* 15310000
*  Disconnect from the log stream                                 @D2A* 15320000
*                                                                 @D2A* 15330000
*  Free the buffer area                                           @D2A* 15340000
*                                                                 @D2A* 15350000
*  Exit                                                           @D2A* 15360000
*                                                                 @D2A* 15370000
*********************************************************************** 15380000
         MVC   LOGRMSGT,=CL10'IXGCONN-2' insert in case of error   @P6C 15390000
         IXGCONN REQUEST=DISCONNECT, disconnect from the log stream    X15400000
               STREAMTOKEN=STRTOKEN,                                   X15410000
               ANSAREA=ANSAREA,                                        X15420000
               ANSLEN=ANSLEN,                                          X15430000
               RETCODE=RETCODE,                                        X15440000
               RSNCODE=RSNCODE                                          15450000
         CLC   RETCODE,=AL4(IXGRETCODEOK) did it work ok?          @P6C 15460000
         JNE   LOGRERR             no, display error                    15470000
*                                                                       15480000
         STORAGE RELEASE,LENGTH=STRBUFFL,ADDR=(R10) free the buffer     15490000
*                                                                  @TTA 15492000
         LT    R1,SDTTABLE         Address of system table         @TTA 15494000
         JZ    MDBLGXIT            None - exit program             @TTA 15496000
         STORAGE RELEASE,LENGTH=SDTTSIZE,ADDR=(R1)                 @TTA 15498000
*                                                                       15500000
MDBLGXIT PR    ,                   exit                            @TTC 15510000
*                                                                       15520000
*********************************************************************** 15530000
* End cleanup                                                         * 15540000
*********************************************************************** 15550000
*                                                                       15560000
*********************************************************************** 15570000
* Begin subroutines                                                   * 15580000
*********************************************************************** 15590000
*                                                                       15600000
*********************************************************************** 15610000
* CHKDATE - validate start/end date                                   * 15620000
*                                                                     * 15630000
*   Input:                                                            * 15640000
*     R9 -> date presumably in the form yyyyddd                       * 15650000
*     R14 = return address                                            * 15660000
*                                                                     * 15670000
*   Output:                                                           * 15680000
*     if date is valid, set r15 = 0, otherwise set r15 = nonzero      * 15690000
*********************************************************************** 15700000
CHKDATE  LA    R15,1(0,0)          assume date is invalid               15710000
         TRT   0(7,R9),NUMTAB      scan for numbers                     15720000
         BNZR  R14                 not all numbers, exit                15730000
         PACK  DATEWORK,0(7,R9)    pack the date                        15740000
         CP    DATEWORK+2(2),=P'366'    is it gt 366?                   15750000
         BHR   R14                 yes, error                           15760000
         JE    CHKDLEAP            366, must be a leap year             15770000
         CP    DATEWORK+2(2),=P'1' is it lt 1?                          15780000
         BLR   R14                 yes, error                           15790000
         SR    R15,R15             show date is valid                   15800000
         BR    R14                 exit                                 15810000
*        day is 366 -- make sure it's a leap year                       15820000
CHKDLEAP SRP   DATEWORK,64-3,0     shift out ddd                        15830000
         DP    DATEWORK,=PL1'4'    divide year by 4                     15840000
         CP    DATEWORK+3(1),=P'0' see if remainder is zero             15850000
         BNER  R14                 exit if not, error                   15860000
         SR    R15,R15             show date is valid                   15870000
         BR    R14                 exit                                 15880000
*                                                                       15890000
*********************************************************************** 15900000
* FIXDATE - adjust year after adding / subtracting days           @D2A* 15910000
*                                                                 @D2A* 15920000
*   Input:                                                        @D2A* 15930000
*     WORKDATE = date in the form yyyyddd packed; day may be zero @D2A* 15940000
*                or less, or over 365 (366 for leap years)        @D2A* 15950000
*     R14 = return address                                        @D2A* 15960000
*                                                                 @D2A* 15970000
*   Output:                                                       @D2A* 15980000
*     None; date in WORKDATE is adjusted to correct year and day  @D2A* 15990000
*********************************************************************** 16000000
FIXDATE  DS    0H                                                  @D2A 16010000
         MVC   DATEWRK1,DATEWORK   copy date                       @D2A 16020000
         OI    DATEWRK1+3,X'0F'    force sign positive             @D2A 16030000
         SRP   DATEWRK1,64-3,0     shift out ddd                   @D2A 16040000
         NC    DATEWORK,=X'0000FFFF' zero out year in datework     @D2A 16050000
FIXDBACK DS    0H   back up year if day is zero or less            @D2A 16060000
         CP    DATEWORK,=PL1'0'    is the day zero?                @D2A 16070000
         JH    FIXDFWD             >0, ok                          @D2A 16080000
*        day is 0 or less; adjust day and back up to previous year @D2A 16090000
         AP    DATEWORK,=P'365'    adjust day                      @D2A 16100000
         SP    DATEWRK1,=PL1'1'    subtract 1 from year            @D2A 16110000
*        if leap year, add 1 to day                                @D2A 16120000
         MVC   DATEWRK2,DATEWRK1   copy the year                   @D2A 16130000
         DP    DATEWRK2,=PL1'4'    divide by 4                     @D2A 16140000
         CP    DATEWRK2+3(1),=PL1'0' is remainder zero (leap yr)?  @D2A 16150000
         JNE   FIXDBACK            no, not leap year,loop          @D2A 16160000
         AP    DATEWORK,=PL1'1'    add 1 to day                    @D2A 16170000
         J     FIXDBACK            loop                            @D2A 16180000
FIXDFWD  DS    0H   add to year if day is over 365 (366 if leap yr)@D2A 16190000
         MVC   DATEWRK2,DATEWRK1   copy the year                   @D2A 16200000
         DP    DATEWRK2,=PL1'4'    divide by 4                     @D2A 16210000
         CP    DATEWRK2+3(1),=PL1'0' is remainder zero (leap yr)?  @D2A 16220000
         JE    FIXDFWDL            yes                             @D2A 16230000
*        not leap year                                             @D2A 16240000
         CP    DATEWORK,=PL2'365'  is day over 365?                @D2A 16250000
         JNH   FIXDDONE            no, done                        @D2A 16260000
         SP    DATEWORK,=PL2'365'  subtract 365 from day           @D2A 16270000
FIXDFWDA AP    DATEWRK1,=PL1'1'    add 1 to year                   @D2A 16280000
         J     FIXDFWD             loop back                       @D2A 16290000
*        leap year                                                 @D2A 16300000
FIXDFWDL CP    DATEWORK,=PL2'366'  is day over 366?                @D2A 16310000
         JNH   FIXDDONE            no, done                        @D2A 16320000
         SP    DATEWORK,=PL2'366'  subtract 366 from day           @D2A 16330000
         J     FIXDFWDA            add to year                     @D2A 16340000
FIXDDONE SRP   DATEWRK1,3,0        adjust year to form yyyyddd     @D2A 16350000
         AP    DATEWORK,DATEWRK1   add year back in                @D2A 16360000
         BR    R14                 exit                            @D2A 16370000
*                                                                  @D2A 16380000
*********************************************************************** 16390000
* CONVSTCK -Convert date from yyyyddd to stck format              @D2A* 16400000
*                                                                 @D2A* 16410000
*   Input:                                                        @D2A* 16420000
*     R3 -> date to convert, yyyyddd packed                       @D2A* 16430000
*     R4 -> field to hold STCK format date                        @D2A* 16440000
*     R14 = return address                                        @D2A* 16450000
*                                                                 @D2A* 16460000
*   Output:                                                       @D2A* 16470000
*     None; converted date is stored at address in R4.            @D2A* 16480000
*     Branches to BADPARM if conversion fails.                    @D2A* 16490000
*     Returns with no change if input date is binary zero.        @D2A* 16500000
*********************************************************************** 16510000
CONVSTCK BAKR  R14,0               save caller's environment       @D2A 16520000
         CLC   0(7,R3),=XL7'0'     is input date zero?             @D2A 16530000
         JE    CONVDONE            yes, just return                @D2A 16540000
         PACK  CONVDATE,0(7,R3)    move date to parm area          @D2A 16550000
         SP    CONVDATE,=P'1900000' strip off century              @D2A 16560000
         CONVTOD CONVVAL=CONVWORK,  convert to stck value              X16570000
               TODVAL=(R4),                                            X16580000
               TIMETYPE=BIN,                                           X16590000
               DATETYPE=YYDDD                                      @D2A 16600000
         LTR   R15,R15             did it work?                    @D2A 16610000
         JNZ   BADPARM             no, error                       @D2A 16620000
CONVDONE PR    ,                   return                          @D2A 16630000
*                                                                       16640000
*********************************************************************** 16650000
* MESSR -- Display a message                                          * 16660000
*                                                                     * 16670000
*   Input:                                                            * 16680000
*     r2 -> text of message                                           * 16690000
*     R14 = return address                                            * 16700000
*********************************************************************** 16710000
MESSR    DS    0H                                                       16720000
         BAKR  R14,0               save caller's environment            16730000
         WTO   TEXT=(R2),          display message                     X16740000
               ROUTCDE=(2,11)                                           16750000
         PR                        return to caller                     16760000
*                                                                  @TTA 16760118
******************************************************************@TTA* 16760218
* PARSINIT -- Parse JES3 MAINPROC and MSGROUTE initialization     @TTA* 16760318
*             statements if present.                              @TTA* 16760418
*                                                                 @TTA* 16760518
* It is assumed the syntax conforms to the JES3 Initialization    @TTA* 16760618
* rules.  We will be looking for 'MAINPROC' or 'MSGROUTE' at      @TTA* 16760718
* the beginning of a statement and then scan for the keywords     @TTA* 16760818
* of interest:                                                    @TTA* 16760918
* MAINPROC: NAME= and ID=                                         @TTA* 16761000
* MSGROUTE: All                                                   @TTA* 16761110
*                                                                 @TTA* 16761215
* No error messages are issued for syntax errors; rather, the     @TTA* 16761318
* rest of the statement is skipped.                               @TTA* 16761418
******************************************************************@TTA* 16761518
PARSINIT DS    0H                                                  @TTA 16761618
         BAKR  R14,0               Save caller's environment       @TTA 16761718
*-----------------------------------------------------------------@TTA* 16761818
*        Check if JES3IN DD was included in the JCL.              @TTA* 16761918
*-----------------------------------------------------------------@TTA* 16762018
         EXTRACT TIOTADDR,FIELDS=(TIOT),  Get address of TIOT      @TTA+16762118
               MF=(E,EXTRLIST)                                     @TTA 16762200
         L     R1,TIOTADDR         Load @ of TIOT                  @TTA 16762310
         USING TIOT,R1             Assembler addressability        @TTA 16762418
         LA    R2,TIOENTRY         1. DD entry                     @TTA 16762518
         DROP  R1                  TIOT                            @TTA 16762618
         USING TIOENTRY,R2         TIOT entry addressability       @TTA 16762718
         LA    R4,J3INDCB          JES3IN DCB                      @TTA 16762818
         XR    R3,R3               Clear for insert                @TTA 16762918
DDNSCAN  IC    R3,TIOELNGH         DD entry length                 @TTA 16763018
         LTR   R3,R3               Zero (end) ?                    @TTA 16763118
         JZ    PARSEXIT            Yes, nothing to do              @TTA 16763200
         USING IHADCB,R4           JES3IN DCB addressability       @TTA 16763310
         CLC   DCBDDNAM,TIOEDDNM   JES3IN DD?                      @TTA 16763418
         JE    DDFOUND             Yes, open JES3IN                @TTA 16763518
         AR    R2,R3               Step up to the next DD entry    @TTA 16763618
         J     DDNSCAN             Continue TIOT scan              @TTA 16763718
         DROP  R2,R4               TIOENTRY, IHADCB                @TTA 16763818
*-----------------------------------------------------------------@TTA* 16763918
*        Obtain 24-byte storage for the output DCB                @TTA* 16764018
*-----------------------------------------------------------------@TTA* 16764118
DDFOUND  STORAGE OBTAIN,LENGTH=IFILDCBL,LOC=24  Get DCB storage    @TTA 16764200
         ST    R1,IDCBADDR         Save for later                  @TTA 16764310
         LR    R2,R1               Copy address to work reg.       @TTA 16764418
         MVC   0(IFILDCBL,R2),J3INDCB  Copy the DCB                @TTA 16764518
*-----------------------------------------------------------------@TTA* 16764618
*        Open the JES3IN input file                               @TTA* 16764718
*-----------------------------------------------------------------@TTA* 16764818
         OPEN  ((R2),INPUT),       Open the file                   @TTA+16764918
               MODE=31,                                            @TTA+16765018
               MF=(E,OPENLIST)                                     @TTA 16765118
         C     R15,=F'8'           See if open worked              @TTA 16765200
         JL    GETSDT              Continue if so                  @TTA 16765310
         ABEND 3,DUMP                                              @TTA 16765418
*-----------------------------------------------------------------@TTA* 16765518
*        Obtain storage for the System Definitions Table          @TTA* 16765618
*-----------------------------------------------------------------@TTA* 16765718
GETSDT   STORAGE OBTAIN,LENGTH=SDTTSIZE  Get SDT storage           @TTA 16765818
         ST    R1,SDTTABLE         save its address                @TTA 16765918
         LR    R0,R1               Set up for MVCL                 @TTA 16766018
         LHI   R1,SDTTSIZE         Table size                      @TTA 16766118
         XR    R15,R15             Clear padding & length          @TTA 16766200
         ICM   R15,B'1000',=X'FF'  Fill character                  @TTA 16766310
         MVCL  R0,R14              Clear obtained storage          @TTA 16766418
         L     R1,SDTTABLE         Reload the table address        @TTA 16766518
         AHI   R0,-SDTENLEN        Calculate address of last       @TTA+16766618
                                     entry                         @TTA 16766718
         ST    R0,SDTLAST          Save for JXLE search            @TTA 16766818
*-----------------------------------------------------------------@TTA* 16766918
*        Get the first record of a statement                      @TTA* 16767018
*-----------------------------------------------------------------@TTA* 16767118
READSTMT MVI   SCANFLAG,0          Reset 'statement is             @TTA+16767218
                                     continued'                    @TTA 16767318
*-----------------------------------------------------------------@TTA* 16767418
*        Get one JES3IN record                                    @TTA* 16767500
*-----------------------------------------------------------------@TTA* 16767610
READIN   JAS   R14,READREC         Get the next record             @TTA 16767718
         LTR   R15,R15             Good return?                    @TTA 16767818
         JNZ   PARSEXIT            No, exit                        @TTA 16767918
         LM    R1,R3,INPOINT       Set up registers for scan       @TTA 16768018
         CLC   MAINPROC,0(R1)      Is it MAINPROC?                 @TTA 16768118
         JE    MAINPFND            Yes, go handle                  @TTA 16768218
         CLC   MSGROUTE,0(R1)      Is it MSGROUTE?                 @TTA 16768318
         JE    MSGRTFND            Yes, go handle                  @TTA 16768418
*-----------------------------------------------------------------@TTA* 16768500
*        Statement is not of interest.  Skip to the end.          @TTA* 16768610
*-----------------------------------------------------------------@TTA* 16768718
         OI    SCANFLAG,SCANSKIP   Set skipping till the end       @TTA 16768818
         J     READIN              Go read until the next stmt.    @TTA 16768918
******************************************************************@TTA* 16769018
*        MAINPROC was found                                       @TTA* 16769118
******************************************************************@TTA* 16769218
MAINPFND LA    R1,L'MAINPROC(,R1)  Point past comma                @TTA 16769318
         CR    R1,R3               Are we at the end?              @TTA 16769418
         JL    MAINCONT            Not yet, continue scan          @TTA 16769500
         JAS   R14,READREC         Go read next record             @TTA 16769618
         LTR   R15,R15             Good return?                    @TTA 16769718
         JNZ   PARSEXIT            No, exit                        @TTA 16769818
         LM    R1,R3,INPOINT       Set up registers for scan       @TTA 16769918
MAINCONT CLI   0(R1),C' '          Any other keyword?              @TTA 16770018
         JNE   KEYWDCHK            Maybe, scan some more           @TTA 16770118
         JAS   R14,READREC         Get the next record             @TTA 16770218
         LTR   R15,R15             Good return?                    @TTA 16770300
         JNZ   PARSEXIT            No, exit                        @TTA 16770410
         LM    R1,R3,INPOINT       Set up registers for scan       @TTA 16770518
*-----------------------------------------------------------------@TTA* 16770618
*        Check for NAME= or ID= or end of record/statement        @TTA* 16770718
*-----------------------------------------------------------------@TTA* 16770818
KEYWDCHK CLC   MAINNAME,0(R1)      Is it NAME= ?                   @TTA 16770918
         JE    NAMEFND             Yes, go handle                  @TTA 16771018
         CLC   MAINID,0(R1)        Is it ID= ?                     @TTA 16771118
         JE    IDFOUND             Yes, go handle                  @TTA 16771218
         CLI   0(R1),C' '          End of the statement?           @TTA 16771300
         JE    READSTMT            Yes, go handle                  @TTA 16771410
         CLI   0(R1),C','          Separator?                      @TTA 16771518
         JNE   KEYWDCT             No, continue scan               @TTA 16771618
         CLI   1(R1),C' '          Followed by a blank?            @TTA 16771718
         JE    READSTMT            Yes, end of statement           @TTA 16771818
KEYWDCT  JXLE  R1,R2,KEYWDCHK      Continue search                 @TTA 16771918
*-----------------------------------------------------------------@TTA* 16772018
*        We have reached the end of the record without            @TTA* 16772118
*        finding any continuation character.  Go skip over        @TTA* 16772218
*        the rest of the statement.                               @TTA* 16772300
*-----------------------------------------------------------------@TTA* 16772410
         J     READSKIP            Read the next record            @TTA 16772518
*-----------------------------------------------------------------@TTA* 16772618
*        The NAME keyword was found.  Set up for scanning of the  @TTA* 16772718
*        specified name.                                          @TTA* 16772818
*-----------------------------------------------------------------@TTA* 16772918
NAMEFND  AHI   R1,L'MAINNAME       Skip past the NAME=             @TTA 16773018
         CR    R1,R3               Are we at the end?              @TTA 16773118
         JNL   READSKIP            Already past - ignore the       @TTA+16773218
                                     rest of the statement         @TTA 16773300
         LR    R4,R1               Copy starting point             @TTA 16773410
*-----------------------------------------------------------------@TTA* 16773518
*        Scan for blank or comma                                  @TTA* 16773618
*-----------------------------------------------------------------@TTA* 16773718
NAMEEND  CLI   0(R1),C' '          Blank found?                    @TTA 16773818
         JE    BLNKFND             Yes, get the name               @TTA 16773918
         CLI   0(R1),C','          Comma found?                    @TTA 16774018
         JE    COMMAPRM            Yes                             @TTA 16774118
         JXLE  R1,R2,NAMEEND       Go search for main name end     @TTA 16774218
         CLI   1(R1),C' '          Continuation character?         @TTA 16774300
         JE    BLNKFND             No, continue                    @TTA 16774410
*-----------------------------------------------------------------@TTA* 16774518
*        End of system name found - validate length               @TTA* 16774618
*-----------------------------------------------------------------@TTA* 16774718
COMMAPRM DS    0H                                                  @TTA 16774818
BLNKFND  LR    R15,R1              Copy end address                @TTA 16774918
         SR    R15,R4              Determine length                @TTA 16775018
         JM    CONTSCAN            Go if negative                  @TTA 16775118
         CHI   R15,L'SDTSYSNM      Too long?                       @TTA 16775218
         JH    CONTSCAN            Yes, skip it                    @TTA 16775300
*-----------------------------------------------------------------@TTA* 16775410
*        Save the name in an SDT entry                            @TTA* 16775515
*-----------------------------------------------------------------@TTA* 16775618
         LM    R5,R7,SDTTABLE      Address of the SDT,             @TTA+16775718
                                     increment and last entry      @TTA+16775818
                                     address                       @TTA 16775918
         USING SDTENTRY,R5         Establish addressability        @TTA 16776018
         AHI   R15,-1              Subtract one for EX instr.      @TTA 16776118
SDTSRCH  CLI   0(R5),X'FF'         End of entries?                 @TTA 16776218
         JE    SDTTHIS             Yes, initialize this entry      @TTA 16776318
         EX    R15,CHKSYSNM        Is the name in the table?       @TTA 16776418
         JE    SDTTHIS             Yes, found it                   @TTA 16776500
         JXLE  R5,R6,SDTSRCH       No, Continue search             @TTA 16776610
         L     R5,SDTTABLE         Reuse the first entry           @TTA 16776718
SDTTHIS  MVC   SDTSYSNM,BLANKS     Make sure name is blank         @TTA 16776818
         MVI   SDTIDLEN,0          Clear Receive ID length         @TTA 16776918
         MVI   SDTEFLAG,0          Clear flags                     @TTA 16777018
         EX    R15,MVSYSNM         Copy the system name            @TTA 16777118
MDBLGDAT LOCTR                     Resume data segment             @TTA 16777218
CHKSYSNM CLC   SDTSYSNM(0),0(R4)   Check system name               @TTA 16777318
MVSYSNM  MVC   SDTSYSNM(0),0(R4)   Copy system name                @TTA 16777418
MDBLGCOD LOCTR                     Resume code segment             @TTA 16777500
         CLC   SDTMSGRT,=X'FFFFFFFF'  Table pointer                @TTA+16777610
                                     uninitialized?                @TTA 16777718
         JNE   CONTSCAN            No, continue scan               @TTA 16777818
         XC    SDTMSGRT,SDTMSGRT   Clear the pointer               @TTA 16777918
*-----------------------------------------------------------------@TTA* 16778018
*        Check if at the end of the record and/or if the          @TTA* 16778118
*        record is continued                                      @TTA* 16778218
*-----------------------------------------------------------------@TTA* 16778318
CONTSCAN CR    R1,R3               Are we there yet?               @TTA 16778418
         JL    KEYWDCHK            No, go check for keywords       @TTA 16778500
         TM    SCANFLAG,SCANCONT   Continue statement?             @TTA 16778610
         JZ    READIN              No, read the next statement     @TTA 16778718
         JAS   R14,READREC         Go read next record             @TTA 16778818
         LTR   R15,R15             Good return?                    @TTA 16778918
         JNZ   PARSEXIT            No, exit                        @TTA 16779018
         LM    R1,R3,INPOINT       Set up registers for scan       @TTA 16779118
         J     KEYWDCHK            And check for our keywords      @TTA 16779218
*-----------------------------------------------------------------@TTA* 16779318
*        The ID keyword was found.  Set up for scanning the       @TTA* 16779418
*        specified id.                                            @TTA* 16779500
*-----------------------------------------------------------------@TTA* 16779610
IDFOUND  AHI   R1,L'MAINID         Skip past the ID=               @TTA 16779718
         CR    R1,R3               Are we at the end?              @TTA 16779818
         JNL   READSKIP            Already past - ignore the       @TTA+16779918
                                     rest of the statement         @TTA 16780018
         LR    R4,R1               Copy starting point             @TTA 16780118
*-----------------------------------------------------------------@TTA* 16780218
*        Scan for blank or comma                                  @TTA* 16780318
*-----------------------------------------------------------------@TTA* 16780418
IDEND    CLI   0(R1),C' '          Blank found?                    @TTA 16780500
         JE    BLNKID              Yes, get the id                 @TTA 16780610
         CLI   0(R1),C','          Comma found?                    @TTA 16780718
         JE    COMMAID             Yes                             @TTA 16780818
         JXLE  R1,R2,IDEND         Go search for main id end       @TTA 16780918
         CLI   1(R1),C' '          Continuation character?         @TTA 16781018
         JE    BLNKID              No, continue                    @TTA 16781118
*-----------------------------------------------------------------@TTA* 16781218
*        End of system id found - validate length                 @TTA* 16781318
*-----------------------------------------------------------------@TTA* 16781418
COMMAID  DS    0H                                                  @TTA 16781500
BLNKID   LR    R15,R1              Copy end address                @TTA 16781610
         SR    R15,R4              Determine length                @TTA 16781718
         JNP   KEEPSCAN            Go if negative or zero          @TTA 16781818
*-----------------------------------------------------------------@TTA* 16781918
*        If the last character of ID is '#', the customer         @TTA* 16782018
*        wants to use the sysid= notation instead of sysid R=.    @TTA* 16782118
*-----------------------------------------------------------------@TTA* 16782218
         LR    R14,R1              Copy separator address          @TTA 16782318
         AHI   R14,-1              Subtract one                    @TTA 16782418
         CLI   0(R14),C'#'         Is it '#' ?                     @TTA 16782500
         JNE   SAVRIDLN            No, go save the length          @TTA 16782610
         AHI   R15,-1              Reduce length                   @TTA 16782718
         CH    R15,=AL2(L'SDTRCHAR) Too long?                      @TTA 16782818
         JH    KEEPSCAN            Yes, skip it                    @TTA 16782918
         OI    SDTEFLAG,SDTNOR     Indicate no R=                  @TTA 16783018
*-----------------------------------------------------------------@TTA* 16783118
*        Save the id in the next RID entry                        @TTA* 16783218
*-----------------------------------------------------------------@TTA* 16783318
         USING SDTENTRY,R5         Establish addressability        @TTA 16783418
SAVRIDLN CH    R15,=AL2(L'SDTRCHAR) Too long?                      @TTA 16783500
         JH    KEEPSCAN            Yes, skip it                    @TTA 16783610
         MVC   SDTRCHAR,BLANKS     Blank out first                 @TTA 16783718
         STC   R15,SDTIDLEN        Save length                     @TTA 16783818
         AHI   R15,-1              Subtract one for EX instr.      @TTA 16783918
         EX    R15,MVSYSID         Copy the system ID              @TTA 16784018
MDBLGDAT LOCTR                     Resume data segment             @TTA 16784118
MVSYSID  MVC   SDTRCHAR(0),0(R4)   Copy system ID                  @TTA 16784218
MDBLGCOD LOCTR                     Resume code segment             @TTA 16784318
*-----------------------------------------------------------------@TTA* 16784418
*        Check if at the end of the record and/or if the          @TTA* 16784500
*        record is continued                                      @TTA* 16784610
*-----------------------------------------------------------------@TTA* 16784718
KEEPSCAN CR    R1,R3               Are we there yet?               @TTA 16784818
         JL    KEYWDCHK            No, go check for keywords       @TTA 16784918
         TM    SCANFLAG,SCANCONT   Continued statement?            @TTA 16785018
         JZ    KEYWDCHK            No, check for our keywords      @TTA 16785118
         JAS   R14,READREC         Go read the next record         @TTA 16785218
         LTR   R15,R15             Good return?                    @TTA 16785318
         JNZ   PARSEXIT            No, exit                        @TTA 16785418
         LM    R1,R3,INPOINT       Set up registers for scan       @TTA 16785500
         J     KEYWDCHK            And check for our keywords      @TTA 16785610
******************************************************************@TTA* 16785718
*        MSGROUTE was found                                       @TTA* 16785818
******************************************************************@TTA* 16785918
MSGRTFND LA    R1,L'MSGROUTE(,R1)  Point past comma                @TTA 16786018
         CR    R1,R3               Are we there yet?               @TTA 16786118
         JL    MSGRKWCK            No, go check for keywords       @TTA 16786218
         TM    SCANFLAG,SCANCONT   Continue statement?             @TTA 16786318
         JZ    READIN              No, something wrong, read       @TTA+16786418
                                     the next statement            @TTA 16786500
         JAS   R14,READREC         Go read next record             @TTA 16786610
         LTR   R15,R15             Good return?                    @TTA 16786718
         JNZ   PARSEXIT            No, exit                        @TTA 16786818
         LM    R1,R3,INPOINT       Set up registers for scan       @TTA 16786918
*-----------------------------------------------------------------@TTA* 16787018
*        Check for NAME=                                          @TTA* 16787118
*-----------------------------------------------------------------@TTA* 16787218
MSGRKWCK CLC   MAINKWD,0(R1)       Is it NAME= ?                   @TTA 16787318
         JE    MSGRNFND            Yes, go handle                  @TTA 16787418
         CLI   0(R1),C' '          End of the statement?           @TTA 16787500
         JE    READSTMT            Yes, go handle                  @TTA 16787610
         CLI   0(R1),C','          Separator?                      @TTA 16787718
         JNE   MSGRDCT             No, continue scan               @TTA 16787818
         CLI   1(R1),C' '          Followed by a blank?            @TTA 16787918
         JE    READSTMT            Yes, end of statement           @TTA 16788018
MSGRDCT  JXLE  R1,R2,MSGRKWCK      Continue search                 @TTA 16788118
*-----------------------------------------------------------------@TTA* 16788218
*        We have reached the end of the record without            @TTA* 16788318
*        finding any continuation character.  Skip the            @TTA* 16788418
*        rest of the statement.                                   @TTA* 16788500
*-----------------------------------------------------------------@TTA* 16788610
         J     READSKIP            Read the next record            @TTA 16788718
*-----------------------------------------------------------------@TTA* 16788818
*        The NAME keyword was found.  Set up for scanning the     @TTA* 16788918
*        specified name.                                          @TTA* 16789018
*-----------------------------------------------------------------@TTA* 16789118
MSGRNFND AHI   R1,L'MAINKWD        Skip past the NAME=             @TTA 16789218
         CR    R1,R3               Are we at the end?              @TTA 16789318
         JNL   READSKIP            Already past - ignore the       @TTA+16789418
                                     rest of the statement         @TTA 16789500
         LR    R4,R1               Copy starting point             @TTA 16789610
*-----------------------------------------------------------------@TTA* 16789718
*        Scan for blank or comma                                  @TTA* 16789818
*-----------------------------------------------------------------@TTA* 16789918
MSGRNEMD CLI   0(R1),C' '          Blank found?                    @TTA 16790018
         JE    MSGRBLK             Yes, get the name               @TTA 16790118
         CLI   0(R1),C','          Comma found?                    @TTA 16790218
         JE    MSGRCOMA            Yes                             @TTA 16790318
         JXLE  R1,R2,MSGRNEMD      Go search for main name end     @TTA 16790418
         CLI   1(R1),C' '          Continuation character?         @TTA 16790500
         JE    MSGRBLK             No, continue                    @TTA 16790610
*-----------------------------------------------------------------@TTA* 16790718
*        End of system name found - validate length               @TTA* 16790818
*-----------------------------------------------------------------@TTA* 16790918
MSGRCOMA DS    0H                                                  @TTA 16791018
MSGRBLK  LR    R15,R1              Copy end address                @TTA 16791118
         SR    R15,R4              Determine length                @TTA 16791218
         JM    READSKIP            Go if negative                  @TTA 16791318
         CHI   R15,L'SDTSYSNM      Too long?                       @TTA 16791418
         JH    READSKIP            Yes, skip it                    @TTA 16791500
*-----------------------------------------------------------------@TTA* 16791610
*        Save the name in an SDT entry (unless already saved      @TTA* 16791718
*        in MAINPROC processing)                                  @TTA* 16791818
*-----------------------------------------------------------------@TTA* 16791918
         LM    R5,R7,SDTTABLE      Address of the SDT,             @TTA+16792018
                                     increment and last entry      @TTA+16792118
                                     address                       @TTA 16792218
         USING SDTENTRY,R5         Establish addressability        @TTA 16792318
         AHI   R15,-1              Subtract one for EX instr.      @TTA 16792418
SRCHSDTN CLI   0(R5),X'FF'         End of entries?                 @TTA 16792518
         JE    THISSDTE            Yes, initialize this entry      @TTA 16792618
         EX    R15,CHKSYSNM        Is the name in the table?       @TTA 16792700
         JE    GETMSGRT            Yes, obtain MSGROUTE table      @TTA 16792810
         JXLE  R5,R6,SRCHSDTN      No, get next entry address      @TTA 16792918
         J     READSKIP            Skip this MSGROUTE if system    @TTA+16793018
                                     table is full                 @TTA 16793118
THISSDTE MVC   SDTSYSNM,BLANKS     Make sure name is blank         @TTA 16793218
         EX    R15,MVSYSNM         Copy the system name            @TTA 16793318
*-----------------------------------------------------------------@TTA* 16793418
*        Obtain storage for the MSGROUTE table                    @TTA* 16793518
*-----------------------------------------------------------------@TTA* 16793618
GETMSGRT LT    R4,SDTMSGRT         Get possible table pointer      @TTA 16793718
         JZ    MSGRGETS            None, get storage               @TTA 16793800
         CLC   SDTMSGRT,=X'FFFFFFFF'  Table pointer                @TTA+16793910
                                     uninitialized?                @TTA 16794018
         JNE   SAVMSGRT            No, set current MSGROUTE        @TTA+16794118
                                     pointer                       @TTA 16794218
MSGRGETS ST    R1,INPOINT          Save current pointer            @TTA 16794318
         STORAGE OBTAIN,LENGTH=MGRTSIZE  Get MSGROUTE storage      @TTA 16794418
         ST    R1,SDTMSGRT         Save its address                @TTA 16794518
         LR    R4,R1               Save for later                  @TTA 16794618
         LR    R0,R1               Set up for MVCL                 @TTA 16794718
         LHI   R1,MGRTSIZE         Table size                      @TTA 16794800
         XR    R15,R15             Clear padding & length          @TTA 16794910
         MVCL  R0,R14              Set obtained storage to all     @TTA+16795018
                                     zeros                         @TTA 16795118
         L     R1,INPOINT          Restore current pointer         @TTA 16795218
SAVMSGRT ST    R4,CURRMSGR         Save as current MSGROUTE        @TTA 16795318
*-----------------------------------------------------------------@TTA* 16795418
*        Check if at the end of the record and/or if the          @TTA* 16795518
*        record is continued                                      @TTA* 16795618
*-----------------------------------------------------------------@TTA* 16795718
         AHI   R1,1                Skip past the comma             @TTA 16795800
         CR    R1,R3               Are we there yet?               @TTA 16795910
         JL    INITRTC             No, scan the routcode value     @TTA 16796018
         TM    SCANFLAG,SCANCONT   Continue statement?             @TTA 16796118
         JZ    READSKIP            No, something wrong, skip       @TTA 16796218
         JAS   R14,READREC         Yes, read the next record       @TTA 16796318
         LTR   R15,R15             Good return?                    @TTA 16796418
         JNZ   PARSEXIT            No, exit                        @TTA 16796518
         L     R1,INPOINT          Get first character pointer     @TTA 16796618
*-----------------------------------------------------------------@TTA* 16796718
*        Scan the routcode and set up R5 to point to the          @TTA* 16796800
*        MSGROUTE table entry                                     @TTA* 16796910
*-----------------------------------------------------------------@TTA* 16797018
INITRTC  XR    R3,R3               Clear collector register        @TTA 16797118
         LHI   R2,RTCODTB1         Maximum number of digits        @TTA 16797218
         XR    R0,R0               Clear work register             @TTA 16797318
         LHI   R15,X'0F'           'AND' mask to extract digits    @TTA 16797418
IATM035  IC    R0,0(0,R1)          Insert digit                    @TTA 16797518
         NR    R0,R15              AND off zone                    @TTA 16797618
         ALR   R3,R0               Combine digits                  @TTA 16797718
         CLI   1(R1),C'='          Any more digits?                @TTA 16797800
         JE    IATM040             No, we are done                 @TTA 16797910
         MHI   R3,10               Account for next digit          @TTA 16798018
         AHI   R1,1                Point to next digit             @TTA 16798118
         JCT   R2,IATM035          Check next digit                @TTA 16798218
         J     READSKIP            More than 3 digits - skip       @TTA+16798318
                                     until the next stmt           @TTA 16798418
IATM040  AHI   R1,2                Skip past the equal sign        @TTA 16798518
         ST    R1,INPOINT          Save for later                  @TTA 16798618
         CHI   R3,128              Greater than limit?             @TTA 16798718
         JH    READSKIP            Yes, error                      @TTA 16798800
         LTR   R3,R3               Check if zero                   @TTA 16798910
         JZ    READSKIP            Yes, error                      @TTA 16799018
         BCTR  R3,0                Decrement for index             @TTA 16799118
         LA    R2,MGRESIZE         Table entry size                @TTA 16799218
         MR    R2,R2               Calculate table index           @TTA 16799318
         L     R5,CURRMSGR         Get current MSGROUTE table      @TTA 16799418
         AR    R5,R3               Index into table                @TTA 16799518
         USING MGRENTRY,R5         MSGROUTE entry addr'ty          @TTA 16799618
*-----------------------------------------------------------------@TTA* 16799718
*        Scan the rest of the routcode 'keyword'                  @TTA* 16799800
*-----------------------------------------------------------------@TTA* 16799910
         LM    R1,R3,INPOINT       Set up registers for scan       @TTA 16800018
         CLI   0(R1),C'('          Opening parenthesis?            @TTA 16800118
         JNE   READSKIP            No, that's an error -           @TTA+16800218
                                     ignore rest of statement      @TTA 16800318
         AHI   R1,1                Skip past the paren             @TTA 16800418
         LR    R4,R1               Copy starting point             @TTA 16800518
*-----------------------------------------------------------------@TTA* 16800618
*        Scan for comma or right parenthesis                      @TTA* 16800718
*-----------------------------------------------------------------@TTA* 16800800
MSGRTEND CLI   0(R1),C','          Comma found?                    @TTA 16800910
         JE    COMMAMGR            Yes                             @TTA 16801018
         CLI   0(R1),C')'          Right paren?                    @TTA 16801118
         JE    COMMAMGR            Yes, end of one routcode        @TTA 16801218
         JXLE  R1,R2,MSGRTEND      Go search for main id end       @TTA 16801318
*-----------------------------------------------------------------@TTA* 16801418
*        End of DEST class found - validate length                @TTA* 16801518
*-----------------------------------------------------------------@TTA* 16801618
COMMAMGR LR    R15,R1              Copy end address                @TTA 16801718
         SR    R15,R4              Determine length                @TTA 16801800
         JM    READSKIP            Go if negative                  @TTA 16801910
         JZ    SCANCONN            Go look for console name if     @TTA+16802018
                                     no dest specified             @TTA 16802118
         CHI   R15,RTCODTB1        Too long?                       @TTA 16802218
         JH    READSKIP            Yes, skip it                    @TTA 16802318
*-----------------------------------------------------------------@TTA* 16802418
*        Look up the name in the table to and calculate its       @TTA* 16802518
*        routcode equivalent                                      @TTA* 16802618
*-----------------------------------------------------------------@TTA* 16802718
         ST    R1,INPOINT          Save next character pointer     @TTA 16802800
         BCTR  R15,0               Subtract one for MVC            @TTA 16802910
         LA    R1,RTCODTBL         Routing codes table             @TTA 16803018
         LA    R3,RTCODTBE-RTCODTB1  Last entry address            @TTA 16803118
         LA    R2,RTCODTB1         Increment                       @TTA 16803218
RTCOMP   EX    R15,COMPDEST        Compare destinations            @TTA 16803318
MDBLGDAT LOCTR                                                     @TTA 16803418
COMPDEST CLC   0(0,R1),0(R4)       Compare destinations            @TTA 16803518
MDBLGCOD LOCTR                                                     @TTA 16803618
         JE    CALCRTCD            Match - go calculate routing    @TTA+16803718
                                     code                          @TTA 16803800
         JXLE  R1,R2,RTCOMP        Try again...                    @TTA 16803910
         L     R1,INPOINT          Restore R1                      @TTA 16804018
         J     SCANCONN            No match - ignore it            @TTA 16804118
CALCRTCD LA    R15,RTCODTBL        Table begin                     @TTA 16804218
         SR    R1,R15              Get offset                      @TTA 16804318
         XR    R0,R0               Clear for Divide                @TTA 16804418
         D     R0,=A(RTCODTB1)     Calculate routing code          @TTA+16804518
                                     (zero origin)                 @TTA 16804618
         AHI   R1,1                Adjust for 1 origin             @TTA 16804718
*-----------------------------------------------------------------@TTA* 16804818
*        Save route code value in the MSGROUTE table              @TTA* 16804900
*-----------------------------------------------------------------@TTA* 16805010
         STH   R1,MGRROUT          Save route code value           @TTA 16805118
         LM    R1,R3,INPOINT       Restore scan registers          @TTA 16805218
*-----------------------------------------------------------------@TTA* 16805318
*        Look for console name                                    @TTA* 16805418
*-----------------------------------------------------------------@TTA* 16805518
SCANCONN CLI   0(R1),C')'          Did we find the closing         @TTA+16805618
                                     parenthesis?                  @TTA 16805700
         JE    RPRNMGR             Yes, go handle                  @TTA 16805810
         CLI   0(R1),C' '          End of statement?               @TTA 16805918
         JE    READSTMT            Yes, go read the next           @TTA 16806018
         CLI   0(R1),C','          Comma?                          @TTA 16806118
         JNE   READSKIP            No, skip this stmt.             @TTA 16806218
         AHI   R1,1                Skip past the ','               @TTA 16806318
         LR    R4,R1               Copy starting point             @TTA 16806418
*-----------------------------------------------------------------@TTA* 16806518
*        Scan for comma or right parenthesis                      @TTA* 16806618
*-----------------------------------------------------------------@TTA* 16806700
MSGCNEND CLI   0(R1),C','          Comma found?                    @TTA 16806810
         JE    COMMACOM            Yes                             @TTA 16806918
         CLI   0(R1),C')'          Right paren?                    @TTA 16807018
         JE    COMMACOM            Yes, check what we found        @TTA 16807118
         JXLE  R1,R2,MSGCNEND      Go search for console name      @TTA+16807218
                                     end                           @TTA 16807318
         J     READSKIP            No end found                    @TTA 16807418
*-----------------------------------------------------------------@TTA* 16807518
*        End of console name found - validate length              @TTA* 16807618
*-----------------------------------------------------------------@TTA* 16807700
COMMACOM MVC   MGRCON,BLANKS       Initialize with blanks          @TTA 16807805
         LR    R15,R1              Copy end address                @TTA 16807910
         SR    R15,R4              Determine length                @TTA 16808015
         JM    READSKIP            Go if negative                  @TTA 16808118
         JZ    CHECKJ              Go look for 'J' if no           @TTA+16808218
                                     console name specified        @TTA 16808318
         CHI   R15,L'MGRCON        Too long?                       @TTA 16808418
         JH    READSKIP            Yes, skip it                    @TTA 16808518
         AHI   R15,-1              Subtract one for execute        @TTA 16808618
         EX    R15,MOVECNNM        Move console name               @TTA 16808718
MDBLGDAT LOCTR                                                     @TTA 16808818
MOVECNNM MVC   MGRCON(0),0(R4)     Move console name               @TTA 16808918
MDBLGCOD LOCTR                                                     @TTA 16809018
*-----------------------------------------------------------------@TTA* 16809118
*        LOOK FOR 'J' as the last parameter                       @TTA* 16809218
*-----------------------------------------------------------------@TTA* 16809318
CHECKJ   MVI   MGRFLAG1,0          Clear flag byte                 @TTA 16809418
         CLI   0(R1),C')'          Is it a right parenthesis?      @TTA 16809518
         JE    RPRNMGR             Yes, go handle                  @TTA 16809618
         CLI   1(R1),C'J'          Is it 'J' ?                     @TTA 16809718
         JNE   READSKIP            No, skip this statement         @TTA 16809818
         OI    MGRFLAG1,MGRREPLC   Set corresponding flag          @TTA 16809900
         CLI   2(R1),C')'          Closing parenthesis?            @TTA 16810010
         JNE   READSKIP            No, skip to the end             @TTA 16810118
         AHI   R1,2                Point at the paremthesis        @TTA 16810218
*-----------------------------------------------------------------@TTA* 16810318
*        Right parenthesis detected                               @TTA* 16810418
*-----------------------------------------------------------------@TTA* 16810518
RPRNMGR  CLI   1(R1),C' '          End of statement?               @TTA 16810618
         JE    READSTMT            Yes, go read the next one       @TTA 16810718
         CLI   1(R1),C','          More keywords?                  @TTA 16810818
         JNE   READSKIP            No, skip the rest               @TTA 16810900
         CLI   2(R1),C' '          End of record?                  @TTA 16811010
         JE    CONTMSGR            Yes                             @TTA 16811118
         AHI   R1,2                Skip past '),'                  @TTA 16811218
         J     INITRTC             Go scan next routcode           @TTA 16811318
CONTMSGR JAS   R14,READREC         Yes, read the next record       @TTA 16811418
         LTR   R15,R15             Good return?                    @TTA 16811518
         JNZ   PARSEXIT            No, exit                        @TTA 16811618
         LM    R1,R3,INPOINT       Get scan registers              @TTA 16811718
         J     INITRTC             Go scan next routcode           @TTA 16811818
*-----------------------------------------------------------------@TTA* 16811900
*        Set a skip flag and read another record                  @TTA* 16812010
*-----------------------------------------------------------------@TTA* 16812118
READSKIP MVI   SCANFLAG,SCANSKIP   Set the skip flag               @TTA 16812218
         J     READIN              And go read the next record     @TTA 16812318
*-----------------------------------------------------------------@TTA* 16812418
*        Exit to the caller                                       @TTA* 16812518
*-----------------------------------------------------------------@TTA* 16812618
PARSEXIT PR    ,                                                   @TTA 16812718
         DROP  R5                  SDTENTRY                        @TTA 16812818
******************************************************************@TTA* 16812900
*                                                                 @TTA* 16813010
*        Subroutine to read one JES3IN record                     @TTA* 16813118
*                                                                 @TTA* 16813218
* The subroutine reads one record and does some basic parsing:    @TTA* 16813318
*                                                                 @TTA* 16813418
* - it skips comment statements                                   @TTA* 16813518
* - it skips leading blanks, then sets a starting position        @TTA* 16813618
*   pointer                                                       @TTA* 16813718
******************************************************************@TTA* 16813818
READREC  BAKR  R14,0               Save registers on the stack     @TTA 16813918
READNEXT L     R2,IDCBADDR         Address of input DCB            @TTA 16814018
         GET   (R2),INAREA         Get one input record            @TTA 16814118
*-------------------------------------------------------------*    @TTA 16814218
*                                                             *    @TTA 16814318
*        If this is a comment statement, read the next        *    @TTA 16814400
*        statement.  Otherwise, scan the statement to find    *    @TTA 16814510
*        the first non-blank character and store its location *    @TTA 16814618
*        in the field INPOINT.                                *    @TTA 16814718
*                                                             *    @TTA 16814818
*-------------------------------------------------------------*    @TTA 16814918
         CLI   INAREA,C'*'         Is this a comment ?             @TTA 16815018
         JE    READNEXT            Yes, read the next record       @TTA 16815118
         LA    R1,INAREA           Point to the beginning of       @TTA+16815218
                                     the record                    @TTA 16815318
         LA    R3,INAREA+70        Ending column                   @TTA 16815400
         LHI   R2,1                Increment                       @TTA 16815510
FINDCHAR CLI   0(R1),C' '          Is it blank?                    @TTA 16815618
         JNE   S029END             No, check further               @TTA 16815718
         JXLE  R1,R2,FINDCHAR      Check the next character        @TTA 16815818
S029END  ST    R1,INPOINT          Set the card image pointer      @TTA 16815918
*-------------------------------------------------------------*    @TTA 16816018
*                                                             *    @TTA 16816118
*        Check if the statement is continued.                 *    @TTA 16816218
*                                                             *    @TTA 16816318
*-------------------------------------------------------------*    @TTA 16816400
S029SCNB CLI   1(R1),C' '          Next character blank?           @TTA 16816510
         JE    S029CONT            Yes, check for ending comma     @TTA 16816618
         LA    R1,1(,R1)           Point to next character         @TTA 16816718
         JXLE  R1,R2,S029SCNB      Try again...                    @TTA 16816818
         SPACE 1                                                   @TTA 16816918
S029CONT NI    SCANFLAG,X'FF'-SCANCONT-SCANSKIP Reset continued    @TTA+16817018
                                     and 'skip to the end'         @TTA 16817118
         CLI   0(R1),C','          Record ends with a comma?       @TTA 16817218
         JE    S029SET             Yes, set continuation flag      @TTA 16817318
         CLI   INAREA72-1,C','     Comma in column 72?             @TTA 16817400
         JNE   S029CH72            No, but check column 72 for     @TTA+16817510
                                     blank                         @TTA 16817618
         SPACE 1                                                   @TTA 16817718
S029SET  OI    SCANFLAG,SCANCONT   Set continuation flag           @TTA 16817818
         J     READRETN            Return                          @TTA 16817918
         SPACE 1                                                   @TTA 16818018
S029CH72 CLI   INAREA72,C' '       Continuation column blank?      @TTA 16818118
         JE    READRETN            Yes, OK to return               @TTA 16818218
         OI    SCANFLAG,SCANSKIP   Set to skip till the end        @TTA 16818318
         J     READNEXT            And read the next record        @TTA 16818400
         SPACE 1                                                   @TTA 16818510
*-------------------------------------------------------------*    @TTA 16818618
*                                                             *    @TTA 16818718
*        Return to the caller unless we are skipping a bad    *    @TTA 16818818
*        statement.                                           *    @TTA 16818918
*                                                             *    @TTA 16819018
*-------------------------------------------------------------*    @TTA 16819118
READRETN TM    SCANFLAG,SCANSKIP   Skipping to the end of stmt?    @TTA 16819218
         JO    READNEXT            Yes, read until end found       @TTA 16819318
         XR    R15,R15             Indicate success                @TTA 16819400
         PR                        Return                          @TTA 16819510
******************************************************************@TTA* 16819618
*        CLOSE the JES3IN file                                    @TTA* 16819718
******************************************************************@TTA* 16819818
J3INCLS  L     R2,IDCBADDR         Address of input DCB            @TTA 16819918
         CLOSE ((R2)),             Close the input file            @TTA+16820018
               MODE=31,                                            @TTA+16820118
               MF=(E,CLOSLIST)                                     @TTA 16820218
         LA    R15,4               Indicate CLOSE was done         @TTA 16820318
         PR                        Return to the GET caller        @TTA 16820400
*                                                                       16820500
*********************************************************************** 16820600
* PUTREC -- PUT a record to the output file and set up for next       * 16820700
*                                                                     * 16820800
*   Input:                                                            * 16820900
*     r3 -> input text                                            @TTC* 16821000
*     r4  = input text length                                     @TTC* 16830000
*     R14 = return address                                            * 16840000
*********************************************************************** 16850000
PUTREC   DS    0H                                                       16860000
         BAKR  R14,0               save caller's environment            16870000
         LR    R1,R4               length of text                       16880000
         AHI   R1,-1               subtract 1 for mvc              @TTC 16890000
         JM    PUTRECX             return if negative (length < 1)      16900000
         L     R9,LOGCURTX         DLOG record                     @TTC 16910000
*                                                               19#@TTD 16920000
         EX    R1,PUTMV            move in the text                     17100000
         EX    R1,TRANTEXT         Fold out unreadable characters  @PDA 17101000
         AHI   R1,5                Add 1 back + RDW length         @TTC 17110000
         A     R1,LOGCURLN         Add preamble length             @TTC 17120000
*                                                                2#@TTD 17130000
         STH   R1,LOGBUFL          move it into prefix                  17150000
*                                                                 3@P8D 17160000
         L     R2,ODCBADDR         Get the DCB address             @TTC 17170000
         PUT   (R2),LOGBUFP        PUT the DLOG record             @TTC 17180000
*                                                               23#@TTD 17190000
         MVI   FIRSTLNE,C'N'       show this is no longer first line    17410000
PUTRECX  PR    ,                  return                                17430000
MDBLGDAT LOCTR                     Resume data segment             @TTA 17435000
PUTMV    MVC   0(*-*,R9),0(R3)    executed instruction             @TTC 17440000
TRANTEXT TR    0(*-*,R9),TRCONTRL Convert non-readable characters  @TTC 17441001
MDBLGCOD LOCTR                     Resume code segment             @TTA 17445000
*                                                                       17450000
*********************************************************************** 17460000
* GAPMSG -- PUT special record to the output file indicating       @01A 17470000
*           data missing (due to deleted record, gap, etc.)        @01A 17480000
*           and set up for the next                                @01A 17490000
*                                                                  @01A 17500000
*   Input:                                                         @01A 17510000
*     RETCODE = service routine return code                        @01A 17520000
*     RSNCODE = service routine reason code                        @01A 17530000
*     R14 = return address                                         @01A 17540000
*     Logger service routine already initialized from LOGRMSGT     @01A 17550000
*                                                                  @01A 17560000
*********************************************************************** 17570000
GAPMSG   DS    0H                                                  @01A 17580000
         BAKR  R14,0               save caller's environment       @01A 17590000
         TM    MFLAGS,OPEN         is there an output dataset?     @02A 17600000
         JNO   PUTGOK              No, skip writing message        @02A 17610000
         MVC   NOMSGRTN,LOGRMSGT   put name of logger service routine   17620000
*                                  where gap found in message      @01A 17630000
         LR    R6,R14              save R14 across putrec call     @01A 17640000
*                                  (restored by PR anyway)         @01A 17650000
         UNPK  NOMSGRC(4),RETCODE+2(3)  get return code            @01A 17660000
         TR    NOMSGRC,HEXTAB      make it printable               @01A 17670000
         MVI   NOMSGRC+3,C','      replace lost character          @01A 17680000
         UNPK  NOMSGRS(5),RSNCODE+2(3) get reason code             @01A 17690000
         TR    NOMSGRS,HEXTAB      make it printable               @01A 17700000
         MVI   NOMSGRS+4,C' '      replace lost character          @01A 17710000
         MVC   LOGBUF,BLANKS       Clear out log buffer            @TTC 17720000
         MVC   LOGBUF(NOMSGLEN),NOMSGMSG  move text into DLOG      @TTC+17730000
                                     buffer                        @TTA 17735000
         LH    R3,NOMSGAL2         length of message               @01A 17740000
         LA    R3,4(,R3)           Add for RDW                     @01A 17750000
         STH   R3,LOGBUFL          set record length               @01A 17760000
*                                                                 3@P8D 17770000
         L     R2,ODCBADDR         Get the DCB address             @TTA 17775000
         PUT   (R2),LOGBUFP        PUT the record                  @TTC 17780000
*                                                                 3@P8D 17790000
PUTGOK   EQU   *                                                   @01A 17800000
         PR    ,                   return                          @01A 17810000
*                                                                       17820000
*********************************************************************** 17830000
* GENINFO -- Get information from the MDB general object and          * 17840000
*            fill in the appropriate log record fields.               * 17850000
*                                                                3#@TTD 17860000
*                                                                     * 17890000
*   Input:                                                        @04A* 17900000
*     r7 -> MDBG                                                  @04A* 17910000
*     R14 = return address                                        @04A* 17920000
*                                                                 @TTA* 17921000
*   Output:                                                       @TTA* 17922000
*     The LOGBUF is initialized with the time and date. The       @TTA* 17923000
*     next text position is saved in LOGCURTX and the used        @TTA* 17924000
*     length in LOGCURLN.                                         @TTA* 17925000
*********************************************************************** 17930000
GENINFO  DS    0H                                                  @04A 17940000
         BAKR  R14,0               save caller's environment       @04A 17950000
         USING MDBG,R7             addressability to general object    X17960000
                                                                   @04A 17970000
         LA    R9,LOGBUF           Set up DLOG record base         @TTA 17971000
         USING DLOGLINE,R9         Assembler addressability        @TTA 17972000
         MVC   DLOGTMHH,MDBGTIMH   Copy hours                      @TTA 17973000
         MVC   DLOGTMMM,MDBGTIMH+3 Copy minutes                    @TTA 17974000
         MVC   DLOGTMSS,MDBGTIMH+6 Copy seconds                    @TTA 17975000
         MVC   DLOGTMFS,MDBGTIMT+1 Copy fraction of a second       @TTA 17976000
         TM    PFLAGS,CENTURY      Does customer want a 4-digit year   X17980000
                                   in output records               @04A 17990000
         JNO   TWODGYR1            No, customer wants a 2-digit year   X18000000
                                   in the output records           @04A 18010000
         MVC   DLOG4YDT,MDBGDSTP   date with 4-digit year (yyyyddd)@TTC 18020000
         J     GENINFOX            Continue to exit                @TTC 18030000
TWODGYR1 DS    0H                  Process 2-digit year output recs@TTC 18040000
         MVC   DLOGDATE,MDBGDSTP+2 date (note that MDB form is     @TTC+18050000
                                                          yyyyddd) @TTC 18060000
GENINFOX LHI   R0,DLOGTEXT-DLOGLINE  Text length                   @TTC 18070000
         LA    R1,DLOGTEXT         Text pointer                    @TTC 18080000
         STM   R0,R1,LOGCURLN      Save for later                  @TTC 18090000
*                                                               19#@TTD 18100000
         DROP  R7                  Drop addressability to MDB general  X18280000
                                   object                          @04A 18290000
         DROP  R9                  DLOGLINE                        @TTA 18295000
         PR                        return to caller                @04A 18300000
*                                                                       18310000
*********************************************************************** 18320000
* CPINFO --  Get information from the MDB CP object and               * 18330000
*            fill in the appropriate log record fields.               * 18340000
*                                                                     * 18380000
*   Input:                                                        @04A* 18390000
*     R7 -> MDBSCP                                                @04A* 18400000
*     R14 = return address                                        @04A* 18410000
*                                                                 @TTA* 18411000
*   Output:                                                       @TTA* 18412000
*     The following DLOG fields are filled in:                    @TTA* 18413000
*     - DLOG4YCN (or DLOGCONS)                                    @TTA* 18414000
*     - DLOGSYS                                                   @TTA* 18415000
*     - JOBNAME                                                   @TTA* 18416000
*     - DLOGCLAS                                                  @TTA* 18417000
*     - DLOGSPEC                                                  @TTA* 18418000
*                                                                 @TTA* 18419000
*********************************************************************** 18420000
CPINFO   DS    0H                                                  @04A 18430000
         BAKR  R14,0               save caller's environment       @04A 18440000
         USING MDBSCP,R7           addressability to cp object     @04A 18450000
*                                                               10#@TTD 18460000
         MVI   SnglLnMg,C'N'       Set single line message to N    @05A 18550101
         MVI   PrevRecT,HCRMLWTO   Set PrevRecT to the type of msg @05A 18551001
         CLC   MDBCLCNT,=F'1'      see if more than one line       @04A 18560000
         JH    CPROK               ok if so                        @04A 18570000
*                                                                  @TTD 18580000
         MVI   SnglLnMg,C'Y'       This was a single line message, so  X18581001
                                   save that it is a single line   @05A 18582001
*                                                              121#@TTD 18590000
* set up log record base                                                19450000
*                                                                  @04M 19460000
CPROK    LA    R9,LOGBUF           DLOG record                     @TTC 19470000
         USING DLOGLINE,R9         addressability                  @TTC 19480000
*-----------------------------------------------------------------@TTA* 19485000
* Check if the system is in the system definition table and skip  @TTC* 19490000
* putting out the record if not.                                  @TTA* 19495000
*-----------------------------------------------------------------@TTC* 19500000
         LT    R5,SDTTABLE         Address of the table            @TTC 19505000
         JZ    CPCKCMD             None, continue                  @TTC 19510000
         USING SDTENTRY,R5         Table addressability            @TTA 19515000
         LM    R0,R1,SDTINCR       Set up for JXLE                 @TTC 19520000
RIDSRCH  CLC   SYSNAME,SDTSYSNM    Is this the name?               @TTA 19525000
         JE    CPCKCMD             Yes, set the length             @TTA 19530000
         JXLE  R5,R0,RIDSRCH       Step up to the next entry       @TTC 19540000
         J     CPRETNX             Not found - skip the MDB        @TTC 19550000
*********************************************************************** 19560000
* SET UP MESSAGE PREAMBLE                                          @TTC 19570000
*********************************************************************** 19580000
CPCKCMD  TM    MDBCMSC2,MDBCOCMD   is it an operator cmd echo?     @04A 19590000
         JNO   CPNOP               no, check for response          @L1C 19600000
*********************************************************************** 19620000
* IF command issued internally (console id=0) THEN                 @L1A 19630000
*   IF console id is blank, then put INTERNAL in console id field  @TTC 19640000
*                                                                  @TTD 19650000
*********************************************************************** 19660000
         CLC   MDBCCNID,k_CnId_4B_Internal is it an internal cmd       X19670000
                                   (consid = 0)?                   @L1C 19680000
         JNE   CPCUN               no, check for unknown consid    @L1C 19690000
         TM    PFLAGS,CENTURY      Does customer want a 4-digit    @TTC+19700000
                                     year in output records?       @TTC 19710000
         JZ    CPINTC4Y            No, use different name          @TTC 19720000
         MVC   DLOG4YCN,k_ConsName_Internal  move in "INTERNAL"    @TTC 19730000
         J     CPRC                done with console id            @TTC 19740000
CPINTC4Y MVC   DLOGCONS,k_ConsName_Internal     move in "INTERNAL" @TTC 19750000
         J     CPRC                done with console id            @L1A 19760000
*********************************************************************** 19770000
* IF command issued from the unknown console id (00FFFFFF) THEN    @L1A 19780000
*   IF console id is blank, then put UNKNOWN in console id field   @TTC 19790000
*   ELSE console id exists, insert console id.                     @TTC 19800000
*********************************************************************** 19810000
CPCUN    CLC   MDBCCNID,k_UnkId    is command from unknown console     X19820000
                                   id (00FFFFFF)?                  @L1A 19830000
         JNE   CPCINST             no, check for instream cnid     @L1C 19840000
         TM    PFLAGS,CENTURY      Does customer want a 4-digit    @TTC+19850000
                                     year in output records?       @TTC 19860000
         JZ    CPUNKC4Y            No, use different name          @TTC 19870000
         MVC   DLOG4YCN,k_Unknown  Move in "UNKNOWN"               @TTC 19880000
         J     CPRC                done with console id            @L1C 19890000
CPUNKC4Y MVC   DLOGCONS,k_Unknown  Move in "UNKNOWN"               @TTC 19900000
         J     CPRC                done with console id            @L1C 19910000
*********************************************************************** 19920000
* IF command is from JCL stream (consid=128) use INSTREAM          @L1A 19930000
*********************************************************************** 19940000
CPCINST  CLC   MDBCCNID,k_CnId_4B_Instream_128  is command from        X19950000
                                   instream id (128)?              @L1A 19960000
         JNE   CPCOTH              no, use console id              @L1A 19970000
         TM    PFLAGS,CENTURY      Does customer want a 4-digit    @TTA+19971000
                                     year in output records?       @TTA 19972000
         JZ    CPINSC4Y            No, use different name          @TTA 19973000
         MVC   DLOG4YCN,k_ConsName_Instream  move in "INSTREAM"    @TTA 19974000
         J     CPRC                Done with console id            @TTA 19975000
CPINSC4Y MVC   DLOGCONS,k_ConsName_Instream     move in "INSTREAM" @TTC 19980000
         J     CPRC                Done with console id            @TTC 19990000
*********************************************************************** 20000000
* Must not be a special console id.                                @L1A 20010000
*******************************************************************@TTA 20012000
CPCOTH   CLC   CONSNAME,EIGHTZRO   Any name?                       @TTA 20013000
         JE    CPRC                No, skip moving one in          @TTA 20014000
         TM    PFLAGS,CENTURY      Does customer want a 4-digit    @TTA+20015000
                                     year in output records?       @TTA 20016000
         JZ    CPCONC4Y            No, use different name          @TTA 20017000
         MVC   DLOG4YCN,CONSNAME   move in console name from MDB   @TTA 20018000
         J     CPRC                                                @TTA 20019000
CPCONC4Y MVC   DLOGCONS,CONSNAME   move in console name from MDB   @TTC 20020000
         J     CPRC                Continue                        @TTA 20021000
*******************************************************************@TTA 20022000
* Not an operator command.                                         @TTA 20023000
*********************************************************************** 20024000
*-----------------------------------------------------------------@TTA* 20024500
* R5 is set up to the System Definition Table entry or zero.      @TTA* 20025000
* The entry defines what should be used as system name in the     @TTA* 20025500
* output line.  If no table entry exists, we will use the system  @TTA* 20026000
* name from the MDB (MDBGOSNM) which was copied to SYSNAME.       @TTA* 20026500
*-----------------------------------------------------------------@TTA* 20027000
CPNOP    LTR   R5,R5               Do we have an entry address?    @TTC 20030000
         JZ    SYSNMSCN            None, use the full name         @TTA 20032000
         MVC   DLOGSYS,SDTRCHAR    Set receive ID in DLOG          @TTA 20034000
         XR    R0,R0               Clear for insert                @TTA 20036000
         IC    R0,SDTIDLEN         Receive ID length               @TTA 20038000
         LTR   R0,R0               Any ID?                         @TTC 20040000
         JZ    SYSNMSCN            No, don't even try              @TTA 20041000
         LA    R1,DLOGSYS          Point at RID position           @TTA 20042000
         AR    R1,R0               Add to the output length        @TTA 20043000
         TM    SDTEFLAG,SDTNOR     No R= to be used?               @TTA 20044000
         JO    SETNOR              Yes, just use equal sign        @TTA 20045000
         MVC   0(4,R1),=C' R= '    Move in R=                      @TTA 20046000
         AHI   R1,4                Account for the length          @TTA 20047000
         J     SETPTR              Save the pointer and length     @TTA 20048000
SETNOR   MVC   0(2,R1),=C'= '      Add equal sign                  @TTA 20049000
         AHI   R1,2                Account for the sign            @TTC 20050000
         J     SETPTR              Save the pointer and length     @TTA 20051000
*-----------------------------------------------------------------@TTA* 20052000
* For the system name we only use as many positions in the        @TTA* 20053000
* log buffer as the system name is long.  Scan the name from      @TTA* 20054000
* the end and stop on the first non-blank character.  Then        @TTA* 20055000
* add R= to the log buffer and save the pointer and the length    @TTA* 20056000
* used so far.                                                    @TTA* 20057000
*-----------------------------------------------------------------@TTA* 20058000
SYSNMSCN MVC   DLOGSYS,SYSNAME     System name                     @TTA 20059000
         LA    R1,DLOGSYS+L'DLOGSYS-1  Point at last byte of       @TTC+20060000
                                     system name                   @TTA 20061000
         LA    R0,L'MDBGOSNM-1     Maximum search length           @TTA 20062000
SYSNMCHK CLI   0(R1),C' '          Is it blank?                    @TTA 20063000
         JNE   SETNAMLN            No, set name length             @TTA 20064000
         AHI   R1,-1               Back up to previous charact.    @TTA 20065000
         JCT   R0,SYSNMCHK         Continue                        @TTA 20066000
SETNAMLN MVC   2(2,R1),=C'R='      Move in R=                      @TTA 20067000
         AHI   R1,5                Account for blank before &      @TTA+20068000
                                     after and step past last      @TTA+20069000
                                     character of system name      @TTC 20070000
SETPTR   ST    R1,LOGCURTX         Save current pointer            @TTA 20071000
         SR    R1,R9               Get current length              @TTA 20072000
         ST    R1,LOGCURLN         Save as current length          @TTA 20073000
*-----------------------------------------------------------------@TTA* 20074000
* Put the job name in the DLOG record                             @TTA* 20075000
*-----------------------------------------------------------------@TTA* 20076000
         LM    R0,R1,LOGCURLN      Pick up LOGCURLN & LOGCURTX     @TTA 20077000
         MVC   0(L'JOBNAME,R1),JOBNAME    Save job name            @TTA 20078000
         AHI   R1,L'JOBNAME+1      Add jobname length + blank      @TTA 20079000
         AHI   R0,L'JOBNAME+1      Add jobname length + blank      @TTC 20080000
         STM   R0,R1,LOGCURLN      Save LOGCURLN & LOGCURTX        @TTA 20081000
*-----------------------------------------------------------------@TTA* 20082000
* Check for command response (desc=5 or mcsflag=resp)             @TTA* 20083000
*-----------------------------------------------------------------@TTA* 20084000
         TM    MDBCATT1,MDBCMCSC   Is it a command response?       @TTA 20085000
         JO    CPRSP               Yes, mark it so                 @TTA 20086000
         TM    MDBDESC1,MDBDESCE   is it desc=5 (also cmd resp)    @TTA 20087000
         JNO   CPRC                Not cmd response                @TTA 20088000
*-----------------------------------------------------------------@TTA* 20088200
* Check for INTERNAL, UNKNOWN or INSTREAM console                 @TTA* 20088400
*-----------------------------------------------------------------@TTA* 20088600
CPRSP    CLC   CONSID,k_CnId_4B_Internal is consid internal? (0)   @TTA 20089000
         JNE   CPRUNK              if not internal, check unknown  @TTC 20090000
         MVC   DLOGCONS,k_ConsName_Internal     move in "INTERNAL" @TTA 20091000
         J     CPRC                Done with console id            @TTA 20092000
CPRUNK   CLC   CONSID,k_UnkId      Is consid unknown? (00FFFFFF)   @TTA 20093000
         JNE   CPRINST             If not unknown, check instream  @TTA 20094000
         MVC   DLOGCONS,k_Unknown  move in "UNKNOWN"               @TTA 20095000
         J     CPRC                Done with console id            @TTA 20096000
CPRINST  CLC   CONSID,k_CnId_4B_Instream_128   is it "instream"?   @TTA 20097000
         JNE   CPRNOTS             no, not special console id      @TTA 20098000
         MVC   DLOGCONS,k_ConsName_Instream  move in "INSTREAM"    @TTA 20099000
         J     CPRC                done with job/console field     @TTC 20100000
*-----------------------------------------------------------------@TTA* 20100200
* Initialize console name if one was specified                    @TTA* 20100400
*-----------------------------------------------------------------@TTA* 20100600
CPRNOTS  TM    MCSFLAG1,MDBMCSB    Was it sent by console id?      @TTA 20101000
         JNO   CPRC                No console id                   @TTA 20102000
         MVC   DLOGCONS,CONSNAME   Move in console name            @TTA 20103000
******************************************************************@TTA* 20104000
* convert the routing code to DEST class                          @TTA* 20105000
******************************************************************@TTA* 20106000
CPRC     JAS   R14,RCM2DEST        Convert routing code to         @TTA+20107000
                                     JES3 DEST                     @TTA 20108000
         LTR   R1,R1               Any DEST code set?              @TTA 20109000
         JZ    SETSPEC             No, leave destination blank     @TTC 20110000
         XR    R15,R15             No MGR table yet                @TTA 20111000
         CHI   R1,128              Is it higher than 128?          @TTA 20112000
         JH    CPRCDEST            Yes, skip MSGROUTE process      @TTA 20113000
*-----------------------------------------------------------------@TTA* 20114000
* Process MSGROUTE information using the selected route           @TTA* 20115000
* code to index into the MSGROUTE table which was built at        @TTA* 20116000
* initialization based on the MSGROUTE statement. With            @TTA* 20117000
* the exception of route code 11, the table entry for the         @TTA* 20118000
* route code is used to determine the route code and console      @TTA* 20119000
* (if any) that would have been used to route the message.        @TTC* 20120000
*                                                                 @TTA* 20121000
* Depending on the "J" option specification for the route         @TTA* 20122000
* code, the routing information determined earlier will           @TTA* 20123000
* replace the message's routing information, or it will be        @TTA* 20124000
* ignored if the selected routine code was 'higher' (i.e.         @TTA* 20125000
* lower if within the first 16, or higher if between 17-128).     @TTA* 20126000
*                                                                 @TTA* 20127000
* If the "J" option is specified on the MSGROUTE statement        @TTA* 20128000
* without a destination class, the destination class "MLG"        @TTA* 20129000
* will be assigned to the message.                                @TTC* 20130000
*                                                                 @TTA* 20131000
* In the case of route code 11, only the "J" option is            @TTA* 20132000
* significant.  If "J" was specified, the message will be         @TTA* 20133000
* marked for hardcopy only (i.e. MLG dest class).  If "J"         @TTA* 20134000
* was not specified, then the message routing will not be         @TTA* 20135000
* changed.                                                        @TTA* 20136000
*                                                                 @TTA* 20137000
*-----------------------------------------------------------------@TTA* 20138000
         LTR   R5,R5               Do we have an SDT entry?        @TTA 20138300
         JZ    CPRCDEST            No, set destination class       @TTA 20138600
         LT    R14,SDTMSGRT        Do we have a MSGROUTE table?    @TTA 20139000
         JZ    CPRCDEST            No, set destination class       @TTC 20140000
         LR    R15,R1              Copy route code value           @TTA 20141000
         AHI   R15,-1              Adjust for zero origin          @TTA 20142000
         MHI   R15,MGRESIZE        Multiply by entry size          @TTA 20143000
         AR    R15,R14             Add starting point              @TTA 20144000
         USING MGRENTRY,R15        MSGROUTE table entry            @TTA 20145000
         CHI   R1,11               Route code 11?                  @TTA 20146000
         JNE   CPRCKREP            No, continue                    @TTA 20147000
         TM    MGRFLAG1,MGRREPLC   Route code to be replaced?      @TTA 20148000
         JZ    CPRCDEST            No, leave routing alone         @TTA 20149000
         MVC   DLOGCLAS,=C'MLG'    Else replace by MLG             @TTC 20150000
         J     CPRCKCON            Continue                        @TTA 20151000
CPRCKREP TM    MGRFLAG1,MGRREPLC   Route code to be replaced?      @TTA 20152000
         JO    CPRREPLC            Yes, go do it                   @TTA 20153000
         CLC   MGRROUT,HALFZERO    Any route code specified?       @TTA 20154000
         JE    CPRCDEST            No, use the one we have got     @TTA 20155000
         CHI   R1,16               Route code less or equal to     @TTA+20156000
                                     16?                           @TTA 20157000
         JH    CPRHIRT             No, handle higher values        @TTA 20158000
         CH    R1,MGRROUT          Is selected lower?              @TTA 20159000
         JL    CPRCDEST            Yes, keep it                    @TTC 20160000
         LH    R1,MGRROUT          No, replace it                  @TTA 20161000
         J     CPRCDEST            Continue                        @TTA 20162000
CPRHIRT  CH    R1,MGRROUT          Is selected higher?             @TTA 20163000
         JH    CPRCDEST            Yes, keep it                    @TTA 20164000
CPRREPLC LH    R1,MGRROUT          No, replace it                  @TTA 20165000
*-----------------------------------------------------------------@TTA* 20166000
* Convert the route code to the JES3 destination class            @TTA* 20167000
*-----------------------------------------------------------------@TTA* 20168000
CPRCDEST LR    R2,R1               Multiply ...                    @TTA 20169000
         ALR   R2,R2               .. the value ...                @TTC 20170000
         ALR   R2,R1               .... by three                   @TTA 20171000
         LA    R1,RTCODTBL-RTCODTB1(R2)   Adjust for 1 origin      @TTA 20172000
         MVC   DLOGCLAS,0(R1)      move into record                @04M 20173000
*-----------------------------------------------------------------@TTA* 20174000
* Process the console information from the MSGROUTE entry         @TTA* 20175000
*-----------------------------------------------------------------@TTA* 20176000
CPRCKCON LTR   R15,R15             Do we have a MSGROUTE?          @TTA 20177000
         JZ    SETSPEC             No, continue                    @TTA 20178000
         TM    MGRCON,X'FF'-C' '   Console name specified?         @TTA 20179000
         JZ    SETSPEC             No, leave output as is          @TTC 20180000
         CLC   CONSNAME,BLANKS     Any console in the MDB?         @TTA 20181000
         JE    CPSETCON            No, set in the output           @TTA 20182000
         TM    MGRFLAG1,MGRREPLC   Console name to be replaced?    @TTA 20183000
         JZ    SETSPEC             No, leave routing alone         @TTA 20184000
CPSETCON MVC   CONSNAME,MGRCON     Copy console id                 @TTA 20185000
         TM    PFLAGS,CENTURY      Does customer want a 4-digit    @TTA+20186000
                                     year in output records?       @TTA 20187000
         JZ    MVMGRCN4            Yes, use diferent offset        @TTA 20188000
         MVC   DLOG4YCN,MGRCON     Else replace the console        @TTA 20189000
         J     SETSPEC             Continue                        @TTC 20190000
MVMGRCN4 MVC   DLOGCONS,MGRCON     Replace the console name        @TTA 20191000
         DROP  R15                 MGRENTRY                        @TTA 20192000
*-----------------------------------------------------------------@TTA* 20193000
* Handle special characters and set them in DLOGSPEC:             @TTA* 20194000
*                                                                 @TTA* 20195000
* (-)=MVS command echo                                            @TTA* 20196000
* (*)=action as indicated by these flags:                         @TTA* 20197000
*     - MDBMLR   WTOR                                             @TTA* 20198000
*     - MDBDESCA System Failure                                   @TTA* 20199000
*     - MDBDESCB Immediate Action Required                        @TTC* 20200000
*     - MDBDESCC Eventual Action Required                         @TTA* 20201000
*     - MDBDESCK Critical Eventual Action                         @TTA* 20202000
* (b)=blank                                                       @TTA* 20203000
*                                                                 @TTA* 20204000
* Add suppression character if specified for this message.        @TTA* 20205000
* The character will occupy the first text character position.    @TTA* 20206000
* Suppression is indicated by one of  these flags:                @TTA* 20207000
*     - MDBCSSSI Suppressed by a subsystem                        @TTA* 20208000
*     - MDBCSWTO Suppressed by a WTO user exit routine            @TTA* 20209000
*     - MDBCSMPF Suppressed by MPF or Message                     @TTC* 20210000
*                                                                 @TTA* 20211000
* Note that the suppression character will be displayed           @TTA* 20212000
* AFTER the action character.                                     @TTA* 20213000
*-----------------------------------------------------------------@TTA* 20214000
SETSPEC  TM    MDBCMSC2,MDBCOCMD   Operator command echo?          @TTA 20215000
         JZ    CHKACTN             No, continue                    @TTA 20216000
         MVI   DLOGSPEC,C'-'       Set the corresponding flag      @TTA 20217000
         J     CHKSUPP             All done here                   @TTA 20218000
CHKACTN  TM    MDBMLVL1,MDBMLR     Is it a WTOR?                   @TTA 20219000
         JO    SETASTRK            Yes, Set asterisk               @TTC 20220000
         TM    MDBDESC1,MDBDESCA+MDBDESCB+MDBDESCC  Is it syst.    @TTA+20221000
                                     failure, immediate or         @TTA+20222000
                                     eventual action?              @TTA 20223000
         JNZ   SETASTRK            Yes, set  asterisk              @TTA 20224000
         TM    MDBDESC2,MDBDESCK   Critical eventual action?       @TTA 20225000
         JZ    CHKSUPP             No, continue                    @TTA 20226000
SETASTRK MVI   DLOGSPEC,C'*'       Set action message indicator    @TTA 20227000
CHKSUPP  MVI   SUPPCHAR,C' '       Clear suppression character     @TTA 20228000
         TM    MDBCSUPB,MDBCSSSI+MDBCSSSI+MDBCSMPF  Any            @TTA+20229000
                                     suppression flag set?         @TTC 20230000
         JZ    CPRETN              No, continue                    @TTA 20231000
*-----------------------------------------------------------------@TTA* 20232000
* Move Sysname one position to the right to make room for         @TTA* 20233000
* the suppression character.                                      @TTA* 20234000
*-----------------------------------------------------------------@TTA* 20235000
         MVC   SYSNSAVE,DLOGSYS    Copy system name followed       @TTA+20236000
                                     by 'R='                       @TTA 20237000
         MVC   DLOGSYS+1(L'SYSNSAVE),SYSNSAVE  Copy it back        @TTA 20238000
         L     R1,LOGCURTX         Get current text pointer        @TTC 20240000
         AHI   R1,1                Adjust current text pointer     @TTC 20250000
         L     R3,FLCCVT           Get CVT address                 @TTC 20260000
         USING CVTMAP,R3           CVT addressability              @TTC 20270000
         L     R3,CVTCUCB          UCM header                      @TTC 20280000
         USING UCM,R3              UCM addressability              @TTC 20290000
         MVC   DLOGSYS(1),UCMBMPFS  MPF suppression character      @TTC 20300000
         MVC   SUPPCHAR,UCMBMPFS   Save suppression character      @TTC 20310000
         DROP  R3                  UCM                             @TTC 20320000
         LR    R0,R1               Copy text pointer               @TTC 20330000
         SR    R0,R9               Get current length              @TTC 20340000
         STM   R0,R1,LOGCURLN      Save length and text address    @TTC 20350000
*********************************************************************** 20360000
* remember this is the first line in the message                   @04M 20370000
CPRETN   MVI   FIRSTLNE,C'Y'       set first-line indicator        @TTC 20380001
         NI    MFLAGS,X'FF'-SKIPSYS  Indicate system is valid      @TTA 20381000
         PR                        Return to the caller            @TTA 20382000
*-----------------------------------------------------------------@TTA* 20383000
* The system name wasn't found in the system definition table.    @TTA* 20384000
* Return with a nonzero return code.                              @TTA* 20385000
*-----------------------------------------------------------------@TTA* 20386000
CPRETNX  OI    MFLAGS,SKIPSYS      Indicate system not found       @TTA 20387000
         DROP  R9                  DLOGLINE                        @TTC 20390000
         DROP  R7                  Drop addressability to MDB CP       X20400000
                                                                   @04A 20410000
         DROP  R5                  SDTENTRY                        @TTA 20410100
         PR                        return to caller                @04A 20410200
******************************************************************@TTA* 20410300
* RCM2DEST-  Subroutine to convert a set of routing codes to      @TTA* 20410400
*            a single JES3 class.                                 @TTA* 20410500
*                                                                 @TTA* 20410600
* Processing (paraphrased from module IATCS12):                   @TTA* 20410700
*                                                                 @TTA* 20410800
* -If only route code 11 is specified                             @TTA* 20410900
*   -Then return route code 11 to the caller                      @TTA* 20411000
*   -Set flag to indicate that return value has been found        @TTA* 20411100
* -Else                                                           @TTA* 20411200
*   -Turn off route code 11                                       @TTA* 20411300
* -Is it a broadcast message                                      @TTA* 20411400
*   -Then return ALL                                              @TTA* 20411500
*   -Set flag to indicate that return value has been found        @TTA* 20411600
* -Is it a hardcopy message                                       @TTA* 20411700
*   -Then return MLG                                              @TTA* 20411800
*   -Set flag to indicate that return value has been found        @TTA* 20411900
* -Scan the route codes 16 - 1:                                   @TTA* 20412000
*   -If a route code is found then this is the one to choose      @TTA* 20412100
*     -Save the selected route code number                        @TTA* 20412200
*     -Set flag to indicate that return value has been found      @TTA* 20412300
* -Scan the route codes 17 - 128:                                 @TTA* 20412400
*   -If a route code is found then this is the one to choose      @TTA* 20412500
*     -Save the selected route code number                        @TTA* 20412600
*     -Set flag to indicate that return value has been found      @TTA* 20412700
*                                                                 @TTA* 20412800
* -Return either a zero or the equivalent destination class in R1 @TTA* 20412900
*                                                                 @TTA* 20413100
*   Input:                                                        @TTA* 20413200
*     R7 -> MDBT                                                  @TTA* 20413300
*     R14 = Return address                                        @TTA* 20413400
******************************************************************@TTA* 20413500
RCM2DEST BAKR  R14,0               Save caller's environment       @TTA 20413600
         USING MDBSCP,R7           addressability to cp object     @TTA 20413700
         MVC   LCLRTCDS,MDBCERC     Init local copy                @TTA 20413800
*                                    of routing code mask          @TTA 20413900
         MVI   LCRTLAST,X'00'      Set last byte to zero           @TTA 20414000
         NC    RTCODMSK,LCLRTVLD   Turn off invalid bits           @TTA 20414100
         OI    RCFNDFLG,RCNOTFND     Init to not found             @TTA 20414200
         XR    R0,R0               Set the defaults for flags      @TTA 20414300
         ST    R0,RTCFINAL           used in searching             @TTA+20414400
                                     the route code mask           @TTA 20414500
         CLC   RTCODMSK,WTPMASK    Check if only route code 11     @TTA+20414600
                                     was specified                 @TTA 20414700
         JNE   RCT11OFF            Go if not just 11               @TTA 20414800
         LA    R1,11               Set 11 in the output            @TTA 20414900
         ST    R1,RTCFINAL         Return code 11 to               @TTA+20415000
                                     the caller                    @TTA 20415100
         NI    RCFNDFLG,X'FF'-RCNOTFND Set flag to indicate        @TTA+20415200
                                     that return value has been    @TTA+20415300
                                     found                         @TTA 20415400
         J     RCHCONLY            Continue                        @TTA 20415500
RCT11OFF NI    RTCODMSK+1,B'11011111'  Turn off route code 11      @TTA 20415600
RCHCONLY TM    MDBMCSF1,MDBMCSG    Check for hardcopy-only         @TTA 20415700
         JZ    RCBCONLY            Not hardcopy only               @TTA 20415800
         TM    MDBCMSC2,MDBCOCMD   Operator command echo?          @TTA 20416000
         JO    RCBCONLY            Yes                             @TTA 20416100
         LA    R5,130              Set routing code 130 for        @TTA+20416200
                                     hardcopy message              @TTA 20416300
         ST    R5,RTCFINAL         Set in output                   @TTA 20416400
         NI    RCFNDFLG,X'FF'-RCNOTFND Set flag to indicate        @TTA+20416500
                                     that return value has been    @TTA+20416600
                                     found                         @TTA 20416700
         J     RCT1TO16                                            @TTA 20416800
RCBCONLY TM    MDBMLVL1,MDBMLBC    Check for broadcast msg         @TTA 20416900
         JZ    RCT1TO16            Go if it is not broadcast       @TTA 20417000
         LA    R0,129              Use routing code 129 for        @TTA+20417100
                                     broadcast                     @TTA 20417200
         ST    R0,RTCFINAL         Set final route code            @TTA 20417300
         NI    RCFNDFLG,X'FF'-RCNOTFND Set flag to indicate        @TTA+20417400
                                     that return value has been    @TTA+20417500
                                     found                         @TTA 20417600
*-----------------------------------------------------------------@TTA* 20417700
* Check for routing codes 1-16 not zero AND routing code not      @TTA* 20417800
* yet set                                                         @TTA* 20417900
*-----------------------------------------------------------------@TTA* 20418000
RCT1TO16 CLC   LCLRTC16,HALFZERO   Check if routing codes 1-16     @TTA+20418100
                                     specified                     @TTA 20418200
         JE    RC17T128            Go if not                       @TTA 20418300
         TM    RCFNDFLG,RCNOTFND   Check if any routing code       @TTA+20418400
                                     has been found                @TTA 20418500
         JNO   RCTDEST             Yes, continue                   @TTA 20418600
*-----------------------------------------------------------------@TTA* 20418700
* One of the routing codes in the first 2 bytes is on.            @TTA* 20418800
* Search from hignest to lowest.                                  @TTA* 20418900
*-----------------------------------------------------------------@TTA* 20419000
         XR    R2,R2               Clear work                      @TTA 20419100
         XR    R3,R3                 registers                     @TTA 20419200
         LA    R4,RTCODMSK+1       Address the second byte of      @TTA+20419300
                                     the route code mask           @TTA 20419400
         LA    R5,16               Initialize to 16 (route cds)    @TTA 20419500
         OC    0(1,R4),0(R4)       Check if any code set           @TTA 20419600
         JNZ   RCKWHICH            There is some                   @TTA 20419700
         LA    R4,RTCODMSK         Address the first byte          @TTA 20419800
         LA    R5,8                Route code counter              @TTA 20419900
*-----------------------------------------------------------------@TTC* 20420000
* Get the non-zero byte and determine which routing code (bit)    @TTA* 20420100
* is set.                                                         @TTA* 20420200
*-----------------------------------------------------------------@TTA* 20420300
RCKWHICH IC    R2,0(R4)            Get the non-zero byte           @TTA 20420400
         LA    R15,8                                               @TTA 20420500
RCCHBIT1 SRDL  R2,1                Shift out the last bit of R2    @TTA+20420600
                                     into the first bit of R3      @TTA 20420700
         LTR   R3,R3               Anything there?                 @TTA 20420800
         JM    RCTRTCDE            Go if the high-order bit on     @TTA 20420900
         BCTR  R5,0                Else reduce count by one        @TTA 20421000
         JCT   R15,RCCHBIT1        Continue search                 @TTA 20421100
         J     RC17T128            All bits are zero, go check     @TTA+20421200
                                     routing codes 17-128          @TTA 20421300
RCTRTCDE ST    R5,RTCFINAL         Set the route code found        @TTA 20421400
         NI    RCFNDFLG,X'FF'-RCNOTFND  Indicate routing code      @TTA+20421500
                                     found                         @TTA 20421600
         J     RCTDEST             Continue                        @TTA 20421700
*-----------------------------------------------------------------@TTA* 20421800
* Check for routing codes 17-128 not zero AND routing code not    @TTA* 20421900
* yet found.                                                      @TTA* 20422000
*-----------------------------------------------------------------@TTA* 20422100
RC17T128 CLC   LCLRTCHI,MASKZERO   Any routing code 17-128?        @TTA 20422200
         JE    RCTDEST             No, check if any found          @TTA 20422300
         TM    RCFNDFLG,RCNOTFND   No routing code found so        @TTA+20422400
                                     far?                          @TTA 20422500
         JNO   RCTDEST             No                              @TTA 20422600
*-----------------------------------------------------------------@TTA* 20422700
* The 17-128 portion of the routing code mask is non-zero.        @TTA* 20422800
* Search from 17 to 128 and select the first one set.             @TTA* 20422900
*-----------------------------------------------------------------@TTA* 20423000
         XR    R5,R5               Clear counter                   @TTA 20423100
         LA    R4,RTCODMSK+2       Start past routing code 16      @TTA 20423200
         LR    R2,R4               Copy starting point addr        @TTA 20423300
         LA    R3,14               Set length for CLCL             @TTA 20423400
         CLCL  R2,R4               Check if any bit set            @TTA 20423500
         JE    RCTDEST             None, return zero value         @TTA 20423618
         LA    R4,RTCODMSK         Get starting address of         @TTA+20423700
                                     routing code mask             @TTA 20423800
         LR    R5,R2               Copy non-zero byte address      @TTA 20423900
         SR    R5,R4               Calculate offset                @TTA 20424000
         SLL   R5,3                Multiply by 8 to get first      @TTA+20424100
                                     bit address                   @TTA 20424200
         LA    R5,1(,R5)           Add one                         @TTA 20424300
         XR    R3,R3               Clear for insert                @TTA 20424400
         ICM   R3,B'1000',0(R2)    Get the content of the byte     @TTA 20424500
         XR    R2,R2               Set starting value for          @TTA+20424600
                                     bit search                    @TTA 20424700
         LA    R15,8               Set the count of bits           @TTA 20424800
*-----------------------------------------------------------------@TTA* 20424900
* Keep shifting out the bits until a non-zero bit is found        @TTA* 20425000
*-----------------------------------------------------------------@TTA* 20425100
RCCHBIT2 SLDL  R2,1                Shift all bits left             @TTA 20425200
         LTR   R2,R2               Is the high-order bit set?      @TTA 20425300
         JNZ   RCBITFND            Yes, save the value             @TTA 20425400
         AHI   R5,1                Next bit                        @TTA 20425500
         JCT   R15,RCCHBIT2        Keep checking                   @TTA 20425600
         J     RCTDEST             No more routing bits            @TTA 20425700
RCBITFND ST    R5,RTCFINAL         Store selected routing code     @TTA 20425800
         NI    RCFNDFLG,X'FF'-RCNOTFND  Indicate routing code      @TTA+20425900
                                     found                         @TTA 20426000
*                                      IF RTCFINAL µ= 0            @TTA 20426100
*-----------------------------------------------------------------@TTA* 20426200
* Return to the caller.  R1 contains either zero or the final     @TTA* 20426300
* route code.                                                     @TTA* 20426400
*-----------------------------------------------------------------@TTA* 20426500
RCTDEST  L     R1,RTCFINAL         Get the final route code        @TTA 20426600
         PR                        Return to caller                @TTA 20426700
         DROP  R7                  MDBSCP                          @TTA 20426800
*********************************************************************** 20430000
* PROCLINE-  Process the line. Test to see if the message is a        * 20431000
*            multiline message, and if so set the appropriate         * 20432000
*            log record fields.                                       * 20433000
*            Test to see if the line fits in one output record.       * 20434000
*            If line does not fit in one output record, then          * 20435000
*            split the line. Finally put the output record in         * 20436000
*            the output dataset.                                      * 20437000
*                                                                 @TTA* 20437200
* From IATCNDFM:                                                  @TTA* 20437400
*                                                                 @TTA* 20437600
*  | JES3 Prefix   |        DLOGTEXT                    |         @TTA* 20437800
*  +---------------+--------------------+---------------+         @TTC* 20438000
*  | JES3 prefix |*|&|receive id text   | message text  |         @TTA* 20438200
*  +---------------+--------------------+---------------+         @TTA* 20438400
*                                                                 @TTA* 20438600
* If we need to create another record, we will keep the           @TTA* 20438800
* preamble of the existing record.  Here are examples of          @TTC* 20439000
* split messages and how the suppression character is handled:    @TTA* 20439200
*                                                                 @TTA* 20439400
* An Example of a Message with a Receive Id that was              @TTA* 20439600
* Split (beginning of prefix chopped off and the record is        @TTA* 20439800
* truncated for illustration purposes):                           @TTC* 20440000
*                                                                 @TTA* 20440200
*  1055149  SY1 R= MSTJCL00 IEE136I LOCAL  TIME=10.55.14 DATE=    @TTA* 20440400
*  1055149  SY1 R= MSTJCL00 2019.362                              @TTA* 20440600
*                                                                 @TTA* 20440800
* Note that the split text begins at the same position as text    @TTA* 20441000
* in previous Line (after the Receive Id).                        @TTA* 20441200
*                                                                 @TTA* 20441400
* An Example of a Suppressed Message that has a Receive Id that   @TTA* 20441600
* was Split (beginning of prefix chopped off and the record is    @TTA* 20441800
* truncated for illustration):                                    @TTA* 20442000
*                                                                 @TTA* 20442200
*  1108299 &SY1 R= MSTJCL00 IEE136I LOCAL  TIME=11.08.29 DATE=    @TTA* 20442400
*  1108299 &SY1 R= MSTJCL002019.362                               @TTA* 20442600
*                                                                 @TTA* 20442800
* Note that the split text begins 1 back from message text in     @TTA* 20443000
* previous Line (no space after the job name)                     @TTA* 20443200
*                                                                 @TTA* 20443400
* An Example of a Suppressed Action Message that has a Receive    @TTA* 20443600
* Id that was Split (beginning of prefix chopped off and the      @TTA* 20443800
* record was truncated for illustration):                         @TTA* 20444000
*                                                                 @TTA* 20444200
*  1220599 *&SY1 R= MSTJCL00 IEE136I LOCAL  TIME=12.16.28 DATE=   @TTA* 20444400
*  1220599 *&SY1 R= MSTJCL002019.363                              @TTA* 20444600
*                                                                 @TTA* 20444800
* Note that the split text begins 1 back from message text in     @TTA* 20445000
* previous Line and the suppression character IS repeated in      @TTA* 20445200
* the split text.                                                 @TTA* 20445400
*                                                                 @TTA* 20445600
*                                                                 @TTA* 20445800
*                                                                     * 20450000
*   Input:                                                        @04A* 20460000
*     R2  = MDB message length                                    @TTA* 20465000
*     R3 -> MDBTMSGT - input message text                         @TTA* 20467000
*     r7 -> MDBT                                                  @04A* 20470000
*     R14 = return address                                        @04A* 20480000
*********************************************************************** 20490000
PROCLINE DS    0H                                                  @04A 20500000
         BAKR  R14,0               save caller's environment       @04A 20510000
         USING MDBT,R7             addressability to MDB Text          X20520000
                                   object                          @04A 20530000
         MVI   FrstLnSp,C'N'       Set first line was split to N   @TTC 20540000
*                                                                3#@TTD 20550000
*                                                                       20580000
* set up log record base                                                20590000
*                                                                  @04A 20600000
*                                                               51#@TTD 20610000
*                                                                  @TTD 20810000
         MVC   PREVMLID,MLID       Setup PrevMLID for next iteration   X20811001
                                                                 6#@TTD 20812001
*********************************************************************** 20880000
* loop through text, issue PUT for each piece of text up to length @TTC 20890000
* 126                                                              @TTA 20895000
*                                                                  @04A 20900000
*********************************************************************** 20910000
TXTLP    L     R0,LOGCURLN         Get used line length            @TTA 20912000
         LA    R1,DLOGBFSZ         Output line length              @TTA 20914000
         SR    R1,R0               calculate available length      @TTA 20918000
         CR    R2,R1               see if text is too long for buffer  X20920000
                                                                   @TTC 20930000
         JNH   TXTDN               do last piece if not            @04A 20940000
         CLI   FrstLnSp,C'N'       First line?                     @TTA 20942000
         JNE   TXTDNLST            No, just put out the the        @TTA+20944000
                                     rest up to the max. line      @TTA+20946000
                                     length                        @TTA 20948000
*********************************************************************** 20950000
* The Text needs to be split.  scan the text backward for         @TTA* 20950500
* for a split position.                                           @TTA* 20951000
*                                                                 @TTA* 20951500
* To determine were the text should be split the following        @TTA* 20952000
* rules are applied.  Valid split characters (character in        @TTA* 20952500
* the message at which a split is desired): blank, comma, or      @TTA* 20953000
* an equal sign.  Scan backwards using the residual text          @TTA* 20953500
* text length and and stop on the first valid split character.    @TTA* 20954000
* If a valid split character is not found within 28 positions     @TTA* 20954500
* back then split it there.                                       @TTA* 20955000
*                                                                 @TTA* 20955500
* Also, the default maximum scan length (28) may need to be       @TTC* 20956000
* adjusted to guarantee that the entire message will fit by       @TTA* 20956500
* just splitting the message once.                                @TTA* 20957000
* get length in R4                                                @TTC* 20960000
*********************************************************************** 20970000
         AR    R1,R3               Position past the last char.    @TTA+20975000
                                     of the input text             @TTA 20985000
         AHI   R1,-1               Point at the last character     @TTA 20990000
         LR    R4,R1               Copy to R1                      @TTC 21000000
         AHI   R1,-28              Ending position                 @TTA 21005000
TXTSC    CLI   0(R4),C' '          look for a blank                @04A 21010000
         JE    TXTL                stop if found                   @04A 21020000
         CLI   0(R4),C'='          Equal sign?                     @TTA 21023000
         JE    TXTL                Yes, stop                       @TTA 21026000
         CLI   0(R4),C','          look for a comma                @04A 21030000
         JE    TXTL                Yes, stop                       @TTC 21040000
*                                                                4#@TTD 21050000
         BCTR  R4,0                back up                         @TTC 21090000
         CR    R4,R1               see if at end position          @04A 21100000
         JNL   TXTSC               loop back if not                @04A 21110000
         J     TXTL5               Continue                        @TTC 21130000
TXTL     AHI   R4,1                Step past the split char.       @TTC 21140000
TXTL5    SR    R4,R3               calculate length                @TTA 21145000
*********************************************************************** 21150000
* issue PUT for the partial text                                   @04A 21160000
*********************************************************************** 21170000
         JAS   R14,PUTREC          PUT the DLOG record             @TTC 21180000
         CLI   FrstLnSp,C'N'       First split line?               @TTA 21180100
         JNE   SETSPLN                                             @TTA 21180200
         CLI   SUPPCHAR,C' '       Was suppression char. used?     @TTA 21180300
         JE    SETSPLN             No, continue                    @TTA 21180400
         L     R0,LOGCURTX         Get the current pointer         @TTA 21180500
         AHI   R0,-1               Back up                         @TTA 21180600
         ST    R0,LOGCURTX         Save                            @TTA 21180700
         L     R0,LOGCURLN         Get used length                 @TTA 21180800
         AHI   R0,-1               reduce by one                   @TTA 21180900
         ST    R0,LOGCURLN         Save                            @TTA 21181000
SETSPLN  CLI   PrevRecT,HCRMLWTO   Is this the first line and we just  X21182001
                                   split it to a second line?      @TTC 21183001
         JNE   FnshSpt4            No, then finish split and put line  X21184001
                                                                   @05A 21185001
         CLI   SnglLnMg,C'Y'       Is this a single line message?  @05A 21185101
         JE    FnshSpt4            Yes, then skip setting first line   X21185201
                                   split indicator                 @05A 21185301
         MVI   FrstLnSp,C'Y'       Set first line was split to Y   @05A 21186001
FnshSpt4 DS    0H                                                  @05A 21187001
*                                                                4#@TTD 21190000
         SR    R2,R4               reduce the count                @04A 21230000
         AR    R3,R4               bump down the record            @04A 21240000
         J     TXTLP               loop to do all pieces           @TTC 21250000
TXTDNLST LR    R2,R1               Set length to the max.          @TTA+21253000
                                     available                     @TTA 21256000
*********************************************************************** 21260000
* issue PUT for last (or only) piece                               @04A 21270000
*                                                                  @04A 21280000
TXTDN    DS    0H                                                  @04A 21290000
*                                                                  @04A 21300000
*                                                                4#@TTD 21310000
*********************************************************************** 21350000
         CLI   FrstLnSp,C'Y'       Is this the first line of a         X21351001
                                   multiline that was split?       @05A 21352001
         JE    MLIDAPP4            Yes, then branch to build line with X21353001
                                     console name added            @TTC 21354001
*                                                                  @TTD 21360001
         JNO   NOTFIRST            no, ok                          @04A 21370001
         TM    DESC2,MDBDESCI      is it descriptor code 9?        @04A 21380000
         JO    NOTFIRST            yes, ok                         @04A 21390000
         CLI   SnglLnMg,C'Y'       Is this a single line message?  @05A 21391001
         JE    NOTFIRST            Skip adding console id since    @TTCX21392001
                                     it is a single message        @TTC 21393001
*                                                                2#@TTD 21400000
MLIDAPP4 DS    0H                                                  @05A 21411001
         MVI   FrstLnSp,C'N'       Reset first line split field    @05A 21412001
         LA    R9,LOGBUF           DLOG record                     @TTC 21420000
         USING DLOGLINE,R9         addressability                  @TTC 21430000
         CLC   CONSNAME,EIGHTZRO   Any console?                    @TTC 21440000
         JE    NOTFIRST            No, skip moving one in          @TTC 21450000
         TM    PFLAGS,CENTURY      Does customer want a 4-digit    @TTC+21460000
                                     year in output records?       @TTC 21470000
         JZ    MV4YCON             Yes, use diferent offset        @TTC 21480000
         MVC   DLOG4YCN,CONSNAME   Copy console id                 @TTC 21490000
         J     NOTFIRST            Continue                        @TTC 21500000
MV4YCON  MVC   DLOGCONS,CONSNAME   Copy console id                 @TTC 21510000
         DROP  R9                  LOGBUF                          @TTC 21520000
*                                                              117#@TTD 21530000
NOTFIRST DS    0H                                                  @04M 22640000
*                                                                  @04M 22650000
         LR    R4,R2               get length of text              @04M 22660000
         JAS   R14,PUTREC          PUT the DLOG record             @TTC 22670000
         DROP  R7                  Drop addressability to MDB Text     X22680000
                                   object                          @04A 22690000
         PR                        return to caller                @04A 22700000
*                                                                       22710000
*********************************************************************** 22720000
* End subroutines                                                     * 22730000
*********************************************************************** 22740000
*                                                                       22750000
*********************************************************************** 22760000
* static variables                                                    * 22770000
*********************************************************************** 22780000
MDBLGDAT LOCTR                     Resume data segment             @TTA 22785000
*                                                                       22790000
*      translate table for testing for ebcdic numbers                   22800000
*                                                                       22810000
NUMTAB   DC    240X'FF',10X'00',6X'FF'                                  22820000
*                                                                  @D2A 22830000
*      translate tables for scanning parm field                    @D2A 22840000
*                                                                  @D2A 22850000
TRTTAB1  DC    256X'00'                                            @D2A 22860000
         ORG   TRTTAB1+C','         stop on comma                  @D2A 22870000
         DC    C','                                                @D2A 22880000
         ORG   TRTTAB1+C'('         stop on left paren             @D2A 22890000
         DC    C'('                                                @D2A 22900000
         ORG   ,                                                   @D2A 22910000
TRTTAB2  DC    256X'00'                                            @D2A 22920000
         ORG   TRTTAB2+C')'         stop on right paren            @D2A 22930000
         DC    C')'                                                @D2A 22940000
         ORG   ,                                                   @D2A 22950000
ZLPAREN  DC    0F'0',3X'00',C'('   3 zeros and a left paren        @D2A 22960000
*                                                                       22970000
*      translate table for hex conversion                               22980000
*      must be at least 240 bytes past base                             22990000
HEXTAB   EQU   *-240                                                    23000000
         DC    C'0123456789ABCDEF' must follow hextab                   23010000
*                                                                       23020000
STRNAME  DC    CL26'SYSPLEX.OPERLOG' stream name                        23030000
k_UnkId  DC    X'00FFFFFF'         Unknown console id              @L1A 23040000
k_CnId_4B_Internal   DC  X'00000000'   Internal console id         @L1A 23050000
k_CnId_4B_Instream_128 DC  X'00000080' Instream console id         @L1A 23060000
k_ConsName_Instream  DC  CL8'INSTREAM' Console name INSTREAM       @L1A 23070000
k_ConsName_Internal  DC  CL8'INTERNAL' Console name INTERNAL       @L1A 23080000
k_Unknown            DC  CL8'UNKNOWN'  Console name UNKNOWN        @L1A 23090000
*                                                                3#@TTD 23100000
ANSLEN   DC    A(L'ANSAREA)        length of logger's answer area       23130000
STRBUFFL EQU   64*1024             length of largest log record         23140000
STRBLEN  DC    A(STRBUFFL)                                              23150000
         LTORG                                                          23160000
*********************************************************************** 23161000
*        Control Translation Table.  This table converts all      @PDA* 23162000
*        unreadable symbols to EBCDIC blanks, with the exception  @PDA* 23163000
*        of the DBCS Shift-out and Shift-in charaters, which are  @PDA* 23164000
*        converted to '<' and '>' respectively.                   @PDA* 23165000
*********************************************************************** 23167000
         SPACE 1                                                        23168000
TRCONTRL EQU   *                                                        23169000
         DC    X'40404040404040404040404040404C6E'                      23169200
         DC    X'40404040404040404040404040404040' Shift-Out, Shift-in  23169300
         DC    X'40404040404040404040404040404040'                      23169500
         DC    X'40404040404040404040404040404040'                      23169600
         DC    X'404040404040404040404A4B4C4D4E4F'                      23169700
         DC    X'504040404040404040405A5B5C5D5E5F'                      23169800
         DC    X'60614040404040404040406B6C6D6E6F'                      23169900
         DC    X'404040404040404040407A7B7C7D7E7F'                      23170200
         DC    X'40818283848586878889404040404040'                      23170300
         DC    X'40919293949596979899404040404040'                      23170400
         DC    X'4040A2A3A4A5A6A7A8A9404040404040'                      23170500
         DC    X'40404040404040404040404040404040'                      23170600
         DC    X'40C1C2C3C4C5C6C7C8C9404040404040'                      23170700
         DC    X'40D1D2D3D4D5D6D7D8D9404040404040'                      23170800
         DC    X'4040E2E3E4E5E6E7E8E9404040404040'                      23170900
         DC    X'F0F1F2F3F4F5F6F7F8F9404040404040'                      23171100
******************************************************************@TTA* 23171200
*        JES3 Routing destinations table                           @TTA 23171318
******************************************************************@TTA* 23171400
RTCODTBL DC    CL3'1  '            Routing code   1                @TTA 23171518
         DC    CL3'2  '            Routing code   2                @TTA 23171600
         DC    CL3'TAP'            Routing code   3                @TTA 23171718
         DC    CL3'4  '            Routing code   4                @TTA 23171800
         DC    CL3'5  '            Routing code   5                @TTA 23171918
         DC    CL3'6  '            Routing code   6                @TTA 23172000
         DC    CL3'UR '            Routing code   7                @TTA 23172118
         DC    CL3'TP '            Routing code   8                @TTA 23172200
         DC    CL3'SEC'            Routing code   9                @TTA 23172318
         DC    CL3'ERR'            Routing code  10                @TTA 23172400
         DC    CL3'11 '            Routing code  11                @TTA 23172518
         DC    CL3'12 '            Routing code  12                @TTA 23172600
         DC    CL3'13 '            Routing code  13                @TTA 23172718
         DC    CL3'14 '            Routing code  14                @TTA 23172800
         DC    CL3'15 '            Routing code  15                @TTA 23172918
         DC    CL3'16 '            Routing code  16                @TTA 23173000
         DC    CL3'17 '            Routing code  17                @TTA 23173118
         DC    CL3'18 '            Routing code  18                @TTA 23173200
         DC    CL3'19 '            Routing code  19                @TTA 23173318
         DC    CL3'20 '            Routing code  20                @TTA 23173400
         DC    CL3'21 '            Routing code  21                @TTA 23173518
         DC    CL3'22 '            Routing code  22                @TTA 23173600
         DC    CL3'23 '            Routing code  23                @TTA 23173718
         DC    CL3'24 '            Routing code  24                @TTA 23173800
         DC    CL3'25 '            Routing code  25                @TTA 23173918
         DC    CL3'26 '            Routing code  26                @TTA 23174000
         DC    CL3'27 '            Routing code  27                @TTA 23174118
         DC    CL3'28 '            Routing code  28                @TTA 23174200
         DC    CL3'29 '            Routing code  29                @TTA 23174318
         DC    CL3'30 '            Routing code  30                @TTA 23174400
         DC    CL3'31 '            Routing code  31                @TTA 23174518
         DC    CL3'32 '            Routing code  32                @TTA 23174600
         DC    CL3'33 '            Routing code  33                @TTA 23174718
         DC    CL3'34 '            Routing code  34                @TTA 23174800
         DC    CL3'35 '            Routing code  35                @TTA 23174918
         DC    CL3'36 '            Routing code  36                @TTA 23175000
         DC    CL3'37 '            Routing code  37                @TTA 23175118
         DC    CL3'38 '            Routing code  38                @TTA 23175200
         DC    CL3'39 '            Routing code  39                @TTA 23175318
         DC    CL3'40 '            Routing code  40                @TTA 23175400
         DC    CL3'LOG'            Routing code  41                @TTA 23175518
         DC    CL3'JES'            Routing code  42                @TTA 23175600
         DC    CL3'D1 '            Routing code  43                @TTA 23175718
         DC    CL3'D2 '            Routing code  44                @TTA 23175800
         DC    CL3'D3 '            Routing code  45                @TTA 23175918
         DC    CL3'D4 '            Routing code  46                @TTA 23176000
         DC    CL3'D5 '            Routing code  47                @TTA 23176118
         DC    CL3'D6 '            Routing code  48                @TTA 23176200
         DC    CL3'D7 '            Routing code  49                @TTA 23176318
         DC    CL3'D8 '            Routing code  50                @TTA 23176400
         DC    CL3'D9 '            Routing code  51                @TTA 23176518
         DC    CL3'D10'            Routing code  52                @TTA 23176600
         DC    CL3'D11'            Routing code  53                @TTA 23176718
         DC    CL3'D12'            Routing code  54                @TTA 23176800
         DC    CL3'D13'            Routing code  55                @TTA 23176918
         DC    CL3'D14'            Routing code  56                @TTA 23177000
         DC    CL3'D15'            Routing code  57                @TTA 23177118
         DC    CL3'D16'            Routing code  58                @TTA 23177200
         DC    CL3'D17'            Routing code  59                @TTA 23177318
         DC    CL3'D18'            Routing code  60                @TTA 23177400
         DC    CL3'D19'            Routing code  61                @TTA 23177518
         DC    CL3'D20'            Routing code  62                @TTA 23177600
         DC    CL3'D21'            Routing code  63                @TTA 23177718
         DC    CL3'D22'            Routing code  64                @TTA 23177800
         DC    CL3'M1 '            Routing code  65                @TTA 23177918
         DC    CL3'M2 '            Routing code  66                @TTA 23178000
         DC    CL3'M3 '            Routing code  67                @TTA 23178118
         DC    CL3'M4 '            Routing code  68                @TTA 23178200
         DC    CL3'M5 '            Routing code  69                @TTA 23178318
         DC    CL3'M6 '            Routing code  70                @TTA 23178400
         DC    CL3'M7 '            Routing code  71                @TTA 23178518
         DC    CL3'M8 '            Routing code  72                @TTA 23178600
         DC    CL3'M9 '            Routing code  73                @TTA 23178718
         DC    CL3'M10'            Routing code  74                @TTA 23178800
         DC    CL3'M11'            Routing code  75                @TTA 23178918
         DC    CL3'M12'            Routing code  76                @TTA 23179000
         DC    CL3'M13'            Routing code  77                @TTA 23179118
         DC    CL3'M14'            Routing code  78                @TTA 23179200
         DC    CL3'M15'            Routing code  79                @TTA 23179318
         DC    CL3'M16'            Routing code  80                @TTA 23179400
         DC    CL3'M17'            Routing code  81                @TTA 23179518
         DC    CL3'M18'            Routing code  82                @TTA 23179600
         DC    CL3'M19'            Routing code  83                @TTA 23179718
         DC    CL3'M20'            Routing code  84                @TTA 23179800
         DC    CL3'M21'            Routing code  85                @TTA 23179918
         DC    CL3'M22'            Routing code  86                @TTA 23180000
         DC    CL3'M23'            Routing code  87                @TTA 23180118
         DC    CL3'M24'            Routing code  88                @TTA 23180200
         DC    CL3'M25'            Routing code  89                @TTA 23180318
         DC    CL3'M26'            Routing code  90                @TTA 23180400
         DC    CL3'M27'            Routing code  91                @TTA 23180518
         DC    CL3'M28'            Routing code  92                @TTA 23180600
         DC    CL3'M29'            Routing code  93                @TTA 23180718
         DC    CL3'M30'            Routing code  94                @TTA 23180800
         DC    CL3'M31'            Routing code  95                @TTA 23180918
         DC    CL3'M32'            Routing code  96                @TTA 23181000
         DC    CL3'S1 '            Routing code  97                @TTA 23181118
         DC    CL3'S2 '            Routing code  98                @TTA 23181200
         DC    CL3'S3 '            Routing code  99                @TTA 23181318
         DC    CL3'S4 '            Routing code 100                @TTA 23181400
         DC    CL3'S5 '            Routing code 101                @TTA 23181518
         DC    CL3'S6 '            Routing code 102                @TTA 23181600
         DC    CL3'S7 '            Routing code 103                @TTA 23181718
         DC    CL3'S8 '            Routing code 104                @TTA 23181800
         DC    CL3'S9 '            Routing code 105                @TTA 23181918
         DC    CL3'S10'            Routing code 106                @TTA 23182000
         DC    CL3'S11'            Routing code 107                @TTA 23182118
         DC    CL3'S12'            Routing code 108                @TTA 23182200
         DC    CL3'S13'            Routing code 109                @TTA 23182318
         DC    CL3'S14'            Routing code 110                @TTA 23182400
         DC    CL3'S15'            Routing code 111                @TTA 23182518
         DC    CL3'S16'            Routing code 112                @TTA 23182600
         DC    CL3'S17'            Routing code 113                @TTA 23182718
         DC    CL3'S18'            Routing code 114                @TTA 23182800
         DC    CL3'S19'            Routing code 115                @TTA 23182918
         DC    CL3'S20'            Routing code 116                @TTA 23183000
         DC    CL3'S21'            Routing code 117                @TTA 23183118
         DC    CL3'S22'            Routing code 118                @TTA 23183200
         DC    CL3'S23'            Routing code 119                @TTA 23183318
         DC    CL3'S24'            Routing code 120                @TTA 23183400
         DC    CL3'S25'            Routing code 121                @TTA 23183518
         DC    CL3'S26'            Routing code 122                @TTA 23183600
         DC    CL3'S27'            Routing code 123                @TTA 23183718
         DC    CL3'S28'            Routing code 124                @TTA 23183800
         DC    CL3'S29'            Routing code 125                @TTA 23183918
         DC    CL3'S30'            Routing code 126                @TTA 23184000
         DC    CL3'S31'            Routing code 127                @TTA 23184118
         DC    CL3'S32'            Routing code 128                @TTA 23184200
         DC    CL3'ALL'            Routing code 129                @TTA 23184318
         DC    CL3'MLG'            Routing code 130                @TTA 23184400
RTCODTBE EQU   *                   End of the table                @TTA 23184518
RTCODTB1 EQU   3                   Single entry length             @TTA 23184600
         SPACE 1                                                   @TTA 23184718
LCLRTVLD DC    X'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC0'               @TTA 23184800
WTPMASK  DC    X'0020000000000000000000000000000000'               @TTA 23184918
MASKZERO DC    XL14'0'             Zeros for rt. code check        @TTA 23185000
HALFZERO EQU   MASKZERO,2,C'B'     Halfword of zeroes              @TTA 23185118
EIGHTZRO EQU   MASKZERO,8,C'B'     8 zeros                         @TTA 23185218
BLANKS   DC    CL(DLOGBFSZ)' '     Blanks for clearing LOGBUF      @TTA 23185300
         EJECT                                                     @TTA 23185418
*********************************************************************** 23185500
* dynamic variables                                                   * 23185600
*********************************************************************** 23185700
*                                                                       23185800
*********************************************************************** 23185900
*********************************************************************** 23186000
SV       DS    18F                 save area                            23186100
DATEWORK DS    F                   work area for checking dates         23187000
DATEWRK1 DS    F                   work area for checking dates         23188000
DATEWRK2 DS    F                   work area for checking dates    @D2A 23189000
DAYSWORK DS    F                   work area for checking dates    @D2A 23190000
SSTCK    DS    2F                  start date in stck format            23200000
ESTCK    DS    2F                  end date in stck format              23210000
DSTCK    DS    2F                  delete date in stck format           23220000
CONVWORK DC    4F'0'               parm area for convtod macro          23230000
CONVDATE EQU   CONVWORK+8,4        date in parm area                    23240000
CURRSTCK DS    2F,2F               timestamps (GMT,local) of curr rec   23250000
RETCODE  DS    F                   return code from logger              23260000
RSNCODE  DS    F                   reason code from logger              23270000
*                                                                  @TTD 23280000
RECCOUNT DS    F                   number of logger records read        23300000
TIOTADDR DS    F                   TIOT address from EXTRACT       @TTA 23303000
MSGOFFST DS    H                   Copy of MDBCTOFF2               @TTA 23306000
*                                                                  @TTD 23310000
SDATE    DS    XL7                 start date as ebcdiic yyyyddd        23320000
EDATE    DS    XL7                 end date as ebcdiic yyyyddd          23330000
DDATE    DS    XL7                 delete date as ebcdiic yyyyddd       23340000
TDATE    DS    XL7                 today's date as ebcdiic yyyyddd @D2A 23350000
COPYDAYS DS    CL3                 copy days ebcdiic nnn           @D2A 23360000
DELDAYS  DS    CL3                 delete days ebcdiic nnn         @D2A 23370000
STRTOKEN DS    CL16                token for accessing stream           23380000
BRWTOKEN DS    CL4                 token for browse session             23390000
ANSAREA  DS    CL(ANSAA_LEN)       answer area for log requests         23400000
CURRBLK  DS    XL8                 block id of current block            23410000
DELBLK   DS    XL8                 block id of blk after one to delete  23420000
*                                                                  @TTD 23430000
JOBNAME  DS    CL8                 jobname                              23440000
CONSNAME DS    CL8                 console name                    @D1A 23450000
SYSNAME  DS    CL(L'MDBGOSNM)      System name                     @TTA 23451000
SYSNSAVE DS    CL11                Save area for system name       @TTA+23452000
                                     followed by ' R='             @TTA 23453000
SUPPCHAR DS    C                   Suppression character           @TTA 23454000
SCANFLAG DC    X'0'                Scan flag                       @TTA 23455000
SCANCONT EQU   X'80'               Statement is continued          @TTA 23456000
SCANSKIP EQU   X'40'               Skip the statement              @TTA 23459500
CONSID   DS    XL4                 4-byte console id               @TTC 23460000
*                                                                2#@TTD 23470000
MCSFLAGS DS    0CL2                MCS flags from MDB              @D1A 23490000
MCSFLAG1 DS    X                   MCS flag 1                      @D1A 23500000
MCSFLAG2 DS    X                   MCS flag 2                      @D1A 23510000
*                                                                2#@TTD 23520000
MLID     DC    F'0'                multiline id from MDB           @TTC 23540000
PREVMLID DC    F'0'                Previous multiline id from MDB  @TTC 23541000
         ORG   ,                                                   @P4A 23550000
*                                                                  @TTD 23560000
*                                                                  @P4A 23570000
DESCS    DS    0XL2                copy of descriptor codes        @P4A 23580000
DESC1    DS    XL1                 descriptor codes byte 1         @P4A 23590000
DESC2    DS    XL1                 descriptor codes byte 2         @P4A 23600000
*                                                                  @P4A 23610000
*                                                                  @TTD 23620000
WTLFLAG  DS    C                   'Y' indicates a WTL                  23630000
FIRSTLNE DS    C                   'Y' indicates the first msg line     23640000
FrstLnSp DS    C                   'Y' indicates the first msg line    X23641000
                                   was split                       @05A 23642000
PrevRecT DS    C                   Previous message record type    @05A 23643000
SnglLnMg DS    C                   'Y' indicates that it is a single   X23644000
                                   line message                    @05A 23645000
*                                                                       23650000
FLAGS1   DS    XL1                 mdb flags                            23660000
FLAGGO   EQU   X'01'               processed general object             23670000
FLAGCO   EQU   X'02'               processed control prog object        23680000
*                                                                       23690000
PFLAGS   DS    XL1                 parameter flags                 @D2A 23700000
COPY     EQU   X'01'               "COPY" was specified            @D2A 23710000
DELETE   EQU   X'02'               "DELETE" was specified          @D2A 23720000
HCFORMAT EQU   X'04'               "HCFORMAT" was specified        @04A 23730000
YEAR     EQU   X'08'               "HCFORMAT(YEAR)" was specified      *23740000
                                    (this is also the default)     @04A 23750000
CENTURY  EQU   X'10'               "HCFORMAT(CENTURY)" was specified   *23760000
                                                                   @04A 23770000
*                                                                       23780000
MFLAGS   DS    XL1                 Miscellaneous flags             @01A 23790000
OPEN     EQU   X'80'               Output file has been opened     @01A 23800000
REACHEOF EQU   X'40'               End of file reached             @01A 23810000
NOBREND  EQU   X'20'               Return code of 8 or more on     @02C 23820000
*                                  IXGBRWSE REQUEST=START. Do not  @02A 23830000
*                                  perform IXGBRWSE REQUEST=END    @02A 23840000
SKIPSYS  EQU   X'01'               Skip MDB - system outside of    @TTA+23843000
                                     the JESplex                   @TTA 23846000
*                                                                       23850000
HCRMLWTO EQU   C'M'                1st line of multi-line message  @TTA 23851000
SDTTABLE DC    A(0)                System Definition Table         @TTA 23852000
SDTINCR  DC    A(SDTENLEN)         Increment for JXLE              @TTA 23852500
SDTLAST  DC    A(0)                Last entry for JXLE             @TTA 23853000
CURRMSGR DS    A                   Current MSGROUTE entry          @TTA 23853500
MAINPROC DC    C'MAINPROC,'        MAINPROC keyword                @TTA 23854000
MAINNAME DC    C'NAME='            NAME keyword                    @TTA 23854500
MAINID   DC    C'ID='              ID keyword                      @TTA 23855000
MSGROUTE DC    C'MSGROUTE,'        MSGROUTE keyword                @TTA 23855500
MAINKWD  DC    C'MAIN='            MAIN keyword                    @TTA 23856000
*                                                                 2@P8D 23860000
         SPACE 1                                                   @TTA 23860400
* JES3 dest to routing code conversion routine dynamic storage     @TTA 23860800
         DS    0F                  Align routing code storage      @TTA 23861200
RTCODMSK DS    CL17                Routing codes work area         @TTA 23861600
LCLRTCDS EQU   RTCODMSK,16,C'C'    First 16 bytes of rt. codes     @TTA 23862000
LCLRTC16 EQU   LCLRTCDS,2,C'C'     First 2 bytes of rt. codes      @TTA 23862400
LCRTLAST EQU   RTCODMSK+16,1,C'B'  Last byte of rt. codes          @TTA 23862800
LCLRTCHI EQU   LCLRTCDS+2,14,C'C'  First 2 bytes of extended       @TTA+23863200
                                     routing codes (17-128)        @TTA 23863600
RCFNDFLG DC    B'0'                Flag byte                       @TTA 23864000
RCNOTFND EQU   B'10000000'         Not found flag                  @TTA 23864400
RTCFINAL DS    F                   Final routing code              @TTA 23864800
*                                                                  @TTA 23865200
* JES3IN record area                                               @TTA 23865600
*                                                                  @TTA 23866000
INAREA   DS    CL80                JES3IN Input record             @TTA 23866400
INAREA72 EQU   INAREA+71           Continuation column             @TTA 23866800
*-----------------------------------------------------------------@TTA* 23867200
*        Register save area used for record scans                 @TTA* 23867600
*-----------------------------------------------------------------@TTA* 23868000
INPOINT  DS    A ---------------+  R1= Starting column for scan    @TTA 23868400
         DC    F'1'             |  R2= Increment                   @TTA 23868800
         DC    A(INAREA+70) ----+  R3= Ending column               @TTA 23869200
*                                                                       23870000
* buffer for log record                                                 23880000
*                                                                       23890000
LOGBUFP  DS    0F                  prefix to log record                 23900000
LOGBUFL  DS    H                   length of logbuf data + 4            23910000
         DC    H'0'                                                     23920000
LOGBUF   DS    CL(DLOGBFSZ)        log record (mapped by           @TTC+23930000
                                     DLOGLINE)                     @TTA 23931000
LOGCURLN DS    F ---------------+  Current length                  @TTA 23934000
LOGCURTX DS    F ---------------+  Current text pointer            @TTA 23937000
*                                                                       23940000
EXTRLIST EXTRACT MF=L              List form of EXTRACT            @TTA 23940500
*                                                                  @TTA 23941000
J3INDCB  DCB   DDNAME=JES3IN,      Input DCB                       @TTA+23941500
               MACRF=GM,                                           @TTA+23942000
               DSORG=PS,                                           @TTA+23942500
               LRECL=80,                                           @TTA+23943000
               RECFM=FB,                                           @TTA+23943500
               DCBE=IFILEX                                         @TTA 23944000
IFILDCBL EQU   *-J3INDCB           DCB storage length              @TTA 23944500
IFILEX   DCBE  RMODE31=BUFF,       DCB extension                   @TTA+23945000
               EODAD=J3INCLS                                       @TTA 23945500
*                                                                  @TTA 23946000
IDCBADDR DS    F                   Input DCB storage address       @TTA 23946500
OFILE    DCB   DDNAME=DLOG,        dcb for output file             @TTCX23950000
               DSORG=PS,                                               X23960000
               MACRF=PM,                                               X23970000
               RECFM=VB,                                               X23980000
               DCBE=OFILEX,                                        @TTA+23985000
               LRECL=130           126 + 4 for rdw                 @TTC 23990000
OFILDCBL EQU   *-OFILE             DCB storage length              @TTA 23990500
OFILEX   DCBE  RMODE31=BUFF        DCB extension                   @TTA 23991000
*                                                                  @TTA 23991500
ODCBADDR DS    F                   Output DCB storage address      @TTA 23992000
*                                                                  @TTA 23992500
OPENLIST OPEN  (0),                List form of OPEN               @TTA+23993000
               MODE=31,                                            @TTA+23993500
               MF=L                                                @TTA 23994000
*                                                                  @TTA 23994500
CLOSLIST CLOSE (0),                List form of CLOSE              @TTA+23995000
               MODE=31,                                            @TTA+23995500
               MF=L                                                @TTA 23996000
*                                                                       24000000
*********************************************************************** 24010000
* messages                                                            * 24020000
*********************************************************************** 24030000
*                                 1         2         3         4       24040000
*                        1234567890123456789012345678901234567890123456 24050000
BADPMSG  DC    AL2(36),C'MLG001I INVALID OR MISSING PARAMETER'     @D2C 24060000
*                                                                       24070000
LOGRMSG  DC    AL2(LOGRMLEN)                                            24080000
LOGRMSGD DC    C'MLG002I ERROR DURING SYSTEM LOGGER '              @P5C 24090000
LOGRMSGT DC    CL10' ',C', RETURN CODE '                           @P6C 24100000
LOGRMRET DC    CL3' ',C', REASON CODE '                                 24110000
LOGRMRSN DS    CL4,C' '                                                 24120000
LOGRMLEN EQU   *-LOGRMSGD                                          @P5C 24130000
*                                 1         2         3         4       24140000
*                        1234567890123456789012345678901234567890123456 24150000
         DS    0H                   for alignment                  @03A 24160000
EMPTYMSG DC    AL2(27),C'MLG003I NO RECORDS IN RANGE'                   24170000
         DS    0H                   for alignment                  @03A 24180000
EMPTYSTM DC    AL2(27),C'MLG004I LOG STREAM IS EMPTY'              @03A 24190000
*********************************************************************** 24200000
* Output record                                                    @01A 24210000
*********************************************************************** 24220000
         DS    0H                   for alignment                  @03A 24230000
NOMSGAL2 DC    AL2(NOMSGLEN)        length field                   @01A 24240000
NOMSGMSG DC    C'ILG0001 RECORDS NOT AVAILABLE. '                  @01A 24250000
NOMSGRTN DC    CL10' '              IXG service routine instance   @01A 24260000
NOMSGM2  DC    C' RETURN CODE '     more text                      @01A 24270000
NOMSGRC  DC    CL4'   ,'            return code                    @01A 24280000
NOMSGM3  DC    C' REASON CODE '     more text                      @01A 24290000
NOMSGRS  DC    CL4' '               reason code                    @01A 24300000
         DC    CL1' '               pad character for unpack       @01A 24310000
NOMSGLEN EQU   *-NOMSGMSG           Message text length            @01A 24320000
*                                                                       24330000
         EJECT                                                          24340000
*********************************************************************** 24350000
* dsects                                                              * 24360000
*********************************************************************** 24370000
*-----------------------------------------------------------------@TTA* 24370200
* System Definitions Table                                        @TTA* 24370400
*-----------------------------------------------------------------@TTA* 24370600
SDTENTRY DSECT                     System Definition Table         @TTA 24370800
SDTSYSNM DS    CL8                 System name                     @TTA 24371000
SDTIDLEN DS    X                   RID length                      @TTA 24371200
SDTEFLAG DS    X                   Flags                           @TTA 24371400
SDTNOR   EQU   X'80'               Don't use R= (only system       @TTA+24371600
                                     name, e.g. SY1= )             @TTA 24371800
SDTRCHAR DS    CL8                 RID value                       @TTA 24372000
SDTMSGRT DS    F                   MSGROUTE table pointer          @TTA 24372200
SDTENLEN EQU   *-SDTENTRY          SDT Entry length                @TTA 24372400
SDTTSIZE EQU   32*SDTENLEN         Size of all entries             @TTA 24372600
*                                                                  @TTA 24372800
*-----------------------------------------------------------------@TTA* 24373000
*        Message Routing Table Entry.                             @TTA* 24373200
*-----------------------------------------------------------------@TTA* 24373400
MGRENTRY DSECT ,                   Message Routing Table Entry     @TTA 24373600
MGRCON   DS    CL8                 MCS Console Name                @TTA 24373800
MGRROUT  DS    H                   Route code mask                 @TTA 24374000
         SPACE 1                                                   @TTA 24374200
MGRFLAG1 DS    CL1                 MSGROUTE Flag One               @TTA 24374400
*-------------------------------------------------------------*    @TTA 24374600
*        Definition of MGRFLAG1.                              *    @TTA 24374800
*-------------------------------------------------------------*    @TTA 24375000
MGRREPLC EQU   X'80'               Route code equivalent of        @TTA 24375200
*                                    the destination class         @TTA 24375400
*                                    associated with this          @TTA 24375600
*                                    MSGROUTE statement should     @TTA 24375800
*                                    replace message's route       @TTA 24376000
*                                    codes                         @TTA 24376200
         DS    CL1                 Align on halfword boundary      @TTA 24376700
MGRESIZE EQU   *-MGRENTRY          Size of MSGROUTE entry          @TTA 24377200
MGRTSIZE EQU   128*MGRESIZE        Total table size                @TTA 24377700
*                                                                       24380000
STRBUFF  DSECT                     buffer for log records               24390000
         ORG   *+STRBUFFL          length of buffer                     24400000
*                                                                       24410000
         IXGANSAA LIST=YES         logger answer area                   24420000
         PUSH  PRINT                                                    24430000
******************************************************************@TTA* 24430118
*              DUMMY CONTROL SECTION FOR DLOG MESSAGE BUFFER       @TTA 24430200
******************************************************************@TTA* 24430318
*        A dual mapping of a portion of the DLOGLINE DSECT        @TTA* 24430400
*        (Console ID through DATE stamp) has been defined to      @TTA* 24430518
*        accommodate the choice of either a 2-digit year or       @TTA* 24430600
*        4-digit year datestamp.                                  @TTA* 24430718
*        Layout of the mappings is as follows:                    @TTA* 24430800
*                                                                 @TTA* 24430918
*        For a 2-digit year datestamp                             @TTA* 24431000
*        DLOGCLAS ---------------------------------               @TTA* 24431118
*                 |  3 bytes for class of message |               @TTA* 24431200
*        DLOGBLNK ---------------------------------               @TTA* 24431318
*                 |  2 bytes for format blanks    |               @TTA* 24431400
*        DLOGCONS ---------------------------------               @TTA* 24431518
*                 |  8 bytes for console id       |               @TTA* 24431600
*        DLOGSEP1 ---------------------------------               @TTA* 24431718
*                 |  1 byte  for format blank     |               @TTA* 24431800
*        DLOGDATE ---------------------------------               @TTA* 24431918
*                 |  5 bytes for datestamp YYDDD  |               @TTA* 24432000
*        DLOGSEPA ---------------------------------               @TTA* 24432118
*                 |  1 byte  for format blank     |               @TTA* 24432200
*                 ---------------------------------               @TTA* 24432318
*                                                                 @TTA* 24432400
*        For a 4-digit year datestamp                             @TTA* 24432518
*        DLOGCLAS ---------------------------------               @TTA* 24432600
*                 |  3 bytes for class of message |               @TTA* 24432718
*        DLOG4YBK ---------------------------------               @TTA* 24432800
*                 |  1 byte  for format blank     |               @TTA* 24432918
*        DLOG4YCN ---------------------------------               @TTA* 24433000
*                 |  8 bytes for console id       |               @TTA* 24433118
*        DLOG4YDT ---------------------------------               @TTA* 24433200
*                 |  7 bytes for datestamp YYYYDDD|               @TTA* 24433318
*        DLOGSEPA ---------------------------------               @TTA* 24433400
*                 |  1 byte  for format blank     |               @TTA* 24433518
*                 ---------------------------------               @TTA* 24433600
*                                                                 @TTA* 24433700
******************************************************************@TTA* 24433800
DLOGLINE DSECT                                                     @TTA 24433900
DLOGCLAS DS    CL3                 class of message                @TTA 24434000
DLOGDUFL EQU   *                   start of dual year, 2-digit     @TTA 24434100
*                                  or 4-digit format section       @TTA 24434200
*                                  start of 2-digit section        @TTA 24434300
DLOGBLNK DS    CL2                 format blanks                   @TTA 24434400
DLOGCONS DS    CL8                 console to which                @TTA 24434500
*                                  message was issued              @TTA 24434600
DLOGSEP1 DS    CL1                 format blanks                   @TTA 24434700
DLOGDATE DS    CL5                 julian date stamp yyddd         @TTA 24434800
*                                  start of 4-digit format         @TTA 24434900
         ORG   DLOGDUFL            mapping section                 @TTA 24435000
DLOG4YBK DS    CL1                 format blank                    @TTA 24435100
DLOG4YCN DS    CL8                 console to which                @TTA 24435200
*                                  message was issued              @TTA 24435300
DLOG4YDT DS    CL7                 julian date stamp yyyyddd       @TTA 24435400
         ORG   ,                   back to common mapping          @TTA 24435500
DLOGSEPA DS    CL1                 format blank                    @TTA 24435600
DLOGTIME DS    CL7                 time message was issued         @TTA 24435700
         ORG   DLOGTIME            Back up to the time stamp       @TTA 24435800
DLOGTMHH DS    CL2                 HH portion                      @TTA 24435900
DLOGTMMM DS    CL2                 MM portion                      @TTA 24436000
DLOGTMSS DS    CL2                 SS portion                      @TTA 24436100
DLOGTMFS DS    CL1                 Fraction of seconds             @TTA 24436200
DLOGSEP2 DS    CL1                 format blank                    @TTA 24436300
DLOGSPEC DS    CL1                 (*)=action                      @TTA+24436400
                                   (+)=JES3 command echo           @TTA+24436500
                                   (=)=MVS command echo            @TTA+24436600
                                   (b)=blank                       @TTA 24436700
DLOGTEXT DS    CL90                message text starting with      @TTA+24436800
                                     MPF suppression character     @TTA+24436900
                                     if specified                  @TTA 24437000
         ORG   DLOGTEXT            Back up to message start        @TTA 24437100
DLOGSYS  DS    CL8                 Message origin system name      @TTA 24437200
         ORG   ,                                                   @TTA 24437300
DLOGEND  EQU   *                   end of buffer                   @TTA 24437400
DLOGBFSZ EQU   DLOGEND-DLOGLINE    console buffer cell             @TTA 24437500
*                                  pool cell size                  @TTA 24437600
DLOGLGPT EQU   DLOGTEXT-DLOGCLAS   length of DLOG preamble         @TTA 24437700
*        PRINT NOGEN                                               @TTC 24440000
         IEAVG132 ,                mdb prefix                           24450000
         IEAVM105 ,                mdb                                  24460000
         IEECUCM ,                 UCM                             @TTA 24463000
         IHADCB ,                  DCB mapping                     @TTA 24466000
TIOT     DSECT                                                     @TTA 24469000
         IEFTIOT1                  Task I/O table                  @TTC 24470000
         IHAPSA ,                  Prefixed save area              @TTA 24475000
         CVT   DSECT=YES           cvt                                  24480000
         POP   PRINT                                                    24490000
*                                                                       24500000
*********************************************************************** 24510000
* equates                                                             * 24520000
*********************************************************************** 24530000
*                                                                       24540000
         IXGCON ,                  System logger equates                24550000
*                                                                       24568000
*********************************************************************** 24570000
* register definition and usage                                   @TTC* 24580000
*********************************************************************** 24590000
*                                                                       24600000
R0       EQU   0                   Parameter register              @TTA 24605000
R1       EQU   1                   work and parm reg                    24610000
R2       EQU   2                   work reg                             24620000
R3       EQU   3                   work reg                             24630000
R4       EQU   4                   work reg                             24640000
R5       EQU   5                   unused                          @TTC 24650000
R6       EQU   6                   pointer to end of the mdb            24660000
R7       EQU   7                   base for mdb objects                 24670000
R8       EQU   8                   base for mdb                         24680000
R9       EQU   9                   entry parameters and                 24690000
*                                  base for DLOG record DSECT      @TTC 24700000
R10      EQU   10                  base for logger buffer               24710000
R11      EQU   11                  unused                          @TTC 24720000
R12      EQU   12                  data section base               @TTC 24730000
R13      EQU   13                  linkage                              24740000
R14      EQU   14                  linkage                              24750000
R15      EQU   15                  linkage                              24760000
         END                                                            24770000
