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

  package com.ibm.smf.was.common;

  import java.io.*;
  import java.lang.reflect.*;

import com.ibm.smf.format.SmfEntity;
import com.ibm.smf.format.SmfPrintStream;
import com.ibm.smf.format.SmfStream;
import com.ibm.smf.format.UnsupportedVersionException;

//  ------------------------------------------------------------------------------
  /** Data container for SMF data related to a Smf record product section. */
  public class UserDataSection extends SmfEntity {
     
    /** Supported version of this class. */
     
	  public final static int s_supportedVersion = 1;  
    /** Version of this section*/
    public int m_version;
    /** data type for this section (less than 65535 reserved for IBM use) */
    public int m_dataType;
    /** length of data in this section */
    public int m_dataLength;
    /** user data itself */
    public byte m_data[];       

    private static final boolean debug = Boolean.getBoolean("com.ibm.ws390.sm.smfview.UserDataSection.debug");
    
    //----------------------------------------------------------------------------
    /** UserDataSection constructor from a SmfStream.
     * @param aSmfStream SmfStream to be used to build this UserDataSection.
     * The requested version is currently set in the Platform Neutral Section
     * @throws UnsupportedVersionException Exception to be thrown when version is not supported
     * @throws UnsupportedEncodingException Exception thrown when an unsupported encoding is detected.
     */
    public UserDataSection(SmfStream aSmfStream) 
    throws UnsupportedVersionException, UnsupportedEncodingException {
      
      super(s_supportedVersion);
      
      m_version = aSmfStream.getInteger(4);   
      
      m_dataType = aSmfStream.getInteger(4);   
      
      m_dataLength = aSmfStream.getInteger(4); 
      
      m_data = aSmfStream.getByteBuffer(2048); 
      
    } // UserDataSection(..)
    
    //----------------------------------------------------------------------------
    /**
     * UserDataSection constructor from a SmfStream.
     *
     * @param aSmfStream        SmfStream to be used to build this UserDataSection.
     * @param lengthFromTriplet The length of each userdata section read from the userdata triplet
     *                              The requested version is currently set in the Platform Neutral Section
     * @throws UnsupportedVersionException  Exception to be thrown when version is not supported
     * @throws UnsupportedEncodingException Exception thrown when an unsupported encoding is detected.
     */
    public UserDataSection(SmfStream aSmfStream, int lengthFromTriplet) throws UnsupportedVersionException, UnsupportedEncodingException {

        super(s_supportedVersion);

        m_version = aSmfStream.getInteger(4);

        m_dataType = aSmfStream.getInteger(4);

        m_dataLength = aSmfStream.getInteger(4);

        m_data = aSmfStream.getByteBuffer(lengthFromTriplet - 12);

    } // UserDataSection(..)

    
    /**
     * Copy CTOR, called by custom formatters that extend this class.
     * @param uds The user data section
     * @throws UnsupportedVersionException bad version
     * @throws UnsupportedEncodingException bad encoding
     */
    public UserDataSection(UserDataSection uds)
      throws UnsupportedVersionException, UnsupportedEncodingException 
    {
      super(s_supportedVersion);

      m_version = uds.m_version;
      m_dataType = uds.m_dataType;
      m_dataLength = uds.m_dataLength;
      m_data = uds.m_data;
    }

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
     * @param aTripletNumber The triplet number of this UserDataSection.
     */
    public void dump(SmfPrintStream aPrintStream, int aTripletNumber) {
         
      aPrintStream.println("");
      aPrintStream.printKeyValue("Triplet #",aTripletNumber);
      aPrintStream.printlnKeyValue("Type","UserDataSection");

      aPrintStream.push();
      aPrintStream.printlnKeyValue("Version     ",m_version);
      aPrintStream.printlnKeyValue("Data Type   ",m_dataType);
      aPrintStream.printlnKeyValue("Data Length ",m_dataLength);
      aPrintStream.printlnKeyValue("Data        ",m_data,null);
      
      aPrintStream.pop();
      
      
    } // dump()
    

    /**
     * Attempt to load a formatter for the given UserDataSection type.
     * <p>
     * Custom formatter classes are named using the following pattern: 
     *    com.ibm.ws390.smf.formatters.SMFType120SubType9UserDataTypexxx.class
     * where xxx is the user data type value, in decimal.  
     * <p>
     * The custom formatter class must:
     * <br>(1) extend com.ibm.smf.was.common.UserDataSection
     * <br>(2) define a CTOR that takes a com.ibm.smf.was.common.UserDataSection object 
     *     as its only argument.  (Note: It is highly recommended that this CTOR call 
     *     super(UserDataSection);)
     *     
     * @param aSmfStream SmfStream to be used to build this UserDataSection.
     * @param recordSubType the 120 subtype we're adding user data to (e.g. 9)
     * @param lengthFromTriplet The length of each userdata section read from the userdata triplet
     * @return UserDataSection formatter
     * @throws UnsupportedVersionException Exception to be thrown when version is not supported
     * @throws UnsupportedEncodingException Exception thrown when an unsupported encoding is detected.
     */
    public static UserDataSection loadUserDataFormatter(SmfStream aSmfStream,int recordSubType,
    		int lengthFromTriplet) throws UnsupportedVersionException, UnsupportedEncodingException 
    {
      UserDataSection uds = new UserDataSection(aSmfStream,lengthFromTriplet);

	    int type = 120;
      int subtype = recordSubType;
      int udstype = uds.m_dataType;
	    String formatterPackage = "com.ibm.smf.format.types.";
	    String newClassName = formatterPackage + "SMFType"+type+"SubType"+subtype+"UserDataType"+udstype;

      UserDataSection newUds = uds;  // initialize with base UDS object

	    try
	    {
	      // Take a shot at finding a class that implements the right UserData type.
	      // If it blows up in any way, just return the base UserDataSection object,
        // which will format the raw data.
        Class parameterTypes[] = new Class[] { UserDataSection.class } ;
        Class newClass = Class.forName(newClassName);
        Constructor ctor = newClass.getConstructor(parameterTypes);
        Object parms[]= new Object[] { uds };
        newUds = (UserDataSection)ctor.newInstance(parms);
	    }
	    catch(Throwable t)  // just catch everything
	    {
        if (debug)
        {
        System.err.println("Failed to load class " +  newClassName + " due to exception: " + t);
        t.printStackTrace();
      }
      }

      return newUds;
    }

  } // UserDataSection


  
