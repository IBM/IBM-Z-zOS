/* REXX */
/***********************************************************************
   sdsfout   print output from a job to stdout

   Syntax:  sdsfout <jobname | jobid>
    
   PROPERTY OF IBM
   COPYRIGHT IBM CORP. 2009

   Install this in a directory where you can run programs.
   Set permissions to read+execute
    
   Bill Schoen  1/22/2009
***********************************************************************/
arg jname
call isfcalls 'ON'
jname.=''
address sdsf 'ISFEXEC ST'
if rc<>0 then
   do
   call sayerr 'SDSF error.  RC='rc
   return
   end
do s=1 to jname.0
   if jname=jname.s then leave
   if jname=jobid.s then leave
end
if jname.s='' then
   do
   call sayerr 'jobname or jobid missing or not found'
   return
   end
call sayerr 'Printing JobName='jname.s 'JobID='jobid.s 'Owner='ownerid.s 'Queue='queue.s
address sdsf "ISFACT ST TOKEN('"token.s"') PARM(NP SA)"
do i=1 to isfddname.0
   do forever
      address mvs 'execio 1000 diskr' isfddname.i '(stem st.'
      if st.0=0 then leave
      do j=1 to st.0
         say st.j
      end
   end
   address mvs 'execio 0 diskr' isfddname.i '(fini'
end
return

sayerr:
   parse arg msg
   msg=msg'15'x
   address syscall 'write 2 msg'
   return
