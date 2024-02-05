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

import java.util.HashMap;
import java.util.Iterator;
import java.util.Set;
import java.util.TreeSet;

import com.ibm.smf.format.DefaultFilter;
import com.ibm.smf.format.SMFFilter;
import com.ibm.smf.format.SmfPrintStream;
import com.ibm.smf.format.SmfRecord;
import com.ibm.smf.format.Triplet;
import com.ibm.smf.twas.request.RequestActivitySmfRecord;
import com.ibm.smf.twas.request.ZosRequestInfoSection;
import com.ibm.smf.was.common.WASConstants;
import com.ibm.smf.utilities.ConversionUtilities;
import com.ibm.smf.utilities.STCK;


/**
 * Produces a CSV file with one row per second requests arrived with a count
 * of the number of requests that arrived (in the CR) in that second. 
 */
public class RequestDensity implements SMFFilter {
	private SmfPrintStream smf_printstream = null;
	private HashMap table = new HashMap();
	private int unique_times = 0;
	
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

	public void processRecord(SmfRecord record) 
	{
     // cast to a subtype 9 and declare generic variables
	 RequestActivitySmfRecord rec = (RequestActivitySmfRecord)record;
	 Triplet zOSRequestTriplet;
	 int sectionCount;
    
	 // Ignore Async work records...
	 zOSRequestTriplet = rec.m_asyncWorkDataTriplet;
	 sectionCount = zOSRequestTriplet.count();
	 if (sectionCount >0) {
		 return;
	 }

	 // From the zOS request section
	 zOSRequestTriplet = rec.m_zosRequestInfoTriplet;
	 sectionCount = zOSRequestTriplet.count();
	 // If we have the zOS request info section
     if (sectionCount>0)
     {
      ZosRequestInfoSection sec = rec.m_zosRequestInfoSection;
         
      String time;
      TimeData td;
      // Add received time
      time =  STCK.toString(ConversionUtilities.longByteArrayToHexString(sec.m_received)).replace(',',' ');
      td = findTimeData(time);
      td.addCr();      

      // Add queued time
      time =  STCK.toString(ConversionUtilities.longByteArrayToHexString(sec.m_queued)).replace(',',' ');
      td = findTimeData(time);
      td.addQ();      

      // Add dispatched time
      time =  STCK.toString(ConversionUtilities.longByteArrayToHexString(sec.m_dispatched)).replace(',',' ');
      td = findTimeData(time);
      td.addDisp();
      
      // Add dispatched completed
      time =  STCK.toString(ConversionUtilities.longByteArrayToHexString(sec.m_dispatchcomplete)).replace(',',' ');
      td = findTimeData(time);
      td.addComp();      
      
     }
	}
	
	private TimeData findTimeData(String t) {
	  TimeData td;
      td = (TimeData)table.get(t);
      if (td==null)
      {
       td = new TimeData(t);
       table.put(t,td);
       ++unique_times;
      }
      return td;
	}
	
	
	public void processingComplete() 
	{
	 // Sort 'em
     Iterator it = (table.keySet()).iterator();
     Set set = table.keySet();
     TreeSet treeset = new TreeSet();
     while (it.hasNext())
     {
      treeset.add(it.next());
     }
     it = treeset.iterator();
     
     smf_printstream.println("Time,In CR,In Q,In Disp,In Comp");

     // Iterate over 'em
     while (it.hasNext())
	 {
      // Get the URI from the iterator
      String time_s = (String)it.next();
      //Get the data for this time
      TimeData td = (TimeData)table.get(time_s);
      // Print the data from the Servant
      smf_printstream.println(time_s+","+td.inCr()+","+td.inQueue()+","+td.inDispatch()+","+td.inCompletion());     
	 }
	}
	
	public class TimeData {
		private int inCR;
		private int inQueue;
		private int inDispatch;
		private int inCompletion;
		private String time;
		
		public TimeData(String t) {
			time = t;
			inCR=0;
			inQueue=0;
			inDispatch=0;
			inCompletion=0;
		}

		public void addCr() {++inCR; }
		public void addQ() {++inQueue; }
		public void addDisp() {++inDispatch;}
		public void addComp() {++inCompletion;}
		
		public int inCr() {return inCR;}
		public int inQueue() {return inQueue;}
		public int inDispatch() {return inDispatch;}
		public int inCompletion() {return inCompletion;}
		
	}
}
