/**REXX **************************************************************/
/*                              DOMCHK                      ZZ026184 */
/*-------------------------------------------------------------------*/
/* Copyright 2017 IBM Corp.                                          */
/*                                                                   */
/* Licensed under the Apache License, Version 2.0 (the "License");   */
/* you may not use this file except in compliance with the License.  */
/* You may obtain a copy of the License at                           */
/*                                                                   */
/* http://www.apache.org/licenses/LICENSE-2.0                        */
/*                                                                   */
/* Unless required by applicable law or agreed to in writing, software*/
/* distributed under the License is distributed on an "AS IS" BASIS, */
/* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. */
/* See the License for the specific language governing permissions and */
/* limitations under the License.                                   */
/*-------------------------------------------------------------------*/
/*01* CHANGE-ACTIVITY:                                               */
/*-------------------------------------------------------------------*/
/* 1509           Change verrel to contain period to compare to 2.1  */
/* 1604           Add check for /usr/lpp/internet/sbin/httpd         */
/*********************************************************************/
rc = Process_DOM_Check_Start()
if rc = 0 then do
  rc = Process_DOM_Check_Parms()
  if rc = 0 then do
    rc = Process_DOM_Main()
    if rc = 0 then do
      call Process_DOM_Check_Report
    end
  end
  call Process_DOM_Check_End
end
exit

/*-------------------------------------------------------------------*/
/* For debug purpose. Only run in SYSREXX environment                */
/*-------------------------------------------------------------------*/
/*
HZSLSTRT:
HZS_PQE_DEBUG = 1
HZS_PQE_FUNCTION_CODE = 'RUN'
HZS_PQE_LOOKATPARMS = 1
HZSLSTRT_RC = 0
HZSLSTRT_RSN = 'NONE'
HZSLSTRT_SYSTEMDIAG = 'NONE'
return HZSLSTRT_RC

HZSLSTOP:
HZSLSTOP_RC = 0
HZSLSTOP_RSN = 'NONE'
HZSLSTOP_SYSTEMDIAG = 'NONE'
return HZSLSTOP_RC

HZSLFMSG:
HZSLFMSG_RC = 0
HZSLFMSG_RSN = 'NONE'
HZSLFMSG_SYSTEMDIAG = 'NONE'
return HZSLFMSG_RC
*/

/*********************************************************************/
/* Function: Process_DOM_Check_Start                                 */
/*********************************************************************/
/* If HZSLSTRT is not successful all IBM Health Checker for z/OS     */
/* function calls will fail.                                         */
/*********************************************************************/
Process_DOM_Check_Start:
rc = 0
check_name = 'ZOSMIG_HTTP_SERVER_DOMINO_CHECK'
check_name = 'The Domino HTTP server check'
text = 'TEXT'
sysname = mvsvar(sysname)
date = DATE()                                          /*Get Run Date*/
timeStarted = word(date,1) DATE('M') word(date,3)"," TIME()
HZSLSTRT_RC = HZSLSTRT()
if HZSLSTRT_RC <> 0 then do        /* HZSLSTRT error             @01C*/
  if HZS_PQE_DEBUG = 1 then do     /* Report debug detail in REXXOUT */
    call LOGMSGS text,"  HZSLSTRT ACTIVATE PROCESSING HAS FAILED. RC="HZSLSTRT_RC /*1408*/
    call LOGMSGS text,"  HZSLSTRT RC" HZSLSTRT_RC
    call LOGMSGS text,"  HZSLSTRT RSN" HZSLSTRT_RSN
    call LOGMSGS text,"  HZSLSTRT SYSTEMDIAG" HZSLSTRT_SYSTEMDIAG
  end
  rc = 8                      /* Exit, check cannot be performed     */
end
else do
  if HZS_PQE_DEBUG = 1 then do
    call LOGMSGS text,' 'check_name' started at 'timeStarted' on 'sysname
    call LOGMSGS text,' Entering PROCESS_DOM_CHECK_START'
  end
  /*-----------------------------------------------------------------*/
  /*      Check the function code to determine what to do            */
  /*-----------------------------------------------------------------*/
  /*                  look for Init function                         */
  /*-----------------------------------------------------------------*/
  if HZS_PQE_FUNCTION_CODE = "INITRUN" then do
    if HZS_PQE_DEBUG = 1 then                                /* 0912 */
      call LOGMSGS text,"  HZS_PQE_CHKWORK is null with function code 'INITRUN'"
  end
  /*-----------------------------------------------------------------*/
  /*                  look for Run function                          */
  /*-----------------------------------------------------------------*/
  else if HZS_PQE_FUNCTION_CODE = "RUN" then do
    if HZS_PQE_DEBUG = 1 then                                /* 0912 */
      call LOGMSGS text,"  HZS_PQE_CHKWORK is "HZS_PQE_CHKWORK" with function code 'RUN'"
  end
end
return rc

/*********************************************************************/
/* Function: Process_DOM_Check_End                                   */
/*********************************************************************/
Process_DOM_Check_End:
HZSLSTOP_RC = HZSLSTOP()                  /* report check completion */
if HZS_PQE_DEBUG = 1 then do       /* Report debug detail in REXXOUT */
  call LOGMSGS text,' Entering Process_DOM_CHECK_END'
  call LOGMSGS text,"  HZSLSTOP RC" HZSLSTOP_RC
  call LOGMSGS text,"  HZSLSTOP RSN" HZSLSTOP_RSN
  call LOGMSGS text,"  HZSLSTOP SYSTEMDIAG" HZSLSTOP_SYSTEMDIAG
end
return

/*********************************************************************/
/* Function: Process_DOM_Check_Parms                                 */
/*********************************************************************/
Process_DOM_Check_Parms:
rc = 0
if HZS_PQE_DEBUG = 1 then
  call LOGMSGS text,' Entering Process_DOM_CHECK_PARMS'
if HZS_PQE_LOOKATPARMS = 1 then do /* HCHECK var that identifies parm attribute in parmlib */
  /*-----------------------------------------------------------------*/
  /*         User has specified overriding default parameter         */
  /*-----------------------------------------------------------------*/
  if HZS_PQE_DEBUG = 1 then do
    if HZS_PQE_PARMAREA = '' then
      call LOGMSGS text,'  There are no parms for this Check.'
    else
      call LOGMSGS text,'  Found HZS Parms: 'HZS_PQE_PARMAREA
  end
end
return rc

/*********************************************************************/
/* Function: Process_DOM_Main                                        */
/*********************************************************************/
/* - Checks System for Domino HTTP webserver                         */
/*********************************************************************/
PROCESS_DOM_MAIN:
xrc = 0
if HZS_PQE_DEBUG = 1 then
  call LOGMSGS text,' Entering Process_DOM_MAIN'
dom_server_found = 0
na_env = 0
sysLvl = mvsvar(sysopsys)
parse var syslvl os ver'.'rel'.' .
ver = format(ver)
rel = format(rel)
verrel = ver'.'rel     /* add period between for compare to 2.1 1509 */
if verrel <= 2.1 then do    /* change 21 to 2.1 for compare     1509 */
  say;say '  This system is at level 'os' Rel 'ver'.'rel'. Processing continues.';say
  dom_server. = ''
  dom_server.0 = 0
  say;say '  Display all z/OS UNIX System Services address spaces.';say
  asid_Cmd  = 'D OMVS,ASID=ALL'
  say '  Issuing command 'asid_cmd;say
  AxrCmdRc = AXRCMD(asid_Cmd,OMsg.,4)
  if AxrCmdRc = 0 then do
    say '  Searching for IMWHTTPD in command results.';say
    do i = 1 to OMsg.0
      say '  'Omsg.i
      if pos('CMD=IMWHTTPD',Omsg.i) > 0 | ,                  /* 1604 */
	       pos('/usr/lpp/internet/sbin/httpd',Omsg.i) > 0 then do
        j = i - 1               /* back up so we can get the jobname */
        jobname = space(substr(Omsg.j,10,9))
        say;say "  A Domino HTTP WebServer named "jobname" was found."
        dom_server_found = 1
        ds = dom_server.0 + 1
        dom_server.ds = left(jobname,79)
        dom_server.0 = ds
      end
    end
    if dom_server_found = 0 then do
      say;say "  A Domino HTTP WebServer was not found."
    end
    else do
      serverlist = dom_server.1
      do i = 2 to dom_server.0
        serverlist = serverlist' 'dom_server.i
      end
    end
    say
  end
  else do
    if HZS_PQE_DEBUG = 1 then do
      if AxrCmdRc = 4 then do
        call LOGMSGS text,'  No response received. Message might be suppressed by a Subsystem.'
        call LOGMSGS text,'  Verify the automation on this system.'
      end
    end
    xrc = AxrCmdRc
    say '  Failed to obtain results of command 'asid_cmd'.'
  end
end
else do
  na_env = 1
  say;say '  This exec will only run on a z/OS Rel 2.1 or earlier system.'
  say '  This system is at level 'os' Rel 'ver'.'rel'.';say
end
return xrc

/*********************************************************************/
/* Function: Process_DOM_Check_Report                                */
/*********************************************************************/
/* Purpose : Set message variables and generate check report.        */
/* Assuming the code above did not detect an exception situation,    */
/* Write "all is OK" message                                         */
/*********************************************************************/
Process_DOM_Check_Report:
if HZS_PQE_DEBUG = 1 then
  call LOGMSGS text,' Entering Process_DOM_CHECK_REPORT'
HZSLFMSG_REQUEST='DIRECTMSG'
/*-------------------------------------------------------------------*/
/* Directmsg options are CHECKEXCEPTION, CHECKINFO and CHECKREPORT   */
/* The _TEXT option is required on all. The _ID option is NOT        */
/* required for CHECKREPORT, it is for the other two.                */
/*        The other vars are optional for CHECKEXECPTION             */
/*-------------------------------------------------------------------*/
/*
HZSLFMSG_REASON = "CHECKEXCEPTION"
  HZSLFMSG_DIRECTMSG_ID = ''
  HZSLFMSG_DIRECTMSG_TEXT = ''
  HZSLFMSG_DIRECTMSG.EXPL = ''
  HZSLFMSG_DIRECTMSG.SYSACT = ''
  HZSLFMSG_DIRECTMSG.ORESP = ''
  HZSLFMSG_DIRECTMSG.SPRESP = ''
  HZSLFMSG_DIRECTMSG.PROBD = ''
  HZSLFMSG_DIRECTMSG.SOURCE = ''
  HZSLFMSG_DIRECTMSG.REFDOC = ''
  HZSLFMSG_DIRECTMSG.AUTOMATION = ''
  HZSLFMSG_SEVERITY = ''                /* SYSTEM, LOW, MED, HI, NONE*/
HZSLFMSG_REASON = "CHECKINFO"
  HZSLFMSG_DIRECTMSG_ID = ''
  HZSLFMSG_DIRECTMSG_TEXT = ''
*/
if dom_server_found = 1 then do
  /*-----------------------------------------------------------------*/
  /* One or more Domino Webservers were found on this system.        */
  /* This is not what we want, so flag an exception.                 */
  /*-----------------------------------------------------------------*/
  HZSLFMSG_REASON = "CHECKEXCEPTION"
  HZSLFMSG_DIRECTMSG_ID = 'DOMCHK8'
  HZSLFMSG_DIRECTMSG_TEXT = ,
   left('One or more IBM HTTP Server(s) Powered by Domino were found.',80),
                             serverlist
  HZSLFMSG_DIRECTMSG.EXPL = 'z/OS V2R1 is planned to be the last release to include',
   'the IBM HTTP Server Powered by Domino.  IBM recommends that you',
   'use the IBM HTTP Server Powered by Apache, which is available in',
   'z/OS Ported Tools as a replacement.  Refer to the IBM Redbook',
   'called IBM HTTP Server on z/OS:  Migrating from Domino-powered',
   'to Apache-powered.',
   copies(' ',80),
   'For any comments or questions on this IBM Health Checker for z/OS',
   'migration health check, send an email to zosmig@us.ibm.com.'
end
else do
  if env_na = 1 then do
    /*---------------------------------------------------------------*/
    /*   The level of the system was not applicable. It was > 2.1    */
    /*---------------------------------------------------------------*/
    HZSLFMSG_REASON = 'CHECKREPORT'
    HZSLFMSG_DIRECTMSG_TEXT = ,
     copies(' ',80),
     'This IBM Health Checker for z/OS migration check is running on a system',
     'that is later than z/OS V2.1.  This check is not appropriate for this',
     'system, as it verifies applicability of a migration action that',
     'occurred in z/OS V2.1.'
    HZSLFMSG_RC = HZSLFMSG()
    HZSLFMSG_REQUEST = 'STOP'
    HZSLFMSG_REASON = 'ENVNA'
  end
  else do
    /*---------------------------------------------------------------*/
    /* A Domino Webserver was NOT found on this system. That's good. */
    /*---------------------------------------------------------------*/
    HZSLFMSG_REASON = "CHECKREPORT"
    HZSLFMSG_DIRECTMSG_TEXT = ,
     copies(' ',80),
     'No IBM HTTP Servers Powered by Domino were found.',
     'The migration action to move from the IBM HTTP Server Powered by',
     'Domino to IBM HTTP Server Powered by Apache was not applicable',
     'to this system.',
     copies(' ',80),
     copies(' ',80),
     'For any comments or questions on this IBM Health Checker for z/OS',
     'migration health check, send an email to zosmig@us.ibm.com.'
  end
end
if HZS_PQE_DEBUG = 1 then do
  call LOGMSGS text,"  "HZSLFMSG_DIRECTMSG_TEXT
end
/* Flush the checker report */
HZSLFMSG_RC = HZSLFMSG()
if HZS_PQE_DEBUG = 1 then do
  call LOGMSGS text,"  HZSLFMSG RC" HZSLFMSG_RC
  call LOGMSGS text,"  HZSLFMSG RSN" HZSLFMSG_RSN
  call LOGMSGS text,"  SYSTEMDIAG" HZSLFMSG_SYSTEMDIAG
  if HZSLFMSG_RC = 8 then do             /* A user error occurred    */
    call LOGMSGS text,"  USER RSN" HZSLFMSG_UserRsn
    call LOGMSGS text,"  USER RESULT" HZSLFMSG_AbendResult
  end
end
return

/*********************************************************************/
/*                           LOGMSGS                                 */
/*********************************************************************/
LOGMSGS:
parse arg output,msg
/*-------------------------------------------------------------------*/
/*   Load the contents of the message to outputlog stem. We will     */
/*   then write the outputlog stem back to the output file.          */
/*-------------------------------------------------------------------*/
if output <> 'TEXT' then do
  /*-----------------------------------------------------------------*/
  /*                    Log a pre-defined array                      */
  /*-----------------------------------------------------------------*/
  do k = 1 to WTO.output.0
    say WTO.Output.k                                         /* 0912 */
    /*AxrWtoRc = AXRWTO(WTO.Output.k)                           0912 */
  end
end
else do
  /*-----------------------------------------------------------------*/
  /*                      Log a single message                       */
  /*-----------------------------------------------------------------*/
  say msg                                                    /* 0912 */
  /* AxrWtoRc = AXRWTO(msg)                                     0912 */
end
return
