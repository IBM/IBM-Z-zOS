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

import com.ibm.jzos.ZFile;

//------------------------------------------------------------------------------
/** Implementation for ISmfFile to access a local Smf file. */
public class JzOSSmfFile implements ISmfFile {
  
  /** Record file. */
  private ZFile m_file = null;
    
  private byte[] m_buffer = null;
  
  //----------------------------------------------------------------------------
  /** SmfFile constructor. */
  public JzOSSmfFile() { }
  
  //----------------------------------------------------------------------------
  /** Open local Smf file.
   * @param aName Name of Smf file. If it starts DD: then we assume its a DD name, otherwise we assume
   * its a fully qualified dataset name.
   * @throws IOException in case of IO errors.
   */
  public void open (String aName) throws IOException {
        
    try 
    {           
     if (!aName.startsWith("DD:"))
     {
      aName = "'"+aName+"'";
     }
     m_file = new ZFile("//"+aName,"rb,type=record");
     m_buffer = new byte[m_file.getLrecl()];
    } 
    catch (Exception e) 
    {
     e.printStackTrace();
    }                                               
       
  } // SmfFile(...)
  
  
  //----------------------------------------------------------------------------
  /** Close local Smf file.
   * @throws IOException in case of IO errors.
   */
  public void close() throws IOException {
    
    if (m_file != null) m_file.close();
    
    m_file = null;
    
  } // close()
  
  
  //----------------------------------------------------------------------------
  /** Read a record.
   * @return byte array containing the record read.
   * @throws java.io.IOException in case of IO errors.
   */
  public byte[] read() throws IOException {
    
	    if (m_file == null) return null;
	    
	    int byteN = m_file.read(m_buffer);
	    
	    if ((byteN == -1) | (byteN == 0)) return null;
	    byte[] record = new byte[byteN];
	    
	    ByteArrayInputStream s = new ByteArrayInputStream(m_buffer,0,byteN);
	    
	    s.read(record,0,byteN);
	    
	    return record;
    
  } // read(...)
  
  public void seek(long offset, int origin) throws IOException {
	  m_file.seek(offset,origin);
  }
  
} 