/*********************************************************************/
/* smf84fmt.h                                                        */
/*   Author: Nick Becker                                             */
/*   Created: 2 March, 2018                                          */
/*   License: apache-2.0 (Apache License 2.0)                        */
/*     URL: https://www.apache.org/licenses/LICENSE-2.0              */
/*********************************************************************/
/* Beginning of Copyright and License                                */
/*                                                                   */
/* Copyright 2017 IBM Corp.                                          */
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
/* either express or implied.  See the License for the specific      */
/* language governing permissions and limitations under the License. */
/*                                                                   */
/* End of Copyright and License                                      */
/*********************************************************************/

/*********************************************************************/
/* Defines                                                           */
/*********************************************************************/

/* maximum length of WTO messages */
#define WTO_MAX 80

/*********************************************************************/
/* Assembly inserts                                                  */
/*********************************************************************/

/* DCB mapping */
#pragma insert_asm(" DCBD DSORG=PS")
#pragma insert_asm(" IHADCBE")

/* WTO parameter list */
__asm(" WTO TEXT=0,MF=L" : "DS"(WTO_PARM_DS));
__asm(" WTOR TEXT=(0,1,2,3),MF=L" : "DS"(WTOR_PARM_DS));

/* I/O parameter lists */
__asm(" OPEN (,),MF=L" : "DS"(OPEN_PARM_DS));
__asm(" CLOSE (,),MF=L" : "DS"(CLOSE_PARM_DS));

/* DDs */
__asm(" DCB DDNAME=SYSPRINT,"
           "MACRF=PL," // locate mode
           "DSORG=PS,"
           "RECFM=VB,"
           "LRECL=132,"
           "BLKSIZE=0"
      : "DS"(SYSPRINT_DCB_DS));

__asm(" DCB DDNAME=SMF84OUT,"
           "MACRF=PL," // locate mode
           "DSORG=PS,"
           "RECFM=VB,"
           "LRECL=32756,"
           "BLKSIZE=0"
      : "DS"(SMF84OUT_DCB_DS));

__asm(" DCB DDNAME=SMF84IN,"
           "MACRF=GL," // locate mode
           "DSORG=PS,"
           "BFTEK=A,"  // unspan the records for us
           "DCBE=0"
      : "DS"(SMF84IN_DCB_DS));

__asm(" DCBE EODAD=GET_EOF,"
            "RMODE31=BUFF,"
            "BLKSIZE=0"
      : "DS"(SMF84IN_DCBE_DS));

/*********************************************************************/
/* Types                                                             */
/*********************************************************************/

#pragma pack(1)

/* enum to represent options passed to smf84fmt on PARM= */
typedef enum {
  /* sections */
  OPT_HEADER   = 0x80000000,
  OPT_PRODUCT  = 0x40000000,
  OPT_GENERAL  = 0x20000000,
  OPT_JES2     = 0x10000000,
  OPT_MEMORY   = 0x08000000,
  OPT_RESOURCE = 0x04000000,

  /* formatting options */
  OPT_CSV  = 0x00000080,
  OPT_JSON = 0x00000040

} SMF84FMT_OPTS;

/* map out SMF84HDR */
typedef struct {
  uint16_t SMF84LEN;
  uint16_t SMF84SEG;
  uint8_t  SMF84FLG;
  uint8_t  SMF84RTY;
  uint32_t SMF84TME;
  uint32_t SMF84DTE;
  char SMF84SID[4];
  uint16_t SMF84SBS;
  uint16_t SMF84SGN;
  uint8_t SMF84FL1;
  uint8_t SMF84VER;
  uint16_t SMF84STY;
  uint16_t SMF84TRN;
  uint32_t SMF84PRS;
  uint16_t SMF84PRL;
  uint16_t SMF84PRN;
  uint32_t SMF84GNS;
  uint16_t SMF84GNL;
  uint16_t SMF84GNN;
  uint32_t SMF84J1O;
  uint16_t SMF84J1L;
  uint16_t SMF84J1N;
} SMF84HDR;

/* map out SMF84PRO */
typedef struct {
  uint16_t R84MFVER;
  char R84PRDNM[8];
  uint32_t R84INTST;
  uint32_t R84SDATE;
  uint32_t R84INTEN;
  uint32_t R84EDATE;
  uint32_t R84INTER;
  uint32_t R84MFCYC;
  char reserved1[2];
  uint32_t R84SAMPL;
  char R84MFCMD[80];
  char R84MVSRL[8];
  char R84JESRL[8];
  char R84CPUM[4];
  uint32_t R84RSTO;
  char R84CPUNM[8];
  char R84CPUID[4];
  char R84MPNAM[8];
  uint8_t R84J3FLG;
  char reserved2[1];
  uint16_t R84JPRTY;
  uint32_t R84JMFMN;
  uint32_t R84JMFMX;
  uint32_t R84JMFAV;
  uint32_t R84MVSMN;
  uint32_t R84MVSMX;
  uint32_t R84MVSAV;
} SMF84PRO;

/* map out SMF84GS */
typedef struct {
  uint32_t R84CPUSC;
  uint32_t R84NPA;
  uint32_t R84APA;
  uint32_t R84NPNA;
  uint32_t R84APNA;
  uint32_t R84NNP;
  uint32_t R84ANP;
  uint32_t R84NNW;
  uint32_t R84ANW;
  uint32_t R84NSLLR;
  uint32_t R84ASLLR;
  uint32_t R84NSO;
  uint32_t R84ASO;
} SMF84GS;

/* map out SMF84JRU */
typedef struct {
  uint32_t R84J2RUL;
  char reserved1[26];
  // Triplets to describe the data areas being returned.
  uint16_t R84J2RTR;
  // Memory usage section (R84MEMJ2 DSECTs)
  uint32_t R84J2RMO;
  uint16_t R84J2RML;
  uint16_t R84J2RMN;
  // Resource usage section (R84RSUJ2 DSECTs)
  uint32_t R84J2RRO;
  uint16_t R84J2RRL;
  uint16_t R84J2RRN;
} SMF84JRU;

/* map out R84MEMJ2 */
typedef struct {
  char R84MEM_NAME[12];
  uint32_t reserved1;
  uint64_t R84MEM_REGION;
  uint64_t R84MEM_USE;
  uint64_t R84MEM_LOW;
  uint64_t R84MEM_HIGH;
  uint64_t R84MEM_AVERAGE;
} R84MEMJ2;

/* map out R84RSUJ2 */
typedef struct {
  char R84RSU_NAME[8];
  uint32_t R84RSU_LIMIT;
  uint32_t R84RSU_INUSE;
  uint32_t R84RSU_LOW;
  uint32_t R84RSU_HIGH;
  uint16_t R84RSU_WARN;
  uint8_t R84RSU_FLG1;
  uint8_t reserved1;
  uint32_t R84RSU_OVER;
  uint32_t R84RSU_AVERAGE;
  char reserved2[4];
} R84RSUJ2;

/* for WTOs */
typedef struct {
  uint16_t length;
  char text[WTO_MAX];
} Wto;

/* for OPEN/PUT/GET/CLOSE */
typedef struct {
  char DCB[256];
} DCB;

typedef struct {
  char DCBE[256];
} DCBE;

#pragma pack(pop)

/*********************************************************************/
/* Constants
/*********************************************************************/

/* bit masks for SMF84FMT_OPTS */
static const uint32_t OPT_SECTIONS = 0xFF000000;
static const uint32_t OPT_FORMAT = 0x000000FF;

/* compute sizes of sections */
static const int SMF84HDR_SIZE = sizeof(SMF84HDR);
static const int SMF84PRO_SIZE = sizeof(SMF84PRO);
static const int SMF84GS_SIZE = sizeof(SMF84GS);
static const int SMF84JRU_SIZE = sizeof(SMF84JRU);
static const int R84MEMJ2_SIZE = sizeof(R84MEMJ2);
static const int R84RSUJ2_SIZE = sizeof(R84RSUJ2);

/* compute sizes of name fields */
static const int R84MEM_NAME_SIZE =
  sizeof(((R84MEMJ2 *) 0) -> R84MEM_NAME);

static const int R84RSU_NAME_SIZE =
  sizeof(((R84RSUJ2 *) 0) -> R84RSU_NAME);

/* misc */
static const uint16_t EOF = -1;

/*********************************************************************/
/* Forward declarations
/*********************************************************************/

/* mainline support */
static int32_t open_dds();
static int32_t read_parm(const char *user_data);

static void log_message(const char *fmt, ...);

/* record formatting - CSV */
static int32_t format_records_csv();
static uint16_t format_headings_csv(char *buffer, size_t size,
  SMF84HDR *smf84hdr);

/* record formatting - JSON */
static int32_t format_records_json();

/* record formatting - misc */
static char *rtrim(char *str, size_t length);
static char *format_smftime(char buffer[16], uint32_t hseconds);
static char *format_smftime2(char buffer[16], uint32_t smftime);
static char *format_smftime3(char buffer[16], uint32_t smftime);
static char *format_smfdate(char *buffer, uint32_t smfdate);

/* assembly - memory */
static void *obtain24(size_t size, int subpool);
static void release24(void *ptr, size_t size, int subpool);

/* assembly - I/O */
static int32_t open_read(DCB *dcb);
static int32_t open_write(DCB *dcb);
static int32_t close(DCB *dcb);
static uint16_t put(DCB *dcb, char **buffer);
static uint16_t get(DCB *dcb, char **buffer);

static int32_t issue_wto(const char *fmt, ...);

