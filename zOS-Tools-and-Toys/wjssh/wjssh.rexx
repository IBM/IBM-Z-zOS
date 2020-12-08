/* REXX */
/**********************************************************************/
/* Run a shell command from tso or sysrexx                            */
/*                                                                    */
/* PROPERTY OF IBM                                                    */
/* COPYRIGHT IBM CORP. 2008,2012                                      */
/*                                                                    */
/* Syntax:  wjssh <command line>                                      */
/*                                                                    */
/* Notes:                                                             */
/*   To run from TSO, save this to a PDS in your sysproc or sysexec   */
/*   concatenation                                                    */
/*   To run from sysrexx, save this to a PDS in your sysrexx search   */
/*   list as specified in parmlib AXRnn.  To use this you must be     */
/*   logged onto the console with a userid that is properly setup to  */
/*   use z/OS UNIX services.  Beware <command line> is case sensitive,*/
/*   you will probably need to quote it.                              */
/*                                                                    */
/* Bill Schoen  8/25/2008   wjs@us.ibm.com                            */
/*                                                                    */
/**********************************************************************/
parse arg cmd
parse source . . me . . . . where .
if syscalls('ON')>4 then
   do
   say 'Cannot initialize as a unix process'
   if where='AXR' then
      say 'Logon to the console with userid that can access z/OS UNIX'
   return
   end
env.0=1
env.1='PATH=/bin:/usr/bin:/usr/sbin:.'
out.0=0
err.0=0
rr=bpxwunix(cmd,,out.,err.,env.)
if rr<>0 then
   say 'RC('rr')'
call brstem out.
call brstem err.
return

brstem:
   arg stem
   if where<>'ISPF' then
      do
      do i=1 to value(stem'0')
         if where='AXR' then
            do
            wtomsg=value(stem||i)
            if wtomsg='' then
               wtomsg='.'
            call axrwto wtomsg
            end
          else
            say value(stem||i)
      end
      return
      end
   address ispexec
   brc=value(arg(1)"0")
   if brc=0 then
      return
   brlen=250
   do bri=1 to brc
      if brlen<length(value(arg(1) || bri)) then
         brlen=length(value(arg(1) || bri))
   end
   brlen=brlen+4
   call bpxwdyn "alloc rtddn(bpxpout) reuse new",
                "recfm(v,b) lrecl("brlen") msg(wtp)"
   address tso "execio" brc "diskw" bpxpout "(fini stem" arg(1)
   'LMINIT DATAID(DID) DDNAME('BPXPOUT')'
   'VIEW   DATAID('did') PROFILE(WJSC) MACRO(RESET)'
   'LMFREE DATAID('did')'
   call bpxwdyn 'free dd('bpxpout')'
   return

