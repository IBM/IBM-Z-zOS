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

package com.ibm.smf.liberty.batch;

import java.io.UnsupportedEncodingException;

import com.ibm.smf.format.SmfEntity;
import com.ibm.smf.format.SmfPrintStream;
import com.ibm.smf.format.SmfStream;
import com.ibm.smf.format.SmfUtil;
import com.ibm.smf.format.UnsupportedVersionException;

public class LibertyBatchReferenceNamesSection extends SmfEntity {

    /** Supported version of this class. */
    public final static int s_supportedVersion = 1;

    /** version of section. */
    public int m_version;

    /** type type of ref */
    public int m_refType;

    /** space used in buffer */
    public int m_refLength;

    /** name of the ref */
    public String m_refName;
    
    /** Reference types */
    public static final int READER_REF_TYPE = 1;
    public static final int PROCESSOR_REF_TYPE = 2;
    public static final int WRITER_REF_TYPE = 3;
    public static final int CHECKPOINT_REF_TYPE = 4;
    public static final int BATCHLET_REF_TYPE = 5;
    public static final int PARTITION_MAPPER_REF_TYPE = 6;
    public static final int PARTITION_REDUCER_REF_TYPE = 7;
    public static final int PARTITION_COLLECTOR_REF_TYPE = 8;
    public static final int PARTITION_ANALYZER_REF_TYPE = 9;
    public static final int DECIDER_REF_TYPE = 10;    

    public static final String[] typeString = {"","Reader","Processor","Writer","Checkpoint","Batchlet","PartitionMapper","PartitionReducer","PartitionCollector","PartitionAnalyzer","Decider"};

    //----------------------------------------------------------------------------
    /**
     * Returns the supported version of this class.
     *
     * @return supported version of this class.
     */
    @Override
    public int supportedVersion() {

        return s_supportedVersion;

    } // supportedVersion()

    public LibertyBatchReferenceNamesSection(SmfStream aSmfStream) throws UnsupportedVersionException, UnsupportedEncodingException {

        super(s_supportedVersion);
        m_version = aSmfStream.getInteger(4);
        m_refType = aSmfStream.getInteger(4);
        m_refLength = aSmfStream.getInteger(4);
        m_refName = aSmfStream.getString(128, SmfUtil.ASCII);

    }

    //----------------------------------------------------------------------------
    /**
     * Dumps the fields of this object to a print stream.
     *
     * @param aPrintStream The stream to print to.
     * @param aTripletNumber The triplet number of this LibertyRequestInfoSection.
     */
    public void dump(SmfPrintStream aPrintStream, int aTripletNumber) {

        aPrintStream.println("");
        aPrintStream.printKeyValue("Triplet #", aTripletNumber);
        aPrintStream.printlnKeyValue("Type", "LibertyBatchReferenceNamesSection");

        aPrintStream.push();

        aPrintStream.printlnKeyValue("References Name  Version              ", m_version);
        aPrintStream.printlnKeyValue("Reference type                        ", m_refType);
        if ((m_refType>=READER_REF_TYPE)&& (m_refType <=DECIDER_REF_TYPE)) {
        	aPrintStream.printlnKeyValue("                                      ",typeString[m_refType]);
        }        
        aPrintStream.printlnKeyValue("Reference length                      ", m_refLength);
        aPrintStream.printlnKeyValue("Reference Name                        ", m_refName);

        aPrintStream.pop();

    }
}