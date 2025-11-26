/*                                                                   */
/* Copyright 2025 IBM Corp.                                          */
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
package com.ibm.smf.format.types;

import java.io.IOException;
import java.io.UnsupportedEncodingException;

import com.ibm.smf.format.SmfPrintStream;
import com.ibm.smf.format.SmfStream;
import com.ibm.smf.format.UnsupportedVersionException;
import com.ibm.smf.was.common.UserDataSection;

/**
 * The SMF 120 Subtype 11 User Data tag type 104 (z/OS Connect API requester).
 * 
 * The data for the 104 User Data section looks like this
 *
 *  DCL 1 zConnectUserData104,
 *       3 version          4  bytes  BINARY - Version
 *       3 stubSentTime     16 bytes  BINARY - STCKE stub sent time 
 *       3 zcEntryTime      16 bytes  BINARY - STCKE request entry time to z/OS Connect
 *       3 zcExitTime       16 bytes  BINARY - STCKE request exit time from z/OS Connect 
 *       3 requestID        8  bytes  BINARY - Request ID in z/OS Connect
 *       3 trackingToken    64 bytes  CHAR   - z/OS Connect generated tracking token
 */
public class SMFType120SubType11UserDataType104 extends UserDataSection {
    public int     m_version;
    public byte [] m_stubSentTime;
    public byte [] m_zcEntryTime;
    public byte [] m_zcExitTime;
    public long    m_requestID;
    public byte [] m_trackingToken;
    
    /**
     * Construct the class and read the data
     * 
     * @param uds The User Data Section
     * @throws UnsupportedVersionException unknown version
     * @throws UnsupportedEncodingException text encoding errors
     */
    public SMFType120SubType11UserDataType104(UserDataSection uds) throws UnsupportedVersionException, UnsupportedEncodingException{
        super(uds);
        
        try {
              SmfStream data= new SmfStream(m_data);
              m_version = data.getInteger(4);
              m_stubSentTime = data.getByteBuffer(16);
              m_zcEntryTime = data.getByteBuffer(16);
              m_zcExitTime = data.getByteBuffer(16);
              m_requestID = data.getLong();
              m_trackingToken = data.getByteBuffer(64);
              data.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
      }
    
    /** 
     * Dumps the fields of this object to a print stream.
     * 
     * @param aPrintStream The stream to print to.
     * @param aTripletNumber The triplet number of this UserDataSection.
     */
    public void dump(SmfPrintStream aPrintStream, int aTripletNumber) {
         
        aPrintStream.println("");
        aPrintStream.printKeyValue("Triplet #",aTripletNumber);
        aPrintStream.printlnKeyValue("Type","UserDataSection");

        aPrintStream.push();
        aPrintStream.printlnKeyValue("Version        ",m_version);
        aPrintStream.printlnKeyValue("Data Type      ",m_dataType);
        aPrintStream.printlnKeyValue("Data Length    ",m_dataLength);
        aPrintStream.printlnKeyValue("Data Version   ",m_version);
        aPrintStream.printlnKeyValue("Stub Sent Time ",m_stubSentTime,null);
        aPrintStream.printlnKeyValue("ZC Entry Time  ",m_zcEntryTime,null);
        aPrintStream.printlnKeyValue("ZC Exit Time   ",m_zcExitTime,null);
        aPrintStream.printlnKeyValue("Request ID     ",m_requestID);
        aPrintStream.printlnKeyValue("Tracking Token ",m_trackingToken,null);
        aPrintStream.pop(); 
    }

}
