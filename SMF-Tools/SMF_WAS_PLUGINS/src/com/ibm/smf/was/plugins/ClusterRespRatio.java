/*                                                                   */
/* Copyright 2021 IBM Corp.                                          */
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

import com.ibm.smf.format.DefaultFilter;
import com.ibm.smf.format.SMFFilter;
import com.ibm.smf.format.SmfPrintStream;
import com.ibm.smf.format.SmfRecord;
import com.ibm.smf.format.Triplet;
import com.ibm.smf.twas.request.RequestActivitySmfRecord;
import com.ibm.smf.twas.request.ZosRequestInfoSection;
import com.ibm.smf.was.common.PlatformNeutralSection;
import com.ibm.smf.was.common.WASConstants;

public class ClusterRespRatio implements SMFFilter {
	
	private SmfPrintStream smf_printstream = null;
	private HashMap clusters = new HashMap();

	 
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
	 if (record.type()== WASConstants.SmfRecordType) {
	   if (record.subtype()==WASConstants.RequestActivitySmfRecordSubtype) {
	         ok_to_process = true;
	   }      
	 } 
     return ok_to_process;
	}

	public void processRecord(SmfRecord record) {
		
		int sectionCount;
		String clustername=null;
		int respRatio = 0;
		Triplet zOSRequestTriplet=null;
	    RequestActivitySmfRecord rec = null;
		PlatformNeutralSection psec = null;

		
	    // cast to a subtype 9 and declare generic variables
		rec = (RequestActivitySmfRecord)record;
	    zOSRequestTriplet = rec.m_platformNeutralSectionTriplet;
	    sectionCount = zOSRequestTriplet.count();
	    
		 if (sectionCount>0)
		 {
		  psec = rec.m_platformNeutralSection;
          clustername = psec.m_clusterShortName;
		 }

		 zOSRequestTriplet = rec.m_zosRequestInfoTriplet;
		 sectionCount = zOSRequestTriplet.count();
		 // If we have the zOS request info section
	     if (sectionCount>0)
	     {
	      ZosRequestInfoSection sec = rec.m_zosRequestInfoSection;
		    
		  respRatio = sec.m_EnclaveDeleteRespTimeRatio;
		  if (respRatio>100) {
			  ClusterData cd = (ClusterData)clusters.get(clustername);
			  if (cd==null) {
				  cd = new ClusterData(clustername);
				  clusters.put(clustername, cd);
			  }	 
			  cd.missedGoal_count();
		   }
	      } 
	}
		

	public void processingComplete() {
		smf_printstream.println("Cluster,MissedGoal");
		Iterator clusterIT = clusters.keySet().iterator();
		while (clusterIT.hasNext()) {
			
			String clusterName = (String)clusterIT.next();
			ClusterData svd = (ClusterData)clusters.get(clusterName);
			String line = new String(svd.cluster() + "," + svd.getMissedGoal_count());
			smf_printstream.println(line);
		}
	}	

	/**
	 * A little sub-class to hold data about a particular server.
	 */
	public class ClusterData {
		private String cluster;
		private int missedGoal_count;
		
		/**
		 * Constructor
		 * @param c the cellname
		 * @param n the node name
		 * @param cl the cluster name
		 * @param s The servername
		 * @param t The system name
		 * @param l the level
		 */
		public ClusterData(String cl) {
			cluster = cl;
			missedGoal_count=0;
		}
		
		
		/**
		 * Get the cluster name
		 * @return The server name
		 */
		public String cluster() {return cluster;}
		
		/**
		 * Increment the count of requests that missed the goal threshold
		 */
		public void missedGoal_count() {++missedGoal_count;}
		
		/**
		 * Get the count of requests that missed the goal threshold
		 * @return count of requests
		 */
		public int getMissedGoal_count() {return missedGoal_count;}
			
	}
}
