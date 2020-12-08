/* REXX */
/**********************************************************************/
/* wjsthrds: show process thread count waiting in syscalls            */
/*           for processes to which you have access                   */
/*                                                                    */
/*   Syntax:  wjsthrds <opts>                                         */
/*            opts:                                                   */
/*               -m sec  monitor for specified number of seconds      */
/*               -su     switch to superuser                          */
/*                       must be permitted to BPX.SUPERUSER           */
/*   Notes:   if -m is used, all process found during the monitor     */
/*            period will be shown.  Thrds will be the maximum number */
/*            of threads found.  InKern will be the maximum number of */
/*            threads found in kernel and the syscalls shown will be  */
/*            the syscalls for threads in that sample.                */
/*                                                                    */
/*   Install:  This can be placed anywhere a rexx exec can be run.    */
/*             It will run in the shell, TSO, or sysrexx              */
/*                                                                    */
/* PROPERTY OF IBM                                                    */
/* COPYRIGHT IBM CORP. 2013                                           */
/*                                                                    */
/* Bill Schoen    wjs@us.ibm.com  05/15/2013, last change 05/24/2013  */
/**********************************************************************/

me='wjsthrds'
arg opts
su=pos('-SU',opts)
parse var opts '-M' secs .
if datatype(secs,'W')=0 then
   secs=0
interval=5
call init
pids.=''
pids=0
totinkern=0
call runprocs
do mon=secs by -interval while mon>0
   address syscall 'sleep (interval)'
   call runprocs
end
call report
call brstem 'out.'
return

report:
   dta=0
   do i=1 to pids
      pid=pids.i
      job=pids.pid.1
      asid=pids.pid.2
      maxthrd=pids.pid.3
      tc=pids.pid.4
      calls=pids.pid.5
      if tc=0 then iterate  /* skip procs with no threads in kern */
      dta=dta+1
      dta.dta=left(job,8)right(asid,4,0)right(999999-tc,6,0)'!' ||,
              left(job,8) right(asid,4,0)'!'right(pid,10),
              right(maxthrd,6) right(tc,6) calls
   end
   dta.0=dta
   call sortstem 'dta.'

   out.1='Maximum threads in kernel:' totinkern
   out.2=left('Job',8) 'ASID' right('PID',10),
         right('Thrds',6) right('InKern',6) ' State-Syscall(count)...'
   out=2
   lastpre=''
   do i=1 to dta.0
      parse var dta.i '!' pre '!' suf
      if pre=lastpre then
         pre=copies(' ',length(pre))
       else
         lastpre=pre
      out=out+1
      out.out=pre suf
   end
   call statecodes
   out.0=out
   return

runprocs:
   out=0
   inkern=0
   call procinfo
   do i=1 to bpxw_pid.0
      pid=bpxw_pid.i
      asid=d2x(bpxw_asid.i)
      job=bpxw_jobname.i
      if pids.pid.2='' then
         do
         pids=pids+1
         pids.pids=pid
         pids.pid.1=job
         pids.pid.2=asid
         pids.pid.3=0
         pids.pid.4=0
         end
      bpxw_syscall.=''
      tc=0
      calls=0
      calls.=0
      if procinfo(pid,'thread')='' then iterate
      if pids.pid.3<bpxw_threads then  /* max threads in process */
         pids.pid.3=bpxw_threads
      do j=1 to bpxw_threads
         if bpxw_syscall.j='00000000'x then iterate
         if bpxw_syscall.j='' then iterate
         sc=bpxw_syscall.j
         state=bpxw_ptrunwait.j
         sc=state'-'sc
         if calls.sc=0 then
            do
            calls=calls+1
            calls.calls=sc
            end
         calls.sc=calls.sc+1
         tc=tc+1
      end
      if tc>0 then
         do
         inkern=inkern+tc
         calls.0=calls
         calls=''
         do k=1 to calls.0
            sc=calls.k
            if calls.sc=1 then
               calls=calls sc
              else
               calls=calls sc'('calls.sc')'
         end
         if pids.pid.4<tc then  /* max threads in kern for process */
            do
            pids.pid.4=tc
            pids.pid.5=calls
            end
         end
   end
   if inkern>totinkern then
      totinkern=inkern
   return

statecodes:
   do stc=1 to sourceline(),
      while sourceline(stc)<>'codetable'
   end
   do stc=stc+1 by 1,
      while sourceline(stc)<>''
      out=out+1
      out.out=sourceline(stc)
   end
   return

/*
codetable
State codes:
   A msgrecv wait         P PTwaiting
   B msgsend wait         R Running or non-kernel wait
   C communication wait   S Sleep
   D Semaphore wait       W Waiting for child
   F File System Wait     X Fork new process
   G MVS in Pause         Y MVS wait
   K Other kernel wait
syscall codes can be found at http://goo.gl/RxcQ8

*/

/**********************************************************************/
sayc:
   if rxenv='AXR' then
      call axrwto arg(1)
   else
      say arg(1)
   return

exit:
   parse arg msg
   say msg
   exit

init:
   sx=0
   parse source . . . . . . . rxenv .
   if syscalls('ON')>4 then
      if rxenv='AXR' then
         call exit 'Logon to the console with an OMVS superuser ID'
       else
         call exit 'Cannot initialize as a unix process'
   if su>0 then
      do
      address syscall 'geteuid'
      if retval<>0 then
         address syscall 'seteuid 0'
      address syscall 'geteuid'
      myeuid=retval
      if myeuid<>0 then
         call exit 'You must run as UID=0 or be permitted to BPX.SUPERUSER'
      end
   if rxenv<>'OMVS' then
      do
      tmp='/tmp/'me'.'userid()
      do i=1 to sourceline()
         sl.i=sourceline(i)
      end
      sl.0=i-1
      address syscall 'writefile (tmp) 700' sl.
      if retval=-1 then
         do
         say 'cannot write file' tmp
         exit 20
         end
      rv=bpxwunix('_BPX_SHAREAS=YES' tmp opts,,out.,err.)
      address syscall 'unlink (tmp)'
      call brstem 'out.'
      exit 0
      end
   return

/**********************************************************************/
sortstem:
   arg sst,sscol
   ssm=value(sst||0)
   do ssi=1 to ssm
      do ssj=ssi+1 to ssm
         if sscol<>'' then
          do
          if substr(value(sst||ssi),sscol)>>,
             substr(value(sst||ssj),sscol) then
            do
            ssx=value(sst||ssi,value(sst||ssj))
            ssx=value(sst||ssj,ssx)
            end
          end
         else
         if value(sst||ssi)>>value(sst||ssj) then
            do
            ssx=value(sst||ssi,value(sst||ssj))
            ssx=value(sst||ssj,ssx)
            end
      end
   end
   return

/**********************************************************************/
brstem:
   arg stem
   parse source . . . . . . . isp .
   if isp<>'ISPF' then
      do
       do i=1 to value(stem'0')
         call sayc value(stem||i)
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
