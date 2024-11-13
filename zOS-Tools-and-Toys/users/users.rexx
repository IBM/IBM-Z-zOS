/* REXX ***************************************************************
**                                                                   **
** Copyright 1997 IBM Corp.                                          **
**                                                                   **
**  Licensed under the Apache License, Version 2.0 (the "License");  **
**  you may not use this file except in compliance with the License. **
**  You may obtain a copy of the License at                          **
**                                                                   **
**     http://www.apache.org/licenses/LICENSE-2.0                    **
**                                                                   **
**  Unless required by applicable law or agreed to in writing,       **
**  software distributed under the License is distributed on an      **
**  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,     **
**  either express or implied. See the License for the specific      **
**  language governing permissions and limitations under the         **
**  License.                                                         **
**                                                                   **
** ----------------------------------------------------------------- **
**                                                                   **
** Disclaimer of Warranties:                                         **
**                                                                   **
**   The following enclosed code is sample code created by IBM       **
**   Corporation.  This sample code is not part of any standard      **
**   IBM product and is provided to you solely for the purpose       **
**   of assisting you in the development of your applications.       **
**   The code is provided "AS IS", without warranty of any kind.     **
**   IBM shall not be liable for any damages arising out of your     **
**   use of the sample code, even if they have been advised of       **
**   the possibility of such damages.                                **
**                                                                   **
**                                                                   **
**********************************************************************/

/* This REXX exec displays a message that shows the number of
** shell sessions and unique users logged on to the system.
** It is useful to add to your .profile or .bashrc so it displays
** upon login.
**/

verbose = 0

parse arg options

do i = 1 to words(options)
  token = word(options,i)
  if token = '-a' then verbose = 1
end

address syscall 'pipe p.'
'who | sort > /dev/fd' || p.2

address syscall 'close' p.2
address mvs 'execio * diskr' p.1 '(stem out.'

users = ''
ttys. = ''

do i=1 to out.0
  parse var out.i user tty .
  if find(users, user) = 0 then users = users user
  ttys.user = ttys.user tty
end

say "There are" out.0 "shell sessions and" words(users) "unique users."

if verbose then do i = 1 to words(users)
  user = word(users,i)
  say left(user,10) || ttys.user
end

