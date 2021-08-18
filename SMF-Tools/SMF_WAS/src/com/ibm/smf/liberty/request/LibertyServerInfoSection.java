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

import com.ibm.smf.format.SmfEntity;
import com.ibm.smf.format.SmfPrintStream;
import com.ibm.smf.format.SmfStream;
import com.ibm.smf.format.SmfUtil;
import com.ibm.smf.format.UnsupportedVersionException;


/**
 * Formats the Server Information Section of the SMF 120.11 record
 *
 */
public class LibertyServerInfoSection extends SmfEntity{
	
	  /** Supported version of this class. */
		public final static int s_supportedVersion = 3;  

		  /** section version. */
		  public int m_version;

		  /** The system name within the interpreted record. */
		  public String m_systemName;

		  /** The sysplex name within the interpreted record. */
		  public String m_sysplexName;

		  /** The controller job ID within the interpreted record. */
		  public String m_jobId;
		  
		  /** The controller job name within the interpreted record. */
		  public String m_jobName;
		  
		  /** Server stoken */
		  public byte m_server_stoken[];
		  
		  /** reserved space */
		  public byte m_reserved[];

		  /** asid */
		  public int m_asid;
		  
		  /** PID */
		  public int m_pid;
		  
		  /** server config directory */
		  public String m_serverConfigDir;
		  
		  /** product version */
		  public String m_productVersion;
		  
          /** flag word */
          public byte[] m_bitFlags = new byte[4];
	         
          /** Bit Masks */
          private final static int MASK_CVTZCBP = 0x80;

		  /**
		   * The Server Information section of the 120.11
		   * @param aSmfStream The SMF data string
		   * @throws UnsupportedVersionException An unknown version
		   * @throws UnsupportedEncodingException Problems with text string encoding
		   */
		  public LibertyServerInfoSection(SmfStream aSmfStream) 
				  throws UnsupportedVersionException, UnsupportedEncodingException {
				    
				    super(s_supportedVersion);

				    m_version = aSmfStream.getInteger(4);
				    
				    m_systemName = aSmfStream.getString(8,SmfUtil.EBCDIC);

				    m_sysplexName =  aSmfStream.getString(8,SmfUtil.EBCDIC);

				    m_jobId = aSmfStream.getString(8,SmfUtil.EBCDIC);
				    
				    m_jobName = aSmfStream.getString(8,SmfUtil.EBCDIC);
				    
				    m_server_stoken = aSmfStream.getByteBuffer(8);
				    
				    if (m_version == 1) {
				    	m_reserved = aSmfStream.getByteBuffer(36);
				    } 
				    
				    if (m_version >= 2) {
				    	m_asid = aSmfStream.getInteger(4);
				    	m_serverConfigDir = aSmfStream.getString(128,SmfUtil.EBCDIC);
				    	m_productVersion = aSmfStream.getString(16,SmfUtil.EBCDIC);
				    	m_pid = aSmfStream.getInteger(4);
                        if (m_version >= 3) {
                            m_bitFlags = aSmfStream.getByteBuffer(4);
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
		    /** Dumps the fields of this object to a print stream.
		     * @param aPrintStream The stream to print to.
		     * @param aTripletNumber The triplet number of this LibertyServerInfoSection.
		     */
		    public void dump(SmfPrintStream aPrintStream, int aTripletNumber) {
		         
		      aPrintStream.println("");
		      aPrintStream.printKeyValue("Triplet #",aTripletNumber);
		      aPrintStream.printlnKeyValue("Type","LibertyServerInfoSection");

		      aPrintStream.push();

		      aPrintStream.printlnKeyValue("Server Info Version                 ", m_version);
		      aPrintStream.printlnKeyValue("System Name (CVTSNAME)              ",m_systemName);
		      aPrintStream.printlnKeyValue("Sysplex Name                        ",m_sysplexName);
		      aPrintStream.printlnKeyValue("JobID                               ",m_jobId);
		      aPrintStream.printlnKeyValue("JobName                             ",m_jobName);
		      aPrintStream.printlnKeyValue("Stoken                              ",m_server_stoken,null);
		      if (m_version >= 2) {
		    	  aPrintStream.printlnKeyValue("Server asid                     ", m_asid);
		    	  aPrintStream.printlnKeyValue("Server config directory         ",m_serverConfigDir);
		    	  aPrintStream.printlnKeyValue("Product version                 ",m_productVersion);		    	  
		    	  aPrintStream.printlnKeyValue("Server pid                      ", m_pid);
                  if (m_version >= 3) {
                      aPrintStream.printlnKeyValue("Flag word                           ", m_bitFlags, null);
                      int firstByte = (0x000000FF & (m_bitFlags[0]));
                      int booleanValue = ((firstByte & MASK_CVTZCBP) == MASK_CVTZCBP) ? 1 : 0;
                      aPrintStream.printlnKeyValue("  CVTZCBP                           ", booleanValue);
                  }
		      }
		      
		      aPrintStream.pop();
		    }   
}
