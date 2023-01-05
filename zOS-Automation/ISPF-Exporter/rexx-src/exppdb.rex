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
 *  Name: exppdb.rex
 *  Author: Jürgen Holtz
 *
 *  Descriptive Name: Export Automation Policy Data Base
 *
 *  1. Allocate table library
 *  2. Get member list
 *  3. Free table library
 *  4. Process each table member one by one and call ISPF2J to
 *     convert the table to JSON-format.
 *
 *  Notes:
 *
 *  05.01.2023 JMH - Initial version
 */

parse arg parms

 /* --- Parameter section --- */
parse var parms dsn dirpath "(" opts

if dsn = "" | dirpath = "" then do
   say "Required positional arguments are missing"
   exit 1
end
dsn = strip(translate(dsn))
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

/* --- Mainline section --- */
signal on syntax

/* Check if data set exists. Exit in case of error. */
dsn_info = SYSDSN(dsn)
if dsn_info ^= "OK" then do
    say "Input data set:" dsn_info
    signal exit
end

/* Use LISTDS TSO/E command to retrieve member list. */
x = outtrap('listds.')
"LISTDS" dsn members
x = outtrap('OFF')

/* Check, if this is a partitioned data set and has members. */
x = LISTDSI(dsn DIRECTORY)
if SYSDSORG ^= "PO" & SYSDSORG ^= "POU" then do
    say dsn "is not a partitioned data set."
    signal exit
end
if SYSMEMBERS = 0 then do
    say dsn "is empty."
    signal exit
end

/* Skip over first couple lines until members section is found. */
do line = 1 to listds.0
    if pos("--MEMBERS--", listds.line) > 0 then do
        leave line
    end
end

/* Check, if output data set exists and create it if necessary. */
call syscalls 'ON'

address SYSCALL
"chdir" dirpath
if retval = -1 then do
    say "Directory" dirpath "does not exist."
    "mkdir" dirpath 755
end

address TSO
/* Process member by member */
do memx = line+1 to listds.0
    member = strip(listds.memx)
    if quoted = 1 then
       dirpath = '"'||dirpath||'"'
    "ispf2j" dsn member dirpath
end

signal exit


syntax:
    Address TSO
    say "REXX error" rc "in line" SIGL":" "ERRORTEXT"(rc)
    say "SOURCELINE"(SIGL)

exit:
    exit 0
