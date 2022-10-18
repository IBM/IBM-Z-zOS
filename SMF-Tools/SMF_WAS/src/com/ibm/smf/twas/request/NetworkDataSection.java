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
  public class NetworkDataSection extends SmfEntity {
     
    /** Supported version of this class. */
	  public final static int s_supportedVersion = 1;  
    /** version of this section */
    public int m_version;
    /** number of bytes received for this request */
    public long  m_bytesReceived;
    /** number of bytes sent as response for this request */
    public long  m_bytesSent;
    /** target port number for this request */
    public int m_targetPort;
    /** length of origin string */
    public int m_lengthOriginString;
    /** origin host/port of this request (or jobname/asid for local clients) */    
    public String m_originstring;

    /** reserved space */
    public byte m_theblob[];
    
    //----------------------------------------------------------------------------
    /** NetworkDataSection constructor from a SmfStream.
     * @param aSmfStream SmfStream to be used to build this NetworkDataSection.
     * The requested version is currently set in the Platform Neutral Section
     * @throws UnsupportedVersionException Exception to be thrown when version is not supported
     * @throws UnsupportedEncodingException Exception thrown when an unsupported encoding is detected.
     */
    public NetworkDataSection(SmfStream aSmfStream) 
    throws UnsupportedVersionException, UnsupportedEncodingException {
      
      super(s_supportedVersion);
      // 188 total
      m_version = aSmfStream.getInteger(4); 
      m_bytesReceived = aSmfStream.getLong();
      m_bytesSent = aSmfStream.getLong();
      m_targetPort = aSmfStream.getInteger(4); 
      m_lengthOriginString =  aSmfStream.getInteger(4);    
      m_originstring = aSmfStream.getString(128,SmfUtil.EBCDIC);

      m_theblob = aSmfStream.getByteBuffer(32); 
      
    } // NetworkDataSection(..)
    
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
     * @param aTripletNumber The triplet number of this NetworkDataSection.
     */
    public void dump(SmfPrintStream aPrintStream, int aTripletNumber) {
         
      aPrintStream.println("");
      aPrintStream.printKeyValue("Triplet #",aTripletNumber);
      aPrintStream.printlnKeyValue("Type","NetworkDataSection");
      
      aPrintStream.push();
      
      aPrintStream.printlnKeyValue("Version             ",m_version);
      
      aPrintStream.printlnKeyValue("Bytes Received      ",m_bytesReceived);
      
      aPrintStream.printlnKeyValue("Bytes Sent          ",m_bytesSent);
      
      aPrintStream.printlnKeyValue("Target Port         ",m_targetPort);
      
      aPrintStream.printlnKeyValue("Origin String Length",m_lengthOriginString);
      
      aPrintStream.printlnKeyValue("Origin String       ",m_originstring);      
     
      aPrintStream.printlnKeyValue("Reserved            ",m_theblob,null);
      
      aPrintStream.pop();

    } // dump()
    
  } // NetworkDataSection

