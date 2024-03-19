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
package com.ibm.smf.format.types;

import java.io.UnsupportedEncodingException;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.List;

import com.ibm.smf.format.SmfRecord;
import com.ibm.smf.format.SmfUtil;
import com.ibm.smf.format.Triplet;
import com.ibm.smf.format.UnsupportedVersionException;

/**
 * https://www.ibm.com/docs/en/zos/3.1.0?topic=statistics-subtype-1-zos-supervisor
 */
@SuppressWarnings("unused")
public class SMFType98SubType1 extends SmfRecord {
	private static final boolean DEBUG = Boolean.parseBoolean(System.getProperty("DEBUG", "false"));
	private static final boolean WARNINGS = Boolean.parseBoolean(System.getProperty("WARNINGS", "true"));
	private static final boolean ERRORS = Boolean.parseBoolean(System.getProperty("ERRORS", "true"));

	public int m_SMF98_1_UT_Avg_CpuBusy_CP;
	public int m_SMF98_1_UT_Avg_CpuBusy_zAAP;
	public int m_SMF98_1_UT_Avg_CpuBusy_zIIP;
	public String m_AddressSpaceMostCPUTime_CP;
	public String m_AddressSpaceMostCPUTime_zAAP;
	public String m_AddressSpaceMostCPUTime_zIIP;

	public SMFType98SubType1(SmfRecord aSmfRecord) throws UnsupportedVersionException, UnsupportedEncodingException {
		super(aSmfRecord);

		// SmfRecord reads up to and including SMF98STY
		// https://www.ibm.com/docs/en/zos/3.1.0?topic=rm-record-header
		int SMF98IND = m_stream.read();

		// We don't really care to reconstitute the record parts so we'll
		// just analyze the record parts as they stream through
		int SMF98PartSeqNo = m_stream.read();
		int SMF98SDSLen = m_stream.getInteger(2);
		int SMF98SDSTripletsNum = m_stream.getInteger(2);
		
		if (DEBUG)
			System.out.println(
					"SMFType98SubType1 new record SMF98IND: " + SMF98IND + ", SMF98PartSeqNo: " + SMF98PartSeqNo
							+ ", SMF98SDSLen: " + SMF98SDSLen + ", SMF98SDSTripletsNum: " + SMF98SDSTripletsNum);

		// Sanity check
		if (SMF98SDSTripletsNum == 3) {
			// Reserved: https://www.ibm.com/docs/en/zos/3.1.0?topic=rm-record-header
			m_stream.skip(18);

			Triplet i = new Triplet(m_stream, 4, 2, 2);
			Triplet cs = new Triplet(m_stream, 4, 2, 2);
			Triplet d = new Triplet(m_stream, 4, 2, 2);
			
			if (DEBUG)
				System.out.println(
						"SMFType98SubType1 triplets i: " + i + ", cs: " + cs + ", d: " + d);

			if (i.count() == 1) {
				// https://www.ibm.com/docs/en/zos/3.1.0?topic=rm-identification-section-2
				seek(i);

				String jobName = m_stream.getString(8, SmfUtil.EBCDIC);

				Calendar start = readDateTime();

				m_stream.skip(8);

				m_stream.skip(8);
				m_stream.skip(8);

				String systemName = m_stream.getString(8, SmfUtil.EBCDIC);

				// Sanity check that we're reading things right
				if (systemName.trim().equals(m_sid.trim())) {
					if (DEBUG)
						System.out.println("SMFType98SubType1 system name = " + systemName);

					m_stream.skip(16);

					m_stream.skip(16);
				} else {
					if (ERRORS)
						System.err
								.println("ERROR: Unexpected system name " + systemName + " in the context of " + m_sid);

					return;
				}
			} else if (i.count() > 1) {
				if (ERRORS)
					System.err.println("ERROR: Unexpected number of identification sections: " + i.count());

				return;
			}

			// https://www.ibm.com/docs/en/zos/3.1.0?topic=rm-context-summary-section
			if (cs.count() == 1) {
				seek(cs);

				m_stream.skip(8);

				// SMF98_SubtypeInfo is an alias of the 5 subsequent fields, so we don't
				// actually read it.
				// This is why its offset matches SMF98_ReleaseIndex.
				// m_stream.skip(24);

				int SMF98_ReleaseIndex = m_stream.getInteger(2);
				int SMF98_WithinReleaseIndex = m_stream.getInteger(2);
				int SMF98_PrototypeIndex = m_stream.getInteger(2);
				m_stream.skip(2);
				String SMF98_Prodlevel = m_stream.getString(16, SmfUtil.EBCDIC);

				m_stream.skip(8);
				m_stream.skip(8);
				m_stream.skip(8);
				m_stream.skip(8);
				m_stream.skip(16);
				m_stream.skip(16);
			} else if (cs.count() > 1) {
				if (ERRORS)
					System.err.println("ERROR: Unexpected number of context summary sections: " + cs.count());

				return;
			}

			// The data section depends on the subtype:
			// https://www.ibm.com/docs/en/zos/3.1.0?topic=sr-record-type-98-x62-workload-interaction-correlator-high-frequency-throughput-statistics

			// Sanity check that we're in subtype 1
			if (m_subtype == 1) {
				// Subtype 1:
				// https://www.ibm.com/docs/en/zos/3.1.0?topic=statistics-subtype-1-zos-supervisor
				if (d.count() > 0) {

					seek(d);

					if (d.count() > 1) {
						if (ERRORS)
							// We would presumably need to first read all of the triplets and then seek
							// around
							System.err.println("ERROR: Not implemented");
						return;
					}

					for (int j = 0; j < d.count(); j++) {
						// Finally, read the subtype 1 data record:
						// https://www.ibm.com/docs/en/zos/3.1.0?topic=supervisor-data-section
						int tripletsCount = m_stream.getInteger(4);

						// "The SMF type 98 subtype 1 data section begins with a number of triplets
						// (SMF98_1_DataTripletsNum) for a length of SMF98_1_DataTripletsNum. Check this
						// triplet information prior to accessing a section of the record. The "number"
						// triplet field is the primary indication of the existence of a section.
						if (tripletsCount > 0) {

							// If the number of triplets changes, then we're dealing with a change to the
							// SMF98 record type and that would need to be re-coded
							if (tripletsCount == 17) {
								int tripletsLength = m_stream.getInteger(4);

								if (DEBUG)
									System.out.println("SMFType98SubType1 triplets: " + tripletsCount);

								Triplet Env = new Triplet(m_stream, 4, 2, 2);
								Triplet SIGPGRP = new Triplet(m_stream, 4, 2, 2);
								Triplet SIGP = new Triplet(m_stream, 4, 2, 2);
								Triplet OTH = new Triplet(m_stream, 4, 2, 2);
								Triplet TX = new Triplet(m_stream, 4, 2, 2);
								Triplet ECCC = new Triplet(m_stream, 4, 2, 2);
								Triplet MISC = new Triplet(m_stream, 4, 2, 2);
								Triplet UT = new Triplet(m_stream, 4, 2, 2);
								Triplet LockSpinSum = new Triplet(m_stream, 4, 2, 2);
								Triplet LockSpinDet = new Triplet(m_stream, 4, 2, 2);
								Triplet LockSuspendSum = new Triplet(m_stream, 4, 2, 2);
								Triplet LockSuspendDet = new Triplet(m_stream, 4, 2, 2);
								Triplet LockLocalCMLDet = new Triplet(m_stream, 4, 2, 2);
								Triplet PriorityBucket = new Triplet(m_stream, 4, 2, 2);
								Triplet Consume = new Triplet(m_stream, 4, 2, 2);
								Triplet LockSuspendMaxDet = new Triplet(m_stream, 4, 2, 2);
								Triplet LockSuspendMaxSum = new Triplet(m_stream, 4, 2, 2);

								// Read utilization:
								// https://www.ibm.com/docs/en/zos/3.1.0?topic=supervisor-utilization-section
								if (UT.count() == 0) {
									// ignore
								} else if (UT.count() == 1) {
									seek(UT);
									int SMF98_1_UT_CPUs_Unparked_CP = m_stream.getInteger(4);
									int SMF98_1_UT_CPUs_Unparked_zAAP = m_stream.getInteger(4);
									int SMF98_1_UT_CPUs_Unparked_zIIP = m_stream.getInteger(4);
									int SMF98_1_UT_Avg_Num_UnparkedVLs_CP = m_stream.getInteger(4);
									int SMF98_1_UT_Avg_Num_UnparkedVLs_zAAP = m_stream.getInteger(4);
									int SMF98_1_UT_Avg_Num_UnparkedVLs_zIIP = m_stream.getInteger(4);
									m_SMF98_1_UT_Avg_CpuBusy_CP = m_stream.getInteger(4);
									m_SMF98_1_UT_Avg_CpuBusy_zAAP = m_stream.getInteger(4);
									m_SMF98_1_UT_Avg_CpuBusy_zIIP = m_stream.getInteger(4);
								} else {
									if (ERRORS)
										System.err.println("ERROR: Unexpected count for utilization triplet: " + UT);
								}

								if (Consume.count() > 0) {
									seek(Consume);
									
									List<AddressSpaceConsumption> interestingASCs = new ArrayList<>();
									for (int k = 0; k < Consume.count(); k++) {

										// https://www.ibm.com/docs/en/zos/3.1.0?topic=supervisor-address-space-consumption-section
										AddressSpaceConsumption asc = new AddressSpaceConsumption();

										asc.SMF98_1_Consume_ProcClass = m_stream.getInteger(2);
										asc.SMF98_1_Consume_PriorityBucket = m_stream.getInteger(2);
										asc.SMF98_1_Consume_SubBucket = m_stream.getInteger(2);
										
										m_stream.skip(2);
										
										// https://www.ibm.com/docs/en/zos/3.1.0?topic=supervisor-execution-efficiency-sections
										asc.SMF98_1_Consume_ExEff = new Triplet(m_stream, 4, 2, 2);
										
										// https://www.ibm.com/docs/en/zos/3.1.0?topic=supervisor-work-unit-sections
										asc.SMF98_1_Consume_WorkUnit = new Triplet(m_stream, 4, 2, 2);
										
										// https://www.ibm.com/docs/en/zos/3.1.0?topic=supervisor-address-space-spin-lock-sections
										asc.SMF98_1_Consume_SpinLock = new Triplet(m_stream, 4, 2, 2);
										
										// Only interested in certain stats
										if (asc.SMF98_1_Consume_PriorityBucket == -1 && asc.SMF98_1_Consume_SubBucket == -1) {
											interestingASCs.add(asc);
										}
									}
									
									for (AddressSpaceConsumption asc : interestingASCs) {
										if (DEBUG)
											System.out.println("SMFType98SubType1 interesting ASC work unit = " + asc.SMF98_1_Consume_WorkUnit);

										seek(asc.SMF98_1_Consume_WorkUnit);
										for (int l = 0; l < asc.SMF98_1_Consume_WorkUnit.count(); l++) {
											// https://www.ibm.com/docs/en/zos/3.1.0?topic=supervisor-work-unit-sections
											int SMF98_1_WorkUnit_Type = m_stream.getInteger(2);
											
											m_stream.skip(2);
											m_stream.skip(2);
											m_stream.skip(2);
											m_stream.skip(24);
											
											{
												// https://www.ibm.com/docs/en/zos/3.1.0?topic=supervisor-address-space-information-section#smf98-1-asinfo
												int SMF98_1_AsidInfo_ASID = m_stream.getInteger(2);
												int SMF98_1_AsidInfo_DP = m_stream.getInteger(1);
												int SMF98_1_AsidInfo_Flags = m_stream.getInteger(1);
												int SMF98_1_AsidInfo_Seqnum = m_stream.getInteger(4);
												String SMF98_1_AsidInfo_JobName = m_stream.getString(8, SmfUtil.EBCDIC);
	
												long SMF98_1_AsidInfo_CP_AllTaskSRB_TimeTOD = m_stream.getLong(8);
												long SMF98_1_AsidInfo_zIIP_AllTaskSRB_TimeTOD = m_stream.getLong(8);
												int SMF98_1_AsidInfo_CP_All_TD1EQ_CPI = m_stream.getInteger(4);
												int SMF98_1_AsidInfo_zIIP_All_TD1EQ_CPI = m_stream.getInteger(4);
												m_stream.skip(16);
												
												// Only interested in certain stats
												if (SMF98_1_WorkUnit_Type == 1) {
													if (DEBUG)
														System.out.println("SMFType98SubType1 SMF98_1_AsidInfo_JobName = " + SMF98_1_AsidInfo_JobName);
													
													if (asc.SMF98_1_Consume_ProcClass == 0) {
														m_AddressSpaceMostCPUTime_CP = SMF98_1_AsidInfo_JobName;
													} else if (asc.SMF98_1_Consume_ProcClass == 2) {
														m_AddressSpaceMostCPUTime_zAAP = SMF98_1_AsidInfo_JobName;
													} else if (asc.SMF98_1_Consume_ProcClass == 4) {
														m_AddressSpaceMostCPUTime_zIIP = SMF98_1_AsidInfo_JobName;
													}
												}
											}
											
											m_stream.skip(24);
										}
									}
								}

							} else {
								if (ERRORS)
									System.err.println("ERROR: Unexpected SMF98 triplet count: " + tripletsCount);
							}
						}
					}
				}
			} else {
				if (WARNINGS)
					System.err.println("WARNING: Skipping 98." + m_subtype);
			}
		} else {
			if (WARNINGS)
				System.err.println("WARNING: Triplet count unexpected: " + SMF98SDSTripletsNum);
		}
	}
	
	class AddressSpaceConsumption {
		int SMF98_1_Consume_ProcClass, SMF98_1_Consume_PriorityBucket, SMF98_1_Consume_SubBucket;
		Triplet SMF98_1_Consume_ExEff, SMF98_1_Consume_WorkUnit, SMF98_1_Consume_SpinLock;
	}
}
