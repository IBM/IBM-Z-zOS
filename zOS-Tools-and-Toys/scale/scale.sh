#!/bin/sh
###################################################################
# Copyright 1994 IBM Corp.
#
# Author: John Pfuntner <pfuntner@pobox.com>
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
# This displays an 80-column scale on the screen.  It can be useful
# for adjusting program output to fit without wrapping.

tens=''
units=''
col=0
while let "(col=col+1) <= 80"
do
  ((ten = col / 10))
  ((unit = col % 10))
  tens=$tens$ten
  units=$units$unit
done
echo $tens
echo $units
