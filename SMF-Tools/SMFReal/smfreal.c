/*                                                                              
 *                                                                              
 * Name: smfreal.c                                                              
 *                                                                              
 * Descriptive name: SMF Real-Time service invocation sample.                   
 *                                                                              
 * Copyright 2017 IBM Corp.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
 * either express or implied. See the License for the specific
 * language governing permissions and limitations under the
 * License.
 *
 *                                                                              
 * Change Activity =                                                            
 *                                                                              
 *   $00=REAL-TIME,HQX7790,16108,PDNM:  Initial sample                          
 *                                                                              
 * Processor: IBM z/OS XL C                                                     
 *                                                                              
 * DISCLAIMER:                                                                  
 *                                                                              
 *   This sample program is provided for tutorial purposes only.  A             
 *   complete handling of error conditions has not been shown or                
 *   attempted, and this source has not been submitted to formal IBM            
 *   testing. This source is distributed on an 'as is' basis                    
 *   without any warranties either expressed or implied.                        
 *                                                                              
 * Notes:                                                                       
 *                                                                              
 *   The output of the program is simply sent to stdout.                        
 *   A single connect attempt is made.   If successful, an iteration            
 *   of get calls are executed, and information about the length and the        
 *   type of the record is printed.   Additional data for SMF type 30           
 *   records are printed, if type 30 records are retrieved.                     
 *   Then, a disconnect is performed.                                           
 *                                                                              
 * Requirements:                                                                
 *                                                                              
 *   The in-memory resource is hard coded and should be available.              
 *                                                                              
 *   The SMF record types to be collected by the IFAMGET calls can              
 *   be SMF type 30 records for output with more details.                       
 *                                                                              
 *   These must be collected by the resource that this application              
 *   connects to.  Adjust your SMFPRMxx member accordingly.  Ensure             
 *   the owner running this application has SAF access to that                  
 *   resource.                                                                  
 *                                                                              
 * Usage:                                                                       
 *                                                                              
 *   Modify the program for your environment.                                   
 *   Mappings are in smfreal.h and must be included.  The header                
 *   also contains the external function definitions for the                    
 *   SMF Real-Time callable services.                                           
 *                                                                              
 *   Compile and link the program. Ensure that the IFAMxxx                      
 *   CSSLIB stubs are either in the linklist or linked into your                
 *   application program.                                                       
 *                                                                              
 *   Execute the compiled program via the shell and review the                  
 *   output manually.                                                           
 *                                                                              
 *                                                                              
 */                                                                             
                                                                                
/* Includes */                                                                  
#include <stdio.h>                                                              
#include <string.h>                                                             
#include <stdint.h>                                                             
#include <stdlib.h>                                                             
#include <ctype.h>                                                              
#include <smfreal.h>
/* If using this sample from within MVS data sets instead
 * of USS files, you can use this form of include to
   pull in the header from a member of a data set.
   #include <//'EBPRYOR.SMFREAL.CSAMP(SMFREALH)'>
   */
                                                                                
/*                                                                              
 * SMF Record Area mapping (we reserve a full 32K area)                         
 */                                                                             
#pragma pack(1)                    /* 1-byte alignment rule       */            
typedef struct rec_area {                                                       
    uint16_t   SmfLen;             /* Record Length (of a record) */            
    uint16_t   SmfSeg;             /* Segment descriptor          */            
    uint8_t    SmfFlg;             /* System indicator            */            
    uint8_t    SmfRty;             /* Record Type                 */            
    char       SmfTme[4];          /* Time since midnight 1/100s                
                                      of a second since moved to                
                                      SMF buffer                  */            
    char       SmfDte[4];          /* Date record moved to the                  
                                        SMF buffer 0cyydddF       */            
    char       SmfSid[4];          /* System ID (EBCDIC)          */            
    char       SmfWid[4];          /* Work type indicator, STC,                 
                                        TSO,...                   */            
    uint16_t   SmfStp;             /* SMF 30 record subtype       */            
    char       Remainder[32744];   /* Remainder of our buffer area              
                                      but the total:  32768 bytes */            
} rec_area;                                                                     
#pragma pack(reset)                /* reset to prior alignment    */            
                                                                                
/*                                                                              
 * Parameter list area definitions for callable services                        
 */                                                                             
                                                                                
/* IFAMCON connection parmlist area structure */                                
typedef struct parmlist_connect {                                               
    void * cnpb_ptr;       /* Ptr to the Connect parm block          */         
    int * retcode_ptr;     /* Ptr to return code int                 */         
    int * rsncode_ptr;     /* Ptr to reason code int                 */         
} parmlist_connect;                                                             
                                                                                
/* IFAMGET get function parmlist area structure */                              
typedef struct parmlist_get {                                                   
    void * gtpb_ptr;     /* Ptr to the Connect parm block            */         
    int * retcode_ptr;   /* Ptr to return code int                   */         
    int * rsncode_ptr;   /* Ptr to reason code int                   */         
} parmlist_get;                                                                 
                                                                                
/* IFAMDSC disconnection parmlist area structure */                             
typedef struct parmlist_disconnect {                                            
    void * dspb_ptr;   /* Ptr to the Connect parm block              */         
    int * retcode_ptr; /* Ptr to return code int                     */         
    int * rsncode_ptr; /* Ptr to reason code int                     */         
} parmlist_disconnect;                                                          
                                                                                
/* local constants */                                                           
const char BLANK = ' ';                 /* Constant for a black char */         
static const int RETCODE_INITIAL = -1;  /* initial "primed" values   */         
static const int RSNCOD_INITIAL  = -1;  /* ..                        */         
                                                                                
static const int NUM_GETS  =  50;       /* Number records to obtain  */         
                                                                                
static const int LOCAL_SUCCESS_RC = 0;  /* local rc constant values  */         
static const int LOCAL_ERROR_RC   = 8;                                          
                                                                                
static const char MEM_BUFNAME[] = "IFASMF.INMEM"; /* in-memory                  
                                              resource buffer name to           
                                              connect to             */         
                                                                                
static const char SMF30TYPE = 30;     /* SMF 30 Type number          */         
                                                                                
/* local function prototypes */                                                 
int  initializeParmlists(void);                                                 
int  validateConnectToken(void);                                                
void promoteConnectionToken(void);                                              
void printParmlistRCs(void *, parmlist_type);                                   
void setBlockingMode(void);                                                     
void setNonBlockingMode(void);                                                  
                                                                                
/* Note:  external functions IFAMxxx are defined in smfreal.h  */               
                                                                                
/* Local macros */                                                              
#define mb_size(type, member) sizeof(((type *)0)->member) /* Used               
                                                to obtain size of               
                                                structure elements   */         
/* Global variables */                                                          
                                                                                
cnpb cnpb_test;                       /* Connection parm block       */         
int cn_retcode;                                                                 
int cn_rsncode;                                                                 
parmlist_connect pc;                  /* Connection parmlist         */         
                                                                                
gtpb gtpb_test;                       /* Connection parm block       */         
int gt_retcode;                                                                 
int gt_rsncode;                                                                 
parmlist_get pg;                      /* Get parmlist                */         
                                                                                
dspb dspb_test;                       /* Disconnection parm block    */         
int ds_retcode;                                                                 
int ds_rsncode;                                                                 
parmlist_disconnect pd;               /* Disconnect parmlist         */         
                                                                                
rec_area get_outbuffer;               /* 32K area buffer for IFAMGET */         
                                                                                
smf30 *smf30Rec;                      /* Used for smf30 mapping                 
                                         to the get_outbuffer        */         
                                                                                
smf30ID *smf30IDSec;                 /*  Also used for smf30 mapping            
                                         in the Identification                  
                                         section                     */         
                                                                                
/*                                                                              
 * main                                                                         
 *                                                                              
 * Invokes the SMF Real-Time callable services available in CSSLIB              
 * and prints out data areas needed to verify success.                          
 *                                                                              
 * Reference the IFARCINM macro for all reason and return codes from            
 * the SMF Real-Time services as they are not detailed here.                    
 *                                                                              
 * Parameters:                                                                  
 *  none                                                                        
 *                                                                              
 * Returns:                                                                     
 *  0 - success                                                                 
 *  8 - error                                                                   
 *                                                                              
 */                                                                             
int main() {                                                                    
                                                                                
    int init_rc                 = LOCAL_ERROR_RC;                               
    int validate_rc             = LOCAL_ERROR_RC;                               
                                                                                
    char *ptrID_Section         = 0; /* Used to map Type 30 ID                  
                                        section.  This is a char ptr            
                                        type to force 1-byte pointer            
                                        arithmetic operations        */         
                                                                                
    int iGets;                       /* A counter for # Get calls    */         
                                                                                
    printf("\n--------- SMFREAL start ---------\n\n");                          
                                                                                
    init_rc = initializeParmlists();                                            
    printf("Initialize RC=%d\n", init_rc);                                      
    printf("\n");                                                               
                                                                                
    if(init_rc == LOCAL_SUCCESS_RC) {     /* setup OK, good to go... */         
                                                                                
        printf("CONNECT attempt to %s begins now...\n",MEM_BUFNAME);            
                                                                                
        /*                                                                      
         * CONNECT:                                                             
         * Make a call to the IFAMCON service                                   
         */                                                                     
                                                                                
        IFAMCON(&cnpb_test, &cn_retcode, &cn_rsncode);                          
        printf("CONNECT attempt made.\n");                                      
        printParmlistRCs(&pc, CONNECT);                                         
        printf("\n");                                                           
                                                                                
        if(cn_retcode == LOCAL_SUCCESS_RC) {      /* good connection */         
            validate_rc = validateConnectToken();                               
            printf("Validating connect token, RC=%d\n",validate_rc);            
            printf("\n");                                                       
        }                                                                       
        if(validate_rc == LOCAL_SUCCESS_RC) {     /* Good token      */         
            promoteConnectionToken();                                           
        }                                                                       
                                                                                
        if(validate_rc == LOCAL_SUCCESS_RC) { /* if token is valid   */         
                                                                                
            /*                                                                  
             * GET:                                                             
             * Loop IFAMGET calls if we are connected.                          
             *                                                                  
             * In this example, we only tolerate RC=0 from each call,           
             * however a full application should take various                   
             * actions for RC/RSNs other than 0.                                
             */                                                                 
                                                                                
            for (iGets = 0; iGets < NUM_GETS; ++iGets) {                        
                                                                                
                printf("GET attempt begins now...\n");                          
                IFAMGET(&gtpb_test, &gt_retcode, &gt_rsncode);                  
                printf("GET attempt made.\n");                                  
                printParmlistRCs(&pg, GET);                                     
                                                                                
                /*                                                              
                 * Print out some basic info on a record                        
                 * when one is returned                                         
                 */                                                             
                                                                                
                if(gt_retcode == LOCAL_SUCCESS_RC) {                            
                                                                                
                    printf("Record(%d) was retrieved:\n",iGets);                
                    printf("  Record Length: %d, Record Type: %d\n",            
                            get_outbuffer.SmfLen, get_outbuffer.SmfRty);        
                                                                                
                    /*                                                          
                     * Determine the record type of what we received            
                     * and if it is an SMF type 30, print more detail.          
                     *                                                          
                     * When printing text fields, note that a length            
                     * should be provided, as these may not be null-            
                     * terminated areas.  In this example, an mb_size           
                     * macro is used for calculating structure member           
                     * lengths.                                                 
                     *                                                          
                     * Additional checking could also be added on               
                     * content using such functions as isprint() out            
                     * of ctype.h to ensure only printable chars                
                     * are there.                                               
                     *                                                          
                     */                                                         
                                                                                
                    if(get_outbuffer.SmfRty == SMF30TYPE) {                     
                                                                                
                        smf30Rec = (smf30 *)&get_outbuffer;                     
                                                                                
                        printf("\tSMF Type 30 Details follow...\n");            
                        printf("\tSystem ID: %.*s\n",                           
                                mb_size(smf30, Smf30Sid),                       
                                smf30Rec->Smf30Sid);                            
                                                                                
                        printf("\tWork Type: %.*s\n",                           
                                mb_size(smf30, Smf30Wid),                       
                                smf30Rec->Smf30Wid);                            
                                                                                
                        printf("\tSMF 30 Sub Type: %.*d\n",                     
                                mb_size(smf30, Smf30Stp),                       
                                smf30Rec->Smf30Stp);                            
                                                                                
                        if(smf30Rec->Smf30Ion >= 1) { /* if there is            
                                                         an ID                  
                                                         section     */         
                                                                                
                            /*                                                  
                             * Map the ID area with smf30ID structure           
                             * using a pointer to char to enforce               
                             * 1-byte pointer arithmetic, so the                
                             * Smf30Iof offset math works.                      
                             */                                                 
                                                                                
                            ptrID_Section = (char *)smf30Rec; /* From           
                                                    beginning of RDW */         
                                                                                
                            ptrID_Section += smf30Rec->Smf30Iof; /*             
                                                  Using the offset,             
                                                  adjust to start               
                                                  of smf30ID section */         
                                                                                
                            smf30IDSec = (smf30ID *)ptrID_Section; /*           
                                                  Assign to a ptr               
                                                  mapped to smf30ID             
                                                  type structure     */         
                                                                                
                                                                                
                            /*                                                  
                             * Now print ID detail from this section.           
                             * If these text fields aren't set, then            
                             * they should contain nulls, and thus              
                             * are interpreted as an empty null                 
                             * terminated string. They will simply be           
                             * blank on the output report.                      
                             */                                                 
                                                                                
                            printf("\tJob Name: %.*s\n",                        
                                    mb_size(smf30ID, Smf30Jbn),                 
                                    smf30IDSec->Smf30Jbn);                      
                                                                                
                            printf("\tProgram Name: %.*s\n",                    
                                     mb_size(smf30ID, Smf30Pgm),                
                                     smf30IDSec->Smf30Pgm);                     
                                                                                
                            printf("\tStep Name: %.*s\n",                       
                                     mb_size(smf30ID, Smf30Stm),                
                                     smf30IDSec->Smf30Stm);                     
                                                                                
                            printf("\tUser-defined ID field: %.*s\n",           
                                     mb_size(smf30ID, Smf30Uif),                
                                     smf30IDSec->Smf30Uif);                     
                                                                                
                            printf("\tJES JobID: %.*s\n",                       
                                     mb_size(smf30ID, Smf30Jnm),                
                                     smf30IDSec->Smf30Jnm);                     
                                                                                
                        }                                                       
                                                                                
                    }                                                           
                    printf("\n");                                               
                                                                                
                    /*                                                          
                     * Here, consider clearing the output buffer                
                     * for the next call if reusing.                            
                     *                                                          
                     * However, clearing will be less efficient than            
                     * ensuring the length of the last obtained SMF             
                     * record is respected, and old record fragments            
                     * beyond that are to be ignored and not                    
                     * accidently used.                                         
                     *                                                          
                     */                                                         
                }                                                               
            }                                                                   
        }                                                                       
                                                                                
        if(validate_rc == LOCAL_SUCCESS_RC) { /* If token is valid   */         
                                                                                
                                                                                
            /*                                                                  
             * DISCONNECT:                                                      
             * Make call to the IFAMDSC service                                 
             */                                                                 
                                                                                
            printf("DISCONNECT attempt begins now...\n");                       
            IFAMDSC(&dspb_test, &ds_retcode, &ds_rsncode);                      
            printf("DISCONNECT attempt made.\n");                               
            printParmlistRCs(&pd, DISCONNECT);                                  
        }                                                                       
                                                                                
                                                                                
    } else {                                                                    
        printf("Parmlist initialization/setup error, quitting test.\n");        
    }                                                                           
                                                                                
    printf("\n\n--------- SMFREAL end -----------\n");                          
                                                                                
    return(init_rc);                                                            
}                                                                               
                                                                                
/*                                                                              
 * printParmlistRCs                                                             
 *                                                                              
 * Simple convenience method to print return codes for each parameter           
 * list.  The values are printed in hexadecimal.  See the IFARCINM              
 * macro for reason and return code values.                                     
 *                                                                              
 * This function may be improved by adding code to optionally print             
 * the parameter block contents as well, which will make problems easier        
 * to diagnose.                                                                 
 *                                                                              
 * Parameters:                                                                  
 *        ptr to a parmlist                                                     
 *        parmlist_type value                                                   
 *                                                                              
 * Returns:                                                                     
 *   None                                                                       
 *                                                                              
 */                                                                             
void printParmlistRCs(void *parmlist, parmlist_type ptype) {                    
                                                                                
    switch(ptype) {                                                             
        case CONNECT:                                                           
            printf("Connect RC=%04x\tRSN=%04x\n",                               
                    *((parmlist_connect *)parmlist)->retcode_ptr,               
                    *((parmlist_connect *)parmlist)->rsncode_ptr);              
            break;                                                              
        case GET:                                                               
            printf("Get RC=%04x\tRSN=%04x\n",                                   
                    *((parmlist_get *)parmlist)->retcode_ptr,                   
                    *((parmlist_get *)parmlist)->rsncode_ptr);                  
            break;                                                              
        case DISCONNECT:                                                        
            printf("Disconnect RC=%04x\tRSN=%04x\n",                            
                    *((parmlist_disconnect *)parmlist)->retcode_ptr,            
                    *((parmlist_disconnect *)parmlist)->rsncode_ptr);           
            break;                                                              
        default:                                                                
            /*                                                                  
             * This should not really ever happen unless a new                  
             * enumerated parmlist_type is added in smfreal.h without           
             * a new case for it here.                                          
             */                                                                 
            printf("Unknown RC=%04x\tRSN=%04x\n",                               
                    *((parmlist_connect *)parmlist)->retcode_ptr,               
                    *((parmlist_connect *)parmlist)->rsncode_ptr);              
            break;                                                              
    }                                                                           
}                                                                               
/*                                                                              
 *  promoteConnectionToken                                                      
 *                                                                              
 *  Copies a token received in a connect parm block into a get & disconnect     
 *  parameter block in order to prepare it for use.                             
 *                                                                              
 *  Destination field in the gtpb is assumed to be large enough.                
 *                                                                              
 *  Parameters:                                                                 
 *   None                                                                       
 *                                                                              
 *  Messages:                                                                   
 *    None                                                                      
 *                                                                              
 *  Returns:                                                                    
 *    None                                                                      
 */                                                                             
void promoteConnectionToken() {                                                 
                                                                                
    memcpy(gtpb_test.GtPb_Token, cnpb_test.CnPb_Token,                          
            sizeof(gtpb_test.GtPb_Token));                                      
    memcpy(dspb_test.DsPb_Token, cnpb_test.CnPb_Token,                          
            sizeof(dspb_test.DsPb_Token));                                      
}                                                                               
                                                                                
/*                                                                              
 *  validateConnectToken                                                        
 *                                                                              
 *  Ensures that a connection token has been set in the CNPB structure          
 *                                                                              
 *    This simple routine looks for a non-zero value in the token area,         
 *    if true, then a token is considered set                                   
 *                                                                              
 *    If the entire token area is set to zeros, then the token is               
 *      considered not set                                                      
 *                                                                              
 *  Parameters:                                                                 
 *   None                                                                       
 *                                                                              
 *  Messages:                                                                   
 *    None                                                                      
 *                                                                              
 *  Returns:                                                                    
 *    integer return code:                                                      
 *        0 if a token has been set                                             
 *        8 if the token has not been set                                       
 */                                                                             
int validateConnectToken() {                                                    
                                                                                
    int local_rc = LOCAL_SUCCESS_RC;                                            
    char test = 0x00;                                                           
    int i;                                                                      
                                                                                
    for (i = 0; i < sizeof(cnpb_test.CnPb_Token); ++i) {                        
      test |= cnpb_test.CnPb_Token[i];                                          
    }                                                                           
    if (test == 0x00) {                                                         
      local_rc = LOCAL_ERROR_RC;                                                
    }                                                                           
    return local_rc;                                                            
}                                                                               
                                                                                
/*                                                                              
 *                                                                              
 *  initializeParmlists                                                         
 *                                                                              
 *  Sets up the parmlists by:                                                   
 *    - initializing all parm blocks, and initial settings                      
 *    - assigning parm blocks, rsn, and retcode vars                            
 *                                                                              
 *  Parameters:                                                                 
 *   None                                                                       
 *                                                                              
 *  Messages:                                                                   
 *    None                                                                      
 *                                                                              
 *  Returns:                                                                    
 *    integer return code:                                                      
 *        0 If successful                                                       
 *        8 If not successful                                                   
 *                                                                              
 */                                                                             
                                                                                
int initializeParmlists() {                                                     
                                                                                
    int local_rc = LOCAL_SUCCESS_RC;    /* local return code */                 
                                                                                
    /*                                                                          
     * General set up for each parm area                                        
     */                                                                         
                                                                                
    /* clear all parameter control blocks */                                    
    memset(&cnpb_test, 0, sizeof cnpb_test);                                    
    memset(&gtpb_test, 0, sizeof gtpb_test);                                    
    memset(&dspb_test, 0, sizeof dspb_test);                                    
                                                                                
                                                                                
    /* clear all parmlists */                                                   
    memset(&pc, 0, sizeof pc);                                                  
    memset(&pg, 0, sizeof pg);                                                  
    memset(&pd, 0, sizeof pd);                                                  
                                                                                
                                                                                
    /*                                                                          
     * Connect specifics                                                        
     */                                                                         
                                                                                
    /* Initialize entire membuffer name area in the cnpb to blanks   */         
    memset(cnpb_test.CnPb_Name, BLANK, sizeof(cnpb_test.CnPb_Name));            
                                                                                
    /* Set up connect parms with initial data */                                
    strncpy(cnpb_test.CnPb_Eyecatcher, CNPB_Catcher,                            
            strlen(CNPB_Catcher));             /* Eyecatcher         */         
                                                                                
    cnpb_test.CnPb_Version = CNPB_CurVer;      /* Version            */         
                                                                                
    cnpb_test.CnPb_Length = sizeof(cnpb);      /* cnpb buffer length */         
                                                                                
    strncpy(cnpb_test.CnPb_Name, MEM_BUFNAME,                                   
            strlen(MEM_BUFNAME));              /* Memory buffer name */         
                                                                                
    cnpb_test.CnPb_NameLength = strlen(MEM_BUFNAME);  /* Memory buffer          
                                                         Name length */         
                                                                                
    cn_retcode = RETCODE_INITIAL;           /* Initial retcode prime */         
    cn_rsncode = RSNCOD_INITIAL;            /* Initial rsncode prime */         
                                                                                
    /* Set up the connect parmlist area */                                      
    pc.cnpb_ptr     = &cnpb_test;                                               
    pc.retcode_ptr  = &cn_retcode;                                              
    pc.rsncode_ptr  = &cn_rsncode;                                              
                                                                                
    /************************/                                                  
    /* Disconnect specifics */                                                  
    /************************/                                                  
                                                                                
    /* Set up disconnect parms with data */                                     
    strncpy(dspb_test.DsPb_Eyecatcher, DSPB_Catcher,                            
            strlen(DSPB_Catcher));             /* Eyecatcher         */         
                                                                                
    dspb_test.DsPb_Version = DSPB_CurVer;      /* Version            */         
                                                                                
    dspb_test.DsPb_Length = sizeof(dspb);      /* dspb buffer length */         
                                                                                
    ds_retcode = RETCODE_INITIAL;           /* Initial retcode prime */         
    ds_rsncode = RSNCOD_INITIAL;            /* Initial rsncode prime */         
                                                                                
    /* Set up the disconnect parmlist area */                                   
    pd.dspb_ptr     = &dspb_test;                                               
    pd.retcode_ptr  = &ds_retcode;                                              
    pd.rsncode_ptr  = &ds_rsncode;                                              
                                                                                
    /*****************/                                                         
    /* Get specifics */                                                         
    /*****************/                                                         
                                                                                
    /* set up get parm block with data */                                       
    strncpy(gtpb_test.GtPb_Eyecatcher, GTPB_Catcher,                            
            strlen(GTPB_Catcher));             /* Eyecatcher         */         
                                                                                
    gtpb_test.GtPb_Version = GTPB_CurVer;      /* Version            */         
                                                                                
    gtpb_test.GtPb_Length = sizeof(gtpb);      /* gtpb buffer len    */         
                                                                                
    gtpb_test.GtPb_BufferPtr = &get_outbuffer; /* Set output buffer  */         
                                                                                
    memset(gtpb_test.GtPb_BufferPtr, 0, sizeof(rec_area)); /* Clear             
                                                  the output buffer  */         
                                                                                
    gtpb_test.GtPb_BufferLength = 32768;       /* Set output buffer             
                                                  length             */         
                                                                                
    setBlockingMode();                         /* Wait for records if           
                                                  none are immediately          
                                                  available          */         
                                                                                
                                                                                
    gt_retcode = RETCODE_INITIAL;           /* Initial retcode prime */         
    gt_rsncode = RSNCOD_INITIAL;            /* Initial rsncode prime */         
                                                                                
    /* set up the get parmlist area */                                          
    pg.gtpb_ptr     = &gtpb_test;                                               
    pg.retcode_ptr  = &gt_retcode;                                              
    pg.rsncode_ptr  = &gt_rsncode;                                              
                                                                                
    return local_rc;                                                            
                                                                                
}                                                                               
/*                                                                              
 * Sets "blocking mode" for the IFAMGET service.                                
 *                                                                              
 * Parameters:                                                                  
 *  None                                                                        
 *                                                                              
 * Returns:                                                                     
 *  None                                                                        
 *                                                                              
 */                                                                             
void setBlockingMode() {                                                        
    static const char BLOCKING_MODE = 0x00;                                     
    gtpb_test.GtPb_Flags[0] = BLOCKING_MODE;                                    
                                                                                
}                                                                               
/*                                                                              
 * Sets "non blocking mode" for the IFAMGET service.                            
 *                                                                              
 * Parameters:                                                                  
 *  None                                                                        
 *                                                                              
 * Returns:                                                                     
 *  None                                                                        
 *                                                                              
 */                                                                             
void setNonBlockingMode() {                                                     
                                                                                
    static const char NON_BLOCKING_MODE = 0x10;                                 
    gtpb_test.GtPb_Flags[0] = NON_BLOCKING_MODE;                                
                                                                                
}                                                                               
                                                                                
