000100 PROCESS NUMPROC(PFD) TRUNC(OPT) APOST NOSEQ LIST
000200* LAST UPDATE ON 9 Apr 2018 AT 15:43:22 BY  HOWARDT VERSION 01   *
000300 ID DIVISION.
000400 PROGRAM-ID. APKOUTXT.
000500 AUTHOR. TURETZKY--HYDRA.
000600 INSTALLATION. IBM BOULDER PROGRAMMING CENTER.
000700
000800               This program is a sample exit for ACIF
000900               (APKACIF,5648-062) demonstrating the use of the
001000               ACIF output exit.
001100
001200               In order to use this exit, include the control
001300               OUTEXIT=APKOUTXT to enable this exit, and include
001400               the load module in a dataset referenced in STEPLIB
001500               or elsewhere in the module search order.
001600
001700               The program will delete the Begin Document and End
001800               Document structured fields (BDT/EDT), and will
001900               insert a comment triplet on each Begin Page (BPG)
002000               structured field (I didn't say it would do anything
002100               useful).  It will also renumber each structured
002200               field sequence field within a page. If the BPG
002300               record does not contain a Page Name triplet (FQN
002400               type x'01'), one will be inserted with a sequential
002500               page number.
002600
002700               Method of operation: each output record is examined
002800               for a BPG, BDT, or EDT structured field. If it is
002900               a BDT/EDT, the delete code (x'01') will be returned
003000               to ACIF. If it is a BPG, it will be scanned for an
003100               X'02' FQN triplet of type X'01'. If none is found,
003200               one will be inserted with the running page count.
003300
003400               This program must either be compiled with the
003500               NORENT option or linked with IGZOPT with the
003600               RTEREUS option.  (See VS COBOL II Application
003700               Programming Guide, SC26-4045).
003800
003900 DATE-WRITTEN. 18 OCT 93.
004000 DATE-COMPILED.
004100 SECURITY. IBM SAMPLE CODE ONLY.
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
006300 TITLE 'ACIF Sample output Exit'.
006400 ENVIRONMENT DIVISION.
006500 CONFIGURATION SECTION.
006600 SOURCE-COMPUTER. IBM-370.
006700 OBJECT-COMPUTER. IBM-370.
006800     EJECT
006900 DATA DIVISION.
007000 WORKING-STORAGE SECTION.
007100 77  PGMNAME                 PIC X(8) VALUE 'APKOUTXT'.
007230 77  ABND-PGM                PIC X(8) VALUE 'CEE3DMP'.            !@01
007300 77  ABEND-CODE              PIC 9(4) BINARY VALUE 12.
007310 77  ABEND-OPTS              PIC X(255)                           !@01
007320     VALUE 'ENC(CUR) THR(CUR) FILE VAR NOBLOCK NOSTOR SF(ALL)' .  !@01
007400 77  LINE-COUNT              PIC S9(8) BINARY VALUE ZERO.
007500 77  PAGE-COUNT              PIC S9(8) BINARY VALUE ZERO.
007600 77  INSERT-PHRASE           PIC X(13) VALUE 'MODIFIED BY:'.
007700 77  FQN-FOUND-FLAG          PIC X.
007800     88  FQN-FOUND           VALUE HIGH-VALUE.
007900     88  FQN-NOTFOUND        VALUE  LOW-VALUE.
008000     SKIP2
008100 01  DATE-DATA.
008200   05  RUN-DATE.
008300     10 RUN-YY                 PIC 99.
008400     10 RUN-MM                 PIC 99.
008500     10 RUN-DD                 PIC 99.
008600   05  COMPILE-DATE.
008700     10  COMP-DATE             PIC X(8).
008800     10  COMP-TIME             PIC X(12).
008900   05  RUN-TIME.
009000     10  RUN-HH                PIC 99.
009100     10  RUN-MM                PIC 99.
009200     10  RUN-SS                PIC 99.
009300     10  RUN-MS                PIC 99.
009400     SKIP2
009500 01  BINARY-NUMBERS.
009600     05  BIN-4                   PIC 9(8) BINARY VALUE ZERO.
009700     05  BIN4-X                  REDEFINES BIN-4
009800                                 PIC X(4).
009900     05  BIN2                    PIC 9(4) BINARY VALUE ZERO.
010000     05  BIN2-X                  REDEFINES BIN2.
010100         10  FILLER              PIC X.
010200         10  BIN2-2              PIC X.
010300     SKIP2
010400 01  FQN-TRIPLET.
010500     05  FQN-LEN             PIC X.
010600     05  FQN-IDENT           PIC X.
010700     05  FQN-TYPE            PIC X.
010800     05  FQN-PAGENUM         PIC ZZ,ZZZ,ZZ9.
010900     SKIP2
011000 01  COMMENT-TRIPLET.
011100     05  COMMENT-LEN         PIC X.
011200     05  COMMENT-TYPE        PIC X.
011300     05  COMMENT-DATA        PIC X(250).
011400     SKIP2
011500 01  TRIPLET-DATA.
011600     05  TRIPLET-PTR             PIC 9(8) BINARY.
011700     05  TRIPLET-LENGTH          PIC 9(4) BINARY.
011800* offset to start of attribute value
011900     05  ATTVAL-OFFSET           PIC 9(8) BINARY VALUE 4.
012000     SKIP2
012100         EJECT
012200/ AFP STRUCTURED FIELD DEFINITIONS.
012300     COPY STRFLDS SUPPRESS.
012400/ PASSED PARAMETERS.
012500 LINKAGE SECTION.
012600 01  OUT-PARMS.
012700     05  OUT-WORKA           POINTER.
012800     05  OUT-PFATTR          POINTER.
012900     05  OUT-RECPTR          POINTER.
013000     05  OUT-RECLEN          PIC 9(4) BINARY.
013100     05  OUT-REQUEST         PIC X.
013200         88  OUT-USE         VALUE X'00'.
013300         88  OUT-DELETE      VALUE X'01'.
013400     05  OUT-EOF-FLAG        PIC X.
013500         88  OUT-EOF         VALUE 'Y'.
013600         88  OUT-NOTEOF      VALUE 'N'.
013700
013800 01  OUT-UAREA.
013900     05  OUT-FIRST-FLAG      PIC X.
014000         88  OUT-FIRST       VALUE LOW-VALUE.
014100         88  OUT-NOTFIRST    VALUE HIGH-VALUE.
014200
014300 01  OUT-ATTR.
014400     05  OUT-CC              PIC XXX.
014500     05  OUT-CCTYPE          PIC X.
014600         88  OUT-ANSI-CC     VALUE 'A'.
014700         88  OUT-MACH-CC     VALUE 'M'.
014800     05  OUT-CHARS           PIC X(20).
014900     05  OUT-FORMDEF         PIC X(8).
015000     05  OUT-PAGEDEF         PIC X(8).
015100     05  OUT-PRMODE          PIC X(8).
015200     05  OUT-TRC             PIC XXX.
015300
015400* This is a template for the output record, pointed to by
015500* OUT-RECPTR. The record's actual length is given by
015600* OUT-RECLEN.
015700 01  OUT-LINE.
015800     05  OUT-CCVAL           PIC X.
015900     05  OUT-SFINTRO.
016000         10  OUT-SFLEN       PIC 9(4) BINARY.
016100         10  OUT-SFTYPE      PIC XXX.
016200         10  OUT-SFFLAG      PIC X.
016300         10  OUT-SFSEQ       PIC 9(4) BINARY.
016400     05  OUT-SFDATA          PIC X(32751).
016500 TITLE 'Initialization and Main Line'.
016600 PROCEDURE DIVISION USING OUT-PARMS.
016700* make work area, attributes, and output line addressable.
016800     SET ADDRESS OF OUT-UAREA TO OUT-WORKA.
016900     SET ADDRESS OF OUT-ATTR TO OUT-PFATTR.
017000     SET ADDRESS OF OUT-LINE TO OUT-RECPTR.
017100* no special action is necessary at EOF.
017200     IF OUT-EOF
017300      THEN
017400       DISPLAY PGMNAME, ' EOF REACHED.';
017500       GOBACK;
017600     END-IF.
017700     IF OUT-FIRST
017800      THEN
017900       SET OUT-NOTFIRST TO TRUE;
018000       MOVE WHEN-COMPILED TO COMPILE-DATE;
018100       ACCEPT RUN-DATE FROM DATE;
018200       ACCEPT RUN-TIME FROM TIME;
018300     END-IF.
018400     SET OUT-USE TO TRUE.
018500     EVALUATE OUT-SFTYPE;
018600      WHEN SF-BDT
018700       SET OUT-DELETE TO TRUE;
018800      WHEN SF-EDT
018900       SET OUT-DELETE TO TRUE;
019000      WHEN SF-BPG
019100       ADD 1 TO PAGE-COUNT;
019200       MOVE 0 TO LINE-COUNT;
019300       PERFORM 0200-FIX-BPG;
019400      WHEN OTHER
019500       ADD 1 TO LINE-COUNT;
019600       MOVE LINE-COUNT TO OUT-SFSEQ;
019700     END-EVALUATE.
019800     SKIP1
019900     GOBACK.
020000        SKIP2
020100     EJECT
020200 0200-FIX-BPG.
020300* First, scan the BPG for an FQN GID triplet. If one is not found,
020400* insert one containing the formatted page count.
020500* Then, locate the end of the record and insert a comment triplet
020600* indicating we modified the document with a time/date stamp.
020700* Triplets begin after the token name.
020800     MOVE 9 TO TRIPLET-PTR.
020900     SET FQN-NOTFOUND TO TRUE;
021000     PERFORM UNTIL TRIPLET-PTR >=
021100                   (OUT-SFLEN - LENGTH OF OUT-SFINTRO);
021200* the triplet length is the first byte of the triplet
021300       MOVE OUT-SFDATA (TRIPLET-PTR : 1) TO BIN2-2;
021400       MOVE BIN2 TO TRIPLET-LENGTH;
021500* the triplet type is the second byte of the triplet
021600       EVALUATE (OUT-SFDATA (TRIPLET-PTR + 1 : 1));
021700        WHEN TR-FQN (2 : 1)
021800* the FQN type is the third byte of an FQN triplet
021900         EVALUATE (OUT-SFDATA (TRIPLET-PTR + 2 : 1));
022000          WHEN FQN-GID
022100           SET FQN-FOUND TO TRUE;
022200          WHEN OTHER
022300           CONTINUE;
022400         END-EVALUATE;
022500         WHEN OTHER
022600          CONTINUE;
022700       END-EVALUATE;
022800       ADD TRIPLET-LENGTH TO TRIPLET-PTR;
022900     END-PERFORM.
023000     IF FQN-NOTFOUND
023100      THEN
023200       PERFORM 0300-CREATE-FQN;
023300     END-IF.
023400     PERFORM 0400-CREATE-COMMENT.
023500     SKIP2
023600 0300-CREATE-FQN.
023700     MOVE TR-FQN TO FQN-IDENT.
023800     MOVE FQN-GID TO FQN-TYPE.
023900     MOVE PAGE-COUNT TO FQN-PAGENUM.
024000     MOVE LENGTH OF FQN-TRIPLET TO BIN2.
024100     MOVE BIN2-2 TO FQN-LEN.
024200     MOVE FQN-TRIPLET TO OUT-SFDATA (OUT-RECLEN + 1 :
024300                                     LENGTH OF FQN-TRIPLET).
024400     ADD LENGTH OF FQN-TRIPLET TO OUT-RECLEN,
024500                                  OUT-SFLEN.
024600     SKIP2
024700 0400-CREATE-COMMENT.
024800     MOVE TR-UCOMMENT (2:1) TO COMMENT-TYPE.
024900     MOVE INSERT-PHRASE TO COMMENT-DATA.
025000     ADD LENGTH OF INSERT-PHRASE, 1 GIVING BIN2.
025100     MOVE PGMNAME TO COMMENT-DATA (BIN2 : LENGTH OF PGMNAME).
025200     ADD LENGTH OF PGMNAME, 1 TO BIN2.
025300     MOVE RUN-DATE TO COMMENT-DATA (BIN2 : LENGTH OF RUN-DATE).
025400     ADD LENGTH OF RUN-DATE, 1 TO BIN2.
025500     MOVE RUN-TIME TO COMMENT-DATA (BIN2 : LENGTH OF RUN-TIME).
025600     ADD LENGTH OF RUN-TIME TO BIN2.
025700     ADD LENGTH OF COMMENT-LEN, LENGTH OF COMMENT-TYPE TO BIN2.
025800     MOVE BIN2-2 TO COMMENT-LEN.
025900     MOVE COMMENT-TRIPLET TO OUT-SFDATA
026000                  (OUT-SFLEN - LENGTH OF OUT-SFINTRO + 1 : BIN2).
026100
026200     ADD BIN2 TO OUT-RECLEN,
026300                 OUT-SFLEN.