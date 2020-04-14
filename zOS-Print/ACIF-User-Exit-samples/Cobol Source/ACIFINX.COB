000200 PROCESS DYNAM NUMPROC(PFD) TRUNC(OPT) APOST NOSEQ RENT                 03
000220* LAST UPDATE ON 9 Apr 2018 AT 15:32:21 BY  HOWARDT VERSION 01 *
000300* UPDATE ON 10 Sep 2012 AT 16:47:38 BY  HOWARDT VERSION 01   *     0002 00
000400 ID DIVISION.                                                     00030003
000500 PROGRAM-ID. 'ACIFINX'.                                           00040003
000600 AUTHOR. TURETZKY--HYDRA.                                         00050003
000700 INSTALLATION. IBM BOULDER PROGRAMMING CENTER.                    00060003
000800               This program is a sample exit for ACIF
000900               (APKACIF,5648-062) demonstrating the use of the
001000               ACIF input exit.
001100                                                                  00100003
001200               In order to use this exit, include the control     00110003
001300               INPEXIT=ACIFINX to enable this exit, and include   00120003
001400               the load module in a dataset referenced in STEPLIB 00130003
001500               or elsewhere in the module search order.  This     00140003
001600               example uses the ACIFSAMP.LINEDATA data from the   00150003
001700               ACIF examples disk and the ACSAMP FORMDEF and      00160003
001800               PAGEDEF.                                           00170003
001900                                                                  00180003
002000               This program will create an indexing NOP record    00190003
002100               after the first line of the first page of each     00200003
002200               document, remove the barcode data, and replace     00210003
002300               the bottom page message with another phrase.       00220003
002400                                                                  00230003
002500               Method of operation: each input record is examined 00240003
002600               for an ANSI skip to channel 1, used to indicate    00250003
002700               top- of-form. The account number on this line is   00260003
002800               looked up in a table, and a NOP containing the     00270003
002900               store name is inserted.                            00280003
003000                                                                  00290003
003100               If the last line of the page contains a            00300003
003200               continuation message (identified by a skip to      00310003
003300               channel 4), a flag is set. If the page is not      00320003
003400               continued, then the message text on the skip to    00330003
003500               channel 3 is replaced with new text. The barcode   00340003
003600               information, indicated by a skip to channel 12,    00350003
003700               is removed by setting the record delete flag.      00360003
003800                                                                  00370003
003900 DATE-WRITTEN. 23 SEP 93.                                         00430003
004000 DATE-COMPILED.                                                   00440003
004100 SECURITY. IBM SAMPLE CODE ONLY.                                  00450003
004200*/**************************************************************/
004220*/* Licensed under the Apache License, Version 2.0 (the        */
004230*/* "License"); you may not use this file except in compliance */
004240*/* with the License. You may obtain a copy of the License at  */
004250*/*                                                            */
004260*/* http://www.apache.org/licenses/LICENSE-2.0                 */
004270*/*                                                            */
004280*/* Unless required by applicable law or agreed to in writing, */
004290*/* software distributed under the License is distributed on an*/
004291*/* "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY     */
004292*/* KIND, either express or implied.  See the License for the  */
004293*/* specific language governing permissions and limitations    */
004294*/* under the License.                                         */
004295*/*------------------------------------------------------------*/
004296*/*                                                            */
004300*/*   COPYRIGHT (C) 1993,2007 IBM CORPORATION                  */
004400*/*   COPYRIGHT (C) 2007,2018 RICOH COMPANY, LTD               */
004500*/*                                                            */
004600*/*   Permission to use, copy, modify, and distribute          */
004700*/*   this software for any purpose with or without fee        */
004800*/*   is hereby granted, provided that the above               */
004900*/*   copyright notices appear in all copies.                  */
005000*/*                                                            */
005100*/*   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY       */
005200*/*   OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT       */
005300*/*   LIMITED TO THE WARRANTIES OF MERCHANTABILITY,            */
005400*/*   FITNESS FOR A PARTICULAR PURPOSE AND                     */
005500*/*   NONINFRINGEMENT.  IN NO EVENT SHALL RICOH, RICOH         */
005600*/*   SUBSIDIARIES, ANY OF ITS SUPPLIERS OR ANY OF THE         */
005700*/*   OTHER COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,         */
005800*/*   DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF      */
005900*/*   CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF        */
006000*/*   OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR         */
006100*/*   OTHER DEALINGS IN THE SOFTWARE.                          */
006200*/**************************************************************/
006300 TITLE 'ACIF Sample Input Exit'.                                  00640003
006400 ENVIRONMENT DIVISION.                                            00650003
006500 CONFIGURATION SECTION.                                           00660003
006600 SOURCE-COMPUTER. IBM-370.                                        00670003
006700 OBJECT-COMPUTER. IBM-370.                                        00680003
006800     EJECT                                                        00690003
006900 DATA DIVISION.                                                   00700003
007000 WORKING-STORAGE SECTION.                                         00710003
007100 77  PGMNAME                 PIC X(8) VALUE 'ACIFINX'.            00720003
007210 77  ABND-PGM                PIC X(8) VALUE 'CEE3DMP'.            00730003
007300 77  ABEND-CODE              PIC 9(4) BINARY VALUE 12.            00740003
007310 77  ABEND-OPTS              PIC X(255)                           !@01
007320     VALUE 'ENC(CUR) THR(CUR) FILE VAR NOBLOCK NOSTOR SF(ALL)' .  !@011
007400 77  AFPWRITE                PIC X(8) VALUE 'AFPWRITE'.           00750003
007500* The following are values for positions and lengths of items     00760003
007600* in the input lines.                                             00770003
007700 77  REPT-LEN                PIC 9(4) BINARY VALUE 3.             00780003
007800 77  DATE-LEN                PIC 9(4) BINARY VALUE 8.             00790003
007900 77  PAGE-DISP               PIC ZZ,ZZ9.                          00800003
008000 77  CC-TOF                  PIC X.                               00810003
008100     88  ANSI-TOF            VALUE '1'.                           00820003
008200     88  MACH-TOF            VALUE X'8B'.                         00830003
008300 77  CC-CONTINUED            PIC X.                               00840003
008400     88  ANSI-CONTINUED      VALUE '4'.                           00850003
008500     88  MACH-CONTINUED      VALUE X'A3'.                         00860003
008600 77  CC-MESSAGE              PIC X.                               00870003
008700     88  ANSI-MESSAGE        VALUE '3'.                           00880003
008800     88  MACH-MESSAGE        VALUE X'9B'.                         00890003
008900 77  CC-BARCODE              PIC X.                               00900003
009000     88  ANSI-BARCODE        VALUE 'C'.                           00910003
009100     88  MACH-BARCODE        VALUE X'F3'.                         00920003
009200     SKIP1                                                        00930003
009300 01  MISC-SAVED-DATA.                                             00940003
009400     05  FIRST-LINE-FLAG     PIC X VALUE LOW-VALUE.               00950003
009500         88 FIRST-LINE       VALUE HIGH-VALUE.                    00960003
009600         88 NOTFIRST-LINE    VALUE LOW-VALUE.                     00970003
009700     05  INSERT-FLAG         PIC X VALUE LOW-VALUE.               00980003
009800         88 INSERT-LINE      VALUE HIGH-VALUE.                    00990003
009900         88 NOINSERT-LINE    VALUE LOW-VALUE.                     01000003
010000     05  LINE-COUNT          PIC S9(8) BINARY VALUE ZERO.         01010003
010100     05  PAGE-COUNT          PIC S9(8) BINARY VALUE ZERO.         01020003
010200     SKIP2                                                        01030003
010300* This is the data portion of the NOP record. It specifies        01040003
010400* the name of division and store for indexing.                    01050003
010500 01  NOP-DATA.                                                    01060003
010600     05  FILLER              PIC X(11) VALUE '**INDEX**: '.       01070003
010700     05  NOP-DIVISION-CODE   PIC 99.                              01080003
010800     05  NOP-DIVISION-NAME   PIC X(12).                           01090003
010900     05  FILLER              PIC X  VALUE SPACE.                  01100003
011000     05  NOP-STORE-CODE      PIC 99.                              01110003
011100     05  NOP-STORE-NAME      PIC X(12).                           01120003
011200     SKIP2                                                        01130003
011300 01  RECORD-BUFFERS.                                              01140003
011400     05  SAVED-LINE-RECLEN   PIC 9(4) BINARY.                     01150003
011500     05  INSERT-RECLEN       PIC 9(4) BINARY.                     01160003
011600     05  SAVED-LINE-BUFFER   PIC X(8192).                         01170003
011700     05  INSERT-RECORD-BUFFER PIC X(8192).                        01180003
011800     05  COPY-PHRASE.                                             01190003
011900         10  COPY-PHRASE-CC  PIC X.                               01200003
012000         10  FILLER          PIC X(30) VALUE                      01210003
012100                             '***COPY***COPY***COPY***COPY**'.    01220003
012200         10  FILLER          PIC X(30) VALUE                      01230003
012300                             '*COPY***COPY***COPY***COPY****'.    01240003
012400     SKIP2                                                        01250003
012500 01  LOCATION-TABLES.                                             01260003
012600     05  DIV-DIVISION-VALUES.                                     01270003
012700         10 FILLER           PIC 99    VALUE 01.                  01280003
012800         10 FILLER           PIC X(12) VALUE 'BALDMTN BIKE'.      01290003
012900         10 FILLER           PIC 99    VALUE 02.                  01300003
013000         10 FILLER           PIC X(12) VALUE 'WeeBee Shoes'.      01310003
013100         10 FILLER           PIC 99    VALUE 03.                  01320003
013200         10 FILLER           PIC X(12) VALUE 'TennisRacket'.      01330003
013300         10 FILLER           PIC 99    VALUE 04.                  01340003
013400         10 FILLER           PIC X(12) VALUE 'U-SELLUM    '.      01350003
013500     05  DIV-DIVISION           REDEFINES DIV-DIVISION-VALUES.    01360003
013600         10 DIV-DIV-TABLE OCCURS 4                                01370003
013700                             INDEXED BY DIV-DIV-INDX.             01380003
013800             15 DIV-DIV-NUM  PIC 99.                              01390003
013900             15 DIV-DIV-NAME PIC X(12).                           01400003
014000     05  DIV-STORE-VALUES.                                        01410003
014100         10 FILLER           PIC 99    VALUE 01.                  01420003
014200         10 FILLER           PIC X(12) VALUE 'N. Chicago  '.      01430003
014300         10 FILLER           PIC 99    VALUE 02.                  01440003
014400         10 FILLER           PIC X(12) VALUE 'Breckenridge'.      01450003
014500         10 FILLER           PIC 99    VALUE 03.                  01460003
014600         10 FILLER           PIC X(12) VALUE 'Rustbelt, MI'.      01470003
014700         10 FILLER           PIC 99    VALUE 04.                  01480003
014800         10 FILLER           PIC X(12) VALUE 'Aspen, CO   '.      01490003
014900         10 FILLER           PIC 99    VALUE 05.                  01500003
015000         10 FILLER           PIC X(12) VALUE 'Masonville  '.      01510003
015100         10 FILLER           PIC 99    VALUE 06.                  01520003
015200         10 FILLER           PIC X(12) VALUE 'Albuquerque '.      01530003
015300         10 FILLER           PIC 99    VALUE 07.                  01540003
015400         10 FILLER           PIC X(12) VALUE 'Bastogne    '.      01550003
015500         10 FILLER           PIC 99    VALUE 08.                  01560003
015600         10 FILLER           PIC X(12) VALUE 'Florence    '.      01570003
015700         10 FILLER           PIC 99    VALUE 09.                  01580003
015800         10 FILLER           PIC X(12) VALUE 'Madrid      '.      01590003
015900     05  DIV-STORE              REDEFINES DIV-STORE-VALUES.       01600003
016000         10 DIV-STORE-TABLE  OCCURS 9                             01610003
016100                             INDEXED BY DIV-STORE-INDX.           01620003
016200             15 DIV-STORE-NUM  PIC 99.                            01630003
016300             15 DIV-STORE-NAME PIC X(12).                         01640003
016400         SKIP1                                                    01650003
016500/ AFP STRUCTURED FIELD DEFINITIONS.                               01660003
016600     COPY STRFLDS SUPPRESS.                                       01670003
016700/ PASSED PARAMETERS.                                              01680003
016800 LINKAGE SECTION.                                                 01690003
016900 01  INP-PARMS.                                                   01700003
017000     05  INP-USTOR           POINTER.                             01710003
017100     05  INP-PFATTR          POINTER.                             01720003
017200     05  INP-RECPTR          POINTER.                             01730003
017300     05  FILLER              POINTER.                             01740003
017400     05  INP-RECLEN          PIC 9(4) BINARY.                     01750003
017500     05  FILLER              PIC XX.                              01760003
017600     05  INP-REQUEST         PIC X.                               01770003
017700         88  INP-USE         VALUE X'00'.                         01780003
017800         88  INP-DELETE      VALUE X'01'.                         01790003
017900         88  INP-INSERT      VALUE X'02'.                         01800003
018000     05  INP-EOF-FLAG        PIC X.                               01810003
018100         88  INP-EOF         VALUE 'Y'.                           01820003
018200                                                                  01830003
018300 01  INP-UAREA               PIC X(16).                           01840003
018400                                                                  01850003
018500 01  INP-ATTR.                                                    01860003
018600     05  INP-CC              PIC XXX.                             01870003
018700     05  INP-CCTYPE          PIC X.                               01880003
018800         88  INP-ANSI-CC     VALUE 'A'.                           01890003
018900         88  INP-MACH-CC     VALUE 'M'.                           01900003
019000     05  INP-CHARS           PIC X(20).                           01910003
019100     05  INP-FORMDEF         PIC X(8).                            01920003
019200     05  INP-PAGEDEF         PIC X(8).                            01930003
019300     05  INP-PRMODE          PIC X(8).                            01940003
019400     05  INP-TRC             PIC XXX.                             01950003
019500                                                                  01960003
019600* This is a template for the input record, pointed to by          01970003
019700* INP-RECPTR. The record's actual length is given by              01980003
019800* INP-RECLEN.                                                     01990003
019900 01  INP-LINE.                                                    02000003
020000     05  INP-CCVAL           PIC X.                               02010003
020100     05  INP-LINEDATA        PIC X(8191).                         02020003
020200     05  INP-FIRSTLINE       REDEFINES INP-LINEDATA.              02030003
020300         10  INP-DATE        PIC X(12).                           02040003
020400         10  FILLER          PIC X.                               02050003
020500         10  INP-ACCOUNT.                                         02060003
020600             15  INP-DIV-CODE   PIC 99.                           02070003
020700             15  FILLER         PIC X.                            02080003
020800             15  INP-STORE-CODE PIC 99.                           02090003
020900             15  FILLER         PIC X.                            02100003
021000             15  INP-ACCOUNT-NO PIC 99.                           02110003
021100     SKIP1                                                        02120003
021200 TITLE 'Initialization and Main Line'.                            02130003
021300 PROCEDURE DIVISION USING INP-PARMS.                              02140003
021400* make work area, attributes, and input line addressable.         02150003
021500     SET ADDRESS OF INP-UAREA TO INP-USTOR.                       02160003
021600     SET ADDRESS OF INP-ATTR TO INP-PFATTR.                       02170003
021700     SET ADDRESS OF INP-LINE TO INP-RECPTR.                       02180003
021800     MOVE ZERO TO RETURN-CODE.                                    02190003
021900* no special action is necessary at EOF.                          02200003
022000     IF INP-EOF                                                   02210003
022100      THEN                                                        02220003
022200       DISPLAY PGMNAME, ' EOF REACHED.';                          02230003
022300       MOVE PAGE-COUNT TO PAGE-DISP;                              02240003
022400       DISPLAY PGMNAME, PAGE-DISP, ' Pages processed.';           02250003
022500       GOBACK;                                                    02260003
022600     END-IF.                                                      02270003
022700* The print file attributes are used to determine the type        02280003
022800* of carriage control to test for for top-of-form.                02290003
022900* For purposes of this example, we assume the file will           02300003
023000* always have carriage control, and if machine control the        02310003
023100* skip to channel 1 immediate is used for new pages.              02320003
023200     IF INP-ANSI-CC                                               02330003
023300      THEN                                                        02340003
023400       SET ANSI-TOF       TO TRUE;                                02350003
023500       SET ANSI-MESSAGE   TO TRUE;                                02360003
023600       SET ANSI-CONTINUED TO TRUE;                                02370003
023700       SET ANSI-BARCODE   TO TRUE;                                02380003
023800      ELSE                                                        02390003
023900       SET MACH-MESSAGE   TO TRUE;                                02400003
024000       SET MACH-CONTINUED TO TRUE;                                02410003
024100       SET MACH-BARCODE   TO TRUE;                                02420003
024200       SET MACH-TOF       TO TRUE.                                02430003
024300     SKIP1                                                        02440003
024400* If the insert flag is set then a record has been placed in      02450003
024500* the saved buffer to be inserted. The record is put into         02460003
024600* the ACIF buffer and returned to ACIF with no further            02470003
024700* processing.                                                     02480003
024800     IF INSERT-LINE                                               02490003
024900      THEN                                                        02500003
025000       MOVE SAVED-LINE-RECLEN TO INP-RECLEN;                      02510003
025100       MOVE SAVED-LINE-BUFFER TO INP-LINE (1:SAVED-LINE-RECLEN);  02520003
025200       SET NOINSERT-LINE TO TRUE;                                 02530003
025300       GOBACK;                                                    02540003
025400     END-IF.                                                      02550003
025500     SKIP1                                                        02560003
025600* The carriage control character is tested for top-of-form.       02570003
025700* This identifies the first line of a page. The account           02580003
025800* number division and store code are found in the lookup          02590003
025900* tables, and a NOP record is inserted containing the names       02600003
026000* for use as an indexing key.                                     02610003
026100* If machine carriage control is used, then the first             02620003
026200* print line is the line after the top-of-form. A flag            02630003
026300* is set to cause this line to be treated as the top.             02640003
026400     IF FIRST-LINE OR (INP-CCVAL = CC-TOF)                        02650003
026500      THEN                                                        02660003
026600       IF ANSI-TOF OR FIRST-LINE                                  02670003
026700        THEN                                                      02680003
026800* This is a top-of-form line (or the first line on the page),     02690003
026900* so extract the accounting information and create the NOP        02700003
027000* line to be inserted. Control is then returned to ACIF and       02710003
027100* the original record inserted at the next call.                  02720003
027200         SET NOTFIRST-LINE TO TRUE;                               02730003
027300         ADD 1 TO PAGE-COUNT;                                     02740003
027400         MOVE 1 TO LINE-COUNT;                                    02750003
027500         PERFORM 0200-LOOKUP-ACCOUNT;                             02760003
027600         MOVE LENGTH OF NOP-DATA TO INSERT-RECLEN,                02770003
027700         CALL AFPWRITE USING SF-NOP,                              02780003
027800                             NOP-DATA,                            02790003
027900                             BY CONTENT LENGTH OF NOP-DATA,       02800003
028000                             BY REFERENCE INSERT-RECLEN,          02810003
028100                             INSERT-RECORD-BUFFER;                02820003
028200         PERFORM 0100-INSERT-RECORD;                              02830003
028300        ELSE                                                      02840003
028400         SET FIRST-LINE TO TRUE;                                  02850003
028500       END-IF;                                                    02860003
028600      ELSE                                                        02870003
028700       ADD 1 TO LINE-COUNT;                                       02880003
028800     END-IF.                                                      02890003
028900     SKIP1                                                        02900003
029000* Check for the page bottom lines by checking the carriage skips. 02910003
029100     EVALUATE INP-CCVAL;                                          02920003
029200      WHEN CC-MESSAGE                                             02930003
029300*      Replace the message line with the COPY line. The original  02940003
029400*      line buffer from ACIF is replaced and the length adjusted  02950003
029500*      to include carriage control and the new data. The          02960003
029600*      INP-REQUEST flag is unchanged, since ACIF sets it to USE.  02970003
029700       MOVE LENGTH OF COPY-PHRASE TO INP-RECLEN;                  02980003
029800       MOVE CC-MESSAGE TO COPY-PHRASE-CC;                         02990003
029900       MOVE COPY-PHRASE TO INP-LINE (1:LENGTH OF COPY-PHRASE);    03000003
030000      WHEN CC-CONTINUED                                           03010003
030100*      The continued message must appear before the COPY phrase   03020003
030200*      because continued uses channel 4 and the message uses      03030003
030300*      channel 3 to control placement. Therefore, the continued   03040003
030400*      line is saved, the insert flag set, the COPY phrase        03050003
030500*      replaces the continued message, and the continued message  03060003
030600*      is returned on the next call.                              03070003
030700       MOVE CC-MESSAGE TO COPY-PHRASE-CC;                         03080003
030800       MOVE LENGTH OF COPY-PHRASE TO INSERT-RECLEN;               03090003
030900       MOVE COPY-PHRASE TO INSERT-RECORD-BUFFER                   03100003
031000                           (1:LENGTH OF COPY-PHRASE);             03110003
031100       PERFORM 0100-INSERT-RECORD;                                03120003
031200      WHEN CC-BARCODE                                             03130003
031300*      The barcode line is deleted by setting the delete flag.    03140003
031400       SET INP-DELETE TO TRUE;                                    03150003
031500      WHEN OTHER                                                  03160003
031600*      all other lines are returned unmolested.                   03170003
031700       CONTINUE;                                                  03180003
031800     END-EVALUATE.                                                03190003
031900     SKIP1                                                        03200003
032000     GOBACK.                                                      03210003
032100     EJECT                                                        03220003
032200 0100-INSERT-RECORD.                                              03230003
032300* Insert a record before the current record. The current record   03240003
032400* from ACIF is saved in a buffer and and the new record returned  03250003
032500* to ACIF with the insert flag set.                               03260003
032600* Our own insert flag is set so that the original record can be   03270003
032700* returned on the next call.                                      03280003
032800     SUBTRACT 1 FROM LINE-COUNT.                                  03290003
032900     MOVE INP-RECLEN TO SAVED-LINE-RECLEN.                        03300003
033000     MOVE INP-LINE (1:INP-RECLEN) TO SAVED-LINE-BUFFER.           03310003
033100     MOVE INSERT-RECLEN TO INP-RECLEN.                            03320003
033200     MOVE INSERT-RECORD-BUFFER TO INP-LINE (1:INSERT-RECLEN).     03330003
033300     SET INSERT-LINE TO TRUE.                                     03340003
033400     SET INP-INSERT TO TRUE.                                      03350003
033500     SKIP3                                                        03360003
033600 0200-LOOKUP-ACCOUNT.                                             03370003
033700* This routine searches the division code and store code tables.  03380003
033800* The codes and names are placed into an AFP NOP record for use   03390003
033900* by the ACIF indexer so that names will show in the Viewer       03400003
034000* index window instead of just codes.                             03410003
034100     SET DIV-DIV-INDX TO 1.                                       03420003
034200     SEARCH DIV-DIV-TABLE                                         03430003
034300      AT END                                                      03440003
034400       MOVE 'UNKNOWN' TO NOP-DIVISION-NAME;                       03450003
034500      WHEN DIV-DIV-NUM (DIV-DIV-INDX) = INP-DIV-CODE              03460003
034600       MOVE DIV-DIV-NAME (DIV-DIV-INDX) TO                        03470003
034700            NOP-DIVISION-NAME;                                    03480003
034800     END-SEARCH.                                                  03490003
034900     SET DIV-STORE-INDX TO 1.                                     03500003
035000     SEARCH DIV-STORE-TABLE                                       03510003
035100      AT END                                                      03520003
035200       MOVE 'UNKNOWN' TO NOP-STORE-NAME;                          03530003
035300      WHEN DIV-STORE-NUM (DIV-STORE-INDX) = INP-STORE-CODE        03540003
035400       MOVE DIV-STORE-NAME (DIV-STORE-INDX) TO                    03550003
035500            NOP-STORE-NAME;                                       03560003
035600     END-SEARCH.                                                  03570003
035700     MOVE INP-DIV-CODE TO NOP-DIVISION-CODE.                      03580003
035800     MOVE INP-STORE-CODE TO NOP-STORE-CODE.                       03590003
035900 TITLE 'FORMAT AFPDS RECORD'.                                     03600003
036000 ID DIVISION.                                                     03610003
036100* This routine takes the structured field type, data, and data    03620003
036200* length and formats an AFP record and places it in the           03630003
036300* exit's buffer.                                                  03640003
036400 PROGRAM-ID. AFPWRITE COMMON.                                     03650003
036500 DATA DIVISION.                                                   03660003
036600 WORKING-STORAGE SECTION.                                         03670003
036700 77  SF-CC                       PIC X VALUE X'5A'.               03680003
036800 LINKAGE SECTION.                                                 03690003
036900 01  AFP-TYPE                    PIC X(3).                        03700003
037000 01  AFP-DATA                    PIC X(8192).                     03710003
037100 01  AFP-DATA-LENGTH             PIC 9(9) BINARY.                 03720003
037200 01  AFP-INSERT-LEN              PIC 9(4) BINARY.                 03730003
037300     SKIP1                                                        03740003
037400 01  SF-RECORD.                                                   03750003
037500     05  SF-INTRODUCER.                                           03760003
037600         10 SF-INTRO-CC      PIC X.                               03770003
037700         10 SF-INTRO-LEN     PIC 9(4) BINARY.                     03780003
037800         10 SF-INTRO-TYPE    PIC X(3).                            03790003
037900         10 SF-INTRO-FLAG    PIC X.                               03800003
038000         10 SF-INTRO-SEQNUM  PIC 9(4) BINARY.                     03810003
038100     05  SF-DATA             PIC X(8192).                         03820003
038200 SKIP3                                                            03830003
038300 PROCEDURE DIVISION USING AFP-TYPE,                               03840003
038400                          AFP-DATA,                               03850003
038500                          AFP-DATA-LENGTH,                        03860003
038600                          AFP-INSERT-LEN,                         03870003
038700                          SF-RECORD.                              03880003
038800* set the final record length (introducer plus data), which is    03890003
038900* found in the introducer length field, move in the introducer    03900003
039000* and the data, then write the record.                            03910003
039100     ADD LENGTH OF SF-INTRODUCER, AFP-DATA-LENGTH GIVING          03920003
039200         AFP-INSERT-LEN.                                          03930003
039300     SUBTRACT 1 FROM AFP-INSERT-LEN GIVING SF-INTRO-LEN.          03940003
039400     MOVE SF-CC TO     SF-INTRO-CC.                               03950003
039500     MOVE AFP-TYPE TO SF-INTRO-TYPE.                              03960003
039600     MOVE LOW-VALUE TO SF-INTRO-FLAG.                             03970003
039700     MOVE ZERO TO      SF-INTRO-SEQNUM.                           03980003
039800     MOVE AFP-DATA (1 : AFP-DATA-LENGTH) TO SF-DATA               03990003
039900                                         (1 : AFP-DATA-LENGTH).   04000003
040000     EXIT PROGRAM.                                                04010003
040100 END PROGRAM AFPWRITE.                                            04020003
040200 SKIP1                                                            04030003
040300 END PROGRAM ACIFINX.                                             04040003