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
import java.util.Set;
import java.util.TimeZone;
import java.util.TreeSet;

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


// Different from ThreadRequestDensity because it uses the dispatch end time instead of start.
// Won't matter for sub-second (or even sub-minute) dispatches, but for long ones it gives a different view
// (or maybe if things are hanging....)
/**
 * Produces a minute by minute summary of the number of requests that END
 * dispatch on each TCB in each servant region. 
 * Contrast with ThreadRequestDensity which uses the Begin-Dispatch time.
 * Generally this doesn't matter with one-minute granularity, but it might someday.
 */
public class ThreadRequestDensity2 implements SMFFilter {

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
	      Date dt = STCK.toDate(ConversionUtilities.longByteArrayToHexString(sec.m_dispatchcomplete));
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

	      
	      byte [] stoken = sec.m_dispatchServantStoken;
	      String stoken_s = ConversionUtilities.longByteArrayToHexString(stoken);
	      
	      
	      byte [] tcb = sec.m_dispatchServantTcbAddress;
	      String tcb_s = ConversionUtilities.intByteArrayToHexString(tcb);
	      
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
	      
	      LinkedList ll = srd.getAllThreads();
	      if (!!!ll.contains(tcb_s)) {
	    	  ll.add(tcb_s);
	      }
	      
	      
	      DayData dd = (DayData)srd.getDays().get(Day);
	      if (dd==null) {
	    	  dd = new DayData(day);
	    	  srd.getDays().put(Day,dd);
	      }
	      
	      HourData hd = (HourData)dd.getHours().get(Hour);
	      if (hd==null){
	    	  hd = new HourData(hour);
	    	  dd.getHours().put(Hour, hd);
	      }

	      MinuteData md = (MinuteData)hd.getMinutes().get(Minute);
	      if (md == null) {
	    	  md = new MinuteData(minute);
	    	  hd.getMinutes().put(Minute,md);
	      }
	      
	      SecondData sd = (SecondData)md.getSeconds().get(Second);
	      if (sd == null) {
	    	  sd = new SecondData(second);
	    	  md.getSeconds().put(Second,sd);
	      }
	           
	      Integer counterI = (Integer)dd.getThreadData().get(tcb_s);
	      if (counterI==null) {
	    	  dd.getThreadData().put(tcb_s,new Integer(1));
	      } else  {
	    	  counterI = counterI + 1;
	    	  dd.getThreadData().put(tcb_s, counterI);
	      }
	      
	      counterI = (Integer)hd.getThreadData().get(tcb_s);
	      if (counterI==null) {
	       hd.getThreadData().put(tcb_s,new Integer(1));
	      } else  {
	       counterI = counterI + 1;
	       hd.getThreadData().put(tcb_s,counterI);
	      }
  
	      counterI = (Integer)md.getThreadData().get(tcb_s);
	      if (counterI==null) {
	       md.getThreadData().put(tcb_s,new Integer(1));
	      }  else  {
	       counterI = counterI + 1;
	       md.getThreadData().put(tcb_s,counterI);
	      }
	      
	      counterI = (Integer)sd.getThreadData().get(tcb_s);
	      if (counterI==null) {
	       sd.getThreadData().put(tcb_s,new Integer(1));
	      } else {
	       counterI = counterI + 1;
	       sd.getThreadData().put(tcb_s,counterI);
	      }

	      counterI = (Integer)srd.getTotalByThread().get(tcb_s);
	      if (counterI == null) {
	    	srd.getTotalByThread().put(tcb_s,new Integer(1));
	      } else {
	    	counterI = counterI + 1;
	    	srd.getTotalByThread().put(tcb_s,counterI);
	      }
	      
	      
	     }  
	}

	
	public void processingComplete() {
		
		Iterator serverIT = servers.keySet().iterator();
		while (serverIT.hasNext()) {
			
			String servername = (String)serverIT.next();
			ServerData svd = (ServerData)servers.get(servername);
			
			Iterator servantIT = svd.getServants().keySet().iterator();
			while (servantIT.hasNext()) {
				
				String servant = (String)servantIT.next();
				ServantData srd = (ServantData)svd.getServants().get(servant);
				
				smf_printstream.println("Data for Server "+servername+" in servant "+srd.servantSTC()+" with stoken "+servant);
				
				LinkedList ll = srd.getAllThreads();
				
				// print header
				Iterator threadIT = ll.descendingIterator();
				String header = new String("Day,Hour,Minute");
				while (threadIT.hasNext()) {
					header = header + "," + (String)threadIT.next();
				}
				header = header + ",Total,ThreadsUsed";
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
							
							String result = Day.toString() + "," + Hour.toString() + "," + Minute.toString();
							int total = 0; 
							int threadsUsed = 0;
							
							threadIT = ll.descendingIterator();
							while (threadIT.hasNext()) {
								
								String s = (String)threadIT.next();
								Integer i = (Integer)md.getThreadData().get(s);
							
								if (i!=null) {
								  result = result + "," + i.toString();
								  total = total + i.intValue();
								  ++threadsUsed;
								} else {
									result = result + ",0";
								}		
							}
							result = result + "," + total + "," + threadsUsed;
							smf_printstream.println(result);
						}
					}					
				}
				String totalResult = "Total,,";
				int grandTotal = 0;
				threadIT = ll.descendingIterator();
				while (threadIT.hasNext()) {
					
					String s = (String)threadIT.next();
					Integer i = (Integer)srd.getTotalByThread().get(s);
				
					if (i!=null) {
					  totalResult = totalResult + "," + i.toString();
					  grandTotal = grandTotal + i.intValue();
					} else {
						totalResult = totalResult + ",0";
					}		
				}
				totalResult = totalResult + "," + grandTotal;
				smf_printstream.println(totalResult);
				
				smf_printstream.println(" ");				
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
		private LinkedList allThreads = new LinkedList();
		private HashMap totalByThread = new HashMap();
		
		public ServantData(String s) {servantID = s;}
		public String getID() {return servantID; }
		public void servantSTC(String s) { servantSTC= s;}
		public String servantSTC() {return servantSTC;}
		public LinkedList getAllThreads() {return allThreads;}
		public HashMap getDays() {return days;}
		public HashMap getTotalByThread() {return totalByThread;}
	}
	
	public class DayData {
		private int day;
		private HashMap hours = new HashMap();
		
		public DayData(int i) {day = i;}
		public int getDay() {return day;}
		public HashMap getHours() {return hours;}
		private HashMap threadData = new HashMap();
		public HashMap getThreadData() {return threadData; }

	}
	
	public class HourData {
		private int hour;
		private HashMap minutes = new HashMap();
		private HashMap threadData = new HashMap();
		
		public HourData(int i) {
			hour =i;
		}
		
		public int getHour() { return hour; }
		
		public HashMap getMinutes() { return minutes; }
		public HashMap getThreadData() {return threadData; }
		
	}
	
	public class MinuteData {
		private int minute;
		private HashMap seconds = new HashMap();
		private HashMap threadData = new HashMap();
		
		public MinuteData(int i) {
			minute= i;
		}
		
		public int getMinute() {return minute; }
		public HashMap getSeconds() {return seconds; }
		public HashMap getThreadData() {return threadData; }
	}
	
	
	public class SecondData {
		private int second;
		private HashMap threadData = new HashMap();
		
		public SecondData(int i) {
			second = i;
		}
		
		public int getSecond() {return second; }
		
		public HashMap getThreadData() {return threadData; }
	}
	
	
}
