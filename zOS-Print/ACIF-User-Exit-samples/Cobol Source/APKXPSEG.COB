000100 PROCESS DYNAM NUMPROC(PFD) TRUNC(OPT) APOST     NOSEQ     RENT
000200* LAST UPDATE ON 9 Apr 2018 AT 15:49:14 BY  HOWARDT VERSION 01   *
000300 ID DIVISION.
000400 PROGRAM-ID. APKXPSEG.
000500 AUTHOR. TURETZKY--HYDRA.
000600 INSTALLATION. IBM BOULDER PROGRAMMING CENTER.
000700               This program is an exit for ACIF (APKACIF,5648-062)
000800               that will print a list page segments referenced in
000900               a print job, and cause them to be excluded from the
001000               output resource library.
001100
001200               In order to use this exit, you must use the ACIF
001300               control statement RESTYPE=ALL for the list to be
001400               complete. RESTYPE=NONE will produce no list at all.
001500               If you only wish to see certain type of resource,
001600               use RESTYPE to select it. Include the control
001700               RESEXIT=APKXPSEG to enable this exit, and include
001800               the load module in a dataset referenced in STEPLIB
001900               or elsewhere in the module search order.
002000
002100               To control resource inclusion in the output
002200               resource library, set the value of RES-ACTION
002300               appropriately.  Note that if resources are
002400               excluded, resources contained in overlays will not
002500               appear in the report because overlay contents will
002600               not be processed by ACIF.
002700
002800               Method of operation: each resource name is saved in
002900               a table for that type of resource. The table may be
003000               searched to eliminate duplicates. When the last
003100               call flag is set, the contents of the tables are
003200               printed.
003300
003400               You must allocate a DD named PAPKRSLS for the print
003500               file, with an LRECL of 84, BLKSIZE of n*84+4, VBA.
003600
003700               This program must either be compiled with the
003800               NORENT option or linked with IGZOPT with the
003900               RTEREUS option.  (See VS COBOL II Application
004000               Programming Guide, SC26-4045).
004100
004200 DATE-WRITTEN. 23 FEB 93.
004300 DATE-COMPILED.
004400 SECURITY. IBM SAMPLE CODE ONLY.
004500*/**************************************************************/
004510*/* Licensed under the Apache License, Version 2.0 (the        */
004520*/* "License"); you may not use this file except in compliance */
004530*/* with the License. You may obtain a copy of the License at  */
004540*/*                                                            */
004550*/* http://www.apache.org/licenses/LICENSE-2.0                 */
004560*/*                                                            */
004570*/* Unless required by applicable law or agreed to in writing, */
004580*/* software distributed under the License is distributed on an*/
004590*/* "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY     */
004591*/* KIND, either express or implied.  See the License for the  */
004592*/* specific language governing permissions and limitations    */
004593*/* under the License.                                         */
004594*/*------------------------------------------------------------*/
004595*/*                                                            */
004600*/*   COPYRIGHT (C) 1993,2007 IBM CORPORATION                  */
004700*/*   COPYRIGHT (C) 2007,2018 RICOH COMPANY, LTD               */
004800*/*                                                            */
004900*/*   Permission to use, copy, modify, and distribute          */
005000*/*   this software for any purpose with or without fee        */
005100*/*   is hereby granted, provided that the above               */
005200*/*   copyright notices appear in all copies.                  */
005300*/*                                                            */
005400*/*   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY       */
005500*/*   OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT       */
005600*/*   LIMITED TO THE WARRANTIES OF MERCHANTABILITY,            */
005700*/*   FITNESS FOR A PARTICULAR PURPOSE AND                     */
005800*/*   NONINFRINGEMENT.  IN NO EVENT SHALL RICOH, RICOH         */
005900*/*   SUBSIDIARIES, ANY OF ITS SUPPLIERS OR ANY OF THE         */
006000*/*   OTHER COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,         */
006100*/*   DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF      */
006200*/*   CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF        */
006300*/*   OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR         */
006400*/*   OTHER DEALINGS IN THE SOFTWARE.                          */
006500*/**************************************************************/
006600 TITLE 'ACIF RESOURCE REPORT EXIT'.
006700 ENVIRONMENT DIVISION.
006800 CONFIGURATION SECTION.
006900 SOURCE-COMPUTER. IBM-370.
007000 OBJECT-COMPUTER. IBM-370.
007100 INPUT-OUTPUT SECTION.
007200 FILE-CONTROL.
007300     SELECT PRINT-FILE ASSIGN TO PAPKXPSE.
007400     SKIP2
007500 DATA DIVISION.
007600 FILE SECTION.
007700 FD  PRINT-FILE
007800     BLOCK CONTAINS 0
007900     LABEL RECORDS STANDARD
008000     RECORD VARYING DEPENDING ON PRINT-REC-LEN
008100     RECORDING MODE V.
008200 01  PRINT-RECORD.
008300     05  PRINT-DATA          OCCURS 1 TO 80,
008400                             DEPENDING ON PRINT-REC-LEN,
008500                             PIC X.
008600     EJECT
008700 WORKING-STORAGE SECTION.
008800 77  PGMNAME                 PIC X(8) VALUE 'APKXPSEG'.
008911 77  ABND-PGM                PIC X(8) VALUE 'CEE3DMP'.            !@01
009000 77  ABEND-CODE              PIC 9(4) BINARY VALUE 12.
009010 77  ABEND-OPTS              PIC X(255)                           !@01
009020     VALUE 'ENC(CUR) THR(CUR) FILE VAR NOBLOCK NOSTOR SF(ALL)' .  !@01
009100 77  PRINT-REC-LEN           PIC 9(8) BINARY VALUE ZERO.
009200 77  MIN-REC-LEN             PIC 9(4) BINARY VALUE 9.
009300 77  MAX-REC-LEN             PIC 9(4) BINARY VALUE 81.
009400 77  LINE-COUNT              PIC S9(8) BINARY VALUE ZERO.
009500 77  PAGE-COUNT              PIC S9(8) BINARY VALUE ZERO.
009600 77  PAGE-LEN                PIC S9(8) BINARY VALUE 50.
009700 77  PSEG-CNTR               PIC S9(8) BINARY VALUE ZERO.
009800 77  OVLY-CNTR               PIC S9(8) BINARY VALUE ZERO.
009900 77  CSET-CNTR               PIC S9(8) BINARY VALUE ZERO.
010000 77  CPAGE-CNTR              PIC S9(8) BINARY VALUE ZERO.
010100 77  UNKNOWN-CNTR            PIC 9(4) BINARY VALUE ZERO.
010200 77  INCLUDE-RESOURCE        PIC X VALUE X'00'.
010300 77  IGNORE-RESOURCE         PIC X VALUE X'01'.
010400 77  FIRST-TIME-FLAG         PIC X VALUE LOW-VALUE.
010500     88  FIRST-TIME          VALUE LOW-VALUE.
010600     88  NOT-FIRST-TIME      VALUE HIGH-VALUE.
010700 77  CPAGE                   PIC X VALUE X'41'.
010800 77  CSET                    PIC X VALUE X'40'.
010900 77  PSEG                    PIC X VALUE X'FB'.
011000 77  OVLY                    PIC X VALUE X'FC'.
011100 77  FDEF-NAME               PIC X(14) VALUE 'FORMDEF'.
011200 77  CPAGE-NAME              PIC X(14) VALUE 'CODEPAGE'.
011300 77  CSET-NAME               PIC X(14) VALUE 'CHARACTER-SET'.
011400 77  PSEG-NAME               PIC X(14) VALUE 'PAGE-SEGMENT'.
011500 77  OVLY-NAME               PIC X(14) VALUE 'OVERLAY'.
011600     SKIP2
011700         SKIP1
011800 01  LINE-DETAIL.
011900     05  LINE-CC             PIC X   VALUE SPACE.
012000     05  FILLER              PIC X(02) VALUE SPACES.
012100     05  LINE-TYPE           PIC X(14) VALUE SPACES.
012200     05  FILLER              PIC X(02) VALUE SPACES.
012300     05  LINE-RESNAME        PIC X(8).
012400         SKIP1
012500 01  TIME-STAMP.
012600     05  T-S-DAY             PIC 9(5).
012700     05  FILLER              PIC X VALUE '/'.
012800     05  T-S-TIME            PIC X(6).
012900         SKIP1
013000/ PASSED PARAMETERS.
013100 LINKAGE SECTION.
013200 01  RES-PARMS.
013300     05  RES-USTOR           POINTER.
013400     05  RES-PFATTR          POINTER.
013500     05  RES-RSNAME          PIC X(8).
013600     05  RES-RSTYPE          PIC X.
013700     05  RES-ACTION          PIC X.
013800     05  RES-EOF-FLAG        PIC X.
013900         88  RES-EOF         VALUE 'Y'.
014000
014100 01  RES-UAREA               PIC X(16).
014200
014300 01  RES-ATTR.
014400     05  RES-CC              PIC XXX.
014500     05  RES-CCTYPE          PIC X.
014600     05  RES-CHARS           PIC X(20).
014700     05  RES-FORMDEF         PIC X(8).
014800     05  RES-PAGEDEF         PIC X(8).
014900     05  RES-PRMODE          PIC X(8).
015000     05  RES-TRC             PIC XXX.
015100 TITLE 'INITIALIZATION AND MAIN LINE'.
015200 PROCEDURE DIVISION USING RES-PARMS.
015300 0010-UPDATE-TABLE.
015400     SET ADDRESS OF RES-UAREA TO RES-USTOR.
015500     SET ADDRESS OF RES-ATTR TO RES-PFATTR.
015600     SKIP1
015700     IF FIRST-TIME
015800      THEN
015900       OPEN OUTPUT PRINT-FILE;
016000       MOVE FDEF-NAME TO LINE-TYPE;
016100       MOVE RES-FORMDEF TO LINE-RESNAME;
016200       PERFORM 0120-PRINT-DETAIL;
016300       SET NOT-FIRST-TIME TO TRUE;
016400     END-IF.
016500     SKIP1
016600     IF RES-EOF
016700      THEN
016800       CLOSE PRINT-FILE;
016900       SET FIRST-TIME TO TRUE;
017000       GOBACK;
017100     END-IF.
017200     SKIP1
017300     EVALUATE RES-RSTYPE
017400* ACIF presents code pages each time they appear in a font, so
017500* there may be many occurences of the same codepage. Make sure
017600* we save only 1 of each.
017700      WHEN CPAGE
017800       ADD 1 TO CPAGE-CNTR;
017900       MOVE CPAGE-NAME TO LINE-TYPE;
018000       MOVE RES-RSNAME TO LINE-RESNAME;
018100       PERFORM 0120-PRINT-DETAIL;
018200      WHEN CSET
018300       ADD 1 TO CSET-CNTR;
018400       MOVE CSET-NAME TO LINE-TYPE;
018500       MOVE RES-RSNAME TO LINE-RESNAME;
018600       PERFORM 0120-PRINT-DETAIL;
018700      WHEN PSEG
018800       ADD 1 TO PSEG-CNTR;
018900       MOVE PSEG-NAME TO LINE-TYPE;
019000       MOVE RES-RSNAME TO LINE-RESNAME;
019100       PERFORM 0120-PRINT-DETAIL;
019200      WHEN OVLY
019300       ADD 1 TO OVLY-CNTR;
019400       MOVE OVLY-NAME TO LINE-TYPE;
019500       MOVE RES-RSNAME TO LINE-RESNAME;
019600       PERFORM 0120-PRINT-DETAIL;
019700      WHEN OTHER
019800       ADD 1 TO UNKNOWN-CNTR;
019900     END-EVALUATE.
020000* The following omits or includes all resources.
020100     MOVE IGNORE-RESOURCE TO RES-ACTION.
020200*    MOVE INCLUDE-RESOURCE TO RES-ACTION.
020300     GOBACK.
020400 TITLE 'Produce Resource Used Report'.
020500 0120-PRINT-DETAIL.
020600     MOVE LENGTH OF LINE-DETAIL TO PRINT-REC-LEN.
020700     WRITE PRINT-RECORD FROM LINE-DETAIL.