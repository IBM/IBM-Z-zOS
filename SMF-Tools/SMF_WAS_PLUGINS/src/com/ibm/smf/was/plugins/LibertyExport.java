/*                                                                   */
/* Copyright 2024 IBM Corp.                                          */
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

package com.ibm.smf.was.plugins;

import java.math.BigInteger;

import com.ibm.smf.format.DefaultFilter;
import com.ibm.smf.format.SMFFilter;
import com.ibm.smf.format.SmfPrintStream;
import com.ibm.smf.format.SmfRecord;
import com.ibm.smf.format.Triplet;
import com.ibm.smf.liberty.request.LibertyNetworkDataSection;
import com.ibm.smf.liberty.request.LibertyRequestInfoSection;
import com.ibm.smf.liberty.request.LibertyRequestRecord;
import com.ibm.smf.liberty.request.LibertyServerInfoSection;
import com.ibm.smf.was.common.ClassificationDataSection;
import com.ibm.smf.was.common.WASConstants;
import com.ibm.smf.utilities.ConversionUtilities;
import com.ibm.smf.utilities.STCK;


/**
 * First pass at CSVExport for Liberty SMF 120-11 V2 records
 * @author follis
 *
 */
public class LibertyExport implements SMFFilter {

	protected SmfPrintStream smf_printstream = null;
	private boolean header_written = false;
	
	
	public boolean initialize(String parms) 
	{
	 boolean return_value = true;
	    smf_printstream = DefaultFilter.commonInitialize(parms);
	    if (smf_printstream==null)
	         return_value = false;
	 return return_value;
	} 

	public SmfRecord parse(SmfRecord record) 
	{
	 return DefaultFilter.commonParse(record);		
	}


	public boolean preParse(SmfRecord record) 
	{
	 boolean ok_to_process = false;
	 if (record.type()== WASConstants.SmfRecordType)
	   if (record.subtype()==WASConstants.LibertyRequestActivitySmfRecordSubtype)
	         ok_to_process = true;
     return ok_to_process;
	}
	
	public void processRecord(SmfRecord record) 
	{
		int sectionCount;
		
		 // cast to a subtype 11 and declare generic variables
		LibertyRequestRecord rec = (LibertyRequestRecord)record;

		 // Here's the string we stuff everything into:
		 String s = new String();
		 
		 // Here's the header
		 String sHeader = new String();
		 
		 // From the base record get the time
		 s = s + rec.date().toString();
		 sHeader = sHeader + "RecordTime";

		 Triplet ServerInfoTriplet = rec.m_LibertyServerInfoSectionTriplet;
		 sectionCount = ServerInfoTriplet.count();
		 if (sectionCount>0)
		 {
			 LibertyServerInfoSection sec = rec.m_libertyServerInfoSection;

		      // Add some strings
		      s = s + "," + sec.m_systemName + "," + sec.m_sysplexName +
		              "," + sec.m_jobId + "," + sec.m_jobName;
		      sHeader = sHeader + ",SystemName,SysplexName,JobId,JobName";
		      
		      // Add stoken and asid
		      s = s + "," + ConversionUtilities.longByteArrayToHexString(sec.m_server_stoken);
		      sHeader = sHeader + ",Stoken";
		      
		      if (sec.m_version>=2) {
		    	  s = s + "," + sec.m_asid + "," + sec.m_serverConfigDir + "," + sec.m_productVersion + "," + sec.m_pid;
		    	  sHeader = sHeader + ",ASID,ConfigDir,Version,PID"; 
		      }
		      
		 }    
		 
		if (rec.m_subtypeVersion>=2) {
			 Triplet requestDataTriplet = rec.m_requestDataTriplet;
			 sectionCount = requestDataTriplet.count();
			 if (sectionCount>0)
			 {
				 LibertyRequestInfoSection sec = rec.m_libertyRequestInfoSection;
				 
                 long startTime= (new BigInteger(ConversionUtilities.longByteArrayToHexString(sec.m_startStck),16).shiftRight(12).longValue())/1000L;				 
                 long endTime = (new BigInteger(ConversionUtilities.longByteArrayToHexString(sec.m_endStck),16).shiftRight(12).longValue())/1000L;

                 float totalCPU = (float)(sec.m_totalCPUEnd-sec.m_totalCPUStart)/(float)4096000;
                 float totalCP = (float)(sec.m_CPEnd - sec.m_CPStart)/(float)4096000;
                 float totalOffload = totalCPU - totalCP;
                 
				 s = s + "," + 
				               ConversionUtilities.intByteArrayToHexString(sec.m_tcbAddress) +
						 /* skip ttoken */
						 "," + ConversionUtilities.longByteArrayToHexString(sec.m_threadId) +
						 "," + new BigInteger(ConversionUtilities.longByteArrayToHexString(sec.m_systemGmtOffset),16).toString() +
						 "," + ConversionUtilities.longByteArrayToHexString(sec.m_threadIdCurrentThread) +
						 "," + ConversionUtilities.bytesToHex(sec.m_requestId) +
						 "," + STCK.toString(ConversionUtilities.longByteArrayToHexString(sec.m_startStck)).replace(',',' ') +
						 "," + startTime + 
						 "," + STCK.toString(ConversionUtilities.longByteArrayToHexString(sec.m_endStck)).replace(',',' ') +
						 "," + endTime +
						 "," + (endTime-startTime) +
						 "," + sec.m_wlmTransactionClass +
						 "," + sec.m_totalCPUStart +
						 "," + sec.m_totalCPUEnd +
						 "," + sec.m_CPStart +
						 "," + sec.m_CPEnd +
						 "," + totalCPU +
						 "," + totalCP +
						 "," + totalOffload;

				 sHeader = sHeader + ",TCB,ThreadId,GMTOffset,JavaThreadId,requestID,StartTime(stck),StartTime(ms),EndTime(stck),EndTime(ms),ResponseTime(ms),TranClass" + 
			             ",Total CPU Start,Total CPU End" +
					     ",GP CPU Start,GP CPU End" +
			             ",TotalCPU(ms),TotalGP(ms),TotalOffload(ms)";
				 
			      s = s + "," + sec.m_enclaveDeleteCPU                 +
			              "," + (float)sec.m_enclaveDeleteCPU/(float)4096000         +
			              "," + sec.m_enclaveDeletezAAPCPU             +
			              "," + sec.m_enclaveDeletezAAPNorm            +
			              "," + sec.m_enclaveDeletezIIPCPU   +
			              "," + (float)sec.m_enclaveDeletezIIPCPU/(float)4096000 +
			              "," + sec.m_enclaveDeletezIIPService         +
			              "," + sec.m_enclaveDeletezAAPService         +
			              "," + sec.m_enclaveDeleteCpuService          +
			              "," + sec.m_enclaveDeleteRespTimeRatio;
			      
			      sHeader = sHeader + ",EnclaveDeleteCPU"        +
			                          ",EnclaveDeleteCPU(ms)"    +
			                          ",EnclaveDeletezAAPCPU"    +
			                          ",EnclaveDeletezAAPNorm"   +
			                          ",EnclaveDeletezIIPCPU"+
			                          ",EnclaveDeletezIIPCPU(ms)"+
			                          ",EnclaveDeletezIIPServiceUnits"+
			                          ",EnclaveDeletezAAPServiceUnits"+
			                          ",EnclaveDeleteCPUServiceUnits"+
			                          ",EnclaveDeleteResponseTimeRatio";

			      s = s + "," + sec.m_userid +
			    		  "," + sec.m_mappedUserid +
			    		  "," + sec.m_requestUri;
			      
			      sHeader = sHeader + ",userid" +
			                          ",mappedUserid" +
			    		              ",requestURI";
				 

			 }

			 Triplet classificationDataTriplet = rec.m_classificationDataTriplet;
			 sectionCount = classificationDataTriplet.count();
			 if (sectionCount>0)
			 {
				 String uri="";
				 String host="";
				 String port = "";

				 ClassificationDataSection sec[] = new ClassificationDataSection[sectionCount];
				 for (int i=0; i < sectionCount; i++) {
					 sec[i] = rec.m_classificationDataSection[i];
					 
					 if (sec[i].m_dataType==ClassificationDataSection.TypeURI){
						 uri = sec[i].m_theData;
						 
					 }
					 if (sec[i].m_dataType == ClassificationDataSection.TypeHostname) {
						 host = sec[i].m_theData;					 
					 }
					 if (sec[i].m_dataType == ClassificationDataSection.TypePort) {
						 port = sec[i].m_theData;
					 }
					 
			      }
				 s = s + "," + host + "," + port + "," + uri;
				 sHeader = sHeader + ",host,port,uri";
		     }
			 
			 Triplet networkDataTriplet = rec.m_networkDataTriplet;
			 sectionCount = networkDataTriplet.count();
			 if (sectionCount>0)
			 {
				 LibertyNetworkDataSection sec = rec.m_libertyNetworkDataSection;
				
				 s = s + "," + sec.m_responseBytes +
						 "," + sec.m_targetPort +
						 "," + sec.m_remotePort +
						 "," + sec.m_remoteaddrstring;
				             
				 sHeader = sHeader + ",responseBytes,targetPort,remotePort,RemoteAddr";
				 
			 }
			 
			 
			
		}
		 
		 
        // Write the header (if first time through)
        if (!header_written)
        {	   
         smf_printstream.println(sHeader);
  	     header_written = true;
        }
        // Write the record
        smf_printstream.println(s);
		
	}
	
	public void processingComplete() 
	{
	}
	
}
