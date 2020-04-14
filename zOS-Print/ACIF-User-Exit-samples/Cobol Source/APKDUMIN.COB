000100 PROCESS NUMPROC(PFD) TRUNC(OPT) APOST NOSEQ NOLIST
000200* LAST UPDATE ON 5 Apr 2018 AT 15:52:20 BY  HOWARDT VERSION 01   *
000300 ID DIVISION.
000400 PROGRAM-ID. APKDUMIN.
000500 AUTHOR. TURETZKY--HYDRA.
000600 INSTALLATION. IBM BOULDER PROGRAMMING CENTER.
000700               Test LE ACIF exits.          This program is a
000800               sample exit for ACIF (APKACIF,5648-062)
000900               demonstrating the use of the ACIF input exit.
001000
001100               In order to use this exit, include the control
001200               INPEXIT=APKDUMIN to enable this exit, and include
001300               the load module in a dataset referenced in STEPLIB
001400               or elsewhere in the module search order.
001500
001600               The program is used to test the input exit. It will
001700               simply return after each call from an ACIF exit.
001800
001900 DATE-WRITTEN. 04 DEC 2017.
002000 DATE-COMPILED.
002100 SECURITY. IBM SAMPLE CODE ONLY.
002200 TITLE 'ACIF Test Input Exit'.
002300*/**************************************************************/
002400*/* LICENSED UNDER THE APACHE LICENSE, VERSION 2.0 (THE        */
002500*/* "LICENSE"); YOU MAY NOT USE THIS FILE EXCEPT IN COMPLIANCE */
002600*/* WITH THE LICENSE. YOU MAY OBTAIN A COPY OF THE LICENSE AT  */
002700*/*                                                            */
002800*/* HTTP://WWW.APACHE.ORG/LICENSES/LICENSE-2.0                 */
002900*/*                                                            */
003000*/* UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING, */
003100*/* SOFTWARE DISTRIBUTED UNDER THE LICENSE IS DISTRIBUTED ON AN*/
003200*/* "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY     */
003300*/* KIND, EITHER EXPRESS OR IMPLIED.  SEE THE LICENSE FOR THE  */
003400*/* SPECIFIC LANGUAGE GOVERNING PERMISSIONS AND LIMITATIONS    */
003500*/* UNDER THE LICENSE.                                         */
003600*/*------------------------------------------------------------*/
003700*/*                                                            */
004410*/*   COPYRIGHT (C) 1993,2007 IBM CORPORATION                  */
004420*/*   COPYRIGHT (C) 2007,2018 RICOH COMPANY, LTD               */
004430*/*                                                            */
004440*/*   Permission to use, copy, modify, and distribute          */
004450*/*   this software for any purpose with or without fee        */
004460*/*   is hereby granted, provided that the above               */
004470*/*   copyright notices appear in all copies.                  */
004480*/*                                                            */
004490*/*   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY       */
004491*/*   OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT       */
004492*/*   LIMITED TO THE WARRANTIES OF MERCHANTABILITY,            */
004493*/*   FITNESS FOR A PARTICULAR PURPOSE AND                     */
004494*/*   NONINFRINGEMENT.  IN NO EVENT SHALL RICOH, RICOH         */
004495*/*   SUBSIDIARIES, ANY OF ITS SUPPLIERS OR ANY OF THE         */
004496*/*   OTHER COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,         */
004497*/*   DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF      */
004498*/*   CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF        */
004499*/*   OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR         */
004500*/*   OTHER DEALINGS IN THE SOFTWARE.                          */
004510*/**************************************************************/
004400 ENVIRONMENT DIVISION.
004500 CONFIGURATION SECTION.
004600 SOURCE-COMPUTER. IBM-370.
004700 OBJECT-COMPUTER. IBM-370.
004800     EJECT
004900 DATA DIVISION.
005000 WORKING-STORAGE SECTION.
005100 77  PGMNAME                 PIC X(8) VALUE 'APKINPTS'.
005200 77  ABND-PGM                PIC X(8) VALUE 'CEE3DMP'.            !@01
005300 77  ABEND-CODE              PIC 9(4) BINARY VALUE 12.
005400 77  ABEND-OPTS              PIC X(255)                           !@01
005500     VALUE 'ENC(CUR) THR(CUR) FILE VAR NOBLOCK NOSTOR SF(ALL)' .  !@01
005600 77  AFPWRITE                PIC X(8) VALUE 'AFPWRITE'.
005700 77  DIV-BY-ZERO             PIC 9(8) BINARY VALUE ZERO.
005800 77  PAGE-COUNT              PIC 9(8) BINARY VALUE ZERO.
005900 77  LINE-COUNT              PIC 9(8) BINARY VALUE ZERO.
006000 77  EOF-LIT                 PIC X(9) VALUE 'AFTER EOF'.
006100 77  FIRST-LINE-FLAG         PIC X VALUE LOW-VALUE.
006200     88  FIRST-LINE          VALUE HIGH-VALUE.
006300     88  NOTFIRST-LINE       VALUE LOW-VALUE.
006400     SKIP2
006500/ PASSED PARAMETERS.
006600 LINKAGE SECTION.
006700 01  INP-PARMS.
006800     05  INP-USTOR           POINTER.
006900     05  INP-PFATTR          POINTER.
007000     05  INP-RECPTR          POINTER.
007100     05  FILLER              POINTER.
007200     05  INP-RECLEN          PIC 9(4) BINARY.
007300     05  FILLER              PIC XX.
007400     05  INP-REQUEST         PIC X.
007500         88  INP-USE         VALUE X'00'.
007600         88  INP-DELETE      VALUE X'01'.
007700         88  INP-INSERT      VALUE X'02'.
007800     05  INP-EOF-FLAG        PIC X.
007900         88  INP-EOF         VALUE 'Y'.
008000
008100 01  INP-UAREA.
008200     05  UAREA-CNTR          PIC 9(4) BINARY.
008300     05  UAREA-INSCOUNT      PIC 9(4) BINARY.
008400     05  INSERT-FLAG         PIC X.
008500         88 INSERT-LINE      VALUE HIGH-VALUE.
008600         88 INSERT-MULTIPLE  VALUE 'M'.
008700         88 NOINSERT-LINE    VALUE LOW-VALUE.
008800     05  FILLER              PIC X(12).
008900
009000 01  INP-ATTR.
009100     05  INP-CC              PIC XXX.
009200     05  INP-CCTYPE          PIC X.
009300         88  INP-ANSI-CC     VALUE 'A'.
009400         88  INP-MACH-CC     VALUE 'M'.
009500     05  INP-CHARS           PIC X(20).
009600     05  INP-FORMDEF         PIC X(8).
009700     05  INP-PAGEDEF         PIC X(8).
009800     05  INP-PRMODE          PIC X(8).
009900     05  INP-TRC             PIC XXX.
010000
010100* This is a template for the input record, pointed to by
010200* INP-RECPTR. The record's actual length is given by
010300* INP-RECLEN.
010400 01  INP-LINE.
010500     05  INP-CCVAL           PIC X.
010600     05  INP-TRCVAL          PIC X.
010700     05  INP-PAGELIT         PIC X(4).
010800     05  FILLER              PIC X.
010900     05  INP-PAGENUM         PIC 9(4).
011000     05  FILLER              PIC X.
011100     05  INP-LINELIT         PIC X(4).
011200     05  FILLER              PIC X.
011300     05  INP-LINENUM         PIC 9(3).
011400     05  FILLER              PIC X(8191).
011500     SKIP1
011600 TITLE 'Initialization and Main Line'.
011700 PROCEDURE DIVISION USING INP-PARMS.
011800* create an abend to see if we get control.
011900*    DIVIDE ABEND-CODE BY DIV-BY-ZERO GIVING PAGE-COUNT.
012000* make work area, attributes, and input line addressable.
012100     display 'Entered before set address'.
012200     SET ADDRESS OF INP-UAREA TO INP-USTOR.
012300     SET ADDRESS OF INP-ATTR TO INP-PFATTR.
012400     SET ADDRESS OF INP-LINE TO INP-RECPTR.
012500     display 'Before GOBACK'.
012600     GOBACK.