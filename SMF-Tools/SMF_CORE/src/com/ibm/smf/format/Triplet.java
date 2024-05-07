/*                                                                   */
/* Copyright 2024 IBM Corp.                                          */
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

//------------------------------------------------------------------------------
/** Data container for SMF data related to a triplet. */
public class Triplet {
  
  /** Offset of data described by this triplet in SmfRecord. */
  private int m_offset;
  
  /** Length of data described by this triplet in SmfRecord. */
  private int m_length;
  
  /** Number of data sections described by this triplet in SmfRecord. */
  private int m_count;
  
  //----------------------------------------------------------------------------
  /** Triplet constructor from SmfStream.
   * The instance is filled from the provided SmfStream.
   * @param aSmfStream Smf stream to create this instance of ServeIntervalSection from.
   */
  public Triplet(SmfStream aSmfStream) {
	  this(aSmfStream, 4, 4, 4);
  }
  
  //----------------------------------------------------------------------------
  /** Triplet constructor from SmfStream.
   * The instance is filled from the provided SmfStream.
   * @param aSmfStream Smf stream to create this instance of ServeIntervalSection from.
   * @param offsetLength Length of offset field
   * @param lengthLength Length of length field
   * @param countLength Length of count field
   */
  public Triplet(SmfStream aSmfStream, int offsetLength, int lengthLength, int countLength) {
    
    m_offset = aSmfStream.getInteger(offsetLength);
    
    m_length = aSmfStream.getInteger(lengthLength);
    
    m_count = aSmfStream.getInteger(countLength);
    
  } // Triplet(...)
  
  //----------------------------------------------------------------------------
  /** Returns the offset to the section from RDW.
   * @return Offset to the section from RDW.
   */
  public int offset() {
    return m_offset;
  } // offset()
  
  //----------------------------------------------------------------------------
  /** Returns the length of the section.
   * @return Length of the section.
   */
  public int length() {
    return m_length;
  } // length()
  
  //----------------------------------------------------------------------------
  /** Returns the number of sections.
   * @return Number of sections.
   */
  public int count() {
    return m_count;
  } // count()
  
  //----------------------------------------------------------------------------
  /** Dumps the object into a print stream.
   * @param aPrintStream print stream to dump to.
   * @param aTripletNumber number of the triplet.
   */
  public void dump(SmfPrintStream aPrintStream, int aTripletNumber) {
    String Hex_offset = Integer.toHexString(m_offset);     // @SU9
    String Hex_length = Integer.toHexString(m_length);     // @SU9
    aPrintStream.printKeyValue("Triplet #",aTripletNumber);
    aPrintStream.printKeyValue("offsetDec",m_offset);
    aPrintStream.printKeyValue("offsetHex",Hex_offset);    // @SU9
    aPrintStream.printKeyValue("lengthDec",m_length);
    aPrintStream.printKeyValue("lengthHex",Hex_length);    // @SU9
    aPrintStream.printlnKeyValue("count",m_count);
    
  } // dump(...)
  
  /* @L1 start */
  //----------------------------------------------------------------------------
  /** Dumps the object into a print stream.
   * @param aPrintStream Print stream to dump to.
   * @param aBaseTripletNumber Number of the containing triplet.
   * @param aTripletNumber Number of the triplet.
   */
  public void dump(
  SmfPrintStream aPrintStream,
  int aBaseTripletNumber,
  int aTripletNumber) {
    
    String Hex_offset = Integer.toHexString(m_offset);    // @SU9
    String tripletId = Integer.toString(aBaseTripletNumber) + "." +
    Integer.toString(aTripletNumber);
    aPrintStream.printKeyValue("Triplet #",tripletId);
    aPrintStream.printKeyValue("offsetDec",m_offset);
    aPrintStream.printKeyValue("offsetHex",Hex_offset);   // @SU9
    aPrintStream.printKeyValue("length",m_length);
    aPrintStream.printlnKeyValue("count",m_count);
    
  } // dump(...)
  /* @L1 end */
  
  @Override
	public String toString() {
		return super.toString() + " { count: " + m_count + ", offset: " + m_offset + ", length: " + m_length + " }";
	}
  
} // Triplet