000110 PROCESS DYNAM NUMPROC(PFD) TRUNC(OPT) APOST     NOSEQ     RENT
000200* LAST UPDATE ON 9 Apr 2018 AT 15:38:00 BY  HOWARDT VERSION 01   *
000300 ID DIVISION.
000400 PROGRAM-ID. APKINFIL.
000500 AUTHOR. TURETZKY--HYDRA.
000600 INSTALLATION. IBM BOULDER PROGRAMMING CENTER.
000700               This program is a sample exit for ACIF
000800               (APKACIF,5648-062) demonstrating the use of the
000900               ACIF input exit.
001000
001100               In order to use this exit, include the control
001200               INPEXIT=APKINFIL to enable this exit, and include
001300               the load module in a dataset referenced in STEPLIB
001400               or elsewhere in the module search order.
001500
001600               This program tests inserting an entire file at the
001700               input exit. The first record from ACIF is a single
001800               dummy record from the input file. The exit opens
001900               the "real" input file, sets the insert flag, and
002000               returns each record from the actual file. When all
002100               records are processed, the delete flag is set.
002200
002300               This program must either be compiled with the
002400               NORENT option or linked with IGZOPT with the
002500               RTEREUS option.  (See VS COBOL II Application
002600               Programming Guide, SC26-4045).
002700
002800 DATE-WRITTEN. 16 AUG 94.
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
005700 INPUT-OUTPUT SECTION.
005800 FILE-CONTROL.
005900     SELECT APKINFIL-IN          ASSIGN TO SYS001-S-APKINFIL
006000                                 FILE STATUS
006100                                 APKINFIL-IN-STATUS.
006200     EJECT
006300 DATA DIVISION.
006400 FILE SECTION.
006500 FD  APKINFIL-IN                 GLOBAL,
006600     BLOCK CONTAINS 0 RECORDS,
006700     RECORDING MODE IS V
006800     RECORD VARYING FROM 08 TO 32752 DEPENDING ON APKINFIL-LENGTH.
006900
007000 01  APKINFIL-IN-RECORD.
007100     05  APKINFIL-IN-INTRODUCER.
007200       10  APKINFIL-IN-CC PIC X.
007300       10  APKINFIL-IN-LEN-CHR PIC XX.
007400       10  APKINFIL-IN-RECLEN REDEFINES
007500                                  APKINFIL-IN-LEN-CHR
007600                             PIC 9(4) COMP.
007700* NOTE:  9(4) COMP IS USED TO GET HALFWORD INTEGER, BUT COBOL
007800* MAY RESTRICT VALUE TO 9999. COBOL II COMPILE-TIME PARM
007900* TRUNC(BIN) OR TRUNC(OPT) WILL TREAT THE VALUE AS A HALFWORD
008000* WITH NO TRUNCATION (TRUNC(OPT) PRODUCES FAR BETTER CODE).
008100       10  APKINFIL-IN-TYPE PIC XXX.
008200       10  APKINFIL-IN-FLAG PIC X.
008300       10  APKINFIL-IN-SEQ-CHR PIC XX.
008400       10  APKINFIL-IN-SEQNUM REDEFINES
008500                                  APKINFIL-IN-SEQ-CHR
008600                             PIC 9(4) COMP.
008700     05  APKINFIL-IN-DATA.
008800         10  APKINFIL-IN-ARRAY
008900                             OCCURS 32743,
009000                             DEPENDING ON
009100                             APKINFIL-IN-RECLEN,
009200                             INDEXED BY APKINFIL-IN-INDX,
009300                             PIC X.
009400   SKIP3
009500 WORKING-STORAGE SECTION.
009600 77  PGMNAME                 PIC X(8) VALUE 'APKINFIL'.
009610 77  ABND-PGM                PIC X(8) VALUE 'CEE3DMP'.            !@01
009620 77  ABEND-CODE              PIC 9(4) BINARY VALUE 12.
009630 77  ABEND-OPTS              PIC X(255)                           !@01
009640     VALUE 'ENC(CUR) THR(CUR) FILE VAR NOBLOCK NOSTOR SF(ALL)' .  !@01
009900 77  AFPWRITE                PIC X(8) VALUE 'AFPWRITE'.
010000 77  PAGE-COUNT              PIC 9(8) BINARY VALUE ZERO.
010100 77  LINE-COUNT              PIC 9(8) BINARY VALUE ZERO.
010200 77  APKINFIL-LENGTH         PIC 9(8) BINARY VALUE ZERO.
010300 01  GLOBAL-VARIABLES            GLOBAL.
010400     05  APKINFIL-IN-STATUS      PIC 99   VALUE ZERO.
010500         88  APKINFIL-IN-OK      VALUE 00.
010600         88  APKINFIL-IN-EOF     VALUE 10.
010700/ PASSED PARAMETERS.
010800 LINKAGE SECTION.
010900 01  INP-PARMS.
011000     05  INP-USTOR           POINTER.
011100     05  INP-PFATTR          POINTER.
011200     05  INP-RECPTR          POINTER.
011300     05  FILLER              POINTER.
011400     05  INP-RECLEN          PIC 9(4) BINARY.
011500     05  FILLER              PIC XX.
011600     05  INP-REQUEST         PIC X.
011700         88  INP-USE         VALUE X'00'.
011800         88  INP-DELETE      VALUE X'01'.
011900         88  INP-INSERT      VALUE X'02'.
012000     05  INP-EOF-FLAG        PIC X.
012100         88  INP-EOF         VALUE 'Y'.
012200
012300 01  INP-UAREA.
012400     05  UAREA-INCNTR        PIC 9(8) BINARY.
012500     05  INIT-FLAG           PIC X.
012600         88 INITTED          VALUE HIGH-VALUE.
012700         88 NOT-INITTED      VALUE LOW-VALUE.
012800     05  FILLER              PIC X(11).
012900
013000 01  INP-ATTR.
013100     05  INP-CC              PIC XXX.
013200     05  INP-CCTYPE          PIC X.
013300         88  INP-ANSI-CC     VALUE 'A'.
013400         88  INP-MACH-CC     VALUE 'M'.
013500     05  INP-CHARS           PIC X(20).
013600     05  INP-FORMDEF         PIC X(8).
013700     05  INP-PAGEDEF         PIC X(8).
013800     05  INP-PRMODE          PIC X(8).
013900     05  INP-TRC             PIC XXX.
014000
014100* This is a template for the input record, pointed to by
014200* INP-RECPTR. The record's actual length is given by
014300* INP-RECLEN.
014400 01  INP-LINE.
014500     05  INP-CCVAL           PIC X.
014600     05  INP-TRCVAL          PIC X.
014700     05  INP-DATA            PIC X(32750).
014800     SKIP1
014900 TITLE 'Initialization and Main Line'.
015000 PROCEDURE DIVISION USING INP-PARMS.
015100* make work area, attributes, and input line addressable.
015200     SET ADDRESS OF INP-UAREA TO INP-USTOR.
015300     SET ADDRESS OF INP-ATTR TO INP-PFATTR.
015400     SET ADDRESS OF INP-LINE TO INP-RECPTR.
015500* no special action is necessary at EOF.
015600     IF INP-EOF
015700      THEN
015800       DISPLAY PGMNAME, ' EOF REACHED.';
015900       DISPLAY PGMNAME, ' RECORDS INSERTED ', UAREA-INCNTR;
016000       CLOSE APKINFIL-IN;
016100       GOBACK;
016200     END-IF.
016300     IF NOT-INITTED
016400      THEN
016500       OPEN INPUT APKINFIL-IN;
016600       IF NOT APKINFIL-IN-OK
016700        THEN
016800         DISPLAY PGMNAME, ' ERROR OPENING APKINFIL INPUT FILE';
016900         DISPLAY PGMNAME, ' STATUS CODE ', APKINFIL-IN-STATUS;
017000         MOVE APKINFIL-IN-STATUS TO RETURN-CODE;
017100         GOBACK;
017200        ELSE
017300         SET INITTED TO TRUE;
017400       END-IF;
017500     END-IF.
017600     SKIP1
017700* Set the insert flag, and point the ACIF input record pointer
017800* to the input record just read.
017900     PERFORM 0100-READ-RECORD.
018000     IF APKINFIL-IN-OK
018100      THEN
018200       SET INP-INSERT TO TRUE;
018300       MOVE APKINFIL-IN-RECORD TO INP-LINE (1 : APKINFIL-LENGTH);
018400       MOVE APKINFIL-LENGTH TO INP-RECLEN;
018500      ELSE
018600       IF NOT APKINFIL-IN-EOF
018700        THEN
018800         DISPLAY PGMNAME, ' ERROR READING APKINFIL INPUT FILE';
018900         DISPLAY PGMNAME, ' STATUS CODE ', APKINFIL-IN-STATUS;
019000         MOVE APKINFIL-IN-STATUS TO RETURN-CODE;
019100        END-IF;
019200       SET INP-DELETE TO TRUE;
019300      END-IF.
019400     SKIP1
019500     GOBACK.
019600 SKIP3
019700 0100-READ-RECORD.
019800* Read a record from the input file.
019900     READ APKINFIL-IN,
020000      AT END
020100       CONTINUE;
020200      NOT AT END
020300       ADD 1 TO UAREA-INCNTR;
020400     END-READ.