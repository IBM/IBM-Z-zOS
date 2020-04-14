000100 PROCESS NUMPROC(PFD) TRUNC(OPT) APOST NOSEQ NOLIST
000200* LAST UPDATE ON 9 Apr 2018 AT 15:39:32 BY  HOWARDT VERSION 01   *
000300* LAST UPDATE ON 16 Nov 2017            BY  Howardt VERSION 02   *
000400 ID DIVISION.
000500 PROGRAM-ID. APKINPTS.
000600 AUTHOR. TURETZKY--HYDRA.
000700 INSTALLATION. IBM BOULDER PROGRAMMING CENTER.
000800               This program is a sample exit for ACIF
000900               (APKACIF,5648-062) demonstrating the use of the
001000               ACIF input exit.
001100
001200               In order to use this exit, include the control
001300               INPEXIT=APKINPTS to enable this exit, and include
001400               the load module in a dataset referenced in STEPLIB
001500               or elsewhere in the module search order.
001600
001700               The program is used to test the input exit. It will
001800               pass back each input record unchanged, then insert
001900               a record after each input record. It will also
002000               insert a record after EOF.
002100
002200               Method of operation: for each input record, the
002300               request flag is set to INSERT (x'02'), the existing
002400               record is sent back unchanged, then when control is
002500               returned a new record created and the flag set to
002600               process (x'00').
002700
002800 DATE-WRITTEN. 23 SEP 93.
002900 DATE-COMPILED.
003000 SECURITY. IBM SAMPLE CODE ONLY.
003100*/**************************************************************/
003120*/* Licensed under the Apache License, Version 2.0 (the        */
003130*/* "License"); you may not use this file except in compliance */
003140*/* with the License. You may obtain a copy of the License at  */
003150*/*                                                            */
003160*/* http://www.apache.org/licenses/LICENSE-2.0                 */
003170*/*                                                            */
003180*/* Unless required by applicable law or agreed to in writing, */
003190*/* software distributed under the License is distributed on an*/
003191*/* "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY     */
003192*/* KIND, either express or implied.  See the License for the  */
003193*/* specific language governing permissions and limitations    */
003194*/* under the License.                                         */
003195*/*------------------------------------------------------------*/
003196*/*                                                            */
003200*/*   COPYRIGHT (C) 1993,2007 IBM CORPORATION                  */
003300*/*   COPYRIGHT (C) 2007,2018 RICOH COMPANY, LTD               */
003400*/*                                                            */
003500*/*   Permission to use, copy, modify, and distribute          */
003600*/*   this software for any purpose with or without fee        */
003700*/*   is hereby granted, provided that the above               */
003800*/*   copyright notices appear in all copies.                  */
003900*/*                                                            */
004000*/*   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY       */
004100*/*   OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT       */
004200*/*   LIMITED TO THE WARRANTIES OF MERCHANTABILITY,            */
004300*/*   FITNESS FOR A PARTICULAR PURPOSE AND                     */
004400*/*   NONINFRINGEMENT.  IN NO EVENT SHALL RICOH, RICOH         */
004500*/*   SUBSIDIARIES, ANY OF ITS SUPPLIERS OR ANY OF THE         */
004600*/*   OTHER COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,         */
004700*/*   DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF      */
004800*/*   CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF        */
004900*/*   OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR         */
005000*/*   OTHER DEALINGS IN THE SOFTWARE.                          */
005100*/**************************************************************/
005200 TITLE 'ACIF Test Input Exit'.
005300 ENVIRONMENT DIVISION.
005400 CONFIGURATION SECTION.
005500 SOURCE-COMPUTER. IBM-370.
005600 OBJECT-COMPUTER. IBM-370.
005700     EJECT
005800 DATA DIVISION.
005900 WORKING-STORAGE SECTION.
006000 77  PGMNAME                 PIC X(8) VALUE 'APKINPTS'.
006100 77  ABND-PGM                PIC X(8) VALUE 'CEE3DMP'.            !@01
006200 77  ABEND-CODE              PIC 9(4) BINARY VALUE 12.
006300 77  ABEND-OPTS              PIC X(255)                           !@01
006400     VALUE 'ENC(CUR) THR(CUR) FILE VAR NOBLOCK NOSTOR SF(ALL)' .  !@01
006500 77  AFPWRITE                PIC X(8) VALUE 'AFPWRITE'.
006600 77  PAGE-COUNT              PIC 9(8) BINARY VALUE ZERO.
006700 77  LINE-COUNT              PIC 9(8) BINARY VALUE ZERO.
006800 77  EOF-LIT                 PIC X(9) VALUE 'AFTER EOF'.
006900 77  CC-TOF                  PIC X.
007000     88  ANSI-TOF            VALUE '1'.
007100     88  MACH-TOF            VALUE X'8B'.
007200 77  FIRST-LINE-FLAG         PIC X VALUE LOW-VALUE.
007300     88  FIRST-LINE          VALUE HIGH-VALUE.
007400     88  NOTFIRST-LINE       VALUE LOW-VALUE.
007500     SKIP2
007600 01  NEW-LINE.
007700     05  NEW-CC              PIC X.
007800     05  FILLER              PIC X(17) VALUE '>>>INSERTED LINE '.
007900     05  NEW-COUNT           PIC ZZZ,ZZ9.
008000     05  FILLER              PIC X(03) VALUE '<<<'.
008100     05  NEW-EOF             PIC X(9) VALUE SPACES.
008200/ PASSED PARAMETERS.
008300 LINKAGE SECTION.
008400 01  INP-PARMS.
008500     05  INP-USTOR           POINTER.
008600     05  INP-PFATTR          POINTER.
008700     05  INP-RECPTR          POINTER.
008800     05  FILLER              POINTER.
008900     05  INP-RECLEN          PIC 9(4) BINARY.
009000     05  FILLER              PIC XX.
009100     05  INP-REQUEST         PIC X.
009200         88  INP-USE         VALUE X'00'.
009300         88  INP-DELETE      VALUE X'01'.
009400         88  INP-INSERT      VALUE X'02'.
009500     05  INP-EOF-FLAG        PIC X.
009600         88  INP-EOF         VALUE 'Y'.
009700
009800 01  INP-UAREA.
009900     05  UAREA-CNTR          PIC 9(4) BINARY.
010000     05  UAREA-INSCOUNT      PIC 9(4) BINARY.
010100     05  INSERT-FLAG         PIC X.
010200         88 INSERT-LINE      VALUE HIGH-VALUE.
010300         88 INSERT-MULTIPLE  VALUE 'M'.
010400         88 NOINSERT-LINE    VALUE LOW-VALUE.
010500     05  FILLER              PIC X(12).
010600
010700 01  INP-ATTR.
010800     05  INP-CC              PIC XXX.
010900     05  INP-CCTYPE          PIC X.
011000         88  INP-ANSI-CC     VALUE 'A'.
011100         88  INP-MACH-CC     VALUE 'M'.
011200     05  INP-CHARS           PIC X(20).
011300     05  INP-FORMDEF         PIC X(8).
011400     05  INP-PAGEDEF         PIC X(8).
011500     05  INP-PRMODE          PIC X(8).
011600     05  INP-TRC             PIC XXX.
011700
011800* This is a template for the input record, pointed to by
011900* INP-RECPTR. The record's actual length is given by
012000* INP-RECLEN.
012100 01  INP-LINE.
012200     05  INP-CCVAL           PIC X.
012300     05  INP-TRCVAL          PIC X.
012400     05  INP-PAGELIT         PIC X(4).
012500     05  FILLER              PIC X.
012600     05  INP-PAGENUM         PIC 9(4).
012700     05  FILLER              PIC X.
012800     05  INP-LINELIT         PIC X(4).
012900     05  FILLER              PIC X.
013000     05  INP-LINENUM         PIC 9(3).
013100     05  FILLER              PIC X(8191).
013200     SKIP1
013300 TITLE 'Initialization and Main Line'.
013400 PROCEDURE DIVISION USING INP-PARMS.
013500* make work area, attributes, and input line addressable.
013600     SET ADDRESS OF INP-UAREA TO INP-USTOR.
013700     SET ADDRESS OF INP-ATTR TO INP-PFATTR.
013800     SET ADDRESS OF INP-LINE TO INP-RECPTR.
013900* no special action is necessary at EOF.
014000     IF INP-EOF
014100      THEN
014200       DISPLAY PGMNAME, ' EOF REACHED.';
014300       MOVE EOF-LIT TO NEW-EOF;
014400       PERFORM 0100-INSERT-RECORD;
014500       GOBACK;
014600     END-IF.
014700* The print file attributes are used to determine the type
014800* of carriage control to test for for top-of-form.
014900* For purposes of this example, we assume the file will
015000* always have carriage control, and if machine control the
015100* skip to channel 1 immediate is used for new pages.
015200     IF INP-ANSI-CC
015300      THEN
015400       SET ANSI-TOF TO TRUE
015500      ELSE
015600       SET MACH-TOF TO TRUE.
015700* The carriage control character is tested for top-of-form.
015800* This identifies the first line of a page. The line is
015900* scanned for a space large enough for our text insert.
016000* The report number and run date are saved for use in the
016100* indexer key. The page counter is incremented and the
016200* line counter is reset, then the modified line is passed
016300* back to ACIF.
016400* If machine carriage control is used, then the first
016500* print line is the line after the top-of-form. A flag
016600* is set to cause this line to be treated as the top.
016700     IF FIRST-LINE OR (INP-CCVAL = CC-TOF)
016800      THEN
016900       IF ANSI-TOF OR FIRST-LINE
017000        THEN
017100         ADD 1 TO PAGE-COUNT;
017200         MOVE 1 TO LINE-COUNT;
017300         SET NOTFIRST-LINE TO TRUE;
017400        ELSE
017500         SET FIRST-LINE TO TRUE;
017600       END-IF;
017700      ELSE
017800       ADD 1 TO LINE-COUNT;
017900     END-IF.
018000     SKIP1
018100* If this record is received from ACIF, send it back and set
018200* the insert flag and also set our flag to note that a record
018300* will be inserted on the next call.
018400     INSPECT INP-PAGENUM REPLACING ALL SPACES BY ZEROES.
018500     INSPECT INP-LINENUM REPLACING ALL SPACES BY ZEROES.
018600     IF INSERT-LINE
018700      THEN
018800       SET NOINSERT-LINE TO TRUE;
018900       PERFORM 0100-INSERT-RECORD;
019000       SET INP-USE TO TRUE;
019100      ELSE
019200* last line is on page 5, line 5
019300       IF (INP-PAGENUM = 5 AND INP-LINENUM = 5) OR INSERT-MULTIPLE
019400        THEN
019500         SET INSERT-MULTIPLE TO TRUE;
019600         ADD 1 TO UAREA-INSCOUNT;
019700         IF UAREA-INSCOUNT < 6
019800          THEN
019900           SET INP-INSERT TO TRUE;
020000           PERFORM 0100-INSERT-RECORD;
020100          ELSE
020200           SET INP-DELETE TO TRUE;
020300         END-IF;
020400        ELSE
020500         SET INSERT-LINE TO TRUE;
020600         SET INP-INSERT TO TRUE;
020700      END-IF;
020800     END-IF.
020900     SKIP1
021000     GOBACK.
021100 SKIP3
021200 0100-INSERT-RECORD.
021300* create the record, move it to the provided buffer, and
021400* set the flag to use the record and then provide a new one.
021500     MOVE SPACE TO NEW-CC.
021600     ADD 1 TO UAREA-CNTR.
021700     MOVE UAREA-CNTR TO NEW-COUNT.
021800     MOVE NEW-LINE TO INP-LINE.
021900     MOVE LENGTH OF NEW-LINE TO INP-RECLEN.