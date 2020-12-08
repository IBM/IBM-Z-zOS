/* rexx */
/***********************************************************************

   Title: jobwait
   Syntax:  jobwait [-t time] jobid
   Options:
     t <time>  set maximum wait time in seconds

   PROPERTY OF IBM
   COPYRIGHT IBM CORP. 2016,2019

   Install this in a directory where you can run programs.
   Set permissions to read+execute

 Bill Schoen (wjs@us.ibm.com)  1/26/2016
                               5/3/2019 allow jobid piping, fix cc
***********************************************************************/

parse arg '-t' wt jobid .
if jobid='' then
   parse arg jobid .
if jobid='' then
   jobid=linein()
if jobid='' then
   do
   say 'Usage:  jobwait [-t time] jobid'
   exit 1
   end
jobid=translate(jobid)
call time 'E'
call isfcalls 'on'
isfprefix='*'
isfowner=userid()
notfound=0
do forever
   address sdsf 'ISFEXEC ST'
   if rc<>0 then
      do
      say 'probably some error...rc='rc
      exit 1
      end
   do i=1 to jobid.0
      if jobid.i<>jobid then iterate  /* not the specified job */
      if queue.i<>'PRINT' then leave  /* job not done yet */
      parse var retcode.i . cc .
      if cc=0 then
         exit 0
      exit 8
   end
   if i>jobid.0 then
      if notfound then
         do
         say 'Job' jobid 'not found'
         exit 2
         end
       else
         notfound=1
   if wt<>'' then
      do
      parse value time('E') with s '.'
      if s>wt then
         do
         say 'wait time exceeded'
         exit 2
         end
      end
   address syscall 'sleep 5'
end
