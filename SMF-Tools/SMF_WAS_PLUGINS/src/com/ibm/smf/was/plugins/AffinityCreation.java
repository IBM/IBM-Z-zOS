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
import java.util.Set;
import java.util.TimeZone;
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
 * Produces a summary of the number of affinities created per server per servant region.
 * The report can be on a per hour, per minute, or per second basis depending on the
 * setting of com.ibm.ws390.smf.plugins.AffinityCreation.Interval. 
 *
 */
public class AffinityCreation  implements SMFFilter{

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

	public void processRecord(SmfRecord record) 
	{
	 // cast to a subtype 9 and declare generic variables
	 RequestActivitySmfRecord rec = (RequestActivitySmfRecord)record;
	 Triplet zOSRequestTriplet;
	 int sectionCount;
	 String servername=null;
	 String servantSTC=null;

	 
	 // Ignore Async work records...maybe a different CSV handler for those?
	 zOSRequestTriplet = rec.m_asyncWorkDataTriplet;
	 sectionCount = zOSRequestTriplet.count();
	 if (sectionCount >0) {
		 return;
	 }
	 
	 zOSRequestTriplet = rec.m_zosRequestInfoTriplet;
	 sectionCount = zOSRequestTriplet.count();
	 // If we have the zOS request info section
     if (sectionCount>0)
     {
      ZosRequestInfoSection sec = rec.m_zosRequestInfoSection;
      servantSTC = sec.m_dispatchServantJobId;   
      byte [] stoken = sec.m_dispatchServantStoken;
      String stoken_s = ConversionUtilities.longByteArrayToHexString(stoken);
      int version = sec.m_version;
      if (version>=2) {
   	   int obtained_aff_length = sec.m_obtainedAffinityLength;
   	   
       if (obtained_aff_length>0) {
 	      Date dt = STCK.toDate(ConversionUtilities.longByteArrayToHexString(sec.m_dispatched));
 	      Calendar c = Calendar.getInstance();
 	      TimeZone tz = TimeZone.getTimeZone("GMT");
 	      c.setTimeZone(tz);
 	      c.setTime(dt);
 	      int day = c.get(Calendar.DAY_OF_YEAR);
 	      Integer Day = new Integer(day);
 	      int hour = c.get(Calendar.HOUR_OF_DAY);
 	      Integer Hour = new Integer(hour);
 	      int minute = c.get(Calendar.MINUTE);
 	      Integer Minute = new Integer(minute);
 	      int second = c.get(Calendar.SECOND);
 	      Integer Second = new Integer(second);
       
	      ServerData svd = (ServerData)servers.get(servername);
	      if (svd==null) {
	    	  svd = new ServerData(servername);
	    	  servers.put(servername,svd);
	      }
	      
	      ServantData srd = (ServantData)svd.getServants().get(stoken_s);
	      if (srd==null){
	    	  srd = new ServantData(stoken_s);
	    	  srd.servantSTC(sec.m_dispatchServantJobId);
	    	  svd.getServants().put(stoken_s,srd);
	      }
	      DayData dd = (DayData)srd.getDays().get(Day);
	      if (dd==null) {
	    	  dd = new DayData(day);
	    	  srd.getDays().put(Day,dd);
	      }
	      dd.newAffinity();
	      
	      HourData hd = (HourData)dd.getHours().get(Hour);
	      if (hd==null){
	    	  hd = new HourData(hour);
	    	  dd.getHours().put(Hour, hd);
	      }
	      hd.newAffinity();

	      MinuteData md = (MinuteData)hd.getMinutes().get(Minute);
	      if (md == null) {
	    	  md = new MinuteData(minute);
	    	  hd.getMinutes().put(Minute,md);
	      }
	      md.newAffinity();
	      
	      SecondData sd = (SecondData)md.getSeconds().get(Second);
	      if (sd == null) {
	    	  sd = new SecondData(second);
	    	  md.getSeconds().put(Second,sd);
	      }
	      sd.newAffinity();

       }
      }
     }  
	}   
	
	public void processingComplete() {
		
		String interval_s = System.getProperty("com.ibm.ws390.smf.plugins.AffinityCreation.Interval", "Seconds");
		int interval;  // should really be an enum...
		if (interval_s.equalsIgnoreCase("Hours")){
			interval=1;
		} else if (interval_s.equalsIgnoreCase("Minutes")) {
			interval=2;
		} else {
			interval=3;
		}
		
		
		Iterator serverIT = servers.keySet().iterator();
		while (serverIT.hasNext()) {
			
			String servername = (String)serverIT.next();
			ServerData svd = (ServerData)servers.get(servername);
			
			Iterator servantIT = svd.getServants().keySet().iterator();
			while (servantIT.hasNext()) {
				
				String servant = (String)servantIT.next();
				ServantData srd = (ServantData)svd.getServants().get(servant);
				
				smf_printstream.println("Data for Server "+servername+" in servant "+srd.servantSTC()+" with stoken "+servant);
			
				// print header
				String header = new String("Day,Hour");
				if (interval==2) header = header + ",Minute";
				if (interval==3) header = header + ",Minute,Second";
				header = header + ",CreatedAff";
				smf_printstream.println(header);
				
				Iterator daysIT = srd.getDays().keySet().iterator();
			    Set set = srd.getDays().keySet();
			    TreeSet treeset = new TreeSet();
			    while (daysIT.hasNext())
			    {
			     treeset.add(daysIT.next());
			    }
			    daysIT = treeset.iterator();
				while (daysIT.hasNext()) {
					
					Integer Day = (Integer)daysIT.next();
					DayData dd = (DayData)srd.getDays().get(Day);
		

					Iterator hoursIT = dd.getHours().keySet().iterator();
				    set = dd.getHours().keySet();
				    treeset = new TreeSet();
				    while (hoursIT.hasNext())
				    {
				     treeset.add(hoursIT.next());
				    }
				    hoursIT = treeset.iterator();
					while (hoursIT.hasNext()) {
						
						Integer Hour = (Integer)hoursIT.next();
						HourData hd = (HourData)dd.getHours().get(Hour);

						if (interval==1) {
							String result = Day.toString() + "," + Hour.toString() + "," + hd.affinityCount();
							smf_printstream.println(result);
							
						} else {
							
						  Iterator minutesIT = hd.getMinutes().keySet().iterator();
					      set = hd.getMinutes().keySet();
					      treeset = new TreeSet();
					      while (minutesIT.hasNext())
					      {
					       treeset.add(minutesIT.next());
					      }
					      minutesIT = treeset.iterator();
						  while (minutesIT.hasNext()) {
							
							  Integer Minute = (Integer)minutesIT.next();
							  MinuteData md = (MinuteData)hd.getMinutes().get(Minute);
						
							  if (interval==2) {
								    String result = Day.toString() + "," + Hour.toString() + "," + Minute.toString() + "," + md.affinityCount();
								    smf_printstream.println(result);
							  } else {
							  
							    Iterator secondsIT = md.getSeconds().keySet().iterator();
						        set = md.getSeconds().keySet();
						        treeset = new TreeSet();
						        while (secondsIT.hasNext())
						        {
						         treeset.add(secondsIT.next());
						        }
						        secondsIT = treeset.iterator();
							    while (secondsIT.hasNext()) {
							   	    Integer Second  = (Integer)secondsIT.next();
								    SecondData sd = (SecondData)md.getSeconds().get(Second);
								    String result = Day.toString() + "," + Hour.toString() + "," + Minute.toString() + "," + Second.toString() + "," + sd.affinityCount();
								    smf_printstream.println(result);
							    }
							  }
						  }
					  }
					}					
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
		private String servantSTC;
		private HashMap days = new HashMap();
		
		public ServantData(String s) {servantID = s;}
		public String getID() {return servantID; }
		public void servantSTC(String s) { servantSTC= s;}
		public String servantSTC() {return servantSTC;}
		public HashMap getDays() {return days;}
	}
	
	public class DayData {
		private int day;
		private HashMap hours = new HashMap();
		private int affinities;
		
		public DayData(int i) {day = i;}
		public int getDay() {return day;}
		public HashMap getHours() {return hours;}
		public void newAffinity() {++affinities;}
		public int affinityCount() {return affinities;}

	}
	
	public class HourData {
		private int hour;
		private HashMap minutes = new HashMap();
		private int affinities;
		
		public HourData(int i) {
			hour =i;
		}
		
		public int getHour() { return hour; }
		
		public HashMap getMinutes() { return minutes; }
		public void newAffinity() {++affinities;}
		public int affinityCount() {return affinities;}
		
	}
	
	public class MinuteData {
		private int minute;
		private HashMap seconds = new HashMap();
		private int affinities;

		
		public MinuteData(int i) {
			minute= i;
		}
		
		public int getMinute() {return minute; }
		public HashMap getSeconds() {return seconds; }
		public void newAffinity() {++affinities;}
		public int affinityCount() {return affinities;}

	}
	
	
	public class SecondData {
		private int second;
		private int affinities;
		
		public SecondData(int i) {
			second = i;
		}
		
		public int getSecond() {return second; }
		public void newAffinity() {++affinities;}
		public int affinityCount() {return affinities;}
		
	}
       
       
}
