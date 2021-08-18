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

  package com.ibm.smf.twas.request;

  import java.io.*;

import com.ibm.smf.format.SmfEntity;
import com.ibm.smf.format.SmfPrintStream;
import com.ibm.smf.format.SmfStream;
import com.ibm.smf.format.SmfUtil;
import com.ibm.smf.format.UnsupportedVersionException;

//  ------------------------------------------------------------------------------
  /** Data container for SMF data related to a Smf record product section. */
  public class CpuUsageSection extends SmfEntity {
     
    /** Supported version of this class. */
    private final static int s_supportedVersion = 1;  

    /** version of this section */
    public int m_version;
    /** Type of data (1=EJB container, 2=Web Container) */
    public int m_dataType;
    /** cpu time for this item */    
    public long m_cpuTime;       //@SU99
    /** elapsed time for this item */    
    public long m_elapsedTime;   //@SU99
    /** count of calls to this item */
    public int m_invocationCount;
    /** length of first string identifying this items */
    public int m_string1Length;
    /** length of second string identifying this item */
    public int m_string2Length;
    /** first string identifying this item */
    public String m_String1;                                  //@SU9
    /** second string identifying this item */
    public String m_String2;                                  //@SU9
    
    //----------------------------------------------------------------------------
    /** CpuUsageSection constructor from a SmfStream.
     * @param aSmfStream SmfStream to be used to build this CpuUsageSection.
     * The requested version is currently set in the Platform Neutral Section
     * @throws UnsupportedVersionException Exception to be thrown when version is not supported
     * @throws UnsupportedEncodingException Exception thrown when an unsupported encoding is detected.
     */
    public CpuUsageSection(SmfStream aSmfStream) 
    throws UnsupportedVersionException, UnsupportedEncodingException {
      
      super(s_supportedVersion);
      
      m_version = aSmfStream.getInteger(4);   
      
      m_dataType = aSmfStream.getInteger(4);   
      
      m_cpuTime = aSmfStream.getLong();              //@SU99
      
      // m_elapsedTime = aSmfStream.getByteBuffer(8);
       m_elapsedTime = aSmfStream.getLong();          //@SU99
      
      m_invocationCount = aSmfStream.getInteger(4);   
      
      m_string1Length = aSmfStream.getInteger(4); 
      
      m_String1 = aSmfStream.getString(256,SmfUtil.EBCDIC);
      
      m_string2Length = aSmfStream.getInteger(4); 
      
      m_String2 = aSmfStream.getString(256,SmfUtil.EBCDIC);
      
    } // CpuUsageSection(..)
    
    //----------------------------------------------------------------------------
    /** Returns the supported version of this class.
     * @return supported version of this class.
     */
    public int supportedVersion() {
      
      return s_supportedVersion;
      
    } // supportedVersion()


    //----------------------------------------------------------------------------
    /** Dumps the fields of this object to a print stream.
     * @param aPrintStream The stream to print to.
     * @param aTripletNumber The triplet number of this CpuUsageSection.
     */
    public void dump(SmfPrintStream aPrintStream, int aTripletNumber) {
    	
      // Append a user readable type string as a description
      // instead of just the number for the data types
      String dataTypeString = "";
      switch (m_dataType) {
        case 1 : dataTypeString = "EJB Container"; break;
        case 2 : dataTypeString = "Web Container"; break;
      }
         
      aPrintStream.println("");
      aPrintStream.printKeyValue("Triplet #",aTripletNumber);
      aPrintStream.printlnKeyValue("Type","CpuUsageSection");

      aPrintStream.push();
      aPrintStream.printlnKeyValue("Version         ",m_version);
      aPrintStream.printlnKeyValue("Data Type       ",m_dataType);
      aPrintStream.printlnKeyValueString("Request Type    ",m_dataType,dataTypeString);
      aPrintStream.printlnKeyValue("CPU Time        ",m_cpuTime);                  //@SU99
      aPrintStream.printlnKeyValue("Elapsed Time    ",m_elapsedTime);              //@SU99
      aPrintStream.printlnKeyValue("Invocation Count",m_invocationCount);
      aPrintStream.printlnKeyValue("String 1 Length ",m_string1Length);
      aPrintStream.printlnKeyValueString("String 1        ",m_string1Length,m_String1); //@SU99
      aPrintStream.printlnKeyValue("String 2 Length ",m_string2Length);                   
      aPrintStream.printlnKeyValueString("String 2        ",m_string2Length,m_String2); //@SU99
      
      aPrintStream.pop();
      
    } // dump()
    
  } // CpuUsageSection


  
