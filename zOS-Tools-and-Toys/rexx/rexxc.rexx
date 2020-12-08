/* REXX */
/***********************************************************************        
   Author: Bill Schoen  wjs@us.ibm.com
                                                                                
   Title: Shell utility to compile a REXX program
                                                                                
   PROPERTY OF IBM                                                              
   COPYRIGHT IBM CORP. 1994,2000
------------------------------------------------------------------------
   This exec runs under the OE shell to compile a REXX exec
     syntax:   rexxc [-cgV -o output_file] input_file
   Error messages will be directed to STDERR.
   -V produces a listing on STDOUT
   -c is compile for syntax only
   -g adds the SLINE and TRACE options
   -o names the output file, default is .cexec appended to input_file
   The permissions are preserved for an existing output file or set
   from the permissions of the original for a new file.

   Bill Schoen  5/5/94
      last update 4/9/00
***********************************************************************/        

if arg(1)='-?' then signal help
lcg='g'
lcc='c'
lco='o'
ucv='V'
opts='TERMINAL'
argx=getopts('gcV','o')
if argx=0 then
   signal usage
if __argv.0<argx then
   do
   call sayit 'file not specified'
   signal usage
   end
if __argv.0>argx then
   do
   call sayit 'too many files specified'
   signal usage
   end
src=__argv.argx
if opt.lcg<>'' then opts=opts 'SLINE TRACE'
if opt.lcc<>'' then opts=opts 'NOCOMPILE'
               else opts=opts 'CEXEC COMPILE'
if opt.ucv<>'' then opts=opts 'PRINT SOURCE XREF SAA'
               else opts=opts 'NOPRINT'
if opt.lco<>'' then cexec=opt.lco
               else cexec=src'.cexec'

lns.0=0
address syscall
'readfile (src) lns.'
if lns.0=0 then
   do
   call sayit 'file' src 'not found or empty'
   return
   end
if opt.lcc='' then
   do
   'stat (src) st.'
   'creat (cexec)' st.st_mode
   if retval=-1 then
      do
      call sayit 'unable to create' cexec
      return
      end
   fd=retval
   end
 else
   fd=-1

call sayit 'compiling' src 'as' cexec
call sayit 'options:' opts

attr='alloc new space(5,5) tracks recfm(v,b) lrecl(260) blksize(3280)'
call alloc 'sysin',attr
call alloc 'syscexec',attr
call alloc 'systerm',attr
if opt.ucv<>'' then
   do
lst='alloc new space(5,5) tracks recfm(v,b,a) lrecl(125) blksize(3280)'
   call alloc 'sysprint',lst
   end

address mvs
'execio' lns.0 'diskw sysin (stem lns. fini'
address attchmvs 'rexxcomp opts'
crc=rc
call sayit 'compiler return code was' crc
'execio * diskr syscexec (stem exec. fini'
'execio * diskr systerm (stem msg. fini'

'execio' msg.0 'diskw 2 (stem msg. fini'
address syscall
if opt.lcc='' then
   do
   do i=1 to exec.0
      'write (fd) exec.i'
   end
   'close' fd
   end
call alloc 'sysin','free'
call alloc 'syscexec','free'
call alloc 'systerm','free'
if opt.ucv<>'' then
   do
   address mvs 'execio * diskr sysprint (stem msg. fini'
   address mvs 'execio' msg.0 'diskw 1 (stem msg. fini'
   call alloc 'sysprint','free'
   end
return crc

alloc:
   parse arg dd,keys
   cmd=keys 'dd('dd')'
   if bpxwdyn(cmd 'msg(2)')<>0 then
      do
      call sayit 'dynalloc failed' result':' cmd
      exit 1
      end
   return 0

/**********************************************************************/
/*  Function: GETOPTS                                                 */
/*     This function parses __ARGV. stem for options in the format    */
/*     used by most POSIX commands.  This supports simple option      */
/*     letters and option letters followed by a single parameter.     */
/*     The stem OPT. is setup with the parsed information.  The       */
/*     options letter in appropriate case is used to access the       */
/*     variable:  op='a'; if opt.op=1 then say 'option a found'       */
/*     or, if it has a parameter:                                     */
/*        op='a'; if opt.op<>'' then say 'option a has value' opt.op  */
/*                                                                    */
/*  Parameters: option letters taking no parms                        */
/*              option letters taking 1 parm                          */
/*                                                                    */
/*  Returns: index to the first element of __ARGV. that is not an     */
/*           option.  This is usually the first of a list of files.   */
/*           A value of 0 means there was an error in the options and */
/*           a message was issued.                                    */
/*                                                                    */
/*  Usage:  This function must be included in the source for the exec */
/*                                                                    */
/*  Example:  the following code segment will call GETOPTS to parse   */
/*            the arguments for options a, b, c, and d.  Options a    */
/*            and b are simple letter options and c and d each take   */
/*            one argument.  It will then display what options were   */
/*            specified and their values.  If a list of files is      */
/*            specified after the options, they will be listed.       */
/*                                                                    */
/*    parse value 'a   b   c   d' with,                               */
/*                 lca lcb lcc lcd .                                  */
/*    argx=getopts('ab','cd')                                         */
/*    if argx=0 then exit 1                                           */
/*    if opt.0=0 then                                                 */
/*       say 'No options were specified'                              */
/*     else                                                           */
/*       do                                                           */
/*       if opt.lca<>'' then say 'Option a was specified'             */
/*       if opt.lcb<>'' then say 'Option b was specified'             */
/*       if opt.lcc<>'' then say 'Option c was specified as' opt.lcc  */
/*       if opt.lcd<>'' then say 'Option d was specified as' opt.lcd  */
/*       end                                                          */
/*    if __argv.0>=argx then                                          */
/*       say 'Files were specified:'                                  */
/*     else                                                           */
/*       say 'Files were not specified'                               */
/*    do i=argx to __argv.0                                           */
/*       say __argv.i                                                 */
/*    end                                                             */
/*                                                                    */
/**********************************************************************/
getopts: procedure expose opt. __argv.
   parse arg arg0,arg1
   argc=__argv.0
   opt.=''
   opt.0=0
   optn=0
   do i=2 to argc
      if substr(__argv.i,1,1)<>'-' then leave
      if __argv.i='-' then leave
         opt=substr(__argv.i,2)
      do j=1 to length(opt)
         op=substr(opt,j,1)
         if pos(op,arg0)>0 then
            do
            opt.op=1
            optn=optn+1
            end
         else
         if pos(op,arg1)>0 then
            do
            if substr(opt,j+1)<>'' then
               do
               opt.op=substr(opt,j+1)
               j=length(opt)
               end
             else
               do
               i=i+1
               if i>argc then
                  do
                  call sayit 'Option' op 'requires an argument'
                  return 0
                  end
               opt.op=__argv.i
               end
            optn=optn+1
            end
         else
            do
            call sayit 'Invalid option =' op
            return 0
            end
      end
   end
   opt.0=optn
   return i

sayit:
   parse arg saytext.1
   address mvs 'execio 1 diskw 2 (stem saytext.'
   return
    
usage:
   call sayit "Usage: rexxc [-cgV -o output_file] input_file"
   call sayit "For additional help enter rexxc -?"
   exit 1

help:
   do i=1 to sourceline(),
        while sourceline(i)<>'<help>'
   end
   do i=i+1 to sourceline(),
        while sourceline(i)<>'<end>'
      say sourceline(i)
   end
   exit 2

/*
<help>
Syntax:   rexxc [-cgV -o output_file] input_file
 
This invokes the REXX compiler to compile a REXX program into CEXEC format.
 
-V produces a listing on STDOUT
-c is compile for syntax only, no output file is created
-g adds the SLINE and TRACE options.  This is needed for execs that use
   sourceline() or any other function that needs the REXX source.
-o names the output file.  Default is .cexec appended to input_file
   The permissions are preserved for an existing output file or set
   from the permissions of the original for a new file.
 
input_file is the name of the REXX program to be compiled.  Only one
           file can be specified.
<end>
*/
