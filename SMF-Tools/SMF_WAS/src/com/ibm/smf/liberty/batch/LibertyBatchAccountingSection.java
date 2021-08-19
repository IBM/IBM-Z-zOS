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
import com.ibm.smf.format.SmfUtil;
import com.ibm.smf.format.UnsupportedVersionException;

public class LibertyBatchAccountingSection extends SmfEntity {

	  /** Supported version of this class. */
	  public final static int s_supportedVersion = 1;  
	  
	  /** version of section. */
	  public int m_version;	  
	  
	  /** length of data */
	  public int m_length;
	  
	  /** accounting string */
	  public String m_accountingString;

	  //----------------------------------------------------------------------------
	  /** Returns the supported version of this class.
	   * @return supported version of this class.
	   */
	  public int supportedVersion() {
	    
	    return s_supportedVersion;
	    
	  } // supportedVersion()	
	  
	  public LibertyBatchAccountingSection(SmfStream aSmfStream) 
			  throws UnsupportedVersionException, UnsupportedEncodingException {
			    
			    super(s_supportedVersion);
			    m_version = aSmfStream.getInteger(4);
			    
			    m_length = aSmfStream.getInteger(4);
			    m_accountingString = aSmfStream.getString(128,SmfUtil.EBCDIC);
			    
	  }
	  
	  //----------------------------------------------------------------------------
	  /** Dumps the fields of this object to a print stream.
	   * @param aPrintStream The stream to print to.
	   * @param aTripletNumber The triplet number of this LibertyRequestInfoSection.
	   */
	  public void dump(SmfPrintStream aPrintStream, int aTripletNumber) {
	       
	    aPrintStream.println("");
	    aPrintStream.printKeyValue("Triplet #",aTripletNumber);
	    aPrintStream.printlnKeyValue("Type","LibertyBatchAccountingSection");

	    aPrintStream.push();
	    aPrintStream.printlnKeyValue("Accounting Info Version             ", m_version);

	    aPrintStream.printlnKeyValue("Accounting String Length            ",m_length);
	    aPrintStream.printlnKeyValue("Accounting String                   ",m_accountingString);	    
	    
	    aPrintStream.pop();
	  }  
	  
	  
}
