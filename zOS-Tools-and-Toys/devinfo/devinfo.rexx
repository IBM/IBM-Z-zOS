/******************************** REXX ********************************
**                                                                   **
** Copyright 2020-2021 IBM Corp.                                     **
**                                                                   **
**  Licensed under the Apache License, Version 2.0 (the "License");  **
**  you may not use this file except in compliance with the License. **
**  You may obtain a copy of the License at                          **
**                                                                   **
**     http://www.apache.org/licenses/LICENSE-2.0                    **
**                                                                   **
**  Unless required by applicable law or agreed to in writing,       **
**  software distributed under the License is distributed on an      **
**  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,     **
**  either express or implied. See the License for the specific      **
**  language governing permissions and limitations under the         **
**  License.                                                         **
**                                                                   **
** ----------------------------------------------------------------- **
**                                                                   **
** Disclaimer of Warranties:                                         **
**                                                                   **
**   The following enclosed code is sample code created by IBM       **
**   Corporation.  This sample code is not part of any standard      **
**   IBM product and is provided to you solely for the purpose       **
**   of assisting you in the development of your applications.       **
**   The code is provided "AS IS", without warranty of any kind.     **
**   IBM shall not be liable for any damages arising out of your     **
**   use of the sample code, even if they have been advised of       **
**   the possibility of such damages.                                **
**                                                                   **
** ----------------------------------------------------------------- **
** Description:                                                      **
**                                                                   **
**  This exec will issue several zOS commands to get information for **
**  all systems in the sysplex to display a DASD device connections. **
**  The commands are,                                                **
**    D XCF,S                                                        **
**      Used to get systems in the sysplex and cpu serial/type.      **
**    RO *ALL,D M=DEV(target device)                                 **
**      Used to get target device data from each system.             **
**    RO *ALL,DS QP,target device                                    **
**      Used to get SSID and CCA of target device on each system.    **
**    RO target system,D M=CHP(chipid)                               **
**      Used to get physical chpid information from target system.   **
**      Note, a chipid will only be queried once per cpu serial/type.**
**                                                                   **
**                                                                   **
** Variables:                                                        **
**  device - This is a required parameter and identifies the DASD    **
**           device to be queried.                                   **
**                                                                   **
**  BOTPRINT - This is an optional keyword which, if provided, will  **
**             reformat the generated output to less than 79         **
**             characters in length.                                 **
**                                                                   **
** DDs:                                                              **
**  BOTDD - This is an optional DD that works just like the BOTPRINT **
**             parameter.                                            **
**                                                                   **
**  15 Oct 2020 K.Miner Originally coded                             **
**  23 Mar 2021 K.Miner Added code to format for bot print, < 79     **
**                      characters                                   **
**  24 Mar 2021 K.Miner Corrected errors summarizing channel info    **
**                                                                   **
**********************************************************************/
DEVINW:
 arg parmin                     /* Save any parms passed to the exec */
 Call Initialize                /* Subroutine to init exec variables */

 /* Create summary table for the target devic for all systems in plex*/
 do i = 1 to system_name.0
  system_name = system_name.i          /* Name from D XCF            */
  system_name = left(system_name,wc1)  /* left justity field         */
  cpu_type    = system_type.i          /* CPU type from D XCF        */
  cpu_type    = left(cpu_type,wc2)     /* left justity field         */
  cpu_serial  = system_serial.i        /* CPU serial # from D XCF    */
  cpu_serial  = left(cpu_serial,wc3)   /* left justity field         */
  cpu_lpar    = system_lpar.i          /* CPU LPAR from D XCF        */
  cpu_lpar    = center(cpu_lpar,wc4)   /* center justity field       */
  box_serial  = left(serial.sc.1,wc5)  /* DSxK box serial number     */
  chp         = chp.i.1                /* Chpid from D M=DEV         */
  chp         = strip(chp,'b')
  chp         = center(chp,wc6)        /* center justify field       */
  ela         = ela.i.1                /*Entry Link Addr from D M=DEV*/
  ela         = center(ela,wc6)        /* center justity field       */
  dla         = dla.i.1                /* Dest Link Addr from D M=DEV*/
  dla         = center(dla,wc6)        /* center justity field       */
  po          = po.i.1                 /* Path Online from D M=DEV   */
  po          = center(po,wc7)         /* center justity field       */
  cpo         = cpo.i.1                /*Chp Phys Online from D M=DEV*/
  cpo         = center(cpo,wc7)        /* center justity field        */
  poper       = poper.i.1              /* Chp Phys Online from D M=DEV*/
  poper       = center(poper,wc7)      /* center justity field        */
  managed     = mng.i.1                /* Managed from D M=DEV        */
  cu_number   = cun.i.1                /* Control Unit from D M=DEV   */
  interface_id= infid.i.1              /* Interface id from D M=DEV   */
  interface_id = center(interface_id,wc8) /* center justity field     */
  iobcp = ''                           /* I/O bay, card, port variable*/
  ssid        = ssid.i.1               /* SSID from DS QD             */
  ssid        = left(ssid,wc9)         /* left justity field          */
  lss         = lss.i.1                /* LSS from D M=DEV            */
  lss         = center(lss,wc10)       /* center justity field        */
  cca         = cca.i.1                /* CCA from DS QP              */
  cca         = center(cca,wc11)       /* center justity field        */
  /*
  say ' chp.'i'.1     ='chp.i.1
  say ' ela.'i'.1     ='ela.i.1
  say ' dla.'i'.1     ='dla.i.1
  say ' po.'i'.1      ='po.i.1
  say ' cpo.'i'.1     ='cpo.i.1
  say ' poper.'i'.1   ='poper.i.1
  say ' mng.'i'.1     ='mng.i.1
  say ' cun.'i'.1     ='cun.i.1
  say ' infid.'i'.1   ='infid.i.1
  say ' lss.'i'.1     ='lss.i.1
  say ' cca.'i'.1     ='cca.i.1
  say ' ssid.'i'.1    ='ssid.i.1
  */
  if format_4bot = 'n' then
   do
   dr.1= ' 'system_name cpu_type cpu_serial cpu_lpar box_serial chp po
   /* Calc len to pad multi lines plus one for each column skipped   */
   pad_len = wc1+wc2+wc3+wc4 + wc5 + 5
   pad_line = left(' ',pad_len)
   dr.1= dr.1 interface_id ssid lss cca
   end
  else
   do
    dr.1= ' 'system_name cpu_type box_serial chp po
    /* Calc len to pad multi lines plus one for each column skipped  */
    pad_len = wc5 + 1
    pad_line = left(' ',pad_len)
    dr.1= dr.1 ssid lss cca
   end

  if format_4bot = 'n' then
   dr.2 = pad_line ela cpo     /*stack ELA and DLA under chpid       */
  else   /* Stack LPAR, CPU serial#, ELA and DLA                     */
   do
    pad_len = pad_len - 1     /* Subtract one for space before LPAR  */
    pad_line = left(' ',pad_len)
    cpu_lpar = center(cpu_lpar,wc1)
    dr.2 = ' 'cpu_lpar cpu_serial pad_line ela cpo
   end

  /*
  pad_len = wc1+wc2+wc3+wc4 + wc5 + 5
  pad_line = left(' ',pad_len)
   */
 if format_4bot = 'y' then
  do
  /* Calc len to pad multi lines plus one for each column skipped   */
  pad_len = wc1+wc2+ wc5 + 3
  pad_line = left(' ',pad_len)
  end
  dr.3 = pad_line dla poper    /*stack dest  link address under chpid*/
 /*
  /* Break up the interface id into differnt piece parts             */
  do ii = 1 to words(interface_id)
    interface_idw = word(interface_id,ii)
    if interface_idw = '....' then
      dr.2 = dr.2 '      '
    else
     do
      parse var interface_idw 1 something 2 IO_bay 3 IO_card 4 IO_port
      dr.2 = dr.2 '  'IO_bay'/'IO_card'/'IO_port
     end
  end
   */

  dr.0 = 3                     /* Set number of data records to write*/
  do wr = 1 to dr.0           /* Write summary data records          */
   oc = oc + 1
   output.oc = dr.wr
   output.0 = oc
  end
 end

 /* While querying this device has an anomaly been found?            */
 if words(devanomaly_flag) > 0 then
  do
   oc = oc +1
   output.oc = ' This device is' devanomaly_flag
  end


 /* Set up to find all physical chipid infor for unique chipids      */
 qchp_cputype.0 = 0
 qchp_serial.0  = 0
 chip_list.0    = 0
 qchp_count     = 0
 cpu_chp_matched = 'n'
 cpu_chp_matched  = 'n'         /* Turn off chp queried on cpu flag  */

 do i = 1 to system_name.0      /* Loop thru each system in the plex */
  cpu_chp_matched  = 'n'        /* Turn off chp queried on cpu flag  */
 /* SAY ' i system_name.'i'  =' system_name.i      */
  /* Scan thru the list of queried cpu chipids                       */
  do pc = 1 to qchp_count while cpu_chp_matched  = 'n'
 /*   SAY '  pc system_name.'pc' ='  system_name.pc */
   /* Has a chipid already been queried on this LPAR?                */
   if qchp_cputype.pc = system_type.i,
    & qchp_serial.pc  = system_serial.i then
     do cc = 1 to words(chp.i.1)  /* Look at each chipid on this lpar*/
      /* 1st time thru set flat to indicate a chp queried on lpar    */
      if cc = 1 then cpu_chp_matched  = 'y'
      chp2_query = word(chp.i.1,cc) /* Find specific chipid to query */
      /* Has this chipid already been queried?                       */
      if wordpos(chp2_query, qchp_list.pc) > 0 then iterate
      else call GetPhysical_Chp  /* Get data about physical chipid   */
     end
  end

  /* Didn't find this cpu type/serial # in the list of queried LPARs */
  if cpu_chp_matched  = 'n' then
   do cc = 1 to words(chp.i.1)  /* Scan each chipid on this lpar     */
    chp2_query = word(chp.i.1,cc)
 /* say 'chp2_query =' chp2_query 'on' system_name.i system_serial.i */
    call GetPhysical_Chp
    if cc = 1 then cpu_chp_matched  = 'y'  /* set after 1st chp scan */
     do
      cpu_chp_matched  = 'y'    /* Set on after 1st chipid queried   */
      pc = qchp_count           /* Set queried cpus array offset     */
     end
   end
 end

 /* Write to SYSPRINT or SYSTSPRT DD as directred by the user        */
 if sysprint_avail = 'y' then
   "execio * diskw SYSPRINT (stem output. finis"
  else
   do i = 1 to output.0
    if words(output.i) > 0 then       /* If this is not a blank line */
     output.i = strip(output.i,'t')   /* Strip trailing blanks       */
    say output.i
   end

  write_rc = rc
  if write_rc <> 0 then say 'write return code was:' write_rc

 exit(0)

/*------------------------ Subroutines ------------------------------*/
/*-------------------------------------------------------------------*/
/* Set up initial variables for this exec                            */
Initialize:
 if words(parmin) = 0 then
  do
   say '  '
   dr =' A device address to query must be passed to this exec.'
   dr = dr ' Exit RC 20.'
   say dr;say ' '
   exit(20)
   say '  '
  end

 /* Source is a keyword to the parse command that returns a string
    that is fixed (does not change) while the program is running that
    describes the environment in which the program is running.       */
 parse source tk1 tk2 tk3 tk4 tk5 tk6 tk7 tk8 tk9
 opsys           = tk1 /* The characters TSO                         */
 command_type    = tk2 /* String COMMAND, FUNCTION, or SUBROUTINE    */
 exec_name       = tk3 /* Exec name in uppercase                     */
 load_from_DD    = tk4 /* Name of DD from which the exec was loaded  */
 load_from_DSN   = tk5 /* Name of the dsn from which exec was loaded */
 exec_as_called  = tk6 /* Name of the exec as it was called          */
 init_cmd_env    = tk7 /* Initial host command environment           */
 addr_space_name = tk8 /* Address space in uppercase MVS TSO/E ISPF  */
 user_token      = tk9 /* Eight character user token PARSETOK field  */
 exec_name = '<'exec_name'>'  /* Enclose exec name in < >            */

 /* Queue the command and the command output                         */
 say   ' '
 say   ' Exec' exec_name' collected the folloing information,'
 say   ' '

 upper_case = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
 lower_case = 'abcdefghijklmnopqrstuvwxyz'

 cmd_output.0 = 0              /* Set output array counter to zero   */
 device2_query = word(parmin,1) /* Get the device address to query   */
 format_4bot = 'n'             /* Set for normal output              */
 oc = 0
 output.0 = oc
 wait_time = 2

 if pos('BOTPRINT',parmin) > 0 then format_4bot = 'y'

 /* Write to command output to SYSPRINT DD?                          */
 Call Find_Specific_DDs

  /* Set up the fields for the heading line                          */
  wc1 =  4                           /* System name                  */
  wc2 =  4                           /* CPU type                     */
  wc3 =  4                           /* CPU serial number            */
  wc4 =  4                           /* LPAR number                  */
  wc5 =  7                           /* Box serial number            */
  wc6 = 12                           /* Chipids                      */
  wc7 = 12                           /* Path statuses                */
  wc8 = 18                           /* Interface id                 */
  wc9 =  5                           /* SSID                         */
  wc10 = 4                           /* LSS                          */
  wc11=  4                           /* CCA                          */

  /* Create the column headings for the output to be created.        */
  hf.1.1 = left('Sys',wc1);hf.2.1 = left('Name',wc1)
  hf.1.2 = left('CPU',wc2);hf.2.2 = left('Type',wc2)
  hf.1.3 = left('CPU',wc3);hf.2.3 = left('Ser#',wc3)
  hf.1.4 = left(' ',wc4); hf.2.4 = left('LPAR',wc4)
  if format_4bot = 'y' then
   do  /* Reformat if output must be 78 characters if less.          */
    hf.1.1 = left('Name',wc1);hf.2.1 = left('LPAR',wc1)
    hf.1.2 = left('Type',wc2);hf.2.2 = left('Ser#',wc2)
   end
  hf.1.5 = center('DS?K',wc5); hf.2.5 = center('Serial#',wc5)
  hf.1.6 = center('ChipIDs',wc6); hf.2.6 = center('ELA/DLA',wc6)
  hf.1.7 = center('Path Online',wc7,' ');
  hf.2.7 = center('Phys Onl/Opr',wc7,' ')
  hf.1.8 = center(' ',wc8)
  hf.2.8 = center('Interface ID  ',wc8)
/*hf.2.8 = center('      I/O bay/card/port' ,wc8) */
  hf.1.9 = left(' ',wc9,);hf.2.9 = left('SSID',wc9)
  hf.1.10= left(' ',wc10,);hf.2.10= left('LSS',wc10)
  hf.1.11= left(' ',wc11,);hf.2.11 = left('CCA',wc11)
  hf.1.0 = 11;hf.2.0=11
  hc = 2

  /* Create the heading records based on the arrays created above.   */
  do h = 1 to hc                /* Create the two headings           */
   dr = ''
   do build_dr = 1 to hf.h.0
    if format_4bot = 'y',       /* Skip these heading for bot print  */
     & (build_dr = 3 | build_dr = 4 | build_dr = 8) then
     iterate                    /* Skip these headings               */
    dr = dr hf.h.build_dr
   end
   oc = oc + 1
   output.oc = dr               /* Add to the output array           */
   output.0 = oc
  end

  plex_name = MVSVAR('SYSPLEX')  /* Get the name for this sysplex    */
  oc = oc + 1;output.oc= '  '    /* Add a blank line                 */
  oc = oc + 1
   dr = ' Info for device' device2_query 'in sysplex 'plex_name'.'
  output.oc= dr

 sc = 0                       /* Count for active systems in sysplex */
 found_systems = 'n'          /* Flag list of systems found          */
 mvscmd = 'D XCF,S'           /* Find the systems in this sysplex    */
 Call Issue_Command

  do co = 1 to cmd_output.0   /* Summarize command output and queue  */
    if word(cmd_output.co,1) = 'SYSTEM',
     & word(cmd_output.co,2) = 'TYPE' then
     do
      found_systems = 'y'     /* List of systems found in D XCF,S    */
      iterate
     end
   if found_systems = 'n' then iterate  /*Skip until list of systems */
   /* Skip any systems in the list not listed as active              */
   if word(cmd_output.co,7) <> 'ACTIVE' then iterate
   sc = sc +1            /*Create an entry for each system in sysplex*/
   system_name.sc   = word(cmd_output.co,1) /* Save system name      */
   system_type.sc   = word(cmd_output.co,2) /*Save cpu type system on*/
   system_serial.sc = word(cmd_output.co,3) /* Save cpu serial number*/
   system_lpar.sc   = word(cmd_output.co,4) /* Save cpu LPAR number  */

   /* Ensure the column widths can hold the required fields          */
   if length(system_name.sc) > wc1 then
    wc1 = length(system_name.sc) + 1
   if length(system_type.sc) > wc2 then
    wc2 = length(system_type.sc) + 1
   if length(system_serial.sc) > wc2 then
    wc3 = length(system_serial.sc) + 1

   system_name.0    = sc                   /* Save # of array entries*/
   system_type.0    = sc                   /* Save # of array entries*/
   system_serial.0  = sc                   /* Save # of array entries*/
   system_lpar.0    = sc                   /* Save # of array entries*/
   chp.sc.1         = ''                   /* Set varialble to null  */
   ela.sc.1         = ''                   /* Set varialble to null  */
   dla.sc.1         = ''                   /* Set varialble to null  */
   po.sc.1          = ''                   /* Set varialble to null  */
   cpo.sc.1         = ''                   /* Set varialble to null  */
   poper.sc.1       = ''                   /* Set varialble to null  */
   mng.sc.1         = ''                   /* Set varialble to null  */
   cun.sc.1         = ''                   /* Set varialble to null  */
   infid.sc.1       = ''                   /* Set varialble to null  */
   serial.sc.1      = ''                   /* Set varialble to null  */
   lss.sc.1         = ''                   /* Set varialble to null  */
   cca.sc.1         = ''                   /* Set varialble to null  */
   ssid.sc.1        = ''                   /* Set varialble to null  */
  end

 mvscmd = 'RO *ALL,D M=DEV('device2_query')' /* List device info     */
 Call Issue_Command
 Call Getdev_Info          /* Get device/chpid/ELA/DLA/interface info*/

 if words(ssid.sc.1) = 0 then
  do
   /* Issue DS QP command to find the SSID and CCA for the device    */
   mvscmd = 'RO *ALL,DS QP,'device2_query
   Call Issue_Command
   Call GetSSID_Info
  end
return

/*-------------------------------------------------------------------*/
GetPhysical_Chp:
 phy_chpid       = ''
 phy_type        = ''
 phy_desc        = ''
 phy_status      = ''
 phy_generation  = ''
 phy_oper_speed  = ''
 phy_switch_devno = ''

 /* If chipid to test is NA then device is alias or not exist.       */
 if chp2_query = 'NA' then return

 say 'Querying chipid =' chp2_query 'on' system_name.i  system_serial.i
 if cpu_chp_matched  = 'n' then      /* This is a new CPU/lpar       */
  do
   qchp_count = qchp_count + 1        /* Add 1 to chipid count       */
   chp2_query = word(chp.i.1,1)      /* Scan 1st chp on this CPU/lpar*/
   qchp_system = system_name.i       /* Get system name for RO cmd   */
   qchp_cputype.qchp_count = system_type.i
   qchp_serial.qchp_count   = system_serial.i
   if qchp_count = 1 then
    qchp_list.qchp_count = chp2_query
   else
    qchp_list.qchp_count = qchp_list.qchp_count chp2_query
   qchp_serial.0  = qchp_count
   qchp_cputype.0 = qchp_count
   qchp_list.0    = qchp_count
   qchp_serial    = qchp_serial.qchp_count
   qchp_infid     = word(infid.i.1,1)
  end
 else /* Add this new chp to list of chps queried on this cpu/lpar   */
  do
   qchp_list.pc = qchp_list.pc chp2_query
   qchp_system = system_name.pc       /* Get system name for RO cmd  */
   qchp_serial    = qchp_serial.pc
   qchp_infid     = word(infid.cc.1,cc)
  end

 mvscmd = 'RO' qchp_system',D M=CHP('chp2_query')'
 Call Issue_Command
  mvscmdrc = rc
  /*
  phy_desc.cd
  phy_type.cd
  phy_switch_devn
  phy_chpid.cd
  phy_oper_speed.
  phy_generation.
  */
 summary_printed = 'n'
  /* Summarize physical chipid information and queue to output       */
  do cd = 1 to cmd_output.0
   chpdata = cmd_output.cd
   if words(chpdata) = 0 then iterate

   if pos('DEVICE STATUS FOR CHANNEL PATH',chpdata) > 0 then
    do
     cd = cd + 1            /* Skip down to the next line            */
     chpdata = cmd_output.cd
     if pos('CHP=',chpdata) > 0,
     & pos(' IS ',chpdata) > 0 then
      do
       chpdata = strip(chpdata,'b')  /* Remove leading/traling blanks*/
       parse var chpdata junk ' ' phy_status
       /* Convert channel status to lower case                       */
       phy_status = translate(phy_status, lower_case, upper_case)
      end
    end

   if pos('SYMBOL EXPLANATIONS',chpdata) > 0 then
    do
     if summary_printed = 'n' then call Channel_Summary
     return
    end
   /*
   if pos('DOES NOT EXIST',chpdata) > 0 then
    do
     chpdata = 'This CHPID does not exist'
     iterate
    end
    */

   /* Break down the different fields in D M=CHP into different fields*/
    if pos('DESC=',chpdata) > 0 then
     parse var chpdata junk 'DESC=' phy_desc

    if pos('TYPE=',chpdata) > 0 then
     parse var chpdata junk 'TYPE=' phy_type',' junk2

    if pos('SWITCH DEVICE NUMBER = ',chpdata) > 0 then
     parse var chpdata junk 'SWITCH DEVICE NUMBER = ' phy_switch_devno

   if phy_switch_devno = '' then iterate

    if pos('PHYSICAL CHANNEL ID = ',chpdata) > 0 then
     parse var chpdata junk 'PHYSICAL CHANNEL ID = ' phy_chpid

    if pos('OPERATING SPEED = ',chpdata) > 0 then
     do
      parse var chpdata junk 'OPERATING SPEED = ' phy_oper_speed
      phy_oper_speed = word(phy_oper_speed,1)
      /* Change commas to blank                                      */
      phy_oper_speed = translate(phy_oper_speed,' ',',')
      phy_oper_speed = strip(phy_oper_speed,'b') /* Remove any blanks*/
     end

    if pos('GENERATION = ',chpdata) > 0 then
     parse var chpdata junk 'GENERATION = ' phy_generation junk2

   end

return

/*-------------------------------------------------------------------*/
/* Write a summary of the chipid information                         */
/*-------------------------------------------------------------------*/
Channel_Summary:

 summary_printed = 'y'
 cs = 0

 if chp2_query = 88 then trace ?i
 else
  do
   trace
   executil te
  end
 dr ='  Chipid ('chp2_query') on' qchp_serial 'has the following'
 dr= dr 'connection information,'
 cs = cs + 1
 sum.cs = '   '
 cs = cs + 1
 sum.cs = dr

 if phy_chpid<> '' then
  dr = '    Connect to physical channel id ' phy_chpid'.'
 else dr = '  '

 if phy_type <> '' then
  do
   dr = dr'  This is a TYPE('phy_type
   if phy_desc <> '' then dr = dr '('phy_desc')) channel'
   else dr = dr')'
  end

 cs = cs + 1
 sum.cs = dr
 sum.0 = cs

 dr = ''
 if phy_generation <> '' then
  do
   dr = '    Which is a generation' phy_generation' channel'
   if phy_oper_speed <> '' then
    dr = dr 'that can operate at' phy_oper_speed 'speed.'
   else dr = dr'.'
  end

 if dr <> '' then
  do
   cs = cs + 1
   sum.cs = dr
  end
  sum.0 = cs

 dr = ''
  if pos('.',qchp_infid) = 0,
   & datatype(qchp_infid,'N') = 1 then           /* Numeric field?   */
   do
    parse var qchp_infid 1 something 2 IO_bay 3 IO_card 4 IO_port
    dr = '    Connected to IO bay('IO_bay') IO card('IO_card')'
    dr = dr 'IO port('IO_port')'
   end

 if dr <> '' then
  do
   cs = cs + 1
   sum.cs = dr
  end
  sum.0 = cs

 dr = ''
 if phy_status <> '' then
   dr = '    This channel' phy_status

 if dr <> '' then
  do
   cs = cs + 1
   sum.cs = dr
  end
  sum.0 = cs

  if sum.0 > 0 then
   do cs = 1 to sum.0
    oc = oc + 1
    output.oc = sum.cs
    output.0 = oc
   end

return

/*-------------------------------------------------------------------*/
/* Find the data set name allocated to the SYSPRINT DD               */
Find_Specific_DDs:
 if bpxwdyn("info dd(SYSPRINT) inrtdsn(dsnvar)") = 0 then
  sysprint_avail = 'y'
 else sysprint_avail = 'n'

 if bpxwdyn("info dd(BOTDD) inrtdsn(dsnvar)") = 0 then
  format_4bot = 'y'

return

Issue_Command:
 TSOMSG = MSG('OFF')            /* hide any error msgs from next cmd */
 /* deactivate any active console session user may have              */
 "CONSOLE DEACT"
 TSOMSG = MSG('ON')
 mycart = mvsvar('symdef',jobname)
 cnslname = mvsvar('symdef',jobname) /* set up the console name      */
 cmd_output = 0

 /* set up console profile                                           */
 "CONSPROF SOLDISP(NO) UNSOLDISPLAY(NO) SOLNUM(400) UNSOLNUM(1000)"
 "CONSOLE ACTIVATE NAME("cnslname")" /* activate a console session   */

 "CONSOLE SYSCMD("mvscmd") CART("mycart")" /* Issue cmds             */
  console_rc = rc
  /* say 'mvscmd ='mvscmd 'return code =' console_rc  */

Get_Cmd_Output:
 getcode=GETMSG('CMDR.','EITHER',mycart,,wait_time) /*wait for output*/
 /* say 'getcode =' getcode  'cmdr.0 =' cmdr.0       */
 if getcode = 0 then            /* Add command output to array       */
  do co= 1 to cmdr.0
   cmd_output = cmd_output + 1
   cmd_output.cmd_output = cmdr.co
  end

  cmd_output.0 = cmd_output          /* Save number of array entries */
 if getcode = 0 then signal Get_Cmd_Output  /* Look for more output  */

 "CONSOLE DEACT"                /* Deactivate console session        */
 if SYSVAR('SYSISPF') = 'ACTIVE' /*Running under ISPF? Reset profile */
  then "CONSPROF SOLDISP(YES) UNSOLDISPLAY(YES)"

  /* Add any caputered output to existing captured output            */
  if cmd_output.0 = 0 then            /* If cmd output was captured  */
   do
    say '  '
    say ' There is no command output from' mvscmd
    say '  '
    exit(4)
   end
return

/*-------------------------------------------------------------------*/
/* Parse the D M=DEV() command to get the device information         */
Getdev_Info:
 system_name = ''
 do di = 1 to cmd_output.0  /* Summarize command output and queue  */
  if pos('RESPONSES',cmd_output.di) > 0 then
   do
    system_name = word(cmd_output.di,1)
    /* Loop through system names array until a match is found       */
    do sc = 1 to system_name.0
     if system_name = word(system_name.sc,1) then
      do
       di = di + 2          /* Skip past the message id line         */
       leave
      end
    end
   end

  if system_name = '' then iterate

  /* Break down the different fields in D M=DEV into different arrays*/
  /* If the device is not in the system then set array fields as NA  */
  if pos('STATUS=',cmd_output.di) > 0,
   & pos('NOT IN SYSTEM',cmd_output.di) > 0 then
   do
    chp.sc.1 = 'NA';chp.sc.0 = 1
    ela.sc.1 = 'NA';ela.sc.0 = 1
    dla.sc.1 = 'NA';dla.sc.0 = 1
    po.sc.1  = 'N'; po.sc.0  = 1
    poper.sc.1 = 'N'; poper.sc.0 = 1
    cpo.sc.1 = 'N'; cpo.sc.0 = 1
    infid.sc.1 = '....'; infid.sc.0 = 1
    lss.sc.1 = 'N/A'; lss.sc.0 = 1
    cca.sc.1 = 'N/A'; cca.sc.0 = 1
    ssid.sc.1 = 'N/A'; ssid.sc.0 = 1
    serial.sc.1 = '....'; serial.sc.0 = 1
    devanomaly_flag ='not in system.'
    iterate
   end

  /* If the device is an alias then set ssid to alias type           */
  if pos('STATUS=',cmd_output.di) > 0,
   & pos('ALIAS',cmd_output.di) > 0 then
   do
    /* Determine the alias type for this device.                     */
    parse var cmd_output.di junk 'STATUS=' tempdata
    if words(tempdata) > 1 then    /* Is status type more than 1 word*/
     do
      word1 = word(tempdata,1)     /* Get 1st word of alias type     */
      word2 = word(tempdata,2)     /* Get 2nd word of alias type     */
      parse var word1 1 word1_c2 3 /* Use 1st 2 chars of word1       */
      parse var word2 1 word2_c2 3 /* Use 1st 2 chars of word2       */
      alias_type = word1_c2||word2_c2 /* Create 4 char alias type    */
     end
    else alias_type = 'ALIA'       /* Use a generic alias            */

    chp.sc.1 = 'NA';chp.sc.0 = 1
    ela.sc.1 = 'NA';ela.sc.0 = 1
    dla.sc.1 = 'NA';dla.sc.0 = 1
    po.sc.1  = 'N'; po.sc.0  = 1
    poper.sc.1 = 'N'; poper.sc.0 = 1
    cpo.sc.1 = 'N'; cpo.sc.0 = 1
    infid.sc.1 = '....'; infid.sc.0 = 1
    lss.sc.1 = 'N/A'; lss.sc.0 = 1
    cca.sc.1 = 'N/A'; cca.sc.0 = 1
    ssid.sc.1 = alias_type; ssid.sc.0 = 1
    serial.sc.1 = '....'; serial.sc.0 = 1
    devanomaly_flag ='an alias device.'
    iterate
   end

  devanomaly_flag =''
  if pos('CHP    ',cmd_output.di) > 0 then /* Find CHP plus 3 spaces */
   do pd = 2 to words(cmd_output.di) /* Save 2nd thru last word      */
    chp.sc.1 = chp.sc.1 word(cmd_output.di,pd)
    chp.sc.0 = words(chp.sc.1)
   end

  if pos('ENTRY LINK ADDRESS',cmd_output.di) > 0 then
   do pd = 4 to words(cmd_output.di) /* Save 4th thru last word      */
    ela.sc.1 = ela.sc.1 word(cmd_output.di,pd)
    ela.sc.0 = words(ela.sc.1)
   end

  if pos('DEST LINK ADDRESS',cmd_output.di) > 0 then
   do pd = 4 to words(cmd_output.di) /* Save 4th thru last word      */
    dla.sc.1 = dla.sc.1 word(cmd_output.di,pd)
   dla.sc.0 = words(dla.sc.1)
   end

  if pos('PATH ONLINE',cmd_output.di) > 0 then /* PATH ONLINE        */
   do pd = 3 to words(cmd_output.di) /* Save 3rd thru last word      */
    po.sc.1 = po.sc.1 word(cmd_output.di,pd)
    po.sc.0 = words(po.sc.1)
   end

  if pos('CHP PHYSICALLY ONLINE',cmd_output.di) > 0 then
   do pd = 4 to words(cmd_output.di) /* Save 4th thru last word      */
    cpo.sc.1 = cpo.sc.1 word(cmd_output.di,pd)
    cpo.sc.0 = words(cpo.sc.1)
   end

  if pos('PATH OPERATIONAL',cmd_output.di) > 0 then
   do pd = 3 to words(cmd_output.di) /* Save 3rd thru last word      */
    poper.sc.1 = poper.sc.1 word(cmd_output.di,pd)
    poper.sc.0 = words(poper.sc.1)
   end

  if pos('MANAGED        ',cmd_output.di) > 0 then /* MANAGED        */
   do pd = 2 to words(cmd_output.di) /* Save 2nd thru last word      */
    mng.sc.1 = mng.sc.1 word(cmd_output.di,pd)
    mng.sc.0 = words(mng.sc.1)
   end

  if pos('CU NUMBER',cmd_output.di) > 0 then /* Control Unit Number  */
   do pd = 3 to words(cmd_output.di) /* Save 3rd thru last word      */
    cun.sc.1 = cun.sc.1 word(cmd_output.di,pd)
    cun.sc.0 = words(cun.sc.1)
   end

  if pos('INTERFACE ID ',cmd_output.di) > 0 then /* Interface id     */
   do pd = 3 to words(cmd_output.di) /* Save 3rd thru last word      */
    infid.sc.1 = infid.sc.1 word(cmd_output.di,pd)
    infid.sc.0 = words(infid.sc.1)
   end

  if pos('CONNECTION SECURITY',cmd_output.di) > 0 then
   do pd = 3 to words(cmd_output.di) /* Save 3rd thru last word      */
    consec.sc.1 = consec.sc.1 word(cmd_output.di,pd)
    consec.sc.0 = words(consec.sc.1)
   end

  /* The DESTINATION CU LOGICAL ADDRESS is the LSS for the device    */
  if pos('DESTINATION CU LOGICAL ADDRESS',cmd_output.di) > 0 then
   do
    lss_words = words(cmd_output.di)   /* Find last word on this line*/
    lss.sc.1 = word(cmd_output.di,lss_words) /* Save LSS for this dev*/
    lss.sc.0 = words(lss.sc.1)
   end

  /* The SCP DEVICE NED contains the box serial number               */
  if pos('SCP DEVICE NED',cmd_output.di) > 0 then
   do
    parse var cmd_output.di junk '=' box_serial /*Get part w/serial  */
    /* Translate perions in string with the serial number to blanks  */
    box_serial = translate(box_serial,' ','.')
    box_serial = word(box_serial,5)          /* Keep just 5th word   */
    serial.sc.1= strip(box_serial,'L',0)     /* Remove leading zeros */
    if length(serial.sc.1) >= wc5 then
     wc5 = length(serial.sc.1) + 1           /* set width of column  */
    serial.sc.0 = words(serial.sc.1)

   end

  /* Remove leading and trailing blanks from these fields            */
  chp.sc.1   = strip(chp.sc.1,'b')   /* Chpid from D M=DEV           */
  ela.sc.1   = strip(ela.sc.1,'b')   /* Entry Link Addr from D M=DEV */
  dla.sc.1   = strip(dla.sc.1,'b')   /* Dest Link Addr from D M=DEV  */
  po.sc.1    = strip(po.sc.1,'b')    /* Path Online from D M=DEV     */
  cpo.sc.1   = strip(cpo.sc.1,'b')   /* Chp Phys Online from D M=DEV */
  poper.sc.1 = strip(poper.sc.1,'b') /* Physical oper from D M=DEV   */
  infid.sc.1 = strip(infid.sc.1,'b') /* Interface id from D M=DEV    */
/*infid.sc.1 = space(Qnfid.sc.1,4)      Interface id from D M=DEV    */

  /* Ensure the column widths can hold the required fields           */
  if length(chp.sc.1) >= wc6 then
   do
    wc6 = length(chp.sc.1) + 1
    wc7 = wc6
   end
  /* Ensure the column widths can hold the required fields           */
  if length(infid.sc.1) >= wc8 then
    wc8 = length(infid.sc.1) + 1

 end
return


/* Parse the DS QP,device address command to get SSID and CCA        */
GetSSID_Info:
 system_name = ''
 do pi= 1 to cmd_output.0   /* Summarize command output and queue    */
  if pos('RESPONSES',cmd_output.pi) > 0 then
   do
    system_name = word(cmd_output.pi,1)
   /* Loop through system names array until a match is found         */
    do sc = 1 to system_name.0
     if system_name = word(system_name.sc,1) then leave
    end
   end

   if system_name = '' then iterate

   /* If ssid has already been set for this device then the device   */
   /* may not physically exist.                                      */
   if words(ssid.sc.1) > 0,
    & word(chp.sg.1,1) = 'NA' then return

  /* Look for the ' NUM. UA  TYPE        STATUS     SSID' line       */
  if pos('NUM',cmd_output.pi) = 0,
   | pos('UA',cmd_output.pi) = 0,
   | pos('TYPE',cmd_output.pi) = 0,
   | pos('STATUS',cmd_output.pi) = 0,
   | pos('SSID',cmd_output.pi) = 0 then iterate

  ua_pos   = pos('UA ',cmd_output.pi) /* Save the start of the UA/CCA */
  ssid_pos = pos('SSID',cmd_output.pi)  /* Save the start of the SSID*/

  pi = pi + 2                        /* Skip down two line           */
  parse var cmd_output.pi ua_pos dev_cca ssid_pos dev_ssid
/*parse var cmd_output.pi ssid_pos dev_ssid ' ' junk    save the SSID*/

  /* Save the CCA and SSID for this system in an arrray              */
  cca.sc.1  = dev_cca ; cca.sc.0  = 1
  ssid.sc.1 = word(dev_ssid,1);ssid.sc.0 =1

  /* Ensure the column widths can hold the required fields           */
  if length(ssid.sc.8) >= wc9 then
    wc9 = length(ssid.sc.1) + 1
  if length(ssid.sc.8) >= wc9 then
    wc9 = length(ssid.sc.1) + 1
  if length(lss.sc.9) >= wc10 then
    wc10 = length(lss.sc.1) + 1
  if length(lss.sc.1) >= wc11 then
    wc11 = length(lss.sc.1) + 1

 end
 return


