/* rexx */
/****PROPRIETARY_STATEMENT********************************************/
/*                                                                   */
/*   Licensed Materials - Property of IBM                            */
/*   5694-A01 Copyright IBM Corp. 2010, 2010                         */
/*                                                                   */
/*   Status = HOT7770                                                */
/*                                                                   */
/****END_OF_PROPRIETARY_STATEMENT*************************************/
/*                                                                   */
/*  Source File: tsocmd (REXX)                                       */
/*                                                                   */
/*  Source File Description: tsocmd runs a TSO/E command from the    */
/*   shell using the TSO/E TMP (IKJEFT01).  Unlike the tso command,  */
/*   the tsocmd command can be used to issue authorized TSO/E        */
/*   commands. The TSO/E TMP is run in a separate address space and  */
/*   process from the tsocmd command, therefore any issued TSO/E     */
/*   commands will not affect the environment the tsocmd is issued   */
/*   from.                                                           */
/*                                                                   */
/*                                                                   */
/* Change Activity:                                                  */
/*                                                                   */
/* FLAG REASON    RELEASE  DATE   PROGRAMMER CHANGE DESCRIPTION      */
/* ---- --------  -------  ------ ---------- ------------------      */
/* $A0  ME15895   HOT7770  090331 ROCH       Created for DCR B780.00 */
/*                                                                   */
/*********************************************************************/

  /* Global variables: if needed by function, need to be on functions
     procedure expose statement. It can be easiest to just put on
     all such statements.                                            */
  catdesc = -1                     /* Message catalog descriptor     */
  dbgLvl = 0                       /* Initialize debug level to none
                                      where
                                      0 - no debug activity
                                      1 - get additional messaging
                                      2 - get messages and trace all */
  /* End of global variables, will also use standard ESC_N variable. */

  Parse arg command                /* Determine input value.         */

  If command = ' ' Then            /* Determine if value was passed for
                                      command string.                */
    Do                             /* Do for no command data.        */
      Call usage                   /* If no data was passed, then send
                                      Usage message and exit.        */
    End                            /* End do for no command data.    */
  Else
    Do                             /* Do for have command data.      */
      dbgLvl = checkDebug(command) /* Determine debug level.         */
      /* Remove the debug-related characters from the command string */
      /*  so only work on command user specified without -d or -dd.  */
      If dbgLvl > 0 Then
        Do                         /* Do for have a debug level set. */
           command = substr(command,(3 + dbgLvl))
        End                        /* End Do for Have a debug level. */
    End                            /* End Do for have command data.  */

  /* Check debug level for tracing and turn it on, do it here instead
     of in nested Ifs above so start tracing at start of main code.  */
  If dbgLvl > 1 Then Trace 'I'

  Call dbgInfo 'Input cmd = '||command  /* If debugging echo command.*/

  Call procEnvVar                  /* Process environment variables as
                                      appropriate.  Control will not
                                      return if an error occurs.     */

  /* Echo the command string (mimics behavior of tso command code).
     Duplicate of debug information line above, but wanted that line
     to clearly call out that it was the input command, and wanted it
     first while the code I am mimicing has the command repeat just
     before the call to do the tso command work, and does not have
     any additional text.                                            */
  Call sendMsg 2,-1,command

  Address tso command              /* Pass the input command argument
                                      to the TSO/E TMP facility.     */
  error = rc                       /* Save away the return code from
                                      the called TSO command.        */

  Select                           /* Process the return codes.      */
    When error = -3 Then           /* Return code indicates TSO
                                      command was not found.         */
      Do                           /* Send appropriate error message.*/
        Call sendMsg 2,5451,"tsocmd: TSO/E command ""%%"" not found.",
           ,command
        error = 255                /* Set return code to 255.        */
      End                          /* End Do for error = -3.         */
    When (error < 0) | (error > 254)
      Then                         /* Return code not a value which
                                      can be returned.               */
      Do                           /* Send appropriate error message.*/
        Call sendMsg 2,5452,
           ,"tsocmd: Unexpected error occurred processing TSO/E command ""%%"", return code %%.",
           ,command,error
        error = 255                /* Set return code to 255.        */
      End                          /* End for error < 0 & > 254.     */
    Otherwise
      Do
        /* Do nothing, return tso command return code as is.  Message
           should have been sent if there was an error.              */
      End
  End                              /* End select on return code.     */

  Call cleanup                     /* Call cleanup function.         */

  Call dbgInfo 'Return = '||error  /* If debugging echo return code. */

  Return error                     /* Return return code, if any.    */
/* End of main code path                                             */

/*--   START OF FUNCTION SPECIFICATIONS   -----------------------------
//
// Function Name       : sendMsg
//
// Function Description: Sends a message to the specified file descriptor.
//
// Dependencies        : catdesc has been defined for catalog descriptor,
//                       it will be modified by a function that is
//                       called by this function.
//                       Any messages sent by this will use %% in the
//                       messages to represent substitution variables.
//
// Restrictions        : The maximum message limit is 4096 bytes.
//                       Anything over that limit will be truncated.
//
// Input               : filedesc - file descriptor to send message to
//                                  where we assume:
//                                  1 = standard out (stdout)
//                                  2 = standard error (stderr)
//                       msgNum  - message number from the catalog, specify
//                                 -1 to skip catalog processing
//                       mtextin - message text to use if catalog
//                                 retrieve fails or if skipped catalog
//                       arg(4-n)- substitution text for the message,
//                                 if any.
//
// Exit Normal
//   Return Value      : None.
//   Outputs           : Message is sent to the file descriptor.
//
// Exit Error
//   Return Value      : None.
//   Outputs           : Unknown.
//
// Notes               : None.
//
//--   END OF SPECIFICATIONS   --------------------------------------*/
sendMsg: Procedure expose dbgLvl catdesc ESC_N
   Parse arg filedesc, msgNum, mtextin   /* Determine passed values  */

   If msgNum <> -1 Then            /* Are we to work with catalog?   */
     Do                            /* Do for work with catalog.      */
       /* Set message text using message ID or default text,
          append a new line.                                         */
       mtext = getMsg(msgNum, mtextin) || ESC_N
     End                           /* End Do for work with catalog.  */
   Else                            /* Just use input data as is.     */
     Do                            /* Do for use input data as is.   */
       mtext = mtextin || ESC_N    /* Set data to input data, append
                                      a new line.                    */
     End                           /* End Do for use input data as is*/

   /* Loop over the remaining substitution text, if any, replace
      the %%'s in message with substitution variables values.        */
   Do si = 4 to arg()
     Parse var mtext mtpref '%%' mtsuf /* Determine strings before
                                          and after the first %%.    */
     mtext = mtpref||arg(si)||mtsuf    /* Change text to have before
                                          text, then substitution
                                          var value, then after.     */
   End                             /* End Do loop over subst vars.   */

   /* Write the data to the specified descriptor                     */
   Address syscall "write " || filedesc || " mtext"

Return

/*--   START OF FUNCTION SPECIFICATIONS   -----------------------------
//
// Function Name       : getMsg
//
// Function Description: Retrieves message from the message catalog or
//                       returns input message if nothing found in the
//                       catalog.
//
// Dependencies        : catdesc has been defined for catalog descriptor,
//                       it will be modified by this function.
//
// Restrictions        : None.
//
// Input               : msgNum - message number from the catalog
//                       mtext  - message text to use if catalog
//                                retrieve fails
//
// Exit Normal
//   Return Value      : Retrieved message text.
//   Outputs           : Message text is retrieved.
//
// Exit Error
//   Return Value      : Default message text which was passed in.
//   Outputs           : Unknown.
//
// Notes               : None.
//
//--   END OF SPECIFICATIONS   --------------------------------------*/
getMsg: Procedure expose dbgLvl catdesc ESC_N
   Parse arg msgNum, mtext         /* Determine passed values.       */
   mset = 1                        /* Use this message set number
                                      for english.msf (all one set). */

   /* If we have not already opened the message catalog, open it.    */
   If catdesc = -1 Then
     Do
       Address syscall "catopen fsumrcat.cat" /* Open message catalog*/
       catdesc = retval            /* Determine return value, -1 is
                                      returned if an error.          */

       /* Send out additional information on catopen if debug on.    */
       Call dbgInfo 'catopen request, return code = '|| retval
     End

   /* Retrieve the message information, if possible.                 */
   If catdesc >= 0 Then
     Do
       Address syscall "catgets (catdesc) (mset) (msgNum) mtext"
     End

/* Return message text from catalog or default                       */
Return mtext

/*--   START OF FUNCTION SPECIFICATIONS   -----------------------------
//
// Function Name       : cleanup
//
// Function Description: Cleanup any resources.
//
// Dependencies        : catdesc has been defined for catalog descriptor,
//                       it will be modified by this function.
//
// Restrictions        : None.
//
// Input               : None.
//
// Exit Normal
//   Return Value      : None.
//   Outputs           : Resources cleaned up.
//
// Exit Error
//   Return Value      : None.
//   Outputs           : Unknown.
//
// Notes               : None.
//
//--   END OF SPECIFICATIONS   --------------------------------------*/
cleanup: Procedure expose dbgLvl catdesc ESC_N

  If (catdesc <> -1) Then          /* If we have opened the catalog  */
    Do
      Address syscall "catclose (catdesc)"  /* Close the catalog     */
      catdesc = -1                          /* Reset indicator       */
    End
Return

/*--   START OF FUNCTION SPECIFICATIONS   -----------------------------
//
// Function Name       : usage
//
// Function Description: Display usage message and exit.
//
// Dependencies        : None.
//
// Restrictions        : None.
//
// Input               : None.
//
// Exit Normal
//   Return Value      : None.
//   Outputs           : Usage message is displayed and program exits.
//
// Exit Error
//   Return Value      : None.
//   Outputs           : Unknown.
//
// Notes               : None.
//
//--   END OF SPECIFICATIONS   --------------------------------------*/
usage: Procedure expose dbgLvl catdesc ESC_N

/* Send the usage message to standard error                          */
  Call sendMsg 2,5450,"Usage: tsocmd [tsocommand]"

  Call cleanup                     /* Call cleanup function          */

/* Exit the command with return code 255                             */
Exit 255

/*--   START OF FUNCTION SPECIFICATIONS   -----------------------------
//
// Function Name       : procEnvVar
//
// Function Description: Process the following environment variables:
//                         SYSEXEC
//                         SYSPROC
//                         TSOALLOC
//                         TSOPROFILE
//                       If there is an error while processing the
//                       variables, control will not be returned to
//                       the invoker.
//
// Dependencies        : None.
//
// Restrictions        : None.
//
// Input               : None.
//
// Exit Normal
//   Return Value      : None.
//   Outputs           : Environment variable values have been processed.
//
// Exit Error
//   Return Value      : None.
//   Outputs           : Error message.
//
// Notes               : The first usage of Address tso in this REXX
//                       program will start a TSO 'environment'.  All
//                       subsequent Address tso calls will be working
//                       in the same environment.  This environment
//                       will be active until the REXX program ends
//                       which is why the processing which occurs in
//                       this function will be in effect when the
//                       users tso command is invoked in the main
//                       code path.
//
//--   END OF SPECIFICATIONS   --------------------------------------*/
procEnvVar: Procedure expose dbgLvl catdesc ESC_N

  Call dbgInfo 'Processing Environment Variables'

  /* Process the TSOALLOC, SYSEXEC, and SYSPROC Environment          */
  /*   variables.  Only process the SYSEXEC and SYSPROC variables    */
  /*   if TSOALLOC has not been specified.                           */
  If (1 = Environment('TSOALLOC',,'e')) Then /* Is the variable
                                                defined?             */
    Do                             /* Do for Variable is defined.    */
      /* Retrieve environment variable value.                        */
      envvarInfo = Environment('TSOALLOC')
      Call dbgInfo 'Processing TSOALLOC ev = '||envvarInfo

      rtn = 0                      /* Initialize return code.        */

      /* The TSOALLOC variable information is a series of environment
         variable names, separated by colons,
         which should be processed for data set allocations.         */

      /* Determine first piece of info, prior to first : or all of it
         if no : .                                                   */
      Parse var envvarInfo infoBef ':' infoAft

      Do While infoBef <> ' '      /* While info still to process.   */
        /* Allocate data set according to data in associated         */
        /*  variable. Increment return code as want to keep          */
        /*  processing the allocations, but need to exit if had      */
        /*  any failures.  This behavior of continuing to process    */
        /*  allocation requests even if we had one failure mimics    */
        /*  the existing code in tso command and the Tools and Toys  */
        /*  version of the tsocmd command.                           */
        rtn = rtn + allocDataset(Environment(infoBef),infoBef)

        /* Determine next item to process                            */
        Parse var infoAft infoBef ':' infoAft

      End                          /* End Do while on infoBef.       */

      If rtn > 0 Then              /* Check allocDataset return value*/
        Do
          /* Send failure message, indicate send message without
             a return code value, control does not return.           */
          Call sendEnvVarMsg 'TSOALLOC',0
        End                        /* End Do for non zero return code*/
    End                            /* End Do for Variable is defined.*/
  Else                             /* TSOALLOC is not defined.       */
    Do                             /* Do for TSOALLOC is not defined.*/
      /* Process the SYSPROC environment variable.                   */
      If (1 = Environment('SYSPROC',,'e')) Then /* Is the variable
                                                   defined?          */
        Do                         /* Do for Variable is defined.    */
          /* Retrieve environment variable value.                    */
          envvarInfo = Environment('SYSPROC')
          Call dbgInfo 'Processing SYSPROC ev = '||envvarInfo

          /* Process the information in the SYSPROC variable.        */
          rtn = allocDataset(envvarInfo,'SYSPROC')
          If rtn > 0 Then          /* Any errors?                    */
            Do
              /* Send failure message, indicate send message without
                 a return code value, control does not return.       */
              Call sendEnvVarMsg 'SYSPROC',0
            End                    /* End Do for any errors.         */
        End                        /* End Do for variable is defined.*/

      /* Process the SYSEXEC environment variable.                   */
      If (1 = Environment('SYSEXEC',,'e')) Then /* Is the variable
                                                   defined?          */
        Do                         /* Do for Variable is defined.    */
          /* Retrieve environment variable value.                    */
          envvarInfo = Environment('SYSEXEC')
          Call dbgInfo 'Processing SYSEXEC ev = '||envvarInfo
          /* Process the information in the SYSEXEC variable         */
          rtn = allocDataset(envvarInfo,'SYSEXEC')
          If rtn > 0 Then          /* Any errors?                    */
            Do
              /* Send failure message, indicate send message without
                 a return code value, control does not return.       */
              Call sendEnvVarMsg 'SYSEXEC',0
            End                    /* End Do for any errors.         */
        End                        /* End Do for variable is defined.*/
    End                            /* End Do for TSOALLOC not defined*/

  /* Process the TSOPROFILE Environment variable.                    */
  If (1 = Environment('TSOPROFILE',,'e')) Then /* Is the variable
                                                  defined?           */
    Do                             /* Do for Variable is defined.    */
      envvarInfo = Environment('TSOPROFILE')
      Call dbgInfo 'Processing TSOPROFILE ev = '||envvarInfo
      cmdString = 'profile '||envvarInfo  /* Build command info.     */
      Address tso cmdString        /* Process profile command.       */

      If rc <> 0 Then              /* Check return value from
                                      address tso request.           */
        Do
          /* Echo the command string in this case (mimics behavior of
             tso command code).                                      */
          Call sendMsg 2,-1,cmdString
          /* Send failure message with a return code, control does
             not return.                                             */
          Call sendEnvVarMsg 'TSOPROFILE',rc
        End                        /* End Do for non zero return code*/
    End                            /* End Do for variable is defined.*/

Return

/*--   START OF FUNCTION SPECIFICATIONS   -----------------------------
//
// Function Name       : allocDataset
//
// Function Description: Allocate data set with the specified
//                       information.
//
// Dependencies        : None.
//
// Restrictions        : None.
//
// Input               : names - allocation information for dd
//                       dd    - data set to be allocated
//
// Exit Normal
//   Return Value      : 0 if allocation completed
//                       1 if allocation had an error
//   Outputs           : Data set allocated as requested
//
// Exit Error
//   Return Value      : 1 if allocation had an error
//   Outputs           : Unknown
//
// Notes               : None.
//
//--   END OF SPECIFICATIONS   --------------------------------------*/
allocDataset: Procedure expose dbgLvl catdesc ESC_N
  Parse arg names, dd               /* Determine passed values.      */

  /* If no value for the allocation information, then will allocate
     a dummy data set.                                               */
  If names = ' ' Then
    Do                             /* Do for no names value.         */
      /* Build command string for dummy allocation request.          */
      cmdString = "alloc dd("||dd||") dummy"
      Call dbgInfo 'Dummy allocation cmd = '||cmdString

      Address tso cmdString        /* Process alloc command.         */
      If rc <> 0 Then              /* Check return value from
                                      address tso request.           */
        Do                         /* Do for non zero return code.   */
          /* Send informational failure message.                     */
          Call sendMsg 2,5455,
            ,"tsocmd: Data set not allocated to %%: %%, return code %%.",
            ,dd,"dummy",rc
          Return 1                 /* Return indicating failure.     */
        End                        /* End Do for non zero return code*/
      Else
        Return 0                   /* Return indicating success.     */
    End                            /* End Do for no names value.     */

  /* Grab first part of names field, and upper case it so can
     determine if direct ALLOC request.  Also ensure the ALLOC is
     followed by a blank.  This must be done as two separate checks
     where the blanks is specifically checked on its own.            */
  If (translate(substr(names,1,5)) = 'ALLOC' & (substr(names,6,1)=' '))
  Then
    Do                             /* Do for alloc request.          */
      /* Build command string with specified alloc information.      */
      cmdString = "alloc dd("||dd||") "||substr(names,7)
      Call dbgInfo 'ALLOC allocation cmd = '||cmdString

      Address tso cmdString        /* Process alloc command.         */
      If rc <> 0 Then              /* Check return value from
                                      address tso request.           */
        Do                         /* Do for non zero return code.   */
          /* Send informational failure message.                     */
          Call sendMsg 2,5456,
            ,"tsocmd: Data set not allocated for DD %% with command ""%%"", return code %%.",
            ,dd,cmdString,rc
          Return 1                 /* Return indicating failure.     */
        End                        /* End Do for non zero return code*/
      Else
        Return 0                   /* Return indicating success.     */
    End                            /* End Do for alloc request.      */

  /* If not dummy or direct ALLOC request, then process the
     string for information to specify on ALLOC request.             */

  /* Determine first piece of info, prior to first : or all of it
     if no : .                                                       */
  Parse var names dsnBef ':' dsnAft
  delim = ''                       /* This will be needed to build
                                      dslist if more than one, start
                                      with blank.                    */
  dslist = ''                      /* Start list with blanks.        */
  msgdslist = ''                   /* Start message list with blanks */
  /* Need to loop over names in order to process concatenation.      */
  Do While dsnBef <> ' '           /* While info still to process.   */
    /* Append data set name to list of data sets, put quotes around
       dslist entries so no prefix work will occur, matches tso
       command behavior.                                             */
    dslist = dslist||delim||''''||dsnBef||''''
    /* Create list of data sets without quotes, in case need to send
       a message so we can mimic message presentation of the tso
       command.                                                      */
    msgdslist = msgdslist||delim||dsnBef

    /* Determine next item to process                                */
    Parse var dsnAft dsnBef ':' dsnAft

    delim = ','                    /* Reset delimiter to comma for
                                      additional data sets.          */
  End                              /* End Do while on infoBef.       */

  /* Set up command string with created data set list.  This         */
  /*  request (e.g. usage of shr) mimics the request in the tso      */
  /*  command and Tools and Toys version of tsocmd command.          */
  cmdString = 'alloc dd('||dd||') dsname('||dslist||') shr'
  Call dbgInfo 'Other allocation cmd = '||cmdString

  Address tso cmdString            /* Process alloc command.         */
  If rc <> 0 Then                  /* Check return value from
                                      address tso request.           */
    Do                             /* Do for non zero return code.   */
      /* Send informational failure message.                         */
      Call sendMsg 2,5455,
        ,"tsocmd: Data set not allocated to %%: %%, return code %%.",
        ,dd,msgdslist,rc
      Return 1                     /* Return indicating failure.     */
    End                            /* End Do for non zero return code*/
  Else
    Return 0                       /* Return indicating success.     */

Return 0                           /* Should never get here.         */

/*--   START OF FUNCTION SPECIFICATIONS   -----------------------------
//
// Function Name       : sendEnvVarMsg
//
// Function Description: Send the appropriate common environment variable
//                       message and then exit with 255 return code.
//
// Dependencies        : None.
//
// Restrictions        : None.
//
// Input               : envvarin - environment variable name
//                                  to be put in the message
//                       rcin - return code value to be put in
//                              the message.  If this is 0, then
//                              send message without return code.
//
// Exit Normal
//   Return Value      : None.
//   Outputs           : Environment variable failure message is
//                       displayed and the program exits.
//
// Exit Error
//   Return Value      : None.
//   Outputs           : Unknown.
//
// Notes               : None.
//
//--   END OF SPECIFICATIONS   --------------------------------------*/
sendEnvVarMsg: Procedure expose dbgLvl catdesc ESC_N
  Parse arg envvarin, rcin          /* Determine passed values.      */

  /* Send failure message with specified environment variable value. */
  If rcin = 0 Then
    Do                              /* No return code to specify.    */
      Call sendMsg 2,5454,
        ,"tsocmd: Unexpected error occurred processing environment variable ""%%"".",
        ,envvarin
    End
  Else
   Do                              /* Have return code to specify.   */
      Call sendMsg 2,5453,
        ,"tsocmd: Unexpected error occurred processing environment variable ""%%"", return code %%.",
        ,envvarin,rcin
    End

  Call cleanup                     /* Call cleanup function.         */
Exit 255

/*--   START OF FUNCTION SPECIFICATIONS   -----------------------------
//
// Function Name       : dbgInfo
//
// Function Description: Writes out information according to debug level.
//
// Dependencies        : dbgLvl has been set.
//
// Restrictions        : None.
//
// Input               : info - information to write if requested
//
// Exit Normal
//   Return Value      : None.
//   Outputs           : Information is written to standard error.
//
// Exit Error
//   Return Value      : None.
//   Outputs           : Unknown.
//
// Notes               : None.
//
//--   END OF SPECIFICATIONS   --------------------------------------*/
dbgInfo:  Procedure expose dbgLvl catdesc ESC_N
  Parse arg info                   /* Determine passed value.        */

  /* Determine if need to send debug information.                    */
  If dbgLvl > 0 Then
    Call sendMsg 2,-1,info         /* Send information; indicate to
                                      do no catalog work.            */
Return

/*--   START OF FUNCTION SPECIFICATIONS   -----------------------------
//
// Function Name       : checkDebug
//
// Function Description: Determine debug level if any.
//
// Dependencies        : None.
//
// Restrictions        : None.
//
// Input               : cmdInput - information passed to tsocmd
//
// Exit Normal
//   Return Value      : 0,1 or 2 for debug level
//   Outputs           : None.
//
// Exit Error
//   Return Value      : None.
//   Outputs           : Unknown.
//
// Notes               : Only looking for -d and -dd options.
//
//--   END OF SPECIFICATIONS   --------------------------------------*/
checkDebug:  Procedure expose dbgLvl catdesc ESC_N
  Parse arg cmdInput               /* Determine passed value.        */
  rtnDbg = 0                       /* Init return to 0.              */

  /* Was -dd specified (followed by blank)?  This must be done as two
     separate checks where the blanks is specifically checked on its
     own.                                                            */
  If ((substr(cmdInput,1,3) = '-dd') & (substr(cmdInput,4,1) = ' '))
  Then rtnDbg = 2                  /* Set debug level to get tracing
                                      and debug messages.            */
  Else
    Do
      /* Was -d specified (followed by blank)? This must be done as
         two separate checks where the blanks is specifically checked
         on its own.                                                 */
      If ((substr(cmdInput,1,2) = '-d') & (substr(cmdInput,3,1) = ' '))
      Then rtnDbg = 1              /* Set debug level to get debug
                                      messages.                      */
    End
Return rtnDbg
/* Must always end source with new line                              */

