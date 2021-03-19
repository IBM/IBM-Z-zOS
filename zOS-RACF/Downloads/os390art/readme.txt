Welcome to the OS/390 Security Server Audit Tool and Report Application,
os/390art! The installation and use of os390art is documented in the
IBM Redbook "OS/390 Security Server Audit Tool and Report Application",
which is book number SG24-4820. You can get information on this and all
other IBM Redbooks at the URL http://www.redbooks.ibm.com/redbooks.
 
os390art is available as a set of files on lscpok.kgn.ibm.com. The
files are available in the /pub/racf/mvs/os390art directory and
its subdirectories as follows:
 
 
(1) creathdr                        -- CREATE TABLE SQL statements
(2) loadhdr                         -- DB2 Load Utility statements
(3) readme                          -- This file
 
(4) os390art.xmit.exp.data          -- QMF control file
(5) os390art.xmit.form              -- QMF forms
(6) os390art.xmit.panels            -- ISPF panels
(7) os390art.xmit.procs             -- QMF procedures
(8) os390art.xmit.query             -- QMF queries
(9) os390art.xmit.rexx              -- REXX procedures
 
You can upload these files using anonymous ftp. Files 1,2 and 3
are text files, that are intended to be uploaded in ascii format.
Files 4,5,6,7,8, and 9 are binary files, which must be transferred
in binary format to your MVS system.
 
Files 4,5,6,7,8, and 8 are "package" files in TSO TRANSMIT format.
Once you have imported them (in binary) to your MVS system, you
must then unpackaged them using the "RECEIVE" command.
 
The syntax of the RECEIVE command is:
 
    RECEIVE INDATASET(dsname)
 
RECEIVE prompts you for a target data set name.
 
Note: If you receive a message from the RECEIVE command that
indicates that the input data set is in an incorrect format,
verify that:
 
   - The files were FTP'd in binary format
   - The input files are in fixed block format
 
Questions on this tool may be directed to markn@vnet.ibm.com.
--------------------------------------------------------------------------------
DISCLAIMERS, ETC:
 
These programs contain code made available by IBM Corporation on
an AS IS basis. Any one receiving these programs is considered to
be licensed under IBM copyrights to use the IBM-provided source
code in any way he or she deems fit, including copying it,
compiling it, modifying it, and redistributing it, with or
without modifications, except that it may be neither sold nor
incorporated within a product that is sold.  No license under
any IBM patents or patent applications is to be implied from
this copyright license.
 
The software is provided "as-is", and IBM disclaims all warranties,
express or implied, including but not limited to implied warranties of
merchantibility or fitness for a particular purpose.  IBM shall not be
liable for any direct, indirect, incidental, special or consequential
damages arising out of this agreement or the use or operation of the
software.
 
A user of this program should understand that IBM cannot provide
technical support for the program and will not be responsible for any
consequences of use of the program.
 
See the individual documentation files for more information, including
information on contacting the author of these programs.
