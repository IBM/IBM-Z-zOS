000100 PROCESS DYNAM NUMPROC(PFD) TRUNC(OPT) APOST     NOSEQ     RENT   APKRSLST
000200* LAST UPDATE ON 9 Apr 2018 AT 15:46:17 BY  HOWARDT VERSION 01   *
000300* LAST UPDATE ON 4 Mar 1993 AT 11:54:13 BY  VEND789 VERSION 01   *APKRSLST
000400 ID DIVISION.                                                     APKRSLST
000500 PROGRAM-ID. APKRSLST.                                            APKRSLST
000600 AUTHOR. TURETZKY--HYDRA.                                         APKRSLST
000700 INSTALLATION. IBM BOULDER PROGRAMMING CENTER.                    APKRSLST
000800                                                                  APKRSLST
000900               Modified 1Feb2018: extended parameter list         !@01A
001000                                  additional resource types.      !@01A
001100                                                                  APKRSLST
001200               NOTE: REQUIRES VS COBOL II OR LE COBOL.
001300               !@02 This program is an apkrslst exit for ACIF
001400               (APKACIF,5648-062) that will print a list of
001500               resources referenced in a print job, and
001600               (optionally) cause them to be excluded from  the
001700               output resource library.
001900                                                                  APKRSLST
002000               In order to use this exit, you must use the ACIF   APKRSLST
002100               control statement RESTYPE=ALL for the list to be   APKRSLST
002200               complete. RESTYPE=NONE will produce no list at     APKRSLST
002300               all.  If you only wish to see certain type of      APKRSLST
002400               resource, use RESTYPE to select it. Include the    APKRSLST
002500               control RESEXIT=APKRSLST to enable this exit, and  APKRSLST
002600               include the load module in a dataset referenced    APKRSLST
002700               in STEPLIB or elsewhere in the module search       APKRSLST
002800               order.                                             APKRSLST
002900                                                                  APKRSLST
003000               To control resource inclusion in the output        APKRSLST
003100               resource library, set the value of RES-ACTION      APKRSLST
003200               appropriately.  Note that if resources are         APKRSLST
003300               excluded, resources contained in overlays will     APKRSLST
003400               not appear in the report because overlay contents  APKRSLST
003500               will not be processed by ACIF.                     APKRSLST
003600                                                                  APKRSLST
003700               Method of operation: each resource name is saved   APKRSLST
003800               in a table for that type of resource. The table    APKRSLST
003900               may be searched to eliminate duplicates. When the  APKRSLST
004000               last call flag is set, the contents of the tables  APKRSLST
004100               are printed.                                       APKRSLST
004200                                                                  APKRSLST
004300               You must allocate a DD named PAPKRSLS for the      APKRSLST
004400               print file, with an LRECL of 84, BLKSIZE of        APKRSLST
004500               n*84+4, VBA.                                       APKRSLST
004600                                                                  APKRSLST
004700 DATE-WRITTEN. 23 FEB 93.                                         APKRSLST
004800 DATE-COMPILED.                                                   APKRSLST
004900 SECURITY. IBM SAMPLE CODE ONLY.                                  APKRSLST
005000*/**************************************************************/
005010*/* Licensed under the Apache License, Version 2.0 (the        */
005020*/* "License"); you may not use this file except in compliance */
005030*/* with the License. You may obtain a copy of the License at  */
005040*/*                                                            */
005050*/* http://www.apache.org/licenses/LICENSE-2.0                 */
005060*/*                                                            */
005070*/* Unless required by applicable law or agreed to in writing, */
005080*/* software distributed under the License is distributed on an*/
005090*/* "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY     */
005091*/* KIND, either express or implied.  See the License for the  */
005092*/* specific language governing permissions and limitations    */
005093*/* under the License.                                         */
005094*/*------------------------------------------------------------*/
005095*/*                                                            */
005100*/*   COPYRIGHT (C) 1993,2007 IBM CORPORATION                  */
005200*/*   COPYRIGHT (C) 2007,2018 RICOH COMPANY, LTD               */
005300*/*                                                            */
005400*/*   Permission to use, copy, modify, and distribute          */
005500*/*   this software for any purpose with or without fee        */
005600*/*   is hereby granted, provided that the above               */
005700*/*   copyright notices appear in all copies.                  */
005800*/*                                                            */
005900*/*   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY       */
006000*/*   OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT       */
006100*/*   LIMITED TO THE WARRANTIES OF MERCHANTABILITY,            */
006200*/*   FITNESS FOR A PARTICULAR PURPOSE AND                     */
006300*/*   NONINFRINGEMENT.  IN NO EVENT SHALL RICOH, RICOH         */
006400*/*   SUBSIDIARIES, ANY OF ITS SUPPLIERS OR ANY OF THE         */
006500*/*   OTHER COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,         */
006600*/*   DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF      */
006700*/*   CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF        */
006800*/*   OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR         */
006900*/*   OTHER DEALINGS IN THE SOFTWARE.                          */
007000*/**************************************************************/
007100 TITLE 'ACIF RESOURCE REPORT EXIT'.                               APKRSLST
007200 ENVIRONMENT DIVISION.                                            APKRSLST
007300 CONFIGURATION SECTION.                                           APKRSLST
007400 SOURCE-COMPUTER. IBM-370.                                        APKRSLST
007500 OBJECT-COMPUTER. IBM-370.                                        APKRSLST
007600 INPUT-OUTPUT SECTION.                                            APKRSLST
007700 FILE-CONTROL.                                                    APKRSLST
007800     SELECT PRINT-FILE ASSIGN TO PAPKRSLS.                        APKRSLST
007900     SKIP2                                                        APKRSLST
008000 DATA DIVISION.                                                   APKRSLST
008100 FILE SECTION.                                                    APKRSLST
008200 FD  PRINT-FILE                                                   APKRSLST
008300     BLOCK CONTAINS 0                                             APKRSLST
008400     LABEL RECORDS STANDARD                                       APKRSLST
008500     RECORD VARYING DEPENDING ON PRINT-REC-LEN                    APKRSLST
008600     RECORDING MODE V.                                            APKRSLST
008700 01  PRINT-RECORD.                                                APKRSLST
008800     05  PRINT-DATA          OCCURS 1 TO 255,                     APKRSLST
008900                             DEPENDING ON PRINT-REC-LEN,          APKRSLST
009000                             PIC X.                               APKRSLST
009100     EJECT                                                        APKRSLST
009200 WORKING-STORAGE SECTION.                                         APKRSLST
009300 77  PGMNAME                 PIC X(8) VALUE 'APKRSLST'.           APKRSLST
009400 77  ABND-PGM                PIC X(8) VALUE 'CEE3ABD' .           APKRSLST
009500 77  ABEND-CODE              PIC 9(4) BINARY VALUE 12.            APKRSLST
009600 77  PRINT-REC-LEN           PIC 9(8) BINARY VALUE ZERO.          APKRSLST
009700 77  MIN-REC-LEN             PIC 9(4) BINARY VALUE 9.             APKRSLST
009800 77  MAX-REC-LEN             PIC 9(4) BINARY VALUE 255.           APKRSLST
009900 77  LINE-COUNT              PIC S9(8) BINARY VALUE ZERO.         APKRSLST
010000 77  PAGE-COUNT              PIC S9(8) BINARY VALUE ZERO.         APKRSLST
010100 77  PAGE-LEN                PIC S9(8) BINARY VALUE 50.           APKRSLST
010200 77  UNKNOWN-CNTR            PIC 9(4) BINARY VALUE ZERO.          APKRSLST
010300 77  INCLUDE-RESOURCE        PIC X VALUE X'00'.                   APKRSLST
010400 77  IGNORE-RESOURCE         PIC X VALUE X'01'.                   APKRSLST
010500 77  FIRST-TIME-FLAG         PIC X VALUE LOW-VALUE.               APKRSLST
010600     88  FIRST-TIME          VALUE HIGH-VALUE.                    APKRSLST
010700* RESOURCE TYPES
010800 77  CPAGE                   PIC X VALUE X'41'.                   APKRSLST
010900 77  CSET                    PIC X VALUE X'40'.                   APKRSLST
011000 77  CODED-FONT              PIC X VALUE X'42'.                   APKRSLST
011100 77  PSEG                    PIC X VALUE X'FB'.                   APKRSLST
011200 77  OVLY                    PIC X VALUE X'FC'.                   APKRSLST
011300 77  GOCA                    PIC X VALUE X'03'.                   !@01A
011400 77  BCOCA                   PIC X VALUE X'05'.                   !@01A
011500 77  IOCA                    PIC X VALUE X'06'.                   !@01A
011600 77  PTOCA-OBJECT            PIC X VALUE X'9B'.                   !@01A
011700 77  OBJECT-CONT             PIC X VALUE X'92'.                   !@01A
011800 77  CPAGE-NAME              PIC X(14) VALUE 'CODE PAGE'.         APKRSLST
011900 77  CSET-NAME               PIC X(14) VALUE 'CHARACTER SET'.     APKRSLST
012000 77  CODED-FONT              PIC X(14) VALUE 'CODED FONT'.        APKRSLST
012100 77  PSEG-NAME               PIC X(14) VALUE 'PAGE SEGMENT'.      APKRSLST
012200 77  OVLY-NAME               PIC X(14) VALUE 'OVERLAY'.           APKRSLST
012300 77  OBJ-CONT-NAME           PIC X(14) VALUE 'OBJECT'.            !@01A
012400 77  GOCA-NAME               PIC X(14) VALUE 'GOCA'.              !@01A
012500 77  IOCA-NAME               PIC X(14) VALUE 'IOCA'.              !@01A
012600 77  BCOCA-NAME              PIC X(14) VALUE 'BCOCA'.             !@01A
012700 77  PTOCA-NAME              PIC X(14) VALUE 'PTOCA'.             !@01A
012800     SKIP2                                                        APKRSLST
012900* code page name table                                            APKRSLST
013000 01  CPGS-USED.                                                   APKRSLST
013100     05  CPGS-CNTR           PIC 9(4) BINARY VALUE ZERO.          APKRSLST
013200     05  CPGS-TABLE          OCCURS 256                           APKRSLST
013300                             DEPENDING ON CPGS-CNTR               APKRSLST
013400                             INDEXED BY CPGS-INDEX                APKRSLST
013500                             PIC X(8).                            APKRSLST
013600* character sets used table                                       APKRSLST
013700 01  CSETS-USED.                                                  APKRSLST
013800     05  CSETS-CNTR          PIC 9(4) BINARY VALUE ZERO.          APKRSLST
013900     05  CSETS-TABLE         OCCURS 256                           APKRSLST
014000                             DEPENDING ON CSETS-CNTR              APKRSLST
014100                             INDEXED BY CSETS-INDEX               APKRSLST
014200                             PIC X(8).                            APKRSLST
014300* page segments used table                                        APKRSLST
014400 01  PSEGS-USED.                                                  APKRSLST
014500     05  PSEGS-CNTR          PIC 9(4) BINARY VALUE ZERO.          APKRSLST
014600     05  PSEGS-TABLE         OCCURS 256                           APKRSLST
014700                             DEPENDING ON PSEGS-CNTR              APKRSLST
014800                             INDEXED BY PSEGS-INDEX               APKRSLST
014900                             PIC X(8).                            APKRSLST
015000* overlays used table                                             APKRSLST
015100 01  OVLYS-USED.                                                  APKRSLST
015200     05  OVLYS-CNTR          PIC 9(4) BINARY VALUE ZERO.          APKRSLST
015300     05  OVLYS-TABLE         OCCURS 256                           APKRSLST
015400                             DEPENDING ON OVLYS-CNTR              APKRSLST
015500                             INDEXED BY OVLYS-INDEX               APKRSLST
015600                             PIC X(8).                            APKRSLST
015700* GOCA     used table                                             APKRSLST
015800 01  GOCA-USED.                                                   APKRSLST
015900     05  GOCA-CNTR           PIC 9(4) BINARY VALUE ZERO.          APKRSLST
016000     05  GOCA-TABLE          OCCURS 256                           APKRSLST
016100                             DEPENDING ON GOCA-CNTR               APKRSLST
016200                             INDEXED BY GOCA-INDEX                APKRSLST
016300                             PIC X(8).                            APKRSLST
016400* IOCA     used table                                             APKRSLST
016500 01  IOCA-USED.                                                   APKRSLST
016600     05  IOCA-CNTR           PIC 9(4) BINARY VALUE ZERO.          APKRSLST
016700     05  IOCA-TABLE          OCCURS 256                           APKRSLST
016800                             DEPENDING ON IOCA-CNTR               APKRSLST
016900                             INDEXED BY IOCA-INDEX                APKRSLST
017000                             PIC X(8).                            APKRSLST
017100* BCOCA    used table                                             APKRSLST
017200 01  BCOCA-USED.                                                  APKRSLST
017300     05  BCOCA-CNTR          PIC 9(4) BINARY VALUE ZERO.          APKRSLST
017400     05  BCOCA-TABLE         OCCURS 256                           APKRSLST
017500                             DEPENDING ON BCOCA-CNTR              APKRSLST
017600                             INDEXED BY BCOCA-INDEX               APKRSLST
017700                             PIC X(8).                            APKRSLST
017800* PTOCA    used table                                             APKRSLST
017900 01  PTOCA-USED.                                                  APKRSLST
018000     05  PTOCA-CNTR          PIC 9(4) BINARY VALUE ZERO.          APKRSLST
018100     05  PTOCA-TABLE         OCCURS 256                           APKRSLST
018200                             DEPENDING ON PTOCA-CNTR              APKRSLST
018300                             INDEXED BY PTOCA-INDEX               APKRSLST
018400                             PIC X(8).                            APKRSLST
018500* objects  used table                                             !@01A
018600 01  OBJECTS-USED.                                                !@01A
018700     05  OBJECTS-CNTR        PIC 9(4) BINARY VALUE ZERO.          !@01A
018800     05  OBJECTS-NM-LEN      PIC 9(4) BINARY VALUE ZERO.          !@01A
018900     05  OBJECTS-TABLE       OCCURS 256                           !@01A
019000                             DEPENDING ON OBJECTS-CNTR            !@01A
019100                             INDEXED BY OBJECTS-INDEX             !@01A
019200                             PIC N(125).                          !@01A
019300     SKIP2                                                        APKRSLST
019400 01  PAGE-TITLE.                                                  APKRSLST
019500     05  FILLER              PIC X VALUE '1'.                     APKRSLST
019600     05  FILLER              PIC X(26)                            APKRSLST
019700                             VALUE 'ACIF Resources Used Report'.  APKRSLST
019800     05  FILLER              PIC X(4)  VALUE SPACES.              APKRSLST
019900     05  PAGE-TIMESTAMP      PIC X(10).                           APKRSLST
020000     05  FILLER              PIC X     VALUE SPACE.               APKRSLST
020100     05  FILLER              PIC X(05) VALUE 'Page'.              APKRSLST
020200     05  LINE-PAGE-NUM       PIC Z(4).                            APKRSLST
020300         SKIP1                                                    APKRSLST
020400 01  PAGE-SUBTITLE-1.                                             APKRSLST
020500     05  FILLER              PIC X VALUE SPACE.                   APKRSLST
020600     05  FILLER              PIC XXX VALUE 'CC'.                  APKRSLST
020700     05  FILLER              PIC X VALUE SPACE.                   APKRSLST
020800     05  FILLER              PIC X(7) VALUE 'CC Type'.            APKRSLST
020900     05  FILLER              PIC X VALUE SPACE.                   APKRSLST
021000     05  FILLER              PIC X(20) VALUE 'CHARS'.             APKRSLST
021100     05  FILLER              PIC X VALUE SPACE.                   APKRSLST
021200     05  FILLER              PIC X(8) VALUE 'FORMDEF'.            APKRSLST
021300     05  FILLER              PIC X VALUE SPACE.                   APKRSLST
021400     05  FILLER              PIC X(8) VALUE 'PAGEDEF'.            APKRSLST
021500     05  FILLER              PIC X VALUE SPACE.                   APKRSLST
021600     05  FILLER              PIC X(8) VALUE 'PRMODE'.             APKRSLST
021700     05  FILLER              PIC X VALUE SPACE.                   APKRSLST
021800     05  FILLER              PIC XXX VALUE 'TRC'.                 APKRSLST
021900         SKIP1                                                    APKRSLST
022000 01  PAGE-SUBTITLE-2.                                             APKRSLST
022100     05  FILLER              PIC X VALUE SPACE.                   APKRSLST
022200     05  PS1-CC              PIC XXX.                             APKRSLST
022300     05  FILLER              PIC X VALUE SPACE.                   APKRSLST
022400     05  PS1-CCTYPE          PIC X.                               APKRSLST
022500     05  FILLER              PIC X(7) VALUE SPACE.                APKRSLST
022600     05  PS1-CHARS           PIC X(20).                           APKRSLST
022700     05  FILLER              PIC X VALUE SPACE.                   APKRSLST
022800     05  PS1-FORMDEF         PIC X(8).                            APKRSLST
022900     05  FILLER              PIC X VALUE SPACE.                   APKRSLST
023000     05  PS1-PAGEDEF         PIC X(8).                            APKRSLST
023100     05  FILLER              PIC X VALUE SPACE.                   APKRSLST
023200     05  PS1-PRMODE          PIC X(8).                            APKRSLST
023300     05  FILLER              PIC X VALUE SPACE.                   APKRSLST
023400     05  PS1-TRC             PIC XXX.                             APKRSLST
023500         SKIP1                                                    APKRSLST
023600 01  PAGE-SUBTITLE-3.                                             APKRSLST
023700     05  FILLER              PIC X VALUE '0'.                     APKRSLST
023800     05  FILLER              PIC X(14)                            APKRSLST
023900                             VALUE 'Resource Type '.              APKRSLST
024000     05  PS-RESTYPE          PIC X(14).                           APKRSLST
024100         SKIP1                                                    APKRSLST
024200 01  LINE-DETAIL.                                                 APKRSLST
024300     05  LINE-CC             PIC X   VALUE SPACE.                 APKRSLST
024400     05  FILLER              PIC X(02) VALUE SPACES.              APKRSLST
024500     05  LINE-RESNAME        PIC X(128).                          !@01A
024600         SKIP1                                                    APKRSLST
024700 01  TIME-STAMP.                                                  APKRSLST
024800     05  T-S-DAY             PIC 9(5).                            APKRSLST
024900     05  FILLER              PIC X VALUE '/'.                     APKRSLST
025000     05  T-S-TIME            PIC X(6).                            APKRSLST
025100         SKIP1                                                    APKRSLST
025200/ PASSED PARAMETERS.                                              APKRSLST
025300 LINKAGE SECTION.                                                 APKRSLST
025400 01  RES-PARMS.                                                   APKRSLST
025500     05  RES-USTOR           POINTER.                             APKRSLST
025600     05  RES-PFATTR          POINTER.                             APKRSLST
025700     05  RES-RSNAME          PIC X(8).                            APKRSLST
025800     05  RES-RSTYPE          PIC X.                               APKRSLST
025900     05  RES-ACTION          PIC X.                               APKRSLST
026000     05  RES-EOF-FLAG        PIC X.                               APKRSLST
026100         88  RES-EOF         VALUE 'Y'.                           APKRSLST
026200     05  FILLER              PIC X.
026300     05  RES-RESNAMEL        PIC 9(4) BINARY.                     !@01A
026400     05  FILLER              PIC X(3).                            !@01A
026500     05  RES-RESNAMF         PIC N(125).                          !@01A
026600                                                                  APKRSLST
026700 01  RES-UAREA               PIC X(16).                           APKRSLST
026800                                                                  APKRSLST
026900 01  RES-ATTR.                                                    APKRSLST
027000     05  RES-CC              PIC XXX.                             APKRSLST
027100     05  RES-CCTYPE          PIC X.                               APKRSLST
027200     05  RES-CHARS           PIC X(20).                           APKRSLST
027300     05  RES-FORMDEF         PIC X(8).                            APKRSLST
027400     05  RES-PAGEDEF         PIC X(8).                            APKRSLST
027500     05  RES-PRMODE          PIC X(8).                            APKRSLST
027600     05  RES-TRC             PIC XXX.                             APKRSLST
027700 TITLE 'INITIALIZATION AND MAIN LINE'.                            APKRSLST
027800 PROCEDURE DIVISION USING RES-PARMS.                              APKRSLST
027900 0010-UPDATE-TABLE.                                               APKRSLST
028000     SET ADDRESS OF RES-UAREA TO RES-USTOR.                       APKRSLST
028100     IF RES-EOF                                                   APKRSLST
028200      THEN                                                        APKRSLST
028300       PERFORM 0100-PRINT-REPORT;                                 APKRSLST
028400       GOBACK;                                                    APKRSLST
028500     END-IF.                                                      APKRSLST
028600     EVALUATE RES-RSTYPE                                          APKRSLST
028700* ACIF presents code pages each time they appear in a font, so    APKRSLST
028800* there may be many occurences of the same codepage. Make sure    APKRSLST
028900* we save only 1 of each.                                         APKRSLST
029000      WHEN CPAGE                                                  APKRSLST
029100       SET CPGS-INDEX TO 1;                                       APKRSLST
029200       SEARCH CPGS-TABLE                                          APKRSLST
029300        AT END                                                    APKRSLST
029400         ADD 1 TO CPGS-CNTR;                                      APKRSLST
029500         MOVE RES-RSNAME TO CPGS-TABLE (CPGS-INDEX);              APKRSLST
029600        WHEN RES-RSNAME = CPGS-TABLE (CPGS-INDEX)                 APKRSLST
029700         CONTINUE;                                                APKRSLST
029800       END-SEARCH;                                                APKRSLST
029900      WHEN CSET                                                   APKRSLST
030000       ADD 1 TO CSETS-CNTR;                                       APKRSLST
030100       SET CSETS-INDEX TO CSETS-CNTR;                             APKRSLST
030200       MOVE RES-RSNAME TO CSETS-TABLE (CSETS-INDEX);              APKRSLST
030300      WHEN PSEG                                                   APKRSLST
030400       ADD 1 TO PSEGS-CNTR;                                       APKRSLST
030500       SET PSEGS-INDEX TO PSEGS-CNTR;                             APKRSLST
030600       MOVE RES-RSNAME TO PSEGS-TABLE (PSEGS-INDEX);              APKRSLST
030700      WHEN OVLY                                                   APKRSLST
030800       ADD 1 TO OVLYS-CNTR;                                       APKRSLST
030900       SET OVLYS-INDEX TO OVLYS-CNTR;                             APKRSLST
031000       MOVE RES-RSNAME TO OVLYS-TABLE (OVLYS-INDEX);              APKRSLST
031100      WHEN GOCA                                                   APKRSLST
031200       ADD 1 TO GOCA-CNTR;                                        APKRSLST
031300       SET GOCA-INDEX TO GOCA-CNTR;                               APKRSLST
031400       MOVE RES-RSNAME TO GOCA-TABLE (GOCA-INDEX);                APKRSLST
031500      WHEN IOCA                                                   APKRSLST
031600       ADD 1 TO IOCA-CNTR;                                        APKRSLST
031700       SET IOCA-INDEX TO IOCA-CNTR;                               APKRSLST
031800       MOVE RES-RSNAME TO IOCA-TABLE (IOCA-INDEX);                APKRSLST
031900      WHEN BCOCA                                                  APKRSLST
032000       ADD 1 TO BCOCA-CNTR;                                       APKRSLST
032100       SET BCOCA-INDEX TO BCOCA-CNTR;                             APKRSLST
032200       MOVE RES-RSNAME TO BCOCA-TABLE (BCOCA-INDEX);              APKRSLST
032300      WHEN PTOCA-OBJECT                                           APKRSLST
032400       ADD 1 TO PTOCA-CNTR;                                       APKRSLST
032500       SET PTOCA-INDEX TO PTOCA-CNTR;                             APKRSLST
032600       MOVE RES-RSNAME TO PTOCA-TABLE (PTOCA-INDEX);              APKRSLST
032700      WHEN OBJECT-CONT                                            !@01A
032800       ADD 1 TO OBJECTS-CNTR;                                     !@01A
032900       SET OBJECTS-INDEX TO OBJECTS-CNTR;                         !@01A
033000       MOVE SPACES TO OBJECTS-TABLE (OBJECTS-INDEX);              !@01A
033100       MOVE RES-RESNAMF (1:RES-RESNAMEL) TO                       !@01A
033200            OBJECTS-TABLE (OBJECTS-INDEX);                        !@01A
033300      WHEN OTHER                                                  APKRSLST
033400       ADD 1 TO UNKNOWN-CNTR;                                     APKRSLST
033500     END-EVALUATE.                                                APKRSLST
033600* The following omits or includes all resources.                  APKRSLST
033700*    MOVE IGNORE-RESOURCE TO RES-ACTION.                          APKRSLST
033800     MOVE INCLUDE-RESOURCE TO RES-ACTION.                         APKRSLST
033900     GOBACK.                                                      APKRSLST
034000 TITLE 'Produce Resource Used Report'.                            APKRSLST
034100 0100-PRINT-REPORT.                                               APKRSLST
034200     ACCEPT T-S-DAY FROM DAY.                                     APKRSLST
034300     ACCEPT T-S-TIME FROM TIME.                                   APKRSLST
034400     MOVE TIME-STAMP TO PAGE-TIMESTAMP.                           APKRSLST
034500     SET ADDRESS OF RES-ATTR TO RES-PFATTR.                       APKRSLST
034600     MOVE RES-CC TO PS1-CC.                                       APKRSLST
034700     MOVE RES-CCTYPE TO PS1-CCTYPE.                               APKRSLST
034800     MOVE RES-CHARS TO PS1-CHARS.                                 APKRSLST
034900     MOVE RES-FORMDEF TO PS1-FORMDEF.                             APKRSLST
035000     MOVE RES-PAGEDEF TO PS1-PAGEDEF.                             APKRSLST
035100     MOVE RES-PRMODE TO PS1-PRMODE.                               APKRSLST
035200     MOVE RES-TRC TO PS1-TRC.                                     APKRSLST
035300     MOVE CPAGE-NAME TO PS-RESTYPE.                               APKRSLST
035400     SKIP1                                                        APKRSLST
035500     OPEN OUTPUT PRINT-FILE.                                      APKRSLST
035600     SKIP1                                                        APKRSLST
035700     MOVE PAGE-LEN TO LINE-COUNT.                                 APKRSLST
035800     PERFORM WITH TEST BEFORE                                     APKRSLST
035900         VARYING CPGS-INDEX FROM 1 BY 1                           APKRSLST
036000         UNTIL CPGS-INDEX > CPGS-CNTR;                            APKRSLST
036100       MOVE CPGS-TABLE (CPGS-INDEX) TO LINE-RESNAME;              APKRSLST
036200       PERFORM 0120-PRINT-DETAIL;                                 APKRSLST
036300     END-PERFORM.                                                 APKRSLST
036400     MOVE CSET-NAME TO PS-RESTYPE.                                APKRSLST
036500     MOVE PAGE-LEN TO LINE-COUNT.                                 APKRSLST
036600     PERFORM WITH TEST BEFORE                                     APKRSLST
036700         VARYING CSETS-INDEX FROM 1 BY 1                          APKRSLST
036800         UNTIL CSETS-INDEX > CSETS-CNTR;                          APKRSLST
036900       MOVE CSETS-TABLE (CSETS-INDEX) TO LINE-RESNAME;            APKRSLST
037000       PERFORM 0120-PRINT-DETAIL;                                 APKRSLST
037100     END-PERFORM.                                                 APKRSLST
037200     MOVE PSEG-NAME TO PS-RESTYPE.                                APKRSLST
037300     MOVE PAGE-LEN TO LINE-COUNT.                                 APKRSLST
037400     PERFORM WITH TEST BEFORE                                     APKRSLST
037500       VARYING PSEGS-INDEX FROM 1 BY 1                            APKRSLST
037600       UNTIL PSEGS-INDEX > PSEGS-CNTR;                            APKRSLST
037700       MOVE PSEGS-TABLE (PSEGS-INDEX) TO LINE-RESNAME;            APKRSLST
037800       PERFORM 0120-PRINT-DETAIL;                                 APKRSLST
037900     END-PERFORM.                                                 APKRSLST
038000     MOVE OVLY-NAME TO PS-RESTYPE.                                APKRSLST
038100     MOVE PAGE-LEN TO LINE-COUNT.                                 APKRSLST
038200     PERFORM WITH TEST BEFORE                                     APKRSLST
038300         VARYING OVLYS-INDEX FROM 1 BY 1                          APKRSLST
038400         UNTIL OVLYS-INDEX > OVLYS-CNTR;                          APKRSLST
038500       MOVE OVLYS-TABLE (OVLYS-INDEX) TO LINE-RESNAME;            APKRSLST
038600       PERFORM 0120-PRINT-DETAIL;                                 APKRSLST
038700     END-PERFORM.                                                 APKRSLST
038800     MOVE GOCA-NAME TO PS-RESTYPE.                                !@01A
038900     MOVE PAGE-LEN TO LINE-COUNT.                                 !@01A
039000     PERFORM WITH TEST BEFORE                                     !@01A
039100         VARYING GOCA-INDEX FROM 1 BY 1                           !@01A
039200         UNTIL GOCA-INDEX > GOCA-CNTR;                            !@01A
039300       MOVE GOCA-TABLE (GOCA-INDEX) TO LINE-RESNAME;              !@01A
039400       PERFORM 0120-PRINT-DETAIL;                                 !@01A
039500     END-PERFORM.                                                 !@01A
039600     MOVE BCOCA-NAME TO PS-RESTYPE.                               !@01A
039700     MOVE PAGE-LEN TO LINE-COUNT.                                 !@01A
039800     PERFORM WITH TEST BEFORE                                     !@01A
039900         VARYING BCOCA-INDEX FROM 1 BY 1                          !@01A
040000         UNTIL BCOCA-INDEX > BCOCA-CNTR;                          !@01A
040100       MOVE BCOCA-TABLE (BCOCA-INDEX) TO LINE-RESNAME;            !@01A
040200       PERFORM 0120-PRINT-DETAIL;                                 !@01A
040300     END-PERFORM.                                                 !@01A
040400     MOVE IOCA-NAME TO PS-RESTYPE.                                !@01A
040500     MOVE PAGE-LEN TO LINE-COUNT.                                 !@01A
040600     PERFORM WITH TEST BEFORE                                     !@01A
040700         VARYING IOCA-INDEX FROM 1 BY 1                           !@01A
040800         UNTIL IOCA-INDEX > IOCA-CNTR;                            !@01A
040900       MOVE IOCA-TABLE (IOCA-INDEX) TO LINE-RESNAME;              !@01A
041000       PERFORM 0120-PRINT-DETAIL;                                 !@01A
041100     END-PERFORM.                                                 !@01A
041200     MOVE PTOCA-NAME TO PS-RESTYPE.                               !@01A
041300     MOVE PAGE-LEN TO LINE-COUNT.                                 !@01A
041400     PERFORM WITH TEST BEFORE                                     !@01A
041500         VARYING PTOCA-INDEX FROM 1 BY 1                          !@01A
041600         UNTIL PTOCA-INDEX > PTOCA-CNTR;                          !@01A
041700       MOVE PTOCA-TABLE (PTOCA-INDEX) TO LINE-RESNAME;            !@01A
041800       PERFORM 0120-PRINT-DETAIL;                                 !@01A
041900     END-PERFORM.                                                 !@01A
042000     MOVE OBJ-CONT-NAME TO PS-RESTYPE.                            !@01A
042100     MOVE PAGE-LEN TO LINE-COUNT.                                 !@01A
042200     PERFORM WITH TEST BEFORE                                     !@01A
042300         VARYING OBJECTS-INDEX FROM 1 BY 1                        !@01A
042400         UNTIL OBJECTS-INDEX > OBJECTS-CNTR;                      !@01A
042500       MOVE SPACES TO LINE-RESNAME;                               !@01A
042600       MOVE FUNCTION DISPLAY-OF (OBJECTS-TABLE (OBJECTS-INDEX))   !@01A
042700            TO  LINE-RESNAME;                                     !@01A
042800       PERFORM 0120-PRINT-DETAIL;                                 APKRSLST
042900     END-PERFORM.                                                 APKRSLST
043000     MOVE PAGE-LEN TO LINE-COUNT.                                 APKRSLST
043100     SKIP1                                                        APKRSLST
043200     CLOSE PRINT-FILE.                                            APKRSLST
043300     SKIP1                                                        APKRSLST
043400 0110-PRINT-HEADER.                                               APKRSLST
043500     ADD 1 TO PAGE-COUNT.                                         APKRSLST
043600     MOVE PAGE-COUNT TO LINE-PAGE-NUM.                            APKRSLST
043700     MOVE LENGTH OF PAGE-TITLE TO PRINT-REC-LEN.                  APKRSLST
043800     WRITE PRINT-RECORD FROM PAGE-TITLE.                          APKRSLST
043900     MOVE LENGTH OF PAGE-SUBTITLE-1 TO PRINT-REC-LEN.             APKRSLST
044000     WRITE PRINT-RECORD FROM PAGE-SUBTITLE-1.                     APKRSLST
044100     MOVE LENGTH OF PAGE-SUBTITLE-2 TO PRINT-REC-LEN.             APKRSLST
044200     WRITE PRINT-RECORD FROM PAGE-SUBTITLE-2.                     APKRSLST
044300     MOVE LENGTH OF PAGE-SUBTITLE-3 TO PRINT-REC-LEN.             APKRSLST
044400     WRITE PRINT-RECORD FROM PAGE-SUBTITLE-3.                     APKRSLST
044500     MOVE ZERO TO LINE-COUNT.                                     APKRSLST
044600       SKIP2                                                      APKRSLST
044700 0120-PRINT-DETAIL.                                               APKRSLST
044800     IF LINE-COUNT >= PAGE-LEN                                    APKRSLST
044900      THEN                                                        APKRSLST
045000       PERFORM 0110-PRINT-HEADER;                                 APKRSLST
045100     END-IF.                                                      APKRSLST
045200     ADD 1 TO LINE-COUNT.                                         APKRSLST
045300     MOVE LENGTH OF LINE-DETAIL TO PRINT-REC-LEN.                 APKRSLST
045400     WRITE PRINT-RECORD FROM LINE-DETAIL.                         APKRSLST