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

import java.io.UnsupportedEncodingException;
import java.math.BigInteger;
import java.util.Calendar;
import java.util.Date;
import java.util.GregorianCalendar;

import com.ibm.smf.utilities.ConversionUtilities;

//------------------------------------------------------------------------------
/** Data container for SMF data related to a SmfRecord.
 * This is the base class for all Smf record classes.
 * It constructs itself from an SmfStream.
 * After the basic record related stuff is read
 * the specific Smf record subtype is known and
 * a new subtype specific record must be created.
 * For that reason subtype specific constructors derived from SmfRecord
 * need to provide a copy constructor to catch the data from the initial
 * SmfRecord instance, typically by calling che copy constructor
 * of SmfRecord. The subtype specific copy constructor then continues
 * to setup itself by reading subtype specific data from the record.
 * This is most often achieved by constructing contained entities
 * which are able to construct theirselves from a SmfStream.
 */
public class SmfRecord extends SmfEntity {
  
  /** Supported version of this implementation. */
	public final static int s_supportedVersion = 1;
  
    
  /** Bit mask for bit indicating subtype validity in SmfRecord. */
  public final static byte SubTypeValidFlag = (byte) 0x40;


public static final int RequestActivitySmfRecordSubtype = 0;
  
  /** SmfStream where the SmfRecord constructs from. */
  protected SmfStream m_stream = null;
  
  /** Raw byte array of record */
  private byte[] raw_record;
    
  /** Record number. */
  public static int my_recordN = 0;                         //@SUa
  /** Set this to your page length */
  public static int my_pageLength = 64;
  
  /** Flag word. */
  public int m_flag;
  
  /** Record type. */
  public int m_type;
  
  /** Date of the record. */
  public Date m_date;
  
  /** System id. */
  public String m_sid;
  
  /** Subsystem id. */
  public String m_subsysid;
  
  /** Record subtype. */
  public int m_subtype = 0;
  
  /** hours for PerformanceSummary. */                                //@SUa
  public static int my_hours;                                         //@SUa
  /** Minutes for PerformanceSummary */
  public static int my_mins;                                          //@SUa
  /** Seconds for PerformanceSummary */
  public static int my_secs;                                          //@SUa
  //----------------------------------------------------------------------------
  /** SmfRecord constructor from a SmfStream.
   * The instance is filled from the provided SmfStream.
   * @param aSmfStream Smf stream to create this instance of SmfRecord.
   * @throws UnsupportedVersionException Exception thrown when the requested version is higher than the supported version.
   * @throws UnsupportedEncodingException Exception thrown when an unsupported encoding is encountered during Smf stream parse.
   */
  public SmfRecord(SmfStream aSmfStream)
  throws UnsupportedVersionException, UnsupportedEncodingException {
    
    super(s_supportedVersion); // preliminary record version
    
    m_stream = aSmfStream;
    
    m_flag = m_stream.read();
    
    boolean subtypes_valid = false;
    if ((m_flag&0x04)==0x04) { subtypes_valid = true;}
    
    m_type = m_stream.read();
    
    ++my_recordN;          /* Increment my_recordN(umber)    */     //@SUa
    
    Calendar cal = readDateTime();
    m_date = cal.getTime();
    
    /* get the sid */
    m_sid = m_stream.getString(4,SmfUtil.EBCDIC);
    
    if (subtypes_valid) {
        if (m_stream.available() >= 4) {
            m_subsysid = m_stream.getString(4,SmfUtil.EBCDIC);
          }
          
          if (m_stream.available() >= 2) {
            m_subtype = m_stream.getInteger(2);                                     //    @L1C     
          }    	
    } else {
    	m_subsysid = "";
    	m_subtype=0;
    }
    
    my_hours = cal.get(Calendar.HOUR_OF_DAY);                              //@SUa
    my_mins = cal.get(Calendar.MINUTE);                                    //@SUa
    my_secs = cal.get(Calendar.SECOND);                                    //@SUa 
    
  } // SmfRecord(...)
  
	protected Calendar readDateTime() {
		/* get the time field and calculate the hours, mins, secs */
		int time = m_stream.getInteger(4); // @L1C

		int secs = time / 100;
		int mins = secs / 60;
		secs -= (mins * 60);
		int hours = mins / 60;
		mins -= (hours * 60);

		/* get the date */
		int century = (m_stream.read() == 1) ? 2000 : 1900;

		int year = m_stream.read();
		int y2 = year >> 4;
		int y1 = year - y2 * 16;
		year = century + y2 * 10 + y1;

		int byte2 = m_stream.read();
		int byte1 = m_stream.read();
		int d1 = byte1 >> 4;
		int d3 = byte2 >> 4;
		int d2 = byte2 - d3 * 16;
		int day = d3 * 100 + d2 * 10 + d1;

		Calendar calendar = new GregorianCalendar(year, 1, 1, hours, mins, secs);
		calendar.set(Calendar.DAY_OF_YEAR, day);

		return calendar;
	}
  
  //----------------------------------------------------------------------------
  /** Constructs a SmfRecord from a SmfRecord (Copy Constructor).
   * The instance is intialized from the provided SmfRecord
   * and typically continues to build from the contained SmfStream.
   * @param aSmfRecord SmfRecord to construct from.
   * @throws UnsupportedVersionException Exception thrown when the requested version is higher than the supported version.
   */
  protected SmfRecord(SmfRecord aSmfRecord) throws UnsupportedVersionException {
    
    super(s_supportedVersion); // preliminary record version
    
    m_stream = aSmfRecord.m_stream;
    
    m_flag = aSmfRecord.m_flag;
    m_type = aSmfRecord.m_type;
    
    m_date = aSmfRecord.m_date;
    
    m_sid = aSmfRecord.m_sid;
    
    m_subsysid = aSmfRecord.m_subsysid;
    m_subtype = aSmfRecord.m_subtype;
      
  } // SmfRecord(...)
  
  /**
   * Set raw record into object
   * @param b raw SMF record data
   */
  public void rawRecord(byte [] b) {
	  raw_record = b;
  }
  
  /**
   * Get raw record data
   * @return raw record data
   */
  public byte[] rawRecord() {
	  return raw_record;
  }
  
  //----------------------------------------------------------------------------
  /** Returns the supported version of this class.
   * @return supported version of this class.
   */
  public int supportedVersion() {
    
    return s_supportedVersion;
    
  } // supportedVersion()
  
  //----------------------------------------------------------------------------
  /** Returns the flag word.
   * @return Flag word.
   */
  public int flag() {
    return m_flag;
  } // flag()
  
  //----------------------------------------------------------------------------
  /** Returns the record type.
   * @return Record type.
   */
  public int type() {
    return m_type;
  } // type()
  
  //----------------------------------------------------------------------------
  /** Returns the date when the record was moved into the SMF buffer
   * @return Date when the record was moved into the SMF buffer
   */
  public Date date() {
    return m_date;
  } // date()
  
  //----------------------------------------------------------------------------
  /** Returns the system id as a String
   * @return System id as a String
   */
  public String sid() {
    return m_sid;
  } // sid()
  
  //----------------------------------------------------------------------------
  /** Returns the subsystem id as a String.
   * @return subsystem id as a String.
   */
  public int subtype() {
    return m_subtype;
  } // subType()
  
  //----------------------------------------------------------------------------
  /** Dump the Smf record into a print stream.
   * Override with a dump method specific to the record type
   * Call to the super.dump to get the header stuff, if applicable
   * Only used if DefaultFilter is used (e.g. default behavior)
   * @param aPrintStream print stream to dump to.
   */
  public void dump(SmfPrintStream aPrintStream) {
	    
	    String subsysid;
	    if (m_subsysid == null || m_subsysid.length() == 0) {
	      subsysid = "null";
	    }
	    else {
	      subsysid = m_subsysid;
	    }
	    
	    int recordS = m_stream.size() + 4;
	    
	    aPrintStream.push();
	    
	    aPrintStream.printKeyValue("Type",m_type);
	    aPrintStream.printKeyValue("Size",recordS);
	    aPrintStream.printlnKeyValue("Date",m_date.toString());
	    
	    aPrintStream.printKeyValue("SystemID",m_sid);
	    aPrintStream.printKeyValue("SubsystemID",subsysid);
	    aPrintStream.printlnKeyValue("Flag",m_flag);
	    
	    aPrintStream.printlnKeyValueString("Subtype",subtype(),subtypeToString());
	    
	    aPrintStream.pop();

  }
  
  //----------------------------------------------------------------------------
  /** Returns the record subtype as a String.
   * Override with SMF record type implementation that knows what the subtypes are
   * @return record subtype as a String.
   */
  public String subtypeToString() {
       return "Unknown";
  }
  
  public void seek(Triplet triplet) {
	  m_stream.reset();
	  
	  // The byte array starts after SMFHDR_Seg (or subtype equivalent), so we
	  // always subtract 4
	  // https://www.ibm.com/docs/en/zos/3.1.0?topic=practices-standard-extended-smf-record-headers
	  m_stream.skip(triplet.offset() - 4);
  }
  
} // SmfRecord