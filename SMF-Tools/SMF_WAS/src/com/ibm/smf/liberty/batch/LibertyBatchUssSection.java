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

import com.ibm.smf.format.SmfEntity;
import com.ibm.smf.format.SmfPrintStream;
import com.ibm.smf.format.SmfStream;
import com.ibm.smf.format.UnsupportedVersionException;

public class LibertyBatchUssSection extends SmfEntity {

	  /** Supported version of this class. */
	  public final static int s_supportedVersion = 2;  
	  
	  /** version of section. */
	  public int m_version;	  

	  /** process ID */
	  public int m_pid;
	  
	  /** thread ID */
	  public byte [] m_threadId;
	  
	  /** java Thread ID */
	  public byte[] m_javaThreadId;
	  
	  /** submitter unix uid */
	  public int m_uid;

	  /** submitter unix group id */
	  public int m_gid;
	  
	  //----------------------------------------------------------------------------
	  /** Returns the supported version of this class.
	   * @return supported version of this class.
	   */
	  public int supportedVersion() {
	    
	    return s_supportedVersion;
	    
	  } // supportedVersion()
	  
	  public LibertyBatchUssSection(SmfStream aSmfStream) 
			  throws UnsupportedVersionException, UnsupportedEncodingException {
			    
			    super(s_supportedVersion);
			    m_version = aSmfStream.getInteger(4);
			    m_pid = aSmfStream.getInteger(4);
			    m_threadId = aSmfStream.getByteBuffer(8);
			    m_javaThreadId = aSmfStream.getByteBuffer(8);
			    if (m_version >= 2) {
			        m_uid = aSmfStream.getInteger(4);
			        m_gid = aSmfStream.getInteger(4);
			    }
		    
	  }
	  
	  //----------------------------------------------------------------------------
	  /** Dumps the fields of this object to a print stream.
	   * @param aPrintStream The stream to print to.
	   * @param aTripletNumber The triplet number of this LibertyRequestInfoSection.
	   */
	  public void dump(SmfPrintStream aPrintStream, int aTripletNumber) {
	       
	    aPrintStream.println("");
	    aPrintStream.printKeyValue("Triplet #",aTripletNumber);
	    aPrintStream.printlnKeyValue("Type","LibertyUSSSection");

	    aPrintStream.push();
	    
	    aPrintStream.printlnKeyValue("USS Info Version                      ", m_version);
	    aPrintStream.printlnKeyValue("Server pid                            ", m_pid);	
	    aPrintStream.printlnKeyValue("Thread id                             ",m_threadId,null);
	    aPrintStream.printlnKeyValue("Java Thread id                        ",m_javaThreadId,null);
	    if (m_version >=2) {
	        aPrintStream.printlnKeyValue("Submitter uid                         ", m_uid);
	        aPrintStream.printlnKeyValue("Submitter gid                         ", m_gid);	    	
	    }
	    
	    aPrintStream.pop();
	    
	  }	    
}
