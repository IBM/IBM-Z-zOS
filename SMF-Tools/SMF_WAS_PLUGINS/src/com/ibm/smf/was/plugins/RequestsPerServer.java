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
import com.ibm.smf.twas.outbound.OutboundRequestSmfRecord;
import com.ibm.smf.twas.request.AsyncWorkDataSection;
import com.ibm.smf.twas.request.PlatformNeutralRequestInfoSection;
import com.ibm.smf.twas.request.RequestActivitySmfRecord;
import com.ibm.smf.twas.request.ZosRequestInfoSection;
import com.ibm.smf.was.common.PlatformNeutralSection;
import com.ibm.smf.was.common.WASConstants;
import com.ibm.smf.was.common.ZosServerInfoSection;
import com.ibm.smf.utilities.ConversionUtilities;
import com.ibm.smf.utilities.STCK;


/**
 * This plugin identifies the types of SMF 120-9 records found
 * and the system/servers for which they were written.
 * It yields a report listing all the systems/servers and then
 * for each one a count of the types of work executed (e.g. HTTP, IIOP, etc).
 *
 */
public class RequestsPerServer implements SMFFilter {

	private SmfPrintStream smf_printstream = null;
	private HashMap servers = new HashMap();
	private int request_count;
	private int missed_goal_count;
	private int[] type_counts = new int[PlatformNeutralRequestInfoSection.TypeMax+1];
	private int async_work_count;
	private int outbound_request_count;
	
	public boolean initialize(String parms) 
	{
	 boolean return_value = true;
	 smf_printstream = DefaultFilter.commonInitialize(parms);
	 if (smf_printstream==null)
	      return_value = false;
	 
 	 request_count = 0;
 	 missed_goal_count = 0;
 	 async_work_count = 0;
 	 outbound_request_count = 0;
     for (int i=0;i<=PlatformNeutralRequestInfoSection.TypeMax;++i) {
        	type_counts[i] = 0;
     }

	 return return_value;
	}

	public SmfRecord parse(SmfRecord record) 
	{
	 return DefaultFilter.commonParse(record);		
	}


	public boolean preParse(SmfRecord record) 
	{
	 boolean ok_to_process = false;
	 if (record.type()== WASConstants.SmfRecordType) {
	   if (record.subtype()==WASConstants.RequestActivitySmfRecordSubtype) {
	         ok_to_process = true;
	   }      
	   else if (record.subtype() == WASConstants.OutboundRequestSmfRecordSubtype) {
		   ok_to_process = true;
	   } 	   
	 } 
     return ok_to_process;
	}

	@Override
	public void processRecord(SmfRecord record) {
		 Triplet zOSRequestTriplet=null;
		 Triplet asyncWorkDataTriplet;
		 PlatformNeutralSection psec = null;
		 ZosServerInfoSection zsec=null;
		 int sectionCount;
		 String servername =null;
		 int reqType = 0;
		 int respRatio = 0;
		 String cellname=null;
		 String nodename=null;
		 String clustername=null;
	     String sysname=null;
	     String level=null;
	     long receivedTimeMS=0L;
	     long completeTimeMS=0L;
	     String receivedTime=null;
	     String completeTime=null;
	     RequestActivitySmfRecord rec = null;
         OutboundRequestSmfRecord orec = null;

	     
	     if (record.subtype()==WASConstants.RequestActivitySmfRecordSubtype)
	     {
	       // cast to a subtype 9 and declare generic variables
		   rec = (RequestActivitySmfRecord)record;
	       zOSRequestTriplet = rec.m_platformNeutralSectionTriplet;
		   psec = rec.m_platformNeutralSection;
	     } else if (record.subtype() == WASConstants.OutboundRequestSmfRecordSubtype) 
	     {	 
	       orec = (OutboundRequestSmfRecord)record;
	       zOSRequestTriplet = orec.m_platformNeutralSectionTriplet;
		   psec = orec.m_platformNeutralSection;
	       ++outbound_request_count;
	     }

	     sectionCount = zOSRequestTriplet.count();
	     if (sectionCount>0)
	     {
		  servername = psec.m_serverShortName;
		  cellname = psec.m_cellShortName;
		  nodename= psec.m_nodeShortName;
		  clustername = psec.m_clusterShortName;
		  level = psec.m_wasRelease + "." + psec.m_wasReleaseX + "." + psec.m_wasReleaseY + "." + psec.m_wasReleaseZ;
	     }

	     if (record.subtype()==WASConstants.RequestActivitySmfRecordSubtype)
	     {
	    	 zOSRequestTriplet = rec.m_zosServerInfoTriplet;
	    	 zsec = rec.m_zosServerInfoSection;
	     } else if (record.subtype() == WASConstants.OutboundRequestSmfRecordSubtype) 
	     {	 
	    	 zOSRequestTriplet = orec.m_zosServerInfoTriplet;
	    	 zsec = orec.m_zosServerInfoSection;
	     }	     
		 
		 sectionCount = zOSRequestTriplet.count();
		 if (sectionCount > 0)
		 {
	      sysname = zsec.m_systemName;
		 } else {
			 sysname = new String("");
		 }

	     ServerData sd = (ServerData)servers.get(servername);
	     if (sd==null){
	    	 sd = new ServerData(cellname, nodename, clustername, servername,sysname,level);
	    	 servers.put(servername, sd);
	     }	 
		 
	     int notRegularWork=0;
	     int notAsyncWork=0;
	     
	     
	     if (record.subtype()==WASConstants.RequestActivitySmfRecordSubtype) {
		   zOSRequestTriplet = rec.m_platformNeutralRequestInfoTriplet;
		   sectionCount = zOSRequestTriplet.count();
		   if (sectionCount > 0)
		   {
	        PlatformNeutralRequestInfoSection sec = rec.m_platformNeutralRequestInfoSection;
            reqType = sec.m_requestType;
            sd.increment(reqType);
            ++request_count;
  	        ++type_counts[reqType];
		   }  else {notRegularWork=1;}
		 
		   asyncWorkDataTriplet = rec.m_asyncWorkDataTriplet;
		   sectionCount = asyncWorkDataTriplet.count();
		   if (sectionCount >0) {
             ++async_work_count;
             sd.asyncWork();
             AsyncWorkDataSection sec = rec.m_asyncWorkDataSection[0];
             receivedTime = STCK.toString(ConversionUtilities.longByteArrayToHexString(sec.m_executionStartTime)).replace(',',' ');
             receivedTimeMS = (new BigInteger(ConversionUtilities.longByteArrayToHexString(sec.m_executionStartTime),16).shiftRight(12).longValue())/1000L;
             completeTime = STCK.toString(ConversionUtilities.longByteArrayToHexString(sec.m_executionCompleteTime)).replace(',',' ');
             completeTimeMS = (new BigInteger(ConversionUtilities.longByteArrayToHexString(sec.m_executionCompleteTime),16).shiftRight(12).longValue())/1000L;
		   } else{
			   notAsyncWork=1;
			   zOSRequestTriplet = rec.m_zosRequestInfoTriplet;
			   sectionCount = zOSRequestTriplet.count();
			   // If we have the zOS request info section
		       if (sectionCount>0)
		       {
		        ZosRequestInfoSection sec = rec.m_zosRequestInfoSection;
 			    receivedTime = STCK.toString(ConversionUtilities.longByteArrayToHexString(sec.m_received)).replace(',',' ');
			    receivedTimeMS = (new BigInteger(ConversionUtilities.longByteArrayToHexString(sec.m_received),16).shiftRight(12).longValue())/1000L;
			    completeTime = STCK.toString(ConversionUtilities.longByteArrayToHexString(sec.m_complete)).replace(',',' ');
			    completeTimeMS = (new BigInteger(ConversionUtilities.longByteArrayToHexString(sec.m_complete),16).shiftRight(12).longValue())/1000L;
			    
			    respRatio = sec.m_EnclaveDeleteRespTimeRatio;
			    if (respRatio>100) {
			    	sd.missedGoal_count();
			    	++missed_goal_count;
			    }
		       } 
		   }
		 
		   sd.setEarliestTime(receivedTime, receivedTimeMS);
		   sd.setLatestTime(completeTime, completeTimeMS);
		 
		 
	      if ((notRegularWork==1)&&(notAsyncWork==1)){
	      	System.out.println("Hmmmm...not async and not regular work...how odd");
	      }
	     } else if (record.subtype() == WASConstants.OutboundRequestSmfRecordSubtype) {
	    	 sd.outboundWork();
	     }
	}	
	
	public void processingComplete() {
		smf_printstream.println("System,Cell,Node,Cluster,Server,Level,Requests,MissedGoal,Unknown,IIOP,HTTP,HTTPS,MDBA,MDBB,MDBC,SIP,SIPS,MBEAN,OTS,OTHER,WOLA,ASYNC,Outbound,Earliest,Latest");
		Iterator serverIT = servers.keySet().iterator();
		while (serverIT.hasNext()) {
			
			String servername = (String)serverIT.next();
			ServerData svd = (ServerData)servers.get(servername);
			String line = new String(svd.sysname()+","+svd.cell()+","+svd.node()+","+svd.cluster()+","+servername+","+svd.level()+","+svd.total_count()+
					","+svd.getMissedGoal_count());
			for (int i=0;i<=PlatformNeutralRequestInfoSection.TypeMax;++i) {
				line =line + ","+svd.type_count(i);
			}
			line = line + "," + svd.getAsyncWork() + "," + svd.getOutboundWork() + "," + svd.Earliest() + "," + svd.Latest();
			smf_printstream.println(line);
		}
		
		String last_line = new String("Totals,,,,,,"+request_count+","+missed_goal_count);
		for (int i=0;i<=PlatformNeutralRequestInfoSection.TypeMax;++i) {
			last_line =last_line + ","+type_counts[i];
		}
		last_line = last_line + "," + async_work_count+","+outbound_request_count;
		smf_printstream.println(last_line);
	}	
	
	public HashMap getServers() {return servers;}
	
	/**
	 * A little sub-class to hold data about a particular server.
	 */
	public class ServerData {
		private String name;
		private String cell;
		private String node;
		private String cluster;
		private String sysname;
		private String level;
		private int total_count;
		private int async_count;
		private int outbound_count;
		private int missedGoal_count;
		private int[] type_counts = new int[PlatformNeutralRequestInfoSection.TypeMax+1];
		private String earliestTime;
		private String latestTime;
		private long earliestTimeMS;
		private long latestTimeMS;
		
		/**
		 * Constructor
		 * @param c the cellname
		 * @param n the node name
		 * @param cl the cluster name
		 * @param s The servername
		 * @param t The system name
		 * @param l the level
		 */
		public ServerData(String c, String n, String cl, String s,String t, String l) {
			cell = c;
			node = n;
			cluster = cl;
			name = s;
			sysname = t;
			level = l;
			total_count = 0;
			async_count = 0;
			outbound_count = 0;
			missedGoal_count=0;
			earliestTime=null;
			latestTime=null;
			earliestTimeMS=0;
			latestTimeMS=0;
            for (int i=0;i<=PlatformNeutralRequestInfoSection.TypeMax;++i) {
            	type_counts[i] = 0;
            }
		}
		
		
		/**
		 * Get the cell name
		 * @return The server name
		 */
		public String cell() {return cell;}
		/**
		 * Get the node name
		 * @return The server name
		 */
		public String node() {return node;}
		/**
		 * Get the cluster name
		 * @return The server name
		 */
		public String cluster() {return cluster;}
		/**
		 * Get the server name
		 * @return The server name
		 */
		public String name() {return name;}
		
		/**
		 * Get the system name for this server
		 * @return the system name
		 */
		public String sysname() {return sysname;}

		/**
		 * Get the level string for this server
		 * @return the level string
		 */
		public String level() {return level;}
		
		/**
		 * Increment counters for work of the specified type
		 * @param type the type of word for the record being processed
		 */
		public void increment(int type) {
			++total_count;
			++type_counts[type];
		}
		
		/**
		 * Increment the count of async work records seen for this server
		 */
		public void asyncWork() {++async_count;}
		
		/**
		 * Get the async work count
		 * @return the async work count
		 */
		public int getAsyncWork() {return async_count;}
		
		/**
		 * Increment the count of outbound requests seen for this server
		 */
		public void outboundWork() {++outbound_count;}
		
		/**
		 * Get the outbound request count
		 * @return count of outbound requests
		 */
		public int getOutboundWork() {return outbound_count;}
		
		/**
		 * Increment the count of requests that missed the goal threshold
		 */
		public void missedGoal_count() {++missedGoal_count;}
		
		/**
		 * Get the count of requests that missed the goal threshold
		 * @return count of requests
		 */
		public int getMissedGoal_count() {return missedGoal_count;}
		
		
		/**
		 * Get the total count of work processed by this server
		 * @return total count of work for this server
		 */
		public int total_count() {return total_count;}
		
		/**
		 * Get the count of work for the specified type
		 * @param i request type
		 * @return count of work for that type
		 */
		public int type_count(int i) { return type_counts[i];}
		
		/**
		 * If the first time, or if new early time is earlier than saved one, save it
		 * @param t time as a string
		 * @param tms time in milliseconds
		 */
		public void setEarliestTime(String t, long tms) {
			if (earliestTime==null) {
				// First time
				earliestTime = t;
				earliestTimeMS = tms;
			} else if (tms < earliestTimeMS) {
				earliestTime = t;
				earliestTimeMS = tms;
			}
		}

		/**
		 * If the first time, or if new latest time is after saved one, save it
		 * @param t time as a string
		 * @param tms time in milliseconds
		 */
		public void setLatestTime(String t, long tms) {
			if (latestTime==null) {
				// First time
				latestTime = t;
				latestTimeMS = tms;
			} else if (tms > latestTimeMS) {
				latestTime = t;
				latestTimeMS = tms;
			}
		}
		
		/**
		 * Get the earliest time seen by this server
		 * @return time in readable string
		 */
		public String Earliest() {return earliestTime;}
		
		/**
		 * get the latest time seen by this server 
		 * @return time in readable string
		 */
		public String Latest() {return latestTime;}
		
		
	}

	
}		

