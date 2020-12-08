/* rexx */                                                                      
/**********************************************************************/        
/* List byte range lock holders & waiters for a system                */        
/* For use with z/OS V1.7+                                            */        
/* Updates earlier rangelks exec                                      */        
/* Superuser id needed                                                */        
/*                                                                    */        
/* PROPERTY OF IBM                                                    */        
/* COPYRIGHT IBM CORP. 2006                                           */        
/*                                                                    */        
/* Michael Cox (mccox1@us.ibm.com) with thanks to:                    */        
/* Bill Schoen (schoen@us.ibm.com)                                    */        
/*                                                                    */        
/* 2/16/2007 - fix from Werner Keundig                                */        
/**********************************************************************/        
arg diag                                                                        
call syscalls on                                                                
address syscall                                                                 
                                                                                
sayerror = "do; strerror errno errnojr err.;" ,                                 
           "    say err.se_errno; say err.se_reason;" ,                         
           "    exit 2; end;"                                                   
                                                                                
'v_reg 2 RxLocker'                /* register server as a lock server */        
                                                                                
/**********************************************************************/        
/* register locker                                                    */        
/**********************************************************************/        
lk.vl_serverpid=0                 /* use my pid as server pid         */        
lk.vl_clientpid=1                 /* set client process id            */        
'v_lockctl' vl_reglocker 'lk.'    /* register client as a locker      */        
c1tok=lk.vl_lockertok             /* save client locker token         */        
                                                                                
call loadsysnames                                                               
call dumplocks                                                                  
                                                                                
/**********************************************************************/        
/* unregister locker                                                  */        
/**********************************************************************/        
lk.vl_lockertok=c1tok             /* set client locker token          */        
'v_lockctl' vl_unreglocker 'lk.'  /* unregister client as a locker    */        
                                                                                
return                                                                          
                                                                                
/**********************************************************************/        
dumplocks:                                                                      
                                                                                
lk.vl_lockertok = c1tok                                                         
lk.vl_objclass  = '00000000'x                                                   
lk.vl_objid     = '000000000000000000000000'x                                   
lk.vl_objtok    = '0000000000000000'x                                           
vl_unloadlocks = 10                                                             
ull. = ''                                                                       
'v_lockctl' vl_unloadlocks 'lk.' 'ull.'                                         
if retval = -1 then interpret sayerror                                          
                                                                                
say 'total number of lock entries = ' ull.0                                     
say ' '                                                                         
                                                                                
numeric digits 16                                                               
                                                                                
do i = 1 to ull.0                                                               
  if pos('V',diag)>0 then call dump ull.i                                       
  class = c2d(substr(ull.i,1,4),4)                                              
  if class = c2d(' dup') then iterate                                           
  dev   = c2d(substr(ull.i,5,4),8)                                              
  ino   = c2d(substr(ull.i,13,4),16)                                            
  spid  = c2d(substr(ull.i,17,4),10)                                            
  cpid  = c2d(substr(ull.i,21,4),10)                                            
  tid   = c2x(substr(ull.i,25,8))                                               
  if bitand(substr(ull.i,49,1),'80'x) = '80'x then                              
    waiter = 1                                                                  
  else                                                                          
    waiter = 0                                                                  
                                                                                
  /* get lock count for this process for this file                   */         
  lockcnt = 1                                                                   
  if waiter = 0 then do                                                         
    do j = i+1 to ull.0                                                         
      if substr(ull.i,1,24) = substr(ull.j,1,24) then do                        
        ull.j = ' dup' || right(ull.j,length(ull.j)-4)                          
        lockcnt = lockcnt + 1                                                   
  end; end; end;                                                                
  if lockcnt > 1 then                                                           
    locks = '       # locks =' lockcnt                                          
  else                                                                          
    locks = ''                                                                  
                                                                                
  /* get pathname & filesys name of locked file                      */         
  if class = 0 then do                                                          
    'getmntent lkmnt.' dev                                                      
    if retval = -1 then interpret sayerror                                      
    mntpath  = lkmnt.mnte_path.1'/'                                             
    fsname   = lkmnt.mnte_fsname.1                                              
    sysowner = lkmnt.mnte_sysname.1                                             
                                                                                
    findcmd = 'find "'mntpath'" -xdev -inum' ino'00'x                           
    if retval = -1 then interpret sayerror                                      
    if bpxwunix(findcmd,,s.)=0 then                                             
      file = s.1                                                                
    else                                                                        
      file = '???'                                                              
  end                                                                           
                                                                                
  /* get locker pid                                                  */         
  if maxsys = 0 & spid = 0 then                                                 
    pid = cpid                                                                  
  else if maxsys = 0 & spid <> 0 then                                           
    pid = spid                                                                  
  else if spid > 0 & spid < maxsys+1 then                                       
    pid = cpid                                                                  
  else if spid > 0 then                                                         
    pid = spid                                                                  
  else                                                                          
    pid = -1                                                                    
  if pid <> -1 then                                                             
    sysid = x2d(substr(right(d2x(pid),8,0),3,2))                                
  else                                                                          
    pid = '????', sysid = '????'                                                
                                                                                
  /* get lock status                                                 */         
  if class > 0 & maxsys = 0 & pid = spid then do                                
    type   = '        ** abstract lock **'                                      
    file   = 'n/a   '                                                           
    fsname = 'n/a     '                                                         
  end                                                                           
  else if waiter = 1 then                                                       
    type = '        ** waiting for lock **'                                     
  else if sysid = mysysid then                                                  
    if maxsys = 0 | mems.mysysid.2 = sysowner then                              
      type = '        ** active lock **'                                        
    else                                                                        
      type = '        ** backup lock **'                                        
  else                                                                          
    type = '        ** active lock **'                                          
                                                                                
  say 'File' strip(file) 'in' strip(fsname)                                     
  say 'PID =' right(pid,10) 'on' left(mems.sysid.2,8) type locks                
  say ' '                                                                       
                                                                                
end                                                                             
                                                                                
return                                                                          
                                                                                
/**********************************************************************/        
ofs:                                                                            
   arg ofsx,ln                                                                  
   return substr(buf,x2d(ofsx)+1,ln)                                            
                                                                                
/**********************************************************************/        
loadsysnames:                                                                   
                                                                                
numeric digits 12                                                               
z1='00'x                                                                        
z2='0000'x                                                                      
z4='00000000'x                                                                  
cvtecvt=140                                                                     
ecvtocvt=240                                                                    
ocvtocve=8                                                                      
ocvtfds='58'                                                                    
ocvtkds='48'                                                                    
ocveppra='8'                                                                    
ofsb='1000'                                                                     
ofsblen='200'                                                                   
                                                                                
cvt=c2x(storage(10,4))                                                          
ecvt=c2x(storage(d2x(x2d(cvt)+cvtecvt),4))                                      
ocvt=c2x(storage(d2x(x2d(ecvt)+ecvtocvt),4))                                    
ocve=c2x(storage(d2x(x2d(ocvt)+ocvtocve),4))                                    
                                                                                
fds=storage(d2x(x2d(ocvt)+x2d(ocvtfds)),4)                                      
kds=storage(d2x(x2d(ocvt)+x2d(ocvtkds)),4)                                      
                                                                                
if fetch(fds,'00001000'x,'10') then                                             
   do                                                                           
   say 'Kernel is unavailable or at the wrong level',                           
                  'for this function or you are not a superuser'                
   exit 1                                                                       
   end                                                                          
                                                                                
ocvenxab='84'                                                                   
nxabnxmb='14'                                                                   
nxmbmaxsys='18'                                                                 
nxmbmemar='30'                                                                  
nxmbarsysname='8'                                                               
nxmbarsysnum='0'                                                                
nxmbarstat='4'                                                                  
memarlen=32                                                                     
mysysid=0                                                                       
call fetch z4,x2c(ocve),140                                                     
nxab=c2x(ofs(ocvenxab,4))                                                       
if nxab=0 then                                                                  
   do                                                                           
   maxsys=0                                                                     
   address syscall 'uname unm.'                                                 
   mems.0.1=unm.1                                                               
   mems.0.2=unm.2                                                               
   return                                                                       
   end                                                                          
call fetch z4,x2c(nxab),32                                                      
nxmb=c2x(ofs(nxabnxmb,4))                                                       
call fetch z4,x2c(nxmb),56                                                      
memar=c2x(ofs(nxmbmemar,4))                                                     
maxsys=c2d(ofs(nxmbmaxsys,4))                                                   
call fetch z4,x2c(memar),memarlen*maxsys                                        
do mems=1 to maxsys                                                             
   if bitand('80'x,ofs(nxmbarstat,1))=z1 then                                   
      do                                                                        
      mems.mems.1=0                                                             
      mems.mems.2='unknown'                                                     
      end                                                                       
    else                                                                        
      do                                                                        
      mems.mems.1=c2d(ofs(nxmbarsysnum,1))                                      
      mems.mems.2=ofs(nxmbarsysname,8)                                          
      end                                                                       
   buf=substr(buf,memarlen+1)                                                   
end                                                                             
address syscall 'uname unm.'                                                    
do si=1 to maxsys                                                               
   if unm.2<>mems.si.2 then iterate                                             
   mysysid=mems.si.1                                                            
   say 'Dumping locks managed on' unm.2                                         
   leave                                                                        
end                                                                             
return                                                                          
                                                                                
/**********************************************************************/        
fetch:                                                                          
   parse arg alet,addr,len,eye  /* char: alet,addr  hex: len */                 
   pctcmd=-2147483647                                                           
   pfs='KERNEL'                                                                 
   len=x2c(right(len,8,0))                                                      
   dlen=c2d(len)                                                                
   buf=alet || addr || len                                                      
   'pfsctl' pfs pctcmd 'buf' max(dlen,12)                                       
   if retval=-1 then                                                            
      return 1                                                                  
   if rc<>0 then                                                                
      do                                                                        
      say 'error fetching kernel address'                                       
      say 'buf:' c2x(buf)                                                       
      say 'len:' max(dlen,12)                                                   
      exit 3                                                                    
      end                                                                       
   if eye<>'' then                                                              
      if substr(buf,1,length(eye))<>eye then                                    
         return 1                                                               
   if dlen<12 then                                                              
      buf=substr(buf,1,dlen)                                                    
   return 0                                                                     
                                                                                
/**********************************************************************/        
dump: procedure                                                                 
   parse arg dumpbuf                                                            
   sk=0                                                                         
   do ofs=0 by 16 while length(dumpbuf)>0                                       
      parse var dumpbuf 1 ln 17 dumpbuf                                         
      out=c2x(substr(ln,1,4)) c2x(substr(ln,5,4)),                              
          c2x(substr(ln,9,4)) c2x(substr(ln,13,4)),                             
          "'"translate(ln,,xrange('00'x,'40'x))"'"                              
      if prev=out then                                                          
         sk=sk+1                                                                
       else                                                                     
         do                                                                     
         if sk>0 then say '...'                                                 
         sk=0                                                                   
         prev=out                                                               
         say right(ofs,6)'('d2x(ofs,4)')' out                                   
         end                                                                    
   end                                                                          
   return                                                                       
