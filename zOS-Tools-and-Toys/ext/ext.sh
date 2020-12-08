#!/bin/sh
###################################################################
# Copyright 2000-2020 IBM Corp.
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
#
# ext extracts files from an archive using ASCII to EBCDIC
# character translation and then goes back and identifies binary
# files (by file suffix) and re-extracts them without character
# translation.
#
# Author: Mike MacIssac <mikemac@us.ibm.com>
#
###################################################################


function usage
{
  echo "Usage: `basename $0` [-v] archive"
  echo "  where 'archive' is a tar/pax file"
  echo "        -v - verbose mode"
  echo ""
  echo "Extract files from archive as text and re-extract binary files with suffixes:"
  echo ".ico .bmp .jpg .gif .Z .gz .tgz .class"
  exit
}

paxFlags="-rf"
if [ $# -eq 0 -o $# -gt 2 ]; then
  usage
elif [ $# = 2 ]; then
  if  [ $1 = "-v" ]; then
    paxFlags="-rvf"
  fi
  shift
fi

# first extract with conversion
if [ "$paxFlags" = "-rvf" ]; then
  echo "extracting with -o to=IBM-1047,from=ISO8859-1 flag ..."
  echo "------------------------------------------------------"
fi
pax $paxFlags $1 -o to=IBM-1047,from=ISO8859-1

# capture the names of all binary files
binaryFiles=`pax -f $1 | awk '/.ico$|.bmp$|.jpg$|.gif$|.Z$|.gz$|.tgz$|.class$/ {print $0}'`

# re-extract binary files with no conversion
if [ $binaryFiles ]; then
  if [ "$paxFlags" = "-rvf" ]; then
    echo "re-extracting the following in binary ..."
    echo "-----------------------------------------"
    echo "$binaryFiles"
  fi
else
  echo "No binary files found"
fi
pax -rf $1 $binaryFiles 2>/dev/null
