//OECONSOL JOB REGION=64M,NOTIFY=&SYSUID
//********************************************************************
//      SET LIBRARY=SYS1.LINKLIB        APF Linklist dataset
//      SET DIR='/usr/local/bin'        Directory to hold USS command
//********************************************************************
//ASM      EXEC PGM=ASMA90,PARM='NODECK,OBJECT,TERM,NOXREF'
//SYSLIB   DD   DSN=SYS1.MACLIB,DISP=SHR
//         DD   DSN=SYS1.MODGEN,DISP=SHR
//SYSUT1   DD   DSN=&&SYSUT1,UNIT=SYSDA,SPACE=(CYL,(1,1))
//SYSPRINT DD   SYSOUT=*
//SYSLIN   DD   DSN=&&OBJSET,UNIT=SYSDA,SPACE=(80,(800,100)),
//            DISP=(,PASS)
//SYSTERM  DD   SYSOUT=*
//SYSIN    DD   *
OECONSOL AMODE 31
OECONSOL RMODE ANY
OECONSOL TITLE 'OECONSOL - OpenEdition Command'
**** Start of Specifications *****************************************
*                                                                    *
*01* MODULE NAME = OECONSOL                                          *
*                                                                    *
*01* DESCRIPTIVE NAME = OpenMVS command to issue MVS operator cmds   *
*                                                                    *
*01* FUNCTION = This program uses the extended console interface to  *
*               issue operator commands. The command output is       *
*               written to STDOUT.                                   *
*                                                                    *
*01* INPUT =                                                         *
*                                                                    *
*01* OUTPUT =                                                        *
*       The console output is written to the terminal (STDOUT).      *
*                                                                    *
*01* MESSAGES =                                                      *
*       The following messages may be written to the terminal:       *
*                                                                    *
*        Extended console activation failed RC=xx,RSN=xx'            *
*        Extended console activation failed RC='                     *
*        Extended console deactivation failed RC=xx,RSN=xx'          *
*        Error retrieving operator message RC=xx,RSN=xx'             *
*                                                                    *
*                                                                    *
*01* CHANGE ACTIVITY =                                               *
*                                                                    *
* 20Sep00  Fix failure of multiline messages                         *
*                                                                    *
* 30Nov00  Needs input after response timeout fixed                  *
*                                                                    *
* 11May01  Changed call to open console so that, if the console name *
*          is in use, we try a suffix in the range A-Z, 0-9.         *
*          Also, write to STDERR for error messages.                 *
*          Also, ensure return code is returned to calling program   *
*                                                                    *
* 30May01  If console name is in use, only write error messages      *
*          if we have got to the last possible suffix i.e. 9         *
*                                                                    *
* 14Feb02  Add parm to control wait time in seconds.                 *
*          Second parm 'Wsss' where sss is seconds in decimal        *
*          default 3 seconds (exactly), may omit parm                *
*                                                                    *
* 28May02  Added code to allow additional consoles for userids that  *
*          aren't exactly 7 chars long!                              *
*                                                                    *
* 13Jul06  Added OPERPARM to MCSOPER macro to force AUTH(ALL) for    *
*          e.g. MQ subsystem startup/shutdown                        *
*                                                                    *
**** End of Specifications *******************************************
*
         TITLE 'OECONSOL   - Dynamic Storage Area'
***********************************************************************
*                                                                     *
*        Dynamic Storage Area                                         *
*                                                                     *
***********************************************************************
DSA      DSECT
SAVEAREA DS    18F                     Register save area
DSAADDR  DS    F                       DSA address
WRTENTRY DS    F                       Address of BPX1WRT stub
GLGENTRY DS    F                       Address of BPX1GLG stub
REDENTRY DS    F                       Address of BPX1RED stub
GLGRET   DS    F                       Return value from BPX1GLG
PLIST    DS    7F                      Parameter list for CALL
RETVAL   DS    F                       Return value
RETCODE  DS    F                       Return code
RSNCODE  DS    F                       Reason code
CMD@     DS    F                       Address command area for MGCRE
SAVER3   DS    F                       Area for pointer to SUFFIX
NAMELEN  DS    F                       Length of login name
CMDLEN   DS    XL2                     Command length
CMDBUFF  DS    XL122                   Read buffer area
@CMDBUF  DS    F                       Read buffer area address
WRTBUFF  DS    XL126                   Write buffer area
@WRTBUF  DS    F                       Write buffer area address
WRTBUFL  DS    F                       Write buffer length
OPERPRM  DS    CL(MCSOPLEN)            OPERPARMs area
         DS    0F
ECBS     DS    0CL8                    ECB list
MECBADDR DS    A                       Address of message ECB
TECBADDR DS    A                       Address of timer ECB
STMRID   DS    F                       STIMERM id
CNID     DS    F                       Console id
CSA      DS    A                       MCSCSA address
CSAALET  DS    F                       MCSCSA ALET
MSGECB   DS    F                       Message ECB
TIMEECB  DS    F                       Timer ECB
RC       DS    F                       RC from MCSOPER/MCSOPMSG
RSN      DS    F                       RSN from MCSOPER/MCSOPMSG
TEXTOFF  DS    F                       Text offset in MDB text object
STIMLOC  DS    F                       Local timer interval
TIMLOC   DS    F                       Local timer work field
MDBFLGS  DS    XL1                     MDB flag
MDBFGO   EQU   X'01'                   Processed general object
MDBFCO   EQU   X'02'                   Processed control prog object
PROGFLAG DS    XL1                     Program flag
CMDARG   EQU   X'01'                   Command passed as program arg
X2CWRK1  DS    D                       Work
X2CWRK2  DS    D                       Work
LOGNNAME DS    CL8                     Login userid
*
*---------------------------------------------------------------------*
*                                                                     *
*        Dynamic macro expansions                                     *
*                                                                     *
*---------------------------------------------------------------------*
MACROS   DS    0D
SUP      MODESET MODE=SUP,MF=L         MODESET parm list for sup state
SUP0     MODESET MODE=SUP,KEY=ZERO,MF=L MODESET plist for sup state 0
PROB     MODESET MODE=PROB,KEY=NZERO,MF=L MODESET plist for prob state
MGCRE    MGCRE   MF=L                  MGCRE plist
STIMERMS STIMERM SET,MF=L              STIMERM plist
STIMERMC STIMERM CANCEL,MF=L           STIMERM plist
         MCSOPER MF=(L,MCSOPER)        MCSOPER parameter list
         MCSOPMSG MF=(L,MCSOPMSG)      MCSOPMSG parameter list
*
DSALEN   EQU   *-DSA                   Length of work area
*
         TITLE 'OECONSOL     - Main Routine'
OECONSOL CSECT ,
         BAKR  R14,0                   Save status on linkage stack
         SAC   512                     Set AR mode
         SYSSTATE ASCENV=AR            Let macros know
         LAE   R12,0(R15,0)            Establish a base register
         USING OECONSOL,R12            Establish addressability
         LR    R5,R1                   Load parameter list address
         MODID ,                       Put out an eye-catcher
         STORAGE OBTAIN,LENGTH=DSALEN,LOC=BELOW,BNDRY=PAGE Get storage
         LAE   R13,0(R1,0)             Load storage address
         USING DSA,R13                 Addressability
         LAE   R0,DSA                  Clear
         LA    R1,DSALEN
         LAE   R14,0(0,0)                   storage
         SR    R15,R15
         MVCL  R0,R14                               area
         ST    R13,DSAADDR             Save DSA address
         MVC   SAVEAREA+4(4),=C'F1SA'  Put acronym in save area
         LAE   R0,MACROS               Move
         LAE   R14,MACDEF                  dynamic
         LA    R1,MACLEN                         macros
         LR    R15,R1                                  to
         MVCL  R0,R14                                     workarea
         SAC   0                       Set primary mode
         SYSSTATE ASCENV=P             Let macros know
*
*---------------------------------------------------------------------*
*                                                                     *
*        Initialization                                               *
*                                                                     *
*---------------------------------------------------------------------*
         SLR   R9,R9                   Clear
         LOAD  EP=BPX1GLG              Load stub
         ST    R0,GLGENTRY             Save address
         L     R15,GLGENTRY            Load address of BPX1GLG module
         CALL  (15),                   Get login name                  +
               (GLGRET),               Ret value: address of login name+
               VL,MF=(E,PLIST)
         MVC   LOGNNAME,=CL8' '        Blank login name
         L     R1,GLGRET               Point to GLG return value
         ICM   R2,B'1111',0(R1)        Load login name length
         BCTR  R2,0                    Reduce for EXecute
         EX    R2,COPYLOGN
         ST    R2,NAMELEN              Save for later if needed
         LOAD  EP=BPX1RED              Load read stub
         ST    R0,REDENTRY             Save address
         LA    R1,CMDBUFF              Load read buffer address
         ST    R1,@CMDBUF                 and store
         LOAD  EP=BPX1WRT              Load write stub
         ST    R0,WRTENTRY             Save address
         LA    R1,WRTBUFF              Load buffer address
         ST    R1,@WRTBUF
         LA    R1,MSGECB               Get address of message ECB
         ST    R1,MECBADDR             Put into ECB list
         LA    R1,TIMEECB              Get addr of time ECB
         O     R1,=X'80000000'         Indicate last ECB
         ST    R1,TECBADDR             Put into ECB list
         LA    R1,CMDLEN               Load address of command area
         ST    R1,CMD@                    and store
         LA    R3,SUFFIX-1             Point before SUFFIX
         ST    R3,SAVER3               Save R3
DIFFNAME EQU   *
         L     R3,SAVER3               Restore pointer to SUFFIX
         LA    R3,1(R3)                Bump to next element
         ST    R3,SAVER3               Save R3
         LA    R2,LOGNNAME             Point to console name
         A     R2,NAMELEN              add length
         MVC   1(1,R2),0(R3)           and add suffix
         BAS   R14,ACTCONS             Activate console
         C     R15,=AL4(4)             Was rc Four ?
         BNE   LEAVLOOP                   No
         L     R3,SAVER3               Restore pointer to SUFFIX
         CLI   0(R3),C'9'              At end of suffix table?
         BE    LEAVLOOP                Yes - don't loop again
         BAS   R14,DEACTCN             Go deactivate the console
         B     DIFFNAME                try a different name
LEAVLOOP LTR   R15,R15                 Did it work?
         BNZ   OECONSLX                   No, return
         B     CHKARG                  Cont
COPYLOGN MVC   LOGNNAME(0),4(R1)       *** EXecute ***
*
*---------------------------------------------------------------------*
*                                                                     *
*        Check if a command has been passed as a program argument     *
*                                                                     *
*---------------------------------------------------------------------*
CHKARG   DS    0H
         MVC   STIMLOC(4),STMRINTV     Set default timeout arg2
         L     R2,0(,R5)               Load address of argument count
         L     R2,0(,R2)               Load argument count (#args+1)
         BCTR  R2,0                    Reduce for program name
         LTR   R2,R2                   Were any arguments provided
         BZ    CONSLOOP                   No, cont
         OI    PROGFLAG,CMDARG         Remember ...
*---------------------------------------------------------------------*
*        Look for second parameter and set timer if found
*---------------------------------------------------------------------*
         BCTR  R2,0                    Check for arg2
         LTR   R2,R2
         BZ    CONTARG1                   No, go to arg1
         L     R1,4(,R5)               @Length-array
         L     R1,8(,R1)               @length(arg2)
         LA    R2,4(,R1)               @arg2
         ICM   R1,B'1111',0(R1)        Length arg2
         BZ    CONTARG1                   skip if zero length
*
*    R1 - length>=1, R2 - @arg2  (Wnn meaning wait nn secs)
*
         CLI   0(R2),C'W'              Wait parm?
         BNE   CONTARG1                   skip arg2 if not
*
         XC    TIMLOC(4),TIMLOC        Clear local time field
*
NEXTDIGIT  DS 0H
         BCTR  R1,0                    Decr length
         LTR   R1,R1
         BZ    CONTARG2                   Skip to end if no more
*
         LA    R2,1(R2)                Point to next digit.
         CLI   0(R2),C'0'              Digit?
         BL    CONTARG2                   skip to end if not
         CLI   0(R2),C'9'              Digit?
         BH    CONTARG2                   skip to end if not
*
         LA    R0,10(0)                R0 := 10
         MS    R0,TIMLOC               R0 := 10*TIMLOC
         ST    R0,TIMLOC               TIMLOC := R0
*
         XR    R0,R0                   Clear R0
         ICM   R0,B'0001',0(R2)        Get one byte
         S     R0,DIGITZERO            Get value of digit
         A     R0,TIMLOC
         ST    R0,TIMLOC               TIMLOC := TIMLOC + digval
         B     NEXTDIGIT
*
CONTARG2 DS 0H
         CLI   TIMLOC+3,X'00'          If zero
         BZ    CONTARG1                   skip arg (take default)
*
         LA    R0,100(0)               R0 := 100
         MS    R0,TIMLOC               R0 := 100*TIMLOC
         ST    R0,STIMLOC              Set local timer value
*
*
*
CONTARG1 DS    0H
*---------------------------------------------------------------------*
         L     R1,4(,R5)               Load address of arg length list
         L     R1,4(,R1)               Load address of 1st arg length
         LA    R2,4(,R1)               Load address of 1st argument
         ICM   R1,B'1111',0(R1)        Load length of 1st arg
         BZ    CONSLOOP                Shouldn't happen but ...
         BCTR  R1,0                    Arg ends in nulls so reduce len
         C     R1,=AL4(MAXCMD)         Is length too long
         BH    INVARG                     Yes, invalid
         STCM  R1,B'0011',CMDLEN       Store length
         BCTR  R1,0                    Reduce for EXecute
         EX    R1,COPYARG              Copy argument
         B     ISSUECMD                Go check on first arg
COPYARG  MVC   CMDBUFF(0),0(R2)        *** EXecute ***
*
INVARG   DS    0H
         MVC   WRTBUFF(L'CMDLNMSG),CMDLNMSG
         MVI   WRTBUFF+L'CMDLNMSG,NEWLINE Add "Newline" character
         LA    R1,L'CMDLNMSG+1         Load total message length
         ST    R1,WRTBUFL                 and store
         BAS   R14,WRTMSG              Write message to STDOUT
         B     DCONS                   Return
*
*
*---------------------------------------------------------------------*
*                                                                     *
*        Loop to prompt, read/issue commands, and display command     *
*        output.                                                      *
*                                                                     *
*---------------------------------------------------------------------*
CONSLOOP DS    0H
         MVC   WRTBUFF(L'CONSMSG),CONSMSG Copy "CONSOLE" message
         MVI   WRTBUFF+L'CONSMSG,NEWLINE Add "Newline" character
         LA    R1,L'CONSMSG+1          Load total message length
         ST    R1,WRTBUFL                 and store
         BAS   R14,WRTMSG              Write message to STDOUT
         L     R15,REDENTRY            Load address of BPX1RED module
         CALL  (15),                   Read from a file                +
               (STDIN,                 Input: File descriptor          +
               @CMDBUF,                Input: ->Buffer                 +
               ALET0,                  Input: Buffer ALET              +
               CMDBUFL,                Input: Number of bytes to read  +
               RETVAL,                 Ret value: -1 or bytes read     +
               RETCODE,                Return code                     +
               RSNCODE),               Reason code                     +
               VL,MF=(E,PLIST)         -------------------------------
         ICM   R15,B'1111',RETVAL      Test RETVAL
         BL    ABEND
         BZ    CONSLOOP
         CLI   CMDBUFF,NEWLINE         Was "Enter" pressed?
         BE    CONSENTR                   Yes, cont
         CLC   CMDBUFF(3),=CL3'END'
         BE    DCONS
         CLC   CMDBUFF(3),=CL3'end'
         BE    DCONS
         BCTR  R15,0                   Reduce length for nulls
         STCM  R15,B'0011',CMDLEN         and store
         B     ISSUECMD
CONSENTR DS    0H
         TM    MSGECB,X'40'            Has MSGECB been posted?
         BNO   CONSLOOP                   No, cont
         XC    MSGECB,MSGECB           Clear ECB
         BAS   R14,GETMSGS             Go retrieve console messages
         B     CONSLOOP                Cont
ABEND    DC    H'0000'
ISSUECMD DS    0H
         MODESET MF=(E,SUP0)           Set supervisor state key 0
         L     R2,CMD@                 Point to command
         MGCRE TEXT=(R2),                                              +
               CONSID=CNID,                                            +
               MF=(E,MGCRE)
         MODESET MF=(E,PROB)           Set problem state
ISSUESTM DS    0H
         LA    R2,STMREXIT             Load STIMERM exit address
         LA    R3,DSAADDR              Using DSA for parameter data
         STIMERM SET,                  Set timer                       +
               ID=STMRID,                                              +
               BINTVL=STIMLOC,                                         +
               EXIT=(R2),PARM=(R3),                                    +
               MF=(E,STIMERMS)
         WAIT  ECBLIST=ECBS
         L     R1,MSGECB               Get msg ECB
         N     R1,=X'40000000'         Did it get POSTed?
         BZ    TSTARG                  No, must've been from STIMER
         XC    MSGECB,MSGECB           Clear ECB
         BAS   R14,GETMSGS             Retrieve messages
         STIMERM CANCEL,ID=ALL,MF=(E,STIMERMC) Cancel STIMER
         B     ISSUESTM                Wait again til no resps
TSTARG   TM    PROGFLAG,CMDARG         Was command passed via argument?
         BNZ   DCONS                      Yes, deactivate and exit
         B     CONSLOOP                Cont
DCONS    DS    0H
         BAS   R14,DEACTCN             Deactivate console
         B     OECONSLX                Return
*
*---------------------------------------------------------------------*
*                                                                     *
*        Return processing                                            *
*                                                                     *
*---------------------------------------------------------------------*
OECONSLX DS    0H
         LR    R9,R15                  Store RC
         DELETE EP=BPX1GLG             Delete get login stub
         DELETE EP=BPX1RED             Delete read stub
         DELETE EP=BPX1WRT             Delete write stub
         STORAGE RELEASE,LENGTH=DSALEN,ADDR=(R13) Free storage
         LR    R15,R9                  Load RC
         PR                            Exit program
*
*---------------------------------------------------------------------*
*                                                                     *
*  Routine:     ACTCONS                                               *
*  Environment: ASC Mode Primary                                      *
*               Sets Supervisor state                                 *
*  Function:    Activate an extended console                          *
*  Error:       Issue message if MCSOPER fails                        *
*                                                                     *
*---------------------------------------------------------------------*
         SYSSTATE ASCENV=P             Let macros know we're in primary
ACTCONS  DS    0H
         BAKR  R14,0                   Save storage of linkage stack
         MODESET MF=(E,SUP)            Get in supervisor state
         LA    R1,OPERPRM              Get address of MCSOP area
         USING MCSOPPRM,R1             Addressability
         OI    MCSOATH1,MCSOAALL       Set AUTH=ALL
         DROP  R1                      Addressability drop
         MCSOPER REQUEST=ACTIVATE,NAME=LOGNNAME,TERMNAME=OMVSTERM,     X
               MSGECB=MSGECB,MCSCSA=CSA,OPERPARM=OPERPRM,              X
               ALERTECB=0,MCSCSAA=CSAALET,CONSID=CNID,                 X
               RTNCODE=RC,RSNCODE=RSN,MSGDLVRY=SEARCH,                 X
               MF=(E,MCSOPER)          Activate console
         MODESET MF=(E,PROB)           Back to problem state
         ICM   R1,B'1111',RC           Check RC
         BZ    ACTCONSX                Return if zero
         C     R1,=AL4(4)              Console name in use error?
         BNE   WRITEERR                No - diff error - write it
         L     R3,SAVER3               Restore pointer to SUFFIX
         CLI   0(R3),C'9'              At end of suffix table?
         BNE   ACTCONSX                No - don't write err msg
WRITEERR EQU   *
         BAS   R14,X2C                 Convert to EBCDIC
         MVC   WRTBUFF(L'ACTERR),ACTERR Copy error message
         STCM  R1,B'0011',WRTBUFF+ACTRCOFF Copy EBCDIC RC
         ICM   R1,B'1111',RSN          Load reason code
         BAS   R14,X2C                 Convert to EBCDIC
         STCM  R1,B'0011',WRTBUFF+ACTRSOFF Copy EBCDIC RSN
         MVI   WRTBUFF+L'ACTERR,NEWLINE Add "Newline" character
         LA    R1,L'ACTERR+1           Load total message length
         ST    R1,WRTBUFL                 and store
         BAS   R14,WRTERR              Write message to STDERR
ACTCONSX DS    0H
         L     R15,RC                  Load return code
         PR                            Return
*
*---------------------------------------------------------------------*
*                                                                     *
*  Routine:     DEACTCN                                               *
*  Environment: Set ASC Mode to Primary                               *
*               Sets supervisor state                                 *
*  Function:    Deactivate the console                                *
*  Operation:                                                         *
*  Error:       Issue message if MCSOPER fails                        *
*                                                                     *
*---------------------------------------------------------------------*
DEACTCN  DS    0H
         BAKR  R14,0                   Save status
         SAC   0                       Set primary mode
         SYSSTATE ASCENV=P             Let macros know
         MODESET MF=(E,SUP)            Set supervisor state
         MCSOPER REQUEST=DEACTIVATE,CONSID=CNID,RTNCODE=RC,            X
               RSNCODE=RSN,MF=(E,MCSOPER)  Deactivate console
         MODESET MF=(E,PROB)           Set problem state
         ICM   R1,B'1111',RC           Check RC
         BZ    DEACTCNX                Return if zero
         L     R3,SAVER3               Restore pointer to SUFFIX
         CLI   0(R3),C'9'              At end of suffix table?
         BNE   DEACTCNX                No - don't write err msg
         BAS   R14,X2C                 Convert to EBCDIC
         MVC   WRTBUFF(L'DACTERR),DACTERR Copy error message
         STCM  R1,B'0011',WRTBUFF+DACRCOFF Copy EBCDIC RC
         ICM   R1,B'1111',RSN          Load reason code
         BAS   R14,X2C                 Convert to EBCDIC
         STCM  R1,B'0011',WRTBUFF+DACRSOFF Copy EBCDIC RSN
         MVI   WRTBUFF+L'DACTERR,NEWLINE Add "Newline" character
         LA    R1,L'DACTERR+1          Load total message length
         ST    R1,WRTBUFL                 and store
         BAS   R14,WRTERR              Write message to STDERR
DEACTCNX DS    0H
         L     R15,RC                  Load return code
         PR                            Return
*
*---------------------------------------------------------------------*
*                                                                     *
*  Routine:     GETMSGS                                               *
*  Environment: Sets ASC mode AR                                      *
*  Function:    Process all messages queued to the console            *
*  Operation:   While there are messages queued to the console, keep  *
*               retrieving MDBs. For each MDB, loop through its       *
*               objects and look for the general object, a control    *
*               program object, and any text objects.                 *
*  Error:       Issue WTO if MCSOPMSG fails and set termination flag. *
*  Register Usage:                                                    *
*                                                                     *
*---------------------------------------------------------------------*
GETMSGS  DS    0H
         BAKR  R14,0                   Save status
MSGLP    DS    0H
         SAC   0                       Set primary mode
         SYSSTATE ASCENV=P             Let macros know
         MODESET MF=(E,SUP)            Set supervisor state
         SAC   512                     Set AR mode
         SYSSTATE ASCENV=AR            Let macros know
         MCSOPMSG REQUEST=GETMSG,CONSID=CNID,RTNCODE=RC,RSNCODE=RSN,   X
               MF=(E,MCSOPMSG)         Get a message
         LAE   R8,0(0,R1)              Load MDB address
         USING MDB,R8                  MDB addressability
         SAC   0                       Set primary mode
         SYSSTATE ASCENV=P             Let macros know
         MODESET MF=(E,PROB)           Set problem state
         SAC   512                     Set AR mode
         SYSSTATE ASCENV=AR            Let macros know
         LAE   R1,0(R1,0)              Clear AR
         MVI   MDBFLGS,X'00'           Clear processing flags
         ICM   R1,B'1111',RC           Load RC
         C     R1,=F'8'                Check return code
         BL    GOTMDB                  Process MDB (RC<8)
         BNH   GETMSGSX                Return (RC=8; no msgs)
         BAS   R14,X2C                 Convert to EBCDIC
         MVC   WRTBUFF(L'OPMGERR),OPMGERR Copy error message
         STCM  R1,B'0011',WRTBUFF+OPMRCOFF Copy EBCDIC RC
         ICM   R1,B'1111',RSN          Load reason code
         BAS   R14,X2C                 Convert to EBCDIC
         STCM  R1,B'0011',WRTBUFF+OPMRSOFF Copy EBCDIC RSN
         MVI   WRTBUFF+L'OPMGERR,NEWLINE Add "Newline" character
         LA    R1,L'OPMGERR+1          Load total message length
         ST    R1,WRTBUFL                 and store
         BAS   R14,WRTMSG              Write message to STDOUT
GETMSGSX DS    0H
         PR                            Return
*
*---------------------------------------------------------------------*
*                                                                     *
*  GOTMDB:   Entry via branch (not a subroutine)                      *
*  Function: Process the general object and control program object    *
*            for a message.  Assumptions must not be made that these  *
*            objects will preceed any text objects.                   *
*                                                                     *
*---------------------------------------------------------------------*
GOTMDB   DS    0H
         LR    R5,R8                   Calc end of MDB in R5
         AH    R5,MDBLEN               Point to end of MDB
         LR    R6,R8                   Remember start of MDB
         LA    R8,MDBHLEN(R8)          Bump to 1st object
OBJLOOP  DS    0H                      Loop through the objects
         LH    R3,MDBTYPE              Get object type
         C     R3,=A(MDBGOBJ)          General object?
         BNE   NOTG                      No, cont
         TM    MDBFLGS,MDBFGO          First general object?
         BO    NXTOBJ                    No, skip it
         BAL   R14,GENMDB              Process general object
         B     NXTOBJ                  Bump to next object
NOTG     DS    0H
         C     R3,=A(MDBCOBJ)          Is this a control prog object?.
         BNE   NOTC                      No, cont
         TM    MDBFLGS,MDBFCO          Do we already have a SCP?
         BO    NXTOBJ                    Yes, skip it
         BAL   R14,CPMDB               Process control prog object
         B     NXTOBJ                  Bump to next object
NOTC     DS    0H                      Not control prog obj
NXTOBJ   DS    0H                      Find next object
         TM    MDBFLGS,MDBFGO+MDBFCO   See if we found general and SCP
         BO    FNDTXT                  Got them, loop through text objs
         AH    R8,MDBLEN               Bump to next object
         CR    R8,R5                   Is this is the end?
         BL    OBJLOOP                   No, get another object
         B     MSGLP                   Missing necessary objects
*
*---------------------------------------------------------------------*
*                                                                     *
*  FNDTXT:   Entry via branch (not a subroutine)                      *
*  Function: Process all text objects in all MDBs for this message.   *
*            Text objects are always ordered, but it cannot be        *
*            assumed that they are contiguous.                        *
*                                                                     *
*---------------------------------------------------------------------*
FNDTXT   DS    0H
         LR    R8,R6                   Reset R8 to start of MDB
TXTLP    DS    0H
         LR    R5,R8                   Calcuate end of MDB
         AH    R5,MDBLEN               Start+mdblen in header
         LAE   R6,0(0,R8)              Calc prefix address in R6
         SH    R6,=AL2(MDBPLNNO)       Prefix=start-prefix length
         USING MDBPRFX,R6              Get addressability
         L     R6,MDBPNEXT             Get forward pointer in R6
         DROP  R6                      R6 no longer base for prefix
         LA    R8,MDBHLEN(R8)          Bump to 1st object
TOBJLP   DS    0H                      Loop through the objects
         LH    R3,MDBTYPE              Get type
         C     R3,=A(MDBTOBJ)          Check for text object
         BNE   NOTT                    Not text object
         BAL   R14,TEXTMDB             Process text object
NOTT     DS    0H
         AH    R8,MDBLEN               Bump to next object
         CR    R8,R5                   Is this the end?
         BL    TOBJLP                    No, get another object
         LTR   R6,R6                   Check for more MDBs for message
         BZ    MSGLP                   Done with message
         LR    R8,R6                   Next MDB
         B     TXTLP                   Process the MDB
         DROP  R8
*
*---------------------------------------------------------------------*
*                                                                     *
*  Routine:     GENMDB                                                *
*  Environment: ASC Mode AR                                           *
*  Function:    Process MDB General Object                            *
*  Operation:   Indicate general object MDB was processed             *
*  Register Usage:                                                    *
*               R8:  Address of General Object                        *
*                                                                     *
*---------------------------------------------------------------------*
         SYSSTATE ASCENV=AR            Let macros know AR mode
GENMDB   DS    0H
         BAKR  R14,0                   Save status
         USING MDBG,R8                 General object addressability
         OI    MDBFLGS,MDBFGO          Set processed general object
         PR
         DROP  R8
*
*---------------------------------------------------------------------*
*                                                                     *
*  Routine:     CPMDB                                                 *
*  Environment: ASC Mode AR                                           *
*  Function:    Process MDB Control Program Object                    *
*  Operation:   Indicate control program object MDB was processed     *
*               Save text offset for text processing                  *
*  Register Usage:                                                    *
*               R8:  Address of Control Program Object                *
*                                                                     *
*---------------------------------------------------------------------*
         SYSSTATE ASCENV=AR            Let macros know AR mode
CPMDB    DS    0H
         BAKR  R14,0                   Save status
         USING MDBSCP,R8               CP object addressability
         CLC   MDBCPNAM,=C'MVS '       Is this an MVS object?
         BNE   CPMDBX                    No, skip it
         OI    MDBFLGS,MDBFCO          Remember we've been here
         LH    R1,MDBCTOFF             Load offset to message text
         ST    R1,TEXTOFF                 and store
CPMDBX   DS    0H
         PR
         DROP    R8
*
*---------------------------------------------------------------------*
*                                                                     *
*  Routine:     TEXTMDB                                               *
*  Environment: ASC Mode AR                                           *
*  Function:    Process text object in MDB                            *
*  Operation:   Write message text to STDOUT                          *
*  Register Usage:                                                    *
*               R8:  Address of Text Object                           *
*                                                                     *
*---------------------------------------------------------------------*
         SYSSTATE ASCENV=AR            Let macros know AR mode
TEXTMDB  DS    0H
         BAKR  R14,0                   Save status
         USING MDBT,R8                 Text object addressability
         LH    R1,MDBTLEN              Get text object length
         S     R1,=A(MDBTMSGT-MDBTLEN) Subtract non-text size
         BZ    TEXTMDBX                Return if zero
         S     R1,TEXTOFF              Take off offset to text
         BNH   TEXTMDBX                Return if <= zero
         C     R1,=A(L'WRTBUFF-1)      Is message too long for buffer?
         BNH   WRTTEXT                    No, cont
         L     R1,=A(L'WRTBUFF-1)      Truncate message to fit in buf
WRTTEXT  DS    0H
         LAE   R5,MDBTMSGT             Get address of text data
         A     R5,TEXTOFF              Point to msg text
         BCTR  R1,0                    Reduce for EXecute
         EX    R1,COPYTMDB             Copy msg text to write buffer
         LAE   R2,WRTBUFF              Point to write buffer
         LA    R2,1(R1,R2)             Point past end of msg text
         MVI   0(R2),NEWLINE           Add new line character
         LA    R1,2(,R1)               Load complete length
         ST    R1,WRTBUFL                 and store
         BAS   R14,WRTMSG              Write message to STDOUT
TEXTMDBX DS    0H
         PR
COPYTMDB MVC   WRTBUFF(0),0(R5)        *** EXecute ***
         DROP  R8
*
*---------------------------------------------------------------------*
*                                                                     *
*  Routine:     STIMERM Exit Routine                                  *
*  Environment: ASC Mode Primary                                      *
*  Function:    POST ECB to stop waiting for console response         *
*                                                                     *
*---------------------------------------------------------------------*
         SYSSTATE ASCENV=P             Let macros know we're in primary
STMREXIT DS    0H
         BAKR  R14,0                   Save status
         L     R13,4(,R1)              Restore R13
         POST  TIMEECB                 POST timer ECB
         PR                            Return
*
*---------------------------------------------------------------------*
*                                                                     *
*  Routine:     BLKLINE                                               *
*  Environment: ASC Mode Primary                                      *
*  Function:    Write a blank line to file descriptor 0 (STDOUT)      *
*                                                                     *
*---------------------------------------------------------------------*
         SYSSTATE ASCENV=P             Let macros know we're in primary
BLKLINE  DS    0H
         BAKR  R14,0                   Save status
         MVI   WRTBUFF,NEWLINE         Put "Newline" character
         LA    R1,1                    Load message length
         ST    R1,WRTBUFL                 and store
         BAS   R14,WRTMSG              Write message to STDOUT
         PR                            Return
*
*---------------------------------------------------------------------*
*                                                                     *
*  Routine:     WRTMSG                                                *
*  Environment: ASC Mode Primary                                      *
*  Function:    Write data buffer to file descriptor 0 (STDOUT)       *
*                                                                     *
*---------------------------------------------------------------------*
         SYSSTATE ASCENV=P             Let macros know we're in primary
WRTMSG   DS    0H
         BAKR  R14,0                   Save status
* Line below inserted to allow multi line output
         SAC   0                       Set Primary ar mode
         L     R15,WRTENTRY            Load address of BPX1WRT module
         CALL  (15),                   Write to a file                 +
               (STDOUT,                Input: File descriptor          +
               @WRTBUF,                Input: ->Buffer                 +
               ALET0,                  Input: Buffer ALET              +
               WRTBUFL,                Input: Number of bytes to write +
               RETVAL,                 Ret value: -1 or bytes written  +
               RETCODE,                Return code                     +
               RSNCODE),               Reason code                     +
               VL,MF=(E,PLIST)         -------------------------------
         ICM   R15,B'1111',RETVAL      Test RETVAL
         BL    WRTMSGE                 Branch if negative (-1=failure)
         PR                            Return
WRTMSGE  DS    0H
         WTO   'OECONSOL: WRTMSG Error'
         L     R0,RETCODE
         L     R1,RSNCODE
         DC    H'0000'
*
*---------------------------------------------------------------------*
*                                                                     *
*  Routine:     WRTERR                                                *
*  Environment: ASC Mode Primary                                      *
*  Function:    Write data buffer to file descriptor 2 (STDERR)       *
*                                                                     *
*---------------------------------------------------------------------*
         SYSSTATE ASCENV=P             Let macros know we're in primary
WRTERR   DS    0H @GH1
         BAKR  R14,0                   Save status
* Line below inserted to allow multi line output
         SAC   0                       Set Primary ar mode
         L     R15,WRTENTRY            Load address of BPX1WRT mod
         CALL  (15),                   Write to a file                 +
               (STDERR,                Input: File descriptor          +
               @WRTBUF,                Input: ->Buffer                 +
               ALET0,                  Input: Buffer ALET              +
               WRTBUFL,                Input: Number of bytes to write +
               RETVAL,                 Ret value: -1 or bytes written  +
               RETCODE,                Return code                     +
               RSNCODE),               Reason code                     +
               VL,MF=(E,PLIST)         -------------------------------
         ICM   R15,B'1111',RETVAL      Test RETVAL
         BL    WRTMSGE                 Branch if negative (-1=failure)
         PR                            Return
*
*---------------------------------------------------------------------*
*                                                                     *
*  Routine:     X2C                                                   *
*  Environment: N/A                                                   *
*  Function:    Convert a passed fullword to an EBCDIC double word    *
*  Operation:                                                         *
*  Register Usage:                                                    *
*               R1  - Binary word to be converted                     *
*                                                                     *
*---------------------------------------------------------------------*
X2C      DS    0H
         BAKR  R14,0                   Save the input status
         LR    R2,R1                   Load word to be converted
         L     R4,=X'0F0F0F0F'         Load boolean mask
         LR    R3,R2                   Return code
         SRL   R3,4                    Shift
         NR    R3,R4                   Separate
         NR    R4,R2                          bytes
         STM   R3,R4,X2CWRK1           Store
         TR    X2CWRK1(8),=C'0123456789ABCDEF' Translate into alpha
         MVC   X2CWRK2(8),=X'0004010502060307'
         TR    X2CWRK2(8),X2CWRK1      Rearrange bytes
         LM    R0,R1,X2CWRK2           Load char data
         PR                            Return
*
         LTORG
*---------------------------------------------------------------------*
*                                                                     *
*        Static Storage Area                                          *
*                                                                     *
*---------------------------------------------------------------------*
*
MAXCMD   EQU   X'126'
NEWLINE  EQU   X'15'
ALET0    DC    F'0'
STDIN    DC    F'0'
STDOUT   DC    F'1'
STDERR   DC    F'2'
SUFFIX   DC    C' ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'        @GH1
CONSMSG  DC    C'<OECONSOL>'
CMDLNMSG DC    C'Command length > 126'
ACTERR   DC    C'Extended console activation failed RC=xx,RSN=xx'
         ORG   ACTERR
         DC    C'Extended console activation failed RC='
ACTRCOFF EQU   *-ACTERR
         ORG   ACTERR
         DC    C'Extended console activation failed RC=xx,RSN='
ACTRSOFF EQU   *-ACTERR
         ORG   ACTERR+L'ACTERR
DACTERR  DC    C'Extended console deactivation failed RC=xx,RSN=xx'
         ORG   DACTERR
         DC    C'Extended console deactivation failed RC='
DACRCOFF EQU   *-DACTERR
         ORG   DACTERR
         DC    C'Extended console deactivation failed RC=xx,RSN='
DACRSOFF EQU   *-DACTERR
         ORG   DACTERR+L'DACTERR
OPMGERR  DC    C'Error retrieving operator message RC=xx,RSN=xx'
         ORG   OPMGERR
         DC    C'Error retrieving operator message RC='
OPMRCOFF EQU   *-OPMGERR
         ORG   OPMGERR
         DC    C'Error retrieving operator message RC=xx,RSN='
OPMRSOFF EQU   *-OPMGERR
         ORG   OPMGERR+L'OPMGERR
STMRINTV DC    X'0000012C'             Default timeout = 3 secs
STMRLRGE DC    X'000003E8'
         DS    0F
DIGITZERO DC   X'000000F0'             Digit zero as number
OMVSTERM DC    CL8'OMVS'
CMDBUFL  DC    AL4(L'CMDBUFF)
*
*---------------------------------------------------------------------*
*                                                                     *
*        Macro expansions                                             *
*                                                                     *
*---------------------------------------------------------------------*
MACDEF   DS    0D
         MODESET MODE=SUP,MF=L         MODESET parm list for sup state
         MODESET MODE=SUP,KEY=ZERO,MF=L MODESET plist for sup state 0
         MODESET MODE=PROB,KEY=NZERO,MF=L MODESET plist for prob state
         MGCRE   MF=L                  MGCRE plist
         STIMERM SET,MF=L              STIMERM plist
         STIMERM CANCEL,MF=L           STIMERM plist
MACLEN   EQU   *-MACDEF
*
*---------------------------------------------------------------------*
*                                                                     *
*        Translate Tables                                             *
*                                                                     *
*---------------------------------------------------------------------*
UPCASETR DC    256AL1(*-UPCASETR) Null translate table
         ORG   UPCASETR+C'A'-C' ' Lower case A
         DC    C'ABCDEFGHI'
         ORG   UPCASETR+C'J'-C' ' Lower case J
         DC    C'JKLMNOPQR'
         ORG   UPCASETR+C'S'-C' ' Lower case S
         DC    C'STUVWXYZ'
         ORG   ,
*
*---------------------------------------------------------------------*
*                                                                     *
*        Register Equates                                             *
*                                                                     *
*---------------------------------------------------------------------*
R0      EQU    0
R1      EQU    1
R2      EQU    2
R3      EQU    3
R4      EQU    4
R5      EQU    5
R6      EQU    6
R7      EQU    7
R8      EQU    8
R9      EQU    9
R11     EQU    11
R12     EQU    12
R13     EQU    13
R14     EQU    14
R15     EQU    15
*
         TITLE 'OECONSOL   - Mapping Macros'
*---------------------------------------------------------------------*
*                                                                     *
*        Required mapping macros                                      *
*                                                                     *
*---------------------------------------------------------------------*
         IEAVG132 ,                    MDB prefix
         IEAVM105 ,                    MDB
         IEAVG131 ,                    Console status area
         IEZVG111 ,                    Operparm parameter area
         END  ,
/*
//*
//LKED1    EXEC PGM=IEWL,PARM='XREF,LET,LIST,NCAL,RENT,REFR,AC=1',
//          COND=(04,LT)
//SYSLMOD  DD DISP=SHR,DSN=&LIBRARY
//SYSLIN   DD DSN=&&OBJSET,DISP=(OLD,PASS)
//         DD DDNAME=SYSIN
//SYSUT1   DD DSN=&&SYSUT1,UNIT=SYSDA,SPACE=(CYL,(1,1))
//SYSPRINT DD SYSOUT=*
//SYSIN   DD  *
  ENTRY OECONSOL
  NAME OECONSOL(R)
/*
//* And create a USS file with the sticky bit on
//TOUCH   EXEC PGM=BPXBATCH,REGION=6M,
//   PARM='sh cd &DIR; touch oeconsol; chmod 1755 oeconsol'
