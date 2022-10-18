/*                                                                   */
/* Copyright 2021 IBM Corp.                                          */
/*                                                                   */
/* Licensed under the Apache License, Version 2.0 (the "License");   */
/* you may not use this file except in compliance with the License.  */
/* You may obtain a copy of the License at                           */
/*                                                                   */
/* http://www.apache.org/licenses/LICENSE-2.0                        */
/*                                                                   */
/* Unless required by applicable law or agreed to in writing,        */
/* software distributed under the License is distributed on an       */
/* "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,      */
/* either express or implied. See the License for the specific       */
/* language governing permissions and limitations under the License. */
/*                                                                   */

package com.ibm.smf.was.common;

import java.io.UnsupportedEncodingException;

import com.ibm.smf.format.SmfRecord;
import com.ibm.smf.format.UnsupportedVersionException;

public class WASSmfRecord extends SmfRecord {

	  public WASSmfRecord(SmfRecord aSmfRecord)
			  throws UnsupportedVersionException, UnsupportedEncodingException {
	  
			   super(aSmfRecord); // pushes the print stream once
	  }
	  
	  //----------------------------------------------------------------------------
	  /** Returns the record subtype as a String.
	   * @return record subtype as a String.
	   */
	  public String subtypeToString() {
	    
	    if (m_type == WASConstants.SmfRecordType) {
	      
	      switch (m_subtype) {
	        case WASConstants.ServerActivitySmfRecordSubtype:
	          return "SERVER ACTIVITY";
	        case WASConstants.ContainerActivitySmfRecordSubtype:
	          return "CONTAINER ACTIVITY";
	        case WASConstants.ServerIntervalSmfRecordSubtype:
	          return "SERVER INTERVAL";
	        case WASConstants.ContainerIntervalSmfRecordSubtype:
	          return "CONTAINER INTERVAL";
	        case WASConstants.J2eeContainerActivitySmfRecordSubtype:
	          return "J2EE CONTAINER ACTIVITY";
	        case WASConstants.J2eeContainerIntervalSmfRecordSubtype:
	          return "J2EE CONTAINER INTERVAL";
	        case WASConstants.WebContainerActivitySmfRecordSubtype:
	          return "WEB CONTAINER ACTIVITY";
	        case WASConstants.WebContainerIntervalSmfRecordSubtype:
	          return "WEB CONTAINER INTERVAL";
	        case WASConstants.RequestActivitySmfRecordSubtype:
	          return "REQUEST ACTIVITY";
	        case WASConstants.OutboundRequestSmfRecordSubtype:
	            return "OUTBOUND REQUEST";           
	        case WASConstants.LibertyRequestActivitySmfRecordSubtype:
	        	return "Liberty Request Activity";
	        case WASConstants.LibertyBatchSmfRecordSubtype:
	        	return "Liberty Batch Record";
	          default:
	            return "Unknown WebSphere SMF record subtype";
	      }
	    } 
	    else {
	      return "Unknown SMF Record type/subtype combination";
	    }
	    
	  } // subtypeAsString()
	  
}	  
