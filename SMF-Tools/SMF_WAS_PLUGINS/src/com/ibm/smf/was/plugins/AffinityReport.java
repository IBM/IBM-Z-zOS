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
import com.ibm.smf.was.common.ClassificationDataSection;
import com.ibm.smf.was.common.PlatformNeutralSection;
import com.ibm.smf.was.common.WASConstants;
import com.ibm.smf.utilities.ConversionUtilities;
import com.ibm.smf.utilities.STCK;



/**
 * Produces a CSV report showing server, servant, affinity creation time, affinity token, and use-count.
 * Useful for seeing all the affinities created and how much they were used. 
 */
public class AffinityReport  implements SMFFilter{
	
	private SmfPrintStream smf_printstream = null;
	private HashMap affinities = new HashMap();
	
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

     zOSRequestTriplet = rec.m_platformNeutralSectionTriplet;
     sectionCount = zOSRequestTriplet.count();
     if (sectionCount>0)
     {
      PlatformNeutralSection sec = rec.m_platformNeutralSection;
	  servername = sec.m_serverShortName;
     }
	 
	 zOSRequestTriplet = rec.m_classificationDataTriplet;
	 sectionCount = zOSRequestTriplet.count();
	 String uri = null;

	 // If we have the network info section
     if (sectionCount>0)
     {
    	 for (int i=1;i<=sectionCount;++i) {
    		 ClassificationDataSection cds =  rec.m_classificationDataSection[i-1];
            int type = cds.m_dataType;
            if (type == ClassificationDataSection.TypeURI){
            	uri = cds.m_theData;
            } 
    	 }
     }
     
     
	 zOSRequestTriplet = rec.m_zosRequestInfoTriplet;
	 sectionCount = zOSRequestTriplet.count();
	 // If we have the zOS request info section
     if (sectionCount>0)
     {
      ZosRequestInfoSection sec = rec.m_zosRequestInfoSection;
      servantSTC = sec.m_dispatchServantJobId;   
      int version = sec.m_version;
      if (version>=2) {
   	   int obtained_aff_length = sec.m_obtainedAffinityLength;
   	   int used_aff_length = sec.m_routingAffinityLength;
   	   if (obtained_aff_length >0) {
   		  byte obtained_aff[] = sec.m_obtainedAffinity;
   		  String obtained_aff_s = ConversionUtilities.bytesToHex(obtained_aff);
   		  // Use dispatch-complete as created-time
   		  String createdTime = STCK.toString(ConversionUtilities.longByteArrayToHexString(sec.m_dispatchcomplete)).replace(',',' ');
   		  long dispatchEnd = (new BigInteger(ConversionUtilities.longByteArrayToHexString(sec.m_dispatchcomplete),16).shiftRight(12).longValue())/1000L;

   		  AffinityData ad;
   		  ad = (AffinityData)affinities.get(obtained_aff_s);
   		  if (ad==null) {
   			ad = new AffinityData(obtained_aff_s,createdTime,dispatchEnd);
   			ad.server(servername);
   			ad.servantSTC(servantSTC);
     		affinities.put(obtained_aff_s, ad);
   		  } else {  // apparently we found a used-affinity request for this token before we found the created-affinity request
   			ad.setCreatedTime(createdTime);
   			ad.setCreatedTimeL(dispatchEnd);
   		  }
   		  ad.creatingURI(uri);

   	   } else if (used_aff_length >0) {
   		  byte used_aff[] = sec.m_routingAffinity;
   		  String used_aff_s = ConversionUtilities.bytesToHex(used_aff);
   		  AffinityData ad;
   		  ad = (AffinityData)affinities.get(used_aff_s);
   		  if (ad==null) {
   			  ad = new AffinityData(used_aff_s);  // Fill in the rest later
   			  ad.used();
   			  ad.server(servername);
   			  ad.servantSTC(servantSTC);
   			  affinities.put(used_aff_s, ad);
   		  } else {
   			  ad.used();
   		  }
   	   }
      }	
   	 }
    }	
	
	public void processingComplete() 
	{
	 // Sort 'em
     Iterator it = (affinities.keySet()).iterator();
     
     smf_printstream.println("Created,Created-ms,Server,ServantSTC,Aff-Token,UseCount,CreateURI");

     // Iterate over 'em
     while (it.hasNext())
	 {
      
      String token = (String)it.next();
      //Get the data for this time
      AffinityData ad = (AffinityData)affinities.get(token);
      // Print the data 
      smf_printstream.println(ad.created()+","+ad.createdL()+","+ad.server()+","+ad.servantSTC()+","+ConversionUtilities.stripTrailingZeroes(ad.token())+","+ad.getUsed()+","+ad.creatingURI());
	 }
	}
	
	public class AffinityData {
		private String created;
		private long createdL;
		private String token;
		private int useCount;
		private String server;
		private String servantSTC;
		private String creatingURI;
		
		public AffinityData(String t, String c, long cl) {
			created = c;
			token =t;
			createdL = cl;
		}

		public AffinityData(String t) {
			token = t;
		}
		
		public void used() {++useCount;}
		public int getUsed() {return useCount;}
		public void setCreatedTime(String c) {created= c;}
		public String created() {return created;}
		public void setCreatedTimeL(long cl) {createdL = cl;}
		public long createdL() {return createdL;}
		public void server(String s) {server=s;}
		public String server() {return server;}
		public String token() {return token;}
		public void servantSTC(String s) {servantSTC = s;}
		public String servantSTC() {return servantSTC;}
		public void creatingURI(String s) {creatingURI = s;}
		public String creatingURI() {return creatingURI;}
		
	}
	
	
}
