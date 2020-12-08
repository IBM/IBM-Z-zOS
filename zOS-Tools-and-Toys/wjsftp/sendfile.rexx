/* rexx */
/**********************************************************************/
/*  sendfile send email with attachments                              */
/*                                                                    */
/*    sendfile [-v] [-s subject] [-t textfile]...                     */
/*             [-f binaryfile]... [-n notefile]...                    */
/*             [-d distlist]... [address]...                          */
/*                                                                    */
/*    Options:                                                        */
/*      -v           verbose mode                                     */
/*      -s subject   subject text for the note                        */
/*      -t textfile  pathname of text file to attach to the note      */
/*                   any number of -t options can be specified        */
/*                   specify textfile as - to read from stdin         */
/*      -f binaryfile pathname of binary file to attach to the note   */
/*                   any number of -f options can be specified        */
/*                   specify binaryfile as - to read from stdin       */
/*      -n notefile  pathname of text file to send as the note        */
/*                   any number of -n options can be specified        */
/*                   specify notefile as - to read from stdin         */
/*      -d distfile  pathname of text file containing email addresses */
/*                   that is used as a distribution list              */
/*     address...    list of email addresses                          */
/*                   at least 1 email address must be specified via   */
/*                   -d or an address list                            */
/*  Install:                                                          */
/*     Copy this to your file system in a place where you can run     */
/*     programs.  Permissions must be at least read+execute.          */
/*     sendmail must be configured on your system                     */
/*                                                                    */
/*  PROPERTY OF IBM                                                   */
/*  COPYRIGHT IBM CORP. 2012,2013                                     */
/*                                                                    */
/*  Bill Schoen   4/26/2012   wjs@us.ibm.com                          */
/**********************************************************************/
parse value 'v   z   s   t   f   d   n   ' with,
             lcv lcz lcs lct lcf lcd lcn .
argx=getopts('vz','fdnst')
if __argv.0<argx then
   do
   say errmsg
   say 'usage: sendfile [-v] [-s subject] [-t textfile]...',
                       '[-f binaryfile]... [-n notefile]...',
                       '[-d distlist]... address...'
   exit 1
   end
mail.0=0
if opt.lcs<>'' then
   call buildtext ,'Subject:' opt.lcs
 else
   call buildtext ,'Subject: none'
if opt.lcn<>'' then
   do
   call buildtext opt.lcn
   do i=1 to opt.lcn.0
      call buildtext opt.lcn.i
   end
   end

if opt.lcf<>'' then
   do
   call buildatt opt.lcf
   do i=1 to opt.lcf.0
      call buildatt opt.lcf.i
   end
   end

if opt.lct<>'' then
   do
   call buildatt opt.lct,1
   do i=1 to opt.lct.0
      call buildatt opt.lct.i,1
   end
   end

dist=''
do i=argx to __argv.0
   dist=dist __argv.i
end
if opt.lcd<>'' then
   do
   dist=dist '$(cat' opt.lcd')'
   do i=1 to opt.lcd.0
      dist=dist '$(cat' opt.lcd.i')'
   end
   end
if opt.lcz<>'' then
   do i=1 to mail.0
      say mail.i
   end
cmd='sendmail -i' dist
say cmd
call bpxwunix cmd,mail.,out.,err.
do i=1 to out.0
   say out.i
end
do i=1 to err.0
   say err.0
end
return

buildtext:
   parse arg file,line
   if file='-' then
      file='/dev/fd0'
   ix=mail.0
   if line<>'' then
      do
      ix=ix+1
      mail.ix=line
      end
   if file<>'' then
      do
      out.0=0
      if opt.lcv<>'' then say 'note text:' file
      address syscall 'readfile (file) out.'
      do bi=1 to out.0
         ix=ix+1
         mail.ix=out.bi
      end
      end
   mail.0=ix
   return

buildatt:
   parse arg file,t
   if t=1 then
      do
      if file='-' then
         cmd='iconv -f IBM-1047 -t ISO8859-1 | uuencode stdin.txt'
       else
         cmd='iconv -f IBM-1047 -t ISO8859-1' file '| uuencode' file
      end
   else
      do
      if file='-' then
         cmd='uuencode stdin.txt'
       else
         cmd='uuencode' file file
      end
   if opt.lcv<>'' then say cmd
   call bpxwunix cmd,,out.,err.
   ix=mail.0
   do bi=1 to out.0
      ix=ix+1
      mail.ix=out.bi
   end
   mail.0=ix
   return

/**********************************************************************/
/*  Function: GETOPTS                                                 */
/*  Example:                                                          */
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
/**********************************************************************/
getopts: procedure expose opt. __argv. errmsg
   parse arg arg0,arg1
   argc=__argv.0
   errmsg=''
   opt.=''
   opt.0=0
   optn=0
   do i=2 to argc
      if substr(__argv.i,1,1)<>'-' then leave
      if __argv.i='--' then
         do
         i=i+1
         leave
         end
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
               if opt.op='' then
                  do
                  opt.op=substr(opt,j+1)
                  opt.op.0=0
                  end
                else
                  do
                  optmp=opt.op.0
                  optmp=optmp+1
                  opt.op.optmp=substr(opt,j+1)
                  opt.op.0=optmp
                  end
               j=length(opt)
               end
             else
               do
               i=i+1
               if i>argc then
                  do
                  errmsg='Option' op 'requires an argument'
                  return 0
                  end
               if opt.op='' then
                  do
                  opt.op=__argv.i
                  opt.op.0=0
                  end
                else
                  do
                  optmp=opt.op.0
                  optmp=optmp+1
                  opt.op.optmp=__argv.i
                  opt.op.0=optmp
                  end
               end
            optn=optn+1
            end
         else
            do
            errmsg='Invalid option =' op
            return 0
            end
      end
   end
   opt.0=optn
   return i
