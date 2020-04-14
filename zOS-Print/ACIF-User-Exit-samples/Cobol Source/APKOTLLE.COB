000100 PROCESS NUMPROC(PFD) TRUNC(OPT) APOST NOSEQ NOLIST
000200* LAST UPDATE ON 9 Apr 2018 AT 15:41:28 BY  HOWARDT VERSION 01   *
000300 ID DIVISION.
000400 PROGRAM-ID. APKOTLLE.
000500 AUTHOR. TURETZKY--HYDRA.
000600 INSTALLATION. IBM BOULDER PROGRAMMING CENTER.
000700
000800               This program is a sample exit for ACIF
000900               (APKACIF,5648-062) demonstrating the use of the
001000               ACIF output exit.
001100
001200               In order to use this exit, include the control
001300               OUTEXIT=APKOTLLE to enable this exit, and include
001400               the load module in a dataset referenced in STEPLIB
001500               or elsewhere in the module search order.
001600
001700               This program must be used with APKINLLE. It changes
001800               NOP records whose flag and sequence number fields
001900               contain the LLE structured field ID back into LLEs,
002000               since ACIF can't yet process LLEs. The sequence
002100               number is replaced with the record count within
002200               page, and the flag is zeroed.  The exit also
002300               changes the page name FQN on the Begin Page record
002400               to be identical to the BPG token, including
002500               trailing blanks.
002600
002700               Method of operation: each output record is examined
002800               for a BPG or NOP. The BPG resets the record
002900               counter.  NOPs are examined for the LLE id in the
003000               flag/sequence number field.  If found, the NOP id
003100               is changed back to LLE, the flag cleared, and the
003200               sequence replaced by the current record count.
003300
003400               This program must either be compiled with the
003500               NORENT option or linked with IGZOPT with the
003600               RTEREUS option.  (See VS COBOL II Application
003700               Programming Guide, SC26-4045).
003800
003900 DATE-WRITTEN. 14 Jul 94.
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
006300 TITLE 'ACIF Output Exit--Restore LLE'.
006400 ENVIRONMENT DIVISION.
006500 CONFIGURATION SECTION.
006600 SOURCE-COMPUTER. IBM-370.
006700 OBJECT-COMPUTER. IBM-370.
006800     EJECT
006900 DATA DIVISION.
007000 WORKING-STORAGE SECTION.
007100 77  PGMNAME                 PIC X(8) VALUE 'APKOTLLE'.
007211 77  ABND-PGM                PIC X(8) VALUE 'CEE3DMP'.            !@01
007300 77  ABEND-CODE              PIC 9(4) BINARY VALUE 12.
007310 77  ABEND-OPTS              PIC X(255)                           !@01
007320     VALUE 'ENC(CUR) THR(CUR) FILE VAR NOBLOCK NOSTOR SF(ALL)' .  !@01
007400 77  LINE-COUNT              PIC S9(8) BINARY VALUE ZERO.
007500 77  PAGE-COUNT              PIC S9(8) BINARY VALUE ZERO.
007600 77  PAGE-DISP               PIC Z,ZZZ,ZZ9.
007700 77  TRIPLET-PTR             PIC S9(4) BINARY VALUE ZERO.
007800 77  TRIPLET-LENGTH          PIC S9(4) BINARY VALUE ZERO.
007900 77  FQN-PTR                 PIC S9(4) BINARY VALUE ZERO.
008000 77  FQN-LENGTH              PIC S9(4) BINARY VALUE ZERO.
008100 77  FQN-FOUND-FLAG          PIC X.
008200     88  FQN-FOUND           VALUE HIGH-VALUE.
008300     88  FQN-NOTFOUND        VALUE  LOW-VALUE.
008400     SKIP2
008500 01  FQN-TRIPLET.
008600     05  FQN-LEN             PIC X.
008700     05  FQN-IDENT           PIC X.
008800     05  FQN-TYPE            PIC X.
008900     05  FQN-PAGENAME        PIC X(8).
009000     SKIP2
009100 01  BINARY-NUMBERS.
009200     05  BIN-4                   PIC 9(8) BINARY VALUE ZERO.
009300     05  BIN4-X                  REDEFINES BIN-4
009400                                 PIC X(4).
009500     05  BIN2                    PIC 9(4) BINARY VALUE ZERO.
009600     05  BIN2-X                  REDEFINES BIN2.
009700         10  FILLER              PIC X.
009800         10  BIN2-2              PIC X.
009900         EJECT
010000/ AFP STRUCTURED FIELD DEFINITIONS.
010100     COPY STRFLDS SUPPRESS.
010200/ PASSED PARAMETERS.
010300 LINKAGE SECTION.
010400 01  OUT-PARMS.
010500     05  OUT-WORKA           POINTER.
010600     05  OUT-PFATTR          POINTER.
010700     05  OUT-RECPTR          POINTER.
010800     05  OUT-RECLEN          PIC 9(4) BINARY.
010900     05  OUT-REQUEST         PIC X.
011000         88  OUT-USE         VALUE X'00'.
011100         88  OUT-DELETE      VALUE X'01'.
011200     05  OUT-EOF-FLAG        PIC X.
011300         88  OUT-EOF         VALUE 'Y'.
011400         88  OUT-NOTEOF      VALUE 'N'.
011500
011600 01  OUT-UAREA.
011700     05  OUT-FIRST-FLAG      PIC X.
011800         88  OUT-FIRST       VALUE LOW-VALUE.
011900         88  OUT-NOTFIRST    VALUE HIGH-VALUE.
012000
012100 01  OUT-ATTR.
012200     05  OUT-CC              PIC XXX.
012300     05  OUT-CCTYPE          PIC X.
012400         88  OUT-ANSI-CC     VALUE 'A'.
012500         88  OUT-MACH-CC     VALUE 'M'.
012600     05  OUT-CHARS           PIC X(20).
012700     05  OUT-FORMDEF         PIC X(8).
012800     05  OUT-PAGEDEF         PIC X(8).
012900     05  OUT-PRMODE          PIC X(8).
013000     05  OUT-TRC             PIC XXX.
013100
013200* This is a template for the output record, pointed to by
013300* OUT-RECPTR. The record's actual length is given by
013400* OUT-RECLEN.
013500 01  OUT-LINE.
013600     05  OUT-CCVAL           PIC X.
013700     05  OUT-SFINTRO.
013800         10  OUT-SFLEN       PIC 9(4) BINARY.
013900         10  OUT-SFTYPE      PIC XXX.
014000         10  OUT-SFFLAGSEQ.
014100             15 OUT-SFFLAG   PIC X.
014200             15 OUT-SFSEQ    PIC 9(4) BINARY.
014300     05  OUT-SFDATA          PIC X(32747).
014400 TITLE 'Initialization and Main Line'.
014500 PROCEDURE DIVISION USING OUT-PARMS.
014600* make work area, attributes, and output line addressable.
014700     SET ADDRESS OF OUT-UAREA TO OUT-WORKA.
014800     SET ADDRESS OF OUT-ATTR TO OUT-PFATTR.
014900     SET ADDRESS OF OUT-LINE TO OUT-RECPTR.
015000* no special action is necessary at EOF.
015100     IF OUT-EOF
015200      THEN
015300       DISPLAY PGMNAME, ' EOF REACHED.';
015400       MOVE PAGE-COUNT TO PAGE-DISP;
015500       DISPLAY PGMNAME, PAGE-DISP, ' PAGES PROCESSED.';
015600       GOBACK;
015700     END-IF.
015800     SET OUT-USE TO TRUE.
015900     EVALUATE OUT-SFTYPE;
016000      WHEN SF-NOP
016100       IF OUT-SFFLAGSEQ = SF-LLE
016200        THEN
016300         MOVE SF-LLE TO OUT-SFTYPE;
016400         MOVE LOW-VALUE TO OUT-SFFLAG;
016500         ADD 1 TO LINE-COUNT;
016600         MOVE LINE-COUNT TO OUT-SFSEQ;
016700        ELSE
016800         ADD 1 TO LINE-COUNT;
016900       END-IF;
017000      WHEN SF-BPG
017100       ADD 1 TO PAGE-COUNT;
017200       MOVE 0 TO LINE-COUNT;
017300       PERFORM 0200-FIX-BPG;
017400      WHEN OTHER
017500       ADD 1 TO LINE-COUNT;
017600     END-EVALUATE.
017700     SKIP1
017800     GOBACK.
017900 0200-FIX-BPG.
018000* FIRST, SCAN THE BPG FOR AN FQN GID TRIPLET. IF ONE IS NOT FOUND,
018100* INSERT ONE CONTAINING THE TOKEN NAME.
018200* TRIPLETS BEGIN AFTER THE TOKEN NAME.
018300     MOVE 9 TO TRIPLET-PTR.
018400     SET FQN-NOTFOUND TO TRUE;
018500     PERFORM UNTIL TRIPLET-PTR >=
018600                   (OUT-SFLEN - LENGTH OF OUT-SFINTRO);
018700* THE TRIPLET LENGTH IS THE FIRST BYTE OF THE TRIPLET
018800       MOVE OUT-SFDATA (TRIPLET-PTR : 1) TO BIN2-2;
018900       MOVE BIN2 TO TRIPLET-LENGTH;
019000* THE TRIPLET TYPE IS THE SECOND BYTE OF THE TRIPLET
019100       EVALUATE (OUT-SFDATA (TRIPLET-PTR + 1 : 1));
019200        WHEN TR-FQN (2 : 1)
019300* THE FQN TYPE IS THE THIRD BYTE OF AN FQN TRIPLET.
019400* THE POSITION AND LENGTH OF THE FQN IS SAVED SO IT CAN BE
019500* DELETED AND REPLACED.
019600         EVALUATE (OUT-SFDATA (TRIPLET-PTR + 2 : 1));
019700          WHEN FQN-GID
019800           SET FQN-FOUND TO TRUE;
019900           MOVE TRIPLET-LENGTH TO FQN-LENGTH;
020000           MOVE TRIPLET-PTR TO FQN-PTR;
020100          WHEN OTHER
020200           CONTINUE;
020300         END-EVALUATE;
020400         WHEN OTHER
020500          CONTINUE;
020600       END-EVALUATE;
020700       ADD TRIPLET-LENGTH TO TRIPLET-PTR;
020800     END-PERFORM.
020900     IF FQN-NOTFOUND
021000      THEN
021100       PERFORM 0300-CREATE-FQN;
021200      ELSE
021300       PERFORM 0310-DELETE-FQN;
021400       PERFORM 0300-CREATE-FQN;
021500     END-IF.
021600     SKIP2
021700 0300-CREATE-FQN.
021800     MOVE TR-FQN(2 : 1) TO FQN-IDENT.
021900     MOVE FQN-GID TO FQN-TYPE.
022000     MOVE OUT-SFDATA (1 : 8) TO FQN-PAGENAME.
022100     MOVE LENGTH OF FQN-TRIPLET TO BIN2.
022200     MOVE BIN2-2 TO FQN-LEN.
022300     MOVE FQN-TRIPLET TO OUT-SFDATA (TRIPLET-PTR  :
022400                                     LENGTH OF FQN-TRIPLET).
022500     ADD LENGTH OF FQN-TRIPLET TO OUT-RECLEN,
022600                                  OUT-SFLEN.
022700     SKIP2
022800 0310-DELETE-FQN.
022900* REMOVE THE FQN AND MOVE UP ANY FOLLOWING TRIPLETS SO THE NEW
023000* FQN CAN BE ADDED TO THE END OF THE RECORD. THE STRUCTURED FIELD
023100* LENGTH IS ADJUSTED ACCORDINGLY.
023200     IF FQN-LENGTH + FQN-PTR >= OUT-SFLEN
023300      THEN
023400* IT'S THE LAST TRIPLET IN THE RECORD
023500       SUBTRACT FQN-LENGTH FROM OUT-SFLEN;
023600       SUBTRACT FQN-LENGTH FROM OUT-RECLEN;
023700       SUBTRACT FQN-LENGTH FROM TRIPLET-PTR;
023800      ELSE
023900* COPY THE FOLLOWING TRIPLETS BACK TO WHERE THE FQN WAS
024000       MOVE OUT-SFDATA(FQN-PTR + FQN-LENGTH - 1 :
024100                       TRIPLET-PTR - 1 - FQN-LENGTH) TO
024200            OUT-SFDATA(FQN-PTR : TRIPLET-PTR - 1 - FQN-LENGTH);
024300       SUBTRACT FQN-LENGTH FROM OUT-SFLEN;
024400       SUBTRACT FQN-LENGTH FROM OUT-RECLEN;
024500       SUBTRACT FQN-LENGTH FROM TRIPLET-PTR;
024600     END-IF.