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

package com.ibm.smf.liberty.batch;

import java.io.UnsupportedEncodingException;

import com.ibm.smf.format.SmfPrintStream;
import com.ibm.smf.format.SmfRecord;
import com.ibm.smf.format.Triplet;
import com.ibm.smf.format.UnsupportedVersionException;
import com.ibm.smf.was.common.UserDataSection;
import com.ibm.smf.was.common.WASSmfRecord;

/**
 * 
 * Formats the SMF 120.12 Liberty Batch Record
 */
public class LibertyBatchRecord extends WASSmfRecord{
	
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

	  /** Subsystem Info Section Triplet */
	  public Triplet m_LibertyBatchSubsystemSectionTriplet;
	  
	  /** Triplet for identification section */
	  public Triplet m_LibertyBatchIdentificationSectionTriplet;
	  
	  /** Triplet for completion section */
	  public Triplet m_LibertyBatchCompletionSectionTriplet;
	  
	  /** Triplet for processor section */
	  public Triplet m_LibertyBatchProcessorSectionTriplet;
	  
	  /** Triplet for Accounting section */
	  public Triplet m_LibertyBatchAccountingSectionTriplet;
	  
	  /** Triplet for USS section */
	  public Triplet m_LibertyBatchUssSectionTriplet;
	  
	  /** Triplet for Reference Names section */
	  public Triplet m_LibertyBatchReferenceNamesSectionTriplet;
	  
	  /** Triplet for user data from the request dispatch */
	  public Triplet m_userDataTriplet;
	  
	  /*---------------------------------------------------------------------------*/
	  
	  /** Subsystem Data section */
	  public LibertyBatchSubsystemSection m_libertyBatchSubsystemSection;
	  
	  /** Identification section */
	  public LibertyBatchIdentificationSection m_identificationSection;
	  
	  /** Completion Section */
	  public LibertyBatchCompletionSection m_completionSection;
	  
	  /** Processor section */
	  public LibertyBatchProcessorSection m_processorSection;

	  /** Accounting Sections */
	  public LibertyBatchAccountingSection[] m_accountingSection;
	  
	  /** USS Section */
	  public LibertyBatchUssSection m_ussSection;
	  
	  /** Reference names section */
	  public LibertyBatchReferenceNamesSection[] m_referenceNamesSection;
	  
	  /** User data section(s) */
	  public UserDataSection[] m_userDataSection;
	
	  
	  /**
	   * Create an SMF 120.12 (Liberty Batch Record) object.
	   * @param aSmfRecord The SMF record
	   * @throws UnsupportedVersionException unknown version
	   * @throws UnsupportedEncodingException problems with text string encoding
	   */
	  public LibertyBatchRecord(SmfRecord aSmfRecord)
			  throws UnsupportedVersionException, UnsupportedEncodingException {

		  
			   super(aSmfRecord); // pushes the print stream once

			   m_subtypeVersion = m_stream.getInteger(4);         
			    
			   m_tripletN = m_stream.getInteger(4);                                      
			    
			   m_recordIndex = m_stream.getInteger(4);
			    
			   m_totalNumberOfRecords = m_stream.getInteger(4);
			    
			   m_recordContinuationToken = m_stream.getByteBuffer(8);

			   m_LibertyBatchSubsystemSectionTriplet = new Triplet(m_stream);

			   m_LibertyBatchIdentificationSectionTriplet = new Triplet(m_stream);
			    
			   m_LibertyBatchCompletionSectionTriplet = new Triplet(m_stream);
			    
			   m_LibertyBatchProcessorSectionTriplet = new Triplet(m_stream);
			    
			   m_LibertyBatchAccountingSectionTriplet = new Triplet(m_stream);
			    
			   m_LibertyBatchUssSectionTriplet = new Triplet(m_stream);
			    
			   m_LibertyBatchReferenceNamesSectionTriplet = new Triplet(m_stream);
			    
			   m_userDataTriplet = new Triplet(m_stream);
			    
		       m_libertyBatchSubsystemSection = new LibertyBatchSubsystemSection(m_stream);
		        
		       m_identificationSection = new LibertyBatchIdentificationSection(m_stream);
		       
		       m_completionSection = new LibertyBatchCompletionSection(m_stream);

	           if (m_LibertyBatchProcessorSectionTriplet.count() > 0) {
			       m_processorSection = new LibertyBatchProcessorSection(m_stream); 	        	   
	           }
		        
		       if (m_LibertyBatchAccountingSectionTriplet.count() > 0)
		       {
			      m_accountingSection = new LibertyBatchAccountingSection[m_LibertyBatchAccountingSectionTriplet.count()];
				  for (int i=0; i < m_LibertyBatchAccountingSectionTriplet.count(); i++)
				  {
				    m_accountingSection[i] = new LibertyBatchAccountingSection(m_stream); 
				  }		    	   
		       }
		        
		       m_ussSection = new LibertyBatchUssSection(m_stream);
		       
			   if (m_LibertyBatchReferenceNamesSectionTriplet.count() > 0) {
				   m_referenceNamesSection = new LibertyBatchReferenceNamesSection[m_LibertyBatchReferenceNamesSectionTriplet.count()];
				   
				   for (int i=0; i < m_LibertyBatchReferenceNamesSectionTriplet.count(); i++) {
				    	 m_referenceNamesSection[i] = new LibertyBatchReferenceNamesSection(m_stream); 					   
				   }
			   }			    

			   if (m_userDataTriplet.count() > 0)
			   {
			     m_userDataSection = new UserDataSection[m_userDataTriplet.count()];
			     for (int i=0; i < m_userDataTriplet.count(); i++)
			     {
			       m_userDataSection[i] = UserDataSection.loadUserDataFormatter(m_stream,12,m_userDataTriplet.length()); 
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
	    
	    m_LibertyBatchSubsystemSectionTriplet.dump(aPrintStream, 1);
	    m_LibertyBatchIdentificationSectionTriplet.dump(aPrintStream,2);
	    m_LibertyBatchCompletionSectionTriplet.dump(aPrintStream,3);
	    m_LibertyBatchProcessorSectionTriplet.dump(aPrintStream,4);
	    m_LibertyBatchAccountingSectionTriplet.dump(aPrintStream,5);
	    m_LibertyBatchUssSectionTriplet.dump(aPrintStream,6);
	    m_LibertyBatchReferenceNamesSectionTriplet.dump(aPrintStream,7);
	    m_userDataTriplet.dump(aPrintStream,8);
	    

	    m_libertyBatchSubsystemSection.dump(aPrintStream,1);
	    
	    m_identificationSection.dump(aPrintStream,2);
	    
	    m_completionSection.dump(aPrintStream,3);
	    
	    if (m_LibertyBatchProcessorSectionTriplet.count() > 0) {
		    m_processorSection.dump(aPrintStream,4);	    	
	    }
	    
	    if (m_LibertyBatchAccountingSectionTriplet.count() > 0)
	    { 
	      for (int i=0; i < m_LibertyBatchAccountingSectionTriplet.count(); i++)
	      {
	    	  m_accountingSection[i].dump(aPrintStream,5);
	      }
	    }
	    
	    
        m_ussSection.dump(aPrintStream,6);	    
	    
	    if (m_LibertyBatchReferenceNamesSectionTriplet.count() > 0)
	    { 
	      for (int i=0; i < m_LibertyBatchReferenceNamesSectionTriplet.count(); i++)
	      {
	    	  m_referenceNamesSection[i].dump(aPrintStream,7);
	      }
	    }
	    
	    if (m_userDataTriplet.count() > 0)
	    { 
	      for (int i=0; i < m_userDataTriplet.count(); i++)
	      {
	    	m_userDataSection[i].dump(aPrintStream,8);
	      }
	    }
	    aPrintStream.pop();
	    
	  }   

}

