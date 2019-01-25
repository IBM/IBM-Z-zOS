The RACF development team has numerous tools that can assist you in managing your RACF environment. These tools include:

1. [BPXCHECK](http://ibm.biz/racf-bpxcheck): A REXX exec which uses the RACF IRRXUTIL REXX interface to report the status of various UNIX- related settings in RACF.  

2. [CDT2DYN](http://ibm.biz/racf-cdt2dyn): A REXX exec which examine the contents of the current classes in the RACF static class descriptor table and creates the commands to put those installation-defined classes into the ynamic CDT.

3. [CUTPWHIS](http://ibm.biz/racf-cutpwhis): A utility which trims the orphaned passwords created by decreasing the SETROPTS password history value.

3. [DSNT2PRM](http://ibm.biz/racf-db2prm): A REXX exec which converts your  RACF data set names table (ICHRDSNT) or RACF range table (ICHRRNG) into a RACF PARMLIB member. 

4. [DBSYNC](http://ibm.biz/racf-dbsync): REXX exec to find differences between two RACF databases and create commands to synchronize them. 
b
5. [ICHDEX01](http://ibm.biz/racf-ichdex01): A sample RACF ICHDEX01 which ensures that the default for the encryption of passwords is not MASKED.

6. [IRRHFSU](http://ibm.biz/racf-irrhfsu): A utility which unloads your z/OS UNIX System Services hierarchical file system data (HFZ, TFS, or z/FS) in a manner which is complimentary to the RACF Data Base Unload Utility (IRRDBU00). d

7. [IRRXUTIL](http://ibm.biz/racf-irrxutil): RACF IRRXUTIL Sample prgrams.

8. [JESNODES](http://ibm.biz/racf-jesnodes): A REXX exec which displays the names of trusted NODES profiles (those with a UACC greater than READ) and cover a defined node name in the context of inbound jobs and displays the local nodes defined in the &RACLNODE profile. 

10. [LISTCDT](http://ibm.biz/racf-listcdt): A utility which lists the contents of your RACF Class Descriptor Table.

11. [PWDCOPY](http://ibm.biz/racf-pwdcopy): A utility which copies passwords from one RACF database to another. 

12. [PWDPHRONLY](http://ibm.biz/racf-pwdphronly): RACF sample ICHRIX02 exit which forces users to use password phrases.

14. [RACFICE2](http://ibm.biz/racf-racfice2): RACFICE examples, beyond those which are shipped in 'SYS1.SAMPLIB(IRRICE)'

15. [RACKILL](http://ibm.biz/racf-rackill): A utility deletes profiles from the RACF database that otherwise might not be deletable.  

16. [RACSEQ](http://ibm.biz/racf-racseq): A TSO command which invokes the extract function of R_admin (IRRSEQ00) and displays every profile field to the display using PUTLINE.    

17. [REXXPWEXIT](http://ibm.biz/racf-rexxpwexit): A system-REXX based new password exit.

There are no warranties of any kind, and there is no service or technical support available for these materials from IBM. As a recommended practice, review carefully any materials that you download from this site before using them on a live system.

Your feedback is welcome.

Please note that though the materials provided herein are not supported by the IBM Service organization, your comments are welcomed by the developers, who reserve the right to revise or remove the materials at any time. To report a problem or provide suggestions or comments, please communicate them via the RACF-L mailing list.  To subscribe to RACF-L, you should first send a note to listserv@listserv.uga.edu
and include the following line in the body of the note, substituting your first name and last name as indicated:

     subscribe racf-l first_name last_name

Then, to post messages to RACF-L, send them to racf-l@listserv.uga.edu and include a relevant Subject: line.

