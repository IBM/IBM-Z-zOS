#!/bin/sh
#
# ext extracts files from an archive using ASCII to EBCDIC character translation and then 
# goes back and identifies binary files (by file suffix) and re-extracts them without 
# character translation.
#
# Copyright IBM Corp. 2000
#
# Author: Mike MacIssac <mikemac@us.ibm.com>


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
