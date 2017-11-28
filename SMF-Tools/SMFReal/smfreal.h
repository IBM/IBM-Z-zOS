/*                                                                              
 *                                                                              
 * Name: smfreal.h                                                              
 *                                                                              
 * Descriptive name: Header for SMF Real-Time service invocation sample.        
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
 * Change Activity =                                                            
 *                                                                              
 *   $00=REAL-TIME,HQX7790,16108,PDNM:  Initial sample                          
 *                                                                              
 * Processor: IBM z/OS XL C                                                     
 *                                                                              
 * Notes:                                                                       
 *                                                                              
 *   This to be included as part of the smfreal.c sample program.               
 *                                                                              
 * DISCLAIMER:                                                                  
 *                                                                              
 *   This sample program is provided for tutorial purposes only.  A             
 *   complete handling of error conditions has not been shown or                
 *   attempted, and this source has not been submitted to formal IBM            
 *   testing. This source is distributed on an 'as is' basis                    
 *   without any warranties either expressed or implied.                        
 *                                                                              
 */                                                                             
                                                                                
#ifndef SMFREAL_H_                                                              
#define SMFREAL_H_                                                              
                                                                                
/* Global defines */                                                            
#include <stdint.h>                                                             
                                                                                
#pragma pack(1) /* 1-byte alignment for the following structs */                
                                                                                
/*                                                                              
 *  Define the IFAMCON service parameter structure                              
 *  which is used to establish a connect to the real time SMF service           
 *                                                                              
 *  Note:  this must match what is defined in the IFAZSYSP macro                
 *         which is in MACLIB                                                   
 *
 */                                                                             
#define CNPB_Catcher "CNPB"                                                     
#define CNPB_VERSION_1 1    /* HBB7790 initial */                               
#define CNPB_CurVer CNPB_VERSION_1                                              
                                                                                
 typedef struct cnpb {                                                          
     char        CnPb_Eyecatcher[4];  /* Eye catcher                 */         
     uint16_t    CnPb_Length;         /* Length of the block         */         
     char        CnPb_Rsvd1[1];       /* Reserved                    */         
     uint8_t     CnPb_Version;        /* Version number              */         
     char        CnPb_Flags[4];       /* Flags                       */         
     uint16_t    CnPb_NameLength;     /* Length of the name of the              
                                         memory buffer               */         
     char        CnPb_Name[26];       /* Name of mem buffer resource */         
     char        CnPb_Rsvd2[8];       /* Reserved                    */         
     char        CnPb_Rsvd3[8];       /* Reserved                    */         
     char        CnPb_Token[16];      /* Output token for other                 
                                         services                    */         
     char        CnPb_Rsvd4[34];      /* Reserved                    */         
 } cnpb;                                                                        
                                                                                
 /*                                                                             
  *  Define the IFAMGET service parameter structure                             
  *  which is used to establish a connect to the real time SMF service          
  *                                                                             
  *  Note:  this must match what is defined in the IFAZSYSP macro               
  *         which is in MACLIB                                                  
  *                                                                             
  */                                                                            
#define GTPB_Catcher "GTPB"                                                     
#define GTPB_VERSION_1 1                                                        
#define GTPB_CurVer GTPB_VERSION_1                                              
                                                                                
 typedef struct gtpb {                                                          
     char        GtPb_Eyecatcher[4];  /* Eye catcher                 */         
     uint16_t    GtPb_Length;         /* Length of block             */         
     char        GtPb_Rsvd1[1];       /* Reserved                    */         
     uint8_t     GtPb_Version;        /* Version number              */         
     char        GtPb_Flags[4];       /* Flags  (see IFAZSYSP)       */         
     char        GtPb_Rsvd2[4];       /* Reserved                    */         
     char        GtPb_Token[16];      /* Input token from ifamcon               
                                         service                     */         
     uint32_t    GtPb_BufferLength;   /* Length of the provided                 
                                         buffer in bytes             */         
     char        GtPb_Rsvd3[16];      /* Reserved                    */         
     uint32_t    GtPb_ReturnedLength; /* Length of the data returned            
                                         in the buffer in bytes      */         
     void        *GtPb_BufferPtr;     /* Address of the provided                
                                         buffer                      */         
 } gtpb;                                                                        
                                                                                
 /*                                                                             
   *  Define the IFAMDSC service parameter structure                            
   *  which is used to establish a connect to the real time SMF service         
   *                                                                            
   *  Note:  this must match what is defined in the IFAZSYSP macro              
   *         which is in MACLIB                                                 
   *                                                                            
   */                                                                           
#define DSPB_Catcher "DSPB"                                                     
#define DSPB_VERSION_1 1                                                        
#define DSPB_CurVer DSPB_VERSION_1                                              
                                                                                
 typedef struct dspb {                                                          
     char       DsPb_Eyecatcher[4];   /* Eye catcher                 */         
     uint16_t   DsPb_Length;          /* Length of block             */         
     char       DsPb_Rsvd1[1];        /* Reserved                    */         
     uint8_t    DsPb_Version;         /* Version number              */         
     char       DsPb_Token[16];       /* Input token from ifamcon               
                                         service                     */         
 } dspb;                                                                        
                                                                                
/* enums for each type of parmlist */                                           
 typedef enum Types {CONNECT, DISCONNECT, GET} parmlist_type;                   
                                                                                
/*                                                                              
 * SMF Type 30 partial mapping for the purposes of this example                 
 */                                                                             
 typedef struct smf30 {                                                         
     uint16_t   Smf30Len;             /* Record Length               */         
     uint16_t   Smf30Seg;             /* Segment descriptor          */         
     uint8_t    Smf30Flg;             /* System indicator            */         
     uint8_t    Smf30Rty;             /* Record Type 30 or '1E'x     */         
     char       Smf30Tme[4];          /* Time since midnight 1/100s             
                                         of a second since moved to             
                                         SMF buffer                  */         
     char       Smf30Dte[4];          /* Date record moved to the               
                                         SMF buffer 0cyydddF         */         
     char       Smf30Sid[4];          /* System ID (EBCDIC)          */         
     char       Smf30Wid[4];          /* Work type indicator, STC,              
                                         TSO,...                     */         
     uint16_t   Smf30Stp;             /* SMF 30 record subtype       */         
     uint32_t   Smf30Sof;             /* Offset to subsystem section */         
     uint16_t   Smf30Sln;             /* Length of subsystem section */         
     uint16_t   Smf30Son;             /* Number of subsystem                    
                                         sections                    */         
     uint32_t   Smf30Iof;             /* Offset to Identification               
                                         section                     */         
     uint16_t   Smf30Iln;             /* Length of Identification               
                                         section                     */         
     uint16_t   Smf30Ion;             /* Number of Identification               
                                         sections                    */         
 } smf30;                                                                       
                                                                                
 /*                                                                             
  * SMF Type 30 Identification section partial mapping for the                  
  * purposes of this example                                                    
  */                                                                            
 typedef struct smf30ID {                                                       
     char       Smf30Jbn[8];          /* Job name           (EBCDIC) */         
     char       Smf30Pgm[8];          /* Program name       (EBCDIC) */         
     char       Smf30Stm[8];          /* Step name          (EBCDIC) */         
     char       Smf30Uif[8];          /* User-defined ID                        
                                         field              (EBCDIC) */         
     char       Smf30Jnm[8];          /* JES job ID         (EBCDIC) */         
 } smf30ID;                                                                     
                                                                                
#pragma pack(reset)    /* reset to prior alignment rule */                      
                                                                                
/* IFAMCON external function CSS stub in linklist */                            
extern int IFAMCON(cnpb *, int *, int *);  /* Function definition */            
#pragma linkage(IFAMCON,OS64_NOSTACK)                                           
                                                                                
/* IFAMGET external function CSS stub in linklist */                            
extern int IFAMGET(gtpb *, int *, int *);  /* Function definition */            
#pragma linkage(IFAMGET,OS64_NOSTACK)                                           
                                                                                
/* IFAMDSC external function CSS stub in linklist */                            
extern int IFAMDSC(dspb *, int *, int *);  /* Function definition */            
#pragma linkage(IFAMDSC,OS64_NOSTACK)                                           
                                                                                
/* service return codes */                                                      
#define SUCCESS            0                                                    
#define IFA_SUCCESS        0                                                    
#define IFA_WARNING        4                                                    
#define IFA_ERROR          8                                                    
#define IFA_SEVERE        12                                                    
                                                                                
#endif /* SMFREAL_H_ */                                                         
