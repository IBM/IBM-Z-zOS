####################################################################################
# submit2 - submits JCL and gets output.   
#                                          
#    submit2 <option> <the jcl> <target host> <user> <password>
#        <option>
#           localpath|lp  - The JCL is in a file on this machine.
#           localmvs|lm   - The JCL is in a MVS DS on this machine.
#           remotepath|rp - The JCL is in a file on the target host machine.
#           remotemvs|rm  - The JCL is in a MVS DS on the target host machine.
#        <the jcl> 
#           This is the path to the file or MVS DS name where the source
#           JCL resides. This should be in quotes. Explicit path names are
#           recommended. Wildcards are dangerous to use since input is positional. 
#           The first <option> designates what/where this is.
#        <target host>
#           Where the JCL should be run. The target host can be expressed as host
#           name or its IP address. 
#        <user> 
#           User id used to ftp into the target host.
#        <password>
#           The password of the user id used to ftp into the target host.
#
# Setup/Installation:                      
# 1. Make sure /etc/ftp.data of the target machine has the option: 
#    LEVEL JESINTERFACELEVEL 2 
# 2. Put submit2 in a directory where you keep executable programs.
# 3. Make sure the permission bits are set to 0755 so that it is both
#    readable and executable by everyone. chmod 755 submit2
#
# Examples:                                
#    submit2 localpath 'my/jcl' 9.168.192.12 USER1 password1 
#    submit2 remotepath '/this/is/my/jcl' 9.168.192.12 USER1 password1 
#    submit2 remotemvs 'THIS.IS.MY.JCL' PKSTJ44.PDL.POK.IBM.COM USER2 password2
#    submit2 remotemvs 'THIS.IS.MY.JCL(HERE)' AQTS USER3 password3
#    submit2 localmvs 'THIS.IS.MY.JCL' PKSTJ44.PDL.POK.IBM.COM USER2 password2
#                                          
# Notes:
# 1. The submit2 command uses ftp to put the JCL into JES of the target host.
# 2. submit can be installed and run in a bash shell for example on Linux or
#    in a ksh shell on OMVS.
#
# Tool Contact: jffische@us.ibm.com
#
# Change Activity:                         
#    03/12/09 - John Fischer - Initial code
#    10/15/09 - John Fischer - Added to Tools and Toys
#
# exit codes:
#     0 - Job completed Successfully
#    64 - Can only use localmvs on a zOS machine
#    65 - Syntax error bad option
#    66 - Submit Failed
#    67 - Job not found in JES
#    68 - Job failed with a non-zero RC
#
# Copyright IBM Corp 2009
####################################################################################
## Input     #################################
INOPT=$1
INJCL=$2
INHOST=$3
INUSER=$4
INPSWD=$5
## Variables #################################
THEJCL=temp.$$.submit.jcl
JCLOUT=temp.$$.submit.jcl.out
JCLLISTOUT=temp.$$.submit.jcl.list.out
JCLJOBOUTPUT=temp.$$.submit.jcl.output
SLEEPTIME=10                  #time in seconds
#################################################
#msg - echos official messages
#################################################
msg()
{
echo $0 $(date +%T) $INJCL $INHOST $JOBNAME $JOBID' ... '$line
}
### MAIN #####################################
case $INOPT in
   ##############################################
   # localpath                                  #
   ##############################################
   localpath|lp )
      cp $INJCL $THEJCL
      (
      ftp -v -n $INHOST << SCRIPT
         user $INUSER $INPSWD
         site file=jes
         put $THEJCL
         quit
SCRIPT
      )>$JCLOUT 
   ;;
   ##############################################
   # remotepath                                 #
   ##############################################
   remotepath|rp ) 
      (
      ftp -v -n $INHOST << SCRIPT
         user $INUSER $INPSWD
         get '$INJCL' $THEJCL
         site file=jes
         put $THEJCL
         quit
SCRIPT
      )>$JCLOUT 
   ;;
   ##############################################
   # localmvs                                   #
   ##############################################
   localmvs|lm ) 
      case $(uname) in
         OS/390 )
            cp "//'$INJCL'" $THEJCL
            (
            ftp -v -n $INHOST << SCRIPT
               user $INUSER $INPSWD
               site file=jes
               put $THEJCL
               quit
SCRIPT
            )>$JCLOUT 
         ;;
         * ) 
            echo 'ERROR: option '$INOPT 'can only be used on a z/OS machine'
            exit 64
         ;;
      esac
   ;;
   ##############################################
   # remotedmvs                                 #
   ##############################################
   remotemvs|rm ) 
      (
      ftp -v -n $INHOST << SCRIPT
         user $INUSER $INPSWD
         get '$INJCL' $THEJCL
         site file=jes
         put $THEJCL
         quit
SCRIPT
      )>$JCLOUT 
   ;;
   * )
      echo ERROR: $INOPT is not a valid Option.
      echo ERROR: Valid Options are: localpath and remotemvs.
      echo 'Correct SYNTAX: '$0 '<option> <filename> <host> <userid> <password>'
      exit 65
   ;;
esac
JOBID=$(cat $JCLOUT|grep '250-It is known to JES as'|cut -f 7 -d ' ')
case $JOBID in
   JOB[0-9][0-9][0-9][0-9][0-9]|J[0-9][0-9][0-9][0-9][0-9][0-9][0-9] )
      # get the JOBNAME here
      JOBNAME=$(head -1 $THEJCL|cut -f 1 -d ' '|cut -c 3-10)
      line='Submit Successful.';msg
      rm $JCLOUT 
      rm $THEJCL
   ;;
   * )
      line='Submit Failed.';msg
      echo '### failing FTP output ###############################'
      cat $JCLOUT
      rm $JCLOUT
      rm $THEJCL
      echo '### failing FTP output ###############################'
      exit 66
   ;;
esac
########################################################
# Assign variables based on differences between shells #
########################################################
case $(uname) in
   OS/390 )           # zOS path
      CUTFOUND=3
      CUTSTATUS=5
      CUTRC=7 
      LISTCMD=list
   ;;
   * )                # NOT zOS path
      CUTFOUND=2
      CUTSTATUS=4
      CUTRC=6 
      LISTCMD=ls
   ;;
esac
##############################################
# Wait for the job the finish                #
##############################################
while :
   do
   line='sleeping '$SLEEPTIME' seconds';msg
   sleep $SLEEPTIME
   (
   ftp -v -n $INHOST << SCRIPT
      user $INUSER $INPSWD
      site file=jes
      site JESOWNER=*
      site JESJOBNAME=$JOBNAME
      site JESSTATUS=ALL
      $LISTCMD
      quit
SCRIPT
   )>$JCLLISTOUT
   FOUND0=$(cat $JCLLISTOUT|grep $JOBID)
   FOUND=$(echo $FOUND0|cut -f $CUTFOUND -d ' ')
   case $FOUND in
      $JOBID )
         STATUS0=$(cat $JCLLISTOUT|grep $JOBID)
         STATUS=$(echo $STATUS0|cut -f $CUTSTATUS -d ' ')
         rm $JCLLISTOUT
         case $STATUS in
            OUTPUT )
               RC=$(echo $STATUS0|cut -f $CUTRC -d ' ')
               line=$RC;msg
               (
               ftp -v -n $INHOST << SCRIPT
                  user $INUSER $INPSWD
                  site file=jes
                  site JESOWNER=*
                  site JESJOBNAME=$JOBNAME
                  get $JOBID
                  quit
SCRIPT
               )>$JCLJOBOUTPUT     
               rm $JCLJOBOUTPUT    
               if test -s $JOBID; then
                  line='Output received.';msg
               else 
                  line='Output NOT received. Was it DELETED?';msg
               fi
               case $RC in
                  RC=0000 | RC=0004 )
                     cat $JOBID
                     rm $JOBID
                     exit 0
                  ;;
                  *) 
                     cat $JOBID
                     rm $JOBID
                     exit 68
                     ;;
               esac
               ;;
            * )
               # Job still ACTIVE...wait till it ends
               line='Status: '$STATUS' Continue monitoring.';msg
               ;;
         esac
         ;;
      * )
         line='Status: NOT FOUND ....Output DELETED?';msg
         rm $JCLLISTOUT 
         exit 67
         ;;
   esac
   done
##############################################
