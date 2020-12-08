/* REXX */
/**********************************************************************/
/* ftpput   line command ftp stdin to a destination file              */
/* syntax:  ftpput <userid> <hostname> <hostfile>                     */
/*                                                                    */
/*  Notes:  stdin must be text                                        */
/*          you will be prompted for password                         */
/*          if the destination file exists it will be replaced        */
/*          <hostfile> can be a fully qualified quoted data set name  */
/*            or a simple file name or path name                      */
/*          if data set is a PDS or PDSE it must already be allocated */
/*          ex: cat xx | ftpput myuser my.host.name "'myuser.ds(xx)'" */
/*          ex: cat xx | ftpput myuser my.host.name /u/myuser/xx      */
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
   say 'establishing ftp session to' host
   if ftpapi(ftp.,'scmd','open' host,'w')<0 then return ftperr()
   pw=getpass('enter password for' user)
   say 'logging in user' user
   if ftpapi(ftp.,'scmd','user' user,'w')<0 then return ftperr()
   if ftpapi(ftp.,'scmd','pass' pw,'w')<0 then return ftperr()
   if ftpapi(ftp.,'scmd','ascii','w')<0 then return ftperr()
   if cd<>'' then
      if ftpapi(ftp.,'scmd','cd' cd,'w')<0 then return ftperr()
   if ftpapi(ftp.,'scmd','locsite unixfiletype=fifo','w')<0 then
      return ftperr()
   address syscall 'mkfifo (outfile) 700'
   say 'waiting for ftp to start'
   rv=ftpapi(ftp.,'scmd','put' outfile destfile,'n')
   address syscall 'open (outfile)' o_wronly '000'
   fd=retval
   if retval=-1 then
      do
      call '/bin/bpxmtext' errnojr
      return ftperr()
      end
   say 'sending' destname
   call senddata
   address syscall 'close (fd)'
   say 'waiting for ftp to complete'
   do until i=0
      i=ftpapi(ftp.,'poll',1)
      if i<0 then return ftperr()
   end
   call ftpcleanup
   return 0

ftperr:
   if rv<0 then
      say 'fpt error codes:' rv ftp.FCAI_Result FCAI_Result_ie,
                             ftp.FCAI_ie
   rm=ftpapi(ftp.,'getl_copy','ln.')
   if rm<0 then
      say 'get text error:' rv ftp.FCAI_Result FCAI_Result_ie,
                             ftp.FCAI_ie
   do i=1 to ln.0
      say ln.i
   end
   call ftpcleanup
   return 1
    
senddata:
   do forever
      address syscall 'read 0 buf 4096'
      len=retval
      if len=0 then return
      if len=-1 then
         do
         say 'unable to read from stdin'
         call '/bin/bpxmtext' errnojr
         return
         end
      address syscall 'write (fd) buf' len
      if retval<>len then
         do
         if retval=-1 then
            call '/bin/bpxmtext' errnojr
          else
            say 'unable to write to ftp'
         return
         end
   end

ftpcleanup:
   rv=ftpapi(ftp.,'term')
   address syscall 'unlink (outfile)'
   return

help:
   say 'ftpput <userid> <host> <destpath>'
   exit 0
