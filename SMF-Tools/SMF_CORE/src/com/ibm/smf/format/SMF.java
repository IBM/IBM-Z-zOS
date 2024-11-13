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

import java.util.ArrayList;
import java.util.List;

/**
 * The main class to use to parse SMF records with this browser
 * 
 */
public class SMF {

	/**
	 * The main method
	 * 
	 * @param args The standard input array of strings. May contain strings
	 *             consisting of INFILE(input file name) and PLUGIN(class,parms).
	 */
	public static void main(String[] args) {
		boolean foundINFILE = false;
		boolean foundPLUGIN = false;
		SMFFilter filter = null;

		// No parms? Asking for help?
		if ((args.length == 0)
				|| ((args.length == 1) && ((args[0].equalsIgnoreCase("-help")) || (args[0].equalsIgnoreCase("-?"))))) {
			System.out.println("Specify INFILE(dataset.name) to process one or more SMF dump datasets");
			System.out.println("Specify PLUGIN(class,parms) to run an alternate plugin");
			System.out.println("The default is PLUGIN(DEFAULT,STDOUT)");
			System.out.println("Additional documentation, license information, source code,");
			System.out.println("and javadoc may be found inside this .jar file");
			return;
		}
		List<ISmfFile> files = new ArrayList<>();
		for (int i = 0; i < args.length; ++i) {
			String parm = args[i];
			if ("com.ibm.smf.format.SMF".equals(parm)) {
				continue;
			}
			int openpren = parm.indexOf("(");
			int closepren = parm.indexOf(")");

			if ((openpren == -1) | (closepren == -1)) {
				System.out.println("Must specify keywords with values in parenthesis");
				return;
			}
			String keyword = parm.substring(0, openpren);
			String value = parm.substring(openpren + 1, closepren);
			if ((keyword == null) | (keyword.length() == 0)) {
				System.out.println("Must specify keywords with values in parenthesis");
				return;
			}
			if ((value == null) | value.length() == 0) {
				System.out.println("Keyword values must be greater than zero length");
				return;
			}

			if (keyword.equalsIgnoreCase("INFILE")) {
				foundINFILE = true;

				try {
					ISmfFile file = new JzOSSmfFile();
					file.open(value);
					files.add(file);
				} catch (Exception e) {
					System.out.println(" Exception during open " + value);
					System.out.println(" Exception data:\n" + e.toString());
					return;
				}
			}

			if ((keyword.equalsIgnoreCase("PLUGIN")) & (foundPLUGIN == false)) {
				foundPLUGIN = true;
				try {
					int commaloc = value.indexOf(",");
					if (commaloc == -1) {
						System.out.println("PLUGIN keyword requires class and parm string separated by comma");
						return;
					}
					String classname = value.substring(0, commaloc);
					String parmstring = value.substring(commaloc + 1);
					if ((classname.length() == 0) | (parmstring.length() == 0)) {
						System.out.println("classname and parm string must be non-zero length");
						return;
					}

					if (classname.equals("DEFAULT"))
						classname = "com.ibm.smf.format.DefaultFilter";
					Class filterclass = Class.forName(classname);
					filter = (SMFFilter) filterclass.newInstance();
					boolean result = filter.initialize(parmstring);
					if (result == false) {
						System.out.println("plugin initialization failed..terminating");
						return;
					}
				} catch (Exception e) {
					System.out.println("Exception loading class " + value);
					System.out.println(e.toString());
					return;
				}
			}
		} // end loop

		if (foundPLUGIN == false) {
			filter = new DefaultFilter();
			filter.initialize("STDOUT");
		}

		if (foundINFILE == false) {
			System.out.println("Must specify at least one input file via INFILE");
			return;
		}
		
		for (ISmfFile file : files) {
			Interpreter.interpret(file, filter, false);
		}
		
		Interpreter.performFilterCompletion(filter);
	}
}
