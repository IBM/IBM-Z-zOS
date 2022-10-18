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

package com.ibm.smf.was.plugins;


import java.math.BigInteger;
import java.util.HashMap;
import java.util.Iterator;

import com.ibm.smf.format.DefaultFilter;
import com.ibm.smf.format.SMFFilter;
import com.ibm.smf.format.SmfPrintStream;
import com.ibm.smf.format.SmfRecord;
import com.ibm.smf.format.Triplet;
import com.ibm.smf.twas.request.NetworkDataSection;
import com.ibm.smf.twas.request.PlatformNeutralRequestInfoSection;
import com.ibm.smf.twas.request.RequestActivitySmfRecord;
import com.ibm.smf.twas.request.ZosRequestInfoSection;
import com.ibm.smf.was.common.ClassificationDataSection;
import com.ibm.smf.was.common.WASConstants;
import com.ibm.smf.was.plugins.utilities.ConversionUtilities;

/**
 * Reports on response and CPU times for the SMF data provided
 *
 */
public class ResponseTimes implements SMFFilter {

	private SmfPrintStream smf_printstream = null;
	private long totalCPU = 0;
	private long totalOffloadCPU = 0;
	private long totalRequests = 0;
	private long totalResponseTime = 0;
	private long totalQueueTime = 0;
	private long totalDispatchTime = 0;
	private long totalBytesReceived = 0;
	private long totalBytesSent = 0;
	private HashMap table = new HashMap();
	
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
	   if (record.subtype()==WASConstants.RequestActivitySmfRecordSubtype)
	         ok_to_process = true;
     return ok_to_process;
	}

	@Override
	public void processRecord(SmfRecord record) {
	     // cast to a subtype 9 and declare generic variables
		 RequestActivitySmfRecord rec = (RequestActivitySmfRecord)record;
		 Triplet zOSRequestTriplet;
		 int sectionCount;
		 long cpuTime=0;
		 long offloadCpu = 0;
		 long responseTime=0;
		 long queueTime=0;
		 long dispatchTime=0;
		 long bytesReceived = 0;
		 long bytesSent = 0;
	    
		 // Ignore Async work records...
		 zOSRequestTriplet = rec.m_asyncWorkDataTriplet;
		 sectionCount = zOSRequestTriplet.count();
		 if (sectionCount >0) {
			 return;
		 }

		 // From the Platform Neutral Request Info Section
		 zOSRequestTriplet = rec.m_platformNeutralRequestInfoTriplet;
		 sectionCount = zOSRequestTriplet.count();
		 if (sectionCount > 0)
		 {
	      PlatformNeutralRequestInfoSection sec = rec.m_platformNeutralRequestInfoSection;
	      
	      // Skip records with bad CPU data (probably timed out)
	      if (sec.m_dispatchTcbCpu<0) return;
	      
	      // Accumulate CPU time in milliseconds
	      cpuTime = sec.m_dispatchTcbCpu/1000;
		 }
		 
		 // From the zOS request section
		 zOSRequestTriplet = rec.m_zosRequestInfoTriplet;
		 sectionCount = zOSRequestTriplet.count();
		 // If we have the zOS request info section
	     if (sectionCount>0)
	     {
	      ZosRequestInfoSection sec = rec.m_zosRequestInfoSection;
	         

	      long receiveTime = (new BigInteger(ConversionUtilities.longByteArrayToHexString(sec.m_received),16).shiftRight(12).longValue())/1000L;
	      long queuedTime = (new BigInteger(ConversionUtilities.longByteArrayToHexString(sec.m_queued),16).shiftRight(12).longValue())/1000L;
	      long dispatchStart= (new BigInteger(ConversionUtilities.longByteArrayToHexString(sec.m_dispatched),16).shiftRight(12).longValue())/1000L;
	      long dispatchEnd = (new BigInteger(ConversionUtilities.longByteArrayToHexString(sec.m_dispatchcomplete),16).shiftRight(12).longValue())/1000L;
	      long responded = (new BigInteger(ConversionUtilities.longByteArrayToHexString(sec.m_complete),16).shiftRight(12).longValue())/1000L;
	      responseTime = responded - receiveTime;
	      queueTime = dispatchStart - queuedTime;
	      dispatchTime = dispatchEnd - dispatchStart;
	      
	      //Accumulate CPU offload time in milliseconds
    	  offloadCpu = sec.m_dispatchServantCpuOffload/1000;
	     }
	     
		 // From the classification section
		 zOSRequestTriplet = rec.m_classificationDataTriplet;
		 sectionCount = zOSRequestTriplet.count();
		 String uri = null;

		 // If we have the network info section
	     if (sectionCount>0)
	     {
	    	 // Find the URI
	    	 
	    	 for (int i=1;i<=sectionCount;++i) {
	    		 ClassificationDataSection cds =  rec.m_classificationDataSection[i-1];
	            int type = cds.m_dataType;
	            if (type == ClassificationDataSection.TypeURI){
	            	uri = cds.m_theData;
	            } 
	    	 }
	     }
	     
		 // From the network section
		 zOSRequestTriplet = rec.m_networkDataTriplet;
		 sectionCount = zOSRequestTriplet.count();
		 // If we have the network info section
	     if (sectionCount>0)
	     {
	    	 // There should at most be one of these, but for some reason we have an array so handle it...
	    	 for (int i=1;i<=sectionCount;++i) {
	    		 NetworkDataSection nds =  rec.m_networkDataSection[i-1];
	    		 bytesReceived = bytesReceived + nds.m_bytesReceived;
	    		 bytesSent = bytesSent + nds.m_bytesSent;
	    	 }	 
	     }
	     
	     
	     totalResponseTime = totalResponseTime + responseTime;
	     totalQueueTime = totalQueueTime + queueTime;
	     totalDispatchTime = totalDispatchTime + dispatchTime;	     
		 totalCPU = totalCPU + cpuTime;
		 totalOffloadCPU = totalOffloadCPU + offloadCpu;
		 totalBytesReceived = totalBytesReceived + bytesReceived;
		 totalBytesSent = totalBytesSent + bytesSent;
	  
	     // find or create the hashmap entry for this URI and update
		 URIData urid = (URIData)table.get(uri);
		 if (urid==null){
			  urid = new URIData(uri);
			  table.put(uri,urid);
		 }
		 urid.update(responseTime, queueTime, dispatchTime, cpuTime,offloadCpu,bytesReceived,bytesSent);
	     
         ++totalRequests;
		
	}

	@Override
	public void processingComplete() {
		smf_printstream.println("Requests,AvgResponse,AvgQueue,AvgDisp,AvgCPU,AvgOffload,AvgOffload%,AvgBytesRcvd,AvgBytesSent,URI");
		
		Iterator uridIT = table.keySet().iterator();
		while (uridIT.hasNext()) {
		   URIData urid = (URIData)table.get(uridIT.next());
		   smf_printstream.println(urid.getData());  
		}
		float averageOffloadPercent = 0;
		if (totalCPU>0) {
			averageOffloadPercent = ((float)totalOffloadCPU/(float)totalCPU);
		}
		smf_printstream.println(totalRequests+","+totalResponseTime/totalRequests+","+totalQueueTime/totalRequests+","+totalDispatchTime/totalRequests+","+totalCPU/totalRequests+","+totalOffloadCPU/totalRequests+","+averageOffloadPercent+","+totalBytesReceived/totalRequests+","+totalBytesSent/totalRequests+",Overall");
	}

	
	public class URIData {
		private long totalCPU = 0;
		private long totalOffloadCPU = 0;
		private long totalRequests = 0;
		private long totalResponseTime = 0;
		private long totalQueueTime = 0;
		private long totalDispatchTime = 0;
		private long totalBytesReceived = 0;
		private long totalBytesSent = 0;
		private String uri;
		
		public URIData (String s){
			uri = s;
		}
		
		public void update(long responseTime, long queueTime, long dispatchTime, long cpuTime, long offloadCPU, long bytesReceived, long bytesSent){
		     totalResponseTime = totalResponseTime + responseTime;
		     totalQueueTime = totalQueueTime + queueTime;
		     totalDispatchTime = totalDispatchTime + dispatchTime;
			 totalCPU = totalCPU + cpuTime;
			 totalOffloadCPU = totalOffloadCPU + offloadCPU;
			 totalBytesReceived = totalBytesReceived + bytesReceived;
			 totalBytesSent = totalBytesSent + bytesSent;
	         ++totalRequests;
         
		}
		
		public String getData() {
			float averageOffloadPercent = 0;
			if (totalCPU>0) {
				averageOffloadPercent = ((float)totalOffloadCPU/(float)totalCPU);
			}
			return new String(totalRequests+","+totalResponseTime/totalRequests+","+totalQueueTime/totalRequests+","+totalDispatchTime/totalRequests+","+totalCPU/totalRequests+","+totalOffloadCPU/totalRequests+","+averageOffloadPercent+","+totalBytesReceived/totalRequests+","+totalBytesSent/totalRequests+","+uri);
		}
		
	}
	
}
