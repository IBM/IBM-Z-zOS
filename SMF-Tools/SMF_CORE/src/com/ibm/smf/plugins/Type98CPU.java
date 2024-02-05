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
package com.ibm.smf.plugins;

import com.ibm.smf.format.DefaultFilter;
import com.ibm.smf.format.SMFFilter;
import com.ibm.smf.format.SmfPrintStream;
import com.ibm.smf.format.SmfRecord;
import com.ibm.smf.format.types.SMFType98SubType1;
import com.ibm.smf.utilities.ConversionUtilities;

public class Type98CPU implements SMFFilter {

	private SmfPrintStream smf_printstream = null;

	@Override
	public boolean initialize(String parms) {
		smf_printstream = DefaultFilter.commonInitialize(parms);
		smf_printstream.println(
				"DateTime,LPAR,AvgCpuBusyCP,AvgCpuBusyzAAP,Avg_CpuBusy_zIIP,AddressSpaceMostCPU_CP,AddressSpaceMostCPU_zAAP,AddressSpaceMostCPU_zIIP");
		return true;
	}

	@Override
	public boolean preParse(SmfRecord record) {
		return record.type() == 98 && record.subtype() == 1;
	}

	@Override
	public SmfRecord parse(SmfRecord record) {
		return DefaultFilter.commonParse(record);
	}

	@Override
	public void processRecord(SmfRecord record) {
		if (record instanceof SMFType98SubType1) {
			SMFType98SubType1 record98 = (SMFType98SubType1) record;
			smf_printstream.println(String.format("%1$s,%2$s,%3$d,%4$d,%5$d,%6$s,%7$s,%8$s",
					ConversionUtilities.toString(record98.m_date), record98.m_sid, record98.m_SMF98_1_UT_Avg_CpuBusy_CP,
					record98.m_SMF98_1_UT_Avg_CpuBusy_zAAP, record98.m_SMF98_1_UT_Avg_CpuBusy_zIIP,
					ConversionUtilities.escapeCSV(record98.m_AddressSpaceMostCPUTime_CP),
					ConversionUtilities.escapeCSV(record98.m_AddressSpaceMostCPUTime_zAAP),
					ConversionUtilities.escapeCSV(record98.m_AddressSpaceMostCPUTime_zIIP)));
		}
	}

	@Override
	public void processingComplete() {
	}
}
