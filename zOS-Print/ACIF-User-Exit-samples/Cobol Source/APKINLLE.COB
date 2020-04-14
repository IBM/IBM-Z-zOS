000100 PROCESS NOD NUMPROC(PFD) TRUNC(OPT) APOST     NOSEQ     RENT
000200* LAST UPDATE ON 9 Apr 2018 AT 15:39:10 BY  HOWARDT VERSION 01   *
000300 ID DIVISION.
000400 PROGRAM-ID. APKINLLE.
000500 AUTHOR. TURETZKY--HYDRA.
000600 INSTALLATION. IBM BOULDER PROGRAMMING CENTER.
000700               This program is a sample exit for ACIF
000800               (APKACIF,5648-062) demonstrating the use of the
000900               ACIF input exit.
001000
001100               In order to use this exit, include the control
001200               INPEXIT=APKINLLE to enable this exit, and include
001300               the load module in a dataset referenced in steplib
001400               or elsewhere in the module search order.
001500
001600               This program will change LLE structured fields to
001700               NOP because acif does not currently pass LLEs to
001800               the output.  Corresponding output exit APKOTLLE
001900               will change the NOPs back to LLEs.
001910               NOTE: Current releases of ACIF support LLE.
002000
002100               Method of operation: each input record is examined
002200               for an LLE record. The structured field identifier
002300               is changed to NOP, and the LLE id placed in the
002400               flag and sequence fields. The output exit will use
002500               the flag and sequence to distinguish LLEs from
002600               other NOPs.
002700
002800 DATE-WRITTEN. 14 Jul 94.
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
005200 TITLE 'ACIF INPUT EXIT--FILTER LLE RECORDS'.
005300 ENVIRONMENT DIVISION.
005400 CONFIGURATION SECTION.
005500 SOURCE-COMPUTER. IBM-370.
005600 OBJECT-COMPUTER. IBM-370.
005700     EJECT
005800 DATA DIVISION.
005900 WORKING-STORAGE SECTION.
006000 77  PGMNAME                 PIC X(8) VALUE 'APKINLLE'.
006120 77  ABND-PGM                PIC X(8) VALUE 'CEE3ABD '.
006200 77  ABEND-CODE              PIC 9(4) BINARY VALUE 12.
006300 77  LINE-COUNT              PIC S9(8) BINARY VALUE ZERO.
006400 77  PAGE-COUNT              PIC S9(8) BINARY VALUE ZERO.
006500 77  PAGE-DISP               PIC Z,ZZZ,ZZ9.
006600 77  FIRST-LINE-FLAG         PIC X VALUE LOW-VALUE.
006700     88  FIRST-LINE          VALUE HIGH-VALUE.
006800     88  NOTFIRST-LINE       VALUE LOW-VALUE.
006900 77  INSERT-FLAG             PIC X VALUE LOW-VALUE.
007000     88  INSERT-LINE         VALUE HIGH-VALUE.
007100     88  NOINSERT-LINE       VALUE LOW-VALUE.
007200     SKIP2
007300         SKIP1
007400/ AFP STRUCTURED FIELD DEFINITIONS.
007500     COPY STRFLDS SUPPRESS.
007600/ PASSED PARAMETERS.
007700 LINKAGE SECTION.
007800 01  INP-PARMS.
007900     05  INP-USTOR           POINTER.
008000     05  INP-PFATTR          POINTER.
008100     05  INP-RECPTR          POINTER.
008200     05  FILLER              POINTER.
008300     05  INP-RECLEN          PIC 9(4) BINARY.
008400     05  FILLER              PIC XX.
008500     05  INP-REQUEST         PIC X.
008600         88  INP-USE         VALUE X'00'.
008700         88  INP-DELETE      VALUE X'01'.
008800         88  INP-INSERT      VALUE X'02'.
008900     05  INP-EOF-FLAG        PIC X.
009000         88  INP-EOF         VALUE 'Y'.
009100     SKIP1
009200 01  INP-UAREA               PIC X(16).
009300     SKIP1
009400 01  INP-ATTR.
009500     05  INP-CC              PIC XXX.
009600     05  INP-CCTYPE          PIC X.
009700         88  INP-ANSI-CC     VALUE 'A'.
009800         88  INP-MACH-CC     VALUE 'M'.
009900     05  INP-CHARS           PIC X(20).
010000     05  INP-FORMDEF         PIC X(8).
010100     05  INP-PAGEDEF         PIC X(8).
010200     05  INP-PRMODE          PIC X(8).
010300     05  INP-TRC             PIC XXX.
010400     SKIP1
010500* This is a template for the input record, pointed to by
010600* INP-RECPTR. The record's actual length is given by
010700* INP-RECLEN.
010800 01  INP-REC.
010900     05  INP-CCVAL           PIC X.
011000     05  INP-LEN             PIC 9(4) BINARY.
011100     05  INP-SFID            PIC X(3).
011200     05  INP-FLAGSEQ.
011300         10  INP-FLAG        PIC X.
011400         10  INP-SEQ         PIC 9(4) BINARY.
011500     05  INP-DATA            PIC X(32747).
011600     SKIP1
011700 TITLE 'Initialization and Main Line'.
011800 PROCEDURE DIVISION USING INP-PARMS.
011900* make work area, attributes, and input line addressable.
012000     SET ADDRESS OF INP-UAREA TO INP-USTOR.
012100     SET ADDRESS OF INP-ATTR TO INP-PFATTR.
012200     SET ADDRESS OF INP-REC TO INP-RECPTR.
012300* no special action is necessary at EOF.
012400     IF INP-EOF
012500      THEN
012600       DISPLAY PGMNAME, ' EOF REACHED.';
012700       MOVE PAGE-COUNT TO PAGE-DISP;
012800       DISPLAY PGMNAME, PAGE-DISP, ' Pages processed.';
012900       GOBACK;
013000     END-IF.
013100     EVALUATE INP-SFID
013200      WHEN SF-BPG
013300       ADD 1 TO PAGE-COUNT;
013400       MOVE ZERO TO LINE-COUNT;
013500      WHEN SF-LLE
013600       MOVE INP-SFID TO INP-FLAGSEQ;
013700       MOVE SF-NOP TO INP-SFID;
013800       ADD 1 TO LINE-COUNT;
013900      WHEN OTHER
014000       ADD 1 TO LINE-COUNT;
014100     END-EVALUATE.
014200     GOBACK.
014300 SKIP1
014400 END PROGRAM APKINLLE.