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

import java.io.IOException;
import java.io.UnsupportedEncodingException;

/**
 * 
 * Driver class to run through the input file
 *
 */
public class Interpreter {

	private static final boolean PRINT_WRAPPER = Boolean.parseBoolean(System.getProperty("PRINT_WRAPPER", "true"));

	// ----------------------------------------------------------------------------
	/**
	 * Create a SmfRecord from a stream buffer. The SmfRecord is specialized as
	 * indicated by the type. createSmfRecord acts as a factory method for
	 * SmfRecord.
	 * 
	 * @param aStream SmfStream to create the SmfRecord from.
	 * @return A SmfRecord parsed from the stream.
	 * @throws UnsupportedVersionException  Exception thrown when the requested
	 *                                      version is higher than the supported
	 *                                      version.
	 * @throws UnsupportedEncodingException Exception thrown when an unsupported
	 *                                      encoding is encountered during Smf
	 *                                      stream parse.
	 */
	private static SmfRecord createSmfRecord(SmfStream aStream, SMFFilter a_filter)
			throws UnsupportedVersionException, UnsupportedEncodingException {
		SmfRecord smfRecord = new SmfRecord(aStream);

		/* check the validity of the record header flag */
		if (a_filter.preParse(smfRecord)) {
			smfRecord = a_filter.parse(smfRecord);
		} else
			smfRecord = null;

		return smfRecord;

	} // Interpreter.createSmfRecord()

	// ----------------------------------------------------------------------------

	/**
	 * Main method of the interpreter It reads and interprets SmfRecords from the
	 * SmfStream one by one and dumps each record into a SmfPrintStream.
	 * Perform completion processing.
	 * 
	 * @param infile            input file to parse
	 * @param a_filter          input filter to use
	 */
	public static void interpret(ISmfFile infile, SMFFilter a_filter) {
		interpret(infile, a_filter, true);
	}
	
	/**
	 * Main method of the interpreter It reads and interprets SmfRecords from the
	 * SmfStream one by one and dumps each record into a SmfPrintStream.
	 * 
	 * @param infile            input file to parse
	 * @param a_filter          input filter to use
	 * @param performCompletion whether or not to perform completion on the filter
	 */
	public static void interpret(ISmfFile infile, SMFFilter a_filter, boolean performCompletion) {

		if (PRINT_WRAPPER)
			System.out.println("SMF file analysis starts ...");

		while (true) {
			try {
				// read record
				byte recordData[] = infile.read();

				if (recordData == null)
					break;

				SmfRecord record = null;

				SmfStream recordStream = new SmfStream(recordData);

				record = createSmfRecord(recordStream, a_filter);
				if (record != null) {
					record.rawRecord(recordData);
					a_filter.processRecord(record);
				}

			} // try

			catch (UnsupportedVersionException e) {

				System.out.println("******************");
				System.out.println(e.getMessage());
				System.out.println("******************");

			} // catch ... UnsupportedVersionException

			catch (IOException e) {
				System.out.println(" IOException during read:");
				System.out.println(" Exception data:\n" + e.toString());
			} // catch ... IOException

			catch (Throwable e) {
				System.out.println("Exception during interpretation: " + e.getMessage());
				e.printStackTrace();
			} // catch ... Throwable

		} // while (true) ... scan file for records

		try {
			infile.close();
		} catch (IOException e) {
			System.out.println(" IOException during close:");
			System.out.println(" Exception data:\n" + e.toString());
		}

		if (performCompletion) {
			performFilterCompletion(a_filter);
		}

	} // Interpreter.interpret()
	
	/**
	 * Perform final completion processing on the filter.
	 * 
	 * @param a_filter The filter to process.
	 */
	public static void performFilterCompletion(SMFFilter a_filter) {
		a_filter.processingComplete();

		if (PRINT_WRAPPER) {
			System.out.println("");
			System.out.println("SMF file analysis ended.");
		}
	}

} // Interpreter
