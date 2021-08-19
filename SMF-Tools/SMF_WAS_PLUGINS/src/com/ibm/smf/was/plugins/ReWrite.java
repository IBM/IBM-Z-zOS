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

package com.ibm.smf.was.plugins;

import com.ibm.jzos.ZFile;
import com.ibm.jzos.ZFileException;
import com.ibm.smf.format.DefaultFilter;
import com.ibm.smf.format.SMFFilter;
import com.ibm.smf.format.SmfRecord;
import com.ibm.smf.was.common.WASConstants;

/**
 * This SMF browser plugin rewrites the incoming SMF data into a new (pre-allocated) dataset.
 * Why would you want to do that?  Probably only if you also were using the system-name,
 * server-name, or no-internal filters for the browser.  This plugin would then allow you to
 * create a new, smaller pile of SMF data so other analysis tools can run faster.
 *
 */
public class ReWrite implements SMFFilter {

	
	private ZFile m_file = null;
	
	
	@Override
	public boolean initialize(String parms) {
		String filename = parms;
	    try 
	    {           
	     if (!filename.startsWith("DD:"))
	     {
	      filename = "'"+filename+"'";
	     }
	     m_file = new ZFile("//"+filename,"wb,type=record,recfm=*,lrecl=32756,blksize=27998");
	    } 
	    catch (Exception e) 
	    {
	     e.printStackTrace();
	     return false;
	    } 
		return true;
	}

	@Override
	public boolean preParse(SmfRecord record) {
		 boolean ok_to_process = false;
		 if (record.type()== WASConstants.SmfRecordType)
		   if (record.subtype()==WASConstants.RequestActivitySmfRecordSubtype)
		         ok_to_process = true;
		   else if (record.subtype() == WASConstants.OutboundRequestSmfRecordSubtype) {
			   ok_to_process = true;
		   } 
	     return ok_to_process;
	}

	@Override
	public SmfRecord parse(SmfRecord record) {
		return DefaultFilter.commonParse(record);	
	}

	@Override
	public void processRecord(SmfRecord record) {
		try {
			m_file.write(record.rawRecord());
		} catch (ZFileException e) {
			e.printStackTrace();
		}
		
	}

	@Override
	public void processingComplete() {
         try {
			m_file.close();
		} catch (ZFileException e) {
			e.printStackTrace();
		}
		
	}

}
