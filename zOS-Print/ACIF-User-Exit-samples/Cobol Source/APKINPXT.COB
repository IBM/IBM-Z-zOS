000100 PROCESS DYNAM NUMPROC(PFD) TRUNC(OPT) APOST NOSEQ RENT
000200* LAST UPDATE ON 9 Apr 2018 AT 15:40:38 BY  HOWARDT VERSION 01   *
000300 ID DIVISION.
000400 PROGRAM-ID. APKINPXT.
000500 AUTHOR. TURETZKY--HYDRA.
000600 INSTALLATION. IBM BOULDER PROGRAMMING CENTER.
000700               This program is a sample exit for ACIF
000800               (APKACIF,5648-062) demonstrating the use of the
000900               ACIF input exit.
001000
001100               In order to use this exit, include the control
001200               INPEXIT=APKINPXT to enable this exit, and include
001300               the load module in a dataset referenced in STEPLIB
001400               or elsewhere in the module search order.  This
001500               example uses the BANKDATA data from the ACIF IVP,
001600               and the IVP FORMDEF and PAGEDEF, or, optionally,
001700               PAGEDEF P1EXITS (suppresses printing of the
001800               inserted key).
001900
002000               The program will insert the phrase "CONFIDENTIAL"
002100               in a blank space in the first line of each page
002200               and insert a record key beyond the printable area
002300               of the third line for use as an ACIF indexer key.
002400               It will also insert an AFPDS Include Page Segment
002500               record in each summary page, and delete any detail
002600               line that contains the string "TEST" as the third
002700               word.
002800
002900               Method of operation: each input record is examined
003000               for an ANSI skip to channel 1, used to indicate
003100               top- of-form. This line is examined for the first
003200               space large enough to contain the inserted phrase.
003300               and the modified record returned to ACIF.
003400
003500               Each record after the third line of the page is
003600               also scanned for the word "TEST" as the third word
003700               in the line. When found, ACIF is instructed to
003800               delete the record.
003900
004000               The third line of each page is the last heading
004100               line.  If it indicates a summary page, then an
004200               AFPDS Include Page Segment record is inserted to
004300               cause a logo to print on the page.
004400
004500
004600 DATE-WRITTEN. 23 SEP 93.
004700 DATE-COMPILED.
004800 SECURITY. IBM SAMPLE CODE ONLY.
004900*/**************************************************************/
004920*/* Licensed under the Apache License, Version 2.0 (the        */
004930*/* "License"); you may not use this file except in compliance */
004940*/* with the License. You may obtain a copy of the License at  */
004950*/*                                                            */
004960*/* http://www.apache.org/licenses/LICENSE-2.0                 */
004970*/*                                                            */
004980*/* Unless required by applicable law or agreed to in writing, */
004990*/* software distributed under the License is distributed on an*/
004991*/* "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY     */
004992*/* KIND, either express or implied.  See the License for the  */
004993*/* specific language governing permissions and limitations    */
004994*/* under the License.                                         */
004995*/*------------------------------------------------------------*/
004996*/*                                                            */
005000*/*   COPYRIGHT (C) 1993,2007 IBM CORPORATION                  */
005100*/*   COPYRIGHT (C) 2007,2018 RICOH COMPANY, LTD               */
005200*/*                                                            */
005300*/*   Permission to use, copy, modify, and distribute          */
005400*/*   this software for any purpose with or without fee        */
005500*/*   is hereby granted, provided that the above               */
005600*/*   copyright notices appear in all copies.                  */
005700*/*                                                            */
005800*/*   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY       */
005900*/*   OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT       */
006000*/*   LIMITED TO THE WARRANTIES OF MERCHANTABILITY,            */
006100*/*   FITNESS FOR A PARTICULAR PURPOSE AND                     */
006200*/*   NONINFRINGEMENT.  IN NO EVENT SHALL RICOH, RICOH         */
006300*/*   SUBSIDIARIES, ANY OF ITS SUPPLIERS OR ANY OF THE         */
006400*/*   OTHER COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,         */
006500*/*   DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF      */
006600*/*   CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF        */
006700*/*   OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR         */
006800*/*   OTHER DEALINGS IN THE SOFTWARE.                          */
006900*/**************************************************************/
007000 TITLE 'ACIF Sample Input Exit'.
007100 ENVIRONMENT DIVISION.
007200 CONFIGURATION SECTION.
007300 SOURCE-COMPUTER. IBM-370.
007400 OBJECT-COMPUTER. IBM-370.
007500     EJECT
007600 DATA DIVISION.
007700 WORKING-STORAGE SECTION.
007800 77  PGMNAME                 PIC X(8) VALUE 'APKINPXT'.
007900 77  ABND-PGM                PIC X(8) VALUE 'CEE3ABD'.
008000 77  ABEND-CODE              PIC 9(4) BINARY VALUE 12.
008100 77  AFPWRITE                PIC X(8) VALUE 'AFPWRITE'.
008200* The following are values for positions and lengths of items
008300* in the input lines.
008400 77  REPT-START              PIC 9(4) BINARY VALUE 9.
008500 77  REPT-LEN                PIC 9(4) BINARY VALUE 3.
008600 77  DATE-START              PIC 9(4) BINARY VALUE 100.
008700 77  DATE-LEN                PIC 9(4) BINARY VALUE 8.
008800 77  INSERT-START            PIC 9(4) BINARY VALUE 15.
008900 77  INDX-START              PIC 9(4) BINARY VALUE 134.
009000 77  SUMM-START              PIC 9(4) BINARY VALUE 60.
009100 77  SUMM-LIT                PIC X(7) VALUE 'SUMMARY'.
009200 77  DELT-START              PIC 9(4) BINARY VALUE 15.
009300 77  DELT-LIT                PIC X(4) VALUE 'TEST'.
009400 77  LAST-HEADING            PIC 9(4) BINARY VALUE 3.
009500 77  LINE-COUNT              PIC S9(8) BINARY VALUE ZERO.
009600 77  PAGE-COUNT              PIC S9(8) BINARY VALUE ZERO.
009700 77  PAGE-DISP               PIC ZZ,ZZ9.
009800 77  INSERT-PHRASE           PIC X(12) VALUE 'CONFIDENTIAL'.
009900 77  CC-TOF                  PIC X.
010000     88  ANSI-TOF            VALUE '1'.
010100     88  MACH-TOF            VALUE X'8B'.
010200 77  FIRST-LINE-FLAG         PIC X VALUE LOW-VALUE.
010300     88  FIRST-LINE          VALUE HIGH-VALUE.
010400     88  NOTFIRST-LINE       VALUE LOW-VALUE.
010500 77  INSERT-FLAG             PIC X VALUE LOW-VALUE.
010600     88  INSERT-LINE         VALUE HIGH-VALUE.
010700     88  NOINSERT-LINE       VALUE LOW-VALUE.
010800     SKIP2
010900* The following is a key constructed from data in the input and
011000* a lookup table. It will be used as the index values for ACIF,
011100* and illustrates a method of creating indexer information when
011200* the file does not contain the desired data in fixed positions
011300* as required by ACIF. The index key is placed after the last
011400* print field as defined by the PAGEDEF, so it does not appear
011500* on the page nor in the AFPDS output.
011600 01  INDEX-FIELD.
011700     05  INDEX-REPTNUM       PIC XXX.
011800     05  INDEX-REPTDATE      PIC X(8).
011900     05  INDEX-DEPT          PIC 9(4).
012000     SKIP2
012100* This is the data portion of the IPS record. It specifies
012200* the name of page segment and the position of the segment
012300* on the page. Here we use values indicating the current
012400* print position.
012500 01  PSEG-DATA.
012600     05  PSEG-NAME           PIC X(8) VALUE 'S1ISLOGO'.
012700     05  PSEG-X-OFFSET       PIC XXX VALUE HIGH-VALUE.
012800     05  PSEG-Y-OFFSET.
012900         10  FILLER          PIC X VALUE LOW-VALUE.
013000         10  PSEG-Y-COORD    PIC 9(4) BINARY VALUE 2400.
013100* offset 10 inches down to prevent PEMs.
013200     SKIP2
013300 01  DESTINATION-TABLE.
013400     05  DEST-DEPARTMENT-VALUES.
013500         10 FILLER           PIC XXX  VALUE '000'.
013600         10 FILLER           PIC 9(4) VALUE 0999.
013700         10 FILLER           PIC XXX  VALUE '540'.
013800         10 FILLER           PIC 9(4) VALUE 1000.
013900         10 FILLER           PIC XXX  VALUE '550'.
014000         10 FILLER           PIC 9(4) VALUE 2000.
014100         10 FILLER           PIC XXX  VALUE '560'.
014200         10 FILLER           PIC 9(4) VALUE 3000.
014300         10 FILLER           PIC XXX  VALUE '570'.
014400         10 FILLER           PIC 9(4) VALUE 4000.
014500     05  DEST-DEPARTMENT-TABLE  REDEFINES DEST-DEPARTMENT-VALUES.
014600         10 DEST-TABLE       OCCURS 5
014700                             INDEXED BY DEST-TABLE-INDX.
014800             15 DEST-RPTNUM  PIC XXX.
014900             15 DEST-DEPT    PIC 9(4).
015000         SKIP1
015100/ AFP STRUCTURED FIELD DEFINITIONS.
015200     COPY STRFLDS SUPPRESS.
015300/ PASSED PARAMETERS.
015400 LINKAGE SECTION.
015500 01  INP-PARMS.
015600     05  INP-USTOR           POINTER.
015700     05  INP-PFATTR          POINTER.
015800     05  INP-RECPTR          POINTER.
015900     05  FILLER              POINTER.
016000     05  INP-RECLEN          PIC 9(4) BINARY.
016100     05  FILLER              PIC XX.
016200     05  INP-REQUEST         PIC X.
016300         88  INP-USE         VALUE X'00'.
016400         88  INP-DELETE      VALUE X'01'.
016500         88  INP-INSERT      VALUE X'02'.
016600     05  INP-EOF-FLAG        PIC X.
016700         88  INP-EOF         VALUE 'Y'.
016800
016900 01  INP-UAREA               PIC X(16).
017000
017100 01  INP-ATTR.
017200     05  INP-CC              PIC XXX.
017300     05  INP-CCTYPE          PIC X.
017400         88  INP-ANSI-CC     VALUE 'A'.
017500         88  INP-MACH-CC     VALUE 'M'.
017600     05  INP-CHARS           PIC X(20).
017700     05  INP-FORMDEF         PIC X(8).
017800     05  INP-PAGEDEF         PIC X(8).
017900     05  INP-PRMODE          PIC X(8).
018000     05  INP-TRC             PIC XXX.
018100
018200* This is a template for the input record, pointed to by
018300* INP-RECPTR. The record's actual length is given by
018400* INP-RECLEN.
018500 01  INP-LINE.
018600     05  INP-CCVAL           PIC X.
018700     05  FILLER              PIC X(8191).
018800     SKIP1
018900 TITLE 'Initialization and Main Line'.
019000 PROCEDURE DIVISION USING INP-PARMS.
019100* make work area, attributes, and input line addressable.
019200     SET ADDRESS OF INP-UAREA TO INP-USTOR.
019300     SET ADDRESS OF INP-ATTR TO INP-PFATTR.
019400     SET ADDRESS OF INP-LINE TO INP-RECPTR.
019500* no special action is necessary at EOF.
019600     IF INP-EOF
019700      THEN
019800       DISPLAY PGMNAME, ' EOF REACHED.';
019900       MOVE PAGE-COUNT TO PAGE-DISP;
020000       DISPLAY PGMNAME, PAGE-DISP, ' Pages processed.';
020100       GOBACK;
020200     END-IF.
020300* The print file attributes are used to determine the type
020400* of carriage control to test for for top-of-form.
020500* For purposes of this example, we assume the file will
020600* always have carriage control, and if machine control the
020700* skip to channel 1 immediate is used for new pages.
020800     IF INP-ANSI-CC
020900      THEN
021000       SET ANSI-TOF TO TRUE
021100      ELSE
021200       SET MACH-TOF TO TRUE.
021300* The carriage control character is tested for top-of-form.
021400* This identifies the first line of a page. The line is
021500* scanned for a space large enough for our text insert.
021600* The report number and run date are saved for use in the
021700* indexer key. The page counter is incremented and the
021800* line counter is reset, then the modified line is passed
021900* back to ACIF.
022000* If machine carriage control is used, then the first
022100* print line is the line after the top-of-form. A flag
022200* is set to cause this line to be treated as the top.
022300     IF FIRST-LINE OR (INP-CCVAL = CC-TOF)
022400      THEN
022500       IF ANSI-TOF OR FIRST-LINE
022600        THEN
022700         MOVE INSERT-PHRASE TO
022800              INP-LINE (INSERT-START : LENGTH OF INSERT-PHRASE);
022900         SET NOTFIRST-LINE TO TRUE;
023000         ADD 1 TO PAGE-COUNT;
023100         MOVE 1 TO LINE-COUNT;
023200         MOVE INP-LINE (REPT-START : REPT-LEN) TO INDEX-REPTNUM;
023300         MOVE INP-LINE (DATE-START : DATE-LEN) TO INDEX-REPTDATE;
023400        ELSE
023500         SET FIRST-LINE TO TRUE;
023600       END-IF;
023700      ELSE
023800       ADD 1 TO LINE-COUNT;
023900     END-IF.
024000     SKIP1
024100* If this is the last heading line and this is a summary page
024200* then the page segment is inserted. Note that the insert flag
024300* in the ACIF parameter block is turned on when the last heading
024400* line is seen. The heading line is sent back to ACIF. ACIF will
024500* return the same record buffer, in which the inserted line is
024600* placed. ACIF always resets the request flag (INP-REQUEST)
024700* to USE.
024800     IF LINE-COUNT = LAST-HEADING
024900      THEN
025000       IF NOT INSERT-LINE
025100        THEN
025200         IF INP-LINE (SUMM-START : LENGTH OF SUMM-LIT) = SUMM-LIT
025300          THEN
025400           SET INSERT-LINE TO TRUE;
025500           SET INP-INSERT TO TRUE;
025600           SUBTRACT 1 FROM LINE-COUNT;
025700          END-IF;
025800          SET DEST-TABLE-INDX TO 1;
025900          SEARCH DEST-TABLE
026000           AT END
026100            MOVE DEST-DEPT (1) TO INDEX-DEPT;
026200           WHEN DEST-RPTNUM (DEST-TABLE-INDX) = INDEX-REPTNUM
026300            MOVE DEST-DEPT (DEST-TABLE-INDX) TO INDEX-DEPT;
026400          END-SEARCH;
026500          MOVE INDEX-FIELD TO INP-LINE (INDX-START :
026600                                        LENGTH OF INDEX-FIELD);
026700        ELSE
026800         CALL AFPWRITE USING SF-IPS,
026900                             PSEG-DATA,
027000                             BY CONTENT LENGTH OF PSEG-DATA,
027100                             BY REFERENCE INP-RECLEN,
027200                             INP-RECPTR;
027300         SET NOINSERT-LINE TO TRUE;
027400       END-IF;
027500     END-IF.
027600     IF LINE-COUNT > LAST-HEADING
027700      THEN
027800       IF INP-LINE (DELT-START : LENGTH OF DELT-LIT) = DELT-LIT
027900        THEN
028000         SET INP-DELETE TO TRUE;
028100       END-IF;
028200     END-IF.
028300     SKIP1
028400     GOBACK.
028500 TITLE 'FORMAT AFPDS RECORD'.
028600 ID DIVISION.
028700* This routine takes the structured field type, data, and data
028800* length and formats an AFP record and places it in the
028900* exit's buffer.
029000 PROGRAM-ID. AFPWRITE COMMON.
029100 DATA DIVISION.
029200 WORKING-STORAGE SECTION.
029300 77  SF-CC                       PIC X VALUE X'5A'.
029400 LINKAGE SECTION.
029500 01  AFP-TYPE                    PIC X(3).
029600 01  AFP-DATA                    PIC X(8192).
029700 01  AFP-DATA-LENGTH             PIC 9(9) BINARY.
029800 01  AFP-INSERT-LEN              PIC 9(4) BINARY.
029900 01  AFP-RECPTR                  POINTER.
030000     SKIP1
030100 01  SF-RECORD.
030200     05  SF-INTRODUCER.
030300         10 SF-INTRO-CC      PIC X.
030400         10 SF-INTRO-LEN     PIC 9(4) BINARY.
030500         10 SF-INTRO-TYPE    PIC X(3).
030600         10 SF-INTRO-FLAG    PIC X.
030700         10 SF-INTRO-SEQNUM  PIC 9(4) BINARY.
030800     05  SF-DATA             PIC X(8192).
030900 SKIP3
031000 PROCEDURE DIVISION USING AFP-TYPE,
031100                          AFP-DATA,
031200                          AFP-DATA-LENGTH,
031300                          AFP-INSERT-LEN,
031400                          AFP-RECPTR.
031500* set the final record length (introducer plus data), which is
031600* found in the introducer length field, move in the introducer
031700* and the data, then write the record.
031800     SET ADDRESS OF SF-RECORD TO AFP-RECPTR.
031900     ADD LENGTH OF SF-INTRODUCER, AFP-DATA-LENGTH GIVING
032000         AFP-INSERT-LEN.
032100     SUBTRACT 1 FROM AFP-INSERT-LEN GIVING SF-INTRO-LEN.
032200     MOVE SF-CC TO     SF-INTRO-CC.
032300     MOVE AFP-TYPE TO SF-INTRO-TYPE.
032400     MOVE LOW-VALUE TO SF-INTRO-FLAG.
032500     MOVE ZERO TO      SF-INTRO-SEQNUM.
032600     MOVE AFP-DATA (1 : AFP-DATA-LENGTH) TO SF-DATA.
032700     EXIT PROGRAM.
032800 END PROGRAM AFPWRITE.
032900 SKIP1
033000 END PROGRAM APKINPXT.
