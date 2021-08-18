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

  package com.ibm.smf.twas.request;

  import java.io.*;

import com.ibm.smf.format.SmfEntity;
import com.ibm.smf.format.SmfPrintStream;
import com.ibm.smf.format.SmfStream;
import com.ibm.smf.format.SmfUtil;
import com.ibm.smf.format.UnsupportedVersionException;
  
  //import java.nio.ByteBuffer;             //@SU99

//  ------------------------------------------------------------------------------
  /** Data container for SMF data related to a Smf record product section. */
  public class ZosRequestInfoSection extends SmfEntity {
     
    /** Supported version of this class. */
	  public final static int s_supportedVersion = 1;  
    
    /** version of section. */
    public int m_version;
    /** timestamp when request was received in the server */
    public byte m_received[];
    /** timestamp when request was placed on the queue for a servant to pick up */
    public byte m_queued[];
    /** timestamp when request was dispatched in a servant */
    public byte m_dispatched[];
    /** timestamp when dispatch in a servant completed */
    public byte m_dispatchcomplete[];
    /** timestamp when controller processing for the request completed (e.g. response sent) */
    public byte m_complete[];
    /** jobname of the servant where the request was dispatched */    
    public String m_dispatchServantJobname;
    /** jobid of the servant where the request was dispatched */
    public String m_dispatchServantJobId;
    /** STOKEN of the servant where the request was dispatched */
    public byte m_dispatchServantStoken[];
    /** ASID of the servant where the request was dispatched */
    public byte m_dispatchServantAsid[];
    /** reserved */
    public byte m_reservedAlignment1[];
    /** TCB address where the request was dispatched */
    public byte m_dispatchServantTcbAddress[];
    /** TTOKEN of the TCB where the request was dispatched */
    public byte m_dispatchServantTtoken[];
    /** CPU time on non-standard processors (e.g. zAAP/zIIP) */
    public long m_dispatchServantCpuOffload;
    /** Enclave token for the request */
    public byte m_dispatchServantEnclaveToken[];
    /** CPU time for the enclave */
    public long m_dispatchServantEnclaveCpu;
    /** zAAP CPU time for the enclave */
    public long m_dispatchServantZaapCpu;
    /** zAAP eligible time for the enclave which ran on regular GPs */
    public long m_dispatchServantzAAPEligibleonCP;
    /** reserved */
    public byte m_reservedAlignment2[];
    /** zIIP eligible time for the enclave which ran on regular GPs */
    public long m_dispatchServantzIIPonCPUsofar;
    /** zIIP qualified time */
    public long m_dispatchServantzIIPQualTimeSoFar;
    /** zIIP CPU time for the enclave */    
    public long m_dispatchServantzIIPCPUSoFar;
    /** WLM zAAP normalization factor */
    public int m_dispatchServantzAAPNormalizationFactor;
    /** CPU time for the enclave at enclave delete */
    public long m_EnclaveDeleteCPU;
    /** zAAP CPU time for the enclave at enclave delete */
    public long m_EnclaveDeletezAAPCPU;
    /** WLM zAAP normalization factor */
    public int m_EnclaveDeletezAAPNorm;
    /** reserved */
    public byte m_reservedAlignment3[];
    /** zIIP CPU time normalized */
    public long m_EnclaveDeletezIIPCPUNormalized;
    /** zIIP CPU usage in service units */
    public long m_EnclaveDeletezIIPService;
    /** zAAP CPU usage in service units */
    public long m_EnclaveDeletezAAPService;
    /** CPU usage in service units */
    public long m_EnclaveDeleteCpuService;
    /** WLM enclave response time ration */
    public int m_EnclaveDeleteRespTimeRatio;
    /** reserved */
    public byte m_reservedAlignment4[];
    /** global transaction id */
    public byte m_gtid[];
    /** reserved */
    public byte m_reservedAlignment5[];
    /** dispatch timeout value used */
    public int m_dispatchTimeout;
    /** WLM transaction class used for classification */
    public String m_tranClass;
    /** flags */
    public byte m_flags[];    

    //static int m_flags_create_enclave_mask               = 0x40000000;
    //static int m_flags_timeout_odr                       = 0x20000000;
    //static int m_flags_tran_class_odr_mask               = 0x10000000;
    //static int m_flags_one_way_mask                      = 0x8000000;
    //static int m_flags_cpu_usage_overflow_mask           = 0x4000000;
    //static int m_flags_request_queued_with_affinity_mask = 0x2000000;
    //static int m_flags_CEEGMTO_not_available             = 0x1000000;
    //static int m_flags_reserved                          = 0x3FFFFFF; //26 bits remaining

    /** Stalled Thread dump action */
    public int m_stalled_thread_dump_action; //@v8A
    /** CPU Time Used Dump Action */
    public int m_cputimeused_dump_action;    //@v8A
    /** DPM Dump Action */
    public int m_dpm_dump_action;            //@v8A  
    /** Timeout Recovery */        
    public int m_timeout_recovery;           //@v8A
    /** dispatch timeout */
    public int m_dispatch_timeout;           //@v8A
    /** Queue Timeout Percent */
    public int m_queue_timeout;      //@v8A
    /** Request Timeout */
    public int m_request_timeout;            //@v8A
    /** CPU Time Used Limit */
    public int m_cputimeused_limit;          //@v8A
    /** DPM Interval */
    public int m_dpm_interval;               //@v8A 
    /** Message Tag */
    public String m_message_tag;             //@v8A
    /** Obtained Affinity length */
    public int m_obtainedAffinityLength;     //@v8A
    /** Obtained Affinity length */
    public byte m_obtainedAffinity[];        //@v8A
    /** Routing Affinity length */
    public int m_routingAffinityLength;      //@v8A
    /** Routing Affinity length */
    public byte m_routingAffinity[];         //@v8A

    
    /** reserved */
    public byte m_reserved[];
    
    //----------------------------------------------------------------------------
    /** ZosRequestInfoSection constructor from a SmfStream.
     * @param aSmfStream SmfStream to be used to build this ZosRequestInfoSection.
     * The requested version is currently set in the Platform Neutral Section
     * @throws UnsupportedVersionException Exception to be thrown when version is not supported
     * @throws UnsupportedEncodingException Exception thrown when an unsupported encoding is detected.
     */
    public ZosRequestInfoSection(SmfStream aSmfStream) 
    throws UnsupportedVersionException, UnsupportedEncodingException {
      
      super(s_supportedVersion);
      m_version = aSmfStream.getInteger(4);
      
      m_received = aSmfStream.getByteBuffer(16);
      m_queued = aSmfStream.getByteBuffer(16);
      m_dispatched = aSmfStream.getByteBuffer(16);
      m_dispatchcomplete = aSmfStream.getByteBuffer(16);
      m_complete = aSmfStream.getByteBuffer(16);
      
      m_dispatchServantJobname = aSmfStream.getString(8,SmfUtil.EBCDIC);
      m_dispatchServantJobId = aSmfStream.getString(8,SmfUtil.EBCDIC);
      m_dispatchServantStoken = aSmfStream.getByteBuffer(8);
      m_dispatchServantAsid = aSmfStream.getByteBuffer(2);
      m_reservedAlignment1 = aSmfStream.getByteBuffer(2);
      m_dispatchServantTcbAddress = aSmfStream.getByteBuffer(4);
      m_dispatchServantTtoken = aSmfStream.getByteBuffer(16);
      m_dispatchServantCpuOffload = aSmfStream.getLong();
      m_dispatchServantEnclaveToken = aSmfStream.getByteBuffer(8);      
      m_reservedAlignment2 = aSmfStream.getByteBuffer(32);
      
      m_dispatchServantEnclaveCpu = aSmfStream.getLong();
      m_dispatchServantZaapCpu = aSmfStream.getLong();
      m_dispatchServantzAAPEligibleonCP = aSmfStream.getLong();
      m_dispatchServantzIIPonCPUsofar = aSmfStream.getLong();
      m_dispatchServantzIIPQualTimeSoFar =  aSmfStream.getLong();
      m_dispatchServantzIIPCPUSoFar =  aSmfStream.getLong();
      m_dispatchServantzAAPNormalizationFactor = aSmfStream.getInteger(4);
      m_EnclaveDeleteCPU = aSmfStream.getLong();
      m_EnclaveDeletezAAPCPU = aSmfStream.getLong();
      m_EnclaveDeletezAAPNorm = aSmfStream.getInteger(4);
      m_reservedAlignment3 = aSmfStream.getByteBuffer(4);
      m_EnclaveDeletezIIPCPUNormalized = aSmfStream.getLong();
      m_EnclaveDeletezIIPService = aSmfStream.getLong();
      m_EnclaveDeletezAAPService = aSmfStream.getLong();
      m_EnclaveDeleteCpuService = aSmfStream.getLong();
      m_EnclaveDeleteRespTimeRatio = aSmfStream.getInteger(4);
      m_reservedAlignment4 = aSmfStream.getByteBuffer(12);
      
      m_gtid = aSmfStream.getByteBuffer(73);
      m_reservedAlignment5 = aSmfStream.getByteBuffer(3);
      
      m_dispatchTimeout = aSmfStream.getInteger(4);
      m_tranClass = aSmfStream.getString(8,SmfUtil.EBCDIC);
      m_flags = aSmfStream.getByteBuffer(4);
      //If breaking out individual flags, will just mask m_flags in dump method
      
      m_reserved = aSmfStream.getByteBuffer(32);     
      if (m_version >= 2)                                       //13@v8A    
      {
        m_stalled_thread_dump_action = aSmfStream.getInteger(4); 
        m_cputimeused_dump_action = aSmfStream.getInteger(4);                
        m_dpm_dump_action = aSmfStream.getInteger(4);     
        m_timeout_recovery = aSmfStream.getInteger(4);     
        m_dispatch_timeout = aSmfStream.getInteger(4);     
        m_queue_timeout = aSmfStream.getInteger(4);     
        m_request_timeout = aSmfStream.getInteger(4);     
        m_cputimeused_limit = aSmfStream.getInteger(4);     
        m_dpm_interval = aSmfStream.getInteger(4);     
        m_message_tag = aSmfStream.getString(8,SmfUtil.EBCDIC);         
        m_obtainedAffinityLength = aSmfStream.getInteger(4);
        // Changed the affinity tokens from Strings to byte-arrays since they aren't really printable (just a hex value)
        m_obtainedAffinity       = aSmfStream.getByteBuffer(128);
        m_routingAffinityLength = aSmfStream.getInteger(4);
        m_routingAffinity       = aSmfStream.getByteBuffer(128);
      }
    } // ZosRequestInfoSection(..)
    
    //----------------------------------------------------------------------------
    /** Returns the supported version of this class.
     * @return supported version of this class.
     */
    public int supportedVersion() {
      
      return s_supportedVersion;
      
    } // supportedVersion()

 
    //----------------------------------------------------------------------------
    /** Dumps the fields of this object to a print stream.
     * @param aPrintStream The stream to print to.
     * @param aTripletNumber The triplet number of this ZosRequestInfoSection.
     */
    public void dump(SmfPrintStream aPrintStream, int aTripletNumber) {
         
      aPrintStream.println("");
      aPrintStream.printKeyValue("Triplet #",aTripletNumber);
      aPrintStream.printlnKeyValue("Type","ZosRequestInfoSection");

      aPrintStream.push();
      
      aPrintStream.printlnKeyValue("Server Info Version            ", m_version);
      
      aPrintStream.printlnKeyValue("Time Received                  ",m_received,null);
      aPrintStream.printlnKeyValue("Time Queued                    ",m_queued,null);
      aPrintStream.printlnKeyValue("Time Dispatched                ",m_dispatched,null);
      aPrintStream.printlnKeyValue("Time Dispatch Complete         ",m_dispatchcomplete,null);
      aPrintStream.printlnKeyValue("Time Complete                  ",m_complete,null);
      
      aPrintStream.printlnKeyValue("Servant Job Name               ",m_dispatchServantJobname);
      aPrintStream.printlnKeyValue("Servant Job ID                 ",m_dispatchServantJobId);
      aPrintStream.printlnKeyValue("Servant SToken                 ",m_dispatchServantStoken,null);
      aPrintStream.printlnKeyValue("Servant ASID (HEX)             ",m_dispatchServantAsid,null);
      aPrintStream.printlnKeyValue("Reserved for alignment         ",m_reservedAlignment1,null);
      aPrintStream.printlnKeyValue("Servant Tcb Address            ",m_dispatchServantTcbAddress,null);
      aPrintStream.printlnKeyValue("Servant TToken                 ",m_dispatchServantTtoken,null);
      aPrintStream.printlnKeyValue("CPU Offload                    ",m_dispatchServantCpuOffload);
      aPrintStream.printlnKeyValue("Servant Enclave Token          ",m_dispatchServantEnclaveToken,null);
      aPrintStream.printlnKeyValue("Reserved                       ",m_reservedAlignment2,null);
      
      aPrintStream.printlnKeyValue("Enclave CPU So Far             ",m_dispatchServantEnclaveCpu);
      aPrintStream.printlnKeyValue("zAAP CPU So Far                ",m_dispatchServantZaapCpu);          //@SU99
      aPrintStream.printlnKeyValue("zAAP Eligible on CP            ",m_dispatchServantzAAPEligibleonCP); //@SU99
      aPrintStream.printlnKeyValue("zIIP on CPU So Far             ",m_dispatchServantzIIPonCPUsofar);
      aPrintStream.printlnKeyValue("zIIP Qual Time So Far          ",m_dispatchServantzIIPQualTimeSoFar);
      aPrintStream.printlnKeyValue("zIIP CPU So Far                ",m_dispatchServantzIIPCPUSoFar);
      aPrintStream.printlnKeyValue("zAAP Normalization Factor      ",m_dispatchServantzAAPNormalizationFactor);
      aPrintStream.printlnKeyValue("Enclave Delete CPU             ",m_EnclaveDeleteCPU);
      aPrintStream.printlnKeyValue("Enclave Delete zAAP CPU        ",m_EnclaveDeletezAAPCPU);
      aPrintStream.printlnKeyValue("Enclave Delete zAAP Norm       ",m_EnclaveDeletezAAPNorm);
      aPrintStream.printlnKeyValue("Reserved                       ",m_reservedAlignment3,null);
      aPrintStream.printlnKeyValue("Enclave Delete zIIP Norm       ",m_EnclaveDeletezIIPCPUNormalized);
      aPrintStream.printlnKeyValue("Enclave Delete zIIP Service    ",m_EnclaveDeletezIIPService);
      aPrintStream.printlnKeyValue("Enclave Delete zAAP Service    ",m_EnclaveDeletezAAPService);
      aPrintStream.printlnKeyValue("Enclave Delete CPU  Service    ",m_EnclaveDeleteCpuService);
      aPrintStream.printlnKeyValue("Enclave Delete Resp Time Ratio ",m_EnclaveDeleteRespTimeRatio);
      aPrintStream.printlnKeyValue("Reserved for alignment         ",m_reservedAlignment4,null);
      
      aPrintStream.printlnKeyValue("GTID                           ",m_gtid,null);
      aPrintStream.printlnKeyValue("Reserved for alignment         ",m_reservedAlignment5,null);
      
      aPrintStream.printlnKeyValue("Dispatch Timeout               ",m_dispatchTimeout);
      aPrintStream.printlnKeyValue("Transaction Class              ",m_tranClass);
      aPrintStream.printlnKeyValue("Flags                          ",m_flags,null);
      // Break out flags here?
      //aPrintStream.printlnKeyValue("- Created Enclave              ",(m_flags & m_flags_create_enclave_mask));
      //aPrintStream.printlnKeyValue("Timeout from ODR               ",(m_flags & m_flags_timeout_odr));
      //aPrintStream.printlnKeyValue("Tran Class from ODR            ",(m_flags & m_flags_tran_class_odr_mask));
      //aPrintStream.printlnKeyValue("One-way                        ",(m_flags & m_flags_one_way_mask));
      //aPrintStream.printlnKeyValue("CPU Usage Overflow             ",(m_flags & m_flags_cpu_usage_overflow_mask));
      //aPrintStream.printlnKeyValue("Request Queued w/Affinity      ",(m_flags & m_flags_request_queued_with_affinity_mask));
      //aPrintStream.printlnKeyValue("CEEGMTO not available          ",(m_flags & m_flags_CEEGMTO_not_available));
      //aPringStream.printlnKeyValue("Reserved                       ",(m_flags & m_flags_reserved));

      aPrintStream.printlnKeyValue("Reserved                       ",m_reserved,null);
      
      if (m_version >= 2)   // 14@v8A
      {
        aPrintStream.printlnKeyValue("Classification attributes","");
        aPrintStream.printlnKeyValue("Stalled thread dump action     ", m_stalled_thread_dump_action);
        aPrintStream.printlnKeyValue("CPU time used dump action      ", m_cputimeused_dump_action);
        aPrintStream.printlnKeyValue("DPM dump action                ", m_dpm_dump_action);
        aPrintStream.printlnKeyValue("Timeout recovery               ", m_timeout_recovery);
        aPrintStream.printlnKeyValue("Dispatch timeout               ", m_dispatch_timeout);
        aPrintStream.printlnKeyValue("Queue timeout                  ", m_queue_timeout);
        aPrintStream.printlnKeyValue("Request timeout                ", m_request_timeout);
        aPrintStream.printlnKeyValue("CPU time used limit            ", m_cputimeused_limit);
        aPrintStream.printlnKeyValue("DPM interval                   ", m_dpm_interval);
        aPrintStream.printlnKeyValue("Message Tag                    ", m_message_tag);
        aPrintStream.printlnKeyValue("Obtained affinity              ", m_obtainedAffinity,null);
        aPrintStream.printlnKeyValue("Routing affinity               ", m_routingAffinity,null);
      }
      
      
      aPrintStream.pop();
      
    
    } // dump()
    
  } // ZosRequestInfoSection
