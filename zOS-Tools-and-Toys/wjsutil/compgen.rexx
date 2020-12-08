/* REXX **************************************************************/
/* edit macro:  compgen <n>                                          */
/* Description: compare the current member you are editing with a    */
/*              prior generation (version) of that member            */
/*              using ISPF EDIT and PDSE V2 with generations         */
/* Args:                                                             */
/*       n is the relative generation number (default 1)             */
/* ex:  compgen     compare session with the prior generation        */
/*      compgen 3   compare session with 3rd oldest generation       */
/*                                                                   */
/* Bill Schoen  4/17/2015   wjs@us.ibm.com                           */
/*********************************************************************/
address ispexec 'control errors return'
ADDRESS ISREDIT 'MACRO (PARM) NOPROCESS'
if rc<>0 then call out 'must be run as an edit macro'
parse var parm gen internal .
if gen='' then gen=1
address isredit '(mem) = member'
address isredit '(dsn) = dataset'
address ispexec "dsinfo dataset('"dsn"')"
cdsn="'"sysvar('syspref')".wjscg.tempdsn'"
if gen=0 then call out 'no generations defined for the data set'

if internal='/load' then      /* re-entered as a macro from view */
   do
   /* create a temp data set for the compare */
   call outtrap 'ON'
   address tso 'del' cdsn
   call outtrap 'OFF'
   recfm=''
   do i=1 by 1 while substr(zdsrf,i,1)<>''
      recfm=recfm','substr(zdsrf,i,1)
   end
   dyn=bpxwdyn("alloc rtddn(ddn) new da("cdsn") catalog msg(wtp)",
               "recfm("substr(recfm,2)") lrecl("strip(zdslrec)")",
               "blksize("strip(zdsblk)") space(1,2) cyl")
   if dyn<>0 then return
   call bpxwdyn 'free dd('ddn')'
   address isredit 'replace' cdsn '.zfirst .zlast'
   address isredit 'can'      /* end the view session */
   return
   end

if gen='' | datatype(gen,'W')=0 then
   call out 'compgen <n>'

/* invoke view for this member and specified generation          */
/* reentry of the macro will copy the view session to a data set */
dsn="'"dsn"("strip(mem)")'"
macprm=gen '/load'
parse source . . me .
address ispexec 'view dataset('dsn') gen(-'gen') macro('me') parm(macprm)'
if rc>4 then  /* if error then generation does not exist */
   call out 'generation' gen 'not found.  Maxgens is' strip(zdsngen)
/* got the data set, now compare then delete the data set */
address isredit 'compare' cdsn 'x'
CALL OUTTRAP 'ON'
address tso 'del' cdsn
call outtrap 'OFF'
return

out:
   zedlmsg=arg(1)
   address ispexec "SETMSG MSG(ISRZ000)"
   exit
