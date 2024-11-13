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
parser = argparse.ArgumentParser(description="z/OS Parmlib Validator",
                                 formatter_class=argparse.ArgumentDefaultsHelpFormatter)
 
# Adding positional argument
parser.add_argument("ParmlibType", help = "(Required) Parmlib Type to Validate")

# Adding optional argument
parser.add_argument("-host", "--Host", help = "(Required) z/OSMF hostname")
parser.add_argument("-port", "--Port", help = "(Required) z/OSMF port")
parser.add_argument("-u", "--Userid", help = "(Optional) z/OS Userid", default = "")
parser.add_argument("-p", "--Password", help = "(Optional) Password of user", default = "")
parser.add_argument("-cert", "--ClientCertFile", help = "(Optional) Client certificate file name", default = "")
parser.add_argument("-key", "--ClientCertKeyFile", help = "(Optional) Client certificate Key file name", default = "")
parser.add_argument("-o", "--Output", help = "(Optional) Output file to write validation results",
                    default="ParmlibTestResults.json")
parser.add_argument("-lD", "--LoadDataset", 
                    help = "(Optional) Specify dataset name that contains LOADxx member for validation of non active LOAD",
                    default = "")
parser.add_argument("-lM", "--LoadMember", 
                    help = "(Optional) Specify LOAD member name for validation of non active LOAD",
                    default = "")
parser.add_argument("-lV", "--LoadVolSer", 
                    help = "(Optional) Specify VOLSER for LOAD dataset if the dataset is not cataloged",
                    default = "")
parser.add_argument("-s", "--System", 
                    help = "(Optional) Specify z/OS System name for validation of parmlib from active LOAD",
                    default = "")
parser.add_argument("-dN", "--DatasetName", 
                    help = "(Optional) Specify Dataset name for validation of speicifc parmlib from dataset",
                    default = "")
parser.add_argument("-mN", "--MemberName", 
                    help = "(Optional) Specify Member name for validation of speicifc parmlib from dataset",
                    default = "")
parser.add_argument("-vN", "--VolumeSerialNumber", 
                    help = "(Optional) Specify VOLSER of the parmlib dataset if the dataset is not cataloged",
                    default = "")
parser.add_argument("-dV", "--deepValidation", help = "(Optional) Specify 'true' to perform deep validation for specified LOAD. \
                     Deep validation is not supported for parmlib type other than LOAD.",
                    default = "false")
# parser.add_argument("deep", help="Perform deep validation for LOAD or IEASYS")


# Read arguments from command line
args = parser.parse_args()
 
if args.ParmlibType:
    print("Performing Validation For: % s" % args.ParmlibType)

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

if args.deepValidation =='true':
   if args.ParmlibType != "LOAD":
        print("Deep validation is not supported for parmlib type %s" % args.ParmlibType)
        sys.exit(1)
   else:
      print("Performing deep validation of entire parmlib setup starting with LOAD member")

if args.Output:
    print("Output file for validation result: % s" % args.Output)
    outputFile = args.Output
else:
    print("Output file for validation result: ParmlibTestResults.json")
    outputFile = "ParmlibTestResults.json"

if args.LoadDataset:
    if args.LoadMember:
      print("Performing validation of LOAD %s(%s)" % (args.LoadDataset, args.LoadMember))
    else:
      print("Load member name is required when Load dataset is specified")
      sys.exit(1)

if args.LoadMember:
    if args.LoadDataset == "":
      print("Load Dataset name is required when Load Member is specified")
      sys.exit(1)
      
if args.DatasetName:
    if args.LoadDataset:
      print("Both Load dataset name and dataset name are not allowed")
      sys.exit(1)
    if args.MemberName:
      print("Performing validation of parmlib from Data set %s(%s)" % (args.DatasetName, args.MemberName))
    else:
      print("Load member name is required when Load dataset is specified")
      sys.exit(1)

if args.MemberName:
    if args.DatasetName == "":
      print("Parmlib Dataset name is required when member name is specified")
      sys.exit(1)

###############################################
# End : Read and validate Command line argument
###############################################

####################################################
#  Begin : Construct URL with command line arguments 
####################################################
from requests.auth import HTTPBasicAuth

url = "https://" + args.Host + ":" + args.Port


reqUrl = url+f"/zosmf/parmlib/v1/" \
         f"{args.ParmlibType}/" \
         f"validate"

if args.deepValidation == 'true':
    reqUrl = reqUrl + "?deep=true"
else:
    reqUrl = reqUrl + "?deep=false"

if args.System != "":
    reqUrl = reqUrl + "&system=" + f"{args.System}"

if args.ParmlibType == "LOAD":
    if args.LoadDataset != "":
        reqUrl = reqUrl + "&memLOAD=" + f"{args.LoadMember}"
        reqUrl = reqUrl + "&datasetLOAD=" + f"{args.LoadDataset}"
       

if args.ParmlibType == "LOAD":
    if args.LoadDataset != "":
        reqUrl = reqUrl + "&memLOAD=" + f"{args.LoadMember}"
        reqUrl = reqUrl + "&datasetLOAD=" + f"{args.LoadDataset}"
    if args.System != "":
          reqUrl = reqUrl + "&system=" + f"{args.System}"

if args.DatasetName != "":
          reqUrl = reqUrl + "&member=" + f"{args.MemberName}"
          reqUrl = reqUrl + "&dataset=" + f"{args.DatasetName}"


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
warningCount = 0
try:
    if args.Userid:
       response = requests.request("PUT", reqUrl, data=payload,  headers=headersList, 
                            auth=HTTPBasicAuth(args.Userid, args.Password),
                            verify=False)
    else:
        cert = (certFile,keyFile)
        response = requests.request("PUT", reqUrl, data=payload, headers=headersList, 
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
     results = r['result']
     if (results == "failed"):
        
        f.write(json.dumps(r, sort_keys=True, indent=4))

        failedCount = r['numberOfFailedMembers']
        jsonData = r['details']
        print("***************************************************************")
        for record in jsonData:
           if isinstance(jsonData[record], list):
              for values in jsonData[record]:
                if 'validationResult' in values:
                    if values["validationResult"] == "failed":
                      print("Failed member %s(%s)" % (values["dataset"], values["member"]))
                if 'Warning' in values:
                    print("Warning is reported for default member %s" % (values["member"]))
                    warningCount = warningCount + 1
           if 'numOfFailure' in record:
               print("Found %s failures in %s member" % (jsonData["numOfFailure"],jsonData["member"]))

         #  else:
          #    if record["validationResult"] == "failed":
             #    print("%s Failure in member Name %s(%s)" % (record["numOfFailure"], record["member"]))
        print("***************************************************************")
        print("Summary : %s parmlib members detected errors, %s parmlib members detected warnings " % (failedCount, warningCount))
        print("Check %s file for details"  % outputFile)
        print("***************************************************************")
     else :
         f.write(json.dumps(r, sort_keys=True, indent=4))
         print("***************************************************************")
         print("validation Successful, check %s for details" % outputFile)
         print("***************************************************************")