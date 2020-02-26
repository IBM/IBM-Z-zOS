000100 PROCESS DYNAM NUMPROC(PFD) TRUNC(OPT)           NOSEQ     RENT
000200* LAST UPDATE ON 9 Apr 2018 AT 15:37:17 BY  HOWARDT VERSION 01   *
000300 ID DIVISION.
000400 PROGRAM-ID. ACSTCHR.
000500 AUTHOR. TURETZKY--HYDRA.
000600 INSTALLATION. IBM BOULDER PROGRAMMING CENTER.
000700               This program is a sample exit for ACIF
000800               (APKACIF,5648-062) demonstrating the use of the
000900               ACIF input exit.
001000
001100               In order to use this exit, include the control
001200               INPEXIT=ACSTCHR to enable this exit, and include
001300               the load module in a dataset referenced in STEPLIB
001400               or elsewhere in the module search order.
001500
001600               This program strips the first character of each
001700               record in the input file, provided it is the
001800               character zero. Records are passed into the exit,
001900               the first byte is tested for zero, and the record
002000               returned with the length adjusted.
002100
002200               This program must either be compiled with the
002300               NORENT option or linked with IGZOPT with the
002400               RTEREUS option.  (See VS COBOL II Application
002500               Programming Guide, SC26-4045).
002600
002700 DATE-WRITTEN. 11 May 98.
002800 DATE-COMPILED.
002900 SECURITY. IBM SAMPLE CODE ONLY.
003000*/**************************************************************/
003100*/*   COPYRIGHT (C) 1993,2007 IBM CORPORATION                  */
003200*/*   COPYRIGHT (C) 2007,2018 RICOH COMPANY, LTD               */
003300*/*                                                            */
003400*/*   Permission to use, copy, modify, and distribute          */
003500*/*   this software for any purpose with or without fee        */
003600*/*   is hereby granted, provided that the above               */
003700*/*   copyright notices appear in all copies.                  */
003800*/*                                                            */
003900*/*   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY       */
004000*/*   OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT       */
004100*/*   LIMITED TO THE WARRANTIES OF MERCHANTABILITY,            */
004200*/*   FITNESS FOR A PARTICULAR PURPOSE AND                     */
004300*/*   NONINFRINGEMENT.  IN NO EVENT SHALL RICOH, RICOH         */
004400*/*   SUBSIDIARIES, ANY OF ITS SUPPLIERS OR ANY OF THE         */
004500*/*   OTHER COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,         */
004600*/*   DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF      */
004700*/*   CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF        */
004800*/*   OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR         */
004900*/*   OTHER DEALINGS IN THE SOFTWARE.                          */
005000*/**************************************************************/
005100 TITLE 'ACIF Strip Character Input Exit'.
005200 ENVIRONMENT DIVISION.
005300 CONFIGURATION SECTION.
005400 SOURCE-COMPUTER. IBM-370.
005500 OBJECT-COMPUTER. IBM-370.
005600     EJECT
005700 DATA DIVISION.
005800 WORKING-STORAGE SECTION.
005900 77  PGMNAME                 PIC X(8) VALUE 'ACSTCHR'.
006000 77  ABND-PGM                PIC X(8) VALUE 'CEE3DMP'.            !@01
006100 77  ABEND-CODE              PIC 9(4) BINARY VALUE 12.
006110 77  ABEND-OPTS              PIC X(255)                           !@01
006120     VALUE 'ENC(CUR) THR(CUR) FILE VAR NOBLOCK NOSTOR SF(ALL)' .  !@01
006200 77  AFPWRITE                PIC X(8) VALUE 'AFPWRITE'.
006300 77  ACSTCHR-LENGTH          PIC 9(8) BINARY VALUE ZERO.
006400 01  GLOBAL-VARIABLES            GLOBAL.
006500     05  ACSTCHR-IN-STATUS       PIC 99   VALUE ZERO.
006600         88  ACSTCHR-IN-OK       VALUE 00.
006700         88  ACSTCHR-IN-EOF      VALUE 10.
006800/ PASSED PARAMETERS.
006900 LINKAGE SECTION.
007000 01  INP-PARMS.
007100     05  INP-USTOR           POINTER.
007200     05  INP-PFATTR          POINTER.
007300     05  INP-RECPTR          POINTER.
007400     05  FILLER              POINTER.
007500     05  INP-RECLEN          PIC 9(4) BINARY.
007600     05  FILLER              PIC XX.
007700     05  INP-REQUEST         PIC X.
007800         88  INP-USE         VALUE X'00'.
007900         88  INP-DELETE      VALUE X'01'.
008000         88  INP-INSERT      VALUE X'02'.
008100     05  INP-EOF-FLAG        PIC X.
008200         88  INP-EOF         VALUE 'Y'.
008300
008400 01  INP-UAREA.
008500     05  UAREA-CHGCNT        PIC 9(8) BINARY.
008600     05  UAREA-RECCNT        PIC 9(8) BINARY.
008700     05  INIT-FLAG           PIC X.
008800         88 INITTED          VALUE HIGH-VALUE.
008900         88 NOT-INITTED      VALUE LOW-VALUE.
009000     05  FILLER              PIC X(07).
009100
009200 01  INP-ATTR.
009300     05  INP-CC              PIC XXX.
009400     05  INP-CCTYPE          PIC X.
009500         88  INP-ANSI-CC     VALUE 'A'.
009600         88  INP-MACH-CC     VALUE 'M'.
009700     05  INP-CHARS           PIC X(20).
009800     05  INP-FORMDEF         PIC X(8).
009900     05  INP-PAGEDEF         PIC X(8).
010000     05  INP-PRMODE          PIC X(8).
010100     05  INP-TRC             PIC XXX.
010200
010300* This is a template for the input record, pointed to by
010400* INP-RECPTR. The record's actual length is given by
010500* INP-RECLEN.
010600 01  INP-LINE.
010700     05  INP-BYTE1           PIC X.
010800     05  INP-CCVAL           PIC X.
010900     05  INP-TRCVAL          PIC X.
011000     05  INP-DATA            PIC X(32750).
011100* This is the returned record. It is pointed to by INP-RECPTR.
011200*The length is given by the adusted value of INP-RECLEN.
011300 01  INP-NEWLINE.
011400     05  INP-CCVAL           PIC X.
011500     05  INP-TRCVAL          PIC X.
011600     05  INP-DATA            PIC X(32750).
011700     SKIP1
011800 TITLE 'Initialization and Main Line'.
011900 PROCEDURE DIVISION USING INP-PARMS.
012000* make work area, attributes, and input line addressable.
012100     SET ADDRESS OF INP-UAREA TO INP-USTOR.
012200     SET ADDRESS OF INP-ATTR TO INP-PFATTR.
012300     SET ADDRESS OF INP-LINE TO INP-RECPTR.
012400     SET ADDRESS OF INP-NEWLINE TO INP-RECPTR.
012500* First time through, reset counters and first-time flag in the
012600*ACIF user area.
012700     IF NOT-INITTED
012800      THEN
012900       SET INITTED TO TRUE;
013000       MOVE ZERO TO UAREA-CHGCNT, UAREA-RECCNT;
013100     END-IF.
013200* no special action is necessary at EOF.
013300     IF INP-EOF
013400      THEN
013500       DISPLAY PGMNAME, ' EOF REACHED.';
013600       DISPLAY PGMNAME, UAREA-CHGCNT, ' RECORDS CHANGED OF ',
013700               UAREA-RECCNT;
013800       GOBACK;
013900     END-IF.
014000     ADD 1 TO UAREA-RECCNT.
014100     SKIP1
014200* If the first byte is a zero, shift the record left one byte
014300*by moving it over itself in the buffer.
014400*Adjust the returned record length.
014500     IF INP-BYTE1 = ZERO
014600      THEN
014700       SUBTRACT 1 FROM INP-RECLEN;
014800       MOVE INP-LINE (2 : INP-RECLEN) TO INP-NEWLINE;
014900       ADD 1 TO UAREA-CHGCNT;
015000     END-IF.
015100* Indicate that record passed to exit will be returned.
015200     SET INP-USE TO TRUE.
015300     SKIP1
015400     GOBACK.
