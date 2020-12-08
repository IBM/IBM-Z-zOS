/* rexx */
/**********************************************************************/
/* list a pds directory                                               */
/*                                                                    */
/* PROPERTY OF IBM                                                    */
/* COPYRIGHT IBM CORP. 1999,2020                                      */
/*                                                                    */
/* Syntax: pdsdir [volser:]fully.qualified.dsn                        */
/*                                                                    */
/* Change activity:                                                   */
/*   8/21/99  handle errors on execio                                 */
/*  12/31/99  fix last day of month problem in j2g                    */
/*  01/09/13  decode stats for loadlibs                               */
/*            indicate orphaned members                               */
/*  04/28/14  accept volser (Barry)                                   */
/*  01/17/20  fix scatter load (Barry)                                */
/*                                                                    */
/* Bill Schoen (wjs@us.ibm.com)                                       */
/**********************************************************************/

/**********************************************************************
Each record has the form:

+------------+------+------+------+------+----------------+
+ # of bytes |Member|Member|......|Member|  Unused        +
+ in record  |  1   |  2   |      |  n   |                +
+------------+------+------+------+------+----------------+
 |--count---||-----------------rest-----------------------|
 (Note that the number stored in count includes its own
  two bytes)

And, each member has the form:

+--------+-------+----+-----------------------------------+
+ Member |TTR    |info|                                   +
+ Name   |       |byte|  User Data TTRN's (halfwords)     +
+ 8 bytes|3 bytes|    |                                   +
+--------+-------+----+-----------------------------------+

bit 0 of the info-byte is '1' if the member is an alias,
0 otherwise.  Bits 3-7 contain the number of user data half-words.

ISPF Stats:
 unsigned int ver:8;
 unsigned int mod:8;
 unsigned int flags:8;
 unsigned int mod_sec:8;

 unsigned int cr_date_rsv:8;
 unsigned int cr_date_y:8;
 unsigned int cr_date_d:12;
 unsigned int cr_date_f:4;

 unsigned int mod_date_rsv:8;
 unsigned int mod_date_y:8;
 unsigned int mod_date_d:12;
 unsigned int mod_date_f:4;

 unsigned int mod_hh:8;
 unsigned int mod_mm:8;
 short lines;

 short ilines;
 short m_lines;

 char  user[7];
 char  rsvd[3];

Loadlib Stats:
 see IHAPDS

***********************************************************************/
parse arg dsn .
if dsn='' then
   do
   say 'Data set name required'
   return 4
   end
if POS(':',dsn)\=0 then do
  parse var dsn volser ':' dsn
  vol = 'vol('volser')'
end
else
  vol = ''
if bpxwdyn('alloc fi(pds) da('dsn') shr msg(2)' || vol ,
           'recfm(f) dsorg(ps) lrecl(256) blksize(256)')<>0 then
   return 4

ent=0
alias.=''
do looking=1 by 0 while looking
   address mvs "execio 1 diskr pds (stem dir."
   if rc<>0 | dir.0=0 then leave
   used = c2d(substr(dir.1,1,2))
   do ix=3 by 0 while ix < used   /* first entry starts in third byte */
      if substr(dir.1,ix,8) = 'ffffffffffffffff'x then
         do
         looking=0
         leave
         end
      name = substr(dir.1,ix,8)
      ix = ix + 8                                   /* skip name      */
      ttr = substr(dir.1,ix,3)
      ix = ix + 3                                   /* skip ttr       */
      len = c2d(bitand(substr(dir.1,ix,1),'1f'x))*2 /* get data len   */
      info = substr(dir.1,ix,1)                     /* get info byte  */
      ix = ix + 1                                   /* skip info byte */
      userdata = c2x(substr(dir.1,ix,len))
      ent=ent+1
      ent.ent.1=name
      ent.ent.2=ttr
      ent.ent.3=info
      ent.ent.4=userdata
      if bitand(info,'80'x)='00'x then
         alias.ttr=name
      ix = ix + len                                 /* skip user data */
   end
end
address mvs 'execio 0 diskr pds (fini'
call bpxwdyn 'free fi(pds)'
do i=1 to ent
   say ent.i.1 stats(ent.i.4,ent.i.3) alias(ent.i.2,ent.i.3)
end
return 0

p2d: procedure
   arg packed
   len=length(packed)
   i=0
   do while packed<>''
      parse var packed 1 ii 2 packed
      i=i*10+x2d(ii)
   end
   return right(i,len,0)

alias:
   parse arg ttr,info
   if bitand(info,'80'x)='00'x then
      return ''
   if alias.ttr='' then
      return 'Orphaned Member'
   return 'Alias('alias.ttr')'

loadstats:
   if length(ud)<42 then return ''
   parse var ud 1 ttr 7 9 ttrn 15 17 att1 19 att2 21,
                stg 27 31 ep 37 flg1 39 flg2 41 flg3 43 rest
   att1=x2c(att1)
   att2=x2c(att2)
   flg1=x2c(flg1)
   flg2=x2c(flg2)
   if bitand(att1,'80'x)<>'00'x then
      reent='RN'
    else
      reent='  '
   if bitand(att1,'40'x)<>'00'x then
      reuse='RU'
    else
      reuse='  '
   if bitand(att1,'02'x)<>'00'x then
      ex='  '
    else
      ex='NX'
   if bitand(att2,'01'x)<>'00'x then
      rf='RF'
    else
      rf='  '
   if bitand(att1,'04'x)<>'00'x then
      do
      parse var rest scatterinfo 17 rest
      scatter='SCTR'
      end
   else
      scatter=''
   alias=bitand(info,'80'x)<>'00'x
   if alias then
      do
      am=bitand(flg2,'0c'x)
      if am='00'x then am='24'
      else
      if am='08'x then am='31'
      else
      if am='0c'x then am='ANY'
      else
      if am='04'x then am='64'
      end
    else
      do
      am=bitand(flg2,'03'x)
      if am='00'x then am='24'
      else
      if am='02'x then am='31'
      else
      if am='03'x then am='ANY'
      else
      if am='01'x then am='64'
      end
   if alias then
      parse var rest aliasinfo 23 rest
    else
      if bitand(flg1,'10'x)<>'00'x then
         rest=substr(rest,3) /* align subsys section */
   if bitand(flg1,'10'x)<>'00'x then
      parse var rest ssi 9 rest
    else
      ssi='        '
   if bitand(flg1,'08'x)<>'00'x then
      do
      parse var rest apfinfo 1 apflen 3 rest
      apflen=x2d(apflen)
      apfcd=substr(rest,1,apflen*2)
      apfcd=x2d(apfcd)
      rest=substr(rest,1,apflen*2+1)
      if apfcd=1 then
         apf='APF'
       else
         apf='   '
      end
   return 'ep('ep')' left('AM('am')',7) reent reuse rf ex apf ssi scatter

stats: procedure expose istat.
   parse arg ud,info
   istat.=''
   if length(ud)<>60 then
      return loadstats()
   istat.1=p2d(substr(ud,1,2))
   istat.2=p2d(substr(ud,3,2))
   istat.3=p2d(substr(ud,5,2))
   istat.4=p2d(substr(ud,7,2))

   cdr=p2d(substr(ud,9,2))
   cdy=p2d(substr(ud,11,2))
   cdd=p2d(substr(ud,13,3))
   cdf=p2d(substr(ud,16,1))
   istat.5=j2g(cdy cdd)'/'cdy

   mdr=p2d(substr(ud,17,2))
   mdy=p2d(substr(ud,19,2))
   mdd=p2d(substr(ud,21,3))
   mdf=p2d(substr(ud,24,1))
   istat.6=j2g(mdy mdd)'/'mdy

   mhh=p2d(substr(ud,25,2))
   mmm=p2d(substr(ud,27,2))
   istat.7=mhh':'mmm
   istat.8=x2d(substr(ud,29,4))

   istat.9=x2d(substr(ud,33,4))
   istat.10=x2d(substr(ud,37,4))

   istat.11=x2c(substr(ud,41,14))
   return istat.5 istat.6 istat.7 right(istat.8,6) right(istat.9,6),
          istat.11

j2g: procedure /* convert from julian */
   arg yy ddd
   if yy//4=0 then
      dom = 31 29 31 30 31 30 31 31 30 31 30 31 999
    else
      dom = 31 28 31 30 31 30 31 31 30 31 30 31 999
   do i=1 by 1 until ddd<=0
      ddd=ddd-word(dom,i)
   end
   return right(i,2,0)'/'right(ddd+word(dom,i),2,0)
