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

import java.util.HashMap;

import com.ibm.jzos.ZFile;
import com.ibm.jzos.ZFileException;
import com.ibm.smf.format.DefaultFilter;
import com.ibm.smf.format.SMFFilter;
import com.ibm.smf.format.SmfRecord;
import com.ibm.smf.format.Triplet;
import com.ibm.smf.twas.request.RequestActivitySmfRecord;
import com.ibm.smf.was.common.PlatformNeutralSection;
import com.ibm.smf.was.common.WASConstants;

public class SplitByServer implements SMFFilter {

	private HashMap<String, FileHolder> serverFiles = new HashMap<String, FileHolder>();
	private HashMap<String, FileHolder> clusterFiles = new HashMap<String, FileHolder>();

	@Override
	public boolean initialize(String parms) {
		// TODO Auto-generated method stub
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

		RequestActivitySmfRecord rec = (RequestActivitySmfRecord)record;
		Triplet zOSRequestTriplet;
		int sectionCount;
		FileHolder fh;

		// From the Platform Neutral Server Section
		zOSRequestTriplet = rec.m_platformNeutralSectionTriplet;
		sectionCount = zOSRequestTriplet.count();
		if (sectionCount>0)
		{
			PlatformNeutralSection sec = rec.m_platformNeutralSection;

			String serverName = sec.m_serverShortName;
			String clusterName = sec.m_clusterShortName;
			Boolean foundCluster = false;
			
			fh = (FileHolder)clusterFiles.get(clusterName);
			if (fh!=null) {
				if ((fh.file()!=null)) {
					try {
						fh.file().write(record.rawRecord());
						foundCluster=true;
					} catch (ZFileException e) {
						e.printStackTrace();
					}
				} else {
					// No file in holder...that shouldn't happen..
				}				
			} else { // no cluster holder, see if there's a DD
				try 
				{
					String filename = new String("//DD:"+clusterName);
					ZFile file = new ZFile(filename,"wb,type=record,recfm=*,lrecl=32756,blksize=27998");						
					fh = new FileHolder();
					fh.file(file);
					try {
						file.write(record.rawRecord());
						clusterFiles.put(clusterName, fh);
						System.out.println("Splitting out data for "+clusterName);
						foundCluster=true;
					} catch (ZFileException e) {
						e.printStackTrace();
					}			     
				} 
				catch (Exception e) 
				{
					// DD not there I guess - try for a DD for the server
				} 
			}
			
			fh = (FileHolder)serverFiles.get(serverName);
			
			if (foundCluster==false) {
				if (fh!=null) {
					if ((fh.file()!=null)) {
						try {
							fh.file().write(record.rawRecord());
						} catch (ZFileException e) {
							e.printStackTrace();
						}
					} else {
						// FileHolder exists, but no file, so ignoring these
					}
				} else {
					// haven't seen this guy before, see if there's a DD for him
					try 
					{
						String filename = new String("//DD:"+serverName);
						ZFile file = new ZFile(filename,"wb,type=record,recfm=*,lrecl=32756,blksize=27998");						
						fh = new FileHolder();
						fh.file(file);
						try {
							file.write(record.rawRecord());
							serverFiles.put(serverName, fh);
							System.out.println("Splitting out data for "+serverName);
						} catch (ZFileException e) {
							e.printStackTrace();
						}			     
					} 
					catch (Exception e) 
					{
						// DD not there I guess, ignore this guy - create an empty holder so we don't check again
						FileHolder tempfh = new FileHolder();
						serverFiles.put(serverName, tempfh);
						System.out.println("Not splitting out data for "+serverName);
					} 
				}				
			}
		} 

	}

	@Override
	public void processingComplete()  {
		if (!serverFiles.isEmpty()){
			for (FileHolder fh : serverFiles.values()) {
				try {
					if (fh.file()!=null) {
						fh.file().close();
					}
				}
				catch (Exception e){
					e.printStackTrace();
				}
			}
		}	
	}

	private class FileHolder {
		private ZFile file;

		public FileHolder() {
			file = null;
		}
		public void file(ZFile f) {file = f;}
		public ZFile file() {return file;}
	}

}
