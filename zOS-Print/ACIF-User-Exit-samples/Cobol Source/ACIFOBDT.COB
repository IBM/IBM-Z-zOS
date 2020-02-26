000200 PROCESS DYNAM NUMPROC(PFD) TRUNC(OPT) APOST     NOSEQ            00020000
000210* LAST UPDATE ON 6 Apr 2018 AT 10:20:18 BY  HOWARDT VERSION 01   *00010003
000400 ID DIVISION.                                                     00040002
000500 PROGRAM-ID. ACIFOBDT.                                            00050002
000600 AUTHOR. TURETZKY--HYDRA.                                         00060002
000700 INSTALLATION. IBM BOULDER PROGRAMMING CENTER.                    00070002
000800                                                                  00080002
000900           This program is a sample exit for ACIF                 00090003
001000           (APKACIF,5648-062) demonstrating the use of the ACIF   00100003
001100           output exit in a simple print archive.                 00110003
001200                                                                  00120002
001300           In order to use this exit, include the control         00130002
001400           OUTEXIT=ACIFOBDT to enable this exit, and include      00140002
001500           the load module in a dataset referenced in STEPLIB     00150002
001600           or elsewhere in the module search order.               00160002
001700                                                                  00170002
001800           The program will change a flagged NOP to a BDT or      00180002
001900           EDT. The NOP must contain the content of the BDT/EDT   00190002
002000           to be inserted as the body of the NOP structured field.00200002
002100           If ACIF writes the output, the BDT will be             00210002
002200           removed from the output file, but will remain in       00220002
002300           the file for the output written by the exit.           00230002
002400           Because ACIF inserts a single BDT/EDT, this exit will  00240002
002500           remove the first and last BDT/EDT.                     00250002
002600                                                                  00260002
002700           This program must either be linked with CEEUOPT        00270003
002800           or ACIF must include the control statement             00280003
002900           EXTENSIONS = MVSICNV.                                  00290003
003000                                                                  00300002
003100 DATE-WRITTEN. 10 Dec 2000.                                       00310002
003200 DATE-COMPILED.                                                   00320002
003300 SECURITY. IBM SAMPLE CODE ONLY.                                  00330002
003400*/**************************************************************/ 00340003
003500*/*   COPYRIGHT (C) 1993,2007 IBM CORPORATION                  */ 00350003
003600*/*   COPYRIGHT (C) 2007,2018 RICOH COMPANY, LTD               */ 00360003
003700*/*                                                            */ 00370003
003800*/*   Permission to use, copy, modify, and distribute          */ 00380003
003900*/*   this software for any purpose with or without fee        */ 00390003
004000*/*   is hereby granted, provided that the above               */ 00400003
004100*/*   copyright notices appear in all copies.                  */ 00410003
004200*/*                                                            */ 00420003
004300*/*   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY       */ 00430003
004400*/*   OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT       */ 00440003
004500*/*   LIMITED TO THE WARRANTIES OF MERCHANTABILITY,            */ 00450003
004600*/*   FITNESS FOR A PARTICULAR PURPOSE AND                     */ 00460003
004700*/*   NONINFRINGEMENT.  IN NO EVENT SHALL RICOH, RICOH         */ 00470003
004800*/*   SUBSIDIARIES, ANY OF ITS SUPPLIERS OR ANY OF THE         */ 00480003
004900*/*   OTHER COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,         */ 00490003
005000*/*   DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF      */ 00500003
005100*/*   CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF        */ 00510003
005200*/*   OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR         */ 00520003
005300*/*   OTHER DEALINGS IN THE SOFTWARE.                          */ 00530003
005400*/**************************************************************/ 00540003
005500 TITLE 'ACIF Sample output Exit'.                                 00550002
005600 ENVIRONMENT DIVISION.                                            00560002
005700 CONFIGURATION SECTION.                                           00570002
005800 SOURCE-COMPUTER. IBM-370.                                        00580002
005900 OBJECT-COMPUTER. IBM-370.                                        00590002
006000 INPUT-OUTPUT SECTION.                                            00600002
006100 FILE-CONTROL.                                                    00610002
006200     SELECT AFPPAGOT-FILE        ASSIGN TO AFPPAGOT,              00620002
006300                                 ORGANIZATION SEQUENTIAL          00630002
006400                                 FILE STATUS AFPPAGOT-STATUS.     00640002
006500     EJECT                                                        00650002
006600 DATA DIVISION.                                                   00660002
006700 FILE SECTION.                                                    00670002
006800 FD  AFPPAGOT-FILE    GLOBAL,                                     00680002
006900     RECORDING MODE V,                                            00690002
007000     BLOCK CONTAINS 0 RECORDS,                                    00700002
007100     RECORD VARYING DEPENDING ON AFPPAGOT-LENGTH.                 00710002
007200 01  AFPPAGOT-RECORD.                                             00720002
007300     05  AFPPAGOT-INTRODUCER.                                     00730002
007400       10  AFPPAGOT-CC       PIC X.                               00740002
007500       10  AFPPAGOT-LEN-CHR  PIC XX.                              00750002
007600       10  AFPPAGOT-RECLEN   REDEFINES AFPPAGOT-LEN-CHR           00760002
007700                             PIC 9(4) BINARY.                     00770002
007800       10  AFPPAGOT-TYPE     PIC XXX.                             00780002
007900       10  AFPPAGOT-FLAG     PIC X.                               00790002
008000       10  AFPPAGOT-SEQ-CHR  PIC XX.                              00800002
008100       10  AFPPAGOT-SEQNUM   REDEFINES AFPPAGOT-SEQ-CHR           00810002
008200                             PIC 9(4) BINARY.                     00820002
008300     05  AFPPAGOT-DATA.                                           00830002
008400         10  AFPPAGOT-ARRAY      OCCURS 0 TO 32743,               00840002
008500                                 DEPENDING ON AFPPAGOT-RECLEN,    00850002
008600                                 INDEXED BY AFPPAGOT-INDX,        00860002
008700                                 PIC X.                           00870002
008800 WORKING-STORAGE SECTION.                                         00880002
008900 77  ABND-PGM                PIC X(8) VALUE 'CEE3ABD'.            00890002
009000 77  ABEND-CODE              PIC 9(4) BINARY VALUE 12.            00900002
009100 77  AFPWRITE                PIC X(8) VALUE 'AFPWRITE'.           00910002
009200 77  PAGE-COUNT              PIC S9(8) BINARY VALUE ZERO.         00920002
009300 77  LINE-COUNT              PIC S9(8) BINARY VALUE ZERO.         00930002
009400 77  AFPPAGOT-STATUS         PIC 99.                              00940002
009500     88  AFPPAGOT-OK         VALUE 00.                            00950002
009600 77  AFPPAGOT-EOF-FLAG       PIC X    VALUE LOW-VALUE.            00960002
009700     88  AFPPAGOT-EOF        VALUE HIGH-VALUE.                    00970002
009800 77  AFPPAGOT-ERROR-FLAG     PIC X    VALUE LOW-VALUE.            00980002
009900     88  AFPPAGOT-ERROR      VALUE HIGH-VALUE.                    00990002
010000     SKIP2                                                        01000002
010100 01  PGMNAME                 PIC X(8) VALUE 'ACIFOBDT' GLOBAL.    01010002
010200 01  AFPPAGOT-LENGTH         PIC 9(8) BINARY GLOBAL.              01020002
010300     SKIP2                                                        01030002
010400 01  DATE-DATA.                                                   01040002
010500   05  RUN-DATE.                                                  01050002
010600     10 RUN-YY                 PIC 99.                            01060002
010700     10 RUN-MM                 PIC 99.                            01070002
010800     10 RUN-DD                 PIC 99.                            01080002
010900   05  COMPILE-DATE.                                              01090002
011000     10  COMP-DATE             PIC X(8).                          01100002
011100     10  COMP-TIME             PIC X(12).                         01110002
011200   05  RUN-TIME.                                                  01120002
011300     10  RUN-HH                PIC 99.                            01130002
011400     10  RUN-MM                PIC 99.                            01140002
011500     10  RUN-SS                PIC 99.                            01150002
011600     10  RUN-MS                PIC 99.                            01160002
011700     SKIP2                                                        01170002
011800 01  BINARY-NUMBERS.                                              01180002
011900     05  BIN-4                   PIC 9(8) BINARY VALUE ZERO.      01190002
012000     05  BIN4-X                  REDEFINES BIN-4                  01200002
012100                                 PIC X(4).                        01210002
012200     05  BIN2                    PIC 9(4) BINARY VALUE ZERO.      01220002
012300     05  BIN2-X                  REDEFINES BIN2.                  01230002
012400         10  FILLER              PIC X.                           01240002
012500         10  BIN2-2              PIC X.                           01250002
012600     SKIP2                                                        01260002
012700 01  XDT-RECORD.                                                  01270002
012800     05  XDT-RECLEN          PIC 9(4) BINARY.                     01280002
012900     05  XDT-LINE            PIC X(32756).                        01290002
013000/ AFP STRUCTURED FIELD DEFINITIONS.                               01300002
013100     COPY STRFLDS SUPPRESS.                                       01310002
013200/ PASSED PARAMETERS.                                              01320002
013300 LINKAGE SECTION.                                                 01330002
013400 01  OUT-PARMS.                                                   01340002
013500     05  OUT-WORKA           POINTER.                             01350002
013600     05  OUT-PFATTR          POINTER.                             01360002
013700     05  OUT-RECPTR          POINTER.                             01370002
013800     05  OUT-RECLEN          PIC 9(4) BINARY.                     01380002
013900     05  OUT-REQUEST         PIC X.                               01390002
014000         88  OUT-USE         VALUE X'00'.                         01400002
014100         88  OUT-DELETE      VALUE X'01'.                         01410002
014200     05  OUT-EOF-FLAG        PIC X.                               01420002
014300         88  OUT-EOF         VALUE 'Y'.                           01430002
014400         88  OUT-NOTEOF      VALUE 'N'.                           01440002
014500                                                                  01450002
014600 01  OUT-UAREA.                                                   01460002
014700     05  AFPPAGOT-REC        PIC 9(8) BINARY.                     01470002
014800     05  OUT-FIRST-FLAG      PIC X.                               01480002
014900         88  OUT-FIRST       VALUE LOW-VALUE.                     01490002
015000         88  OUT-NOTFIRST    VALUE HIGH-VALUE.                    01500002
015100                                                                  01510002
015200 01  OUT-ATTR.                                                    01520002
015300     05  OUT-CC              PIC XXX.                             01530002
015400     05  OUT-CCTYPE          PIC X.                               01540002
015500         88  OUT-ANSI-CC     VALUE 'A'.                           01550002
015600         88  OUT-MACH-CC     VALUE 'M'.                           01560002
015700     05  OUT-CHARS           PIC X(20).                           01570002
015800     05  OUT-FORMDEF         PIC X(8).                            01580002
015900     05  OUT-PAGEDEF         PIC X(8).                            01590002
016000     05  OUT-PRMODE          PIC X(8).                            01600002
016100     05  OUT-TRC             PIC XXX.                             01610002
016200                                                                  01620002
016300* This is a template for the output record, pointed to by         01630002
016400* OUT-RECPTR. The record's actual length is given by              01640002
016500* OUT-RECLEN.                                                     01650002
016600 01  OUT-LINE.                                                    01660002
016700     05  OUT-CCVAL           PIC X.                               01670002
016800     05  OUT-SFINTRO.                                             01680002
016900         10  OUT-SFLEN       PIC 9(4) BINARY.                     01690002
017000         10  OUT-SFTYPE      PIC XXX.                             01700002
017100         10  OUT-SFFLAG      PIC X.                               01710002
017200         10  OUT-SFSEQ       PIC 9(4) BINARY.                     01720002
017300     05  OUT-SFDATA          PIC X(32751).                        01730002
017400     SKIP2                                                        01740002
017500* This is the BDT/EDT NOP record. the NOP data area must contain  01750002
017600* a valid BDT/EDT structured field.                               01760002
017700 01  NOP-RECORD.                                                  01770002
017800     05  NOP-INTRODUCER.                                          01780002
017900       10  NOP-CC            PIC X.                               01790002
018000       10  NOP-LEN-CHR       PIC XX.                              01800002
018100       10  NOP-RECLEN        REDEFINES NOP-LEN-CHR                01810002
018200                             PIC 9(4) BINARY.                     01820002
018300       10  NOP-TYPE          PIC XXX.                             01830002
018400       10  NOP-FLAG          PIC X.                               01840002
018500       10  NOP-SEQ-CHR       PIC XX.                              01850002
018600       10  NOP-SEQNUM        REDEFINES NOP-SEQ-CHR                01860002
018700                             PIC 9(4) BINARY.                     01870002
018800     05  NOP-DATA.                                                01880002
018900       10  FILLER            PIC X.                               01890002
019000       10  NOP-XDT-LEN-CHR   PIC XX.                              01900002
019100       10  NOP-XDT-RECLEN    REDEFINES NOP-XDT-LEN-CHR            01910002
019200                             PIC 9(4) BINARY.                     01920002
019300       10  NOP-XDT-TYPE      PIC XXX.                             01930002
019400           88  NOP-NOP-BDT   VALUE X'D3A8A8'.                     01940002
019500           88  NOP-NOP-EDT   VALUE X'D3A9A8'.                     01950002
019600       10  NOP-ARRAY         OCCURS 0 TO 26597,                   01960002
019700                             DEPENDING ON NOP-RECLEN,             01970002
019800                             PIC X.                               01980002
019900 TITLE 'Initialization and Main Line'.                            01990002
020000 PROCEDURE DIVISION USING OUT-PARMS.                              02000002
020100* make work area, attributes, and output line addressable.        02010002
020200     SET ADDRESS OF OUT-UAREA  TO OUT-WORKA.                      02020002
020300     SET ADDRESS OF OUT-ATTR   TO OUT-PFATTR.                     02030002
020400     SET ADDRESS OF OUT-LINE   TO OUT-RECPTR.                     02040002
020500     SET ADDRESS OF NOP-RECORD TO OUT-RECPTR.                     02050002
020600* no special action is necessary at EOF.                          02060002
020700     IF OUT-EOF                                                   02070002
020800      THEN                                                        02080002
020900       DISPLAY PGMNAME, ' EOF REACHED.';                          02090002
021000       GOBACK;                                                    02100002
021100     END-IF.                                                      02110002
021200     IF OUT-FIRST                                                 02120002
021300      THEN                                                        02130002
021400       SET OUT-NOTFIRST TO TRUE;                                  02140002
021500       MOVE WHEN-COMPILED TO COMPILE-DATE;                        02150002
021600       ACCEPT RUN-DATE FROM DATE;                                 02160002
021700       ACCEPT RUN-TIME FROM TIME;                                 02170002
021800       OPEN OUTPUT AFPPAGOT-FILE;                                 02180002
021900        SKIP2                                                     02190002
022000       IF NOT AFPPAGOT-OK THEN                                    02200002
022100          DISPLAY 'AFPPAGOT  STATUS AFTER OPEN ' AFPPAGOT-STATUS; 02210002
022200          DISPLAY ' ';                                            02220002
022300          MOVE AFPPAGOT-STATUS TO RETURN-CODE;                    02230002
022400          GOBACK;                                                 02240002
022500       END-IF;                                                    02250002
022600       MOVE ZERO TO AFPPAGOT-REC;                                 02260002
022700        SKIP2                                                     02270002
022800     END-IF.                                                      02280002
022900     SET OUT-USE TO TRUE.                                         02290002
023000     EVALUATE OUT-SFTYPE;                                         02300002
023100      WHEN SF-NOP                                                 02310002
023200* If this is the BDT/EDT NOP record, then change it to a real     02320002
023300* BDT/EDT. All other NOPs are written to the output file unchanged02330002
023400       PERFORM 0200-MAKE-BDTEDT;                                  02340002
023500      WHEN SF-BDT                                                 02350002
023600      WHEN SF-EDT                                                 02360002
023700* ACIF generates a BDT that should remain in the ACIF output      02370002
023800* file, but should be removed from the AFPPAGOT output.           02380002
023900        CONTINUE;                                                 02390002
024000      WHEN SF-BPG                                                 02400002
024100       ADD 1 TO PAGE-COUNT;                                       02410002
024200       MOVE 0 TO LINE-COUNT;                                      02420002
024300       CALL AFPWRITE USING OUT-LINE, OUT-RECLEN;                  02430002
024400      WHEN OTHER                                                  02440002
024500       ADD 1 TO LINE-COUNT;                                       02450002
024600       MOVE LINE-COUNT TO OUT-SFSEQ;                              02460002
024700       CALL AFPWRITE USING OUT-LINE, OUT-RECLEN;                  02470002
024800     END-EVALUATE.                                                02480002
024900     SKIP1                                                        02490002
025000     GOBACK.                                                      02500002
025100     SKIP2                                                        02510002
025200 0200-MAKE-BDTEDT.                                                02520002
025300* Change the NOP in the datastream to an BDT or EDT.              02530002
025400* The NOP SFI is removed from the record. The remaining           02540002
025500* data is assumed to be a valid BDT/EDT.                          02550002
025600     IF NOP-NOP-BDT OR NOP-NOP-EDT                                02560002
025700      THEN                                                        02570002
025800*      DISPLAY PGMNAME, ' OUT-RECLEN ', OUT-RECLEN,               02580002
025900*              ' NOP-XDT-RECLEN ', NOP-XDT-RECLEN,                02590002
026000*              ' NOP-RECORD ', NOP-RECORD;                        02600002
026100       COMPUTE XDT-RECLEN = NOP-XDT-RECLEN + 1;                   02610002
026200       MOVE NOP-DATA (1:NOP-XDT-RECLEN) TO XDT-LINE;              02620002
026300       CALL AFPWRITE USING XDT-LINE, XDT-RECLEN;                  02630002
026400      ELSE                                                        02640002
026500* NOPs not containing BDT/EDT are copied to output.               02650002
026600       CALL AFPWRITE USING OUT-LINE, OUT-RECLEN;                  02660002
026700     END-IF.                                                      02670002
026800 TITLE 'WRITE AFPDS RECORD TO FILE'.                              02680002
026900 ID DIVISION.                                                     02690002
027000* This routine writes a record to the exit's output file,         02700002
027100* AFPPAGOT.                                                       02710002
027200 PROGRAM-ID. AFPWRITE COMMON.                                     02720002
027300 DATA DIVISION.                                                   02730002
027400 WORKING-STORAGE SECTION.                                         02740002
027500 77  AFPPAGOT-STATUS         PIC 99.                              02750002
027600 LINKAGE SECTION.                                                 02760002
027700 01  AFP-DATA                    PIC X(32756).                    02770002
027800 01  AFP-DATA-LENGTH             PIC 9(4) BINARY.                 02780002
027900 SKIP3                                                            02790002
028000 PROCEDURE DIVISION USING AFP-DATA,                               02800002
028100                          AFP-DATA-LENGTH.                        02810002
028200     MOVE AFP-DATA-LENGTH TO AFPPAGOT-LENGTH.                     02820002
028300     WRITE AFPPAGOT-RECORD FROM AFP-DATA,                         02830002
028400       INVALID KEY                                                02840002
028500        DISPLAY PGMNAME, ' OUTPUT ERROR, FILE STATUS: ',          02850002
028600                AFPPAGOT-STATUS,                                  02860002
028700                MOVE AFPPAGOT-STATUS TO RETURN-CODE;              02870002
028800     END-WRITE.                                                   02880002
028900 END PROGRAM AFPWRITE.                                            02890002
029000     SKIP1                                                        02900002
029100 END PROGRAM ACIFOBDT.                                            02910002
