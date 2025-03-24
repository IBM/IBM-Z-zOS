/*                                                                   */
/* Copyright 2025 IBM Corp.                                          */
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
import java.util.Arrays;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;
import java.util.Map.Entry;

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
import com.ibm.smf.utilities.ConversionUtilities;
import com.ibm.smf.utilities.STCK;

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
	private long maxResponseTime = 0;
	private Map<Long, Map<String, URIData>> timeTable = new HashMap<>();
	private Map<String, URIData> nonTimeTable = new HashMap<>();
	private Map<String, Map<Long, Map<String, URIData>>> breakdownTable = new HashMap<>();
	private TimeType useTime = TimeType.NONE;
	private IntervalType useTimeInterval = IntervalType.PER_MINUTE;
	private Breakdown useTimeBreakdown = Breakdown.NONE;
	
	enum TimeType {
		NONE, RECEIVED, QUEUED, DISPATCH_START, DISPATCH_END, RESPONDED, 
	}
	
	enum IntervalType {
		PER_SECOND, PER_MINUTE, PER_HOUR, 
	}
	
	enum Breakdown {
		NONE, BY_SERVER, 
	}
	
	public boolean initialize(String parms) 
	{
		String useTimeStr = System.getProperty("com.ibm.ws390.smf.smf1209.useTime");
		if (useTimeStr != null) {
			boolean found = false;
			for (TimeType val : TimeType.values()) {
				if (val.name().equalsIgnoreCase(useTimeStr)) {
					useTime = val;
					found = true;
				}
			}
			if (!found) {
				throw new UnsupportedOperationException("Unknown time type " + useTimeStr);
			}
			
			String intervalTypeStr = System.getProperty("com.ibm.ws390.smf.smf1209.intervalType");
			if (intervalTypeStr != null) {
				found = false;
				for (IntervalType val : IntervalType.values()) {
					if (val.name().equalsIgnoreCase(intervalTypeStr)) {
						useTimeInterval = val;
						found = true;
					}
				}
				if (!found) {
					throw new UnsupportedOperationException("Unknown time interval type " + intervalTypeStr);
				}
			}
			
			String breakdownStr = System.getProperty("com.ibm.ws390.smf.smf1209.breakdown");
			if (breakdownStr != null) {
				found = false;
				for (Breakdown val : Breakdown.values()) {
					if (val.name().equalsIgnoreCase(breakdownStr)) {
						useTimeBreakdown = val;
						found = true;
					}
				}
				if (!found) {
					throw new UnsupportedOperationException("Unknown breakdown " + breakdownStr);
				}
			}
		}

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
		if (record instanceof RequestActivitySmfRecord) {
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
		 String requestTypeString = null;
		 zOSRequestTriplet = rec.m_platformNeutralRequestInfoTriplet;
		 sectionCount = zOSRequestTriplet.count();
		 if (sectionCount > 0)
		 {
	      PlatformNeutralRequestInfoSection sec = rec.m_platformNeutralRequestInfoSection;
	      
	      // Skip records with bad CPU data (probably timed out)
	      if (sec.m_dispatchTcbCpu<0) return;
	      
	      // Accumulate CPU time in milliseconds
	      cpuTime = sec.m_dispatchTcbCpu/1000;
	      
	      requestTypeString = sec.getRequestTypeString();
		 }
		 
		 String breakdownKey = null;
		 switch (useTimeBreakdown) {
		 case BY_SERVER:
			 if (rec.m_platformNeutralSectionTriplet.count() > 0) {
				 breakdownKey = rec.m_platformNeutralSection.m_serverShortName;
			 } else {
				 throw new UnsupportedOperationException("Asked to break down with " + useTimeBreakdown + " but the triple doesn't exist for record " + record.sid());
			 }
			 break;
		 default:
			 // It's okay to not have a breakdown
			 break;
		 }
		 
		 // From the zOS request section
		 zOSRequestTriplet = rec.m_zosRequestInfoTriplet;
		 sectionCount = zOSRequestTriplet.count();
		 // If we have the zOS request info section
		 long receiveTime = -1, queuedTime = -1, dispatchStart = -1, dispatchEnd = -1, responded = -1;
	     if (sectionCount>0)
	     {
	      ZosRequestInfoSection sec = rec.m_zosRequestInfoSection;
	      
	      // https://www.ibm.com/docs/en/was-nd/9.0.5?topic=mapping-smf-subtype-9-request-activity-record#rtrb_SMFsubtype9__title__9
	      // "The time that the request was received."
	      receiveTime = (new BigInteger(ConversionUtilities.longByteArrayToHexString(sec.m_received),16).shiftRight(12).longValue())/1000L;
	      // "The time that the request was added to the queue."
	      queuedTime = (new BigInteger(ConversionUtilities.longByteArrayToHexString(sec.m_queued),16).shiftRight(12).longValue())/1000L;
	      // "The time that the request was dispatched.
	      dispatchStart= (new BigInteger(ConversionUtilities.longByteArrayToHexString(sec.m_dispatched),16).shiftRight(12).longValue())/1000L;
	      // "The time that the dispatch completed."
	      dispatchEnd = (new BigInteger(ConversionUtilities.longByteArrayToHexString(sec.m_dispatchcomplete),16).shiftRight(12).longValue())/1000L;
	      // "The time that the controller finished processing the request response."
	      responded = (new BigInteger(ConversionUtilities.longByteArrayToHexString(sec.m_complete),16).shiftRight(12).longValue())/1000L;
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
	     
	     if (uri == null && requestTypeString != null) {
	    	 uri = requestTypeString;
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
	     if (responseTime > maxResponseTime) {
	    	 maxResponseTime = responseTime;
	     }
	     totalQueueTime = totalQueueTime + queueTime;
	     totalDispatchTime = totalDispatchTime + dispatchTime;	     
		 totalCPU = totalCPU + cpuTime;
		 totalOffloadCPU = totalOffloadCPU + offloadCpu;
		 totalBytesReceived = totalBytesReceived + bytesReceived;
		 totalBytesSent = totalBytesSent + bytesSent;
	  
	     // find or create the hashmap entry for this URI and update
		 Map<String, URIData> table = getTable(breakdownKey, receiveTime, queuedTime, dispatchStart, dispatchEnd, responded);
		 URIData urid = (URIData)table.get(uri);
		 if (urid==null){
			  urid = new URIData(uri);
			  table.put(uri,urid);
		 }
		 urid.update(responseTime, queueTime, dispatchTime, cpuTime,offloadCpu,bytesReceived,bytesSent);
	     
         ++totalRequests;
		}
	}
	
	private Map<String, URIData> getTable(String breakdownKey, long receiveTime, long queuedTime, long dispatchStart, long dispatchEnd, long responded) {
		long key;
		
		switch (useTime) {
		case NONE:
			return nonTimeTable;
		case RECEIVED:
			key = receiveTime;
			break;
		case QUEUED:
			key = queuedTime;
			break;
		case DISPATCH_START:
			key = dispatchStart;
			break;
		case DISPATCH_END:
			key = dispatchEnd;
			break;
		case RESPONDED:
			key = responded;
			break;
		default:
			throw new UnsupportedOperationException("Unhandled time type " + useTime);
		}
		
		switch (useTimeInterval) {
		case PER_SECOND:
			key /= 1000;
			break;
		case PER_MINUTE:
			key /= 1000;
			key -= (key % 60);
			break;
		case PER_HOUR:
			key /= 1000;
			key -= (key % 3600);
			break;
		default:
			throw new UnsupportedOperationException("Unhandled interval type " + useTimeInterval);
		}
		
		Map<Long, Map<String, URIData>> finalTimeTable = timeTable;
		switch (useTimeBreakdown) {
		case BY_SERVER:
			finalTimeTable = breakdownTable.get(breakdownKey);
			if (finalTimeTable == null) {
				finalTimeTable = new HashMap<>();
				breakdownTable.put(breakdownKey, finalTimeTable);
			}
			break;
		case NONE:
			// Nothing extra to do
			break;
		default:
			throw new UnsupportedOperationException("Unhandled breakdown " + useTimeBreakdown);
		}
		
		Map<String, URIData> table = finalTimeTable.get(key);
		if (table == null) {
			table = new HashMap<>();
			finalTimeTable.put(key, table);
		}
		return table;
	}

	@Override
	public void processingComplete() {
		if (useTime == TimeType.NONE) {
			printHeader();
			
			Map<String, URIData> table = nonTimeTable;
			Iterator<String> uridIT = table.keySet().iterator();
			while (uridIT.hasNext()) {
			   URIData urid = (URIData)table.get(uridIT.next());
			   smf_printstream.println(urid.getData());  
			}
			float averageOffloadPercent = 0;
			if (totalCPU>0) {
				averageOffloadPercent = ((float)totalOffloadCPU/(float)totalCPU);
			}
			smf_printstream.println(totalRequests+","+totalResponseTime/totalRequests+","+maxResponseTime+","+totalQueueTime/totalRequests+","+totalDispatchTime/totalRequests+","+totalCPU/totalRequests+","+totalOffloadCPU/totalRequests+","+averageOffloadPercent+","+totalBytesReceived/totalRequests+","+totalBytesSent/totalRequests+",Overall");
		} else {
			smf_printstream.print("Time,");
			if (useTimeBreakdown == Breakdown.NONE) {
				printHeader();
				processTimeTable(null, timeTable);
			} else {
				smf_printstream.print("Server,");
				printHeader();
				for (Entry<String, Map<Long, Map<String, URIData>>> entry : breakdownTable.entrySet()) {
					processTimeTable(entry.getKey(), entry.getValue());
				}
			}
		}
	}

	private void processTimeTable(String breakdownKey, Map<Long, Map<String, URIData>> t) {
		Long[] keys = new Long[t.size()];
		t.keySet().toArray(keys);
		Arrays.sort(keys);
		for (Long key : keys) {
			String time = STCK.toString(key * 1000);
			Map<String, URIData> table = t.get(key);
			Iterator<String> uridIT = table.keySet().iterator();
			while (uridIT.hasNext()) {
			   URIData urid = (URIData)table.get(uridIT.next());
			   smf_printstream.print("\"" + time + "\"");
			   smf_printstream.print(",");
			   if (breakdownKey != null) {
				   smf_printstream.print(breakdownKey);
				   smf_printstream.print(",");
			   }
			   smf_printstream.println(urid.getData());  
			}
		}
	}
	
	private void printHeader() {
		smf_printstream.println("Requests,AvgResponse,MaxResponse,AvgQueue,AvgDisp,AvgCPU,AvgOffload,AvgOffload%,AvgBytesRcvd,AvgBytesSent,URI");
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
		private long maxResponseTime = 0;
		private String uri;
		
		public URIData (String s){
			uri = s;
		}
		
		public void update(long responseTime, long queueTime, long dispatchTime, long cpuTime, long offloadCPU, long bytesReceived, long bytesSent){
		     totalResponseTime = totalResponseTime + responseTime;
		     if (responseTime > maxResponseTime) {
		    	 maxResponseTime = responseTime;
		     }
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
			return new String(totalRequests+","+totalResponseTime/totalRequests+","+maxResponseTime+","+totalQueueTime/totalRequests+","+totalDispatchTime/totalRequests+","+totalCPU/totalRequests+","+totalOffloadCPU/totalRequests+","+averageOffloadPercent+","+totalBytesReceived/totalRequests+","+totalBytesSent/totalRequests+","+uri);
		}
		
	}
	
}
