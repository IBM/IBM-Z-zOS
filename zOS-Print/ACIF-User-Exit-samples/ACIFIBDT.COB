000100 PROCESS DYNAM NUMPROC(PFD) TRUNC(OPT) APOST     NOSEQ            00010012
000200* LAST UPDATE ON 9 Apr 2018 AT 16:12:16 BY  HOWARDT VERSION 01   *00020012
000300 ID DIVISION.                                                     00030008
000400 PROGRAM-ID. ACIFIBDT.                                            00040008
000500 AUTHOR. TURETZKY--IBM PSD.                                       00050008
000600 INSTALLATION. IBM BOULDER PROGRAMMING CENTER.                    00060008
000700               This program is a sample exit for ACIF             00070011
000800               (APKACIF,5648-062) demonstrating the use of the    00080011
000900               ACIF input exit.                                   00090011
001000                                                                  00100008
001100               In order to use this exit, include the control     00110008
001200               INPEXIT=ACIFIBDT to enable this exit, and include  00120008
001300               the load module in a dataset referenced in STEPLIB 00130008
001400               or elsewhere in the module search order.           00140008
001500                                                                  00150008
001600               This program will convert all BDT/EDT structured   00160008
001700               fields to NOPs containing the original structured  00170008
001800               field, which will be turned back into BDT/EDT by   00180008
001900               ACIFOBDT.                                          00190008
002000                                                                  00200008
002100                                                                  00210008
002200 DATE-WRITTEN. 10 Dec 2000.                                       00220008
002300 DATE-COMPILED.                                                   00230008
002400 SECURITY. IBM SAMPLE CODE ONLY.                                  00240008
002500*/**************************************************************/ 00250011
002600*/*   COPYRIGHT (C) 1993,2007 IBM CORPORATION                  */ 00260011
002700*/*   COPYRIGHT (C) 2007,2018 RICOH COMPANY, LTD               */ 00270011
002800*/*                                                            */ 00280011
002900*/*   Permission to use, copy, modify, and distribute          */ 00290011
003000*/*   this software for any purpose with or without fee        */ 00300011
003100*/*   is hereby granted, provided that the above               */ 00310011
003200*/*   copyright notices appear in all copies.                  */ 00320011
003300*/*                                                            */ 00330011
003400*/*   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY       */ 00340011
003500*/*   OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT       */ 00350011
003600*/*   LIMITED TO THE WARRANTIES OF MERCHANTABILITY,            */ 00360011
003700*/*   FITNESS FOR A PARTICULAR PURPOSE AND                     */ 00370011
003800*/*   NONINFRINGEMENT.  IN NO EVENT SHALL RICOH, RICOH         */ 00380011
003900*/*   SUBSIDIARIES, ANY OF ITS SUPPLIERS OR ANY OF THE         */ 00390011
004000*/*   OTHER COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,         */ 00400011
004100*/*   DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF      */ 00410011
004200*/*   CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF        */ 00420011
004300*/*   OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR         */ 00430011
004400*/*   OTHER DEALINGS IN THE SOFTWARE.                          */ 00440011
004500*/**************************************************************/ 00450011
004600 TITLE 'ACIF Sample Input Exit'.                                  00460008
004700 ENVIRONMENT DIVISION.                                            00470008
004800 CONFIGURATION SECTION.                                           00480008
004900 SOURCE-COMPUTER. IBM-370.                                        00490008
005000 OBJECT-COMPUTER. IBM-370.                                        00500008
005100     EJECT                                                        00510008
005200 DATA DIVISION.                                                   00520008
005300 WORKING-STORAGE SECTION.                                         00530008
005400 77  PGMNAME                 PIC X(8) VALUE 'ACIFIBDT'.           00540008
005500 77  ABND-PGM                PIC X(8) VALUE 'CEE3ABD'.            00550008
005600 77  ABEND-CODE              PIC 9(4) BINARY VALUE 12.            00560008
005700 77  AFPWRITE                PIC X(8) VALUE 'AFPWRITE'.           00570008
005800* The following are values for positions and lengths of items     00580008
005900* in the input lines.                                             00590008
006000 77  REPT-LEN                PIC 9(4) BINARY VALUE 3.             00600008
006100 77  DATE-LEN                PIC 9(4) BINARY VALUE 8.             00610008
006200 77  PAGE-DISP               PIC ZZ,ZZ9.                          00620008
006300 77  SF-CC-VALUE             PIC X.                               00630008
006400     88  SF-CC               VALUE X'5A'.                         00640008
006500     SKIP1                                                        00650008
006600 01  MISC-SAVED-DATA.                                             00660008
006700     05  FIRST-LINE-FLAG     PIC X VALUE LOW-VALUE.               00670008
006800         88 FIRST-LINE       VALUE HIGH-VALUE.                    00680008
006900         88 NOTFIRST-LINE    VALUE LOW-VALUE.                     00690008
007000     05  INSERT-FLAG         PIC X VALUE LOW-VALUE.               00700008
007100         88 INSERT-LINE      VALUE HIGH-VALUE.                    00710008
007200         88 NOINSERT-LINE    VALUE LOW-VALUE.                     00720008
007300     05  LINE-COUNT          PIC S9(8) BINARY VALUE ZERO.         00730008
007400     05  PAGE-COUNT          PIC S9(8) BINARY VALUE ZERO.         00740008
007500     SKIP2                                                        00750008
007600 01  RECORD-BUFFERS.                                              00760008
007700     05  SAVED-LINE-RECLEN   PIC 9(4) BINARY.                     00770008
007800     05  SAVED-LINE-BUFFER   PIC X(8192).                         00780008
007900     SKIP2                                                        00790008
008000/ AFP STRUCTURED FIELD DEFINITIONS.                               00800008
008100     COPY STRFLDS SUPPRESS.                                       00810008
008200/ PASSED PARAMETERS.                                              00820008
008300 LINKAGE SECTION.                                                 00830008
008400 01  INP-PARMS.                                                   00840008
008500     05  INP-USTOR           POINTER.                             00850008
008600     05  INP-PFATTR          POINTER.                             00860008
008700     05  INP-RECPTR          POINTER.                             00870008
008800     05  FILLER              POINTER.                             00880008
008900     05  INP-RECLEN          PIC 9(4) BINARY.                     00890008
009000     05  FILLER              PIC XX.                              00900008
009100     05  INP-REQUEST         PIC X.                               00910008
009200         88  INP-USE         VALUE X'00'.                         00920008
009300         88  INP-DELETE      VALUE X'01'.                         00930008
009400         88  INP-INSERT      VALUE X'02'.                         00940008
009500     05  INP-EOF-FLAG        PIC X.                               00950008
009600         88  INP-EOF         VALUE 'Y'.                           00960008
009700                                                                  00970008
009800 01  INP-UAREA               PIC X(16).                           00980008
009900                                                                  00990008
010000 01  INP-ATTR.                                                    01000008
010100     05  INP-CC              PIC XXX.                             01010008
010200     05  INP-CCTYPE          PIC X.                               01020008
010300         88  INP-ANSI-CC     VALUE 'A'.                           01030008
010400         88  INP-MACH-CC     VALUE 'M'.                           01040008
010500     05  INP-CHARS           PIC X(20).                           01050008
010600     05  INP-FORMDEF         PIC X(8).                            01060008
010700     05  INP-PAGEDEF         PIC X(8).                            01070008
010800     05  INP-PRMODE          PIC X(8).                            01080008
010900     05  INP-TRC             PIC XXX.                             01090008
011000     SKIP1                                                        01100008
011100* THIS IS THE BDT/EDT NOP RECORD. THE NOP DATA AREA MUST CONTAIN  01110008
011200* A VALID BDT/EDT STRUCTURED FIELD.                               01120008
011300 01  NOP-RECORD.                                                  01130008
011400     05  NOP-INTRODUCER.                                          01140008
011500       10  NOP-CC            PIC X.                               01150008
011600       10  NOP-LEN-CHR       PIC XX.                              01160008
011700       10  NOP-RECLEN        REDEFINES NOP-LEN-CHR                01170008
011800                             PIC 9(4) BINARY.                     01180008
011900       10  NOP-TYPE          PIC XXX.                             01190008
012000           88  NOP-BDT       VALUE X'D3A8A8'.                     01200008
012100           88  NOP-EDT       VALUE X'D3A9A8'.                     01210008
012200       10  NOP-FLAG          PIC X.                               01220008
012300       10  NOP-SEQ-CHR       PIC XX.                              01230008
012400       10  NOP-SEQNUM        REDEFINES NOP-SEQ-CHR                01240008
012500                             PIC 9(4) BINARY.                     01250008
012600     05  NOP-DATA.                                                01260008
012700       10  FILLER            PIC X.                               01270008
012800       10  NOP-XDT-LEN-CHR   PIC XX.                              01280008
012900       10  NOP-XDT-RECLEN    REDEFINES NOP-XDT-LEN-CHR            01290008
013000                             PIC 9(4) BINARY.                     01300008
013100       10  NOP-XDT-TYPE      PIC XXX.                             01310008
013200       10  NOP-ARRAY         OCCURS 0 TO 26597,                   01320008
013300                             DEPENDING ON NOP-RECLEN,             01330008
013400                             PIC X.                               01340008
013500     SKIP1                                                        01350008
013600 TITLE 'Initialization and Main Line'.                            01360008
013700 PROCEDURE DIVISION USING INP-PARMS.                              01370008
013800* make work area, attributes, and input line addressable.         01380008
013900     SET ADDRESS OF INP-UAREA TO INP-USTOR.                       01390008
014000     SET ADDRESS OF INP-ATTR TO INP-PFATTR.                       01400008
014100     SET ADDRESS OF NOP-RECORD TO INP-RECPTR.                     01410008
014200     MOVE ZERO TO RETURN-CODE.                                    01420008
014300* no special action is necessary at EOF.                          01430008
014400     IF INP-EOF                                                   01440008
014500      THEN                                                        01450008
014600       DISPLAY PGMNAME, ' EOF REACHED.';                          01460008
014700       MOVE PAGE-COUNT TO PAGE-DISP;                              01470008
014800       GOBACK;                                                    01480008
014900     END-IF.                                                      01490008
015000     IF NOP-BDT OR NOP-EDT                                        01500008
015100      THEN                                                        01510008
015200       CALL AFPWRITE USING SF-NOP,                                01520008
015300                           NOP-RECORD,                            01530008
015400                           INP-RECLEN,                            01540008
015500                           BY REFERENCE SAVED-LINE-RECLEN,        01550008
015600                           SAVED-LINE-BUFFER;                     01560008
015700       MOVE SAVED-LINE-RECLEN TO INP-RECLEN;                      01570008
015800       MOVE SAVED-LINE-BUFFER TO NOP-RECORD (1:SAVED-LINE-RECLEN);01580008
015900       SET INP-USE TO TRUE;                                       01590008
016000     SKIP1                                                        01600008
016100     GOBACK.                                                      01610008
016200     EJECT                                                        01620008
016300 TITLE 'FORMAT AFPDS RECORD'.                                     01630008
016400 ID DIVISION.                                                     01640008
016500* This routine takes the structured field type, data, and data    01650008
016600* length and formats an AFP record and places it in the           01660008
016700* exit's buffer.                                                  01670008
016800 PROGRAM-ID. AFPWRITE COMMON.                                     01680008
016900 DATA DIVISION.                                                   01690008
017000 WORKING-STORAGE SECTION.                                         01700008
017100 77  SF-CC                       PIC X VALUE X'5A'.               01710008
017200 LINKAGE SECTION.                                                 01720008
017300 01  AFP-TYPE                    PIC X(3).                        01730008
017400 01  AFP-DATA                    PIC X(8192).                     01740008
017500 01  AFP-DATA-LENGTH             PIC 9(4) BINARY.                 01750008
017600 01  AFP-INSERT-LEN              PIC 9(4) BINARY.                 01760008
017700     SKIP1                                                        01770008
017800 01  SF-RECORD.                                                   01780008
017900     05  SF-INTRODUCER.                                           01790008
018000         10 SF-INTRO-CC      PIC X.                               01800008
018100         10 SF-INTRO-LEN     PIC 9(4) BINARY.                     01810008
018200         10 SF-INTRO-TYPE    PIC X(3).                            01820008
018300         10 SF-INTRO-FLAG    PIC X.                               01830008
018400         10 SF-INTRO-SEQNUM  PIC 9(4) BINARY.                     01840008
018500     05  SF-DATA             PIC X(8192).                         01850008
018600 SKIP3                                                            01860008
018700 PROCEDURE DIVISION USING AFP-TYPE,                               01870008
018800                          AFP-DATA,                               01880008
018900                          AFP-DATA-LENGTH,                        01890008
019000                          AFP-INSERT-LEN,                         01900008
019100                          SF-RECORD.                              01910008
019200* set the final record length (introducer plus data), which is    01920008
019300* found in the introducer length field, move in the introducer    01930008
019400* and the data, then write the record.                            01940008
019500     ADD LENGTH OF SF-INTRODUCER, AFP-DATA-LENGTH GIVING          01950008
019600         AFP-INSERT-LEN.                                          01960008
019700     SUBTRACT 1 FROM AFP-INSERT-LEN GIVING SF-INTRO-LEN.          01970008
019800     MOVE SF-CC TO     SF-INTRO-CC.                               01980008
019900     MOVE AFP-TYPE TO SF-INTRO-TYPE.                              01990008
020000     MOVE LOW-VALUE TO SF-INTRO-FLAG.                             02000008
020100     MOVE ZERO TO      SF-INTRO-SEQNUM.                           02010008
020200     MOVE AFP-DATA (1 : AFP-DATA-LENGTH) TO SF-DATA               02020008
020300                                         (1 : AFP-DATA-LENGTH).   02030008
020400     EXIT PROGRAM.                                                02040008
020500 END PROGRAM AFPWRITE.                                            02050008
020600 SKIP1                                                            02060008
020700 END PROGRAM ACIFIBDT.                                            02070008
