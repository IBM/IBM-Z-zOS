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
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.Date;

import com.ibm.smf.format.Triplet;
import com.ibm.smf.liberty.request.LibertyRequestInfoSection;
import com.ibm.smf.liberty.request.LibertyRequestRecord;
import com.ibm.smf.liberty.request.LibertyServerInfoSection;
import com.ibm.smf.utilities.ConversionUtilities;
import com.ibm.smf.utilities.STCK;

/**
 * Parent class for classes formatting z/OS Connect User Data
 */
public class ZCAPI {

    final protected static char[] hexArray = {'0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F'};

    /**
     * Take a byte array representing a TOD and format it into a 
     * prinatble string UTC representation
     */
    public static String formatStck(byte[] todFormat) {
        if (isAllZeros(todFormat)) {
            return "0000/00/00 00:00:00.000000 UTC";
        }
        Date myDate = STCK.toDate(ConversionUtilities.longByteArrayToHexString(todFormat));
        BigInteger stck = new BigInteger(ConversionUtilities.longByteArrayToHexString(todFormat), 16);
        BigInteger micsSTCK = stck.divide(new BigInteger("4096"));
        BigInteger mics = micsSTCK.mod(new BigInteger("1000000"));
        DateFormat df = new SimpleDateFormat("yyyy/MM/dd HH:mm:ss");
        String dateToPrint = df.format(myDate);
        return dateToPrint + "." + String.format("%06d", mics) + " UTC";
    }

    /**
     * Visually represent a byte array as hex values
     */
    public static String bytesToHex(byte[] bytes) {
        StringBuilder toReturn = new StringBuilder();
        int v;
        for (int j = 0; j < bytes.length; j++) {
            if (j != 0 && j % 4 == 0) {
                toReturn.append(" ");
            }
            v = bytes[j] & 0xFF;
            toReturn.append(hexArray[v >>> 4]);
            toReturn.append(hexArray[v & 0x0F]);
        }
        return toReturn.toString();
    }

    /**
     * Check if it's OK to continue processing this record
     */
    public static boolean recordIsValid(LibertyRequestRecord record, int userDataYpe) {
        // Check if this record has Request Data
        Triplet requestDataTriplet = record.m_requestDataTriplet;
        if (requestDataTriplet.count() == 0){
            return false;
        }

        // Check if this record has User Data and whether it's the right type
        Triplet userDataTriplet = record.m_userDataTriplet;
        if (userDataTriplet.count() == 0 ||
            record.m_userDataSection[0].m_dataType != userDataYpe) {
            return false;
        }

        return true;
    }

    /**
     * Check whether a byte array is all NULL/0x00s
     */
    private static boolean isAllZeros(byte[] byteArray) {
        if (byteArray == null || byteArray.length == 0) {
            return false;
        }
        for (byte b : byteArray) {
            if (b != 0) {
                return false;
            }
        }
        return true;
    }

    /**
     * Add the common server information to the string buffers
     */
    public static void appendServerInfo(LibertyServerInfoSection serverInfo, StringBuilder data, StringBuilder header) {
        data.append(serverInfo.m_systemName).append(",")
          .append(serverInfo.m_sysplexName).append(",")
          .append(serverInfo.m_jobId).append(",")
          .append(serverInfo.m_jobName);
        header.append("SM120BAM,SM120BAN,SM120BAO,SM120BAP");
    }

    /**
     * Add the Time and CPU server information to the string buffers
     * 
     * Division of TOD values by 4096 gives the time in microseconds
     */
    public static void appendTimeAndCPUInfo(LibertyRequestInfoSection req, long startTimeUs, long endTimeUs, StringBuilder data, StringBuilder header) {
        
        // Common fields and time data
        data.append(",").append(new BigInteger(ConversionUtilities.longByteArrayToHexString(req.m_systemGmtOffset), 16).toString())
            .append(",").append(formatStck(req.m_startStck))
            .append(",").append(formatStck(req.m_endStck))
            .append(",").append(endTimeUs - startTimeUs)
            .append(",").append(req.m_wlmTransactionClass);

        header.append(",SM120BBT,SM120BBW,SM120BBX,SM120BBX-SM120BBW,SM120BBY");

        // Calculate CPU consumed
        long totalCPU = (req.m_totalCPUEnd - req.m_totalCPUStart) / 4096;
        long totalGP = (req.m_CPEnd - req.m_CPStart) / 4096;
        long totalOffload = totalCPU - totalGP;

        // Add CPU data and calculations
        data.append(",").append(req.m_totalCPUStart / 4096)
            .append(",").append(req.m_totalCPUEnd / 4096)
            .append(",").append(req.m_CPStart / 4096)
            .append(",").append(req.m_CPEnd / 4096)
            .append(",").append(totalCPU)
            .append(",").append(totalGP)
            .append(",").append(totalOffload)
            .append(",").append(req.m_enclaveDeleteCPU / 4096)
            .append(",").append(req.m_enclaveDeletezIIPCPU / 4096);

        header.append(",SM120BBZ(H),SM120BCA(H),SM120BBZ(L),SM120BCA(L)")
              .append(",TotalCPU=SM120BCA(H)-SM120BBZ(H),TotalGP=SM120BCA(L)-SM120BBZ(L),TotalzIIP=(SM120BCA(H)-SM120BBZ(H))-(SM120BCA(L)-SM120BBZ(L))")
              .append(",SM120BCB,SM120BCF");
    }
}