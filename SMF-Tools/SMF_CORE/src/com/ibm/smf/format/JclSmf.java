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

import java.io.IOException;
import java.io.InputStream;
import java.util.Iterator;
import java.util.Properties;

import com.ibm.jzos.ZFile;

public class JclSmf {

	public static void main(String[] args) {
		
		Properties props = new Properties();
		SMFFilter filter = null;
		ISmfFile m_file = new JzOSSmfFile();

		try {
			ZFile parm_file = null;
		    parm_file = new ZFile("//DD:SMFENV","rt");
			InputStream input = parm_file.getInputStream();
			props.load(input);		
		}
		catch (IOException e) {
			System.out.println("Error reading SMFENV");
			System.out.println("Exception data:\n"+e.toString());
		}

		Iterator it = props.keySet().iterator();
		
		while (it.hasNext()) {
			String key = (String)it.next();
			String val = props.getProperty(key);

			if (key.equals("matchServer")) {
				System.setProperty("com.ibm.ws390.smf.smf1209.matchServer", val);
			}
			else if (key.equals("matchCluster")) {
				System.setProperty("com.ibm.ws390.smf.smf1209.matchCluster", val);
			}
			else if (key.equals("matchSystem")) {
				System.setProperty("com.ibm.ws390.smf.smf1209.matchSystem", val);
			}
			else if (key.equals("excludeInternal")) {
				System.setProperty("com.ibm.ws390.smf.smf1209.ExcludeInternal", val);
			}
			else if (key.equals("RespRatioMin")) {
				System.setProperty("com.ibm.ws390.smf.smf1209.RespRatioMin", val);				
			}
			else if (key.equals("plugin")||key.equals("output")) {
				// do nothing
			}
			else {
				// All others get set to system properties as-is
				System.setProperty(key, val);
			}
		}

		
		String classname = props.getProperty("plugin");
		String output = props.getProperty("output");

		
		try 
		{
		 m_file.open("DD:SMFDATA");
		} 
		catch (Exception e) 
		{
		 System.out.println(" Exception during open of DD:SMFDATA");
		 System.out.println(" Exception data:\n" + e.toString());
		 return;
		}    	


		if (classname!=null) {
			if (!(classname.contains("."))) {
				classname = "com.ibm.smf.was.plugins."+classname;
			}
			try {
			     Class filterclass = Class.forName(classname);
			     filter = (SMFFilter)filterclass.newInstance();
			     boolean result = filter.initialize(output);
			     if (result==false)
			     {
			      System.out.println("plugin initialization failed..terminating");
			      return;
			     }				
			}
		    catch (Exception e)
		    {
		     System.out.println("Exception loading class "+classname);
		     System.out.println(e.toString());
		     return;
		    }
		    Interpreter.interpret(m_file, filter);
	    } else {
	    	System.out.println("SMFENV must specify a plugin value");
	    }
	}	

}
