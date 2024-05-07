#!/bin/sh
###################################################################
# Copyright 1996 IBM Corp.
#
# Author: Marc J. Warden <marcw@vnet.ibm.com>
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing,
#  software distributed under the License is distributed on an
#  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
#  either express or implied. See the License for the specific
#  language governing permissions and limitations under the
#  License.
#
# -----------------------------------------------------------------
#
# Disclaimer of Warranties:
#
#   The following enclosed code is sample code created by IBM
#   Corporation.  This sample code is not part of any standard
#   IBM product and is provided to you solely for the purpose
#   of assisting you in the development of your applications.
#   The code is provided "AS IS", without warranty of any kind.
#   IBM shall not be liable for any damages arising out of your
#   use of the sample code, even if they have been advised of
#   the possibility of such damages.
#
# -----------------------------------------------------------------

echo "A helper script to clean up the messes that"
echo "interrupted ex and vi sessions leave around."

echo "Invoking /usr/lib/exrecover"
/usr/lib/exrecover
echo "Getting rid of exrecover files and /tmp/VI* files."

exrecoverfiles=$(ex -r >/dev/null && ex -r| sed -n 's/^[^"][^"]*"\([^"]*\)".*$/\1/p')

if [ "$exrecoverfiles" ]
then
	echo "... Invoking ex -r on each file to be recovered:\n${exrecoverfiles}"
	echo "... "
	for i in $exrecoverfiles
	do
		select resp in "trash $i\n" "save $i\n"
		do
			exresp=""
			case $REPLY in
			1 )	exresp=':q'
				;;
			2 )	Answer=""
				while [ -z "$Answer" ]
				do
					echo "Enter name for file"
					read Answer
					if [ -e "$Answer" ]
					then
						echo "file $Answer exists: respecify"
						Answer=""
					fi
				done
				exresp=":w $Answer\n:q"
				;;
			esac

			if [ "$exresp" ]
			then
				echo "$exresp" | ex -r $i
				break
			fi
		done
	done
else
	echo "ex reports there are no files to be recovered."
fi

vifiles=$(find /tmp -level 0 -type f -user $LOGNAME -name VI* -print)
if [ "$vifiles" ]
then
	echo "erasing all those /tmp/VI* files that belong to $LOGNAME"
	echo "doing this with rm -i so you can skip ones you want to keep"
	rm -i $(find /tmp -level 0 -type f -user MARCW -name VI* -print)
fi
