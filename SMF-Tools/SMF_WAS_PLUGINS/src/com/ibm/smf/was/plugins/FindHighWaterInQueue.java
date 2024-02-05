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
import java.util.LinkedList;

import com.ibm.smf.format.DefaultFilter;
import com.ibm.smf.format.SMFFilter;
import com.ibm.smf.format.SmfPrintStream;
import com.ibm.smf.format.SmfRecord;
import com.ibm.smf.format.Triplet;
import com.ibm.smf.twas.request.PlatformNeutralRequestInfoSection;
import com.ibm.smf.twas.request.RequestActivitySmfRecord;
import com.ibm.smf.twas.request.ZosRequestInfoSection;
import com.ibm.smf.was.common.PlatformNeutralSection;
import com.ibm.smf.was.common.WASConstants;
import com.ibm.smf.utilities.ConversionUtilities;
import com.ibm.smf.utilities.STCK;

public class FindHighWaterInQueue implements SMFFilter {

	private SmfPrintStream smf_printstream = null;
	private HashMap servers = new HashMap();
	
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
		 Triplet zOSRequestTriplet;
		 int sectionCount;
		 String servername =null;

	     // cast to a subtype 9 and declare generic variables
		 RequestActivitySmfRecord rec = (RequestActivitySmfRecord)record;
		 
		 // Ignore Async work records...
		 zOSRequestTriplet = rec.m_asyncWorkDataTriplet;
		 sectionCount = zOSRequestTriplet.count();
		 if (sectionCount >0) {
			 return;
		 }
		 
		 zOSRequestTriplet = rec.m_platformNeutralRequestInfoTriplet;
		 sectionCount = zOSRequestTriplet.count();
		 if (sectionCount > 0)
		 {
	      PlatformNeutralRequestInfoSection sec = rec.m_platformNeutralRequestInfoSection;

	      // Skip internal work types since they run on a different thread pool
	      int reqType = sec.m_requestType;
	      if ((reqType == PlatformNeutralRequestInfoSection.TypeUnknown)|
	    	  (reqType == PlatformNeutralRequestInfoSection.TypeMBean)|
	    	  (reqType == PlatformNeutralRequestInfoSection.TypeOTS)|
	    	  (reqType == PlatformNeutralRequestInfoSection.TypeOther))
	    	  return;
		 }	      		 
		 
	     zOSRequestTriplet = rec.m_platformNeutralSectionTriplet;
	     sectionCount = zOSRequestTriplet.count();
	     if (sectionCount>0)
	     {
	      PlatformNeutralSection sec = rec.m_platformNeutralSection;

		  servername = sec.m_serverShortName;
		  
	     }

		 // From the zOS request section
		 zOSRequestTriplet = rec.m_zosRequestInfoTriplet;
		 sectionCount = zOSRequestTriplet.count();
		 // If we have the zOS request info section
	     if (sectionCount>0)
	     {
	      ZosRequestInfoSection sec = rec.m_zosRequestInfoSection;
	      
	      long queued;
	      long finished;
	      
	      queued = new BigInteger(ConversionUtilities.longByteArrayToHexString(sec.m_queued),16).shiftRight(12).longValue()/1000L;

	      // assume it came off the queue normally....
	      finished = new BigInteger(ConversionUtilities.longByteArrayToHexString(sec.m_dispatched),16).shiftRight(12).longValue()/1000L;	      
	      
	      // But if we don't have a time when it came off the queue, it timed out on the queue
	      // so then the 'complete' time is when we cleaned it up and took it off the queue
	      if (finished==0) {
	         finished = new BigInteger(ConversionUtilities.longByteArrayToHexString(sec.m_complete),16).shiftRight(12).longValue()/1000L;
	      }
	      
          Times times = new Times(queued,finished);
          
	      ServerData svd = (ServerData)servers.get(servername);
	      if (svd==null) {
	    	  svd = new ServerData(servername);
	    	  servers.put(servername,svd);
	      }
	      
	      svd.earliest(queued);
	      svd.latest(finished);
	      LinkedList ll = svd.getTimes();
	      ll.add(times);
	      
	     }
	}

	@Override
	public void processingComplete() {
		Iterator serverIT = servers.keySet().iterator();
		while (serverIT.hasNext()) {
			
			String servername = (String)serverIT.next();
			ServerData svd = (ServerData)servers.get(servername);

			LinkedList ll = svd.getTimes();
			
			smf_printstream.println("Data for server "+svd.getServerName());
			
			int highwater = 0;
			long highwater_time = 0;
			
			smf_printstream.println("analyzing range "+svd.earliest()+" to "+svd.latest()+" which is "+(svd.latest()-svd.earliest())+" slots");
			Integer samples = Integer.getInteger("com.ibm.ws390.smf.smf1209.FindHighWaterInQueue.Interval",1000);
			int sample_count = samples.intValue();
			long skip_value = (svd.latest()-svd.earliest())/sample_count;
			smf_printstream.println("Generating "+sample_count+" samples every "+skip_value+"ms");
			
			for (long l = svd.earliest();l<=svd.latest();l = l + skip_value){
				if ((l % 10000)==0) 
					System.out.println(l);
				int queued_at_this_time=0;
				Iterator it = ll.iterator();
                while (it.hasNext()) {
                	Times times = (Times)it.next();
                	if (times.onQueue(l)) {
                		++queued_at_this_time;
                	}
                }
                smf_printstream.println(l+","+queued_at_this_time);
                if (queued_at_this_time > highwater) {
                	highwater=queued_at_this_time;
                	highwater_time = l;
                }
			}
			
			smf_printstream.println("Highwater Queued is "+highwater+" at "+highwater_time);
		}		
		
	}

	public class ServerData {
		private String serverName;
		private HashMap servants = new HashMap();
		private long earliest;
		private long latest;
		
		public ServerData(String s) { 
			serverName=s;
			earliest=0;
			latest=0;
			}
		public String getServerName() {return serverName; }
		
		public void earliest(long t) {
			if (earliest==0) earliest = t;
			if (earliest>=t) earliest = t;
		}
		
		public void latest(long t) {
			if (latest==0) latest=t;
			if (latest<=t) latest=t;
		}
		
		public long earliest() {return earliest;}
		public long latest() {return latest;}
		
		public LinkedList allTimes = new LinkedList();
		public LinkedList getTimes() {return allTimes; }
		
	}

	public class Times {
		private long queued;
		private long finished;
		
		public Times(long q, long f) {
			queued=q;
			finished=f;
		}
		
		public boolean onQueue(long t) {
			if ((queued<=t)&&(t<=finished)) return true;
			return false;
		}
		
		
	}
	
}
