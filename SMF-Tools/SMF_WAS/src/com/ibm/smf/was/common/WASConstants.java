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

public class WASConstants {

	  /** Smf record type for WebSphere for z/OS. */
	  public final static int SmfRecordType = 120;
	  
	  /** Unknown Smf record type enum value. */
	  public final static int UnknownSmfRecordSubtype = 0;
	  
	  /** Server activity Smf record type enum value. */
	  public final static int ServerActivitySmfRecordSubtype = 1;
	  
	  /** Container activity Smf record type enum value. */
	  public final static int ContainerActivitySmfRecordSubtype = 2;
	  
	  /** Server interval Smf record type enum value. */
	  public final static int ServerIntervalSmfRecordSubtype = 3;
	  
	  /** Container interval Smf record type enum value. */
	  public final static int ContainerIntervalSmfRecordSubtype = 4;
	  
	  /** J2ee container activity Smf record type enum value. */
	  public final static int J2eeContainerActivitySmfRecordSubtype = 5;
	  
	  /** J2ee container interval Smf record type enum value. */
	  public final static int J2eeContainerIntervalSmfRecordSubtype = 6;
	  
	  /** Web container activity Smf record type enum value. */
	  public final static int WebContainerActivitySmfRecordSubtype = 7;
	  
	  /** Web container interval Smf record type enum value. */
	  public final static int WebContainerIntervalSmfRecordSubtype = 8;
	  
	  /** Request Activity Smf record type enum value. */
	  public final static int RequestActivitySmfRecordSubtype = 9;
	  
	  /** Outbound Request Smf record type enum value. */
	  public final static int OutboundRequestSmfRecordSubtype = 10;
	    
	  /** Liberty Request SMF record */
	  public final static int LibertyRequestActivitySmfRecordSubtype = 11;
	    
	  /** Liberty Batch SMF record */
	  public final static int LibertyBatchSmfRecordSubtype = 12;

	
}
