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

package com.ibm.smf.twas.outbound;

import java.io.*;

import com.ibm.smf.format.SmfEntity;
import com.ibm.smf.format.SmfPrintStream;
import com.ibm.smf.format.SmfStream;
import com.ibm.smf.format.UnsupportedVersionException;

//------------------------------------------------------------------------------
/** Data container for SMF data related to a Smf Outbound Request Ttransaction Context Section. */
public class OutboundRequestTransactionContextSection extends SmfEntity {
   
  /** Supported version of this class. */
  public final static int s_supportedVersion = 1;  
  /** version of this section */
  public int m_version;
  /** transactional XID */
   public byte m_transactionalXID[];
  /** reserved space */
  public byte m_theblob[];
  
  //----------------------------------------------------------------------------
  /** OutboundRequestTransactionContextSection constructor from a SmfStream.
   * @param aSmfStream SmfStream to be used to build this OutboundRequestTransactionContextSection.
   * @throws UnsupportedVersionException Exception to be thrown when version is not supported
   * @throws UnsupportedEncodingException Exception thrown when an unsupported encoding is detected.
   */
  public OutboundRequestTransactionContextSection(SmfStream aSmfStream) 
  throws UnsupportedVersionException, UnsupportedEncodingException {
    
    super(s_supportedVersion);
    
    m_version = aSmfStream.getInteger(4);   
  
    m_transactionalXID = aSmfStream.getByteBuffer(140);
    
    m_theblob = aSmfStream.getByteBuffer(24);
    
  } // OutboundRequestTransactionContextSection(..)
  
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
   * @param aTripletNumber The triplet number of this OutboundRequestTransactionContextSection.
   */
  public void dump(SmfPrintStream aPrintStream, int aTripletNumber) {

     
    aPrintStream.println("");
    aPrintStream.printKeyValue("Triplet #",aTripletNumber);
    aPrintStream.printlnKeyValue("Type","OutboundRequestTransactionContextSection");

    aPrintStream.push();
    aPrintStream.printlnKeyValue("Version            ",m_version);
    aPrintStream.printlnKeyValue("transactional XID  ",m_transactionalXID,null);
    aPrintStream.printlnKeyValue("Reserved           ",m_theblob,null);
    
    aPrintStream.pop();
    
  } // dump()
  
} // OutboundRequestTransactionContextSection




