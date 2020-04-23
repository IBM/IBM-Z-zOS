000100 PROCESS DYNAM NUMPROC(PFD) TRUNC(OPT) APOST     NOSEQ     RENT
000200* UPDATE ON 9 Apr 2018 AT 15:33:56 BY  HOWARDT VERSION 01  *      00020004
000300 ID DIVISION.                                                     00030003
000400 PROGRAM-ID. ACIFOTX.                                             00040003
000500 AUTHOR. TURETZKY--HYDRA.                                         00050003
000600 INSTALLATION. IBM BOULDER PROGRAMMING CENTER.                    00060003
000700                                                                  00070003
000800               This program is a sample exit for ACIF
000900               (APKACIF,5648-062)
001000               demonstrating the use of the ACIF output
001100               exit in a simple print archive.
001200                                                                  00120003
001300               In order to use this exit, include the control     00130003
001400               OUTEXIT=ACIFOTX to enable this exit, and include   00140003
001500               the load module in a dataset referenced in STEPLIB 00150003
001600               or elsewhere in the module search order.           00160003
001700                                                                  00170003
001800               The program will delete the indexing NOP inserted  00180003
001900               by the input exit, ACIFINX, then write the         00190003
002000               remaining records to a VSAM RRDS. The ACIF OUTPUT  00200003
002100               file may be dummy if it is not to be printed.      00210003
002200                                                                  00220003
002300               Method of operation: each output record is examined00230003
002400               for a NOP containing the index tag string. For NOP 00240003
002500               record, the delete code (x'01') will be returned   00250003
002600               to ACIF. All other records are written, in         00260003
002700               sequence, to the RRDS. The records will then be    00270003
002800               passed to ACIF (use code x'00') so that the index  00280003
002900               will reflect the correct record and byte offsets.  00290003
003000                                                                  00300003
003100               This program must either be compiled with the      00310003
003200               NORENT option or linked with IGZOPT with the       00320003
003300               RTEREUS option.  (See VS COBOL II Application      00330003
003400               Programming Guide, SC26-4045).                     00340003
003500                                                                  00350003
003600 DATE-WRITTEN. 18 OCT 93.                                         00360003
003700 DATE-COMPILED.                                                   00370003
003800 SECURITY. IBM SAMPLE CODE ONLY.                                  00380003
003900*/**************************************************************/
003920*/* Licensed under the Apache License, Version 2.0 (the        */
003930*/* "License"); you may not use this file except in compliance */
003940*/* with the License. You may obtain a copy of the License at  */
003950*/*                                                            */
003960*/* http://www.apache.org/licenses/LICENSE-2.0                 */
003970*/*                                                            */
003980*/* Unless required by applicable law or agreed to in writing, */
003990*/* software distributed under the License is distributed on an*/
003991*/* "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY     */
003992*/* KIND, either express or implied.  See the License for the  */
003993*/* specific language governing permissions and limitations    */
003994*/* under the License.                                         */
003995*/*------------------------------------------------------------*/
003996*/*                                                            */
004000*/*   COPYRIGHT (C) 1993,2007 IBM CORPORATION                  */
004100*/*   COPYRIGHT (C) 2007,2018 RICOH COMPANY, LTD               */
004200*/*                                                            */
004300*/*   Permission to use, copy, modify, and distribute          */
004400*/*   this software for any purpose with or without fee        */
004500*/*   is hereby granted, provided that the above               */
004600*/*   copyright notices appear in all copies.                  */
004700*/*                                                            */
004800*/*   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY       */
004900*/*   OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT       */
005000*/*   LIMITED TO THE WARRANTIES OF MERCHANTABILITY,            */
005100*/*   FITNESS FOR A PARTICULAR PURPOSE AND                     */
005200*/*   NONINFRINGEMENT.  IN NO EVENT SHALL RICOH, RICOH         */
005300*/*   SUBSIDIARIES, ANY OF ITS SUPPLIERS OR ANY OF THE         */
005400*/*   OTHER COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,         */
005500*/*   DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF      */
005600*/*   CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF        */
005700*/*   OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR         */
005800*/*   OTHER DEALINGS IN THE SOFTWARE.                          */
005900*/**************************************************************/
006000 TITLE 'ACIF Sample output Exit'.                                 00570003
006100 ENVIRONMENT DIVISION.                                            00580003
006200 CONFIGURATION SECTION.                                           00590003
006300 SOURCE-COMPUTER. IBM-370.                                        00600003
006400 OBJECT-COMPUTER. IBM-370.                                        00610003
006500 INPUT-OUTPUT SECTION.                                            00620003
006600 FILE-CONTROL.                                                    00630003
006700     SELECT AFPPAGOT-FILE        ASSIGN TO AFPPAGOT,              00640003
006800                                 ORGANIZATION RELATIVE,           00650003
006900                                 ACCESS MODE SEQUENTIAL,          00660003
007000                                 FILE STATUS AFPPAGOT-STATUS      00670003
007100                                             VSAM-STATUS,         00680003
007200                                 RELATIVE KEY AFPPAGOT-REC.       00690003
007300     EJECT                                                        00700003
007400 DATA DIVISION.                                                   00710003
007500 FILE SECTION.                                                    00720003
007600 FD  AFPPAGOT-FILE,                                               00730003
007700     RECORD VARYING DEPENDING ON AFPPAGOT-LENGTH.                 00740003
007800     COPY AFPAGOT                                                 00750003
007900          REPLACING ==:PREFIX:== BY ==AFPPAGOT==.                 00760003
008000 WORKING-STORAGE SECTION.                                         00770003
008100 77  PGMNAME                 PIC X(8) VALUE 'ACIFOTX'.            00780003
008200 77  ABND-PGM                PIC X(8) VALUE 'CEE3DMP'.            !@01   3
008300 77  ABEND-CODE              PIC 9(4) BINARY VALUE 12.            00800003
008310 77  ABEND-OPTS              PIC X(255)                           !@01
008320     VALUE 'ENC(CUR) THR(CUR) FILE VAR NOBLOCK NOSTOR SF(ALL)' .  !@01
008400 77  PAGE-COUNT              PIC S9(8) BINARY VALUE ZERO.         00810003
008500 77  LINE-COUNT              PIC S9(8) BINARY VALUE ZERO.         00820003
008600 77  AFPPAGOT-STATUS         PIC 99.                              00830003
008700     88  AFPPAGOT-OK         VALUE 00.                            00840003
008800 77  AFPPAGOT-EOF-FLAG       PIC X    VALUE LOW-VALUE.            00850003
008900     88  AFPPAGOT-EOF        VALUE HIGH-VALUE.                    00860003
009000 77  AFPPAGOT-ERROR-FLAG     PIC X    VALUE LOW-VALUE.            00870003
009100     88  AFPPAGOT-ERROR      VALUE HIGH-VALUE.                    00880003
009200     SKIP2                                                        00890003
009300 01  AFPPAGOT-LENGTH         PIC 9(8) BINARY.                     00900003
009400     SKIP2                                                        00910003
009500     SKIP1                                                        00920003
009600 01  VSAM-STATUS.                                                 00930003
009700     05  VSAM-RC                 PIC 9(4) COMP.                   00940003
009800     05  VSAM-FCT-CODE           PIC 9(1) COMP.                   00950003
009900     05  VSAM-FDBK-CODE          PIC 9(3) COMP.                   00960003
010000     SKIP1                                                        00970003
010100 01  DATE-DATA.                                                   00980003
010200   05  RUN-DATE.                                                  00990003
010300     10 RUN-YY                 PIC 99.                            01000003
010400     10 RUN-MM                 PIC 99.                            01010003
010500     10 RUN-DD                 PIC 99.                            01020003
010600   05  COMPILE-DATE.                                              01030003
010700     10  COMP-DATE             PIC X(8).                          01040003
010800     10  COMP-TIME             PIC X(12).                         01050003
010900   05  RUN-TIME.                                                  01060003
011000     10  RUN-HH                PIC 99.                            01070003
011100     10  RUN-MM                PIC 99.                            01080003
011200     10  RUN-SS                PIC 99.                            01090003
011300     10  RUN-MS                PIC 99.                            01100003
011400     SKIP2                                                        01110003
011500* THIS IS THE DATA PORTION OF THE NOP RECORD. IT SPECIFIES        01120003
011600* THE NAME OF DIVISION AND STORE FOR INDEXING.                    01130003
011700 01  NOP-DATA.                                                    01140003
011800     05  NOP-EYEBALL         PIC X(11) VALUE '**INDEX**: '.       01150003
011900     05  NOP-DIVISION-CODE   PIC 99.                              01160003
012000     05  NOP-DIVISION-NAME   PIC X(12).                           01170003
012100     05  FILLER              PIC X  VALUE SPACE.                  01180003
012200     05  NOP-STORE-CODE      PIC 99.                              01190003
012300     05  NOP-STORE-NAME      PIC X(12).                           01200003
012400     SKIP2                                                        01210003
012500 01  BINARY-NUMBERS.                                              01220003
012600     05  BIN-4                   PIC 9(8) BINARY VALUE ZERO.      01230003
012700     05  BIN4-X                  REDEFINES BIN-4                  01240003
012800                                 PIC X(4).                        01250003
012900     05  BIN2                    PIC 9(4) BINARY VALUE ZERO.      01260003
013000     05  BIN2-X                  REDEFINES BIN2.                  01270003
013100         10  FILLER              PIC X.                           01280003
013200         10  BIN2-2              PIC X.                           01290003
013300         EJECT                                                    01300003
013400/ AFP STRUCTURED FIELD DEFINITIONS.                               01310003
013500     COPY STRFLDS SUPPRESS.                                       01320003
013600/ PASSED PARAMETERS.                                              01330003
013700 LINKAGE SECTION.                                                 01340003
013800 01  OUT-PARMS.                                                   01350003
013900     05  OUT-WORKA           POINTER.                             01360003
014000     05  OUT-PFATTR          POINTER.                             01370003
014100     05  OUT-RECPTR          POINTER.                             01380003
014200     05  OUT-RECLEN          PIC 9(4) BINARY.                     01390003
014300     05  OUT-REQUEST         PIC X.                               01400003
014400         88  OUT-USE         VALUE X'00'.                         01410003
014500         88  OUT-DELETE      VALUE X'01'.                         01420003
014600     05  OUT-EOF-FLAG        PIC X.                               01430003
014700         88  OUT-EOF         VALUE 'Y'.                           01440003
014800         88  OUT-NOTEOF      VALUE 'N'.                           01450003
014900                                                                  01460003
015000 01  OUT-UAREA.                                                   01470003
015100     05  AFPPAGOT-REC        PIC 9(8) BINARY.                     01480003
015200     05  OUT-FIRST-FLAG      PIC X.                               01490003
015300         88  OUT-FIRST       VALUE LOW-VALUE.                     01500003
015400         88  OUT-NOTFIRST    VALUE HIGH-VALUE.                    01510003
015500                                                                  01520003
015600 01  OUT-ATTR.                                                    01530003
015700     05  OUT-CC              PIC XXX.                             01540003
015800     05  OUT-CCTYPE          PIC X.                               01550003
015900         88  OUT-ANSI-CC     VALUE 'A'.                           01560003
016000         88  OUT-MACH-CC     VALUE 'M'.                           01570003
016100     05  OUT-CHARS           PIC X(20).                           01580003
016200     05  OUT-FORMDEF         PIC X(8).                            01590003
016300     05  OUT-PAGEDEF         PIC X(8).                            01600003
016400     05  OUT-PRMODE          PIC X(8).                            01610003
016500     05  OUT-TRC             PIC XXX.                             01620003
016600                                                                  01630003
016700* This is a template for the output record, pointed to by         01640003
016800* OUT-RECPTR. The record's actual length is given by              01650003
016900* OUT-RECLEN.                                                     01660003
017000 01  OUT-LINE.                                                    01670003
017100     05  OUT-CCVAL           PIC X.                               01680003
017200     05  OUT-SFINTRO.                                             01690003
017300         10  OUT-SFLEN       PIC 9(4) BINARY.                     01700003
017400         10  OUT-SFTYPE      PIC XXX.                             01710003
017500         10  OUT-SFFLAG      PIC X.                               01720003
017600         10  OUT-SFSEQ       PIC 9(4) BINARY.                     01730003
017700     05  OUT-SFDATA          PIC X(32751).                        01740003
017800 TITLE 'Initialization and Main Line'.                            01750003
017900 PROCEDURE DIVISION USING OUT-PARMS.                              01760003
018000* make work area, attributes, and output line addressable.        01770003
018100     SET ADDRESS OF OUT-UAREA TO OUT-WORKA.                       01780003
018200     SET ADDRESS OF OUT-ATTR TO OUT-PFATTR.                       01790003
018300     SET ADDRESS OF OUT-LINE TO OUT-RECPTR.                       01800003
018400* no special action is necessary at EOF.                          01810003
018500     IF OUT-EOF                                                   01820003
018600      THEN                                                        01830003
018700       DISPLAY PGMNAME, ' EOF REACHED.';                          01840003
018800       GOBACK;                                                    01850003
018900     END-IF.                                                      01860003
019000     IF OUT-FIRST                                                 01870003
019100      THEN                                                        01880003
019200       SET OUT-NOTFIRST TO TRUE;                                  01890003
019300       MOVE WHEN-COMPILED TO COMPILE-DATE;                        01900003
019400       ACCEPT RUN-DATE FROM DATE;                                 01910003
019500       ACCEPT RUN-TIME FROM TIME;                                 01920003
019600       OPEN OUTPUT AFPPAGOT-FILE;                                 01930003
019700        SKIP2                                                     01940003
019800       IF NOT AFPPAGOT-OK THEN                                    01950003
019900          DISPLAY 'AFPPAGOT  STATUS AFTER OPEN ' AFPPAGOT-STATUS; 01960003
020000          DISPLAY ' ';                                            01970003
020100          MOVE AFPPAGOT-STATUS TO RETURN-CODE;                    01980003
020200          GOBACK;                                                 01990003
020300       END-IF;                                                    02000003
020400       MOVE ZERO TO AFPPAGOT-REC;                                 02010003
020500        SKIP2                                                     02020003
020600     END-IF.                                                      02030003
020700     SET OUT-USE TO TRUE.                                         02040003
020800     EVALUATE OUT-SFTYPE;                                         02050003
020900      WHEN SF-NOP                                                 02060003
021000* If this is the index NOP record, then flag it for deletion.     02070003
021100* All other NOPs are written to the output file.                  02080003
021200       IF OUT-SFDATA (1 : LENGTH OF NOP-EYEBALL) = NOP-EYEBALL    02090003
021300        THEN                                                      02100003
021400         SET OUT-DELETE TO TRUE;                                  02110003
021500        ELSE                                                      02120003
021600         PERFORM 0100-WRITE-PAGEOUT;                              02130003
021700       END-IF;                                                    02140003
021800      WHEN SF-BPG                                                 02150003
021900       ADD 1 TO PAGE-COUNT;                                       02160003
022000       MOVE 0 TO LINE-COUNT;                                      02170003
022100       PERFORM 0100-WRITE-PAGEOUT;                                02180003
022200      WHEN OTHER                                                  02190003
022300       ADD 1 TO LINE-COUNT;                                       02200003
022400       MOVE LINE-COUNT TO OUT-SFSEQ;                              02210003
022500       PERFORM 0100-WRITE-PAGEOUT;                                02220003
022600     END-EVALUATE.                                                02230003
022700     SKIP1                                                        02240003
022800     GOBACK.                                                      02250003
022900        SKIP2                                                     02260003
023000 0100-WRITE-PAGEOUT.                                              02270003
023100     ADD 1 TO AFPPAGOT-REC.                                       02280003
023200     MOVE OUT-RECLEN TO AFPPAGOT-LENGTH.                          02290003
023300     WRITE AFPPAGOT-RECORD FROM OUT-LINE                          02300003
023400       INVALID KEY                                                02310003
023500        DISPLAY PGMNAME, ' VSAM RELATIVE INVALID KEY.'            02320003
023600                ' FILE STATUS ',                                  02330003
023700                AFPPAGOT-STATUS, ' VSAM CODES : ',                02340003
023800                VSAM-RC, VSAM-FCT-CODE, VSAM-FDBK-CODE;           02350003
023900                MOVE VSAM-RC TO RETURN-CODE;                      02360003
024000     END-WRITE.                                                   02370003