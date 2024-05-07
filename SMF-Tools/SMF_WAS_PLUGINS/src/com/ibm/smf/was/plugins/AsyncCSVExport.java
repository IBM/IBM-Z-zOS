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

package com.ibm.smf.was.plugins;

import java.math.BigInteger;

import com.ibm.smf.format.DefaultFilter;
import com.ibm.smf.format.SMFFilter;
import com.ibm.smf.format.SmfPrintStream;
import com.ibm.smf.format.SmfRecord;
import com.ibm.smf.format.Triplet;
import com.ibm.smf.twas.request.AsyncWorkDataSection;
import com.ibm.smf.twas.request.RequestActivitySmfRecord;
import com.ibm.smf.was.common.PlatformNeutralSection;
import com.ibm.smf.was.common.WASConstants;
import com.ibm.smf.was.common.ZosServerInfoSection;
import com.ibm.smf.utilities.ConversionUtilities;
import com.ibm.smf.utilities.STCK;

/**
 * 
 * Export data to comma separated value file
 *
 */
public class AsyncCSVExport implements SMFFilter {

	protected SmfPrintStream smf_printstream = null;
	private boolean header_written = false;
	
	public boolean initialize(String parms) 
	{
	 boolean return_value = true;
	 smf_printstream = DefaultFilter.commonInitialize(parms);
	 if (smf_printstream==null)
	      return_value = false;
	 return return_value;
	}

	public SmfRecord parse(SmfRecord record) 
	{
	 return DefaultFilter.commonParse(record);		
	}


	public boolean preParse(SmfRecord record) 
	{
	 boolean ok_to_process = false;
	 if (record.type()== WASConstants.SmfRecordType)
	   if (record.subtype()==WASConstants.RequestActivitySmfRecordSubtype)
	         ok_to_process = true;
     return ok_to_process;
	}

	public void processRecord(SmfRecord record) 
	{
		
	 // cast to a subtype 9 and declare generic variables
	 RequestActivitySmfRecord rec = (RequestActivitySmfRecord)record;
	 Triplet zOSRequestTriplet;
	 int sectionCount;
	 
	 // Ignore non-Async work records...use CSVExport for those
	 zOSRequestTriplet = rec.m_asyncWorkDataTriplet;
	 sectionCount = zOSRequestTriplet.count();
	 if (sectionCount==0) {
		 return;
	 }
	 
	 
	 // Here's the string we stuff everything into:
	 String s = new String();
	 
	 // Here's the header
	 String sHeader = new String();
	 
	 // From the base record get the time
	 s = s + rec.date().toString();
	 sHeader = sHeader + "RecordTime";
	 
	 // From the Platform Neutral Server Section
	 zOSRequestTriplet = rec.m_platformNeutralSectionTriplet;
	 sectionCount = zOSRequestTriplet.count();
	 if (sectionCount>0)
	 {
	  PlatformNeutralSection sec = rec.m_platformNeutralSection;
	  
	  
	  // Add cell/node/cluster/server names
	  s = s + "," + sec.m_cellShortName + "," + sec.m_nodeShortName + 
	          "," + sec.m_clusterShortName + "," + sec.m_serverShortName;
	  sHeader = sHeader + ",CellName,NodeName,ClusterName,ServerName"; 
	  
	  // Add Controller PID
	  s = s + "," + Integer.toHexString(sec.m_serverControllerPid).toUpperCase();
	  sHeader = sHeader + ",ControllerPid";
	  
	  // Add server version
	  s = s + "," + sec.m_wasRelease + "," + sec.m_wasReleaseX +
	          "," + sec.m_wasReleaseY + "," + sec.m_wasReleaseZ;
	  sHeader = sHeader + ",Release,ReleaseX,ReleaseY,ReleaseZ";
	  
	 }
	 
	 // From the Server Info Section
	 zOSRequestTriplet = rec.m_zosServerInfoTriplet;
	 sectionCount = zOSRequestTriplet.count();
	 if (sectionCount > 0)
	 {
      ZosServerInfoSection sec = rec.m_zosServerInfoSection;
      
      // Add some strings
      s = s + "," + sec.m_systemName + "," + sec.m_sysplexName +
              "," + sec.m_controllerJobName + "," + sec.m_controllerJobId;
      sHeader = sHeader + ",SystemName,SysplexName,CRJobname,CRJobid";
      
      // Add stoken and asid
      s = s + "," + ConversionUtilities.longByteArrayToHexString(sec.m_controllerStoken);
      sHeader = sHeader + ",CRStoken";
      
      s = s + "," + ConversionUtilities.shortByteArrayToHexString(sec.m_controllerAsid);
      sHeader= sHeader + ",CRAsid";
      
      // Skipping server/cluster UUIDs for now
      
      // Daemon Group name and service level
      s = s + "," + sec.m_daemonGroupName + "," + sec.m_maintenanceLevel;
      sHeader = sHeader + ",DaemonGroupName,MaintenanceLevel";
      
      // Add GMT offset for now
      s = s + "," + sec.m_leGmtOffsetHours + 
              "," + sec.m_leGmtOffsetMin +
              "," + sec.m_leGmtOffsetSec;
      sHeader = sHeader + ",LEGMTOffsetHours,LEGMTOffsetMin,LEGMTOffsetSeconds";
      
      s = s + "," + new BigInteger(ConversionUtilities.longByteArrayToHexString(sec.m_systemGmtOffset),16).toString();      
      sHeader = sHeader + ",SystemGMTOffset";
      
	 }

	 zOSRequestTriplet = rec.m_asyncWorkDataTriplet;
	 sectionCount = zOSRequestTriplet.count();
	 if (sectionCount>0) {  // better be or we would have returned earlier
		
		 AsyncWorkDataSection sec = rec.m_asyncWorkDataSection[0];
		 
		  // Add received time
	      
	      s = s + "," + STCK.toString(ConversionUtilities.longByteArrayToHexString(sec.m_timeExecutionContextCreated)).replace(',',' ');
	      sHeader = sHeader + ",ExCtxCreatedTime";
	      long exCtxCreatedTime = (new BigInteger(ConversionUtilities.longByteArrayToHexString(sec.m_timeExecutionContextCreated),16).shiftRight(12).longValue())/1000L;;
	      s = s + "," +  exCtxCreatedTime;
	      sHeader = sHeader + ",ExCtxCreatedTime(Dec-ms)";
	  		 
	      s = s + "," + STCK.toString(ConversionUtilities.longByteArrayToHexString(sec.m_executionStartTime)).replace(',',' ');
	      sHeader = sHeader + ",ExStartTime";
	      long exStartTime = (new BigInteger(ConversionUtilities.longByteArrayToHexString(sec.m_executionStartTime),16).shiftRight(12).longValue())/1000L;;
	      s = s + "," +  exStartTime;
	      sHeader = sHeader + ",ExStartTime(Dec-ms)";
		 
	      s = s + "," + STCK.toString(ConversionUtilities.longByteArrayToHexString(sec.m_executionCompleteTime)).replace(',',' ');
	      sHeader = sHeader + ",ExEndTime";
	      long exEndTime = (new BigInteger(ConversionUtilities.longByteArrayToHexString(sec.m_executionCompleteTime),16).shiftRight(12).longValue())/1000L;;
	      s = s + "," +  exEndTime;
	      sHeader = sHeader + ",ExEndTime(Dec-ms)";
		 
		  // Add Servant PID
	      s = s + "," + Integer.toHexString(sec.m_servantPID).toUpperCase();
	      sHeader = sHeader + ",ServantPid";

	      // Add servant jobname/jobid
	      s = s + "," + sec.m_servantJobName + 
	              "," + sec.m_servantJobId;
	      sHeader = sHeader + ",ServantJobname,ServantJobId";
	      
	      // Add stoken and asid
	      s = s + "," + ConversionUtilities.longByteArrayToHexString(sec.m_servantStoken);
	      sHeader = sHeader + ",SRStoken";
	      
	      s = s + "," + ConversionUtilities.shortByteArrayToHexString(sec.m_servantAsid);
	      sHeader= sHeader + ",SRAsid";
	 
		  // Add Task ID
	      s = s + "," + ConversionUtilities.longByteArrayToHexString(sec.m_executionContextTaskId);
	      sHeader = sHeader + ",ExCtxTaskID";

	      // Add dispatch TCB address
	      s = s + "," + ConversionUtilities.intByteArrayToHexString(sec.m_executionContextTcbAddress);
	      sHeader = sHeader + ",ExCtxTCB";

	      // skip Ex CTX TTOKEN
	      
		  // Add Task ID
	      s = s + "," + ConversionUtilities.longByteArrayToHexString(sec.m_dispatchTaskId);
	      sHeader = sHeader + ",DispatchTaskID";

	      // Add dispatch TCB address
	      s = s + "," + ConversionUtilities.intByteArrayToHexString(sec.m_dispatchTcbAddress);
	      sHeader = sHeader + ",DispatchTCB";

	      // skip Dispatch TTOKEN
	      
	      // Add enclave token
	      s = s + "," + ConversionUtilities.longByteArrayToHexString(sec.m_executionContextEnclaveToken);
	      sHeader = sHeader + ",ExCtxEnclaveToken";

	      // Add enclave token
	      s = s + "," + ConversionUtilities.longByteArrayToHexString(sec.m_dispatchEnclaveToken);
	      sHeader = sHeader + ",DispatchEnclaveToken";
	      
	      // Add Tran Class
	      s = s + "," + sec.m_enclaveTranClass;
	      sHeader = sHeader + ",TransactionClass";

	      // flags
	      int flags = ConversionUtilities.intByteArrayToInt(sec.m_flags);
	      boolean SM1209HE = ((flags&0x80000000)!=0)?true:false;      
	      boolean SM1209HF = ((flags&0x40000000)!=0)?true:false;      

	      s = s + ","+SM1209HE +
	              ","+SM1209HF;
	      
	      sHeader = sHeader + ",CreatedEnclave" +
                  ",isDaemon";
	      
	      // Skipping enclave CPU so-far because the values are crap
	      
	      
	      // Add TCB CPU time
	      s = s + "," + sec.m_dispatchTcbCpu;
	      sHeader = sHeader + ",TCB CPU";
	      // Add TCB CPU time (ms)
	      s = s + "," + (float)sec.m_dispatchTcbCpu/(float)1000;
	      sHeader = sHeader + ",TCB CPU(ms)";
	      
	      // TCB CPU offload
	      s = s + "," + sec.m_dispatchCpuOffloadNonStd;
	      sHeader = sHeader + ",TCPCPUOffloadNonStd";

	      // TCB CPU offload (ms)
	      s = s + "," + (float)sec.m_dispatchCpuOffloadNonStd/(float)1000;
	      sHeader = sHeader + ",TCPCPUOffloadNonStd(ms)";
	      
	      s = s + "," + sec.m_workClassName + "," + sec.m_workMgrName +
	              "," + sec.m_identity;
	      sHeader = sHeader + ",WorkClassName,WorkMgrName,Identity";
	 }

	 
	 
	 
     // Write the header (if first time through)
     if (!header_written)
     {	   
      smf_printstream.println(sHeader);
  	  header_written = true;
     }
     // Write the record
     smf_printstream.println(s);
	}

	public void processingComplete() 
	{
	}

			  
	
}
