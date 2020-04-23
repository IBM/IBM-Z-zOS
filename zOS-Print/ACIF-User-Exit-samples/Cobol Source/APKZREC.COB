000100 PROCESS DYNAM NUMPROC(PFD) TRUNC(OPT) APOST     NOSEQ     RENT
000200* LAST UPDATE ON 9 Apr 2018 AT 15:50:45 BY  HOWARDT VERSION 01   *
000300 ID DIVISION.
000400 PROGRAM-ID. APKBTINP.
000500 AUTHOR. TURETZKY--HYDRA.
000600 INSTALLATION. IBM BOULDER PROGRAMMING CENTER.
000700               THIS PROGRAM IS A SAMPLE EXIT FOR ACIF
000800               (APKACIF,5648-062) demonstrating the use of the
000900               ACIF input exit.
001000
001100               In order to use this exit, include the control
001200               INPEXIT=APKBTINP to enable this exit, and include
001300               the load module in a dataset referenced in steplib
001400               or elsewhere in the module search order.
001500
001600               This program will change input lines with the
001700               carriage control character 'Z' (used for report
001800               distriubtion exits) into an AFPDS NOP. It also
001900               switches the order of the 'Z' record with the
002000               following skip to channel 1 record, so the order
002100               becomes skip to channel 1, then 'Z' record. This is
002200               to make ACIF index properly when only a single page
002300               appears in the group. Normally, ACIF would
002400               associate the 'Z' record with the previous page
002500               which actually contains it.
002600
002700               Method of operation: each input record is examined
002800               for the carriage control character. If it is 'Z',
002900               then the reocrd is changed to a NOP and saved in a
003000               buffer.  If it is skip to channel 1, then the
003100               record is returned to ACIF with the insert
003200               indicator set, and the 'Z' record inserted on the
003300               next call.
003400
003500 DATE-WRITTEN. 14 Jul 94.
003600 DATE-COMPILED.
003700 SECURITY. IBM SAMPLE CODE ONLY.
003810*/**************************************************************/
003820*/* Licensed under the Apache License, Version 2.0 (the        */
003830*/* "License"); you may not use this file except in compliance */
003840*/* with the License. You may obtain a copy of the License at  */
003850*/*                                                            */
003860*/* http://www.apache.org/licenses/LICENSE-2.0                 */
003870*/*                                                            */
003880*/* Unless required by applicable law or agreed to in writing, */
003890*/* software distributed under the License is distributed on an*/
003891*/* "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY     */
003892*/* KIND, either express or implied.  See the License for the  */
003893*/* specific language governing permissions and limitations    */
003894*/* under the License.                                         */
003895*/*------------------------------------------------------------*/
003896*/*                                                            */
003900*/*   COPYRIGHT (C) 1993,2007 IBM CORPORATION                  */
004000*/*   COPYRIGHT (C) 2007,2018 RICOH COMPANY, LTD               */
004100*/*                                                            */
004200*/*   Permission to use, copy, modify, and distribute          */
004300*/*   this software for any purpose with or without fee        */
004400*/*   is hereby granted, provided that the above               */
004500*/*   copyright notices appear in all copies.                  */
004600*/*                                                            */
004700*/*   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY       */
004800*/*   OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT       */
004900*/*   LIMITED TO THE WARRANTIES OF MERCHANTABILITY,            */
005000*/*   FITNESS FOR A PARTICULAR PURPOSE AND                     */
005100*/*   NONINFRINGEMENT.  IN NO EVENT SHALL RICOH, RICOH         */
005200*/*   SUBSIDIARIES, ANY OF ITS SUPPLIERS OR ANY OF THE         */
005300*/*   OTHER COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,         */
005400*/*   DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF      */
005500*/*   CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF        */
005600*/*   OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR         */
005700*/*   OTHER DEALINGS IN THE SOFTWARE.                          */
005800*/**************************************************************/
005900 TITLE 'ACIF INPUT EXIT--FILTER LLE RECORDS'.
006000 ENVIRONMENT DIVISION.
006100 CONFIGURATION SECTION.
006200 SOURCE-COMPUTER. IBM-370.
006300 OBJECT-COMPUTER. IBM-370.
006400     EJECT
006500 DATA DIVISION.
006600 WORKING-STORAGE SECTION.
006700 77  PGMNAME                 PIC X(8) VALUE 'APKBTINP'.
006820 77  ABND-PGM                PIC X(8) VALUE 'CEE3DMP'.            !@01
006900 77  ABEND-CODE              PIC 9(4) BINARY VALUE 12.
006910 77  ABEND-OPTS              PIC X(255)                           !@01
006920     VALUE 'ENC(CUR) THR(CUR) FILE VAR NOBLOCK NOSTOR SF(ALL)' .  !@01
007000 77  LINE-COUNT              PIC S9(8) BINARY VALUE ZERO.
007100 77  PAGE-COUNT              PIC S9(8) BINARY VALUE ZERO.
007200 77  PAGE-DISP               PIC Z,ZZZ,ZZ9.
007300 77  CC-SF                   PIC X VALUE X'5A'.
007400 77  CC-DIST                 PIC X VALUE 'Z'.
007500 77  CC-TOF                  PIC X.
007600     88  ANSI-TOF            VALUE '1'.
007700     88  MACH-TOF            VALUE X'8B'.
007800 77  FIRST-LINE-FLAG         PIC X VALUE LOW-VALUE.
007900     88  FIRST-LINE          VALUE HIGH-VALUE.
008000     88  NOTFIRST-LINE       VALUE LOW-VALUE.
008100     SKIP1
008200/ AFP STRUCTURED FIELD DEFINITIONS.
008300     COPY STRFLDS SUPPRESS.
008400     EJECT
008500 01  ZREC-BUFFER             PIC X(068).
008600/ PASSED PARAMETERS.
008700 LINKAGE SECTION.
008800 01  INP-PARMS.
008900     05  INP-USTOR           POINTER.
009000     05  INP-PFATTR          POINTER.
009100     05  INP-RECPTR          POINTER.
009200     05  FILLER              POINTER.
009300     05  INP-RECLEN          PIC 9(4) BINARY.
009400     05  FILLER              PIC XX.
009500     05  INP-REQUEST         PIC X.
009600         88  INP-USE         VALUE X'00'.
009700         88  INP-DELETE      VALUE X'01'.
009800         88  INP-INSERT      VALUE X'02'.
009900     05  INP-EOF-FLAG        PIC X.
010000         88  INP-EOF         VALUE 'Y'.
010100     SKIP1
010200 01  INP-UAREA.
010300     05  INSERT-FLAG         PIC X.
010400         88 INSERT-LINE      VALUE HIGH-VALUE.
010500         88 INSERT-MULTIPLE  VALUE 'M'.
010600         88 NOINSERT-LINE    VALUE LOW-VALUE.
010700     05  FILLER              PIC X(15).
010800     SKIP1
010900 01  INP-ATTR.
011000     05  INP-CC              PIC XXX.
011100     05  INP-CCTYPE          PIC X.
011200         88  INP-ANSI-CC     VALUE 'A'.
011300         88  INP-MACH-CC     VALUE 'M'.
011400     05  INP-CHARS           PIC X(20).
011500     05  INP-FORMDEF         PIC X(8).
011600     05  INP-PAGEDEF         PIC X(8).
011700     05  INP-PRMODE          PIC X(8).
011800     05  INP-TRC             PIC XXX.
011900     SKIP1
012000* This is a template for the input record, pointed to by
012100* INP-RECPTR. The record's actual length is given by
012200* INP-RECLEN.
012300 01  INP-REC.
012400     05  INP-CCVAL           PIC X.
012500     05  INP-SFHDR.
012600         10 INP-LEN          PIC 9(4) BINARY.
012700         10 INP-SFID         PIC X(3).
012800         10 INP-FLAGSEQ.
012900             15 INP-FLAG     PIC X.
013000             15 INP-SEQ      PIC 9(4) BINARY.
013100     05  INP-DATA            PIC X(32747).
013200     SKIP1
013300 TITLE 'Initialization and Main Line'.
013400 PROCEDURE DIVISION USING INP-PARMS.
013500* make work area, attributes, and input line addressable.
013600     SET ADDRESS OF INP-UAREA TO INP-USTOR.
013700     SET ADDRESS OF INP-ATTR TO INP-PFATTR.
013800     SET ADDRESS OF INP-REC TO INP-RECPTR.
013900* No special action is necessary at EOF.
014000     IF INP-EOF
014100      THEN
014200       DISPLAY PGMNAME, ' EOF REACHED.';
014300       MOVE PAGE-COUNT TO PAGE-DISP;
014400       DISPLAY PGMNAME, PAGE-DISP, ' Pages processed.';
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
015700     IF INSERT-LINE
015800      THEN
015900* Send the saved record back to acif.
016000       SET NOINSERT-LINE TO TRUE;
016100       MOVE ZREC-BUFFER TO INP-REC;
016200       ADD INP-LEN, 1 GIVING INP-RECLEN;
016300       SET INP-USE TO TRUE;
016400      ELSE
016500       EVALUATE INP-CCVAL
016600        WHEN CC-TOF
016700*   Pass the record back and signal an inserted record
016800         ADD 1 TO PAGE-COUNT;
016900         MOVE ZERO TO LINE-COUNT;
017000         SET INP-INSERT TO TRUE;
017100         SET INSERT-LINE TO TRUE;
017200        WHEN CC-DIST
017300*   Construct the NOP and save it in the ZREC buffer, then tell ACIF
017400*   to delete it.
017500         MOVE INP-REC TO ZREC-BUFFER;
017600         MOVE CC-SF TO INP-CCVAL;
017700         MOVE SF-NOP TO INP-SFID;
017800         MOVE LOW-VALUE TO INP-FLAG;
017900         MOVE PAGE-COUNT TO INP-SEQ;
018000         ADD INP-RECLEN, LENGTH OF INP-SFHDR GIVING INP-LEN;
018100         MOVE ZREC-BUFFER TO INP-DATA;
018200         ADD 1 TO LINE-COUNT;
018300         MOVE INP-REC TO ZREC-BUFFER;
018400         SET INP-DELETE TO TRUE;
018500        WHEN OTHER
018600         ADD 1 TO LINE-COUNT;
018700       END-EVALUATE;
018800     END-IF.
018900     GOBACK.
019000 SKIP1
019100 END PROGRAM APKBTINP.