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
import java.util.HashMap;
import java.util.Iterator;

import com.ibm.smf.format.DefaultFilter;
import com.ibm.smf.format.SMFFilter;
import com.ibm.smf.format.SmfPrintStream;
import com.ibm.smf.format.SmfRecord;
import com.ibm.smf.format.Triplet;
import com.ibm.smf.liberty.request.LibertyNetworkDataSection;
import com.ibm.smf.liberty.request.LibertyRequestInfoSection;
import com.ibm.smf.liberty.request.LibertyRequestRecord;
import com.ibm.smf.was.common.ClassificationDataSection;
import com.ibm.smf.was.common.WASConstants;
import com.ibm.smf.utilities.ConversionUtilities;
import com.ibm.smf.utilities.STCK;

public class LibertyResponseTimes implements SMFFilter {
	
	private SmfPrintStream smf_printstream = null;
	private long totalCPU = 0;
	private long totalRequests = 0;
	private long totalResponseTime = 0;
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
	   if (record.subtype()==WASConstants.LibertyRequestActivitySmfRecordSubtype)
	         ok_to_process = true;
     return ok_to_process;
	}
	
	@Override
	public void processRecord(SmfRecord record) {
		// cast to a subtype 11 and declare generic variables
		LibertyRequestRecord rec = (LibertyRequestRecord)record;
		int sectionCount;
		long cpuTime=0;
		long responseTime=0;
		long bytesSent = 0;
		String uri = null;

		if (rec.m_subtypeVersion==2) {
			Triplet requestDataTriplet = rec.m_requestDataTriplet;
			sectionCount = requestDataTriplet.count();
			if (sectionCount>0)
			{
				LibertyRequestInfoSection sec = rec.m_libertyRequestInfoSection;

				long startTime= (new BigInteger(ConversionUtilities.longByteArrayToHexString(sec.m_startStck),16).shiftRight(12).longValue())/1000L;				 
				long endTime = (new BigInteger(ConversionUtilities.longByteArrayToHexString(sec.m_endStck),16).shiftRight(12).longValue())/1000L;

				responseTime = endTime-startTime;
				cpuTime = sec.m_totalCPUEnd-sec.m_totalCPUStart;
			}


			Triplet classificationDataTriplet = rec.m_classificationDataTriplet;
			sectionCount = classificationDataTriplet.count();
			if (sectionCount>0)
			{
				ClassificationDataSection sec[] = new ClassificationDataSection[sectionCount];
				for (int i=0; i < sectionCount; i++) {
					sec[i] = rec.m_classificationDataSection[i];

					if (sec[i].m_dataType==ClassificationDataSection.TypeURI){
						uri = sec[i].m_theData;							 
					}
				}
			}
			Triplet networkDataTriplet = rec.m_networkDataTriplet;
			sectionCount = networkDataTriplet.count();
			if (sectionCount>0)
			{
				LibertyNetworkDataSection sec = rec.m_libertyNetworkDataSection;

				bytesSent = sec.m_responseBytes;
			}		 

			totalResponseTime = totalResponseTime + responseTime;
			totalCPU = totalCPU + cpuTime;
			totalBytesSent = totalBytesSent + bytesSent;

			// find or create the hashmap entry for this URI and update
			URIData urid = (URIData)table.get(uri);
			if (urid==null){
				urid = new URIData(uri);
				table.put(uri,urid);
			}
			urid.update(responseTime, cpuTime,bytesSent);

			++totalRequests;
		}

	}	
	@Override
	public void processingComplete() {
		smf_printstream.println("Requests,AvgResponse,AvgCPU,AvgBytesSent,URI");
		
		Iterator uridIT = table.keySet().iterator();
		while (uridIT.hasNext()) {
		   URIData urid = (URIData)table.get(uridIT.next());
		   smf_printstream.println(urid.getData());  
		}
		smf_printstream.println(totalRequests+","+totalResponseTime/totalRequests+","+totalCPU/totalRequests+","+totalBytesSent/totalRequests+",Overall");
	}

	
	public class URIData {
		private long totalCPU = 0;
		private long totalRequests = 0;
		private long totalResponseTime = 0;
		private long totalBytesSent = 0;
		private String uri;
		
		public URIData (String s){
			uri = s;
		}
		
		public void update(long responseTime, long cpuTime, long bytesSent){
		     totalResponseTime = totalResponseTime + responseTime;
			 totalCPU = totalCPU + cpuTime;
			 totalBytesSent = totalBytesSent + bytesSent;
	         ++totalRequests;
		}
		
		public String getData() {
			return new String(totalRequests+","+totalResponseTime/totalRequests+","+totalCPU/totalRequests+","+totalBytesSent/totalRequests+","+uri);
		}
		
	}

}
