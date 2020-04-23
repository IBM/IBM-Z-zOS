000100 PROCESS DYNAM NUMPROC(PFD) TRUNC(OPT) APOST     NOSEQ            00010000
000200* LAST UPDATE ON 9 Apr 2018 AT 16:12:16 BY  HOWARDT VERSION 01   *00020000
000300 ID DIVISION.                                                     00030000
000400 PROGRAM-ID. ACIFIBDT.                                            00040000
000500 AUTHOR. TURETZKY--IBM PSD.                                       00050000
000600 INSTALLATION. IBM BOULDER PROGRAMMING CENTER.                    00060000
000700               This program is a sample exit for ACIF             00070000
000800               (APKACIF,5648-062) demonstrating the use of the    00080000
000900               ACIF input exit.                                   00090000
001000                                                                  00100000
001100               In order to use this exit, include the control     00110000
001200               INPEXIT=ACIFIBDT to enable this exit, and include  00120000
001300               the load module in a dataset referenced in STEPLIB 00130000
001400               or elsewhere in the module search order.           00140000
001500                                                                  00150000
001600               This program will convert all BDT/EDT structured   00160000
001700               fields to NOPs containing the original structured  00170000
001800               field, which will be turned back into BDT/EDT by   00180000
001900               ACIFOBDT.                                          00190000
002000                                                                  00200000
002100                                                                  00210000
002200 DATE-WRITTEN. 10 Dec 2000.                                       00220000
002300 DATE-COMPILED.                                                   00230000
002400 SECURITY. IBM SAMPLE CODE ONLY.                                  00240000
002500*/**************************************************************/ 00250000
002600*/* Licensed under the Apache License, Version 2.0 (the        */ 00260003
002610*/* "License"); you may not use this file except in compliance */ 00261003
002700*/* with the License. You may obtain a copy of the License at  */ 00270003
003000*/*                                                            */ 00300003
003100*/* http://www.apache.org/licenses/LICENSE-2.0                 */ 00310003
003110*/*                                                            */ 00311003
003300*/* Unless required by applicable law or agreed to in writing, */ 00330003
003400*/* software distributed under the License is distributed on an*/ 00340003
003500*/* "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY     */ 00350003
003510*/* KIND, either express or implied.  See the License for the  */ 00351003
003600*/* specific language governing permissions and limitations    */ 00360003
003700*/* under the License.                                         */ 00370003
003800*/*------------------------------------------------------------*/ 00380004
004402*/*                                                            */ 00440203
004410*/*   COPYRIGHT (C) 1993,2007 IBM CORPORATION                  */ 00441003
004420*/*   COPYRIGHT (C) 2007,2018 RICOH COMPANY, LTD               */ 00442003
004430*/*                                                            */ 00443003
004440*/*   Permission to use, copy, modify, and distribute          */ 00444003
004450*/*   this software for any purpose with or without fee        */ 00445003
004460*/*   is hereby granted, provided that the above               */ 00446003
004470*/*   copyright notices appear in all copies.                  */ 00447003
004480*/*                                                            */ 00448003
004490*/*   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY       */ 00449003
004491*/*   OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT       */ 00449103
004492*/*   LIMITED TO THE WARRANTIES OF MERCHANTABILITY,            */ 00449203
004493*/*   FITNESS FOR A PARTICULAR PURPOSE AND                     */ 00449303
004494*/*   NONINFRINGEMENT.  IN NO EVENT SHALL RICOH, RICOH         */ 00449403
004495*/*   SUBSIDIARIES, ANY OF ITS SUPPLIERS OR ANY OF THE         */ 00449503
004496*/*   OTHER COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,         */ 00449603
004497*/*   DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF      */ 00449703
004498*/*   CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF        */ 00449803
004499*/*   OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR         */ 00449903
004500*/*   OTHER DEALINGS IN THE SOFTWARE.                          */ 00450003
004510*/**************************************************************/ 00451003
004600 TITLE 'ACIF Sample Input Exit'.                                  00460000
004700 ENVIRONMENT DIVISION.                                            00470000
004800 CONFIGURATION SECTION.                                           00480000
004900 SOURCE-COMPUTER. IBM-370.                                        00490000
005000 OBJECT-COMPUTER. IBM-370.                                        00500000
005100     EJECT                                                        00510000
005200 DATA DIVISION.                                                   00520000
005300 WORKING-STORAGE SECTION.                                         00530000
005400 77  PGMNAME                 PIC X(8) VALUE 'ACIFIBDT'.           00540000
005500 77  ABND-PGM                PIC X(8) VALUE 'CEE3ABD'.            00550000
005600 77  ABEND-CODE              PIC 9(4) BINARY VALUE 12.            00560000
005700 77  AFPWRITE                PIC X(8) VALUE 'AFPWRITE'.           00570000
005800* The following are values for positions and lengths of items     00580000
005900* in the input lines.                                             00590000
006000 77  REPT-LEN                PIC 9(4) BINARY VALUE 3.             00600000
006100 77  DATE-LEN                PIC 9(4) BINARY VALUE 8.             00610000
006200 77  PAGE-DISP               PIC ZZ,ZZ9.                          00620000
006300 77  SF-CC-VALUE             PIC X.                               00630000
006400     88  SF-CC               VALUE X'5A'.                         00640000
006500     SKIP1                                                        00650000
006600 01  MISC-SAVED-DATA.                                             00660000
006700     05  FIRST-LINE-FLAG     PIC X VALUE LOW-VALUE.               00670000
006800         88 FIRST-LINE       VALUE HIGH-VALUE.                    00680000
006900         88 NOTFIRST-LINE    VALUE LOW-VALUE.                     00690000
007000     05  INSERT-FLAG         PIC X VALUE LOW-VALUE.               00700000
007100         88 INSERT-LINE      VALUE HIGH-VALUE.                    00710000
007200         88 NOINSERT-LINE    VALUE LOW-VALUE.                     00720000
007300     05  LINE-COUNT          PIC S9(8) BINARY VALUE ZERO.         00730000
007400     05  PAGE-COUNT          PIC S9(8) BINARY VALUE ZERO.         00740000
007500     SKIP2                                                        00750000
007600 01  RECORD-BUFFERS.                                              00760000
007700     05  SAVED-LINE-RECLEN   PIC 9(4) BINARY.                     00770000
007800     05  SAVED-LINE-BUFFER   PIC X(8192).                         00780000
007900     SKIP2                                                        00790000
008000/ AFP STRUCTURED FIELD DEFINITIONS.                               00800000
008110     COPY STRFLDS SUPPRESS.                                       00811002
008200/ PASSED PARAMETERS.                                              00820000
008300 LINKAGE SECTION.                                                 00830000
008400 01  INP-PARMS.                                                   00840000
008500     05  INP-USTOR           POINTER.                             00850000
008600     05  INP-PFATTR          POINTER.                             00860000
008700     05  INP-RECPTR          POINTER.                             00870000
008800     05  FILLER              POINTER.                             00880000
008900     05  INP-RECLEN          PIC 9(4) BINARY.                     00890000
009000     05  FILLER              PIC XX.                              00900000
009100     05  INP-REQUEST         PIC X.                               00910000
009200         88  INP-USE         VALUE X'00'.                         00920000
009300         88  INP-DELETE      VALUE X'01'.                         00930000
009400         88  INP-INSERT      VALUE X'02'.                         00940000
009500     05  INP-EOF-FLAG        PIC X.                               00950000
009600         88  INP-EOF         VALUE 'Y'.                           00960000
009700                                                                  00970000
009800 01  INP-UAREA               PIC X(16).                           00980000
009900                                                                  00990000
010000 01  INP-ATTR.                                                    01000000
010100     05  INP-CC              PIC XXX.                             01010000
010200     05  INP-CCTYPE          PIC X.                               01020000
010300         88  INP-ANSI-CC     VALUE 'A'.                           01030000
010400         88  INP-MACH-CC     VALUE 'M'.                           01040000
010500     05  INP-CHARS           PIC X(20).                           01050000
010600     05  INP-FORMDEF         PIC X(8).                            01060000
010700     05  INP-PAGEDEF         PIC X(8).                            01070000
010800     05  INP-PRMODE          PIC X(8).                            01080000
010900     05  INP-TRC             PIC XXX.                             01090000
011000     SKIP1                                                        01100000
011100* THIS IS THE BDT/EDT NOP RECORD. THE NOP DATA AREA MUST CONTAIN  01110000
011200* A VALID BDT/EDT STRUCTURED FIELD.                               01120000
011300 01  NOP-RECORD.                                                  01130000
011400     05  NOP-INTRODUCER.                                          01140000
011500       10  NOP-CC            PIC X.                               01150000
011600       10  NOP-LEN-CHR       PIC XX.                              01160000
011700       10  NOP-RECLEN        REDEFINES NOP-LEN-CHR                01170000
011800                             PIC 9(4) BINARY.                     01180000
011900       10  NOP-TYPE          PIC XXX.                             01190000
012000           88  NOP-BDT       VALUE X'D3A8A8'.                     01200000
012100           88  NOP-EDT       VALUE X'D3A9A8'.                     01210000
012200       10  NOP-FLAG          PIC X.                               01220000
012300       10  NOP-SEQ-CHR       PIC XX.                              01230000
012400       10  NOP-SEQNUM        REDEFINES NOP-SEQ-CHR                01240000
012500                             PIC 9(4) BINARY.                     01250000
012600     05  NOP-DATA.                                                01260000
012700       10  FILLER            PIC X.                               01270000
012800       10  NOP-XDT-LEN-CHR   PIC XX.                              01280000
012900       10  NOP-XDT-RECLEN    REDEFINES NOP-XDT-LEN-CHR            01290000
013000                             PIC 9(4) BINARY.                     01300000
013100       10  NOP-XDT-TYPE      PIC XXX.                             01310000
013200       10  NOP-ARRAY         OCCURS 0 TO 26597,                   01320000
013300                             DEPENDING ON NOP-RECLEN,             01330000
013400                             PIC X.                               01340000
013500     SKIP1                                                        01350000
013600 TITLE 'Initialization and Main Line'.                            01360000
013700 PROCEDURE DIVISION USING INP-PARMS.                              01370000
013800* make work area, attributes, and input line addressable.         01380000
013900     SET ADDRESS OF INP-UAREA TO INP-USTOR.                       01390000
014000     SET ADDRESS OF INP-ATTR TO INP-PFATTR.                       01400000
014100     SET ADDRESS OF NOP-RECORD TO INP-RECPTR.                     01410000
014200     MOVE ZERO TO RETURN-CODE.                                    01420000
014300* no special action is necessary at EOF.                          01430000
014400     IF INP-EOF                                                   01440000
014500      THEN                                                        01450000
014600       DISPLAY PGMNAME, ' EOF REACHED.';                          01460000
014700       MOVE PAGE-COUNT TO PAGE-DISP;                              01470000
014800       GOBACK;                                                    01480000
014900     END-IF.                                                      01490000
015000     IF NOP-BDT OR NOP-EDT                                        01500000
015100      THEN                                                        01510000
015200       CALL AFPWRITE USING SF-NOP,                                01520000
015300                           NOP-RECORD,                            01530000
015400                           INP-RECLEN,                            01540000
015500                           BY REFERENCE SAVED-LINE-RECLEN,        01550000
015600                           SAVED-LINE-BUFFER;                     01560000
015700       MOVE SAVED-LINE-RECLEN TO INP-RECLEN;                      01570000
015800       MOVE SAVED-LINE-BUFFER TO NOP-RECORD (1:SAVED-LINE-RECLEN);01580000
015900       SET INP-USE TO TRUE;                                       01590000
016000     SKIP1                                                        01600000
016100     GOBACK.                                                      01610000
016200     EJECT                                                        01620000
016300 TITLE 'FORMAT AFPDS RECORD'.                                     01630000
016400 ID DIVISION.                                                     01640000
016500* This routine takes the structured field type, data, and data    01650000
016600* length and formats an AFP record and places it in the           01660000
016700* exit's buffer.                                                  01670000
016800 PROGRAM-ID. AFPWRITE COMMON.                                     01680000
016900 DATA DIVISION.                                                   01690000
017000 WORKING-STORAGE SECTION.                                         01700000
017100 77  SF-CC                       PIC X VALUE X'5A'.               01710000
017200 LINKAGE SECTION.                                                 01720000
017300 01  AFP-TYPE                    PIC X(3).                        01730000
017400 01  AFP-DATA                    PIC X(8192).                     01740000
017500 01  AFP-DATA-LENGTH             PIC 9(4) BINARY.                 01750000
017600 01  AFP-INSERT-LEN              PIC 9(4) BINARY.                 01760000
017700     SKIP1                                                        01770000
017800 01  SF-RECORD.                                                   01780000
017900     05  SF-INTRODUCER.                                           01790000
018000         10 SF-INTRO-CC      PIC X.                               01800000
018100         10 SF-INTRO-LEN     PIC 9(4) BINARY.                     01810000
018200         10 SF-INTRO-TYPE    PIC X(3).                            01820000
018300         10 SF-INTRO-FLAG    PIC X.                               01830000
018400         10 SF-INTRO-SEQNUM  PIC 9(4) BINARY.                     01840000
018500     05  SF-DATA             PIC X(8192).                         01850000
018600 SKIP3                                                            01860000
018700 PROCEDURE DIVISION USING AFP-TYPE,                               01870000
018800                          AFP-DATA,                               01880000
018900                          AFP-DATA-LENGTH,                        01890000
019000                          AFP-INSERT-LEN,                         01900000
019100                          SF-RECORD.                              01910000
019200* set the final record length (introducer plus data), which is    01920000
019300* found in the introducer length field, move in the introducer    01930000
019400* and the data, then write the record.                            01940000
019500     ADD LENGTH OF SF-INTRODUCER, AFP-DATA-LENGTH GIVING          01950000
019600         AFP-INSERT-LEN.                                          01960000
019700     SUBTRACT 1 FROM AFP-INSERT-LEN GIVING SF-INTRO-LEN.          01970000
019800     MOVE SF-CC TO     SF-INTRO-CC.                               01980000
019900     MOVE AFP-TYPE TO SF-INTRO-TYPE.                              01990000
020000     MOVE LOW-VALUE TO SF-INTRO-FLAG.                             02000000
020100     MOVE ZERO TO      SF-INTRO-SEQNUM.                           02010000
020200     MOVE AFP-DATA (1 : AFP-DATA-LENGTH) TO SF-DATA               02020000
020300                                         (1 : AFP-DATA-LENGTH).   02030000
020400     EXIT PROGRAM.                                                02040000
020500 END PROGRAM AFPWRITE.                                            02050000
020600 SKIP1                                                            02060000
020700 END PROGRAM ACIFIBDT.                                            02070000