/*                                                                   */
/* Copyright 2025 IBM Corp.                                          */
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
import com.ibm.smf.format.types.SMFType120SubType11UserDataType104;
import com.ibm.smf.liberty.request.LibertyRequestInfoSection;
import com.ibm.smf.liberty.request.LibertyRequestRecord;
import com.ibm.smf.liberty.request.LibertyServerInfoSection;
import com.ibm.smf.was.common.WASConstants;
import com.ibm.smf.utilities.ConversionUtilities;

/**
 * Format the z/OS Connect API requester User Data fields
 */
public class ZCAPIRequester extends ZCAPI implements SMFFilter {
   
    private SmfPrintStream smf_printstream = null;
    private boolean header_written = false;

    public static final int ZC_API_REQUESTER_USER_DATA_TYPE = 104;

    public boolean initialize(String parms) {
        smf_printstream = DefaultFilter.commonInitialize(parms);
        return smf_printstream != null;
    }

    public SmfRecord parse(SmfRecord record) {
        return DefaultFilter.commonParse(record);
    }

    public boolean preParse(SmfRecord record) {
        return record.type() == WASConstants.SmfRecordType &&
               record.subtype() == WASConstants.LibertyRequestActivitySmfRecordSubtype;
    }

    public void processRecord(SmfRecord record) {
        LibertyRequestRecord rec = (LibertyRequestRecord) record;
        StringBuilder sbData = new StringBuilder();
        StringBuilder sbHeader = new StringBuilder();

        // Only continue if the record is valid
        if(!recordIsValid(rec, ZC_API_REQUESTER_USER_DATA_TYPE)){
            return;
        }

        // Add Server information
        LibertyServerInfoSection serverInfo = rec.m_libertyServerInfoSection;
        appendServerInfo(serverInfo, sbData, sbHeader);

        // Add Request information
        LibertyRequestInfoSection req = rec.m_libertyRequestInfoSection;
        long startTimeUs = new BigInteger(ConversionUtilities.longByteArrayToHexString(req.m_startStck), 16).shiftRight(12).longValue();
        long endTimeUs = new BigInteger(ConversionUtilities.longByteArrayToHexString(req.m_endStck), 16).shiftRight(12).longValue();
        appendTimeAndCPUInfo(req, startTimeUs, endTimeUs, sbData, sbHeader);
        
        // Format the User Data information
        SMFType120SubType11UserDataType104 sec = (SMFType120SubType11UserDataType104) rec.m_userDataSection[0];
        sbData.append(",").append(sec.m_version);
        sbHeader.append(",SMF120UD104_VERSION");

        byte[] todFormat = new byte[8];
        System.arraycopy(sec.m_stubSentTime, 1, todFormat, 0, 8);
        long ssTimeUs = new BigInteger(ConversionUtilities.longByteArrayToHexString(todFormat), 16).shiftRight(12).longValue();
        sbData.append(",").append(formatStck(todFormat));
        sbHeader.append(",SMF120UD104_TIME_STUB_SENT");
        
        sbData.append(",").append(startTimeUs - ssTimeUs);
        sbHeader.append(",SM120BBW-SMF120UD104_TIME_STUB_SENT");

        System.arraycopy(sec.m_zcEntryTime, 1, todFormat, 0, 8);
        long zcEntryTimeUs = new BigInteger(ConversionUtilities.longByteArrayToHexString(todFormat), 16).shiftRight(12).longValue();
        sbData.append(",").append(formatStck(todFormat));
        sbHeader.append(",SMF120UD104_TIME_ZC_ENTRY");
        
        System.arraycopy(sec.m_zcExitTime, 1, todFormat, 0, 8);
        long zcExitTimeUs = new BigInteger(ConversionUtilities.longByteArrayToHexString(todFormat), 16).shiftRight(12).longValue();
        sbData.append(",").append(formatStck(todFormat));
        sbHeader.append(",SMF120UD104_TIME_ZC_EXIT");
        
        sbData.append(",").append(zcEntryTimeUs - startTimeUs);
        sbHeader.append(",SMF120UD104_TIME_ZC_ENTRY-SM120BBW");

        sbData.append(",").append(zcExitTimeUs == 0 ? 0 : endTimeUs - zcExitTimeUs);
        sbHeader.append(",SM120BBX-SMF120UD104_TIME_ZC_EXIT");

        sbData.append(",").append(sec.m_requestID);
        sbHeader.append(",SMF120UD104_REQ_ID");

        sbData.append(",").append(bytesToHex(sec.m_trackingToken));
        sbHeader.append(",SMF120UD104_TRACKING_TOKEN");

        if (!header_written) {
            smf_printstream.println(sbHeader.toString());
            header_written = true;
        }

        smf_printstream.println(sbData.toString());
    }

    public void processingComplete() {}
}