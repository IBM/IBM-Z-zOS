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

/**
 * Interface definition for Plug-Ins
 * 
 */
public interface SMFFilter {

	/**
	 * Called during initialization of browser.  
	 * @param parms The text from the PLUGIN keyword after the comma
	 * @return true if initializatin is successful, false if not
	 */
	public abstract boolean initialize(String parms);
	
	/**
	 * Called for each record found.  Only the record header has been parsed
	 * so you can examine the type/subtype
	 * @param record The record being processed
	 * @return true if this record should be parsed, false if not
	 */
	public abstract boolean preParse(SmfRecord record);
	
	/**
	 * Called to parse the record
	 * @param record The record to parse
	 * @return The parsed record
	 */
	public abstract SmfRecord parse(SmfRecord record);
	
	/**
	 * Called after parsing is complete.  This is an opportunity to format 
	 * the whole record, parts of it, or just examine it
	 * @param record the parsed record
	 */
	public abstract void processRecord(SmfRecord record);
	
	/**
	 * Called when all records have been processed.  Print summary
	 * data or whatever else you like.
	 *
	 */
	public abstract void processingComplete();


}
