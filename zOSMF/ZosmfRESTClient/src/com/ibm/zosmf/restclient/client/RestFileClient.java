/* ** Beginning of Copyright and License **									 */
/*																			 */
/* Copyright 2018 IBM Corp.              									 */                             
/*                                                   						 */                 
/* Licensed under the Apache License, Version 2.0 (the "License"); 			 */    
/* you may not use this file except in compliance with the License. 		 */ 
/* You may obtain a copy of the License at                          		 */
/*                                                                    		 */
/* http://www.apache.org/licenses/LICENSE-2.0                   			 */     
/*                                                                   		 */
/* Unless required by applicable law or agreed to in writing, software		 */
/* distributed under the License is distributed on an "AS IS" BASIS,  		 */
/* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  */
/* See the License for the specific language governing permissions and 		 */
/* limitations under the License.                    						 */
/*																			 */
/* ** End of Copyright and License **  										 */

package com.ibm.zosmf.restclient.client;

import com.ibm.zosmf.restclient.basic.RestConnection;
import java.io.IOException;

public class RestFileClient {
	private RestConnection conn = new RestConnection();
	private String baseUrl = "https://pev076.pok.ibm.com/zosmf";
	private String pluginUrl = "/restfiles/ds";
	private String dsName = null;
	
	protected void setDataSetName(String dsName) throws IOException{
		if (dsName != null && !dsName.isEmpty()) {			
			this.dsName = dsName;
		} else {
			throw new IOException("dsName should not be empty.");
		}
	}
	
	/**
	 * Initialized work of single request to z/OSMF Data Set and File REST Interface
	 * 1. add authorization
	 * 2. bypass CSRF check from server
	 */
	private void init() {
		// basic authorization way, aWJtdXNlcjpzeXMx is the based64 encode of IBMUSER:SYS1
		conn.addHeader("Authorization", "Basic aWJtdXNlcjpzeXMx");
		// "X-CSRF-ZOSMF-HEADER" is a header supported by z/OSMF to bypass the CSRF check when RESTful interface is used
		conn.addHeader("X-CSRF-ZOSMF-HEADER", "zosmf");
	}
	
	public void getDataSetContent() throws IOException{
		init();
		
		// build up url of specify dataset
		setDataSetName("ZTRIAL.ZOSMF.RESTDS");
		String url = baseUrl + pluginUrl + "/" + dsName;
		conn.setUrl(url);
		conn.GET();
		String resStr = conn.getResponseAsString(null);
	}
	
	public void writeDataSetContent() throws IOException{
		init();
		
		// build up url of specify dataset
		setDataSetName("ZTRIAL.ZOSMF.RESTDS");
		String url = baseUrl + pluginUrl + "/" + dsName;
		conn.setUrl(url);
		// wirte one line into dataset ZTRIAL.ZOSMF.RESTDS
		conn.setBody("Welcome to use z/OSMF REST API!");
		conn.PUT();
		String resStr = conn.getResponseAsString(null);
	}
	
	public static void main(String[] args) {
		RestFileClient rfc1 = new RestFileClient();
		RestFileClient rfc2 = new RestFileClient();
		RestFileClient rfc3 = new RestFileClient();
		
		try {
			rfc1.getDataSetContent();
			rfc2.writeDataSetContent();
			rfc3.getDataSetContent();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}

}
