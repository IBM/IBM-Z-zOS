IBM Health Checker for z/OS Downloads 
=====================================

This location contains sample IBM Health Checker for z/OS health checks that are not provided within program products.  

Follow the instructions for each health check here how to use it.  

For more information on the IBM Health Checker for z/OS, see [IBM Health Checker for z/OS User's Guide](https://www.ibm.com/support/knowledgecenter/SSLTBW_2.3.0/com.ibm.zos.v2r3.e0zl100/toc.htm) 

There are no warranties of any kind, and there is no service or technical support available for these materials from IBM. As a recommended practice, review carefully any materials that you download from this site before using them on a live system.

Though the materials provided herein are not supported by the IBM Service organization, your comments are welcomed by the developers, who reserve the right to revise or remove the materials at any time. To report a problem, or provide feedback, contact zosmig@us.ibm.com.

domchk.rexx
===========
This health check is to be used for migration assistance from z/OS V2.1 to V2.2 or V2.3.  Follow the instuctions here to use it.

1. Download or transfer the health check to your z/OS system as a text file.  Store the file in a data set that is formatted with variable block size 256 (VB 256).  Name the file DOMCHK in the data set.  Add the data set to the System REXX (SAXREXEC) concatenation for your system.  Do not add the file to the data set SYS1.SAXREXEC.

2.  Browse the DOMCHK file contents.  Verify that the contents appear as human-readable REXX code.  Otherwise, do not use it; the file is corrupted.  Instead, transfer the file again as a test file to ensure that the contents are human-readable REXX code.

3.  Edit the parmlib member HZSPRMxx and add the statements that follow.  Member HZSPRMxx contains the statements that manage Health Checker processing on your system.

##### ADDREP CHECK(IBMZMIG,ZOSMIG_HTTP_SERVER_DOMINO_CHECK)
##### EXEC(DOMCHK)
##### REXXHLQ(IBMZMIG)
##### REXXTSO(YES)
##### REXXIN(NO)
##### MSGTBL(* NONE)  /* ensure no space between the asterisk and NONE */
##### USS(NO)
##### VERBOSE(NO)
##### SEVERITY(MEDIUM)
##### INTERVAL(168:00)
##### ACTIVE
##### EINTERVAL(SYSTEM)
##### DATE(20140915)
##### PARM('')
##### REASON('Verify that the IBM HTTP Server Domino is not in use.')

4. Optionally, modify the INTERVAL and ACTIVE statements, as follows:  
  *  Set INTERVAL to the frequency in hours for running the health check.  By default, the health check runs once a week (every 168 hours).
  *  To run the health check as soon as you complete this setup process, leave the ACTIVE statement unchanged.  Otherwise, to delay running the health check until later, change ACTIVE to INACTIVE.
  
5.  Make your changes effective.  Based on your current setup for IBM Health Checker, use either the **HZSPROC** command or the **MODIFY** command to refresh your settings with the updated member HZSPRMxx.  For example:  **HZSPROC,ADD,PARMLIB=(xx)** or **F HZSPROC,REPLACE,PARMLIB(xx,yy)**
