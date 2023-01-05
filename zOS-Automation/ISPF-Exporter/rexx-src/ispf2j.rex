/* REXX *************************************************************
 *
 *  Copyright 2023 IBM Corp.                                          
 *                                                                   
 *  Licensed under the Apache License, Version 2.0 (the "License");   
 *  you may not use this file except in compliance with the License.  
 *  You may obtain a copy of the License at                           
 *                                                                   
 *  http://www.apache.org/licenses/LICENSE-2.0                        
 *                                                                   
 *  Unless required by applicable law or agreed to in writing,        
 *  software distributed under the License is distributed on an       
 *  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,      
 *  either express or implied. See the License for the specific       
 *  language governing permissions and limitations under the License.           
 *
 ********************************************************************
 *  Name: ispf2j.rex
 *  Author: Jürgen Holtz
 *
 *  Descriptive Name: ISPF Table to JSON converter
 *
 *  1. Allocate table library
 *  2. Open a specific table
 *  3. Query table keys and variables
 *  4. Process row by row
 *
 *     4.1. For every table column, convert name to JSON-key and
 *          content to JSON-value (string).
 *     4.2. Optionally skip generation of empty (blank) attributes.
 *
 *  5. Close table.
 *  6. Release libraries.
 *
 * Notes:
 *
 *  05.01.2023 JMH - Initial version 
 */

call syscalls 'ON'
msg_stat = MSG("ON")

/* Constants */
ATTR_DSN   = '"dsn":'
ATTR_TABLE = '"table":'
ATTR_ROWS  = '"num_rows":'
ATTR_KEYS  = '"keys":'
ATTR_NAMES = '"names":'
ATTR_DATA  = '"data":'

ATTR_DSN_L   = length(ATTR_DSN)
ATTR_TABLE_L = length(ATTR_TABLE)
ATTR_ROWS_L  = length(ATTR_ROWS)
ATTR_KEYS_L  = length(ATTR_KEYS)
ATTR_NAMES_L = length(ATTR_NAMES)
ATTR_DATA_L  = length(ATTR_DATA)

/* Default options */
log_level = "ERROR"

parse arg parms

/* --- Parameter section --- */
parse var parms dsn tblnam dirpath "(" opts

if dsn = "" | tblnam = "" | dirpath = "" then do
   say "Required positional arguments are missing"
   exit 1
end
dsn = strip(translate(dsn))
tblnam = strip(translate(tblnam))
dirpath = strip(dirpath)

quoted = 0
if pos("'", dirpath) = 1 | pos('"', dirpath) = 1 then do
   /* Remove quotes, in case the directory is quoted */
   quoted = 1
   if pos("'", dirpath) = 1 then
      dirpath = strip(dirpath, "B", "'")
   else
      dirpath = strip(dirpath, "B", '"')
end

if lastpos("/", dirpath) ^= length(dirpath) then
   dirpath = dirpath"/"
filename = tblnam".json"

if opts ^= "" then do
   opts = translate(opts)
   do while (opts ^= "")
      parse var opts opt opts
      if pos("LOGLVL=", opt) = 1 then do
         parse var opt "LOGLVL=" level
         log_level = level
      end
   end

end

call log "INFO", "Called with arguments:" dsn","tblnam","dirpath

/* Variables */
datasets_allocated = 0
libraries_allocated = 0
table_opened = 0

signal on syntax
signal on error name err_label

"Alloc f(tables) da("dsn") shr reuse"
"Alloc f(tabl)   da("dsn") shr reuse"
datasets_allocated = 1

Address ISPEXEC
"CONTROL ERRORS RETURN"
"LIBDEF ISPTLIB LIBRARY ID(tables)"
"LIBDEF ISPTABL LIBRARY ID(tabl)"
libraries_allocated = 1

call log "INFO", "ISPF table data set allocated"

/***************************************************************
**
** Open table for WRITE
**
***************************************************************/
"TBOPEN" tblnam "NOWRITE"
table_opened = 1


/***************************************************************
**
** Query table to understand keys, names and other info
**
***************************************************************/
"TBQUERY" tblnam          ,
   "KEYS("tblkeys") "     ,
   "NAMES("tblnames") "   ,
   "SORTFLDS("sortflds") ",
   "ROWNUM("numrows")"
if rc > 0 then
   call log "ERROR", "Error when attempting TBQUERY "tblnam". RC("rc")"


numrows = numrows+0                 /* get rid of leading 0s */

tblkeys = strip(tblkeys,'L','(')
tblkeys = strip(tblkeys,'T',')')
keys = create_json_array(tblkeys)

tblnames = strip(tblnames, 'L', '(')
tblnames = strip(tblnames, 'T', ')')
names = create_json_array(tblnames)

ptr = 1
buffer = overlay("", "", 1, 4096)
buffer = overlay("{", buffer, 1); ptr = ptr+1

dsnval = dsn /* TODO: remove again */
if pos("'", dsnval) > 0 then do
    dsnval = strip(dsn, "B", "'")
    dsnval = "\'"dsnval"\'"
end
buffer = overlay(ATTR_DSN, buffer, ptr, ATTR_DSN_L); ptr = ptr+ATTR_DSN_L
dsnval = dsn
temp = quoted(dsnval)
buffer = overlay(temp, buffer, ptr, length(temp)); ptr = ptr+length(temp)
buffer = overlay(",", buffer, ptr); ptr = ptr+1

buffer = overlay(ATTR_TABLE, buffer, ptr, ATTR_TABLE_L); ptr = ptr+ATTR_TABLE_L
temp = quoted(tblnam)
buffer = overlay(temp, buffer, ptr, length(temp)); ptr = ptr+length(temp)
buffer = overlay(",", buffer, ptr); ptr = ptr+1

buffer = overlay(ATTR_ROWS, buffer, ptr, ATTR_ROWS_L); ptr = ptr+ATTR_ROWS_L
temp = format(numrows)
buffer = overlay(temp, buffer, ptr, length(temp)); ptr = ptr+length(temp)
buffer = overlay(",", buffer, ptr); ptr = ptr+1

buffer = overlay(ATTR_KEYS, buffer, ptr, ATTR_KEYS_L); ptr = ptr+ATTR_KEYS_L
buffer = overlay(keys, buffer, ptr, length(keys)); ptr = ptr+length(keys)
buffer = overlay(",", buffer, ptr); ptr = ptr+1

buffer = overlay(ATTR_NAMES, buffer, ptr, ATTR_NAMES_L); ptr = ptr+ATTR_NAMES_L
buffer = overlay(names, buffer, ptr, length(names)); ptr = ptr+length(names)
buffer = overlay(",", buffer, ptr); ptr = ptr+1

buffer = overlay(ATTR_DATA, buffer, ptr, ATTR_DATA_L); ptr = ptr+ATTR_DATA_L
buffer = overlay("[", buffer, ptr); ptr = ptr+1

outbuf.1 = strip(buffer)
outbuf.0 = 1
do r = 1 to numrows
   data_line = create_json_object(r)
   if r < numrows then do
      data_line = data_line || ","
   end
   j = outbuf.0 + 1
   outbuf.j = data_line
   outbuf.0 = j
end

j = outbuf.0 + 1
outbuf.j = "]}"
outbuf.0 = j

/* --------------------------------------------------------------------------
 * Prepare for writing the JSON out to a file.
 */
Address SYSCALL
path = strip(dirpath)||strip(filename)
if quoted = 1 then
   path = '"'||path||'"'
call log "INFO", "Create file" path

/* Open the file for write, replace if it already exists */
"open" path,
       O_rdwr+O_creat+O_trunc,
       660

if retval = -1 then do
   call log "ERROR", "Output file >"path"< not opened, error codes",
      errno errnojr
   signal exit
end
fd=retval

/* Write the buffer to the file */
do line = 1 to outbuf.0
   buffer = outbuf.line
   "write" fd "buffer" length(buffer)
   if retval=-1 then do
   call log "ERROR", "Rrecord not written, error codes" errno errnojr
   "close" fd
   signal exit
   end
end

/* Close the file, if it was opened */
"close" fd
call log "INFO", "Output file created."

signal exit


log: procedure expose log_level

   /* some stuff not used at the moment */
   this_level = translate(arg(1))
   this_line  = arg(2)
   target = translate(arg(3))

   /* log level priority */
   levels = "ERROR INFO DEBUG"

   if target = "" | target = "S" then do
      if wordpos(log_level, levels) >= wordpos(this_level, levels) then do
         log_line = time('L') "- ["this_level"] "this_line
         say log_line
      end
   end

   return


quoted: procedure
   string = arg(1)
   return '"'||string||'"'


create_json_object: procedure expose tblnam tblkeys tblnames ATTR_CRP ,
                         ATTR_CRP_L

   crp = arg(1)

   ispf = "TBSKIP"
   ispf tblnam
   if rc > 0 then do
      if rc > 8 then do
         signal ispf_error
      end
      else
         return ""
   end
   ispf = "TBGET"
   ispf tblnam
   if rc > 0 then
      signal ispf_error

   columns = tblkeys tblnames
   numcols = words(columns)
   buffer = overlay("", "", 1, 16384)
   p = 1
   buffer = overlay("{", buffer, p)
   p = 2

   do c = 1 to numcols
      attrname = word(columns, c)
      attrname_len = length(attrname)
      attrvalu = value(attrname)
      attrvalu = escape_special_chars(attrvalu)
      attrvalu_len = length(attrvalu)
      buffer = overlay('"', buffer, p); p = p+1
      buffer = overlay(attrname, buffer, p, attrname_len); p = p+attrname_len
      buffer = overlay('":', buffer, p); p = p+2
      buffer = overlay('"', buffer, p); p = p+1
      buffer = overlay(attrvalu, buffer, p, attrvalu_len); p = p+attrvalu_len
      buffer = overlay('"', buffer, p); p = p+1
      if c < numcols then do
         buffer = overlay(",", buffer, p); p = p+1
      end
   end

   buffer = overlay("}", buffer, p)
   return strip(buffer)


escape_special_chars: procedure
/*
 It is important that the JSON-document contains only characters that
 are allowed within its specification. See also:
 https://www.json.org/json-en.html

 E.g. some characters found using IBM1047 codepage like the paragraph
 sign, the umlaut and the sharp s lead to errors if they weren't
 escaped.

 In JSON, the double quote, the slash and the backslash have to be
 escaped using a leading backslash, like so: \" or \\.

 Other code points could be escaped using a unicode in the form \uxxxx,
 where xxxx is a 4-character hexadecimal code representing the UTF-8
 character. The character with the hexadecimal code point 'FF'x that is
 used in some ISPF tables will be converted to \uFFFF. In both code pages
 these code points represent non-characters.

 838881997A5AB55B6C50E0614D5D7E6FE0614D    43CCDC63ECFC59
 c h a r : ! § $ % & \ / ( ) = ? \ / (     ä ö ü Ä Ö Ü ß

 5D7E6F5C4EA1CC437B5E6D604B6B6E4C4FE07F79
 ) = ? * + ~ ö ä # ; _ - . , > < | \ " `
*/
   val = arg(1)
   if pos('FF'x, val) > 0 |,
      pos('"', val) > 0 |,
      pos('\', val) > 0 |,
      pos('/', val) > 0 then
   do
      l_val = length(val)
      new_val = overlay('','',1, l_val*2)
      p = 1
      do i = 1 to l_val
         c = substr(val,i,1)
         if c = '"' | c = '\' | c = '/' then do
            new_val = overlay("\"c, new_val, p, 2)
            p = p+2
         end
         else if c = 'FF'x then do
            new_val = overlay("\uFFFF", new_val, p, 6)
            p = p+6
         end
         else do
            new_val = overlay(c, new_val, p, 1)
            p = p+1
         end
      end
      val = strip(new_val)
   end
   return val


create_json_array: procedure
   elements = arg(1)
   num_elem = words(elements)
   if num_elem <= 0 then
      return "[]"

   buffer = overlay("", "", 1, 1024)
   p = 1
   buffer = overlay("[", buffer, p)
   p = 2
   do e = 1 to num_elem
      el = word(elements, e)
      ellen = length(el)
      buffer = overlay('"', buffer, p); p = p+1
      buffer = overlay(el, buffer, p, ellen); p = p+ellen
      buffer = overlay('"', buffer, p); p = p+1
      if e < num_elem then do
         buffer = overlay(",", buffer, p); p = p+1
      end
   end
   buffer = overlay("]", buffer, p)
   return strip(buffer)


err_label:
   if table_opened = 0 then
      call log "ERROR", "Service TBOPEN "tblnam" NOWRITE failed. RC("rc")"
   signal exit


syntax:
   Address TSO
   say "REXX error" rc "in line" SIGL":" "ERRORTEXT"(rc)
   say "SOURCELINE"(SIGL)

exit:
/***************************************************************
**
** Close table without saving
**
***************************************************************/
Address ISPEXEC
"CONTROL ERRORS RETURN"
if table_opened = 1 then do
   "TBEND" tblnam
   if rc > 0 then
      call log "ERROR", "Service TBEND "tblnam" unsuccesful. RC("rc")"
end

if libraries_allocated = 1 then do
   "LIBDEF ISPTABL"
   "LIBDEF ISPTLIB"
end


Address TSO
if datasets_allocated = 1 then do
   "Free f(tables)"
   "Free f(tabl)"
end

exit 0
