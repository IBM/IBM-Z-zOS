/* REXX */
/**********************************************************************/
/* ftpget   line command ftp host file to stdout                      */
/* syntax:  ftpget <userid> <hostname> <hostfile>                     */
/*                                                                    */
/*  Notes:  hostfile must be text                                     */
/*          you will be prompted for password                         */
/*          <hostfile> can be a fully qualified quoted data set name  */
/*            or a simple file name or path name                      */
/*          ex: ftpget myuser my.host.name "'myuser.ds(xx)'" | wc     */
/*          ex: ftpget myuser my.host.name /u/myuser/xx | wc          */
/*                                                                    */
/* PROPERTY OF IBM                                                    */
/* COPYRIGHT IBM CORP. 2013                                           */
/*                                                                    */
/* Bill Schoen (wjs@us.ibm.com)  5/31/2013                            */
/**********************************************************************/
   parse arg user host file
   if file='' then
      signal help
   i=lastpos('/',file)
   if i=0 then
      do
      if substr(file,1,1)="'" then
         do
         parse var file "'" hlq '.' destfile "'"
         cd="'"hlq".'"
         destname='data set' translate(hlq'.'destfile)
         end
      else
         do
         cd=''
         destfile=file
         destname=file
         end
      end
    else
      do
      destfile=substr(file,i+1)
      cd=substr(file,1,i)
      destname='file' file
      end
   call syscalls 'ON'
   outfile='/tmp/'userid()'.ftpfifo'
   rv=ftpapi(ftp.,'create')
   if rv<>0 then return ftperr()
   rv=ftpapi(ftp.,'init')
   if rv<>0 then return ftperr()
   call say 'establishing ftp session to' host
   if ftpapi(ftp.,'scmd','open' host,'w')<0 then return ftperr()
   pw=getpass('enter password for' user)
   call say 'logging in user' user
   if ftpapi(ftp.,'scmd','user' user,'w')<0 then return ftperr()
   if ftpapi(ftp.,'scmd','pass' pw,'w')<0 then return ftperr()
   if ftpapi(ftp.,'scmd','ascii','w')<0 then return ftperr()
   if cd<>'' then
      if ftpapi(ftp.,'scmd','cd' cd,'w')<0 then return ftperr()
   if ftpapi(ftp.,'scmd','locsite unixfiletype=fifo','w')<0 then
      return ftperr()
   address syscall 'mkfifo (outfile) 700'
   call say 'waiting for ftp to start'
   rv=ftpapi(ftp.,'scmd','get' destfile outfile,'n')
   address syscall 'open (outfile)' o_rdonly '000'
   fd=retval
   if retval=-1 then
      do
      call '/bin/bpxmtext' errnojr
      return ftperr()
      end
   call say 'receiving destname'
   call senddata
   address syscall 'close (fd)'
   call say 'waiting for ftp to complete'
   do until i=0
      i=ftpapi(ftp.,'poll',1)
      if i<0 then return ftperr()
   end
   call ftpcleanup
   return 0

ftperr:
   if rv<0 then
      call say 'fpt error codes:' rv ftp.FCAI_Result FCAI_Result_ie,
                             ftp.FCAI_ie
   rm=ftpapi(ftp.,'getl_copy','ln.')
   if rm<0 then
      call say 'get text error:' rv ftp.FCAI_Result FCAI_Result_ie,
                             ftp.FCAI_ie
   do i=1 to ln.0
      call say ln.i
   end
   call ftpcleanup
   return 1
    
senddata:
   do forever
      address syscall 'read (fd) buf 4096'
      len=retval
      if len=0 then return
      if len=-1 then
         do
         call say 'unable to read from ftp'
         call '/bin/bpxmtext' errnojr
         return
         end
      address syscall 'write 1 buf' len
      if retval=-1 then
         do
         call say 'unable to write to stdout'
         call '/bin/bpxmtext' errnojr
         return
         end
      if retval<>len then
         do
         call say 'unable to complete writing to stdout'
         return
         end
   end

ftpcleanup:
   rv=ftpapi(ftp.,'term')
   address syscall 'unlink (outfile)'
   return

help:
   call say 'ftpget <userid> <host> <hostfile>'
   exit 0

say:
   msg=arg(1)'15'x
   address syscall 'write 2 msg' length(msg)
   return
