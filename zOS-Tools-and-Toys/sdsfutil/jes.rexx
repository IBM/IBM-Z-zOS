/* rexx */
/**********************************************************************/
/* jes: view and purge jobs                                           */
/*                                                                    */
/* PROPERTY OF IBM                                                    */
/* COPYRIGHT IBM CORP. 2018                                           */
/*                                                                    */
/* Syntax:  jes                                                       */
/*                                                                    */
/*   subcommands:                                                     */
/*      H                 help (see help for full subcommand info)    */
/*      Q                 exit current display                        */
/*      Enter             refresh page                                */
/*      U/D|space/L/R/T/B scrolling (can prefix with number: 100d)    */
/*      /                 find ex: /addr1                             */
/*      -/                find prev                                   */
/*      =                 repeat find                                 */
/*      set <option value>...  set options                            */
/*          options:    prefix <prefix>   default *                   */
/*                      owner <owner>     default your userid         */
/*           ex:  set prefix #* owner wjs                             */
/*                                                                    */
/* Notes:                                                             */
/*  - use this only from a telnet or rlogin session                   */
/*  - install in a directory where you can execute programs           */
/*  - set permissions to 755                                          */
/*  - you must have access to the SDSF REXX API                       */
/*                                                                    */
/* Bill Schoen  3/18/2018   wjs@us.ibm.com                            */
/*                                                                    */
/**********************************************************************/
address syscall 'isatty 0'
r1=retval
address syscall 'isatty 1'
r2=retval
address syscall 'pt3270 0 1'
r3=retval
address syscall 'pt3270 1 1'
r4=retval
if r1<>1 | r2<>1 | r3>0 | r4>0 then
   do
   say 'stdin and stdout must be pttys not under OMVS'
   exit 4
   end
call setesc
pg=24
cols=80
pgoffset=4
pg=pg-pgoffset
cols=cols-1
lmargin=1
isfprefix='*'
isfowner=userid()
emsg=''

do forever
   line.=''
   call getjobs
   ln=1
   lastf=''
   s=pager(1,'Select job by number')
   emsg=''
   parse var s s cmd
   if s='Q' then leave
   if verify(s,'0123456789')>0 then iterate
   if length(s)>8 then iterate
   if s>line.0 | s<1 then iterate
   if cmd='' then
      do
      call getjob s
      call pager
      end
   else
   if cmd='P' then
      call purgejob s
   else
      emsg='Invalid selection command'
   if line.0=0 then iterate
end
return 0

/************************************************************/
getjobs:
   call isfcalls 'ON'
   address sdsf
   width=1
   line.0=0
   jname.=''
   'ISFEXEC ST'
   if rc<>0 then
      do
      say 'SDSF error.  RC='rc
      exit
      end
   do i=1 to jname.0
      line.i= l(jname.i) l(jobid.i) l(ownerid.i) l(retcode.i) l(queue.i) phasename.i
      line.0=i
      width=length(line.1)
   end
   return

l: return left(arg(1),10)

/************************************************************/
purgejob:
   parse arg s
   address sdsf
   isfmsg=''
   "ISFACT ST TOKEN('"token.s"') PARM(NP P)"
   rv=rc
   emsg=''
   if rv<>0 then
      emsg='RC='rv' '
   if isfmsg<>'' then
      emsg=emsg||isfmsg
   return

/************************************************************/
getjob:
   parse arg s
   width=1
   address sdsf
   "ISFACT ST TOKEN('"token.s"') PARM(NP SA)"
   rv=rc
   out.0=0
   line.0=0
   k=0
   do i=1 to isfddname.0
      address mvs 'execio * diskr' isfddname.i '(fini stem st.'
      do j=1 to st.0
         k=k+1
         line.k=translate(strip(st.j,'T'),'',xrange('00'x,'3f'x))
         line.0=k
         if length(line.k)>width then
            width=length(line.k)
      end
   end
   return

/************************************************************/
/************************************************************/
pager:
   parse arg sel,msg
   top=1
   rtn='Q'
   signal on novalue
   signal on syntax
   signal on halt
   call setraw
   checkscreen=1
   do forever
      sz.=''
      if checkscreen then
         do
         checkscreen=0
         call bpxwunix 'stty',,'sz.'
         parse var sz.2 'rows =' newpg ', columns =' newcols ';'
         if newpg<>'' & newcols<>'' then
            do
            pg=newpg-pgoffset
            cols=newcols-1
            end
         end

      if top<1 then top=1
      if top>line.0 then top=line.0
      if lmargin<1 then lmargin=1
      if lmargin>=width then lmargin=width-1
      ln=top
      prefl=length(line.0)
      llen=cols-prefl-1
      if lmargin<1 then lmargin=1
      if llen<1 then llen=1
      if prefl<1 then prefl=1
      if msg<>'' then emsg=msg '  ' emsg

      /* header lines */
      h1=line.0'/'lmargin':'min(width,lmargin+llen-1),
            'help:H quit:Q up:U/T down:Space/B left:L right:R find:/,-/ rfind:='
      buf=ff||nvid||ff||bluefg||substr(h1,1,cols)||nvid||nl || redfg || emsg || nvid nl

      /* body text */
      do i=1 to pg while ln<=line.0
         buf=buf||right(ln,prefl) substr(line.ln,lmargin,llen)||nl
         ln=ln+1
      end
      call charout ,buf

      emsg=''
      cmdasis=getline('123456789-/sS')
      cmd=translate(cmdasis)

      if cmd='Q' | cmdasis=k.$f3 | cmdasis=k.?f3 then
         leave

      if cmd='H' | cmdasis=k.$f1 | cmdasis=k.?f1 then
         do
         call help
         iterate
         end

      if cmd==' ' | cmd='D' | cmdasis=k.$pgdn | cmdasis=k.$f8 then
         do
         if num='' then
            top=top+format(pg/2,,0)
          else
            top=top+num
         iterate
         end

      if cmd='U' | cmdasis=k.$pgup | cmdasis=k.$f7 then
         do
         if num<>'' then
            top=top-num
          else
            top=top-format(pg/2,,0)
         iterate
         end

      if cmdasis=k.$up then
         do
         top=top-1
         iterate
         end

      if cmdasis=k.$dn then
         do
         top=top+1
         iterate
         end

      if cmdasis=k.$rt then
         do
         if num='' then
            lmargin=lmargin+1
           else
            lmargin=lmargin+num
         iterate
         end

      if cmdasis=k.$lft then
         do
         if num='' then
            lmargin=lmargin-1
           else
            lmargin=lmargin-num
         iterate
         end

      if substr(cmd,1,1)='T' then
         do
         top=1
         iterate
         end

      if substr(cmd,1,1)='B' then
         do
         top=line.0-pg+1
         iterate
         end

      if substr(cmd,1,1)='L' | cmdasis=k.$f10 then
         do
         if num<>'' then
            lmargin=lmargin-num
          else
            lmargin=lmargin-format(cols/2,,0)
         iterate
         end

      if substr(cmd,1,1)='R' | cmdasis=k.$f11 then
         do
         if num<>'' then
            lmargin=lmargin+num
          else
            lmargin=lmargin+format(cols/2,,0)
         iterate
         end


      if cmd='=' | cmdasis=k.$f5 then
         do
         top=find(lastdir,lastf)
         iterate
         end

      if substr(cmd,1,1)='/' then
         do
         cmd=substr(cmd,2)
         if cmd='' then cmd=lastf
         top=find('+',cmd)
         iterate
         end

      if substr(cmd,1,2)='-/' then
         do
         cmd=substr(cmd,3)
         if cmd='' then cmd=lastf
         top=find('-',cmd)
         iterate
         end

      if substr(cmd,1,1)='S' then
         do
         parse var cmd cmd parm
         if cmd='SET' then
            do
            if set(parm) then
               return ''
            end

         if cmd='SAVE' then
            do
            parse var cmdasis . path .
            address syscall 'writefile (path) 640 line.'
            if retval=-1 then
               emsg='error' errno errnojr path
             else
               emsg='saved' path
            iterate
            end
         end

      if sel=1 & num<>'' then
         do
         rtn=num cmd
         leave
         end

      if sel=1 & length(cmd)=0 then
         do
         rtn=''
         leave
         end

      if length(cmd)=0 then
         do
         checkscreen=1
         if length(num)>0 then
            top=num
         iterate
         end

      emsg='invalid subcommand' c2x(cmd)
   end
   call resetterm
   return rtn

/************************************************************/
set:
   parse arg parm
   do while parm<>''
      parse var parm opt val parm
      if opt='PREFIX' then
         isfprefix=val
      else
      if opt='OWNER' then
         isfowner=val
      else
        do
        emsg='invalid set option:' opt
        return 0
        end
   end
   return 1

/************************************************************/
find:
   arg dir,cmd
   lastdir=dir
   if dir='+' then
      do
      lastf=cmd
      do i=top+1 to line.0
         if pos(cmd,translate(line.i))>0 then
            do
            top=i
            leave
            end
      end
      if i>line.0 then emsg='hit bottom' c2x(cmd)
      return top
      end

   if dir='-' then
      do
      lastf=cmd
      do i=top-1 to 1 by -1
         if pos(cmd,translate(line.i))>0 then
            do
            top=i
            leave
            end
      end
      if i<1 then emsg='hit top' cmd
      return top
      end
   return top

/************************************************************/
help:
      buf=ff||nvid||ff||nl
      buf=buf '                Help (H|F1)' nl
      buf=buf '                                                                    ' nl
      buf=buf 'Q|F3                  exit page                                     ' nl
      buf=buf 'Enter                 refresh page                                  ' nl
      buf=buf 'D|Space|pgdn|dn|F8    down (or prefix D with number: 100d)          ' nl
      buf=buf 'U|pgup|up|F7          up (or prefix U with number)                  ' nl
      buf=buf 'R|->|F11              right (or prefix R with number)               ' nl
      buf=buf 'L|<-|F10              left (or prefix L with number)                ' nl
      buf=buf 'T                     top                                           ' nl
      buf=buf 'B                     bottom                                        ' nl
      buf=buf 'number                go to that line number                        ' nl
      buf=buf '/                     find ex: /addr1 (with no string, / and -/     ' nl
      buf=buf '-/                    find prev        can repeat with prior string ' nl
      buf=buf '=                     repeat find      and change direction)        ' nl
      buf=buf 'save <path>           save the file to the specified path name      ' nl
      buf=buf 'set <option value>... set options                                   ' nl
      buf=buf '    options: prefix <prefix>   default *                            ' nl
      buf=buf '             owner <owner>     default your userid                  ' nl
      buf=buf '    ex:  set prefix #* owner wjs                                    ' nl
      buf=buf '                                                                    ' nl
      buf=buf 'Top line of screen shows lines/left:right margins, and keys help    ' nl
      buf=buf '                                                                    ' nl
      buf=buf 'Job Selection Screen                                                ' nl
      buf=buf '   view job    select by line number                                ' nl
      buf=buf '   purge       select by line number suffixed with P.  ex: 4p       ' nl
      buf=buf '   refresh     Enter                                                ' nl
      buf=buf '                                                                    ' nl

      call charout ,buf
      call getline
   return

/************************************************************/
/************************************************************/
getline: procedure expose num k.
   parse arg getfull
   num=''
   cmd=''
   bs='07'x
   char=charin()
   if char=bs then return ''
   if char=k.$esc then
      return getesc()
   if pos(char,getfull)=0 then
      if char='15'x then
         return ''
       else
         return char
   if length(getfull)=0 then
      return char

   if pos(char,'1234567890' || bs)>0 then
      do
      num=char
      do forever
         char=charin()
         if pos(char,'1234567890' || bs)>0 then
            num=num||char
          else
            leave
      end
      end
   num=canon(num)
   if char='15'x then
      return ''
   if char=k.$esc then
      return getesc()
   if num='' then
      return canon(char||linein())
   return canon(char)

/************************************************************/
getesc:
      cmd=char
      cmd=cmd||charin()
      do until k.cmd<>''
         cmd=cmd||charin()
         if length(cmd)>8 then return ''
      end
      return cmd

/************************************************************/
canon: procedure expose bs k.
   parse arg str
   strout=''
   do while str<>''
      chr=substr(str,1,1)
      str=substr(str,2)
      /* handle backspace */
      if chr<>bs then
         strout=strout||chr
       else
         if length(strout)>1 then
            strout=substr(strout,1,length(strout)-1)
          else
            strout=''
   end
   return strout

/************************************************************/
setraw:
   call bpxwunix 'stty -g',,'opt.'
   cmd='stty raw -icanon min 1'
   call bpxwunix cmd
   return

/************************************************************/
resetterm:
   buf=clear||defvid||clear
   call charout ,buf
   call bpxwunix 'stty' opt.1
   return rtn

/************************************************************/
setesc:
   fail.=''
   csi='27'x || '['
   curtop='27'x || '[1;1H'
   curtop=csi'1;1H'
   eos=csi'2J'
   clear=curtop || '27'x||'[2J'
   rvid=csi'7m'
   defvid=csi'0m'
   blackfg=csi||'38;30;47;107m'
   redfg=csi||'31m'
   greenfg=csi||'32m'
   yellowfg=csi||'33m'
   bluefg=csi||'34m'
   magentafg=csi||'34m'
   cyanfg=csi||'36m'
   whitefg=csi||'37;40m'
   nvid=blackfg
   ff=curtop||eos
   nl='150d'x
   /* keys */
   k.=''
   k.$esc='27'x
   ?f1  ='27d6d7'x
   k.?f1=?f1
   $f1  ='27ADF1F1A1'x
   k.$f1=$f1
   ?f3  ='27d6d9'x
   k.?f3=?f3
   $f3  ='27ADF1F3A1'x
   k.$f3=$f3
   $f5  ='27ADF1F5A1'x
   k.$f5=$f5
   $f7  ='27ADF1F8A1'x
   k.$f7=$f7
   $f8  ='27ADF1F9A1'x
   k.$f8=$f8
   $f10 ='27ADF2F1A1'x
   k.$f10=$f10
   $f11 ='27ADF2F3A1'x
   k.$f11=$f11
   $pgup='27ADF5A1'x
   k.$pgup=$pgup
   $pgdn='27ADF6A1'x
   k.$pgdn=$pgdn
   $up  ='27ADC1'x
   k.$up  =$up
   $dn  ='27ADC2'x
   k.$dn  =$dn
   $rt  ='27ADC3'x
   k.$rt  =$rt
   $lft ='27ADC4'x
   k.$lft =$lft
   return

/************************************************************/

novalue:
   fail1='novalue failure'
syntax:
halt:
   fail2='Error on line' sigl':' errortext(rc)
   fail3=sourceline(sigl)
   call resetterm
   if symbol('FAIL1')='VAR' then
      say fail1
   say fail2
   say fail3
   exit

