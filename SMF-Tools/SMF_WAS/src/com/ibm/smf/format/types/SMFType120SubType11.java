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

package com.ibm.smf.format.types;

import java.io.UnsupportedEncodingException;

import com.ibm.smf.format.SkipFilteredRecord;
import com.ibm.smf.format.SmfPrintStream;
import com.ibm.smf.format.SmfRecord;
import com.ibm.smf.format.UnsupportedVersionException;
import com.ibm.smf.liberty.request.LibertyRequestRecord;


/**
 * Formats the SMF 120 Subtype 11 record 
 *
 */

public class SMFType120SubType11 extends LibertyRequestRecord
{
   /**
    * Constructor
    * @param smfRecord The SMF record to be contained by this object
    * @throws UnsupportedVersionException bad version
    * @throws UnsupportedEncodingException bad encoding
 * @throws SkipFilteredRecord 
    */
 public SMFType120SubType11(SmfRecord smfRecord)
 throws UnsupportedVersionException, UnsupportedEncodingException, SkipFilteredRecord
 {
  super(smfRecord);
  
 }
 
 public void dump(SmfPrintStream aPrintStream)
 {
  super.dump(aPrintStream);
 }
 
} 