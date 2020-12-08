/* rexx */
/* PROPERTY OF IBM                                                    */
/* COPYRIGHT IBM CORP. 2013                                           */
/* mapping for smf type 92 used by WJSSMFR

   mapping format:
   offsets assigned in quads in stem offs.
      offs.type.n.0  0=section is the same for all subtypes, 1=unique to subtype
      offs.type.n.1  location of offset for section n
      offs.type.n.2  location of length for section n
      offs.type.n.3  location of count for section n
     n has a range of 1 to number of sections
     type is the smf record type
   all mapping values assigned in stem map.
    first index is the smf type
    second index is the section number corresponding to n in offs.
    third index is 0 if n.0=0 otherwise the subtype
    fourth index is the field number, 1-n.  do not skip numbers
      use index 0 as the filter field for the section
   the fifth index, if present, is the bit number for a BIT field, 1-n
   Descriptive information can be provided in the map stem for subtypes:
      map.type.subtype can be assigned a descriptive string

   The format of the non-flag strings is 4 blank delimited columns:
      decimal offset to the field
      field type (TOD, NUM, HEX, CHR, BIT)
      decimal length of field in bytes
      field name
      description
   The format of the flag strings is 2 blank delimited columns
      field name
      description

  Change Activity:
     10/16/2013     initial

   Bill Schoen (wjs@us.ibm.com)
*/
if arg(1)<>'' then
   i=0
else
do i=1 to sourceline()
   if sourceline(i)='/*start*/' then leave
end
do i=i+1 to sourceline()
   if sourceline(i)='' then iterate
   if sourceline(i)='/*end*/' then leave
   queue sourceline(i)
end
return
/*start*/

   offs.92.1    =17  /* max subtype */
   offs.92.2    =3   /* max sections */
   offs.92.1.0  =0   /* use subtype 0=no 1=yes */
   offs.92.1.1  =28  /* location of offset */
   offs.92.1.2  =32  /* location of length */
   offs.92.1.3  =34  /* location of count  */
   offs.92.2.0  =0
   offs.92.2.1  =36
   offs.92.2.2  =40
   offs.92.2.3  =42
   offs.92.3.0  =1
   offs.92.3.1  =44
   offs.92.3.2  =48
   offs.92.3.3  =50

   map.92.1 ='File system mount'
   map.92.2 ='File system suspend'
   map.92.4 ='File system resume'
   map.92.5 ='File system unmount'
   map.92.6 ='File system remount'
   map.92.7 ='File system move'
   map.92.10 ='File open'
   map.92.11 ='File close'
   map.92.12 ='Memmap'
   map.92.13 ='Memunmap'
   map.92.14 ='File/directory delete'
   map.92.15 ='Security attributes changed'
   map.92.16 ='Socket/char spec close'
   map.92.17 ='File accesses'

   map.92.1.0.1='    0 NUM  2 SMF92TYP Record subtype'
   map.92.1.0.2='    2 CHR  2 SMF92RVN Record version number'
   map.92.1.0.3='    4 CHR  8 SMF92PNM Product name - OpenMVS'
   map.92.1.0.4='   12 CHR  8 SMF92OSL MVS product level'

   map.92.2.0.1='    0 CHR 8 SMF92JBN      JobName                      '
   map.92.2.0.0.1='    0 CHR 8 SMF92JBN      JobName                      '
   map.92.2.0.2='    8 HEX 4 SMF92RST      Reader start time            '
   map.92.2.0.3='   12 HEX 4 SMF92RSD      Reader start date            '
   map.92.2.0.4='   16 CHR 8 SMF92STM      Step name                    '
   map.92.2.0.5='   24 CHR 8 SMF92RGD      SAF group ID                 '
   map.92.2.0.6='   32 CHR 8 SMF92RUD      SAF user ID                  '
   map.92.2.0.0.2='   32 CHR 8 SMF92RUD      SAF user ID                  '
   map.92.2.0.7='   40 NUM 4 SMF92UID      OpenMVS real user ID         '
   map.92.2.0.8='   44 NUM 4 SMF92GID      OpenMVS real group ID        '
   map.92.2.0.9='   48 HEX 4 SMF92PID      OpenMVS process ID           '
   map.92.2.0.10='  52 HEX 4 SMF92PGD      OpenMVS process group ID     '
   map.92.2.0.11='  56 HEX 4 SMF92SSD      OpenMVS session ID           '
   map.92.2.0.12='  60 HEX 4 SMF92API      OpenMVS anchor process ID    '
   map.92.2.0.13='  64 HEX 4 SMF92APG      OpenMVS anchor proc grp ID   '
   map.92.2.0.14='  68 HEX 4 SMF92ASG      OpenMVS anchor session ID    '

   map.92.3.1.1='      0 TOD  8 SMF92MTM Time of mount, STCK format                                      '
   map.92.3.1.2='     12 NUM  4 SMF92MFT File system type from MntEntFSType field of BPXYMNTE            '
   map.92.3.1.3='     16 NUM  4 SMF92MFM File system mode from MntEntFSMode field of BPXYMNTE            '
   map.92.3.1.4='     20 HEX  4 SMF92MDN File system device number from MntEntFSDev field of BPXYMNTE    '
   map.92.3.1.0.1='     20 HEX  4 SMF92MDN File system device number from MntEntFSDev field of BPXYMNTE    '
   map.92.3.1.5='     24 CHR  8 SMF92MDD DDNAME specified on mount from MntEntFSDDName field of BPXYMNTE '
   map.92.3.1.6='     32 CHR  8 SMF92MTN File system type name from MntEntFSTName field of BPXYMNTE      '
   map.92.3.1.7='     40 CHR 44 SMF92MFN File system name from MntEntFSName field of BPXYMNTE            '
   map.92.3.1.8='     84 NUM  4 SMF92MBL File system block size                                          '
   map.92.3.1.9='     88 NUM  8 SMF92MST Total space in file system in block size units                  '
   map.92.3.1.10='    96 NUM  8 SMF92MSU Allocated space in file system in block size units              '
   map.92.3.1.11='   104 BIT  1 SMF92MFG Flag byte                                                       '
   map.92.3.1.11.1='             SMF92MAU     Mounted by Automounter                                     '
   map.92.3.1.11.2='             SMF92MAS     Asynchronous mount 1 = Yes, 0= No                          '
   map.92.3.1.12='   105 BIT  1 SMF92MF2 Second Flag byte                                                '
   map.92.3.1.12.1='             SMF92MLU Mounted localy                                                 '
   map.92.3.1.12.2='             SMF92MNU Mounted remotely                                               '
   map.92.3.1.12.3='             SMF92MDO HFS Sysplex client                                             '
   map.92.3.1.12.4='             SMF92MSN Filesystem owner                                               '
   map.92.3.1.13='   110 CHR 1024 SMF92PPN Path name of directory where file system is mounted.          '
   map.92.3.1.0.2='   110 CHR 1024 SMF92PPN Path name of directory where file system is mounted.          '

   map.92.3.2.1='      0 TOD 8   SMF92STS Time of suspend, STCK format                                   '
   map.92.3.2.2='      8 NUM 4   SMF92SFT File system type from MntEntFSType field of BPXYMNTE           '
   map.92.3.2.3='     12 NUM 4   SMF92SFM File system mode from MntEntFSMode field of BPXYMNTE           '
   map.92.3.2.4='     16 HEX 4   SMF92SDN File system device number from MntEntFSDev field of BPXYMNTE   '
   map.92.3.2.0.1='     16 HEX 4   SMF92SDN File system device number from MntEntFSDev field of BPXYMNTE   '
   map.92.3.2.5='     20 CHR 8   SMF92SDD DDNAME specified on mount from MntEntFSDDName field of BPXYMNTE'
   map.92.3.2.6='     28 CHR 8   SMF92STN File system type name from MntEntFSTName field of BPXYMNTE     '
   map.92.3.2.7='     36 CHR 44   SMF92SFN File system name from MntEntFSName field of BPXYMNTE          '
   map.92.3.2.8='     80 BIT 1   SMF92SFG  Flag btye                                                     '
   map.92.3.2.8.1='              SMF92SLU     Mounted localy                      '
   map.92.3.2.8.2='              SMF92SNU     Mounted remotely                    '
   map.92.3.2.8.3='              SMF92SDO     HFS Sysplex client                  '
   map.92.3.2.8.4='              SMF92SSN     Filesystem owner                    '

   map.92.3.4.1='      0 TOD  8  SMF92RTS Time of suspend, STCK format                                   '
   map.92.3.4.2='      8 TOD  8  SMF92RTR Time of resume, STCK format                                    '
   map.92.3.4.3='     16 NUM  4  SMF92RFT File system type from MntEntFSType field of BPXYMNTE           '
   map.92.3.4.4='     20 NUM  4  SMF92RFM File system mode from MntEntFSMode field of BPXYMNTE           '
   map.92.3.4.5='     24 HEX  4  SMF92RDN File system device number from MntEntFSDev field of BPXYMNTE   '
   map.92.3.4.0.1='     24 HEX  4  SMF92RDN File system device number from MntEntFSDev field of BPXYMNTE   '
   map.92.3.4.6='     28 CHR  8  SMF92RDD DDNAME specified on mount fromMntEntFSDDName field of BPXYMNTE '
   map.92.3.4.7='     36 CHR  8  SMF92RTN File system type name from MntEntFSTName field of BPXYMNTE     '
   map.92.3.4.8='     44 CHR 44  SMF92RFN File system name from MntEntFSName field of BPXYMNTE           '
   map.92.3.4.9='     88 BIT  1  SMF92RFG Flag btye                                                      '
   map.92.3.4.9.1='              SMF92RLU     Mounted localy                                             '
   map.92.3.4.9.2='              SMF92RNU     Mounted remotely                                           '
   map.92.3.4.9.3='              SMF92RDO     HFS Sysplex client                                         '
   map.92.3.4.9.4='              SMF92RSN     Filesystem owner                                           '

   map.92.3.5.1='      0 TOD 8  SMF92UTM Time of mount, STCK format                                      '
   map.92.3.5.2='      8 TOD 8  SMF92UTU Time of unmount, STCK format                                    '
   map.92.3.5.3='     16 NUM 4  SMF92UFT File system type from MntEntFSType field of BPXYMNTE            '
   map.92.3.5.4='     20 NUM 4  SMF92UFM File system mode from MntEntFSMode field of BPXYMNTE            '
   map.92.3.5.5='     24 HEX 4  SMF92UDN File system device number from MntEntFSDev field of BPXYMNTE    '
   map.92.3.5.0.1='     24 HEX 4  SMF92UDN File system device number from MntEntFSDev field of BPXYMNTE    '
   map.92.3.5.6='     28 CHR 8  SMF92UDD DDNAME specified on mount from MntEntFSDDName field of BPXYMNTE '
   map.92.3.5.7='     36 CHR 8  SMF92UTN File system type name from MntEntFSTName field of BPXYMNTE      '
   map.92.3.5.8='     44 CHR 44 SMF92UFN File system name from MntEntFSName field of BPXYMNTE            '
   map.92.3.5.9='     88 NUM 4  SMF92UBL File system block size                                          '
   map.92.3.5.10='    92 NUM 8  SMF92UST Total space in file system in block size units                  '
   map.92.3.5.11='   100 NUM 8  SMF92USU Allocated space in file system in block size units              '
   map.92.3.5.12='   108 NUM 4  SMF92USR Reads                                                           '
   map.92.3.5.13='   112 NUM 4  SMF92USW Writes                                                          '
   map.92.3.5.14='   116 NUM 4  SMF92UDI Directory I/O blocks                                            '
   map.92.3.5.15='   120 NUM 4  SMF92UIR I/O blocks read                                                 '
   map.92.3.5.16='   124 NUM 4  SMF92UIW I/O blocks written                                              '
   map.92.3.5.17='   128 NUM 8  SMF92UBR Bytes read                                                      '
   map.92.3.5.18='   136 NUM 8  SMF92UBW Bytes written                                                   '
   map.92.3.5.19='   144 BIT 1  SMF92UFG Flag byte                                                       '
   map.92.3.5.19.1='            SMF92UAU     Unmounted by Automounter                                    '
   map.92.3.5.20='   145 BIT 1  SMF92UF2      Second flag byte                                           '
   map.92.3.5.20.1='            SMF92ULU     Mounted localy                                              '
   map.92.3.5.20.2='            SMF92UNU     Mounted remotely                                            '
   map.92.3.5.20.3='            SMF92UDO     HFS Sysplex client                                          '
   map.92.3.5.20.4='            SMF92USN     Filesystem owner                                            '

   map.92.3.6.1='      0 TOD 8  SMF92UTM Time of mount, STCK format                                      '
   map.92.3.6.2='      8 TOD 8  SMF92UTU Time of unmount, STCK format                                    '
   map.92.3.6.3='     16 NUM 4  SMF92UFT File system type from MntEntFSType field of BPXYMNTE            '
   map.92.3.6.4='     20 NUM 4  SMF92UFM File system mode from MntEntFSMode field of BPXYMNTE            '
   map.92.3.6.5='     24 HEX 4  SMF92UDN File system device number from MntEntFSDev field of BPXYMNTE    '
   map.92.3.6.0.1='     24 HEX 4  SMF92UDN File system device number from MntEntFSDev field of BPXYMNTE    '
   map.92.3.6.6='     28 CHR 8  SMF92UDD DDNAME specified on mount from MntEntFSDDName field of BPXYMNTE '
   map.92.3.6.7='     36 CHR 8  SMF92UTN File system type name from MntEntFSTName field of BPXYMNTE      '
   map.92.3.6.8='     44 CHR 44 SMF92UFN File system name from MntEntFSName field of BPXYMNTE            '
   map.92.3.6.9='     88 NUM 4  SMF92UBL File system block size                                          '
   map.92.3.6.10='    92 NUM 8  SMF92UST Total space in file system in block size units                  '
   map.92.3.6.11='   100 NUM 8  SMF92USU Allocated space in file system in block size units              '
   map.92.3.6.12='   108 NUM 4  SMF92USR Reads                                                           '
   map.92.3.6.13='   112 NUM 4  SMF92USW Writes                                                          '
   map.92.3.6.14='   116 NUM 4  SMF92UDI Directory I/O blocks                                            '
   map.92.3.6.15='   120 NUM 4  SMF92UIR I/O blocks read                                                 '
   map.92.3.6.16='   124 NUM 4  SMF92UIW I/O blocks written                                              '
   map.92.3.6.17='   128 NUM 8  SMF92UBR Bytes read                                                      '
   map.92.3.6.18='   136 NUM 8  SMF92UBW Bytes written                                                   '
   map.92.3.6.19='   144 BIT 1  SMF92UFG Flag byte                                                       '
   map.92.3.6.19.1='            SMF92UAU     Unmounted by Automounter                                    '
   map.92.3.6.20='   145 BIT 1  SMF92UF2      Second flag byte                                           '
   map.92.3.6.20.1='            SMF92ULU     Mounted localy                                              '
   map.92.3.6.20.2='            SMF92UNU     Mounted remotely                                            '
   map.92.3.6.20.3='            SMF92UDO     HFS Sysplex client                                          '
   map.92.3.6.20.4='            SMF92USN     Filesystem owner                                            '

   map.92.3.7.1='      0 TOD 8 SMF92VTV Time of move, STCK format                                        '
   map.92.3.7.2='      8 TOD 8 SMF92VTM Time of mount, STCK format                                       '
   map.92.3.7.3='     16 NUM 4 SMF92VFT File system type from MntEntFSType field of BPXYMNTE             '
   map.92.3.7.4='     20 NUM 4 SMF92VFM File system mode from MntEntFSMode field of BPXYMNTE             '
   map.92.3.7.5='     24 HEX 4 SMF92VDN File system device number from MntEntFSDev field of BPXYMNTE     '
   map.92.3.7.0.1='     24 HEX 4 SMF92VDN File system device number from MntEntFSDev field of BPXYMNTE     '
   map.92.3.7.6='     28 CHR 8 SMF92VDD DDNAME specified on mount from MntEntFSDDName field of BPXYMNTE  '
   map.92.3.7.7='     36 CHR 8 SMF92VTN File system type name from MntEntFSTName field of BPXYMNTE       '
   map.92.3.7.8='     44 CHR 44 SMF92VNM File system name from MntEntFSName field of BPXYMNTE            '
   map.92.3.7.9='     88 NUM 4 SMF92VBL File system block size                                           '
   map.92.3.7.10='    92 NUM 8 SMF92VST Total space in file system in block size units                   '
   map.92.3.7.11='   100 NUM 8 SMF92VSU Allocated space in file system in block size units               '
   map.92.3.7.12='   108 NUM 4 SMF92VSR Reads                                                            '
   map.92.3.7.13='   112 NUM 4 SMF92VSW Writes                                                           '
   map.92.3.7.14='   116 NUM 4 SMF92VDI Directory I/O blocks                                             '
   map.92.3.7.15='   120 NUM 4 SMF92VIR I/O blocks read                                                  '
   map.92.3.7.16='   124 NUM 4 SMF92VIW I/O blocks written                                               '
   map.92.3.7.17='   128 NUM 8 SMF92VBR Bytes read                                                       '
   map.92.3.7.18='   136 NUM 8 SMF92VBW Bytes written                                                    '
   map.92.3.7.19='   144 BIT 1 SMF92VFG Flag byte - reason for move                                      '
   map.92.3.7.19.1='           SMF92VUI     User-initiated                                               '
   map.92.3.7.19.2='           SMF92VRI     Recovery                                                     '
   map.92.3.7.20='   145 BIT 1 SMF92VOF      Flag byte - old status                                      '
   map.92.3.7.20.1='           SMF92VOL     Mounted localy                                               '
   map.92.3.7.20.2='           SMF92VON     Mounted remotely                                             '
   map.92.3.7.20.3='           SMF92VOD     HFS Sysplex client                                           '
   map.92.3.7.20.4='           SMF92VOS     Filesystem owner                                             '
   map.92.3.7.21='   146 BIT 1 SMF92VNF      Flag byte - new status                                      '
   map.92.3.7.21.1='           SMF92VNL     Mounted localy                                               '
   map.92.3.7.21.2='           SMF92VNN     Mounted remotely                                             '
   map.92.3.7.21.3='           SMF92VND     HFS Sysplex client                                           '
   map.92.3.7.21.4='           SMF92VNS     Filesystem owner                                             '

   map.92.3.10.1='     0 TOD 8 SMF92OTO Open time - STCK format                                          '
   map.92.3.10.2='     8 NUM 1 SMF92OTY File Type as defined in BPXYFTYP                                 '
   map.92.3.10.3='     9 BIT 1 SMF92OFG record flag                                                      '
   map.92.3.10.3.1='           SMF92ONF REcord generated by VNode interface service                      '
   map.92.3.10.3.2='           SMF92ONS Network or local socket, 1 = network                             '
   map.92.3.10.3.3='           SMF92OCS Client or server socket 1 = client                               '
   map.92.3.10.4='    12 HEX 4 SMF92OTK Open file token (Matches close)                                  '
   map.92.3.10.5='    16 HEX 4 SMF92OIN Inode number                                                     '
   map.92.3.10.0.2='    16 HEX 4 SMF92OIN Inode number                                                     '
   map.92.3.10.6='    20 HEX 4 SMF92ODN Unique device number                                             '
   map.92.3.10.0.1='    20 HEX 4 SMF92ODN Unique device number                                             '

   map.92.3.11.1='     0 TOD 8 SMF92CTO Open time - STCK format                                          '
   map.92.3.11.2='     8 TOD 8 SMF92CTC Close time - STCK format                                         '
   map.92.3.11.3='    16 NUM 1 SMF92CTY File type as defined in BPXYFTYP                                 '
   map.92.3.11.3.1='  17 BIT 1 SMF92CFG record flag                                                      '
   map.92.3.11.3.2='           SMF92CNF Record generated by VNode interface service                      '
   map.92.3.11.3.3='           SMF92CNS Network or local socket 1 = network                              '
   map.92.3.11.3.4='           SMF92CCS Client or server socket 1 = server                               '
   map.92.3.11.3.5='           SMF92CFC File was cached                                                  '
   map.92.3.11.3.6='           SMF92CDR File had Deny Read on it                                         '
   map.92.3.11.3.7='           SMF92CDW File had Deny Write on it                                        '
   map.92.3.11.4='    20 HEX 4 SMF92CTK Open file token                                                  '
   map.92.3.11.5='    24 HEX 4 SMF92CIN Inode number                                                     '
   map.92.3.11.0.3='    24 HEX 4 SMF92CIN Inode number                                                     '
   map.92.3.11.6='    28 HEX 4 SMF92CDN Unique device number                                             '
   map.92.3.11.0.1='    28 HEX 4 SMF92CDN Unique device number                                             '
   map.92.3.11.7='    32 NUM 4 SMF92CSR Reads                                                            '
   map.92.3.11.8='    36 NUM 4 SMF92CSW Writes                                                           '
   map.92.3.11.9='    40 NUM 4 SMF92CDI Directory I/O blocks                                             '
   map.92.3.11.10='   44 NUM 4 SMF92CIR I/O blocks read                                                  '
   map.92.3.11.11='   48 NUM 4 SMF92CIW I/O blocks written                                               '
   map.92.3.11.12='   52 NUM 8 SMF92CBR Bytes read                                                       '
   map.92.3.11.13='   60 NUM 8 SMF92CBW Bytes written                                                    '
   map.92.3.11.14='   68 CHR 64 SMF92CPN Pathname                                                        '
   map.92.3.11.0.2='   68 CHR 64 SMF92CPN Pathname                                                        '

   map.92.3.16.1='     0 TOD 8 SMF92CTO Open time - STCK format                                          '
   map.92.3.16.2='     8 TOD 8 SMF92CTC Close time - STCK format                                         '
   map.92.3.16.3='    16 NUM 1 SMF92CTY File type as defined in BPXYFTYP                                 '
   map.92.3.16.3.1='  17 BIT 1 SMF92CFG record flag                                                      '
   map.92.3.16.3.2='           SMF92CNF Record generated by VNode interface service                      '
   map.92.3.16.3.3='           SMF92CNS Network or local socket 1 = network                              '
   map.92.3.16.3.4='           SMF92CCS Client or server socket 1 = server                               '
   map.92.3.16.3.5='           SMF92CFC File was cached                                                  '
   map.92.3.16.3.6='           SMF92CDR File had Deny Read on it                                         '
   map.92.3.16.3.7='           SMF92CDW File had Deny Write on it                                        '
   map.92.3.16.4='    20 HEX 4 SMF92CTK Open file token                                                  '
   map.92.3.16.5='    24 HEX 4 SMF92CIN Inode number                                                     '
   map.92.3.16.0.3='    24 HEX 4 SMF92CIN Inode number                                                     '
   map.92.3.16.6='    28 HEX 4 SMF92CDN Unique device number                                             '
   map.92.3.16.0.1='    28 HEX 4 SMF92CDN Unique device number                                             '
   map.92.3.16.7='    32 NUM 4 SMF92CSR Reads                                                            '
   map.92.3.16.8='    36 NUM 4 SMF92CSW Writes                                                           '
   map.92.3.16.9='    40 NUM 4 SMF92CDI Directory I/O blocks                                             '
   map.92.3.16.10='   44 NUM 4 SMF92CIR I/O blocks read                                                  '
   map.92.3.16.11='   48 NUM 4 SMF92CIW I/O blocks written                                               '
   map.92.3.16.12='   52 NUM 8 SMF92CBR Bytes read                                                       '
   map.92.3.16.13='   60 NUM 8 SMF92CBW Bytes written                                                    '
   map.92.3.16.14='   68 CHR 64 SMF92CPN Pathname                                                        '
   map.92.3.16.0.2='   68 CHR 64 SMF92CPN Pathname                                                        '

   map.92.3.12.1='     0 TOD 8 SMF92MTO time of mmap - STCK format                                       '
   map.92.3.12.2='     8 NUM 4 SMF92MSZ Number of bytes being memory mapped                              '
   map.92.3.12.3='    12 HEX 4 SMF92MTK mmap file token (matches token in munmap data section            '
   map.92.3.12.4='    16 HEX 4 SMF92MIN file serial number                                               '
   map.92.3.12.0.2='    16 HEX 4 SMF92MIN file serial number                                               '
   map.92.3.12.5='    20 HEX 4 SMF92MMDN file unique device number                                       '
   map.92.3.12.0.1='    20 HEX 4 SMF92MMDN file unique device number                                       '

   map.92.3.13.1='     0 TOD 8 SMF92MUTO time of mmap - STCK format                                      '
   map.92.3.13.2='     8 TOD 8 SMF92MUTC time of munmap - STCK format                                    '
   map.92.3.13.3='    16 NUM 4 SMF92MUSZ number of bytes being memory mapped                             '
   map.92.3.13.4='    20 HEX 4 SMF92MUTK mmap file token (matches token in mmap data section             '
   map.92.3.13.5='    24 HEX 4 SMF92MUIN file serial number                                              '
   map.92.3.13.0.2='    24 HEX 4 SMF92MUIN file serial number                                              '
   map.92.3.13.0.1='    28 HEX 4 SMF92MUDN file unique device number                                       '
   map.92.3.13.6='    32 NUM 4 SMF92MUIR I/O blocks read                                                 '
   map.92.3.13.7='    36 NUM 4 SMF92MUIW I/O blocks written                                              '

   map.92.3.14.1='     0 TOD 8    SMF92DFT     Delete time - STCK format                                 '
   map.92.3.14.2='     8 NUM 1    SMF92DTY     File Type as defined in BPXYFTYP                          '
   map.92.3.14.3='     9 BIT 1    SMF92DFLG    Flags                               '
   map.92.3.14.3.1='              SMF92DREN   Rename record                        '
   map.92.3.14.4='    12 HEX 4    SMF92DIN     File serial number                  '
   map.92.3.14.0.2='    12 HEX 4    SMF92DIN     File serial number                  '
   map.92.3.14.5='    16 HEX 4    SMF92DINP    File serial number of parent        '
   map.92.3.14.0.3='    16 HEX 4    SMF92DINP    File serial number of parent        '
   map.92.3.14.6='    20 HEX 4    SMF92DDN     File unique device number           '
   map.92.3.14.0.1='    20 HEX 4    SMF92DDN     File unique device number           '
   map.92.3.14.7='    24 CHR 44   SMF92DFS     File System Name                    '
   map.92.3.14.8='    72 CHR 64   SMF92DFN     Name deleted                        '
   map.92.3.14.0.4='    72 CHR 64   SMF92DFN     Name deleted                        '
   map.92.3.14.9='   140 CHR 64   SMF92DFNR    Name renamed                        '
   map.92.3.14.0.5='   140 CHR 64   SMF92DFNR    Name renamed                        '

   map.92.3.15.1='     0 TOD 8  SMF92ACT     Change Time - STCK format                                   '
   map.92.3.15.2='     8 NUM 1  SMF92ATY     File Type. See BPXYFTYP                                     '
   map.92.3.15.3='     9 HEX 1  SMF92AFLG    Flags                                                       '
   map.92.3.15.4='    12 HEX 4  SMF92AIN     File Ino number                                             '
   map.92.3.15.0.3='    12 HEX 4  SMF92AIN     File Ino number                                             '
   map.92.3.15.5='    16 HEX 4  SMF92ADN     File System devno                                           '
   map.92.3.15.0.1='    16 HEX 4  SMF92ADN     File System devno                                           '
   map.92.3.15.6='    20 CHR 44 SMF92AFS    File System Name                                             '
   map.92.3.15.7='    64 BIT 4  SMF92AOLDGENVAL original gen values - same as st_GenValue from BPXYSTAT. '
   map.92.3.15.7.28='           SMF92AOLDSHARELIB Shared Library                                         '
   map.92.3.15.7.29='           SMF92AOLDAPFAUTH Program is APF Auth                                     '
   map.92.3.15.7.30='           SMF92AOLDPROGCTL Program Controlled                                      '
   map.92.3.15.8='    68 CHR 4  SMF92AOLDSECATTRSC original Security flags in character form: A, P, S.   '
   map.92.3.15.9='    68 CHR 1  SMF92AOLDATTRCHAR  > Delimiter                                           '
   map.92.3.15.10='   69 CHR 1  SMF92AOLDSHRLIBC =S if Shared Lib was on                                 '
   map.92.3.15.11='   70 CHR 1  SMF92AOLDAPFAUTHC =A if APF Auth was on                                  '
   map.92.3.15.12='   71 CHR 1  SMF92AOLDPGMCTLC =P if Program Ctl was on                                '
   map.92.3.15.13='   72 BIT 4  SMF92ANEWGENVAL New gen values - same as st_GenValue from BPXYSTAT.      '
   map.92.3.15.13.28='          SMF92ANEWSHARELIB Shared Library                                         '
   map.92.3.15.13.29='          SMF92ANEWAPFAUTH Program is APF Auth                                     '
   map.92.3.15.13.30='          SMF92ANEWPROGCTL Program Controlled                                      '
   map.92.3.15.14='   76 CHR 4  SMF92ANEWSECATTRSC new Security flags in character form: A, P, S.        '
   map.92.3.15.15='   76 CHR 1  SMF92ANEWATTRCHAR  > Delimiter                                           '
   map.92.3.15.16='   77 CHR 1  SMF92ANEWSHRLIBC =S if Shared Lib is on                                  '
   map.92.3.15.17='   78 CHR 1  SMF92ANEWAPFAUTHC =A if APF Auth is on                                   '
   map.92.3.15.18='   79 CHR 1  SMF92ANEWPGMCTLC =P if Program Ctl is on                                 '
   map.92.3.15.19='   80 NUM 4  SMF92AOWNUID File Owner UID                                              '
   map.92.3.15.20='   84 NUM 4  SMF92AOWNGID File Owner GID                                              '
   map.92.3.15.21='   88 CHR 8  SMF92ASECLABEL File SecLabel                                             '
   map.92.3.15.22='   96 HEX 16 SMF92AAUDITFID RACF FID - same as the SMF 80 XXXX_FILE_ID                '
   map.92.3.15.23='  132 HEX 4  SMF92ACWDRC  getcwd Error Return Code                                    '
   map.92.3.15.24='  136 HEX 4  SMF92ACWDRSN getcwd Error Reason Code                                    '
   map.92.3.15.26='  144 CHR 1024   SMF92APN      File Pathname                                          '
   map.92.3.15.0.2='  144 CHR 1024   SMF92APN      File Pathname                                          '

   map.92.3.17.1='     0 TOD 8 SMF92FAWT time when control block is released or interval time            '
   map.92.3.17.2='     8 NUM 1 SMF92FAFT File type as defined in BPXYFTYP                                '
   map.92.3.17.3='     9 BIT 1 SMF92FAFG record flag                                                     '
   map.92.3.17.3.1='           SMF92FAIT    When on SMF92FAWT is SMF interval time.                      '
   map.92.3.17.4='    12 HEX 4 SMF92FAIN Inode number                                                    '
   map.92.3.17.0.3='    12 HEX 4 SMF92FAIN Inode number                                                    '
   map.92.3.17.5='    16 HEX 4 SMF92FADN Unique device number                                            '
   map.92.3.17.0.1='    16 HEX 4 SMF92FADN Unique device number                                            '
   map.92.3.17.6='    20 NUM 4 SMF92FATI Total accesses to file during interval                          '
   map.92.3.17.7='    24 CHR 64 SMF92FAPN Pathname                                                       '
   map.92.3.17.0.2='    24 CHR 64 SMF92FAPN Pathname                                                       '
/*end*/
