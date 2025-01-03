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
# See the License for the specific language governing permissions and 		 #
# limitations under the License.                    						 #
#																			 #
# ** End of Copyright and License **  

#
# This sample python script is designed to be invoked locally from z/OS      #
# system. It's highly recommended to change verify=False to verify=True      #
# while invoking REST API if script will be invoked from remote system.      #
#										 #

import requests
import json
import sys
import argparse
import inspect
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
parser = argparse.ArgumentParser(description="z/OS Security Configuration",
                                 formatter_class=argparse.ArgumentDefaultsHelpFormatter)
 
# Adding positional argument
parser.add_argument("Action", help = "(Optional)Security Action to perform. Specify 'Validate' to validate permission or \
                    'Provision' to drive permit operation",
                    default = "Validate")

# Adding optional argument
parser.add_argument("-host", "--Host", help = "(Required) z/OSMF hostname")
parser.add_argument("-port", "--Port", help = "(Required) z/OSMF port")
parser.add_argument("-u", "--Userid", help = "(Optional) z/OS Userid", default = "")
parser.add_argument("-p", "--Password", help = "(Optional) Password of user", default = "")
parser.add_argument("-cert", "--ClientCertFile", help = "(Optional) Client certificate file name", default = "")
parser.add_argument("-key", "--ClientCertKeyFile", help = "(Optional) Client certificate Key file name", default = "")
parser.add_argument("-o", "--Output", help = "(Optional) Output file to write validation results",
                    default="SecurityValidationResults.json")
parser.add_argument("-rP", "--ResourceProfile", 
                    help = "(Required) Specify SAF resource profile name for access validation or permission",
                    default = "")
parser.add_argument("-rC", "--ResourceClass", 
                    help = "(required) Specify SAF resource class name associated with resource name",
                    default = "")
parser.add_argument("-aT", "--AccessType", 
                    help = "(Optional) Specify access type to be validated or permitted. Valid access types are \
                        'READ', 'UPDATE', 'CONTROL', 'ALTER'",
                    default = "READ")
parser.add_argument("-rU", "--RequestedUserid", 
                    help = "(Required) Specify USERID for which SAF resource profile permission is validation or granted",
                    default = "")


args = parser.parse_args()
 

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

if args.Userid and args.ClientCertFile:
    print("Please specify either Userid or Certificate, both are not supported")

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
        print("When Client Certificate file name is specified, Client Certificate key file name is also required")
        sys.exit(1)
else:
    if not args.Userid:
       print("Either userid/password Or Client Certificate/Key file names are required")
       sys.exit(1)

if args.Output:
    print("Output file for validation result: % s" % args.Output)
    outputFile = args.Output
else:
    print("Output file for validation result: SecurityValidationResults.json")
    outputFile = "SecurityValidationResults.json"

if args.RequestedUserid:
    if args.RequestedUserid == "":
      print("Userid to validate or grant permission is required")
      sys.exit(1)
else:
    print("Requested userid is required")
    sys.exit(1)

if args.ResourceProfile:
    if args.ResourceProfile == "":
      print("SAF Resource Profile name is required")
      sys.exit(1)
else:
    print("SAF Resource Profile Name is required")
    sys.exit(1)

if args.ResourceClass:
    if args.ResourceClass == "":
      print("SAF Resource Class name is required")
      sys.exit(1)
else:
    print("SAF Resource Class name is required")
    sys.exit(1)
    
if args.AccessType:
    if (args.AccessType == "READ" or args.AccessType == "ALTER" or
       args.AccessType == "UPDATE" or args.AccessType == "CONTROL") :
      print("Access type for validation is: % s" % args.AccessType)
    else:
      print("Access type value is incorrect. Valid values are 'NONE', 'READ', 'UPDATE', \
            'CONTROL' or 'EXECUTE'")
      sys.exit(1)
else:
    print("Access Type is required")
    sys.exit(1)

if args.Action:
    if args.Action == "validate" or args.Action == "provision" :
      print("Performing %s action for SAF resource %s in Class %s for userid %s" % (args.Action, args.ResourceProfile, args.ResourceClass, args.RequestedUserid))
    else:
        print("Only 'provision' or 'validate' actions are allowed")
        sys.exit(1)

###############################################
# End : Read and validate Command line argument
###############################################

####################################################
#  Begin : Construct URL with command line arguments 
####################################################
from requests.auth import HTTPBasicAuth

url = "https://" + args.Host + ":" + args.Port


reqUrl = url+f"/zosmf/config/security/v1/" \
         f"{args.Action}"f"?userid="f"{args.RequestedUserid}"

##################################################
#  End : Construct URL with command line arguments 
##################################################

########################################################
# Begin : Construct REST API Payload and invoke REST API 
########################################################
headersList = {
 "Accept": "*/*",
 "Content-Type": "application/json",
 "Referer": url
}

payload = json.dumps({"resourceItems": [{
      "resourceProfile": f"{args.ResourceProfile}",
      "resourceClass": f"{args.ResourceClass}",
      "access": f"{args.AccessType}"
     }]
})


try:
    if args.Userid:
       response = requests.request("POST", reqUrl, data=payload,  headers=headersList, 
                            auth=HTTPBasicAuth(args.Userid, args.Password),
                            verify=False)
    else:
        cert = (certFile,keyFile)
        response = requests.request("POST", reqUrl, data=payload, headers=headersList, 
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
    if response.status_code == 400:
       r = json.loads(response.text)
       print("Additional Message %s" % (r['messageText']))
    print("***************************************************************")
    sys.exit(1)

with open(outputFile, "w") as f:
     r = json.loads(response.text)
     jsonData = r['resourceItems']
     print("*************************** Results ******************************")
    
     for record in jsonData:
                    if record["status"] == "failed" or record["status"] == "unknown":
                        f.write(json.dumps(r, sort_keys=True, indent=4))
                        print(inspect.cleandoc("""UserId %s is not permitted for %s access to\n\
                               resource profile %s in resource class %s""" % (args.RequestedUserid,
                                                                              args.AccessType,
                                                                              args.ResourceProfile,
                                                                              args.ResourceClass)))
                        print("Check %s file for details"  % outputFile)
                    else :
                        f.write(json.dumps(r, sort_keys=True, indent=4))
                        print(inspect.cleandoc("""UserId %s is permitted for %s access to\n\
                                resource profile %s in resource class %s""" % (args.RequestedUserid,
                                                                               args.AccessType,
                                                                               args.ResourceProfile,
                                                                               args.ResourceClass)))
                        print("validation Successful, check %s for details" % outputFile)
     print("***************************************************************")

#####################################
#  End : Process REST API Resposnse 
#####################################