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
import com.ibm.smf.liberty.batch.LibertyBatchCompletionSection;
import com.ibm.smf.liberty.batch.LibertyBatchIdentificationSection;
import com.ibm.smf.liberty.batch.LibertyBatchProcessorSection;
import com.ibm.smf.liberty.batch.LibertyBatchRecord;
import com.ibm.smf.liberty.batch.LibertyBatchReferenceNamesSection;
import com.ibm.smf.liberty.batch.LibertyBatchSubsystemSection;
import com.ibm.smf.liberty.batch.LibertyBatchUssSection;
import com.ibm.smf.was.common.WASConstants;
import com.ibm.smf.utilities.ConversionUtilities;
import com.ibm.smf.utilities.STCK;


/**
 * First pass at CSVExport for Liberty SMF 120-12 records
 * @author follis
 *
 */
public class LibertyBatchExport implements SMFFilter {

	protected SmfPrintStream smf_printstream = null;
	private boolean header_written = false;
	
	public enum BatchStatus {STARTING, STARTED, STOPPING, STOPPED, FAILED, COMPLETED, ABANDONED };
	public static final String[] batchTypeString = {"STARTING","STARTED","STOPPING","STOPPED","FAILED","COMPLETED","ABANDONED"};
			
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
	   if (record.subtype()==WASConstants.LibertyBatchSmfRecordSubtype)
	         ok_to_process = true;
     return ok_to_process;
	}
	
	public void processRecord(SmfRecord record) 
	{
		int sectionCount;
		
		 // cast to a subtype 12 and declare generic variables
		LibertyBatchRecord rec = (LibertyBatchRecord)record;

		 // Here's the string we stuff everything into:
		 String s = new String();
		 
		 // Here's the header
		 String sHeader = new String();
		 
		 // From the base record get the time
		 s = s + rec.date().toString();
		 sHeader = sHeader + "RecordTime";

			 
		 Triplet libertyBatchSubsystemSection = rec.m_LibertyBatchSubsystemSectionTriplet;
		 Triplet libertyBatchIdentificationSection = rec.m_LibertyBatchIdentificationSectionTriplet;
		 Triplet libertyBatchCompletionSection = rec.m_LibertyBatchCompletionSectionTriplet;
		 Triplet libertyBatchProcessorSection = rec.m_LibertyBatchProcessorSectionTriplet;
		 Triplet libertyBatchUssSection = rec.m_LibertyBatchUssSectionTriplet;
		 Triplet libertyBatchReferenceNamesSection = rec.m_LibertyBatchReferenceNamesSectionTriplet;
		 
		 sectionCount = libertyBatchSubsystemSection.count();
		 if (sectionCount==1) {
			 LibertyBatchSubsystemSection sec = rec.m_libertyBatchSubsystemSection;

			 s = s + "," + sec.m_batch_record_type;
			 sHeader = sHeader + ",Type";

			 if ((sec.m_batch_record_type>=LibertyBatchSubsystemSection.STEP_ENDED_TYPE)&& 
					     (sec.m_batch_record_type <=LibertyBatchSubsystemSection.DECIDER_ENDED_TYPE)) {
				 s = s + "," + LibertyBatchSubsystemSection.typeString[sec.m_batch_record_type];
  		     } else {s = s + ",UNKNOWN"; } 
			 sHeader = sHeader + ",Type";
			 
		      // Add some strings
		      s = s + "," + sec.m_systemName + "," + sec.m_sysplexName +
		              "," + sec.m_jobId + "," + sec.m_jobName;
		      sHeader = sHeader + ",SystemName,SysplexName,JobId,JobName";
		      
		      // Add stoken and asid
		      s = s + "," + ConversionUtilities.longByteArrayToHexString(sec.m_server_stoken);
		      sHeader = sHeader + ",Stoken";

		      s = s + "," + sec.m_asid + "," + sec.m_serverConfigDir + "," + sec.m_productVersion;
		      sHeader = sHeader + ",ASID,ConfigDir,Version"; 
			 
			    
		      s = s + "," + new BigInteger(ConversionUtilities.longByteArrayToHexString(sec.m_systemGmtOffset),16).toString();
		      sHeader = sHeader + ",GMTOffset";

		      s = s + "," + sec.m_javaTimezone;
		      sHeader = sHeader + ",Java Timezone";
		      
		      if (sec.m_version==2) {
		    	    s = s + "," + sec.m_rctpcpua + "," + sec.m_rmctadjc + "," + sec.m_repositoryType + "," + sec.m_jobStoreRefId;
		    	    sHeader = sHeader + ",RCTPCPUA,RMCTADJC,RepType,RepRef";
		      }
		      
		 }
		 
		 sectionCount = libertyBatchIdentificationSection.count();
		 if (sectionCount==1) {
			 LibertyBatchIdentificationSection sec = rec.m_identificationSection;
			 
			 s = s + "," + sec.m_instanceId + "," + sec.m_executionId + "," + sec.m_executionNumber + "," + sec.m_stepExecutionId + "," + sec.m_partitionNumber;
			 sHeader = sHeader + ",instanceID,executionID,executionNumber,stepExecutionID,partitionNumber";

			 s = s + "," + sec.m_jobName + "," + sec.m_AmcName + "," + sec.m_XMLName + "," + sec.m_stepName + "," + sec.m_splitName + "," + sec.m_flowName;
			 sHeader = sHeader + ",jobname,AMCName,XMLName,stepName,splitName,flowName";
			 
			 s = s + "," + sec.m_createTime + "," + sec.m_createTimeDate + "," + sec.m_startTime + "," + sec.m_startTimeDate + "," + sec.m_endTime + "," + sec.m_endTimeDate;
			 sHeader = sHeader + ",createTime(ms),createTime,startTime(ms),startTime,endTime(ms),endTime";
			 
			 s = s + "," + (sec.m_endTime-sec.m_startTime);
			 sHeader = sHeader + ",elapsedTime";

			 s = s + "," + sec.m_submitter + "," + sec.m_jesJobName + "," + sec.m_jesJobId;
			 sHeader = sHeader + ",submitter,JESJobName,JESJobId";

			 s = s + "," + ConversionUtilities.intByteArrayToHexString(sec.m_tcbAddress);
			 sHeader = sHeader + ",TCB";
			 
			 if (sec.m_version >=2) {
				 s = s + "," + ConversionUtilities.longByteArrayToHexString(sec.m_flags) + "," + sec.m_stepStartLimit + "," + sec.m_chunkStepCheckpointPolicy +
						 "," + sec.m_chunkStepItemCount + "," + sec.m_chunkStepTimeLimit + "," + sec.m_chunkStepSkipLimit + "," +
						 sec.m_chunkStepRetryLimit;
				 sHeader = sHeader + ",flags,stepStartLimit,chunkStepCheckpointPolicy,chunkStepItemCount,chunkStepTimeLimit,chunkStepSkipLimit,chunkStepRetryLimit";
		    }			 
			 
		 }
		 
		 sectionCount = libertyBatchCompletionSection.count();
		 if (sectionCount==1) {
			 LibertyBatchCompletionSection sec = rec.m_completionSection;
			 
			 s = s + "," + sec.m_batchStatus + "," + batchTypeString[sec.m_batchStatus];
			 sHeader = sHeader + ",Batch Status,Batch Status";
			 
			 s = s + "," + sec.m_exitStatus;
			 sHeader = sHeader + ",Exit Status";
			 
			 s = s + "," + sec.m_partitionPlan + "," + sec.m_partitionPlan;
			 sHeader = sHeader + ",PartitionPlan,PartitionCount";
			 
			 s = s + "," + sec.m_readCount + "," + sec.m_writeCount + "," + sec.m_commitCount + "," + sec.m_rollbackCount + "," + 
			               sec.m_readSkipCount + "," + sec.m_processSkipCount + "," + sec.m_filterCount + "," + sec.m_writeSkipCount;
			 
			 sHeader = sHeader + ",readCount,writeCount,commitCount,rollbackCount,readSkipCount,processSkipCount,filterCount,writeSkipCount";
			 
		 }
		 
		 sectionCount = libertyBatchProcessorSection.count();
		 if (sectionCount==1) {
			 LibertyBatchProcessorSection sec = rec.m_processorSection;
			 
			 long totalCpuStart = sec.m_totalCPUStart;

			 long totalCpuEnd = sec.m_totalCPUEnd;
			 
			 long totalCpu = (totalCpuEnd - totalCpuStart)/4096000;
			 
			 long CPStart = sec.m_CPStart;

			 long CPEnd = sec.m_CPEnd;
			 
			 long CP = (CPEnd - CPStart)/4096000;
			 
			 long offloadStart = sec.m_offloadStart;;

			 long offloadEnd = sec.m_offloadEnd;
			 
			 long offload = (offloadEnd - offloadStart)/4096000;

			 long offloadOnCPStart = sec.m_offloadOnCpStart;

			 long offloadOnCPEnd = sec.m_offloadOnCpEnd;
			 
			 long offloadOnCP = (offloadOnCPEnd - offloadOnCPStart)/4096000;
			 
			 s = s + "," + totalCpuStart + "," + totalCpuEnd + "," + totalCpu +  
					 "," + CPStart + "," + CPEnd + "," + CP +
					 "," + offloadStart + "," + offloadEnd + "," + offload +
					 "," + offloadOnCPStart + "," + offloadOnCPEnd + "," + offloadOnCP;
			 
			 sHeader = sHeader + ",totalCPUStart,totalCPUEnd,totalCPU(ms)" +
			                     ",CPStart,CPEnd,CP(ms)" +
					             ",offloadStart,offloadEnd,offload(ms)" +
			                     ",offloadOnCPStart,offloadOnCPEnd,offloadOnCP(ms)";
			 
			 
		 }

		 sectionCount = libertyBatchUssSection.count();
		 if (sectionCount==1) {
			 LibertyBatchUssSection sec = rec.m_ussSection;
			 
			 s = s + "," + sec.m_pid;
			 s = s + "," + ConversionUtilities.longByteArrayToHexString(sec.m_threadId);
			 s = s + "," + ConversionUtilities.longByteArrayToHexString(sec.m_javaThreadId);
			 
			 sHeader = sHeader + ",pid,ThreadID,JavaThreadID";
			 
			 if (sec.m_version==2) {
				 s = s + "," + sec.m_uid + "," + sec.m_gid;
				 sHeader = sHeader + ",UID,GID";
			 }
			 
		 }
		 
		 sectionCount = libertyBatchReferenceNamesSection.count();
		 String reader = ",";
		 String processor = ",";
		 String writer = ",";
		 String checkpoint = ",";
		 String batchlet = ",";
		 String pMapper = ",";
		 String pReducer = ",";
		 String pCollector = ",";
		 String pAnalyzer = ",";
		 String decider = ",";
		 if (sectionCount>0) {
			 for (int i=1;i<=sectionCount;++i) {
				 LibertyBatchReferenceNamesSection refNames = rec.m_referenceNamesSection[i-1];
				 int type = refNames.m_refType;
				 if (type == LibertyBatchReferenceNamesSection.READER_REF_TYPE) {
					 reader = reader + refNames.m_refName;
				 }
				 if (type == LibertyBatchReferenceNamesSection.PROCESSOR_REF_TYPE) {
					 processor = processor + refNames.m_refName;
				 }
				 if (type == LibertyBatchReferenceNamesSection.WRITER_REF_TYPE) {
					 writer = writer + refNames.m_refName;
				 }
				 if (type == LibertyBatchReferenceNamesSection.CHECKPOINT_REF_TYPE) {
					 checkpoint = checkpoint + refNames.m_refName;
				 }
				 if (type == LibertyBatchReferenceNamesSection.BATCHLET_REF_TYPE) {
					 batchlet = batchlet + refNames.m_refName;
				 }
				 if (type == LibertyBatchReferenceNamesSection.PARTITION_MAPPER_REF_TYPE) {
					 pMapper = pMapper + refNames.m_refName;
				 }
				 if (type == LibertyBatchReferenceNamesSection.PARTITION_REDUCER_REF_TYPE) {
					 pReducer = pReducer + refNames.m_refName;
				 }
				 if (type == LibertyBatchReferenceNamesSection.PARTITION_COLLECTOR_REF_TYPE) {
					 pCollector = pCollector + refNames.m_refName;
				 }
				 if (type == LibertyBatchReferenceNamesSection.PARTITION_ANALYZER_REF_TYPE) {
					 pAnalyzer = pAnalyzer + refNames.m_refName;
				 }
				 if (type == LibertyBatchReferenceNamesSection.DECIDER_REF_TYPE) {
					 decider = decider + refNames.m_refName;
				 }

			 }
			 
			 s = s + reader+processor+writer+checkpoint+batchlet+pMapper+pReducer+pCollector+pAnalyzer+decider;
			 sHeader = sHeader + ",Reader,Processor,Writer,Checkpoint,Batchlet,Mapper,Reducer,Collector,Analyzer,Decider";
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
