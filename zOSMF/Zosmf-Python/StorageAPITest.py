# ** Beginning of Copyright and License **									 #
#																			 #
# Copyright 2024 IBM Corp.              									 #
#                                                   						 #
# Licensed under the Apache License, Version 2.0 (the "License"); 			 #
# you may not use this file except in compliance with the License. 		     #
# You may obtain a copy of the License at                          		     #
#                                                                    		 #
# http://www.apache.org/licenses/LICENSE-2.0                   			     #
#                                                                   		 #
# Unless required by applicable law or agreed to in writing, software		 #
# distributed under the License is distributed on an "AS IS" BASIS,  		 #
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.   #
# See the License for the specific language governing permissions and        #
# limitations under the License.                                             #
#																			 #
# ** End of Copyright and License **  

#
# This sample python script is designed to be invoked locally from z/OS      #
# system. It's highly recommended to change verify=False to verify=True      #
# while invoking REST API if script will be invoked from remote system.      #
#

import requests
import json
import sys
import argparse
import base64
from requests import HTTPError
from requests import status_codes

#################################################
# Begin : Read and validate command line argument 
#################################################
if len(sys.argv) < 2:
    print ("You failed to provide required input on the command line!")
    sys.exit(1)
    
print ('argument list', sys.argv)

# Initialize parser
parser = argparse.ArgumentParser(description="z/OS Storage Management",
                                 formatter_class=argparse.ArgumentDefaultsHelpFormatter)
 
# Adding positional argument
parser.add_argument("ObjectType", help = "(Required)Storage object type to retrieve. Valid values are \
                    DC (Data class), SC (Storage Class), SG (Storage Group), VOL (Volume)")

# Adding optional argument
parser.add_argument("-host", "--Host", help = "(Required) z/OSMF hostname")
parser.add_argument("-port", "--Port", help = "(Required) z/OSMF port")
parser.add_argument("-u", "--Userid", help = "(Optional) z/OS Userid", default = "")
parser.add_argument("-p", "--Password", help = "(Optional) Password of user", default = "")
parser.add_argument("-cert", "--ClientCertFile", help = "(Optional) Client certificate file name", default = "")
parser.add_argument("-key", "--ClientCertKeyFile", help = "(Optional) Client certificate Key file name", default = "")
parser.add_argument("-o", "--Output", help = "(Optional) Output file to write retrieved storage objects",
                    default="StorageMgmtObjects.json")
parser.add_argument("-sgName", "--StorageGroupName", 
                    help = "(Optional) Specify storage group name to obtain \
                            The value must meet the following criteria: \
                            Contains 1 - 8 alphanumeric characters \
                            Begins with an alphabetic or national character. National characters are $, #, and @ \
                            This property is not case-sensitive \
                            Wildcards are not allowed",
                    default = "")
parser.add_argument("-dcName", "--DataClassName", 
                    help = "(Optional) Specify data class name to obtain \
                            The value must meet the following criteria: \
                            Contains 1 - 8 alphanumeric characters \
                            Begins with an alphabetic or national character. National characters are $, #, and @ \
                            This property is not case-sensitive \
                            Wildcards are not allowed",
                    default = "")
parser.add_argument("-scName", "--StorageClassName", 
                    help = "(Optional) Specify Storage class name to obtain \
                            The value must meet the following criteria: \
                            Contains 1 - 8 alphanumeric characters \
                            Begins with an alphabetic or national character. National characters are $, #, and @ \
                            This property is not case-sensitive \
                            Wildcards are not allowed",
                    default = "")
parser.add_argument("-volser", "--VolumeSerialNumber", 
                    help = "(Optional) Specify volume serial number to obtain \
                           The value must be a complete serial number, 1 - 6 characters, no wildcard characters. \
                           Partial volume numbers are not matched. The value is not case sensitive.",
                    default = "")
parser.add_argument("-detail", "--DetailData", 
                    help = "(Optional) Specifies whether the response contains detailed information. \
                            The value must be Y or N. A Y value requests detailed information. A N value requests summary information. \
                            The default value is N",
                    default = "N")

# Read arguments from command line
args = parser.parse_args()

print("************************* Input Properties ********************************")
if args.ObjectType:
    print("Obtaining storage object: % s" % args.ObjectType)

if args.Host:
    print("z/OSMF Host Name is: % s" % args.Host)
else:
    print("z/OSMF Host name is required")
    sys.exit(1)
if args.Port:
    print("z/OSMF Port number is: % s" % args.Port)
else:
    print("z/OSMF Port number is required")
    sys.exit(1)

# Check for optional command line arguments
if args.Userid:
    print("z/OS Userid is: % s" % args.Userid)
    if args.Password:
       print("z/OS Password is: ******")
    else:
       print("Password is required")
       sys.exit(1)

if args.ClientCertFile:
    print("Client Certificate File Name is: % s" % args.ClientCertFile)
    certFile = args.ClientCertFile
    if args.ClientCertKeyFile:
        print("Client Certificate Key File Name is: % s" % args.ClientCertKeyFile)
        keyFile = args.ClientCertKeyFile
    else:
        print("When Client Certificate file name  is specified, Client Certificate key file name is also required")
        sys.exit(1)
else:
    if not args.Userid:
       print("Either userid/password Or Client Certificate/Key file names are required")
       sys.exit(1)

if args.Output:
    print("Output file to save storage object: % s" % args.Output)
    outputFile = args.Output
else:
    print("Output file to save storage object: StorageMgmtObjects.json")
    outputFile = "StorageMgmtObjects.json"

if args.ObjectType == "SG":
    reqType = "storagegroups"
    if args.StorageGroupName != "":
      print("Obtain stroage objects for Storage Group %s" % (args.StorageGroupName))
    else:
      print("Retrieving storage objects for all Storage Groups")

if args.ObjectType == "SC":
    reqType = "storageclasses"
    if args.StorageClassName != "":
      print("Obtain stroage objects for Storage class %s" % (args.StorageClassName))
    else:
      print("Retrieving storage objects for all Storage classes")

if args.ObjectType == "DC":
    reqType = "dataclasses"
    if args.DataClassName != "":
      print("Obtain stroage objects for Data class %s" % (args.DataClassName))
    else:
      print("Retrieving storage objects for all Data classes")

if args.ObjectType == "VOL":
    reqType = "volumes"
    if args.VolumeSerialNumber != "":
      print("Obtain stroage objects for Volume Serial %s" % (args.VolumeSerialNumber))
    else:
      print("Retrieving storage objects for all SMS managed volume serial numbers")

###############################################
# End : Read and validate Command line argument
###############################################

####################################################
#  Begin : Construct URL with command line arguments 
####################################################
from requests.auth import HTTPBasicAuth

url = "https://" + args.Host + ":" + args.Port


reqUrl = url+f"/zosmf/storage/rest/v1/" \
         f"{reqType}"


if args.ObjectType == "SG":
    if args.StorageGroupName != "":
        reqUrl = reqUrl +  "/" + f"{args.StorageGroupName}" 
else:
    if args.ObjectType == "SC":
        if args.StorageClassName != "":
           reqUrl = reqUrl + "/" + f"{args.StorageClassName}"
    else:
        if args.ObjectType == "DC":
            if args.DataClassName != "":
               reqUrl = reqUrl +  "/" + f"{args.DataClassName}"
        else:
            if args.ObjectType == "VOL":
               if args.VolumeSerialNumber != "":
                  reqUrl = reqUrl + "/" + f"{args.VolumeSerialNumber}"

    
reqUrl = reqUrl + "?detail-data=" + f"{args.DetailData}"

##################################################
#  End : Construct URL with command line arguments 
##################################################

########################################################
# Begin : Construct REST API Payload and invoke REST API 
########################################################

headersList = {
 "Referer": url
}

payload = ""
try:
    if args.Userid:
       response = requests.request("GET", reqUrl, data=payload,  headers=headersList, 
                            auth=HTTPBasicAuth(args.Userid, args.Password),
                            verify=False)
    else:
        cert = (certFile,keyFile)
        response = requests.request("GET", reqUrl, data=payload, headers=headersList, 
                            cert=cert,
                            verify=False)
except HTTPError as e:
    print("REST API failed with error code %s" %e)
    sys.exit(1)

########################################################
# End : Construct REST API Payload and invoke REST API 
########################################################

#####################################
#  Begin : Process REST API Resposnse 
#####################################

if response.status_code != 200:
    print("***************************************************************")
    print("REST API failed with error status code %s : %s" % (response.status_code,status_codes._codes[response.status_code][0]))
    print("***************************************************************")
    sys.exit(1)

with open(outputFile, "w") as f:
     r = json.loads(response.text)
     f.write(json.dumps(r, sort_keys=True, indent=4))
     print("******************************  Results  ********************************")
     print("Storage objects retrieved successfully, check %s for details" % outputFile)
     
     if args.ObjectType == "SG":
        for record in r:
                if record["spaceUsed"] > 0:
                    if record["spaceUsed"] * 100 / record["totalSpace"] > 85:
                      print("WARNING : Storage group %s is more than 85 percent Used" % (record["storageGroupName"]))

     print("*************************************************************************")