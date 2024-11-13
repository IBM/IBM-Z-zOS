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

package com.ibm.smf.liberty.request;

import java.io.UnsupportedEncodingException;

import com.ibm.smf.format.SkipFilteredRecord;
import com.ibm.smf.format.SmfPrintStream;
import com.ibm.smf.format.SmfRecord;
import com.ibm.smf.format.Triplet;
import com.ibm.smf.format.UnsupportedVersionException;
import com.ibm.smf.was.common.ClassificationDataSection;
import com.ibm.smf.was.common.UserDataSection;
import com.ibm.smf.was.common.WASSmfRecord;


/**
 * 
 * Formats the SMF 120.11 Liberty Request Record
 */
public class LibertyRequestRecord extends WASSmfRecord{
	
	  /** Supported version of this implementation. */
	  public final static int s_supportedVersion = 3; 
	  
	  /** Subtype Version number */
	  public int m_subtypeVersion;

	  /** Number of triplets contained in this instance. */
	  public int m_tripletN;
	  
	  /** index number of this record */
	  public int m_recordIndex;
	  
	  /** total number of records */
	  public int m_totalNumberOfRecords;
	  
	  /** record continuation token */
	  public byte m_recordContinuationToken[];

	  /** Platform Neutral Server Info section triplet */
	  public Triplet m_LibertyServerInfoSectionTriplet;
	  
	  /** Triplet for user data from the request dispatch */
	  public Triplet m_userDataTriplet;
	  
	  /** Request Data Triplet */
  	  public Triplet m_requestDataTriplet;
  	  
  	  /** Classification Data Triplet */
  	  public Triplet m_classificationDataTriplet;
  	  
  	  /** Network Data Triplet */
  	  public Triplet m_networkDataTriplet; 
	  
	  /** The Server Information Section */
	  public LibertyServerInfoSection m_libertyServerInfoSection;
	  
	  /** User data section(s) */
	  public UserDataSection[] m_userDataSection;
	
	  /** Request Info section */
	  public LibertyRequestInfoSection m_libertyRequestInfoSection;
	  
	  /** Network Data Section */
	  public LibertyNetworkDataSection m_libertyNetworkDataSection;
	  
	  /** Classification Data Section */
	  public ClassificationDataSection[] m_classificationDataSection;	  
	  
	  /**
	   * Create an SMF 120.11 (Liberty Request Record) object.
	   * @param aSmfRecord The SMF record
	   * @throws UnsupportedVersionException unknown version
	   * @throws UnsupportedEncodingException problems with text string encoding
	 * @throws SkipFilteredRecord 
	   */
	  public LibertyRequestRecord(SmfRecord aSmfRecord)
			  throws UnsupportedVersionException, UnsupportedEncodingException, SkipFilteredRecord {

			    super(aSmfRecord); // pushes the print stream once
			    
			    m_subtypeVersion = m_stream.getInteger(4);         
			    
			    m_tripletN = m_stream.getInteger(4);                                      
			    
			    m_recordIndex = m_stream.getInteger(4);
			    
			    m_totalNumberOfRecords = m_stream.getInteger(4);
			    
			    m_recordContinuationToken = m_stream.getByteBuffer(8);
			    
			    m_LibertyServerInfoSectionTriplet = new Triplet(m_stream);
			    
			    m_userDataTriplet = new Triplet(m_stream);
			    
			    if (m_subtypeVersion == 1) {
			    
			       m_libertyServerInfoSection = new LibertyServerInfoSection(m_stream);
			    
			       if (m_userDataTriplet.count() > 0)
			       {
			         m_userDataSection = new UserDataSection[m_userDataTriplet.count()];
			         for (int i=0; i < m_userDataTriplet.count(); i++)
			         {
			           m_userDataSection[i] = UserDataSection.loadUserDataFormatter(m_stream,11,m_userDataTriplet.length()); 
			         }
			       }			    
			    } else {
		            if (m_subtypeVersion == 2 || m_subtypeVersion == 3) {
				    	m_requestDataTriplet = new Triplet(m_stream);
				    	m_classificationDataTriplet = new Triplet(m_stream);
				    	m_networkDataTriplet = new Triplet(m_stream);
					    m_libertyServerInfoSection = new LibertyServerInfoSection(m_stream);
					    
					    if (m_userDataTriplet.count() > 0)
					    {
					      m_userDataSection = new UserDataSection[m_userDataTriplet.count()];
					      for (int i=0; i < m_userDataTriplet.count(); i++)
					      {
					        m_userDataSection[i] = UserDataSection.loadUserDataFormatter(m_stream,11,m_userDataTriplet.length()); 
					      }
					    }		
					    // get request data
					    m_libertyRequestInfoSection = new LibertyRequestInfoSection(m_stream);
					    
					     String s = System.getProperty("com.ibm.ws390.smf.smf1209.RespRatioMin");
					     if (s!=null){
					     	Integer respRatioMin = new Integer(s);
					     	// Skip records that did better than the specified minimum response ratio - just show the problem ones
					     	if (m_libertyRequestInfoSection.m_enclaveDeleteRespTimeRatio<=respRatioMin.intValue()) {
					     		throw new SkipFilteredRecord();
					     	}
					     }    

					    // get classification data
					    if (m_classificationDataTriplet.count() > 0) {
					    	m_classificationDataSection = new ClassificationDataSection[m_classificationDataTriplet.count()];
						      for (int i=0; i < m_classificationDataTriplet.count(); i++) {
						    	  m_classificationDataSection[i] = new ClassificationDataSection(m_stream);
						      }
					    }
					    // get network data
					    m_libertyNetworkDataSection = new LibertyNetworkDataSection(m_stream);
			    	}
			    	
			    }

	  }
	  
	  //----------------------------------------------------------------------------
	  /** Returns the supported version of this class.
	   * @return supported version of this class.
	   */
	  public int supportedVersion() {

	    return s_supportedVersion;

	  }	  
	  
	  //----------------------------------------------------------------------------
	  /** Dumps the object into a print stream.
	   * @param aPrintStream print stream to dump to.
	   */
	  public void dump(SmfPrintStream aPrintStream) {

	    super.dump(aPrintStream);

	    aPrintStream.push();

	    aPrintStream.println("");
	    aPrintStream.printlnKeyValue("#Subtype Version",m_subtypeVersion);
	    aPrintStream.printlnKeyValue("Index of this record",m_recordIndex);
	    aPrintStream.printlnKeyValue("Total number of records",m_totalNumberOfRecords);
	    aPrintStream.printlnKeyValue("record continuation token",m_recordContinuationToken,null);
	    aPrintStream.printlnKeyValue("#Triplets",m_tripletN);
	    m_LibertyServerInfoSectionTriplet.dump(aPrintStream,1);
	    m_userDataTriplet.dump(aPrintStream,2);
        if (m_subtypeVersion == 2 || m_subtypeVersion == 3) {  	
	  	    m_requestDataTriplet.dump(aPrintStream,3);
	  	    m_classificationDataTriplet.dump(aPrintStream,4);
	  	    m_networkDataTriplet.dump(aPrintStream,5);
	    }
	    m_libertyServerInfoSection.dump(aPrintStream,1);
	    if (m_userDataTriplet.count() > 0)
	    { 
	      for (int i=0; i < m_userDataTriplet.count(); i++)
	      {
	    	m_userDataSection[i].dump(aPrintStream,2);
	      }
	    }
        if (m_subtypeVersion == 2 || m_subtypeVersion == 3) {
	        // dump request data
	    	m_libertyRequestInfoSection.dump(aPrintStream,3);
		    // dump classification data
	    	for (int i=0; i < m_classificationDataTriplet.count(); i++) {
	    		m_classificationDataSection[i].dump(aPrintStream, 4);   		
	    	}	
	    	// dump network data
	    	m_libertyNetworkDataSection.dump(aPrintStream,5);
	    }
	    aPrintStream.pop();
	  }   

}
