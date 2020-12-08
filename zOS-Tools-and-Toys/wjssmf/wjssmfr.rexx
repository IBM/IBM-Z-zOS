/* REXX */
/* PROPERTY OF IBM                                                    */
/* COPYRIGHT IBM CORP. 2013                                           */

/*
 Description:
 Read and print select types from an smf data set

 wjssmfr <options>
  Read SMF data set and format or dump records
  if no options are specified a panel will prompt for some basic options

  options:
   -d dsn        smf data set name (TSO format)
   -t typespec   multiple -t args permitted
                 typespec is type(subtypelist)(filterlist)
                 subtypelist is * for all or comma separated subtypes
                 filterlist is a comma separated list of search values
                    the fields that are searched is dependent on the
                    formatting definition for the type.  Use -q to
                    query the filter fields for a type
                 if all subtypes and no filters are requested, only the
                 type needs to be specified
                 The filterlist is optional
                 There must be no blanks in the option value
                 ex: 92(*)(b0b2,7e,/u/,/tmp/)
   -q type       query filter fields for the type.  ex:  -q 92
   -r            show both raw and formatted record
   -u            show unformatted record only
   -c            show tod clock in hex

 This runs in an ISPF environment and requires z/OS 2.1
 End Description

 Change Activity:
    9/27/2013   initial
   10/16/2013   new syntax, multi-filters, subtype descriptions, query

  Bill Schoen (wjs@us.ibm.com)

*/
arg prms
if arg(1)='Q' then
   do
   do i=1 to sourceline()
      queue sourceline(i)
   end
   return
   end
oix=0
brnum=0
call getargs
call syscalls 'ON'
numeric digits 20

tot=0
call loadmaps tplist

if qtyp<>'' then
   do
   call queryfilt
   out.0=oix
   call brstem out.
   return
   end

'alloc fi(smf) da('dsn') shr'
if rc<>0 then return

/* read data set 1000 recs at a time */
maxrec=15000
lim=900000
do until smf.0<maxrec
   'execio' maxrec ' diskr smf (stem smf.'
   if rc>2 then
      do
      say 'error reading data set:' rc
      leave
      end
   /* process each record read from the last execio */
   do i=1 to smf.0
      tot=tot+1
      call gethdr
      /* get record type and see if it was requested */
      stx=wordpos(typ,tplist)
      if stx=0 then iterate
      /* get requested subtypes and filter for this type */
      stlist=stlist.stx
      dvlist=dvlist.stx
      if stlist<>'' & wordpos(subtype,stlist)=0 then iterate
      /* subtype was requested, try to process */
      if checksel()=0 then iterate
      sel=sel+1
      subt=subtype
      if map.typ.subtype<>'' then
         subt=subtype'('strip(map.typ.subtype)')'
      call put '******** Type:' typ 'Subtype:' subt 'Time:' tm dy'.'yr
      call put
      if unf | debug | raw | offset.1.0='' then
         do
         call dump d2c(length(smf.i)+4,2)'0000'x || smf.i
         call put
         if unf then iterate
         end
      call formatrec
      call put
      if oix>lim then
         call brout
   end
   say 'Records scanned:' tot 'Records selected:' sel
end
call brout 1
done:
'execio 0 diskr smf (fini'
'free fi(smf)'
exit

brout:
   brnum=brnum+1
   if arg(1)='' then
      say 'viewing output segment' brnum
   else
   if brnum>1 then
      say 'viewing last output segment' brnum
   out.0=oix
   say 'Output lines:' oix
   call brstem 'out.'
   oix=0
   if arg(1)='' then
      do
      say 'Hit Enter to continue scan or anything else to stop'
      pull xx
      if xx<>'' then
         signal done
      say 'resuming scan'
      end
   return

/* load mappings for requested types */
loadmaps:
   arg tplist
   sel=0
   epoch=x2d('7D91048BCA000000') /* tod at 1970 */
   epsec=x2d('F4240000')         /* tod at 1 second */
   offs.=''
   map.=''

   /* get the mapping for the type by running exec                */
   /* SMFTPn where n=type number                                  */
   /* mapping statements are placed on the stack and interpreted  */
   /* See SMFTP92 for the format of the mapping statements        */
   do i=1 to words(tplist)
      typ=word(tplist,i)
      cmd='wjsst'typ
      trace o
      call outtrap 'xx.'
      cmd
      call outtrap 'OFF'
      trace
      if queued()=0 then
         say 'formatting not available for type' typ
      do while queued()>0
         parse pull xx
         interpret xx
      end
   end
   return

gethdr:
   fmt=c2x(substr(smf.i,1,1))
   typ=c2d(substr(smf.i,2,1))
   if substr(x2b(fmt),2,1) then
      subtype=c2d(substr(smf.i,19,2))
    else
      subtype='n/a'
   yr=c2x(substr(smf.i,8,1))
   dy=substr(c2x(substr(smf.i,9,2)),1,3)
   tm=c2d(substr(smf.i,3,4))%100
   address syscall 'gmtime (tm) tm.'
   tm=right(tm.tm_hour,2,0)':'right(tm.tm_min,2,0)':'right(tm.tm_sec,2,0)
   /* use mapping to load offset. with each section offset, length, count */
   offset.=''
   do ii=1 by 1
      if offs.typ.ii.0='' then leave
      offset.ii.0=c2d(substr(smf.i,offs.typ.ii.1-3,4))-3 /* offset 1 based */
      offset.ii.1=c2d(substr(smf.i,offs.typ.ii.2-3,2))   /* length         */
      offset.ii.2=c2d(substr(smf.i,offs.typ.ii.3-3,2))   /* count          */
   end
   return

queryfilt:
   call put 'Subtype Format Description'
   maxstp=offs.qtyp.1
   maxsec=offs.qtyp.2
   if maxstp='' | maxsec='' then return
   do i=1 to maxsec
      if offs.qtyp.i.0=0 then
         call queryloop i,0
       else
         do j=1 to maxstp
            call queryloop i,j
         end
   end
   return

queryloop:
   arg sec,stp
   if stp=0 then
      dstp='n/a'
    else
      dstp=stp
   do fix=1 by 1
      parse var map.qtyp.sec.stp.0.fix ofs tp ln name desc
      if ofs='' then leave
      call put right(dstp,7) left(tp,6) strip(desc)
   end
   return

checksel:
   if dvlist='' then return 1
   selected=0
   do sec=1 by 1
      if offs.typ.sec.0=0 then
         stp=0
      else
      if offs.typ.sec.0=1 then
         stp=subtype
      else
         return 0
      do fix=1 by 1
         parse var map.typ.sec.stp.0.fix ofs tp ln name desc
         if ofs='' then leave  /* no filter for section/subtype */
         ofs=ofs+offset.sec.0
         if tp='NUM' then
            do
            dv=c2d(substr(smf.i,ofs,ln))
            if wordpos(dv,dvlist)>0 then return  1 /* got a match */
            end
         else
         if tp='CHR' then
            do
            dv=translate(substr(smf.i,ofs,ln))
            do cschr=1 to words(dvlist)
               if pos(word(dvlist,cschr),dv)>0 then return  1 /* got a match */
            end
            end
         else
            do
            dv=strip(c2x(substr(smf.i,ofs,ln)),'L',0)
            if wordpos(dv,dvlist)>0 then return  1 /* got a match */
            end
      end
   end
   return 0


formatrec:
      /* process each defined section for the type */
      do sec=1 by 1
         if offs.typ.sec.0=0 then
            stp=0
         else
         if offs.typ.sec.0=1 then
            stp=subtype
         else
            return
         rec=substr(smf.i,offset.sec.0,offset.sec.1)
         call formatsec
      end
   return

formatsec:
   fw=20
   do ix=1 by 1
      parse var map.typ.sec.stp.ix ofs tp ln name desc
      if ofs='' then
         do
         if ix=1 then
            call dump rec
         return
         end
      ofs=ofs+1
      field=substr(rec,ofs,ln)
      name=left(right(name,8),8) /* right 8 chars of field name */
      desc=strip(desc)
      if tp='TOD' then
         call put name left(todcvt(field),fw) desc
      else
      if tp='NUM' then
         call put name left(c2d(field),fw) desc
      else
      if tp='CHR' then
         do
         field=strip(field)
         if length(field)<fw then
            call put name left(field,fw) desc
          else
            call put name field desc
         end
      else
      if tp='BIT' then
         do
         field=c2x(field)
         call put name left(field,fw) desc
         field=x2b(field)
         do bix=1 to ln*8
            parse var map.typ.sec.stp.ix.bix name desc
            desc=strip(desc)
            name=left(right(name,8),8) /* right 8 chars of name */
            if name='' then iterate
            val=substr(field,bix,1)
            call put name left(val,fw+4) desc
         end
         end
      else /* HEX */
         call put name left(c2x(field),fw) desc
   end
   return

/* convert tod clock to date and time */
/* this normalizes tod to posix time then uses gmtime to convert */
todcvt:
   if clk then return c2x(arg(1))
   todc=c2d(arg(1))
   tod=(todc-epoch)%epsec  /* normalize to 1970 and round to seconds */
   if tod<1 then return c2x(arg(1))
   address syscall 'gmtime (tod) tm.'
   if rc<>0 then trace ?i
   return right(tm.tm_hour,2,0)':'right(tm.tm_min,2,0)':'right(tm.tm_sec,2,0),
          right(tm.tm_mon,2,0)'/'right(tm.tm_mday,2,0)'/'right(tm.tm_year,4,0)

/* parse command line arguments */
getargs:
   if prms='' then
      do
      call buildpan
      address ispexec 'display panel(wjssmfp)'
      svrc=rc
      call cleanup
      if svrc<>0 then exit
      prms='-d' dsn
      prms=prms '-t' typ
      prms=prms || '('stp')'
      if flt<>'' then prms=prms || '('flt')'
      prms=translate(prms)
      if r<>'N' then prms=prms '-R'
      if u<>'N' then prms=prms '-U'
      if c<>'N' then prms=prms '-C'
      if f<>'N' then prms='-Q' typ
      say 'wjssmfr' prms
      end
   tplist=''
   stlist.=''
   stx=0
   dvlist.=''
   dvx=0
   do forever
      if pos('-T',prms)=0 then leave
      parse var prms pre '-T' suf post
      parse var suf typ '(' subs ')' '(' filts ')' suf
      prms=pre suf post
      tplist=tplist typ
      stx=stx+1
      stlist.stx=translate(subs,'  ','*,')
      dvx=dvx+1
      dvlist.dvx=translate(filts,'  ','*,')
   end
   if tplist='' then tplist='92'

   dsn=''
   if pos('-D',prms)>0 then
      do
      parse var prms pre '-D' dsn post
      prms=pre post
      end

   debug=0
   if pos('-Z',prms)>0 then
      do
      parse var prms pre '-B' post
      prms=pre post
      debug=1
      end

   raw=0
   if pos('-R',prms)>0 then
      do
      parse var prms pre '-R' post
      prms=pre post
      raw=1
      end

   unf=0
   if pos('-U',prms)>0 then
      do
      parse var prms pre '-U' post
      prms=pre post
      unf=1
      raw=1
      end

   clk=0
   if pos('-C',prms)>0 then
      do
      parse var prms pre '-C' post
      prms=pre post
      clk=1
      end

   qtyp=''
   if pos('-Q',prms)>0 then
      do
      parse var prms pre '-Q' qtyp post
      if qtyp='' then qtyp=92
      return
      end

   if prms<>'' then
    do
    say 'invalid parms:' prms
    do i=1 to sourceline()
       if sourceline(i)='Description:' then leave
    end
    do i=i+1 to sourceline()
       if sourceline(i)='End Description' then leave
       call put sourceline(i)
    end
    out.0=oix
    call brstem out.
    exit
    end

   say 'SMF data set is' dsn
   do i=1 to words(tplist)
      typ=word(tplist,i)
      stlist=stlist.i
      if stlist='' then
         msg='type' typ 'subtypes: all'
       else
         msg='type' typ 'subtypes:' stlist
      dvlist=dvlist.i
      if dvlist='' then
         msg=msg 'filter: none'
       else
         msg=msg 'filter:' dvlist
      say msg
   end
   return

/**********************************************************************/
/* capture output stream                                              */
/**********************************************************************/
put:
   if arg(2)<>'' then
      do
      call put arg(1)
      return
      end
   outln=arg(1)
   do until outln=''
      parse var outln prtln 200 outln /* wrap lines at 200 */
      oix=oix+1
      out.oix=strip(prtln,'T')
   end
   return

/**********************************************************************/
/* formatted dump utility                                             */
/**********************************************************************/
dump:
   procedure expose ipcs oix out.
   parse arg dumpbuf,echo
   sk=0
   prev=''
   do ofs=0 by 16 while length(dumpbuf)>0
      parse var dumpbuf 1 ln 17 dumpbuf
      out=c2x(substr(ln,1,4)) c2x(substr(ln,5,4)),
          c2x(substr(ln,9,4)) c2x(substr(ln,13,4))
      if prev=out then
         sk=sk+1
       else
         do
         if sk>0 then call put '...'
         sk=0
         prev=out
         call put right(ofs,6)'('d2x(ofs,4)')' out "*"ln"*"
         if echo=1 then say right(ofs,6)'('d2x(ofs,4)')' out
         end
   end
   return

/**********************************************************************/
/* browse stem utility                                                */
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
   call bpxwdyn "alloc rtddn(bpxpout) new",
                "space(20,20) cyl",
                "recfm(v,b) lrecl("brlen") msg(wtp)"
   address tso "execio" brc "diskw" bpxpout "(fini stem" arg(1)
   'LMINIT DATAID(DID) DDNAME('BPXPOUT')'
   'VIEW   DATAID('did') PROFILE(WJSC) MACRO(RESET)'
   'LMFREE DATAID('did')'
   call bpxwdyn 'free dd('bpxpout')'
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
   address ispexec 'LIBDEF ISPPLIB'
   address tso
   call bpxwdyn 'free fi('wjsezpan')'
   if keep=1 then 'del wjsez.pan'
   needcleanup=0
   return

/**********************************************************************/
/*

************************************************************************
//pan wjssmfp
)ATTR
  ^ TYPE(INPUT) caps(off) intens(non) padc('_')
  ! type(output) color(white)
  @ type(output) COLOR(turquoise) intens(high) caps(off)
  + type(text)   color(turquoise) caps(off) intens(low)
)BODY EXPAND(\\) WIDTH(&ZSCREENW)
+              Read SMF Records
%Command ===>_ZCMD                                                \ \ +
%
+Enter parms for smf reader
%
%Data set    :_dsn                                         +
%Record type :_typ+
%Subtypes    :_stp
%Filter      :_flt
%Raw         :_r+   Y=dump and format records
%Unformatted :_u+   Y=dump records with no formatting
%Hex TOD     :_c+   Y=Do not convert TOD times to time and date
%Show filters:_f+   Y=Display filter fields for the record type
+
+Subtypes and filter are comma delimited lists
+
)INIT
&zcmd = ' '
vget (wjsrsdsn) profile
&dsn=&wjsrsdsn
&typ='92'
&stp='*'
&flt=' '
&r='N'
&u='N'
&c='N'
&f='N'
.cursor=dsn
)PROC
   ver (&dsn nb)
   &wjsrsdsn=&dsn
   vput (wjsrsdsn) profile
   ver (&typ nb)
   ver (&stp nb)
   ver (&r nb list Y,N,/)
   ver (&u nb list y,Y,n,N,/)
   ver (&c nb list y,Y,n,N,/)
   ver (&f nb list y,Y,n,N,/)
)END
//end

*/
