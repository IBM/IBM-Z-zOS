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

import java.util.Calendar;
import java.util.Date;
import java.util.HashMap;
import java.util.Iterator;
import java.util.LinkedList;
import java.util.TimeZone;

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

public class DispatchThreadUsage implements SMFFilter {

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

	
	public void processRecord(SmfRecord record) {
		 
		 Triplet zOSRequestTriplet;
		 int sectionCount;
		 String servername =null;
		 long cpuTime=0;
		 Boolean bad_data=false;

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
	      
	      cpuTime = sec.m_dispatchTcbCpu/1000; // convert to milliseconds
	      
	      int minor_code = ConversionUtilities.intByteArrayToInt(sec.m_completionMinorCode);
	      
	      if (minor_code!=0) {
	       bad_data= true;
	      }
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
	      Date start_dt = STCK.toDate(ConversionUtilities.longByteArrayToHexString(sec.m_dispatched));
	      Calendar start_c = Calendar.getInstance();
	      TimeZone tz = TimeZone.getTimeZone("GMT");
	      start_c.setTimeZone(tz);
	      start_c.setTime(start_dt);
	      
	      Date end_dt = STCK.toDate(ConversionUtilities.longByteArrayToHexString(sec.m_dispatchcomplete));
	      Calendar end_c = Calendar.getInstance();
	      end_c.setTimeZone(tz);
	      end_c.setTime(end_dt);

	      byte [] stoken = sec.m_dispatchServantStoken;
	      String stoken_s = ConversionUtilities.longByteArrayToHexString(stoken);
	      
	      String stcname = sec.m_dispatchServantJobId;
	      
	      byte [] tcb = sec.m_dispatchServantTcbAddress;
	      String tcb_s = ConversionUtilities.intByteArrayToHexString(tcb);
	      
	      ServerData svd = (ServerData)servers.get(servername);
	      if (svd==null) {
	    	  svd = new ServerData(servername);
	    	  servers.put(servername,svd);
	      }
	      
	      ServantData srd = (ServantData)svd.getServants().get(stoken_s);
	      
	      if ((srd==null)&&bad_data) {
	    	  // Don't make a new one if the data for this request is bad
	    	  return;
	      }
	      
	      // else data was ok, we need a new ServantData object
	      
	      if (srd==null){
	    	  srd = new ServantData(stoken_s,stcname);
	    	  svd.getServants().put(stoken_s,srd);
	      }

	      // if data is bad, but we already had ServantData indicate its probably bad and skip this data
	      srd.badData(bad_data);
	      if (bad_data) return;
	      
	      LinkedList ll = srd.getAllThreads();
	      if (!!!ll.contains(tcb_s)) {
	    	  ll.add(tcb_s);
	      }

	      // Adjust earliest/latest time for this SR if necessary
	      srd.earliestTime(start_c);
	      srd.latestTime(end_c);
	      
	      // How much time were we in dispatch?
	      long dispatchTime = end_c.getTimeInMillis() - start_c.getTimeInMillis();
	      
	      ThreadData td = (ThreadData)srd.getThreadData().get(tcb_s);
	      if (td == null) {
	    	  srd.getThreadData().put(tcb_s, new ThreadData(new Long(dispatchTime),new Long(cpuTime)));
	      } else {
	    	  td.addTime(new Long(dispatchTime), new Long(cpuTime));
	      }
	      
	     }
	}  
	     
	     
	 	public void processingComplete() {
			
			Iterator serverIT = servers.keySet().iterator();
			smf_printstream.println("Server,SR-Stoken,SR-STCname,TimeRange (ms),TCB,UsedElapsed,UsedElapsedPercent,Used CPU,UsedCPUPercent,WorkCount");
			while (serverIT.hasNext()) {
				
				String servername = (String)serverIT.next();
				ServerData svd = (ServerData)servers.get(servername);
				Iterator servantIT = svd.getServants().keySet().iterator();
				while (servantIT.hasNext()) {
					
					String servant = (String)servantIT.next();
					ServantData srd = (ServantData)svd.getServants().get(servant);

					Long totalTime = srd.latestTime().getTimeInMillis() - srd.earliestTime().getTimeInMillis();

					String row_start = new String();
					row_start = servername+","+servant+","+srd.getSTCname()+","+totalTime.toString();

					if (srd.badData()) {
						System.out.println("WARNING:  For server "+ servername + " non-zero minor codes found, data may be bad");
					}

					
					LinkedList ll = srd.getAllThreads();
					
					// print header
					Iterator threadIT = ll.descendingIterator();

					while (threadIT.hasNext()) {
						String tcb_s = (String)threadIT.next();
						ThreadData td = (ThreadData)srd.getThreadData().get(tcb_s);
						
						Long usedTime = td.elapsedTime();
						if (usedTime==0) usedTime=1L; //elapsed dispatch time is less than one millisecond..call it one. 
						if (totalTime==0) totalTime=1L; // never used this thread?  Probably errors...just use one.
						Long cpuTime = td.cpuTime();
						int workCount =td.workCount();
						smf_printstream.println(row_start + "," + tcb_s + "," + usedTime + "," + usedTime*100/totalTime + "," + cpuTime + "," + cpuTime*100/usedTime + "," + workCount);
					}
				}
			}
	 	}		
	     
	

	
	public class ServerData {
		private String serverName;
		private HashMap servants = new HashMap();
		
		public ServerData(String s) { serverName=s;}
		public String getServerName() {return serverName; }
		public HashMap getServants() {return servants; }
	}
	
	public class ServantData {
		private String servantID;
		private String stcname;
		private LinkedList allThreads = new LinkedList();
		private HashMap threadData = new HashMap();
		
		private Calendar earliestTime=null;
		private Calendar latestTime=null;
		private boolean bad_data=false;
		
		public ServantData(String s1, String s2) {
			servantID = s1;
			stcname = s2;
			}
		public String getID() {return servantID; }
		public String getSTCname() {return stcname;}
		public LinkedList getAllThreads() {return allThreads;}
		public HashMap getThreadData() {return threadData;}
		
		public void earliestTime(Calendar c) {
			if (earliestTime==null) {earliestTime = c;}
			else if (earliestTime.compareTo(c)>0) {earliestTime= c;}
		}
		public Calendar earliestTime() { return earliestTime;}
		
		public void latestTime(Calendar c) {
			if (latestTime==null) {latestTime = c;}
			else if (latestTime.compareTo(c)<0) {latestTime= c;}
		}
		public Calendar latestTime() { return latestTime;}
		
		public void badData(boolean t) {bad_data = t;}
		public boolean badData() {return bad_data;}
		
	}

	public class ThreadData {
		Long elapsedTime;
		Long cpuTime;
		int workCount;
		
		public ThreadData(Long e, Long c) {
			elapsedTime = e;
			cpuTime = c;
			workCount = 1;
		}
		
		public void addTime(Long e, Long c) {
			elapsedTime = elapsedTime + e;
			cpuTime = cpuTime + c;
			++workCount;
		}
		
		public Long elapsedTime() {return elapsedTime;}
		public Long cpuTime() {return cpuTime;}
		public int workCount() {return workCount;}
		
	}

	
	
}
