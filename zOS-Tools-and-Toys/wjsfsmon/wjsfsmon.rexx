/* REXX */
/**********************************************************************/
/* WJSFSMON:  file system monitor                                     */
/*                                                                    */
/*   This utility will monitor file system usage for the purpose of   */
/*   helping you decide which file systems might perform better if    */
/*   they are changed to make use of the zFS sysplex capability.      */
/*                                                                    */
/*   You must be a superuser to start or end the monitor              */
/*   You should have a 7 color 3270 to view the data                  */
/*                                                                    */
/*   Syntax:  wjsfsmon <option>                                       */
/*                                                                    */
/*   Options (valid combinations shown):                              */
/*     -s <-i interval> <-h history>   start monitor on this system   */
/*                  using <interval> seconds and keep <history> number*/
/*                  of intervals. Default: -s -i 60 -h 60             */
/*     -sa <-i interval> <-h history>   start monitor on all systems  */
/*                  using <interval> seconds and keep <history> number*/
/*                  of intervals. Default: -s -i 60 -h 60             */
/*                  This is only supported when run using sysrexx     */
/*                     f axr,wjsfsmon,t=0 -sa                         */
/*     -e          end monitor on all systems and clear data          */
/*     -w file     snapshot the current history and copy to file      */
/*                  for file specify a full data set name             */
/*     -q          query monitor status on all systems                */
/*     -r file     read and process history data                      */
/*                 use -r active to process active data in the sysplex*/
/*                                                                    */
/*                                                                    */
/*    Return codes:                                                   */
/*                                                                    */
/* PROPERTY OF IBM                                                    */
/* COPYRIGHT IBM CORP. 2009,2010                                      */
/*                                                                    */
/* Bill Schoen    wjs@us.ibm.com  10/30/09                            */
/*  Change activity:                                                  */
/*     12/11/09  separate remote from zfs sysplex on first screen     */
/*               subtract remote I/O counts from counts on owner      */
/*      3/09/10   do not exit on END from contention screen           */
/*      3/17/10   avoid data collection on systems with monitor off   */
/*                remove cleared directories, show filesys even if    */
/*                no remote access, scroll help panels, edit help,    */
/*                improve some column formatting, remove heading color*/
/*      4/30/10   capture messages from sort failure                  */
/*                handle special characters in userid                 */
/*                                                                    */
/**********************************************************************/
/*
All files reside in /var/fsmon
./fsmon
   this is a copy of the exec that is used to start the monitor

./control
   monitor puts a write lock on this file
   this ensures only 1 monitor is started
   the lock is also used to query that the monitor is running
   format: 1 line
     pid interval history
   when size changes (trunc to 0) monitor exits

./index
   contains a record for each file system, unique to owner and pfs
   format:
      sysname,owner,fsname,pfsname,localflag devno smf
      localflag=0 xpfs
      localflag=1 locally mounted
      localflag=2 locally mounted to zfs sysplex aware
      smf=0 smf counts are valid
      smf=1 no smf counts, latch counts used

./interval.n   0<=n<history
   contains counts for the interval and active job usage
   type=0 header line: time interval#
   type=1 index# wrcount fastlat slowlat
   type=2 jobname userid ino
     type 2 records immediately follow corresponding type=1
     index# is the record number in the index file corresponding to
     the filesystem/owner/pfs the counts relate to
*/
version=1
numeric digits 20
signal on novalue
signal on halt
parse source . . . . . . . rxenv .
if syscalls('ON')>4 then
   do
   call sayc 'Cannot initialize as a unix process'
   if rxenv='AXR' then
      call sayc 'Logon to the console with an OMVS superuser ID'
   return
   end
arg prms
parse arg mcprms
interval=60
history=60
fsmonpath='/var/fsmon'
sortpath='/tmp/fsmon'
indexfile=fsmonpath'/index'
ctlfile=fsmonpath'/control'
tempfile=fsmonpath'/temp'
stdout=fsmonpath'/stdout'
fsmon=fsmonpath'/fsmon'
intervalpref=fsmonpath'/interval.'
parse value '' with opt_s opt_e opt_q output input active
verbose=0
data.=''
ispf = rxenv='ISPF'
needcleanup=0
initialized=0
sysid=''
if pos('-I',prms)>0 then  /* set interval */
   do
   parse var prms pre '-I' interval post
   prms=pre post
   if interval='' | datatype(interval,'W')=0 then
      prms=pre '-I' interval post   /* not valid, error later */
   end
if pos('-H',prms)>0 then  /* set interval */
   do
   parse var prms pre '-H' history post
   prms=pre post
   if history='' | datatype(history,'W')=0 then
      prms=pre '-H' history post    /* not valid, error later */
   end
if pos('-Q',prms)>0 then  /* query monitor */
   do
   parse var prms pre '-Q' post
   prms=pre post
   opt_q=1
   end
if pos('-SA',prms)>0 then /* start monitor on all systems */
   do
   parse var prms pre '-SA' post
   prms=pre post
   opt_s=2
   end
if pos('-S',prms)>0 then  /* start monitor */
   do
   parse var prms pre '-S' post
   prms=pre post
   opt_s=1
   end
if pos('-E',prms)>0 then  /* end monitor */
   do
   parse var prms pre '-E' post
   prms=pre post
   opt_e=1
   end
if pos('-V',prms)>0 then  /* verbose/debug */
   do
   parse var prms pre '-V' post
   prms=pre post
   verbose=1
   end
if pos('-W',prms)>0 then  /* write raw data */
   do
   parse var prms pre '-W' . post
   parse var mcprms '-W' output .
   if output='' then
      parse var mcprms '-w' output .
   if output='' then signal help
   prms=pre post
   end
if pos('-R',prms)>0 then  /* read and process raw data */
   do
   parse var prms pre '-R' . post
   parse var mcprms '-R' input .
   if input='' then
      parse var mcprms '-r' input .
   if input='' then signal help
   if translate(input)='ACTIVE' then
      do
      active=1
      input=''
      end
   prms=pre post
   end

if prms<>'' then
   signal help

/* mutual exclusion rules */
if opt_s<>'' &,
   (opt_e<>'' | active<>'' | input<>'' | output<>'') then
   signal help
if opt_e<>'' &,
   (opt_s<>'' | active<>'' | input<>'' | output<>'') then
   signal help
if output<>'' &,
   (opt_s<>'' | opt_e<>'' | active<>'' | input<>'') then
   signal help
if input<>'' &,
   (opt_s<>'' | opt_e<>'' | active<>'' | output<>'') then
   signal help

if opt_s=2 then
   call startonall

if opt_s=1 then
   do
   call startmonitor
   end

if output<>'' then
   do
   if data.0='' then
      call collectdata
   if data.0<>0 then
      call savedata
   opt_q=1
   end

if input<>'' then
   do
   call initcolors
   call loaddata
   if data.0>0 then
      call analyzedata
   end
else
if active=1 then
   do
   call initcolors
   call collectdata
   if data.0<>0 then
      call analyzedata
   end

if opt_q=1 then
   call query

if opt_e=1 then
   call stopmonitor

return 0

help:
   do
   call say 'format: wjsfsmon -s  <-i interval> <-h history>'
   call say '        wjsfsmon -sa <-i interval> <-h history>'
   call say '        wjsfsmon -e'
   call say '        wjsfsmon -w file'
   call say '        wjsfsmon -r file|active'
   call say '        wjsfsmon -q'
   exit
   end

novalue:
  say 'uninitialized variable in line' sigl
  say sourceline(sigl)
  trace ?i
  nop
halt:
  exit 0

/**********************************************************************/
query:
   call initialize
   call getsysnames
   do i=1 to 32
      if sysnames.i<>'' then
         do
         parse value monstatus(sysnames.i'/'ctlfile) with pid iv hist .
         if pid='' then
           call sayc left(sysnames.i,8) 'monitor not running'
          else
           call sayc left(sysnames.i,8),
                     'pid='pid 'interval='iv 'history='hist
         end
   end
   return

/**********************************************************************/
loaddata:
   data.0=0
   vx=''
   if substr(input,1,1)='/' then
      do
      call sayc 'pathnames not supported for input files'
      end
    else
      do
      rv=bpxwdyn('alloc fi(fsmon) shr da('input') reuse')
      if rv<>0 then
         do
         call sayc 'allocation error' rv input
         end
       else
         do
         address mvs 'execio 1 diskr fsmon (stem proc.'
         parse var proc.1 'data' dx 'proc' px 'version' vx .
         if datatype(px,'W') then
            do
            address mvs 'execio' dx 'diskr fsmon (stem data.'
            address mvs 'execio' px 'diskr fsmon (fini stem proc.'
            end
         call bpxwdyn 'free fi(fsmon)'
         end
      end
   if data.0=0 then
      do
      call sayc 'unable to read' input
      end
   else
   if vx<>version then
      do
      call sayc input 'is at the wrong version level'
      data.0=0
      end
   return

/**********************************************************************/
buildproci:
   do i=1 to proc.0
      parse var proc.i prtime prowner prfsn prjob logname .

   end
         parse var rest job logname ino .
         prix=fsname'.'job'.'logname
         if proci.prix<>'' then iterate
         proci.prix=1
         px=px+1
         proc.px=itime fsname job logname

/**********************************************************************/
initcolors:
   if ispf=0 then
      do
      call sayc 'wjsfsmon must run under ISPF'
      exit 1
      end
   keep=0
   call buildpan
   address ispexec 'vget (zcolors zhilite)'
   colorsdisabled = zcolors<>7 | zhilite<>'YES'
   colors='BLACK WHITE RED BLUE GREEN PINK YELLOW TURQ'
   black=' '
   parse value '11'x '12'x '13'x '14'x '15'x '16'x '17'x with,
                white red blue green pink yellow turq
   c_bg=white
   c_hd=white
   c_rem=red
   c_remz=yellow
   c_loc=green
   c_but=blue
   c_tm=green
   c_tmw=red
   c_con=red
   c_noc=green
   address ispexec 'vget (wjsfsmc) profile'
   if rc=0 then
      do
      c_bg=substr(wjsfsmc,1,1)
      c_hd=substr(wjsfsmc,2,1)
      c_but=substr(wjsfsmc,3,1)
      c_rem=substr(wjsfsmc,4,1)
      c_remz=substr(wjsfsmc,5,1)
      c_loc=substr(wjsfsmc,6,1)
      c_tm=substr(wjsfsmc,7,1)
      c_tmw=substr(wjsfsmc,8,1)
      c_con=substr(wjsfsmc,9,1)
      c_noc=substr(wjsfsmc,10,1)
      end
   return

/**********************************************************************/
analyzedata:
   rowx=1
   cmd='HelpG'
   call dohelp
/* address ispexec 'CONTROL ERRORS RETURN' */
/* call browsestem 'data.' */
   call initdyn
   call getcountsbyfs
   running=1
   do while running
      call showbyfs
   end
   call cleanup
   return

/**********************************************************************/
qrowcol:
   if csrfld<>'DYN' then
      do
      cmd='HelpG'
      call dohelp
      return 1
      end
   csrrow=(csrpos+width-1)%width
   csrcol=csrpos-(csrrow-1)*width
   return 0

/**********************************************************************/
docmd:
   cmd=''
   if csrrow<>1 then return
   cmd=word(extrl(1),csrcol%10+1)
   if cmd='Exit' then
      running=0
   else
   if cmd='Colors' then
      do
      cmd=''
      call setcolors
      end
   else
   if substr(cmd,1,4)='Help' then
      call dohelp
   return

/**********************************************************************/
dohelp:
   hscroll=3
   do forever
   call initdyn
   do i=1 to sourceline()
      parse value sourceline(i) with '//' key .
      if key=cmd then leave
   end
   j=0
   k=0
   do i=i+1 to sourceline()
      parse value sourceline(i) with '//' key .
      if key='end' then leave
      k=k+1
      if j>1 & k<hscroll then iterate
      j=j+1
      call typeh sourceline(i),j,1
      if j>=depth then leave
   end
   call backh c_but,1,1,width
   address ispexec 'DISPLAY PANEL(DYNSCR) CURSOR(DYN) CSRPOS(1)'
   address ispexec 'vget (zverb)'
   if zverb='DOWN' then
      do
      hscroll=hscroll+1
      iterate
      end
   if zverb='UP' then
      do
      if hscroll>3 then
         hscroll=hscroll-1
      iterate
      end
   if zverb='LEFT' | zverb='RIGHT' then iterate
   leave
   end
   cmd=''
   return

/**********************************************************************/
setcolors:
 colorvars='black white red blue green pink yellow turq'
 do forever
   call initdyn
   call setcmdline 'Back Defaults','C'
   call typeh 'Use the cursor to select the color for an area',2,1
   call colorsel 'background',c_bg,4
/* call colorsel 'heading   ',c_hd,5  */
   call colorsel 'buttons   ',c_but,6
   call colorsel 'remote    ',c_rem,7
   call colorsel 'remote zfs',c_remz,8
   call colorsel 'local     ',c_loc,9
   call colorsel 'time-total',c_tm,10
   call colorsel 'time-write',c_tmw,11
   call colorsel 'contention',c_con,12
   call colorsel 'no conten.',c_noc,13
   address ispexec 'DISPLAY PANEL(DYN) CURSOR(DYN) CSRPOS('3*width+1')'
   if rc<>0 then leave
   if qrowcol() then iterate
   if csrrow=1 then
      do
      call docmd
      if cmd='Back' then leave
      if cmd='Exit' then leave
      if cmd='Defaults' then
         do
         c_bg=white
         c_hd=white
         c_rem=red
         c_remz=yellow
         c_loc=green
         c_but=blue
         c_tm=green
         c_tmw=red
         c_con=red
         c_noc=green
         iterate
         end
      end
   if csrrow<4 | csrcol<12 then iterate
   i=(csrcol-12)%8+1
   if i>8 then iterate
   if csrrow=4 then c_bg=value(word(colorvars,i))
   c_hd=c_bg
/* if csrrow=5 then c_hd=value(word(colorvars,i)) */
   if csrrow=6 then c_but=value(word(colorvars,i))
   if csrrow=7 then c_rem=value(word(colorvars,i))
   if csrrow=8 then c_remz=value(word(colorvars,i))
   if csrrow=9 then c_loc=value(word(colorvars,i))
   if csrrow=10 then c_tm=value(word(colorvars,i))
   if csrrow=11 then c_tmw=value(word(colorvars,i))
   if csrrow=12 then c_con=value(word(colorvars,i))
   if csrrow=13 then c_noc=value(word(colorvars,i))
 end
 c_hd=c_bg
 wjsfsmc=c_bg || c_hd || c_but || c_rem || c_remz || c_loc || c_tm ||,
         c_tmw || c_con || c_noc
 address ispexec 'vput (wjsfsmc) profile'
 return

/**********************************************************************/
colorsel:
   parse arg areaname,areacolor,linenum
   call typeh areaname,linenum,1
   call backh areacolor,linenum,1,10
   do i=1 to 8
      call backh value(word(colorvars,i)),linenum,12+i*8-8,12+i*8
      call typeh word(colorvars,i),linenum,12+i*8-8
   end
   return

/**********************************************************************/
details:
   parse arg fsn
 do while running
   call initdyn
   call setcmdline 'Back Remove',2
   call typeh fsn,2,1
   danosmf=da.fsn.6
   if danosmf=1 then
      do
      call typeh 'Fast',3,28
      call typeh 'Slow',3,39
      end
    else
      do
      call typeh 'Reads',3,27
      call typeh 'Writes',3,37
      end
   row=3
   row1=width*3+1
   row.=''
   localtypes='R L Z'
   do l=0 to 2 by 1
      localtype=word(localtypes,l+1)
      do i=1 to sysnames.0
         sysn=sysnames.i
         didone=0
         do j=1 to sysnames.0
            syso=sysnames.j
            rcount=da.fsn.l.sysn.syso.1
            wcount=da.fsn.l.sysn.syso.2
            count=rcount+wcount
            if count>0 then
               do
               row=row+1
               if localtype='L' | sysn=syso then
                  do
                  call typeh 'L' left(sysn,18),
                             right(rcount,10),
                             right(wcount,10),row,1
                  row.row=c_loc count
                  end
                 else
                  do
                  call typeh localtype left(sysn'>'syso,18),
                             right(rcount,10),
                             right(wcount,10),row,1
                  if localtype='Z' then
                     row.row=c_remz count
                    else
                     row.row=c_rem count
                  end
               didone=1
               end
         end
         if didone then
            row=row+1
      end
   end
   row.0=row
   do i=1 to row.0
      if row.i<>'' then
         call backh word(row.i,1),i,1,scale(word(row.i,2))
   end
   address ispexec 'DISPLAY PANEL(DYN) CURSOR(DYN) CSRPOS(1)'
   if rc<>0 then leave
   if qrowcol() then iterate
   if csrrow=1 then
      do
      call docmd
      if cmd='Remove' then
         do i=1 to da.0
            parse var da.i . fs
            if fs<>fsn then iterate
            da.i=''
            cmd='Back'
            leave
         end
      if cmd='Back' then leave
      end
   else
   if csrrow<3 then
      iterate
   else
      do
      ln=extrl(csrrow)
      parse var ln w1 w2 .
      if pos(w1,'LRZ')<>0 then
         call showbytime w1,w2,fsn
      end
 end
 return

/**********************************************************************/
setcmdline:
   /* 8 characters per command
      left justify in an 8 character color button
      two spaces between command buttons
      all command lines have exit and help buttons appended
   */
   parse arg cmds,helpix
   cmds=cmds 'Exit Help'helpix
   cmdline=''
   do while cmds<>''
      parse var cmds c1 cmds
      cmdline=cmdline left(c1,9)
   end
   call typeh strip(cmdline),1,1
   do i=1 to words(cmdline)
      call backh c_but,1,i*10-9,i*10-2
   end
   return

/**********************************************************************/
buildtimes:
/*
   datime.n    total reads+writes
   datime.n.1  time of day
   datime.n.2  index into data.
   datime.n.3  write count
   datime.n.4  read count
*/
   stime=word(data.1,1)
   itime=stime
   i=data.0
   etime=word(data.i,1)
   secs=etime-stime
   segs=depth-5         /* number of time lines is segs+1 */
   secperseg=format(secs/segs,,0)
   datime.=0
   do i=1 to data.0
      parse var data.i datime darcount dawcount dafast daslow,
                       dalocal dasys daowner dafsn dapfs danosmf .
      dacount=darcount+dawcount
      if dafsn<>sbtfsn then iterate
      if dasys<>sbtsysn then iterate
      if sbtlocal<>'-' & sbtlocal<>dalocal then iterate
  /*  if sbtlocal='L' then
         iterate
      else
      if sbtlocal='R' then
         do
         if daowner<>sbtsyso then iterate
         end
      else
      if sbtlocal='Z' then
         do
         if daowner<>sbtsyso then iterate
         end   */
      if datime>=itime then
         do
         j=j+1
         itime=datime+secperseg
         datime.j.1=datime
         datime.j.2=''            /* keep list of indexes into data.*/
         end
      datime.j=datime.j+dacount
      datime.j.3=datime.j.3+dawcount
      datime.j.4=datime.j.4+darcount
      datime.j.2=datime.j.2 i
   end
   datime.0=j
   return

/**********************************************************************/
showbytime:
   parse arg sbtloc,sbtsys,sbtfsn
   parse var sbtsys sbtsysn'>'sbtsyso
   sbtlocal=translate(sbtloc,'012','RLZ')
   j=0
   call buildtimes
   itime=stime
   cmd='Interval'
   lastcmd='Interval'
   lcmds='Back Interval User Proc'
   do while running
      if cmd='Interval' then call showintervals
      else
      if cmd='User' then call showbyuser
      else
      if cmd='Proc' then call showbyproc
      else
      if cmd='Back' then leave
      else
      cmd=lastcmd
   end
   return

/**********************************************************************/
gmt:
   parse arg posixtime
   ts.=''
   address syscall 'gmtime' posixtime 'ts.'
   return right(ts.tm_hour,2,0)':'right(ts.tm_min,2,0)':' ||,
          right(ts.tm_sec,2,0)

/**********************************************************************/
showintervals:
   lastcmd='Interval'
   cmd=''
   intervalindex=''
   call initdyn
   call setcmdline lcmds,3
   if danosmf=1 then
      do
      call typeh 'Intervals:' sbtloc sbtsys sbtfsn,2,1
      call typeh '  Slow',3,14
      call typeh '  Fast',3,25
      end
    else
      do
      call typeh 'Intervals:' sbtloc sbtsys sbtfsn,2,1
      call typeh 'Writes',3,14
      call typeh ' Reads',3,25
      end
   call typeh 'From' gmt(stime) 'to' gmt(etime),3,35
   do i=1 to datime.0
      call backh c_tm,i+3,1,scale(datime.i)
      if datime.i.3>0 then
         do
         call backh c_tmw,i+3,1,scale(datime.i.3)
         end
      ts=gmt(datime.i.1)
      call typeh ts right(datime.i.3,10),
           right(datime.i.4,10),i+3,1
   end
   address ispexec 'DISPLAY PANEL(DYN) CURSOR(DYN) CSRPOS(1)'
   if rc<>0 then
      do
      cmd='Back'
      return
      end
   if qrowcol() then return
   call docmd
   return

   if csrrow<3 then return
   ln=extrl(csrrow)
   if ln='' then return
   i=csrrow-3                  /* set index into datime. */
   intervalindex=datime.i.2    /* get index list into data. */
   cmd='User'
   return

/**********************************************************************/
showbyuser:
   cmd=''
   lastcmd='User'
   j=0
   proci.=''
   do i=1 to proc.0
      parse var proc.i prtime prowner prfsn prjob logname .
      if prfsn<>sbtfsn then iterate
      if prowner<>sbtsysn then iterate
      if proci.logname='' then
         do
         j=j+1
         proci.j=logname
         proci.logname=0
         end
      proci.logname=proci.logname+1
   end
   proci.0=j
   do i=1 to proci.0
      user=proci.i
      proci.i=right(proci.user,10,0) user
   end
   call sortstem 'proci.'
   call initdyn
   msg='Users of' sbtfsn 'from' sbtsysn
   call typeh msg,2,1
   call setcmdline lcmds,4
   j=3
   do i=proci.0 by -1 to 1
      j=j+1
      if j>depth then leave
      parse var proci.i ucount user .
      call backh c_tm,j,1,scale(ucount)
      call typeh left(user,8) ucount+0,j,1
   end
   address ispexec 'DISPLAY PANEL(DYN) CURSOR(DYN) CSRPOS(1)'
   if rc<>0 then
      do
      cmd='Back'
      return
      end
   if qrowcol() then return
   call docmd
   return

/**********************************************************************/
showbyproc:
   cmd=''
   lastcmd='Proc'
   j=0
   proci.=''
   do i=1 to proc.0
      parse var proc.i prtime prowner prfsn prjob logname .
      if prfsn<>sbtfsn then iterate
      if prowner<>sbtsysn then iterate
      if proci.prjob='' then
         do
         j=j+1
         proci.j=prjob
         proci.prjob=0
         end
      proci.prjob=proci.prjob+1
   end
   proci.0=j
   do i=1 to proci.0
      user=proci.i
      proci.i=right(proci.user,10,0) user
   end
   call sortstem 'proci.'
   call initdyn
   msg='Jobs using' sbtfsn 'from' sbtsysn
   call typeh msg,2,1
   call setcmdline lcmds,5
   j=3
   do i=proci.0 by -1 to 1
      j=j+1
      if j>depth-3 then leave
      parse var proci.i ucount user .
      call backh c_tm,j,1,scale(ucount)
      call typeh left(user,8) ucount+0,j,1
   end
   address ispexec 'DISPLAY PANEL(DYN) CURSOR(DYN) CSRPOS(1)'
   if rc<>0 then
      do
      cmd='Back'
      return
      end
   if qrowcol() then return
   call docmd
   return

/**********************************************************************/
showbyfs:
   call initdyn
   msg='Local and remote access by file system'
   call typeh msg,2,1
   if colorsdisabled then
      call setcmdline 'Locks Remove_1',1
    else
      call setcmdline 'Locks Remove_1 Colors',1
   row=3
   row1=width*3+1
   if rowx<row1 then
      rowx=row1
   top=0
   do i=da.0 to 1 by -1
      didone=0
      parse var da.i . dafsn
      if dafsn='' then iterate
      danosmf=da.dafsn.6
      if danosmf=1 then
         tag='Rqsts'
       else
         tag='I/O'
      if da.dafsn.0>0 then      /* check total remote i/o count */
         do
         row=row+1
         if row>=depth then leave
         if length(da.dafsn.0)>12 then
            ioc=da.dafsn.0
          else
            ioc=right(da.dafsn.0,12)
         call typeh 'remote' left(dafsn,44) da.dafsn.3 ioc tag,row,1
         call backh c_rem,row,1,scale(da.dafsn.0)
         didone=1
         if top=0 then
            top=i
         end
      if da.dafsn.2>0 then      /* check total zfs remote i/o count */
         do
         if length(da.dafsn.2)>12 then
            ioc=da.dafsn.2
          else
            ioc=right(da.dafsn.2,12)
         row=row+1
         if row>=depth then leave
         call typeh 'shared' left(dafsn,44) da.dafsn.3 ioc tag,row,1
         call backh c_remz,row,1,scale(da.dafsn.2)
         didone=1
         end
      /* if da.dafsn.0=0 & da.dafsn.2=0 then
         iterate  */        /* skip fs if there is no remote access */
      localio=max(0,da.dafsn.1-da.dafsn.0)
      if localio>0 then      /* check total local i/o count */
         do
         if length(localio)<=12 then
            localio=right(localio,12)
         row=row+1
         if row>=depth then leave
         call typeh 'local ' left(dafsn,44) da.dafsn.3 localio tag,row,1
         call backh c_loc,row,1,scale(localio)
         didone=1
         end
      if didone then
         do
         row=row+1
         end
   end
   address ispexec 'DISPLAY PANEL(DYN) CURSOR(DYN) CSRPOS('rowx')'
   if rc<>0 then
      running=0
    else
      do
      if qrowcol() then return
      rowx=csrrow*width-width+1
      ln=extrl(csrrow)
      parse var ln w1 w2 w3 w4 w5 .
      if w1='local' | w1='remote' | w1='shared' then
         call details w2
       else
         do
         call docmd
         if cmd='Remove_1' & top<>0 then
            da.top=''
         else
         if cmd='Locks' then
            call showcontention
         end
      end
   return

/**********************************************************************/
scale: procedure expose width
   arg n,f           /* the number to scale and floor */
   if f='' then f=10
   /* scale based on power of 2 */
   /* make n a bit string and find the order of the highest bit */
   v=length(strip(x2b(d2x(arg(1))),'L',0))
   if v<=f then
      if n>0 then
         return 1
      else
         return 0
   v=(v-f)*4        /* 4 ticks per power of 2 over floor */
   if v>width then
      return width
    else
      return v

/**********************************************************************/
showcontention:
  do while running
   call initdyn
   msg='File system contention data'
   call typeh msg,2,1
   call setcmdline 'Back Remove_1',6
   row=3
   row1=width*3+1
   if rowx<row1 then
      rowx=row1
   top=0
   do i=da.0 to 1 by -1
      didone=0
      parse var da.i . dafsn
      if dafsn='' then iterate
      if da.dafsn.5=0 then iterate  /* skip if no contention */
      row=row+1
      if row>=depth then leave
      if da.dafsn.4=0 & da.dafsn.5=0 then
         slowratio=0
       else
         slowratio=da.dafsn.5/(da.dafsn.4+da.dafsn.5)*100
   /* call typeh dafsn da.dafsn.4 da.dafsn.5,row,1 */
   /* call typeh dafsn 'Fast='da.dafsn.4 'Slow='da.dafsn.5,row,1 */
      call typeh left(dafsn,44),
         right(da.dafsn.4,10) 'Fast' right(da.dafsn.5,10) 'Slow',row,1
      call backh c_con,row,1,scale(da.dafsn.5)
      didone=1
      if top=0 then
         top=i
      if didone then
         do
         row=row+1
         end
   end
   address ispexec 'DISPLAY PANEL(DYN) CURSOR(DYN) CSRPOS(1)'
   if rc<>0 then
      return
    else
      do
      if qrowcol() then return
      rowx=csrrow*width-width+1
      ln=extrl(csrrow)
      parse var ln w1 w2 w3 .
      if substr(w2,1,5)='Fast=' then
         call contentionbytime w1
       else
         do
         call docmd
         if cmd='Remove_1' & top<>0 then
            da.top=''
         else
         if cmd='Back' then return
         end
      end
  end
   return

/**********************************************************************/
contentionbytime:     /* not currently supported */
return

   parse arg sbtfsn
   say 'by times' sbtfsn
   cmd=''
   intervalindex=''
   call initdyn
   call typeh 'Contention data for' sbtfsn,2,1
   call setcmdline 'Back',7
   call buildtimes
   /*
   do i=1 to datime.0
      rwbar=format(datime.i*sbtscale,,0)+1
      call backh c_tm,i+3,1,rwbar
      if datime.i.3>0 then
         do
         wbar=format(rwbar*(datime.i.3/datime.i),,0)
         call backh c_tmw,i+3,1,wbar
         end
      ts.=''
      address syscall 'gmtime' datime.i.1 'ts.'
      ts=right(ts.tm_hour,2,0)':'right(ts.tm_min,2,0)':' ||,
         right(ts.tm_sec,2,0)
      call typeh ts right(datime.i.3,10) right(datime.i.4,10),i+3,1
   end
   */
   address ispexec 'DISPLAY PANEL(DYN) CURSOR(DYN) CSRPOS(1)'
   if rc<>0 then
      do
      cmd='Back'
      return
      end
   if qrowcol() then return
   call docmd
   return

   if csrrow<3 then return
   ln=extrl(csrrow)
   if ln='' then return
   i=csrrow-3                  /* set index into datime. */
   intervalindex=datime.i.2    /* get index list into data. */
   cmd='User'
   return

/**********************************************************************
   da.n               n=1,2,... = fsn
   da.fsn             subscript to da.n
   da.fsn.sys.owner   sys=recording system owner=owning system = rwcount
   da.fsn.sys.owner.1 read count
   da.fsn.sys.owner.2 write count
   da.fsn.sys.1       local flag: 0(remote) 1(local) 2(zfs sysplex)
   da.fsn.local       rwcount
   da.fsn.3           pfs name
   da.fsn.4           fast obtains
   da.fsn.5           slow obtains
   da.fsn.6           nosmf
 **********************************************************************/
getcountsbyfs:
   da.=0
   j=0
   k=0
   largest=0
   largefast=0
   largeslow=0
   sysnames.=''
   do i=1 to data.0
      parse var data.i datime darcount dawcount dafast daslow,
                       dalocal dasys daowner dafsn dapfs danosmf .
      dacount=darcount+dawcount
      localtype=dalocal
  /*  if dalocal<>1 then
         dalocal=0  */
      da.dafsn.dalocal=da.dafsn.dalocal + dacount
      /*
      da.dafsn.dalocal.1.dasys=da.dafsn.dalocal.1.dasys + dacount
      da.dafsn.dalocal.2.daowner=da.dafsn.dalocal.2.daowner + dacount
      */
      da.dafsn.dasys.1=localtype
      da.dafsn.3=dapfs
      da.dafsn.4=da.dafsn.4 + dafast
      da.dafsn.5=da.dafsn.5 + daslow
      da.dafsn.6=danosmf    /* treat danosmf as uniform even if not */
      da.dafsn.dasys.daowner=da.dafsn.dasys.daowner + dacount
      da.dafsn.dalocal.dasys.daowner.1=,
      da.dafsn.dalocal.dasys.daowner.1 + darcount
      da.dafsn.dalocal.dasys.daowner.2=,
      da.dafsn.dalocal.dasys.daowner.2 + dawcount
      if da.dafsn.dalocal>largest then largest=da.dafsn.dalocal
      if da.dafsn.4>largefast then largefast=da.dafsn.4
      if da.dafsn.5>largeslow then largeslow=da.dafsn.5
      if da.dafsn=0 then
         do
         j=j+1
         da.j=dafsn
         da.dafsn=j
         end
      if sysnames.dasys='' then
         do
         k=k+1
         sysnames.k=dasys
         sysnames.dasys=1
         end
   end
   da.0=j
   sysnames.0=k
   do i=1 to da.0
      dafsn=da.i
      da.i=right(da.dafsn.0,20,0) dafsn
   end
   call sortstem 'da.'
   return

/**********************************************************************/
savedata:
   numsys=0
   do i=1 to 32
      if sysnames.i<>'' then
         numsys=numsys+1
   end
   if substr(output,1,1)='/' then
      do
      call sayc 'must specify a data set name'
      return
      end
   parse var output dsn '/' vol .
   if verbose then call sayc time() 'writing to' dsn
   alloc='alloc fi(fsmon) msg(wtp) reuse dsn('dsn')'
   newalloc='new catalog cyl dsorg(ps) lrecl(252) recfm(v,b)',
            'space('10*numsys',10)'
   if vol<>'' then
      alloc=alloc 'vol('vol')'
    else
      newalloc=newalloc 'unit(sysallda)'
   rv=bpxwdyn(alloc 'old ckexist')
   if rv<>0 then
      do
      call sayc 'allocating' dsn
      rv=bpxwdyn(alloc newalloc)
      end
   if rv<>0 then
      do
      call sayc 'allocation error' rv dsn vol
      return
      end
   push 'data' data.0 'proc' proc.0 'version' version '.'
   address mvs 'execio 1 diskw fsmon'
   address mvs 'execio * diskw fsmon (stem data.'
   address mvs 'execio * diskw fsmon (fini stem proc.'
   call bpxwdyn 'free fi(fsmon)'
   call sayc time() 'write complete to' dsn
   return

/**********************************************************************/
collectdata:
   if data.0<>'' then return
   call initialize
   call getsysnames
   dx=0
   px=0
   data.=''
   data.0=0
   proc.=''
   proc.0=0
   do i=1 to 32
      if sysnames.i<>'' then
         call loadstats sysnames.i
   end
   if data.0=0 then
      call sayc 'No data collected'
     else
      call sortstem 'data.'
   return

/**********************************************************************/
loadstats:
   arg sysname
   /* if verbose then */
      call sayc time() 'processing files for' sysname
   parse value monstatus(sysname'/'ctlfile) with pid iv hist .
   if pid='' then
      do
      call sayc 'monitor not active on' sysname
      return
      end
   sysixpath='/'sysname'/'indexfile
   sysixmonpath='/'sysname'/'fsmonpath

   index.0=0
   dir.0=0
   dev.=''
   address syscall 'readfile (sysixpath) index.'
   address syscall 'readdir (sysixmonpath) dir. st.'
   file=0
   do j=1 to dir.0
      if substr(dir.j,1,9)<>'interval.' then iterate
      file=file+1
      file.file=right(st.j.st_mtime,20,0) dir.j
   end
   file.0=file
   if index.0=0 | file.0=0 then
      do
      say 'monitor files not available on' sysname
      return
      end
   do j=1 to index.0        /* build fs index */
      parse var index.j ix devno nosmf .
      index.ix=j
      parse var ix ',' ',' fsn ','
      dev.devno=fsn
   end
   do file=1 to file.0      /* read and process each interval file */
      mon.0=0
      fn=sysixmonpath'/'word(file.file,2)
      address syscall 'readfile (fn) mon.'
      if verbose then call sayc time() 'file:' fn mon.0
      call processfile
   end
   if verbose then call sayc time() 'files processed for' sysname
   return

/**********************************************************************/
processfile:
   parse var mon.1 type itime inum .
   if type<>0 then return
   proci.=''
   el='.' /* append space . so windows copies can be handled (crlf) */
   do mon=2 to mon.0
      parse var mon.mon type rest
      if type=1 then
         do
         parse var rest fsix rdelta wdelta fast slow .
         parse var index.fsix mysys ',' owner ',',
                              fsname ',' pfsname ',' local devno nosmf .
         if mysys='*' then
            do
            mysys=sysname
            end
         dx=dx+1
         data.dx=itime right(rdelta,10,0) right(wdelta,10,0),
                 right(fast,10,0) right(slow,10,0) local,
                 left(mysys,8) left(owner,8) fsname pfsname nosmf el
         end
      if type=2 then
         do
         /* collect only 1 usage per fs in each interval file */
         parse var rest job logname ino .
         prix=fsname'.'job'.'logname
         if proci.prix<>'' then iterate
         proci.prix=1
         px=px+1
         proc.px=itime sysname fsname job logname el
         end
   end
   data.0=dx
   proc.0=px
   return

/**********************************************************************/
/* sortstem:
     function:  sorts stem variables using stem.0 as the number of items
                the variables are stem.1, stem.2,...
     argument:  stem
     returns:   0    success
                -1   no access to z/OS UNIX
                -2   some lines are longer than 1024 bytes
                1    error from sort
                2    error from sort
                num  unix error number trying to create a temp file
     example:
                sr=sortstem('inp.')
                if sr<>0 then
                do
                   say 'sort error' sr
                   return
                end
*/
sortstem:
   arg sortstemv
   sortsize=0
   if verbose then call sayc time() 'sort' value(sortstemv||0) 'lines'
   if value(sortstemv||0)<2 then return 0
   call cleardir sortpath
   address syscall 'mkdir (sortpath) 777'
   errors=errno errnojr
   address syscall 'stat (sortpath) st.'
   if retval=-1 then
      do
      say 'cannot establish' sortpath errors
      exit 1
      end
   sortstemrv=sortstemproc(sortstemv,sortpath)
   if verbose then call sayc time() 'end sort'
   if verbose then call sayc time() 'sort file size' sortsize
   return sortstemrv

sortstemproc: procedure expose (sortstemv) sortsize sortpath
   arg stem
   tmpnm=sortpath'/'userid()'.sort.'time()
   if syscalls('ON')>4 then
      return -1
   address syscall
   'writefile (tmpnm) 600' stem
   rv=rc
   err=errno
   if rv=4 | rv=8 then
      'unlink (tmpnm)'
   if rv=4 then return -2          /* line too long */
   if rv=8 then return err
   'stat (tmpnm) st.'
   sortsize=st.st_size
   rv=bpxwunix("sort '"tmpnm"'",,stem,'estem.')
   if rv<>0 then
      do
      call say 'sort failed with return code' rv
      do i=1 to estem.0
         call say estem.i
      end
      end
   'unlink (tmpnm)'
   return rv


/**********************************************************************/
/*
sortstem:
   arg sst,sscol
   ssm=value(sst||0)
   say 'sorting' ssm
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
*/

/**********************************************************************/
browsestem:
   address ispexec
   brc=value(arg(1)"0")
   if brc=0 then
      do
      say 'No entries to display'
      return
      end
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
   if arg(2)='' then
      'VIEW   DATAID('did') PROFILE(WJSC) MACRO(RESET)'
   else
      'VIEW   DATAID('did') PROFILE(WJSC)' arg(2)
   'LMFREE DATAID('did')'
   call bpxwdyn 'free dd('bpxpout')'
   return

/**********************************************************************/
editstem:
   parse arg editst,editmsg
   brc=value(editst"0")
   address tso
   call bpxwdyn "alloc rtddn(bpxpout) reuse new",
                "recfm(v,b) lrecl(500) blksize(5000) msg(wtp)"
   "execio" brc "diskw" bpxpout "(fini stem" editst
   address ispexec
   'LMINIT DATAID(DID) DDNAME('BPXPOUT')'
   if editmsg<>'' then
      say editmsg
   'EDIT   DATAID('did') MACRO(RESET)'
   'LMFREE DATAID('did')'
   address tso "execio * diskr" bpxpout "(fini stem" editst
   call bpxwdyn 'free dd('bpxpout')'
   return

/**********************************************************************/
initdyn:
   address ispexec
   "PQUERY PANEL(DYN) AREANAME(DYN) WIDTH(WIDTH) DEPTH(DEPTH)"
   dyn=copies(' ',width*depth)
   att=copies(c_bg,width*depth)
   "PQUERY PANEL(DYN) AREANAME(TITLE) WIDTH(TWIDTH)"
   title=center('File System Monitor Display',twidth)
   tatt=copies(c_bg,twidth)
   do i=1 to depth
      call backh c_bg,i,1,width
   end
   call backh c_hd,1,1,width
   call backh c_hd,2,1,width
   return

/**********************************************************************/
extrl: procedure expose dyn width depth
   parse arg row
   return substr(dyn,(row-1)*width+1,width)

typeh: procedure expose dyn width depth
   parse arg text,row,col
   dyn=overlay(text,dyn,(row-1)*width+col)
   return

backh: procedure expose att width depth
   parse arg color,row,fromx,tox
   if tox<fromx then return
   bar=(row-1)*width+fromx
   att=overlay(copies(color,tox-fromx+1),att,bar)
   return

typev: procedure expose dyn width depth
   parse arg text,row,col
   tpos=(row-1)*width+col
   do while text<>''
      dyn=overlay(substr(text,1,1),dyn,tpos)
      tpos=tpos+width
      text=substr(text,2)
   end
   return

backv: procedure expose att width depth
   parse arg color,fromy,toy,colx
   if toy<fromy then return
   bar=(fromy-1)*width+colx
   do i=fromy to toy
      att=overlay(color,att,bar)
      bar=bar+width
   end
   return

/**********************************************************************/
stopmonitor:
   call initialize
   call getsysnames
   ln.0=1
   ln.1=''
   do i=1 to 32
      if sysnames.i<>'' then
         do
         call sayc 'ending monitor on' sysnames.i
         address syscall 'writefile' '/'sysnames.i'/'ctlfile '644 ln.'
         end
   end
   address syscall 'sleep 4'
   call query
   /* remove monitor files */
   do i=1 to 32
      if sysnames.i='' then iterate
      if monstatus(sysnames.i'/'ctlfile)='' then
         call cleardir sysnames.i'/'fsmonpath
       else
         say 'monitor still running on' sysnames.i
   end
   return

/**********************************************************************/
startonall:
   call initialize
   call getsysnames
   parse source . . . . . . . rxenv .
   if rxenv<>'AXR' then
      do
      call sayc '-sa option only supported from SYSREXX'
      return
      end
   do sn=1 to 32
      if sysnames.sn<>'' then
         do
         sysnm=strip(sysnames.sn)
         call sayc 'Starting wjsfsmon on' sysnm
         m.0=0
         rv=axrcmd("ro" sysnm",f axr,wjsfsmon,t=0 -s -i" interval,
                   "-h" history,'M.',60)
         if rv<>0 then
            call sayc 'start wjsfsmon RC on' sysnm 'was' rv
         do i=1 to m.0
            call sayc m.i
         end
         end
   end
   call query
   return

/**********************************************************************/
startmonitor:
   call initialize
   if monstatus(ctlfile)<>'' then
      do
      call sayc 'monitor is already running'
      return
      end
   /* create and verify the monitor directory */
   call cleardir fsmonpath
   address syscall 'mkdir (fsmonpath) 755'
   errors=errno errnojr
   address syscall 'stat (fsmonpath) st.'
   if retval=-1 then
      do
      sayc 'cannot establish' fsmonpath errors
      exit 1
      end
   /* find the monitor source, load it into src. and write it out */
   do i=1 to sourceline()
      if sourceline(i)='//file wjsfsmon' then leave
   end
   j=0
   do i=i+1 to sourceline()
      if substr(sourceline(i),1,6)='//end ' then leave
      j=j+1
      src.j=strip(sourceline(i),'T')
   end
   src.0=j
   address syscall 'writefile (fsmon) 744 src.'
   if rc<>0 then
      do
      say 'Error creating monitor file.  RC='rc retval errno errnojr
      return
      end
   cmd=fsmon interval history
   cmd="nohup /bin/sh -c '"cmd
   cmd=cmd "</dev/null >"stdout "2>/dev/null"
   cmd=cmd "&'"
   rv=bpxwunix(cmd)
   do i=1 to 10
      address syscall 'access' ctlfile f_ok
      if retval<>-1 then leave
      address syscall 'sleep 2'
   end
   if i>9 then
      call query
    else
      call sayc 'monitor started'
   return

/**********************************************************************/
cleardir: procedure
   parse arg clearpath
   dir.0=0
   address syscall 'readdir (clearpath) dir.'
   do i=1 to dir.0
      address syscall 'unlink' clearpath'/'dir.i
   end
   address syscall 'rmdir (clearpath)'
   address syscall 'unlink (clearpath)'
   return

/**********************************************************************/
monstatus: procedure
   parse arg ctlfile
   ctlfile='/'ctlfile
   call syscalls 'ON'
   address syscall 'open (ctlfile)' o_rdonly
   if retval=-1 then return ''
   ctlfd=retval
   lk.l_len=1
   lk.l_start=0
   lk.l_type=f_rdlck
   lk.l_whence=seek_set
   address syscall 'f_getlk' ctlfd 'lk.'
   lk=retval
   buf=''
   address syscall 'read (ctlfd) buf 100'
   address syscall 'close' ctlfd
   if lk=-1 | lk.l_pid<1 then return ''
   parse var buf pid interval history .
   return pid interval history

/**********************************************************************/
initialize:
   if initialized then return
   initialized=1
   address syscall 'geteuid'
   if retval<>0 then
      address syscall 'seteuid 0'
   address syscall 'geteuid'
   myeuid=retval
   if myeuid<>0 then
      do
      call sayc 'You must run as UID=0 or be permitted to BPX.SUPERUSER'
      exit 8
      end
   opts=''
   fdsn='SYSZBPX2'
   pfs='KERNEL'
   pctcmd=-2147483647
   z4='00000000'x
   z1='00'x

   cvtecvt=140
   ecvtocvt=240
   ocvtocve=8
   cvt=getstor(10,4,1)
   ecvt=getstor(d2x(x2d(cvt)+cvtecvt),4,1)
   ocvt=getstor(d2x(x2d(ecvt)+ecvtocvt),4,1)
   kasid=x2d(getstor(d2x(x2d(ocvt)+x2d('18')),2,1))
   ocve=getstor(d2x(x2d(ocvt)+ocvtocve),4,kasid)
   fds=getstor(d2x(x2d(ocvt)+x2d('58')),4,1)

   asvt=getstor(d2x(x2d(cvt)+556),4,kasid)
   ascb=getstor(d2x(x2d(asvt)+528+kasid*4-4),4,kasid)
   assb=getstor(d2x(x2d(ascb)+x2d('150')),4,kasid)
   stok=getstor(d2x(x2d(assb)+48),8,kasid)

   return


/**********************************************************************/
getsysnames:
   if sysid<>'' then return
   call initialize
   sysnames.=''
   nxab=getstor(d2x(x2d(ocve)+x2d('84')),4,kasid)
   if nxab=0 then return
   nxmb=getstor(d2x(x2d(nxab)+x2d('14')),4,kasid)
   nxar=getstor(d2x(x2d(nxmb)+x2d('30')),4,kasid)
   sysid=x2d(getstor(d2x(x2d(nxmb)+x2d('c')),1,kasid))
   nxarl=32*x2d(getstor(d2x(x2d(nxmb)+x2d('18')),4,kasid))
   nxarray=getstor(nxar,nxarl,kasid)
   do i=0 by 32 to nxarl-1
      nxent=extr(nxarray,d2x(i),32)
      entid=x2d(extr(nxent,0,1))
      if entid=0 then iterate
      entname=x2c(extr(nxent,8,8))
      sysnames.entid=strip(entname)
   end
   return

/**********************************************************************/
pfsctl:
   if arg(1)=1 then
      pctcmd=x2d('40000005')
   else
   if arg(1)=2 then
      pctcmd=x2d('40000004')
   else
      do
      say 'missing pfsctl arg'
      trace ?i
      nop
      return
      end
   address syscall 'pfsctl ZFS' pctcmd 'pctbf' length(pctbf)
   if rc<0 | retval=-1 then
      do
      if errno<>arg(2) then
         do
         pcter=errno
         pctrs=errnojr
         err.=''
         address syscall 'strerror' pcter 0 'err.'
         say pcter pctrs err.1
         errno=pctrs
         errnojr=pctrs
         rc=0
         retval=-1
         call dump pctbf
         pull pcterr
         end
      return
      end
   return


/**********************************************************************/
brstem:
   arg stem
   parse source . . . . . . . isp .
   if isp<>'ISPF' then
      do
       do i=1 to value(stem'0')
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
/**********************************************************************/
getstor: procedure expose pfs pctcmd
   arg $adr,$len,$asid,$alet,$dspname
   $c1=x2d(substr($adr,1,1))
   if length($adr)>7 & $c1>7 then
      do
      $c1=$c1-8
      $adr=$c1 || substr($adr,2)
      end
   if $asid='' then
      do
      say 'missing asid'
      i=1/0 /* get traceback */
      end
   opts='asid('$asid')'
   if $dspname<>'' then
      opts=opts 'DSPNAME('$dspname')'
   call fetch $adr,$len,$alet,opts
   return cbx

/**********************************************************************/
extr:
   return substr(arg(1),x2d(arg(2))*2+1,arg(3)*2)

/**********************************************************************/
fetch:
   arg addr,cblen,alet,opts
   addr=fixaddr(addr)
   cbx=''
   len=d2c(right(cblen,8,0),4)
   addrc=d2c(x2d(addr),4)
   aletc=d2c(x2d(alet),4)
   cbs=aletc || addrc || len
   retval=-1
   address syscall 'pfsctl' pfs pctcmd 'cbs' max(cblen,12)
   if retval=-1 then
      do
      call say 'Error' errno errnojr 'getting storage at' arg(1),
               'for length' cblen
      exit
      end
   cbx=c2x(substr(cbs,1,cblen))
   return 0

/**********************************************************************/
fixaddr: procedure
   fa=right(arg(1),8,0)
   fa1=x2d(substr(fa,1,1))
   if fa1>7 then
      do
      fa1=fa1-8
      fa=fa1 || substr(fa,2)
      end
   return fa

/**********************************************************************/
xadd: procedure
   return d2x(x2d(arg(1))+x2d(arg(2)))

/**********************************************************************/
sayc:
   if rxenv='AXR' then
      call axrwto arg(1)
   else
      say arg(1)
   return

/**********************************************************************/
say:
   parse arg pl
   say pl
   return

/**********************************************************************/
/* formatted dump utility                                             */
/**********************************************************************/
dump:
   procedure expose
   parse arg dumpbuf
   sk=0
   prev=''
   do ofs=0 by 16 while length(dumpbuf)>0
      parse var dumpbuf 1 ln 17 dumpbuf
      out=c2x(substr(ln,1,4)) c2x(substr(ln,5,4)),
          c2x(substr(ln,9,4)) c2x(substr(ln,13,4)),
          "*"translate(ln,,xrange('00'x,'40'x))"*"
      if prev=out then
         sk=sk+1
       else
         do
         if sk>0 then call say '...'
         sk=0
         prev=out
         call say right(ofs,6)'('d2x(ofs,4)')' out
         end
   end
   return

/**********************************************************************/
/* panel build utility */
/**********************************************************************/
buildpan:
   needcleanup=1
   address tso
   if keep=1 then
      pandsn='da(wjsez.pan)'
    else
      pandsn=''
   if keep=1 then 'del wjsez.pan'
   call bpxwdyn 'alloc rtddn(wjsezpan) unit(sysallda) new reuse',
       'dir(5) space(1,1) msg(wtp)',
       'tracks dsorg(po) recfm(f,b) lrecl(80) blksize(3280)' pandsn
   address ispexec 'LMINIT DATAID(PANID) DDNAME('WJSEZPAN')'
   srcx=1
   do forever
      call getsrc '//pan'
      if src.0=0 then leave
      call mkmem srcmem
   end
   address ispexec 'LMFREE DATAID('PANID')'
   address ispexec 'LIBDEF ISPPLIB LIBRARY ID('WJSEZPAN') STACK'
   return

mkmem:
   address ispexec
   'LMOPEN DATAID('PANID') OPTION(OUTPUT)'
   do i=1 to src.0
      ln=left(src.i,80)
      'LMPUT DATAID('PANID') DATALOC(LN) MODE(INVAR) DATALEN(80)'
   end
   'LMMADD DATAID('PANID') MEMBER('translate(arg(1))')'
   'LMCLOSE DATAID('PANID')'
   return

getsrc:
   parse arg key
   k=0
   j=sourceline()
   src.0=0
   do i=srcx to j
      if word(sourceline(i),1)=key then leave
   end
   srcx=i
   if i>j then return
   srcmem=word(sourceline(i),2)
   if srcmem='' then return
   do i=i+1 to j
      k=k+1
      src.k=strip(sourceline(i),'T')
      if word(src.k,1)='//end' then leave
   end
   srcx=i
   src.0=k-1
   return

cleanup:
   if needcleanup<>1 then return
   address ispexec 'LIBDEF ISPPLIB'
   address tso
   call bpxwdyn 'free fi('wjsezpan')'
   if keep=1 then 'del wjsez.pan'
   needcleanup=0
   return
/*
//Help1
Activity by file system ordered by nonowner (remote) access

Move cursor to one of the file systems and press Enter to view the
breakdown of local access and type of remote access.  Only those file
systems that fit on the screen are shown.

Each line shows the amount of file system usage on a system over the
monitoring period.  Minimizing remote access is likely to improve
performance for applications using that file system from a nonowner
system.

Consider making file systems read-only where possible to eliminate
remote access, or move applications local to the file system.

Where this is not practical, enabling zFS sysplex for that file system
may improve performance for applications using that file system.

Select Remove_1 to move the display up by one file system.  This
removes the top file system from this and all other displays.  Up and
down scrolling is not available.
//end

//Help2
Help for the file system details display

This display breaks down read and write activity and shows the type of
access.  Access may be local access, remote access where the logical
file system is function shipping, or access through zFS sysplex support.

Remote access to a file system drives requests to the owner where local
access is performed.  Be careful interpreting local access since it
includes function shipped remote requests.

If much of the access is remote access, it may indicate the file system
or the workload should be moved so they are on the same system.  Where
this isn't practical, zFS sysplex support may be helpful.

Move the cursor to one of the horizontal bars and press Enter to show
activity by interval.  This could be helpful in finding the users or
workloads driving the usage.
//end

//Help3
Help for the interval display

This display shows file system activity by interval.  Each line is time
stamped with the start of the interval (GMT) and shows two data columns:
write requests and read requests if that information is available,
otherwise slow latch obtains and fast latch obtains.

The bars are color coded to show write requests or slow obtains vs
total activity.

Some information may be available about the users or processes using the
file system.  Use the User and Proc buttons to show this information.

This display can be useful in determining when workloads are using the
file system, and whether it is being used for write or only read access.

File systems that are only used for read or only written to for a
specific workload might be candidates to make read-only.

The interval display for local file system access will also include
I/O counts that were function shipped from other systems, showing the
total demand on that file system through the intervals.
//end

//Help4
Help for the user display

This display shows users that can be identified that are using the file
system along with a count of the number of times found with an active
connection to the file system.  Users can only be identified if they
have an active connection (eg, an open file) for a duration that spans
intervals.

Much use of files is very short duration and will therefore not be
identified on this display.  for usage that is identified, you may be
able to better assess whether the user and data are on the best systems
or if zFS sysplex support can help.
//end

//Help5
Help for the proc display

This display shows jobs that can be identified that are using the file
system along with a count of the number of times found with an active
connection to the file system.  Jobs can only be identified if they
have an active connection (eg, an open file) for a duration that spans
intervals.

Much use of files is very short duration and will therefore not be
identified on this display.  for usage that is identified, you may be
able to better assess whether the jobs and data are on the best systems
or if zFS sysplex support can help.
//end

//Help6
Help for file system contention data

This display shows the amount of contention on file systems.  The file
systems are ordered based on amount of remote activity similar to the
file system activity display.

Contention is indicated by the count of slow latch obtains (Slow=).
Non-contention is indicated by the number or fast latch obtains (Fast=).

Most application use of the file system does not contend.  File system
management activities may cause contention.  This includes activities
such as moving file systems, file system backups, recovering for a
system that was taken down and periodic resource recovery processing.

Short bursts of application access to a lot of files may cause some
contention when those resources are released.  If you are not performing
file system management activities, this is the most likely source of
contention.  zFS sysplex support may help if you are seeing this type
of contention.

File system management activities may contend more with application
usage when the file system is a client remotely accessing the owner.

Select Remove_1 to scroll the display up by one file system.  This
removes the top file system from this and all other displays.
//end

//Help7
Help for file system contention by time

reserved, not currently supported

//end

//HelpC
Help for setting colors

Colors for most areas in this tool can be individually configured.
This color dialog lists the configurable area names shown in the color
selected.

To change a color for an area, move the cursor to the line for that area
and the color desired and press Enter.  One of the command buttons is
Defaults.  Click this button to restore colors to their defaults.

Color support is only available on 3270 devices supporting 7 colors.

The configurable areas are:
background     background color for most of the screen
buttons        color for command buttons
remote         bar showing all remote file system access
remote zfs     bar showing remote file system access by zFS
local          bar showing local file system access
time-total     bar showing total read and write counts
time-write     bar showing only write counts
contention     bar showing file systems operations under contention
no conten.     bar showing file system operations not under contention
//end

//HelpG
General help for WJSFSMON

This dialog is intended to help you better understand file system access
patterns to assist you in placement of file systems and applications to
improve performance.

Help screens are closed by pressing Enter or F3 (END) and scrolled with
F7 (UP) and F8 (DOWN).

Navigation is through cursor select.  F3 (END) usually works as Back.

The top line on most screens is a set of command buttons.  To select a
command, move your cursor to the command button and press Enter.

Some screens let you expand detail for displayed items.  Move the cursor
to one of the items and press Enter.

Each screen has its own help information selectable from a command
button.  Each screen also has an Exit button.  Select this to exit the
dialog immediately.
//end

//pan dynscr
)ATTR
 ? TYPE(INPUT) INTENS(HIGH) CAPS(OFF)
 @  AREA(DYNAMIC) EXTEND(ON) SCROLL(ON)
 ~  AREA(DYNAMIC)
 01 TYPE(CHAR)    COLOR(WHITE)
 02 TYPE(CHAR)    COLOR(RED)
 03 TYPE(CHAR)    COLOR(BLUE)
 04 TYPE(CHAR)    COLOR(GREEN)
 05 TYPE(CHAR)    COLOR(PINK)
 06 TYPE(CHAR)    COLOR(YELLOW)
 07 TYPE(CHAR)    COLOR(TURQ)
 11 TYPE(CHAR)    COLOR(WHITE)  HILITE(REVERSE)
 12 TYPE(CHAR)    COLOR(RED)    HILITE(REVERSE)
 13 TYPE(CHAR)    COLOR(BLUE)   HILITE(REVERSE)
 14 TYPE(CHAR)    COLOR(GREEN)  HILITE(REVERSE)
 15 TYPE(CHAR)    COLOR(PINK)   HILITE(REVERSE)
 16 TYPE(CHAR)    COLOR(YELLOW) HILITE(REVERSE)
 17 TYPE(CHAR)    COLOR(TURQ)   HILITE(REVERSE)
)BODY CMD()     EXPAND(//) width(&zscreenw)
~TITLE,TATT  / /   ~?z   %
@DYN,ATT  / /         @
)INIT
.zvars = '(dummy)'
&dummy = ' '
)PROC
&csrfld=.cursor
&csrpos=.csrpos
)END
//end

//pan dyn
)ATTR
 ? TYPE(INPUT) INTENS(HIGH) CAPS(OFF)
 @  AREA(DYNAMIC) EXTEND(ON)
 ~  AREA(DYNAMIC)
 01 TYPE(CHAR)    COLOR(WHITE)
 02 TYPE(CHAR)    COLOR(RED)
 03 TYPE(CHAR)    COLOR(BLUE)
 04 TYPE(CHAR)    COLOR(GREEN)
 05 TYPE(CHAR)    COLOR(PINK)
 06 TYPE(CHAR)    COLOR(YELLOW)
 07 TYPE(CHAR)    COLOR(TURQ)
 11 TYPE(CHAR)    COLOR(WHITE)  HILITE(REVERSE)
 12 TYPE(CHAR)    COLOR(RED)    HILITE(REVERSE)
 13 TYPE(CHAR)    COLOR(BLUE)   HILITE(REVERSE)
 14 TYPE(CHAR)    COLOR(GREEN)  HILITE(REVERSE)
 15 TYPE(CHAR)    COLOR(PINK)   HILITE(REVERSE)
 16 TYPE(CHAR)    COLOR(YELLOW) HILITE(REVERSE)
 17 TYPE(CHAR)    COLOR(TURQ)   HILITE(REVERSE)
)BODY CMD()     EXPAND(//) width(&zscreenw)
~TITLE,TATT  / /   ~?z   %
@DYN,ATT  / /         @
)INIT
.zvars = '(dummy)'
&dummy = ' '
)PROC
&csrfld=.cursor
&csrpos=.csrpos
)END
//end

%COMMAND ===>?ZCMD  / /  +
SCROLL===>_SCRL+
?z%                   ~File System Monitor Display%
 ~ type(text) caps(off) intens(low)

)ATTR
   % TYPE(TEXT)   INTENS(HIGH)
   + TYPE(TEXT)   INTENS(LOW)
   $ TYPE(TEXT)   INTENS(LOW)                 COLOR(turquoise)
   _ TYPE(INPUT)  INTENS(HIGH) padc('_')      CAPS(OFF)  JUST(LEFT)
   # TYPE(INPUT)  INTENS(HIGH) padc('_')      CAPS(ON)   JUST(LEFT)
   ? TYPE(output) INTENS(low)  caps(off)      COLOR(turquoise)

//pan blank
)BODY
%
%Command ===>_ZCMD                                                %Scroll:_amt +
%
)INIT
  &ZCMD = ' '
)PROC
)END
//end
************************************************************************
*/
//file wjsfsmon
/* REXX */
/**********************************************************************/
/* wjsfsmon: this part gets copied to the fsmon directory and spawned */
/*           to perform the monitoring function                       */
/**********************************************************************/
parse arg interval history .
numeric digits 20
if interval='' then interval=20
if history='' then history=180
setstats=x2d('80000019',8)
statsoff='00000001'x
statson='00000002'x
address syscall 'pfsctl KERNEL' setstats 'statson' 4
if retval=-1 then
   do
   say 'Using latch counts if I/O counts not available'
   statsset=0
   end
 else
   statsset=1
signal on novalue
signal on halt
fsmonpath='/var/fsmon'
indexfile=fsmonpath'/index'
ctlfile=fsmonpath'/control'
tempfile=fsmonpath'/temp'
stdout=fsmonpath'/stdout'
fsmon=fsmonpath'/fsmon'
intervalpref=fsmonpath'/interval.'
sysid=''
call initialize
call monitor
address syscall 'pfsctl KERNEL' setstats 'statsoff' 4
exit 0

novalue:
  say 'uninitialized variable in line' sigl
  say sourceline(sigl)
halt:
  address syscall 'pfsctl KERNEL' setstats 'statsoff' 4
  exit 0

/**********************************************************************/
initialize:
   address syscall 'geteuid'
   myeuid=retval
   if myeuid<>0 then
      do
      say 'You must run as UID=0'
      exit 8
      end
   z1='00'x

   cvtecvt=140
   ecvtocvt=240
   ocvtocve=8
   cvt=getstor(10,4)
   ecvt=getstor(d2x(x2d(cvt)+cvtecvt),4)
   ocvt=getstor(d2x(x2d(ecvt)+ecvtocvt),4)
   ocve=getstor(d2x(x2d(ocvt)+ocvtocve),4)
   fds=getstor(d2x(x2d(ocvt)+x2d('58')),4)
   call findlset 'SYS.BPX.A000.FSLIT.FILESYS.LSN '
   return

/**********************************************************************/
/* sets latchset addr and latch entry length:  lset@ and lsetlen */
findlset:
   arg setname
   lset@=getstor(d2x(x2d(ocve)+64),4)
   do while lset@<>0
      lset=getstor(lset@,128)
      name=x2c(extr(lset,'30',48))
      lsetver=x2d(extr(lset,'70',2))
      if lsetver=0 then
         lsetlen=128
       else
         lsetlen=256
      if name=setname then leave
      lset@=extr(lset,'0c',4)
   end
   if lset@=0 then
      do
      say 'error locating latchset' setname
      end
   return

/**********************************************************************/
/**********************************************************************/
monitor:
   address syscall 'getpid'
   pid=retval
   line=pid interval history '15'x
   address syscall 'creat (ctlfile) 644'
   if retval=-1 then
      do
      say 'cannot create' ctlfile 'error='errno errnojr
      exit 1
      end
   ctlfd=retval
   lk.l_len=1
   lk.l_start=0
   lk.l_type=f_wrlck
   lk.l_whence=seek_set
   address syscall 'f_setlk' ctlfd 'lk.'
   if retval=-1 then
      do
      say 'file' ctlfile 'is locked'
      exit 1
      end
   address syscall 'write (ctlfd) line'
   address syscall 'fstat (ctlfd) st.'
   if st.st_size<>length(line) then
      do
      say 'unable to initialize' ctlfile
      exit 1
      end
   ctlsize=st.st_size
   fs.=''
   dev.=''
   fs.0=0
   fs.0.0=0    /* init client fs count */
   fs.1.0=0    /* init local fs count */
   do intervalnum=1 by 1
      address syscall 'time'
      itime=retval
      call getsysnames
      call getaggrs
      call getcounts
      call calcdeltas
      call getprocesses
      call writelog
      call time 'R'
      do forever
         drop st.
         address syscall 'fstat (ctlfd) st.' /* check for size change */
         if st.st_size<>ctlsize then leave   /* that is signal to end */
         if time('E')>interval then leave
         address syscall 'sleep' 2
      end
      if st.st_size<>ctlsize then leave
   end
   return

/**********************************************************************/
saycons: procedure
   parse arg msg
   msg.1='wjsfsmon:' msg
   msg.0=1
   say msg
   address syscall 'writefile /dev/console 666 msg.'
   return

/**********************************************************************/
getsysnames:
   sysnames.=''
   nxab=getstor(d2x(x2d(ocve)+x2d('84')),4)
   if nxab=0 then return
   nxmb=getstor(d2x(x2d(nxab)+x2d('14')),4)
   nxar=getstor(d2x(x2d(nxmb)+x2d('30')),4)
   sysid=x2d(getstor(d2x(x2d(nxmb)+x2d('c')),1))
   nxarl=32*x2d(getstor(d2x(x2d(nxmb)+x2d('18')),4))
   nxarray=getstor(nxar,nxarl)
   do i=0 by 32 to nxarl-1
      nxent=extr(nxarray,d2x(i),32)
      entid=x2d(extr(nxent,0,1))
      if entid=0 then iterate
      entname=x2c(extr(nxent,8,8))
      sysnames.entid=strip(entname)
   end
   return

/**********************************************************************/
/* on return agid. is indexed by filesys name, value is owner sysname */
/**********************************************************************/
getaggrs: procedure expose agid. e2big
   z1='00'x
   z4='00000000'x
   pl=32
   agidsz=84
   agid.=''
   /* query buffer size */
   pctbf=d2c(140,4) ||,                     /* list op       */
         z4                     ||,         /* p0: bufsz     */
         z4          ||,                    /* p1: buf offs  */
         d2c(pl,4)                ||,       /* p2: sz offs   */
         z4||z4||z4||z4||,                  /* p3-p6     */
         z4                                 /* returned size */
   call pfsctl 1,e2big
   aglistsz=c2d(substr(pctbf,pl+1,4))
   if aglistsz=0 then
      do
      agid.0=0
      return
      end
   /* get aggr list */
   aglist=copies(z1,aglistsz)
   pctbf=d2c(140,4) ||,                     /* list op       */
         d2c(aglistsz,4)  ||,               /* p0: bufsz     */
         d2c(pl,4)   ||,                    /* p1: buf offs  */
         d2c(pl+aglistsz,4) ||,             /* p2: sz offs   */
         z4||z4||z4||z4||,                  /* p3-p6     */
         aglist || z4
   call pfsctl 1
   /* process aggr list */
   do i=pl+1 by agidsz
      agid=substr(pctbf,i,agidsz)
      if substr(agid,1,4)<>'AGID' then leave
      parse var agid 7 agnm '00'x 52 agsys '00'x
      agid.agnm=agsys
   end
   return

/**********************************************************************/
pfsctl:
   if arg(1)=1 then
      pctcmd=x2d('40000005')
   else
   if arg(1)=2 then
      pctcmd=x2d('40000004')
   else
      do
      say 'missing pfsctl arg'
      trace ?i
      nop
      return
      end
   address syscall 'pfsctl ZFS' pctcmd 'pctbf' length(pctbf)
   if rc<0 | retval=-1 then
      do
      if errno<>arg(2) then
         do
         pcter=errno
         pctrs=errnojr
         err.=''
         address syscall 'strerror' pcter 0 'err.'
         say pcter pctrs err.1
         errno=pctrs
         errnojr=pctrs
         rc=0
         retval=-1
         call dump pctbf
         pull pcterr
         end
      return
      end
   return

/**********************************************************************/
getcounts:
   gotone=0
   gotone.=0
   /*
   on return gotone. is populated:
      gotone.0       number of file systems
      gotone.n       fsname
      gotone.n.1     owner
      gotone.n.2     pfsname
      gotone.n.3     fspath
      gotone.n.4     local
      gotone.n.5     devno
      gotone.n.6     reads
      gotone.n.7     writes
      gotone.n.8     fast obtains
      gotone.n.9     slow obtains
      gotone.fsname  r/w counts
   */
   threshold=10000
   gfs@=getstor('1008',4,fds)
   gfsvfs='0c'
   vfsnm='38'
   vfscnt=0
   numeric digits 20
   do while gfs@<>0
      gfs=getstor(gfs@,48,fds)
      gfs@=extr(gfs,'08',4)
      vfs@=extr(gfs,gfsvfs,4)
      gfsname=strip(x2c(extr(gfs,'18',8)))
      call runvfses
   end
   gotone.0=gotone

   return

/**********************************************************************/
runvfses:
   do while vfs@<>0
      vfscnt=vfscnt+1
      vfs=getstor(vfs@,500,fds)
      vfs@=extr(vfs,'08',4)
      fsname=strip(x2c(extr(vfs,'38',44)))
      fsowner=x2d(extr(vfs,'194',1))
      owner=sysnames.fsowner
      rdwr = bitand(x2c(extr(vfs,'34',1)),'40'x)<>z1
      flags=x2c(extr(vfs,'35',1))
      if bitand(flags,'c0'x)<>z1 then
         iterate           /* skip dead and available */
      flags=x2c(extr(vfs,'36',1))
      if bitand(flags,'40'x)<>z1 then
         iterate           /* skip permanent */
      flags=x2c(extr(vfs,'37',1))
      local = bitand(flags,'02'x)=z1
      /* for locally mounted rdwr zfs, if the zfs owner is not this
         system, treat as not local with owner as the zfs owner   */
      if local=1 & rdwr & gfsname='ZFS' then
         if agid.fsname<>sysnames.sysid then
            do
            local=2   /* local type 2 for zfs function ship */
            owner=agid.fsname
            end
      fspath=x2c(extr(vfs,'a0',16))
      devno=x2d(extr(vfs,'6c',4))
      reads=x2d(extr(vfs,'10c',4))
      writes=x2d(extr(vfs,'110',4))
      lflag1=x2c(extr(vfs,'148',1))
      if statsset then
         nosmf=0
       else
         nosmf=bitand(lflag1,'02'x)<>z1
      flcb@=extr(vfs,'1c',4)
      flcb=getstor(flcb@,8,fds)
      latnum=x2d(extr(flcb,'04',4))
      latch=findlatch(latnum)
      if length(latch)>0 then
         do
         fast=x2d(extr(latch,'10',4))
         slow=x2d(extr(latch,'14',4))
         end
       else
         do
         fast=0
         slow=0
         end
      gotone=gotone+1
      gotone.gotone=fsname
      gotone.fsname=reads+writes
      gotone.gotone.1=owner
      gotone.gotone.2=gfsname
      gotone.gotone.3=fspath
      gotone.gotone.4=local
      gotone.gotone.5=devno
      gotone.gotone.6=reads
      gotone.gotone.7=writes
      gotone.gotone.8=fast
      gotone.gotone.9=slow
      gotone.gotone.10=nosmf
   end
   return

/**********************************************************************/
findlatch:
   arg latchnum
   if lset@=0 then return ''
   latlen=32
   lat@=d2x(x2d(lset@)+lsetlen+latlen*latchnum)
   latch=getstor(lat@,latlen)
   return latch

/**********************************************************************/
/*
    fs.ix.1   owner
         .2   sum of read and write counts or v for first time
         .3   total reads+writes
         .4   devno
         .5   fast obtain count from lqe
         .6   slow obtain count from lqe
         .7   fast obtain count for interval
         .8   slow obtain count for interval
         .9   read count from vfs
         .10  write count from vfs
         .11  read count for interval
         .12  write count for interval
*/
calcdeltas:
   fscount=fs.0
   do i=1 to gotone.0
      fsname= gotone.i
      owner=  gotone.i.1
      pfsname=gotone.i.2
      fspath= gotone.i.3
      local=  gotone.i.4
      devno=  gotone.i.5
      rcount= gotone.i.6
      wcount= gotone.i.7
      fast=   gotone.i.8
      slow=   gotone.i.9
      nosmf=  gotone.i.10
      counts= gotone.fsname
      if nosmf then                 /* if no fs counts */
         do
         wcount=slow                /* use latch counts */
         rcount=fast
         end
      if local=1 then
         index='*,'owner','fsname','pfsname','local
       else
         index=sysnames.sysid','owner','fsname','pfsname','local
      ix=fs.index             /* get index for existing entry */
      if fs.index='' then     /* first time for this fs on this owner */
         do
         ix=fs.0              /* add new fs to the list       */
         ix=ix+1
         fs.0=ix
         fs.ix=index devno nosmf
         fs.index=ix          /* save array index             */
         fs.ix.1=intervalnum  /* save interval number         */
         fs.ix.2='v'          /* init del as counts now valid */
         fs.ix.3=counts       /* save r/w counts              */
         fs.ix.4=devno        /* save devno                   */
         fs.ix.5=fast         /* save fast obtain count       */
         fs.ix.6=slow         /* save slow obtain count       */
         fs.ix.9=rcount       /* save read count              */
         fs.ix.10=wcount      /* save write count             */
         dev.devno=ix         /* index devno to this entry    */
         end
      else
      if fs.ix.2='i' then     /* counts not valid last interval */
         do
         fs.ix.2='v'          /* mark counts now valid        */
         fs.ix.1=intervalnum  /* save interval number         */
         fs.ix.3=counts       /* save r/w counts              */
         fs.ix.4=devno        /* keep devno in case it changed*/
         fs.ix.5=fast         /* save fast obtain count       */
         fs.ix.6=slow         /* save slow obtain count       */
         fs.ix.9=rcount       /* save read count              */
         fs.ix.10=wcount      /* save write count             */
         end
      else
      if datatype(fs.ix.2,'W') |,    /* counts valid       */
         fs.ix.2='v' then
         do
         fs.ix.1=intervalnum  /* save interval number         */
         if fs.ix.4<>devno then /* devno changed, skip interval */
            do
            fs.ix.4=devno       /* save new devno             */
            fs.ix.2='v'         /* mark counts valid          */
            end
          else
            do
            fs.ix.2=counts-fs.ix.3   /* calc delta            */
            fs.ix.7=fast-fs.ix.5
            fs.ix.8=slow-fs.ix.6
            fs.ix.11=rcount-fs.ix.9
            fs.ix.12=wcount-fs.ix.10
            end
         fs.ix.3=counts       /* save r/w counts              */
         fs.ix.5=fast         /* save fast obtain count       */
         fs.ix.6=slow         /* save slow obtain count       */
         fs.ix.9=rcount       /* save read count              */
         fs.ix.10=wcount      /* save write count             */
         end
   end
   /* mark any fs not found as invalid for the interval */
   do j=1 to fs.0
      if fs.j.1<>intervalnum then
         fs.j.2='i'        /* not in interval, counts invalid */
   end
   return

/**********************************************************************/
getprocesses:
   /* get basic process info for all processes */
   call rexxopt 'varpref','pid_'
   call procinfo
   call rexxopt 'varpref','file_'
   /* for each pid get file info  */
   do i=1 to pid_pid.0
      if procinfo(pid_pid.i,'file')='' then iterate
      do j=1 to file_nodes
         if file_typecd.j<>'fd' & file_typecd.j<>'vd' then iterate
         /* list process info under filesys record */
         ix=file_devno.j
         ix=dev.ix
         k=fs.ix.5.0
         if k='' then k=0
         k=k+1
         fs.ix.5.0=k
         fs.ix.5.k=pid_jobname.i pid_logname.i file_inode.j
      end
   end
   return

/**********************************************************************/
writelog:
   if fscount<>fs.0 then
      do
      address syscall 'writefile (tempfile) 644 fs.'
      if retval<>-1 then
         address syscall 'rename (tempfile) (indexfile)'
      if retval=-1 then
         do
         say 'error writing index file' errno errnojr indexfile
         exit 1
         end
      end
   j=1
   out.j=0 itime intervalnum  /* header record for interval file */
   do ix=1 to fs.0
      if datatype(fs.ix.2,'W')=0 then iterate
      j=j+1
      /* write record type 1:
         index reads writes fast slow */
      out.j=1 ix fs.ix.11 fs.ix.12 fs.ix.7 fs.ix.8
      if fs.ix.5.0<>'' then
      do p=1 to fs.ix.5.0
         j=j+1
         out.j=2 fs.ix.5.p  /* rec type 2, process info */
      end
      fs.ix.5.0=0
   end
   out.0=j
   file=intervalpref || intervalnum//history
   address syscall 'writefile (tempfile) 644 out.'
   if retval<>-1 then
      address syscall 'rename (tempfile) (file)'
   if retval=-1 then
      do
      say 'error writing interval record' errno errnojr file
      exit 1
      end
   return

/**********************************************************************/
/**********************************************************************/
getstor: procedure expose pfs
   arg $adr,$len,$alet
   $c1=x2d(substr($adr,1,1))
   if length($adr)>7 & $c1>7 then
      do
      $c1=$c1-8
      $adr=$c1 || substr($adr,2)
      end
   call fetch $adr,$len,$alet
   return cbx

/**********************************************************************/
extr:
   return substr(arg(1),x2d(arg(2))*2+1,arg(3)*2)

/**********************************************************************/
fetch:
   arg addr,cblen,alet
   addr=fixaddr(addr)
   cbx=''
   len=d2c(right(cblen,8,0),4)
   addrc=d2c(x2d(addr),4)
   aletc=d2c(x2d(alet),4)
   cbs=aletc || addrc || len
   retval=-1
   address syscall 'pfsctl KERNEL -2147483647 cbs' max(cblen,12)
   if retval=-1 then
      do
      say 'Error' errno errnojr 'getting storage at' arg(1),
               'for length' cblen
      exit
      end
   cbx=c2x(substr(cbs,1,cblen))
   return 0

/**********************************************************************/
fixaddr: procedure
   fa=right(arg(1),8,0)
   fa1=x2d(substr(fa,1,1))
   if fa1>7 then
      do
      fa1=fa1-8
      fa=fa1 || substr(fa,2)
      end
   return fa

/**********************************************************************/
/* formatted dump utility                                             */
/**********************************************************************/
dump:
   procedure expose
   parse arg dumpbuf
   sk=0
   prev=''
   do ofs=0 by 16 while length(dumpbuf)>0
      parse var dumpbuf 1 ln 17 dumpbuf
      out=c2x(substr(ln,1,4)) c2x(substr(ln,5,4)),
          c2x(substr(ln,9,4)) c2x(substr(ln,13,4)),
          "*"translate(ln,,xrange('00'x,'40'x))"*"
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

//end
