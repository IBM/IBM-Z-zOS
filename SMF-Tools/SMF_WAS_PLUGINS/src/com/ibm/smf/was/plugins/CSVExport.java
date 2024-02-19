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
import com.ibm.smf.twas.request.NetworkDataSection;
import com.ibm.smf.twas.request.PlatformNeutralRequestInfoSection;
import com.ibm.smf.twas.request.RequestActivitySmfRecord;
import com.ibm.smf.twas.request.SecurityDataSection;
import com.ibm.smf.twas.request.ZosRequestInfoSection;
import com.ibm.smf.was.common.ClassificationDataSection;
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
public class CSVExport implements SMFFilter {

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
	 
	 // Ignore Async work records...maybe a different CSV handler for those?
	 zOSRequestTriplet = rec.m_asyncWorkDataTriplet;
	 sectionCount = zOSRequestTriplet.count();
	 if (sectionCount >0) {
		 return;
	 }
	 
	 // Variables to remember CPU time, all in millisconds.
	 float cpuTime=0;
	 float offloadCpuTime=0;
	 float enclaveCpuTime=0;
	 float enclaveZiipCpuTime=0;
	 
	 
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
	 
	 // From the Platform Neutral Request Info Section
	 zOSRequestTriplet = rec.m_platformNeutralRequestInfoTriplet;
	 sectionCount = zOSRequestTriplet.count();
	 if (sectionCount > 0)
	 {
      PlatformNeutralRequestInfoSection sec = rec.m_platformNeutralRequestInfoSection;
      
	  // Add Servant PID
      s = s + "," + ConversionUtilities.intByteArrayToHexString(sec.m_dispatchServantPID);
      sHeader = sHeader + ",ServantPid";
      
	  // Add Task ID
      s = s + "," + ConversionUtilities.longByteArrayToHexString(sec.m_dispatchTaskId);
      sHeader = sHeader + ",ServantTaskID";
      
      // Add TCB CPU time
      s = s + "," + sec.m_dispatchTcbCpu;
      sHeader = sHeader + ",TCB CPU";
      // Add TCB CPU time (ms)
 	  cpuTime = (float)sec.m_dispatchTcbCpu/(float)1000;
      s = s + "," + (float)sec.m_dispatchTcbCpu/(float)1000;
      sHeader = sHeader + ",TCB CPU(ms)";
      
      // Add minor code
      s = s + "," + ConversionUtilities.intByteArrayToHexString(sec.m_completionMinorCode);
      sHeader = sHeader + ",MinorCode";
      
      // Add request type
      s = s + "," + sec.m_requestType;
      sHeader = sHeader + ",RequestType";
      
	 }
	 
	 // From the zOS request section
	 zOSRequestTriplet = rec.m_zosRequestInfoTriplet;
	 sectionCount = zOSRequestTriplet.count();
	 
     boolean SM1209DU;      
     boolean SM1209DV;      
     boolean SM1209DW;      
     boolean SM1209DX=false;      
     boolean SM1209DY;      
     boolean SM1209DZ;      
     boolean SM1209FJ;      

	 
	 // If we have the zOS request info section
     if (sectionCount>0)
     {
      ZosRequestInfoSection sec = rec.m_zosRequestInfoSection;
          
      // Add received time
      
      s = s + "," + STCK.toString(ConversionUtilities.longByteArrayToHexString(sec.m_received)).replace(',',' ');
      sHeader = sHeader + ",ReceivedTime";
      long receiveTime = (new BigInteger(ConversionUtilities.longByteArrayToHexString(sec.m_received),16).shiftRight(12).longValue())/1000L;;
      s = s + "," +  receiveTime;
      sHeader = sHeader + ",ReceivedTime(Dec-ms)";
      
      // Add queued time
      s = s + "," + STCK.toString(ConversionUtilities.longByteArrayToHexString(sec.m_queued)).replace(',',' ');
      sHeader = sHeader + ",QueuedTime";
      long queuedTime = (new BigInteger(ConversionUtilities.longByteArrayToHexString(sec.m_queued),16).shiftRight(12).longValue())/1000L;
      s = s + "," + queuedTime;
      sHeader = sHeader + ",QueuedTime(Dec-ms)";
      
      s = s + "," + (queuedTime-receiveTime);
      sHeader = sHeader + ",InCR (ms)";
      
      // Add dispatched time
      s = s + "," + STCK.toString(ConversionUtilities.longByteArrayToHexString(sec.m_dispatched)).replace(',',' ');
      sHeader = sHeader + ",DispatchedTime";
      long dispatchStart= (new BigInteger(ConversionUtilities.longByteArrayToHexString(sec.m_dispatched),16).shiftRight(12).longValue())/1000L;
      s = s + "," + dispatchStart;
      sHeader = sHeader + ",DispatchedTime(Dec-ms)";

      s = s + "," + (dispatchStart - queuedTime);
      sHeader = sHeader + ",InQueue (ms)";
      
      // Add dispatch complete time
      s = s + "," + STCK.toString(ConversionUtilities.longByteArrayToHexString(sec.m_dispatchcomplete)).replace(',',' ');
      sHeader = sHeader + ",DispatchedCompleteTime";
      long dispatchEnd = (new BigInteger(ConversionUtilities.longByteArrayToHexString(sec.m_dispatchcomplete),16).shiftRight(12).longValue())/1000L;
      s = s + "," + dispatchEnd;
      sHeader = sHeader + ",DispatchComplete(Dec-ms)";

      s = s + "," + (dispatchEnd - dispatchStart);
      sHeader = sHeader + ",InDispatch (ms)";
      
      // Add complete time
      s = s + "," + STCK.toString(ConversionUtilities.longByteArrayToHexString(sec.m_complete)).replace(',',' ');
      sHeader = sHeader + ",CompleteTime";
      long responded = (new BigInteger(ConversionUtilities.longByteArrayToHexString(sec.m_complete),16).shiftRight(12).longValue())/1000L;
      s = s + "," + responded;
      sHeader = sHeader + ",Complete(Dec-ms)";
      
      s = s + "," + (responded - dispatchEnd);
      sHeader = sHeader + ",InCompletion (ms)";
      
      s = s + "," + (responded - receiveTime);
      sHeader = sHeader + ",RespTime";
      
      // Add servant jobname/jobid
      s = s + "," + sec.m_dispatchServantJobname + 
              "," + sec.m_dispatchServantJobId;
      sHeader = sHeader + ",ServantJobname,ServantJobId";
      
      // Add stoken and asid
      s = s + "," + ConversionUtilities.longByteArrayToHexString(sec.m_dispatchServantStoken);
      sHeader = sHeader + ",SRStoken";
      
      s = s + "," + ConversionUtilities.shortByteArrayToHexString(sec.m_dispatchServantAsid);
      sHeader= sHeader + ",SRAsid";
      
      // Add dispatch TCB address
      s = s + "," + ConversionUtilities.intByteArrayToHexString(sec.m_dispatchServantTcbAddress);
      sHeader = sHeader + ",DispatchTCB";
      
      // skipping ttoken for now
      
      // TCB CPU offload
      s = s + "," + sec.m_dispatchServantCpuOffload;
      sHeader = sHeader + ",TCPCPUOffload";
      
      // TCB CPU offload (ms)
   	  offloadCpuTime = (float)sec.m_dispatchServantCpuOffload/(float)1000;
      s = s + "," + (float)sec.m_dispatchServantCpuOffload/(float)1000;
      sHeader = sHeader + ",TCPCPUOffload(ms)";
      // Add enclave token
      s = s + "," + ConversionUtilities.longByteArrayToHexString(sec.m_dispatchServantEnclaveToken);
      sHeader = sHeader + ",EnclaveToken";

      // More CPU Times
   	  enclaveCpuTime = (float)sec.m_EnclaveDeleteCPU/(float)4096000;
   	  enclaveZiipCpuTime = (float)sec.m_EnclaveDeletezIIPCPUNormalized/(float)4096000;
      
      s = s + "," + sec.m_dispatchServantEnclaveCpu        +
              "," + sec.m_dispatchServantZaapCpu           +
              "," + sec.m_dispatchServantzAAPEligibleonCP  +
              "," + sec.m_dispatchServantzIIPonCPUsofar    +
              "," + sec.m_dispatchServantzIIPQualTimeSoFar +
              "," + sec.m_dispatchServantzIIPCPUSoFar      +
              "," + sec.m_dispatchServantzAAPNormalizationFactor +
              "," + sec.m_EnclaveDeleteCPU                 +
              "," + (float)sec.m_EnclaveDeleteCPU/(float)4096000         +
              "," + sec.m_EnclaveDeletezAAPCPU             +
              "," + sec.m_EnclaveDeletezAAPNorm            +
              "," + sec.m_EnclaveDeletezIIPCPUNormalized   +
              "," + (float)sec.m_EnclaveDeletezIIPCPUNormalized/(float)4096000 +
              "," + sec.m_EnclaveDeletezIIPService         +
              "," + sec.m_EnclaveDeletezAAPService         +
              "," + sec.m_EnclaveDeleteCpuService          +
              "," + sec.m_EnclaveDeleteRespTimeRatio;
      
      sHeader = sHeader + ",EnclaveCPU"              +
                          ",EnclavezAAPCPU"          +
                          ",EnclavezAAPEligibleonCP" +
                          ",EnclavezIIPOnCPUSoFar"   +
                          ",EnclavezIIPQualTimeSoFar"+
                          ",EnclavezIIPCPUSoFar"     +
                          ",EnclavezAAPNormalization"+
                          ",EnclaveDeleteCPU"        +
                          ",EnclaveDeleteCPU(ms)"    +
                          ",EnclaveDeletezAAPCPU"    +
                          ",EnclaveDeletezAAPNorm"   +
                          ",EnclaveDeletezIIPCPUNorm"+
                          ",EnclaveDeletezIIPCPU(ms)"+
                          ",EnclaveDeletezIIPServiceUnits"+
                          ",EnclaveDeletezAAPServiceUnits"+
                          ",EnclaveDeleteCPUServiceUnits"+
                          ",EnclaveDeleteResponseTimeRatio";
                          
      // skip GTID for now
      
      // add dispatch timeout
      s = s + "," + sec.m_dispatchTimeout;
      sHeader = sHeader + ",Timeout";
      
      // Add Tran Class
      s = s + "," + sec.m_tranClass;
      sHeader = sHeader + ",TransactionClass";
      
      // flags
      int flags = ConversionUtilities.intByteArrayToInt(sec.m_flags);
      SM1209DU = ((flags&0x80000000)!=0)?true:false;      
      SM1209DV = ((flags&0x40000000)!=0)?true:false;      
      SM1209DW = ((flags&0x20000000)!=0)?true:false;      
      SM1209DX = ((flags&0x10000000)!=0)?true:false;      
      SM1209DY = ((flags&0x08000000)!=0)?true:false;      
      SM1209DZ = ((flags&0x04000000)!=0)?true:false;      
      SM1209FJ = ((flags&0x02000000)!=0)?true:false;      

      s = s + ","+SM1209DU +
              ","+SM1209DV +
              ","+SM1209DW +
              ","+SM1209DX +
              ","+SM1209DY +
              ","+SM1209DZ +
              ","+SM1209FJ;
     
      sHeader = sHeader + ",CreatedEnclave" +
                          ",TimeoutExternal" +
                          ",TranClassExternal"+
                          ",OneWay"+
                          ",CPUUsageOverflow"+
                          ",QueuedWithAffinity"+
                          ",CEEGMTOUnavailable";
     }

     
	 // From the network section
	 zOSRequestTriplet = rec.m_networkDataTriplet;
	 sectionCount = zOSRequestTriplet.count();
	 // If we have the network info section
     if (sectionCount>0)
     {
    	 // There should at most be one of these, but for some reason we have an array so handle it...
    	 for (int i=1;i<=sectionCount;++i) {
    		 NetworkDataSection nds =  rec.m_networkDataSection[i-1];

    		 s = s +"," + nds.m_bytesReceived;
    		 
    		 s = s +"," + nds.m_bytesSent;
    		 
    		 s = s +"," + nds.m_targetPort;
    		 
    		 s = s +"," + nds.m_originstring;
    	 }
    
     } else {
    	 s = s + ",,,,";
     }
     
     
     
     // Always add the header in case the first pass doesn't have the section
	 sHeader = sHeader + ",Bytes Rcvd,Bytes Sent,TargetPort,Origin";
     
	 // From the classification section
	 zOSRequestTriplet = rec.m_classificationDataTriplet;
	 sectionCount = zOSRequestTriplet.count();
	 String uri = ",";
	 String host = ",";
	 String port = ",";
	 String appName = ",";
	 String modName = ",";
	 String compName = ",";
	 String className = ",";
	 String methodName = ",";
	 String wolaServiceName = ",";
	 String wolaCICSTranName = ",";

	 // If we have the network info section
     if (sectionCount>0)
     {
    	 // For now we'll just handle HTTP classification types
    	 // Hunt through for those and remember the values
    	 // add 'em to our string at the end so they are always in the same order
    	 // regardless how they show up in the record
    	 
    	 for (int i=1;i<=sectionCount;++i) {
    		 ClassificationDataSection cds =  rec.m_classificationDataSection[i-1];
            int type = cds.m_dataType;
            if (type == ClassificationDataSection.TypeURI){
            	uri = uri + cds.m_theData;
            } else if (type==ClassificationDataSection.TypeHostname) {
            	host = host + cds.m_theData;
            } else if (type==ClassificationDataSection.TypePort) {
            	port = port + cds.m_theData;
            } else if (type==ClassificationDataSection.TypeApplicationName){
            	appName= appName + cds.m_theData;
            } else if (type==ClassificationDataSection.TypeModuleName) {
            	modName = modName + cds.m_theData;
            } else if (type==ClassificationDataSection.TypeComponentName){
            	compName = compName + cds.m_theData;
            } else if (type==ClassificationDataSection.TypeClassName){
            	className = className + cds.m_theData;
            } else if (type==ClassificationDataSection.TypeMethodName){
            	methodName = methodName + cds.m_theData;
            } else if (type==ClassificationDataSection.TypeWolaServiceName){
            	wolaServiceName = wolaServiceName + cds.m_theData;
            } else if (type==ClassificationDataSection.TypeWolaCICSTranName){
            	wolaCICSTranName = wolaCICSTranName + cds.m_theData;
            }  
    	 }
     }

     
     s = s + host + port + uri + appName + modName + compName + className + methodName + wolaServiceName + wolaCICSTranName;
     
	 // But add the HTTP classification header always...first thing we find might not have 'em.
	 sHeader = sHeader + ",Host,Port,URI,EJBApp,EJBMod,EJBComp,EJBClass,EJBMethod,WOLAService,WOLACICSTclass"; 
	 
	 // From the security section
	 zOSRequestTriplet = rec.m_securityDataTriplet;
	 sectionCount = zOSRequestTriplet.count();
	 
	 String server = ",";
	 String received = ",";
	 String invocation = ",";

	 // If we have the network info section
     if (sectionCount>0)
     {
    	 // Hunt through for and remember the values
    	 // add 'em to our string at the end so they are always in the same order
    	 // regardless how they show up in the record
   	 
    	 for (int i=1;i<=sectionCount;++i) {
    		 SecurityDataSection sds =  rec.m_securityDataSection[i-1];
            int type = sds.m_dataType;
            if (type == 1){
            	server = server + sds.m_id;
            } else if (type==2) {
            	received = server + sds.m_id;
            } else if (type==3) {
            	invocation = server + sds.m_id;
            }  // ignore other types for now
    	 }
     }

     s= s + server+received+invocation;
     
	 // But add the HTTP classification header always...first thing we find might not have 'em.
	 sHeader = sHeader + ",Server,Received,Invocation"; 
	 
	 
	 // Go back to the zos request data and look for version 2 data
	 zOSRequestTriplet = rec.m_zosRequestInfoTriplet;
	 sectionCount = zOSRequestTriplet.count();
	 // If we have the zOS request info section
     if (sectionCount>0)
     {
      ZosRequestInfoSection sec = rec.m_zosRequestInfoSection;
          
      int version = sec.m_version;
      if (version>=2) {
    	  int obtained_aff_length = sec.m_obtainedAffinityLength;
    	  s = s + "," + obtained_aff_length;
    	  if (obtained_aff_length >0) {
    		  String obtained_aff = ConversionUtilities.stripTrailingZeroes(ConversionUtilities.bytesToHex(sec.m_obtainedAffinity));
    		  s = s + ","+obtained_aff;
    	  } else { s = s + ","; }
    	  
    	  int used_aff_length = sec.m_routingAffinityLength;
    	  s = s + "," + used_aff_length;
     	  if (used_aff_length >0) {
    		  String used_aff = ConversionUtilities.stripTrailingZeroes(ConversionUtilities.bytesToHex(sec.m_routingAffinity));
    		  s = s + "," + used_aff;
    	  } else { s = s + ","; }

    	  String[] dumpActions = new String[]{"None","JavaCore","HeapDump","TraceBack","SVCDump","TDump"};

    	  int queue_timeout = sec.m_queue_timeout;
    	  s = s + "," + queue_timeout;

    	  int dispatch_timeout = sec.m_dispatch_timeout;
    	  s = s + "," + dispatch_timeout;
    	  
    	  int stalled_thread_dump_action = sec.m_stalled_thread_dump_action;
    	  s = s + ","+ dumpActions[stalled_thread_dump_action];

    	  
    	  int cpu_timeout = sec.m_cputimeused_limit;
    	  s = s + "," + cpu_timeout;
    	  
    	  int cpu_dump_action = sec.m_cputimeused_dump_action;
    	  s = s + "," + cpu_dump_action;
    	  
    	  
    	  int dpm_interval = sec.m_dpm_interval;
    	  s = s + "," + dpm_interval;
    	  
    	  int dpm_dump_action = sec.m_dpm_dump_action;
    	  s = s + "," + dumpActions[dpm_dump_action];

    	  
    	  int timeout_recovery = sec.m_timeout_recovery;
    	  s = s + "," + timeout_recovery;
    	  
    	  int outbound_request_timeout = sec.m_request_timeout;
    	  s = s + "," + outbound_request_timeout;

    	  String tag = sec.m_message_tag;
    	  s = s + "," + tag;
    	  
      } else {
    	  s = s + ",,,,,,,,,,,,,,";
      }
	 
      // Always write header
      sHeader = sHeader + ",ObtainedAffLen,ObtainedAffinityToken,RoutingAffLen,RoutingAffinityToken," +
                          "QueueTimeout, DispatchTimeout,StalledThreadDumpAction,CPUTimeout,CPUDumpAction," +
    		              "DPMInterval,DPMDumpAction,TimeoutRecovery," +
      		      		"OutReqTimeout,Tag";
      
      
     }	 
     
     // Add offload percentages at the end
	 sHeader = sHeader + ",TCBOffload%,EnclaveOffload%";
	 
	 float tcbOffload = 0;
	 float enclaveOffload = 0;
	 if (cpuTime>0) {
		 tcbOffload = offloadCpuTime/cpuTime;
	 }
	 if (enclaveCpuTime>0) {
		 enclaveOffload = enclaveZiipCpuTime/enclaveCpuTime;
	 }
     s = s + "," + tcbOffload + "," + enclaveOffload;
     // Write the header (if first time through)
     if (!header_written)
     {	   
      smf_printstream.println(sHeader);
  	  header_written = true;
     }
     // Write the record
     
     if (Boolean.getBoolean("oneWayOnly")) {
    	 if (SM1209DX) {
    	     smf_printstream.println(s);    		 
    	 }
     } else {
         smf_printstream.println(s);
     }
     		
	}

	public void processingComplete() 
	{
	}

			  
	
}
