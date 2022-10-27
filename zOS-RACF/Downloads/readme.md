The RACF development team has numerous tools that can assist you in managing your RACF environment. These tools include:

1. [BPXCHECK](http://ibm.biz/racf-bpxcheck): A REXX exec which uses the RACF IRRXUTIL REXX interface to report the status of various UNIX- related settings in RACF.  

2. [CDT2DYN](http://ibm.biz/racf-cdt2dyn): A REXX exec which examine the contents of the current classes in the RACF static class descriptor table and creates the commands to put those installation-defined classes into the ynamic CDT.

3. [CUTPWHIS](http://ibm.biz/racf-cutpwhis): A utility which trims the orphaned passwords created by decreasing the SETROPTS password history value.

4. [DSNT2PRM](http://ibm.biz/racf-db2prm): A REXX exec which converts your  RACF data set names table (ICHRDSNT) or RACF range table (ICHRRNG) into a RACF PARMLIB member. 

5. [DBSYNC](http://ibm.biz/racf-dbsync): REXX exec to find differences between two RACF databases and create commands to synchronize them. 

6. [IRRXUTIL](https://github.com/IBM/IBM-Z-zOS/tree/main/zOS-RACF/Downloads/IRRXUTIL): RACF IRRXUTIL Sample programs.

7. [JESNODES](http://ibm.biz/racf-jesnodes): A REXX exec which displays the names of trusted NODES profiles (those with a UACC greater than READ) and cover a defined node name in the context of inbound jobs and displays the local nodes defined in the &RACLNODE profile. 

8. [LISTCDT](http://ibm.biz/racf-listcdt): A utility which lists the contents of your RACF Class Descriptor Table.

9. [PWDCOPY](http://ibm.biz/racf-pwdcopy): A utility which copies passwords from one RACF database to another. 

10. [PWDPHRONLY](http://ibm.biz/racf-pwdphronly): RACF sample ICHRIX02 exit which forces users to use password phrases.

11. [RACFICE2](http://ibm.biz/racf-racfice2): RACFICE examples, beyond those which are shipped in 'SYS1.SAMPLIB(IRRICE)'

12. [RacfUnixCommands](https://github.com/IBM/IBM-Z-zOS/tree/main/zOS-RACF/Downloads/RacfUnixCommands): REXX execs that mimic RALTER, PERMIT, and RLIST to manage and display UNIX file security attributes

13. [RACKILL](http://ibm.biz/racf-rackill): A utility deletes profiles from the RACF database that otherwise might not be deletable.  

14. [RACSEQ](https://github.com/IBM/IBM-Z-zOS/tree/main/zOS-RACF/Downloads/RACSEQ): A TSO command which invokes the extract function of R_admin (IRRSEQ00) and displays every profile field to the display using PUTLINE.    

15. [RexxPwExit](https://github.com/IBM/IBM-Z-zOS/tree/main/zOS-RACF/Downloads/RexxPwExit): Sample REXX-based new password and phrase exits.  Code your quality rules in REXX! Contains one-stop STIG support.

16. [ZfsUnload](https://github.com/IBM/IBM-Z-zOS/tree/main/zOS-RACF/Downloads/ZFSUnload): Unload zFS file security information in a manner consistent with RACF's Database Unload (IRRDBU00) and SMF Unload (IRRADU00) utilities.

There are no warranties of any kind, and there is no service or technical support available for these materials from IBM. As a recommended practice, review carefully any materials that you download from this site before using them on a live system.

Your feedback is welcome.

Please note that though the materials provided herein are not supported by the IBM Service organization, your comments are welcomed by the developers, who reserve the right to revise or remove the materials at any time. To report a problem or provide suggestions or comments, please communicate them via the RACF-L mailing list.  To subscribe to RACF-L, you should first send a note to listserv@listserv.uga.edu
and include the following line in the body of the note, substituting your first name and last name as indicated:

     subscribe racf-l first_name last_name

Then, to post messages to RACF-L, send them to racf-l@listserv.uga.edu and include a relevant Subject: line.

