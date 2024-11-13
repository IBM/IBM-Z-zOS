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
# ** End of Copyright and License **  										 #

import requests

# Define constants
BASE_URL = "https://<host>:<port>/zosmf/restfiles/ds/LIQI.ZMF.TEST(TEST"
HEADERS = {
    "X-CSRF-ZOSMF-HEADER": "",
    "Authorization": "Basic <Base64 encoding of ID and password, joined by a single colon (:)>"
}
CA_BUNDLE_PATH = "/Users/liqi/zosmfca.pem"

# Create 3 members under LIQI.ZMF.TEST.
with requests.Session() as session:
    session.headers.update(HEADERS)
    for i in range(1, 4):
        url = f"{BASE_URL}{i})"
        try:
            response = session.put(url, verify=CA_BUNDLE_PATH)
            response.raise_for_status()
            print(f"Request {i} successful: {response.status_code}")
        except requests.exceptions.RequestException as e:
            print(f"Request {i} failed: {e}")
