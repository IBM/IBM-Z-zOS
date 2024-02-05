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
public class RequestDensity2 implements SMFFilter {
	private SmfPrintStream smf_printstream = null;
	private HashMap table = new HashMap();
	private int outputFormat = 0;  // 0=CSV, 1=HTML
	
	public boolean initialize(String parms) 
	{
	 boolean return_value = true;
	 smf_printstream = DefaultFilter.commonInitialize(parms);
	 if (smf_printstream==null)
	      return_value = false;
	 if (parms.endsWith(".html")) {
		 outputFormat=1;
	 } // else assume CSV
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

      // Get all timestamps in milliseconds
      long receiveTime = (new BigInteger(ConversionUtilities.longByteArrayToHexString(sec.m_received),16).shiftRight(12).longValue())/1000L;
      long queuedTime = (new BigInteger(ConversionUtilities.longByteArrayToHexString(sec.m_queued),16).shiftRight(12).longValue())/1000L;
      long dispatchStart= (new BigInteger(ConversionUtilities.longByteArrayToHexString(sec.m_dispatched),16).shiftRight(12).longValue())/1000L;
      long dispatchEnd = (new BigInteger(ConversionUtilities.longByteArrayToHexString(sec.m_dispatchcomplete),16).shiftRight(12).longValue())/1000L;
      long responded = (new BigInteger(ConversionUtilities.longByteArrayToHexString(sec.m_complete),16).shiftRight(12).longValue())/1000L;
      
      String time;
      TimeData td;
      long currentTime;
      
      // Add received time
      time =  STCK.toString(ConversionUtilities.longByteArrayToHexString(sec.m_received)).replace(',',' ');
      td = findTimeData(time);
      td.addCr();

      // Now then, if it was in the CR for more than 1 second (1000ms) then we need to handle those seconds also
   	  currentTime = receiveTime+1000L;
   	  while (currentTime<queuedTime) {
   		  time = STCK.toString(currentTime).replace(',',' ');
   		  td = findTimeData(time);
   		  td.addCr();
   		  currentTime=currentTime+1000L;
   	  }
 
      // Add queued time
      time =  STCK.toString(ConversionUtilities.longByteArrayToHexString(sec.m_queued)).replace(',',' ');
      td = findTimeData(time);
      td.addQ();      

      // Now then, if it was in the queue for more than 1 second (1000ms) then we need to handle those seconds also
   	  currentTime = queuedTime+1000L;
   	  while (currentTime<dispatchStart) {
   		  time = STCK.toString(currentTime).replace(',',' ');
   		  td = findTimeData(time);
   		  td.addQ();
   		  currentTime=currentTime+1000L;
   	  }
      
      // Add dispatched time
      time =  STCK.toString(ConversionUtilities.longByteArrayToHexString(sec.m_dispatched)).replace(',',' ');
      td = findTimeData(time);
      td.addDisp();

      // Now then, if it was in dispatch for more than 1 second (1000ms) then we need to handle those seconds also
   	  currentTime = dispatchStart+1000L;
   	  while (currentTime<dispatchEnd) {
   		  time = STCK.toString(currentTime).replace(',',' ');
   		  td = findTimeData(time);
   		  td.addDisp();
   		  currentTime=currentTime+1000L;
   	  }
      
      
      // Add dispatched completed
      time =  STCK.toString(ConversionUtilities.longByteArrayToHexString(sec.m_dispatchcomplete)).replace(',',' ');
      td = findTimeData(time);
      td.addComp();

      // Now then, if it was in completion for more than 1 second (1000ms) then we need to handle those seconds also
   	  currentTime = dispatchEnd+1000L;
   	  while (currentTime<responded) {
   		  time = STCK.toString(currentTime).replace(',',' ');
   		  td = findTimeData(time);
   		  td.addComp();
   		  currentTime=currentTime+1000L;
   	  }
      
     }
	}
	
	private TimeData findTimeData(String t) {
	  TimeData td;
      td = (TimeData)table.get(t);
      if (td==null)
      {
       td = new TimeData(t);
       table.put(t,td);
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
     
     if (outputFormat==0)  // CSV
     {	 
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
     else // must be HTML
     {
      String times = new String("labels :[");
      String dataInCr = new String("data :[");
      String dataInQueue = new String("data :[");
      String dataInDispatch = new String("data :[");
      String dataInCompletion = new String("data :[");

      
      smf_printstream.println("<!DOCTYPE html>");
      smf_printstream.println("<html>");
      smf_printstream.println("<head>");
      smf_printstream.println("<meta charset=\"ISO-8859-1\">");
      smf_printstream.println("<title>RequestDensity2</title>");
      smf_printstream.println("</head>");
      smf_printstream.println("<body>");
      
      int groupCount = set.size()/600;
      if (set.size()%600!=0) ++groupCount;  // plus one if there is a remainder..
      for (int i=0;i<groupCount;++i){
        smf_printstream.println("<canvas id =\"canvas"+i+"\" width=\"2500\" height=\"800\" style=\"border:2px solid #FF0000;\"></canvas>");
      }  
      smf_printstream.println("<script src=\"Chart.js\"></script>");
      smf_printstream.println("<script type=\"text/javascript\">");

    //Get the context of the canvas element we want to select
      for (int i=0;i<groupCount;++i) {
         smf_printstream.println("var ctx"+i+" = document.getElementById(\"canvas"+i+"\").getContext(\"2d\");");
      }
      
  	  int counter = 1;
  	  int setNumber = 0;
      while (it.hasNext())
	   {

        // Get the URI from the iterator
        String time_s = (String)it.next();
        //Get the data for this time
        TimeData td = (TimeData)table.get(time_s);
        if ((counter==1)||(counter%60==0)) {
          times = times + "\"" + time_s + "\"";
        }
        else {times = times + "\" \"";}
        
        dataInCr = dataInCr + td.inCr();
        dataInQueue = dataInQueue + td.inQueue();
        dataInDispatch = dataInDispatch + td.inDispatch();
        dataInCompletion = dataInCompletion + td.inCompletion();
       
        if (it.hasNext()&&(counter%600!=0)) // not the last one (or last in this set), add commas 
        {
           times = times + ",";
           dataInCr = dataInCr + ",";
           dataInQueue = dataInQueue + ",";
           dataInDispatch = dataInDispatch + ",";
           dataInCompletion = dataInCompletion + ",";
        }
        
        if (counter%600==0)
        {
            // Close 'em out
            times = times + "],";
            dataInCr = dataInCr + "]";
            dataInQueue = dataInQueue + "]";
            dataInDispatch = dataInDispatch + "]";
            dataInCompletion = dataInCompletion + "]";
            
            drawChart(setNumber,times,dataInCr,dataInQueue,dataInDispatch,dataInCompletion);
            ++setNumber;

            // start fresh
            times = new String("labels :[");
            dataInCr = new String("data :[");
            dataInQueue = new String("data :[");
            dataInDispatch = new String("data :[");
            dataInCompletion = new String("data :[");
            counter=1;
        }
        else{
        	++counter;
        }
	   }
      
      // get the left overs
      if (counter%600!=0)
      {
        // Close 'em out
        times = times + "],";
        dataInCr = dataInCr + "]";
        dataInQueue = dataInQueue + "]";
        dataInDispatch = dataInDispatch + "]";
        dataInCompletion = dataInCompletion + "]";

        drawChart(setNumber,times,dataInCr,dataInQueue,dataInDispatch,dataInCompletion);
      }

      
      smf_printstream.println("</script>");
      smf_printstream.println("</body>");
      smf_printstream.println("</html>");

     }
	}
	
	public void drawChart(int setNumber, String times, String dataInCr, String dataInQueue, String dataInDispatch, String dataInCompletion) {
        smf_printstream.println("var data"+setNumber+" = {");
        
        smf_printstream.println(times);
      	
        smf_printstream.println("datasets : [");

        smf_printstream.println("{");
        smf_printstream.println("// Blue is In CR");
        smf_printstream.println("fillColor : \"rgba(0,0,255,0.5)\",");
        smf_printstream.println("strokeColor : \"rgba(0,0,255,1)\",");
        smf_printstream.println("pointColor : \"rgba(220,220,220,1)\",");
        smf_printstream.println("pointStrokeColor : \"#fff\",");
        smf_printstream.println(dataInCr);
        smf_printstream.println("},");
        
        smf_printstream.println("{");
        smf_printstream.println("// Yellow is in Queue");
        smf_printstream.println("fillColor : \"rgba(255,255,0,0.5)\",");
        smf_printstream.println("strokeColor : \"rgba(255,255,0,1)\",");
        smf_printstream.println("pointColor : \"rgba(220,220,220,1)\",");
        smf_printstream.println("pointStrokeColor : \"#fff\",");
        smf_printstream.println(dataInQueue);
        smf_printstream.println("},");
        
        smf_printstream.println("{");
        smf_printstream.println("// Red is In Dispatch");
        smf_printstream.println("fillColor : \"rgba(255,0,0,0.5)\",");
        smf_printstream.println("strokeColor : \"rgba(255,0,0,1)\",");
        smf_printstream.println("pointColor : \"rgba(151,187,205,1)\",");
        smf_printstream.println("pointStrokeColor : \"#fff\",");
        smf_printstream.println(dataInDispatch);
        smf_printstream.println("},");
        
        smf_printstream.println("{");
        smf_printstream.println("// Orange is in Completion");
        smf_printstream.println("fillColor : \"rgba(255,165,0,0.5)\",");
        smf_printstream.println("strokeColor : \"rgba(255,165,0,1)\",");
        smf_printstream.println("pointColor : \"rgba(151,187,205,1)\",");
        smf_printstream.println("pointStrokeColor : \"#fff\",");
        smf_printstream.println(dataInCompletion);
        smf_printstream.println("}");
        
        smf_printstream.println("]");
        smf_printstream.println("}");      

        smf_printstream.println("var options"+setNumber+" = {");
        smf_printstream.println("pointDot : false,");
        smf_printstream.println("datasetFill : false,");
        smf_printstream.println("animation : false");
        smf_printstream.println("}");      

        
        smf_printstream.println("var myNewChart"+setNumber+" = new Chart(ctx"+setNumber+").Line(data"+setNumber+",options"+setNumber+");");		
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
