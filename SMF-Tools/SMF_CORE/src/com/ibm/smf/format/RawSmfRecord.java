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

package com.ibm.smf.format;

import java.io.*;

/** 
 * RawSmfRecord data.  This class is used when the subtype is unrecognized.
 */
public class RawSmfRecord extends SmfRecord 
{
  /** Supported version of this implementation. */
	public final static int s_supportedVersion = 1;
      

  /** 
   * Constructs a RawSmfRecord from a generic SmfRecord.
   * The generic record already parsed the generic part of the input stream.
   *
   * @param aSmfRecord SmfRecord to parse input from.
   * @throws UnsupportedVersionException Exception thrown when the requested version is higher than the supported version.
   * @throws UnsupportedEncodingException Exception thrown when an unsupported encoding is encountered during Smf stream parse.
   */
  public RawSmfRecord(SmfRecord aSmfRecord) throws UnsupportedVersionException, UnsupportedEncodingException 
  {
    super(aSmfRecord);
  }
  

  /** 
   * Returns the supported version of this class.
   * @return supported version of this class.
   */
  public int supportedVersion() { return s_supportedVersion; }


  /** 
   * Dumps the raw record data into a print stream.
   * @param aPrintStream print stream to dump to.
   */
  public void dump(SmfPrintStream aPrintStream) 
  {
    super.dump(aPrintStream); 

    // Dump the raw record (minus the header, which we just printed).
    int len = m_stream.available();
    byte[] b = new byte[len];
    m_stream.read(b,0,len);

    aPrintStream.printlnKeyValue("RawRecordData",b,SmfUtil.EBCDIC);
  } 
} 