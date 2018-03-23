/*********************************************************************/
/* smf84fmt.c                                                        */
/*   Author: Nick Becker                                             */
/*   Created: 15 February, 2018                                      */
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

/* metal C library headers */
#include <ctype.h>
#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

/* smf84fmt headers */
#include "smf84fmt.h"

/*********************************************************************/
/* Defines                                                           */
/*********************************************************************/

/* points to and returns next character in string */
#define ADVANCE_CHAR(s) (*(++(*(s))))

/* returns a positive integer if a chunk of memory resides within its
     parent area, or a negative integer if it exceeds the boundary of
     area */
#define CHECK_BOUNDS(base, base_size, section, section_size) \
  ((int)(section) - (int)(base) + (base_size) - (section_size))

#define MIN(x,y) (((x) < (y)) ? (x) : (y))
#define MAX(x,y) (((x) > (y)) ? (x) : (y))

/*********************************************************************/
/* Global variables                                                  */
/*********************************************************************/

/* set by __cinit() - establishes a metal C environment */
register void *envtkn __asm("r12");

/* map out work area - will be obtained in 24-bit for DCBs */
typedef struct {
  DCB dcbs[3];
  DCBE dcbes[1];
} SMF84FMT_WORK;

SMF84FMT_WORK *smf84fmt_work24;

/* options passed on PARM= */
SMF84FMT_OPTS smf84fmt_opts;

/* DCBs */
DCB *sysprint_dcb;
DCB *smf84out_dcb;
DCB *smf84in_dcb;
DCBE *smf84in_dcbe;

/* SYSPRINT buffer */
char *sysprint_buffer;

/*********************************************************************/
/* smf84fmt mainline                                                 */
/*********************************************************************/

int32_t main(const char *user_data) {
  /*
  Main entry point.
  */
  int32_t smf84fmt_rc = 0;

  struct __csysenv_s sysenv;

  /* initialize the metal C environment - needed for snprintf() */
  memset(&sysenv, 0, sizeof(sysenv));
  sysenv.__cseversion = __CSE_VERSION_1;
  sysenv.__csesubpool = 0;

  if ((envtkn = (void *) __cinit(&sysenv))) {

    /* obtain 24-bit storage for work area */
    if (smf84fmt_work24 = obtain24(sizeof(SMF84FMT_WORK), 0)) {

      /* open DDs */
      if (!(smf84fmt_rc = open_dds())) {

        /* read options from PARM= */
        if(smf84fmt_rc = read_parm(user_data))
          log_message("Parameter error detected - "
                      "supported parameters are: "
                      "HEADER GENERAL PRODUCT JES2 MEMORY RESOURCE "
                      "CSV JSON");

        /* read and format SMF records - CSV */
        if (smf84fmt_opts & OPT_CSV)
          smf84fmt_rc = MAX(format_records_csv(), smf84fmt_rc);

        /* read and format SMF records - JSON */
        else if (smf84fmt_opts & OPT_JSON)
          smf84fmt_rc = MAX(format_records_json(), smf84fmt_rc);

        log_message("SMF84FMT terminating normally: RC = %d",
           smf84fmt_rc);

        /* close datasets */
        close(smf84in_dcb);
        close(smf84out_dcb);
        close(sysprint_dcb);
      }

      /* failed to open DDs */
      else {
        issue_wto("Failed to open DDs");
      }

      /* release 24-bit storage */
      release24(smf84fmt_work24, sizeof(smf84fmt_work24), 0);
    }

    /* failed to obtain 24-bit storage */
    else {
      issue_wto("Failed to obtain 24 bit storage");
      smf84fmt_rc = 12;
    }

    /* terminate metal C environment */
    __cterm((__csysenv_t) envtkn);
  }

  /* failed to initialize metal C environment */
  else {
    issue_wto("Failed to initialize metal C environment");
    smf84fmt_rc = 8;
  }

  return smf84fmt_rc;
}

/*********************************************************************/
/* Mainline support                                                  */
/*********************************************************************/

static int32_t open_dds() {
  /*
  Open the following datasets:
    SYSPRINT (output)
    SMF84OUT (output)
    SMF84IN (input)
  */
  int32_t open_dds_rc = 0;

  /* set pointers to items in 24-bit work area */
  sysprint_dcb = &(smf84fmt_work24 -> dcbs[0]);
  smf84out_dcb = &(smf84fmt_work24 -> dcbs[1]);
  smf84in_dcb = &(smf84fmt_work24 -> dcbs[2]);
  smf84in_dcbe = &(smf84fmt_work24 -> dcbes[0]);

  /* setup DCBs */
  memcpy(sysprint_dcb, &SYSPRINT_DCB_DS, sizeof(DCB));
  memcpy(smf84out_dcb, &SMF84OUT_DCB_DS, sizeof(DCB));
  memcpy(smf84in_dcb, &SMF84IN_DCB_DS, sizeof(DCB));
  memcpy(smf84in_dcbe, &SMF84IN_DCBE_DS, sizeof(DCBE));

  __asm(" PUSH USING\n"
        " USING IHADCB,%0\n"
        " ST %1,DCBDCBE\n"
        " POP USING"
        // output
        :
        // input
        : "r"(smf84in_dcb),
          "r"(smf84in_dcbe)
        // clobbers
        : "r0", "r1", "r14", "r15"
        );

  /* open SYSPRINT */
  if (open_dds_rc = open_write(sysprint_dcb)) {
    issue_wto("OPEN SYSPRINT failed, rc=%d", open_dds_rc);
    return open_dds_rc;
  }
  log_message("Opened SYSPRINT for writing.");

  /* open SMF84OUT */
  if (open_dds_rc = open_write(smf84out_dcb)) {
    issue_wto("OPEN SMF84OUT failed, rc=%d", open_dds_rc);
    return open_dds_rc;
  }
  log_message("Opened SMF84OUT for writing.");

  /* open SMF84IN */
  if (open_dds_rc = open_read(smf84in_dcb)) {
    issue_wto("OPEN SMF84IN failed, rc=%d", open_dds_rc);
    return open_dds_rc;
  }
  log_message("Opened SMF84IN for reading.");

  return open_dds_rc;
}

static int32_t read_parm(const char *user_data) {
  /*
  Read the PARM= string specified on the EXEC statement.
  */
  int32_t read_parm_rc = 0;

  char parm[128];
  char parm_length;

  char *word;

  int i;

  log_message("Entered read_parm() ...");

  /* second byte is length of the parm string - maximum is 100 bytes */
  parm_length = *(user_data + 1);

  /* copy parm string into local buffer and terminate with a blank */
  memcpy(parm, user_data + 2, parm_length);
  parm[parm_length] = ' ';
  log_message("  PARM = '%.*s'", parm_length, parm);

  /* process words */
  for (i = 0; i < parm_length; i++) {
    if (!isspace(parm[i])) {
      /* at the start of a word */
      word = &parm[i];

      /* find end of word */
      while (++i < parm_length)
        if (isspace(parm[i]))
          break;

      /* mark end of the word */
      parm[i] = '\0';

      /* include SMF84HDR? */
      if (!strcmp(word, "HEADER")) {
        smf84fmt_opts |= OPT_HEADER;
        log_message("  HEADER: SMF84HDR will be formatted");
      }

      /* include SMF84PRO? */
      else if (!strcmp(word, "PRODUCT")) {
        smf84fmt_opts |= OPT_PRODUCT;
        log_message("  PRODUCT: SMF84PRO will be formatted");
      }

      /* include SMF84GS? */
      else if (!strcmp(word, "GENERAL")) {
        smf84fmt_opts |= OPT_GENERAL;
        log_message("  GENERAL: SMF84GS will be formatted");
      }

      /* include SMF84JRU? */
      else if (!strcmp(word, "JES2")) {
        smf84fmt_opts |= OPT_JES2;
        log_message("  JES2: SMF84JRU will be formatted");
      }

      /* include R84MEMJ2s? */
      else if (!strcmp(word, "MEMORY")) {
        smf84fmt_opts |= OPT_MEMORY;
        log_message("  MEMORY: R84MEMJ2 will be formatted");
      }

      /* include R84RSUJ2s? */
      else if (!strcmp(word, "RESOURCE")) {
        smf84fmt_opts |= OPT_RESOURCE;
        log_message("  RESOURCE: R84RSUJ2 will be formatted");
      }

      /* CSV format */
      else if (!strcmp(word, "CSV")) {
        smf84fmt_opts &= ~OPT_FORMAT;
        smf84fmt_opts |= OPT_CSV;
        log_message("  CSV: Output format will be CSV");
      }

      /* JSON format */
      else if (!strcmp(word, "JSON")) {
        smf84fmt_opts &= ~OPT_FORMAT;
        smf84fmt_opts |= OPT_JSON;
        log_message("  JSON: Output format will be JSON");
      }

      /* bad keyword - indicate error */
      else {
        log_message("  %s: Ignored", word);
        read_parm_rc = 4;
      }
    }
  }

  /* no sections selected - set some defaults */
  if (!(smf84fmt_opts & OPT_SECTIONS)) {
    log_message("  No sections were specified -  "
                "using the following defaults: "
                "HEADER MEMORY RESOURCE");

    smf84fmt_opts |= (OPT_HEADER | OPT_MEMORY | OPT_RESOURCE);
    read_parm_rc = 4;
  }

  /* no format selected - set default of CSV */
  if (!(smf84fmt_opts & OPT_FORMAT)) {
    log_message("  No format was specified - defaulting to CSV");

    smf84fmt_opts |= OPT_CSV;
    read_parm_rc = 4;
  }

  log_message("Leaving read_parm() ...");

  return read_parm_rc;
}

/*********************************************************************/
/* Record formatting - CSV                                           */
/*********************************************************************/

static int32_t format_records_csv() {
  /*
  */
  int records_count = 0;
  int records84_count = 0;

  int bounds;

  SMF84HDR *smf84hdr;
  SMF84PRO *smf84pro;
  SMF84GS *smf84gs;
  SMF84JRU *smf84jru;
  R84MEMJ2 *r84memj2;
  R84RSUJ2 *r84rsuj2;

  char *buffer_out;
  char *buffer_in;
  uint16_t smf84out_dcblrecl; // capacity of buffer_out
  uint16_t smf84in_dcblrecl; // capacity of buffer_in
  uint16_t n; // offset into buffer_out

  char fmt_buffer[5][16];

  int i;

  log_message("Entered format_records_csv() ...");

  /* read records until EOF */
  while ((smf84in_dcblrecl = get(smf84in_dcb, &buffer_in)) != EOF) {

    records_count++;

    /* only look at SMF 84.21 records */
    smf84hdr = (SMF84HDR *) buffer_in;

    if ((smf84hdr -> SMF84RTY == 84) &&
        (smf84hdr -> SMF84STY == 21)) {

      log_message("  Record %d is an SMF 84.21 record", records_count);

      /* locate/initialize next output buffer */
      smf84out_dcblrecl = put(smf84out_dcb, &buffer_out);
      n = 4;

      /* if this is the first SMF 84.21 record, emit headings */
      if (!records84_count++) {
        n += format_headings_csv(buffer_out + n,
          smf84out_dcblrecl - n, smf84hdr);

        /* set length of record */
        memcpy(buffer_out, &n, sizeof(n));

        /* locate/initialize next output buffer */
        smf84out_dcblrecl = put(smf84out_dcb, &buffer_out);
        n = 4;
      }

      /* header section */
      if (smf84fmt_opts & OPT_HEADER)
        n += snprintf(buffer_out + n, smf84out_dcblrecl - n,
          ",%d,%d,%02X,%d,%s,%s,%.4s,%d,%d,%02X,%d,%d,%d"
          ",%d,%d,%d,%d,%d,%d,%d,%d,%d",
          smf84hdr -> SMF84LEN,
          smf84hdr -> SMF84SEG,
          smf84hdr -> SMF84FLG,
          smf84hdr -> SMF84RTY,
          format_smftime(fmt_buffer[0], smf84hdr -> SMF84TME),
          format_smfdate(fmt_buffer[1], smf84hdr -> SMF84DTE),
          rtrim(smf84hdr -> SMF84SID, 4),
          smf84hdr -> SMF84SBS,
          smf84hdr -> SMF84SGN,
          smf84hdr -> SMF84FL1,
          smf84hdr -> SMF84VER,
          smf84hdr -> SMF84STY,
          smf84hdr -> SMF84TRN,
          smf84hdr -> SMF84PRS,
          smf84hdr -> SMF84PRL,
          smf84hdr -> SMF84PRN,
          smf84hdr -> SMF84GNS,
          smf84hdr -> SMF84GNL,
          smf84hdr -> SMF84GNN,
          smf84hdr -> SMF84J1O,
          smf84hdr -> SMF84J1L,
          smf84hdr -> SMF84J1N);

      /* product section */
      if (smf84fmt_opts & OPT_PRODUCT) {
        smf84pro = (SMF84PRO *) \
          ((uint32_t) smf84hdr + (smf84hdr -> SMF84PRS));

        n += snprintf(buffer_out + n, smf84out_dcblrecl - n,
          ",%d,%.8s,%s,%s,%s,%s,%d,%s,%d,%.80s,%.8s,%.8s,"
          "%.4s,%d,%.8s,%.4s,%.8s,%02X,%d,%d,%d,%d,%d,%d,%d",
          smf84pro -> R84MFVER,
          rtrim(smf84pro -> R84PRDNM, 8),
          format_smftime2(fmt_buffer[0], smf84pro -> R84INTST),
          format_smfdate(fmt_buffer[1], smf84pro -> R84SDATE),
          format_smftime2(fmt_buffer[2], smf84pro -> R84INTEN),
          format_smfdate(fmt_buffer[3], smf84pro -> R84EDATE),
          smf84pro -> R84INTER,
          format_smftime3(fmt_buffer[4], smf84pro -> R84MFCYC),
          smf84pro -> R84SAMPL,
          rtrim(smf84pro -> R84MFCMD, 80),
          rtrim(smf84pro -> R84MVSRL, 8),
          rtrim(smf84pro -> R84JESRL, 8),
          rtrim(smf84pro -> R84CPUM, 4),
          smf84pro -> R84RSTO,
          rtrim(smf84pro -> R84CPUNM, 8),
          rtrim(smf84pro -> R84CPUID, 4),
          rtrim(smf84pro -> R84MPNAM, 8),
          smf84pro -> R84J3FLG,
          smf84pro -> R84JPRTY,
          smf84pro -> R84JMFMN,
          smf84pro -> R84JMFMX,
          smf84pro -> R84JMFAV,
          smf84pro -> R84MVSMN,
          smf84pro -> R84MVSMX,
          smf84pro -> R84MVSAV);
      }

      /* general section */
      if (smf84fmt_opts & OPT_GENERAL) {
        smf84gs = (SMF84GS *) \
          ((uint32_t) smf84hdr + (smf84hdr -> SMF84GNS));

        n += snprintf(buffer_out + n, smf84out_dcblrecl - n,
          ",%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d",
          smf84gs -> R84CPUSC,
          smf84gs -> R84NPA,
          smf84gs -> R84APA,
          smf84gs -> R84NPNA,
          smf84gs -> R84APNA,
          smf84gs -> R84NNP,
          smf84gs -> R84ANP,
          smf84gs -> R84NNW,
          smf84gs -> R84ANW,
          smf84gs -> R84NSLLR,
          smf84gs -> R84ASLLR,
          smf84gs -> R84NSO,
          smf84gs -> R84ASO);
      }

      /* JES2 section */
      smf84jru = (SMF84JRU *) \
        ((uint32_t) smf84hdr + (smf84hdr -> SMF84J1O));

      if (smf84fmt_opts & OPT_JES2)
        n += snprintf(buffer_out + n, smf84out_dcblrecl - n,
          ",%d,%d,%d,%d,%d,%d,%d,%d",
          smf84jru -> R84J2RUL,
          smf84jru -> R84J2RTR,
          smf84jru -> R84J2RMO,
          smf84jru -> R84J2RML,
          smf84jru -> R84J2RMN,
          smf84jru -> R84J2RRO,
          smf84jru -> R84J2RRL,
          smf84jru -> R84J2RRN);

      /* storage usage sections */
      if (smf84fmt_opts & OPT_MEMORY) {
        r84memj2 = (R84MEMJ2 *) \
          ((uint32_t) smf84jru + (smf84jru -> R84J2RMO));

        for (i = 0; i < smf84jru -> R84J2RMN; i++) {
          n += snprintf(buffer_out + n, smf84out_dcblrecl - n,
            ",%.12s,%lld,%lld,%lld,%lld,%lld",
            rtrim(r84memj2 -> R84MEM_NAME, R84MEM_NAME_SIZE),
            r84memj2 -> R84MEM_REGION,
            r84memj2 -> R84MEM_USE,
            r84memj2 -> R84MEM_LOW,
            r84memj2 -> R84MEM_HIGH,
            r84memj2 -> R84MEM_AVERAGE);

          r84memj2 = (R84MEMJ2 *) \
            ((uint32_t) r84memj2 + (smf84jru -> R84J2RML));
        }
      }

      /* resource usage sections */
      if (smf84fmt_opts & OPT_RESOURCE) {
        r84rsuj2 = (R84RSUJ2 *) \
          ((uint32_t) smf84jru + (smf84jru -> R84J2RRO));

        for (i = 0; i < smf84jru -> R84J2RRN; i++) {
          n += snprintf(buffer_out + n, smf84out_dcblrecl - n,
            ",%.8s,%d,%d,%d,%d,%d,%02X,%d,%d",
            rtrim(r84rsuj2 -> R84RSU_NAME, R84RSU_NAME_SIZE),
            r84rsuj2 -> R84RSU_LIMIT,
            r84rsuj2 -> R84RSU_INUSE,
            r84rsuj2 -> R84RSU_LOW,
            r84rsuj2 -> R84RSU_HIGH,
            r84rsuj2 -> R84RSU_WARN,
            r84rsuj2 -> R84RSU_FLG1,
            r84rsuj2 -> R84RSU_OVER,
            r84rsuj2 -> R84RSU_AVERAGE);

          r84rsuj2 = (R84RSUJ2 *) \
            ((uint32_t) r84rsuj2 + (smf84jru -> R84J2RRL));
        }
      }

      /* set length of record */
      memcpy(buffer_out, &n, sizeof(n));
    }
  }

  log_message("  Read %d records (%d SMF 84.21 records) from SMF84IN",
    records_count, records84_count);
  log_message("Leaving format_records_csv() ...");

  return 0;
}

static uint16_t format_headings_csv(char *buffer, size_t size,
  SMF84HDR *smf84hdr) {
  /*
  */
  SMF84PRO *smf84pro;
  SMF84GS *smf84gs;
  SMF84JRU *smf84jru;
  R84MEMJ2 *r84memj2;
  R84RSUJ2 *r84rsuj2;

  uint16_t n = 0;

  int i;

  log_message("  Entered format_headings_csv() ...");

  /* header section */
  if (smf84fmt_opts & OPT_HEADER)
    n += snprintf(buffer + n, size - n,
      ",SMF84LEN,SMF84SEG,SMF84FLG,SMF84RTY"
      ",SMF84TME,SMF84DTE,SMF84SID,SMF84SBS"
      ",SMF84SGN,MF84FL1,SMF84VER,SMF84STY"
      ",SMF84TRN,SMF84PRS,SMF84PRL,SMF84PRN"
      ",SMF84GNS,SMF84GNL,SMF84GNN,SMF84J1O"
      ",SMF84J1L,SMF84J1N");

  /* product section */
  if (smf84fmt_opts & OPT_PRODUCT)
    n += snprintf(buffer + n, size - n,
      ",R84MFVER,R84PRDNM,R84INTST,R84SDATE,R84INTEN"
      ",R84EDATE,R84INTER,R84MFCYC,R84SAMPL,R84MFCMD"
      ",R84MVSRL,R84JESRL,R84CPUM,R84RSTO,R84CPUNM"
      ",R84CPUID,R84MPNAM,R84J3FLG,R84JPRTY,R84JMFMN"
      ",R84JMFMX,R84JMFAV,R84MVSMN,R84MVSMX,R84MVSAV");

  /* general section */
  if (smf84fmt_opts & OPT_GENERAL)
    n += snprintf(buffer + n, size - n,
      ",R84CPUSC,R84NPA,R84APA,R84NPNA,R84APNA"
      ",R84NNP,R84ANP,R84NNW,R84ANW,R84NSLLR"
      ",R84ASLLR,R84NSO,R84ASO");

  /* JES2 section */
  smf84jru = (SMF84JRU *) \
    ((uint32_t) smf84hdr + (smf84hdr -> SMF84J1O));

  if (smf84fmt_opts & OPT_JES2)
    n += snprintf(buffer + n, size - n,
      ",R84J2RUL,R84J2RTR,R84J2RMO,R84J2RML"
      ",R84J2RMN,R84J2RRO,R84J2RRL,R84J2RRN");

  /* memory usage sections */
  if (smf84fmt_opts & OPT_MEMORY) {
    r84memj2 = (R84MEMJ2 *) \
      ((uint32_t) smf84jru + (smf84jru -> R84J2RMO));

    for (i = 0; i < smf84jru -> R84J2RMN; i++) {
      n += snprintf(buffer + n, size - n,
        ",R84MEM_NAME_%d"
        ",R84MEM_REGION_%d"
        ",R84MEM_USE_%d"
        ",R84MEM_LOW_%d"
        ",R84MEM_HIGH_%d"
        ",R84MEM_AVERAGE_%d",
        i, i, i, i, i, i);

      r84memj2 = (R84MEMJ2 *) \
        ((uint32_t) r84memj2 + (smf84jru -> R84J2RML));
    }
  }

  /* resource usage sections */
  if (smf84fmt_opts & OPT_RESOURCE) {
    r84rsuj2 = (R84RSUJ2 *) \
      ((uint32_t) smf84jru + (smf84jru -> R84J2RRO));

    for (i = 0; i < smf84jru -> R84J2RRN; i++) {
      n += snprintf(buffer + n, size - n,
        ",R84RSU_NAME_%d"
        ",R84RSU_LIMIT_%d"
        ",R84RSU_INUSE_%d"
        ",R84RSU_LOW_%d"
        ",R84RSU_HIGH_%d"
        ",R84RSU_WARN_%d"
        ",R84RSU_FLG1_%d"
        ",R84RSU_OVER_%d"
        ",R84RSU_AVERAGE_%d",
        i, i, i, i, i, i, i, i, i);

      r84rsuj2 = (R84RSUJ2 *) \
        ((uint32_t) r84rsuj2 + (smf84jru -> R84J2RRL));
    }
  }

  log_message("  Leaving format_headings_csv() ...");

  return n;
}

/*********************************************************************/
/* Record formatting - JSON                                          */
/*********************************************************************/

static int32_t format_records_json() {
  /*
  */
  int32_t format_records_rc = 0;

  int records_count = 0;
  int records84_count = 0;

  SMF84HDR *smf84hdr;
  SMF84PRO *smf84pro;
  SMF84GS *smf84gs;
  SMF84JRU *smf84jru;
  R84MEMJ2 *r84memj2;
  R84RSUJ2 *r84rsuj2;

  char *buffer_out;
  char *buffer_in;
  uint16_t smf84out_dcblrecl; // capacity of buffer_out
  uint16_t smf84in_dcblrecl; // capacity of buffer_in
  uint16_t n; // offset into buffer_out

  char fmt_buffer[5][16];

  int i;

  log_message("Entered format_records_json() ...");

  /* emit outer left bracket */
  smf84out_dcblrecl = put(smf84out_dcb, &buffer_out);
  n = 4 + snprintf(buffer_out + 4, smf84out_dcblrecl - 4, "[");
  memcpy(buffer_out, &n, sizeof(n));

  /* read records until EOF */
  while ((smf84in_dcblrecl = get(smf84in_dcb, &buffer_in)) != EOF) {

    records_count++;

    /* only look at SMF 84.21 records */
    smf84hdr = (SMF84HDR *) buffer_in;

    if ((smf84hdr -> SMF84RTY == 84) &&
        (smf84hdr -> SMF84STY == 21)) {

      log_message("  Record %d is an SMF 84.21 record", records_count);

      /* emit comma to separate records */
      if (records84_count++) {
        n += snprintf(buffer_out + n, smf84out_dcblrecl - n, ",");
        memcpy(buffer_out, &n, sizeof(n));

        smf84out_dcblrecl = put(smf84out_dcb, &buffer_out);
        n = 4 + snprintf(buffer_out + 4, smf84out_dcblrecl - 4, " ");
      }

      /* emit left brace */
      n += snprintf(buffer_out + n, smf84out_dcblrecl - n, "{");

      /* header section */
      n += snprintf(buffer_out + n, smf84out_dcblrecl - n,
        "\"SMF84HDR\": {");

      if (smf84fmt_opts & OPT_HEADER) {
        n += snprintf(buffer_out + n, smf84out_dcblrecl - n,
          "\"SMF84LEN\": %d, "
          "\"SMF84SEG\": %d, "
          "\"SMF84FLG\": \"%02X\", "
          "\"SMF84RTY\": %d, "
          "\"SMF84TME\": \"%s\", "
          "\"SMF84DTE\": \"%s\", "
          "\"SMF84SID\": \"%.4s\", "
          "\"SMF84SBS\": %d, "
          "\"SMF84SGN\": %d, "
          "\"SMF84FL1\": \"%02X\", "
          "\"SMF84VER\": %d, "
          "\"SMF84STY\": %d, "
          "\"SMF84TRN\": %d, "
          "\"SMF84PRS\": %d, "
          "\"SMF84PRL\": %d, "
          "\"SMF84PRN\": %d, "
          "\"SMF84GNS\": %d, "
          "\"SMF84GNL\": %d, "
          "\"SMF84GNN\": %d, "
          "\"SMF84J1O\": %d, "
          "\"SMF84J1L\": %d, "
          "\"SMF84J1N\": %d",
          smf84hdr -> SMF84LEN,
          smf84hdr -> SMF84SEG,
          smf84hdr -> SMF84FLG,
          smf84hdr -> SMF84RTY,
          format_smftime(fmt_buffer[0], smf84hdr -> SMF84TME),
          format_smfdate(fmt_buffer[1], smf84hdr -> SMF84DTE),
          rtrim(smf84hdr -> SMF84SID, 4),
          smf84hdr -> SMF84SBS,
          smf84hdr -> SMF84SGN,
          smf84hdr -> SMF84FL1,
          smf84hdr -> SMF84VER,
          smf84hdr -> SMF84STY,
          smf84hdr -> SMF84TRN,
          smf84hdr -> SMF84PRS,
          smf84hdr -> SMF84PRL,
          smf84hdr -> SMF84PRN,
          smf84hdr -> SMF84GNS,
          smf84hdr -> SMF84GNL,
          smf84hdr -> SMF84GNN,
          smf84hdr -> SMF84J1O,
          smf84hdr -> SMF84J1L,
          smf84hdr -> SMF84J1N);
      }
      n += snprintf(buffer_out + n, smf84out_dcblrecl - n, "},");
      memcpy(buffer_out, &n, sizeof(n));

      /* product section */
      smf84out_dcblrecl = put(smf84out_dcb, &buffer_out);
      n = 4 + snprintf(buffer_out + 4, smf84out_dcblrecl - 4,
        "  \"SMF84PRO\": {");

      if (smf84fmt_opts & OPT_PRODUCT) {
        smf84pro = (SMF84PRO *) \
          ((uint32_t) smf84hdr + (smf84hdr -> SMF84PRS));

        n += snprintf(buffer_out + n, smf84out_dcblrecl - n,
          "\"R84MFVER\": %d, "
          "\"R84PRDNM\": \"%.8s\", "
          "\"R84INTST\": \"%s\", "
          "\"R84SDATE\": \"%s\", "
          "\"R84INTEN\": \"%s\", "
          "\"R84EDATE\": \"%s\", "
          "\"R84INTER\": %d, "
          "\"R84MFCYC\": \"%s\", "
          "\"R84SAMPL\": %d, "
          "\"R84MFCMD\": \"%.80s\", "
          "\"R84MVSRL\": \"%.8s\", "
          "\"R84JESRL\": \"%.8s\", "
          "\"R84CPUM\": \"%.4s\", "
          "\"R84RSTO\": %d, "
          "\"R84CPUNM\": \"%.8s\", "
          "\"R84CPUID\": \"%.4s\", "
          "\"R84MPNAM\": \"%.8s\", "
          "\"R84J3FLG\": \"%02X\", "
          "\"R84JPRTY\": %d, "
          "\"R84JMFMN\": %d, "
          "\"R84JMFMX\": %d, "
          "\"R84JMFAV\": %d, "
          "\"R84MVSMN\": %d, "
          "\"R84MVSMX\": %d, "
          "\"R84MVSAV\": %d",
          smf84pro -> R84MFVER,
          rtrim(smf84pro -> R84PRDNM, 8),
          format_smftime2(fmt_buffer[0], smf84pro -> R84INTST),
          format_smfdate(fmt_buffer[1], smf84pro -> R84SDATE),
          format_smftime2(fmt_buffer[2], smf84pro -> R84INTEN),
          format_smfdate(fmt_buffer[3], smf84pro -> R84EDATE),
          smf84pro -> R84INTER,
          format_smftime3(fmt_buffer[4], smf84pro -> R84MFCYC),
          smf84pro -> R84SAMPL,
          rtrim(smf84pro -> R84MFCMD, 80),
          rtrim(smf84pro -> R84MVSRL, 8),
          rtrim(smf84pro -> R84JESRL, 8),
          rtrim(smf84pro -> R84CPUM, 4),
          smf84pro -> R84RSTO,
          rtrim(smf84pro -> R84CPUNM, 8),
          rtrim(smf84pro -> R84CPUID, 4),
          rtrim(smf84pro -> R84MPNAM, 8),
          smf84pro -> R84J3FLG,
          smf84pro -> R84JPRTY,
          smf84pro -> R84JMFMN,
          smf84pro -> R84JMFMX,
          smf84pro -> R84JMFAV,
          smf84pro -> R84MVSMN,
          smf84pro -> R84MVSMX,
          smf84pro -> R84MVSAV);
      }
      n += snprintf(buffer_out + n, smf84out_dcblrecl - n, "},");
      memcpy(buffer_out, &n, sizeof(n));

      /* general section */
      smf84out_dcblrecl = put(smf84out_dcb, &buffer_out);
      n = 4 + snprintf(buffer_out + 4, smf84out_dcblrecl - 4,
        "  \"SMF84GS\": {");

      if (smf84fmt_opts & OPT_GENERAL) {
        smf84gs = (SMF84GS *) \
          ((uint32_t) smf84hdr + (smf84hdr -> SMF84GNS));

        n += snprintf(buffer_out + n, smf84out_dcblrecl - n,
          "\"R84CPUSC\": %d, "
          "\"R84NPA\": %d, "
          "\"R84APA\": %d, "
          "\"R84NPNA,\": %d, "
          "\"R84APNA,\": %d, "
          "\"R84NNP\": %d, "
          "\"R84ANP\": %d, "
          "\"R84NNW\": %d, "
          "\"R84ANW\": %d, "
          "\"R84NSLLR\": %d, "
          "\"R84ASLLR\": %d, "
          "\"R84NSO\": %d, "
          "\"R84ASO\": %d",
          smf84gs -> R84CPUSC,
          smf84gs -> R84NPA,
          smf84gs -> R84APA,
          smf84gs -> R84NPNA,
          smf84gs -> R84APNA,
          smf84gs -> R84NNP,
          smf84gs -> R84ANP,
          smf84gs -> R84NNW,
          smf84gs -> R84ANW,
          smf84gs -> R84NSLLR,
          smf84gs -> R84ASLLR,
          smf84gs -> R84NSO,
          smf84gs -> R84ASO);
      }
      n += snprintf(buffer_out + n, smf84out_dcblrecl - n, "},");
      memcpy(buffer_out, &n, sizeof(n));

      /* JES2 section */
      smf84jru = (SMF84JRU *) \
        ((uint32_t) smf84hdr + (smf84hdr -> SMF84J1O));

      smf84out_dcblrecl = put(smf84out_dcb, &buffer_out);
      n = 4 + snprintf(buffer_out + 4, smf84out_dcblrecl - 4,
        "  \"SMF84JRU\": {");

      if (smf84fmt_opts & OPT_JES2) {
        n += snprintf(buffer_out + n, smf84out_dcblrecl - n,
          "\"R84J2RUL\": %d, "
          "\"R84J2RTR\": %d, "
          "\"R84J2RMO\": %d, "
          "\"R84J2RML\": %d, "
          "\"R84J2RMN\": %d, "
          "\"R84J2RRO\": %d, "
          "\"R84J2RRL\": %d, "
          "\"R84J2RRN\": %d",
          smf84jru -> R84J2RUL,
          smf84jru -> R84J2RTR,
          smf84jru -> R84J2RMO,
          smf84jru -> R84J2RML,
          smf84jru -> R84J2RMN,
          smf84jru -> R84J2RRO,
          smf84jru -> R84J2RRL,
          smf84jru -> R84J2RRN);
      }
      n += snprintf(buffer_out + n, smf84out_dcblrecl - n, "},");
      memcpy(buffer_out, &n, sizeof(n));

      /* storage usage sections */
      smf84out_dcblrecl = put(smf84out_dcb, &buffer_out);
      n = 4 + snprintf(buffer_out + 4, smf84out_dcblrecl - 4,
        "  \"SMF84MEM\": [");

      if (smf84fmt_opts & OPT_MEMORY) {
        r84memj2 = (R84MEMJ2 *) \
          ((uint32_t) smf84jru + (smf84jru -> R84J2RMO));

        for (i = 0; i < smf84jru -> R84J2RMN; i++) {
          /* emit comma/newline to separate regions */
          if (i) {
            n += snprintf(buffer_out + n, smf84out_dcblrecl - n, ",");
            memcpy(buffer_out, &n, sizeof(n));

            smf84out_dcblrecl = put(smf84out_dcb, &buffer_out);
            n = 4 + snprintf(buffer_out + 4, smf84out_dcblrecl - 4,
              "               ");
          }
          n += snprintf(buffer_out + n, smf84out_dcblrecl - n,
            "{"
            "\"R84MEM_NAME\": \"%.12s\", "
            "\"R84MEM_REGION\": %lld, "
            "\"R84MEM_USE\": %lld, "
            "\"R84MEM_LOW\": %lld, "
            "\"R84MEM_HIGH\": %lld, "
            "\"R84MEM_AVERAGE\": %lld"
            "}",
            rtrim(r84memj2 -> R84MEM_NAME, R84MEM_NAME_SIZE),
            r84memj2 -> R84MEM_REGION,
            r84memj2 -> R84MEM_USE,
            r84memj2 -> R84MEM_LOW,
            r84memj2 -> R84MEM_HIGH,
            r84memj2 -> R84MEM_AVERAGE);

          r84memj2 = (R84MEMJ2 *) \
            ((uint32_t) r84memj2 + (smf84jru -> R84J2RML));
        }
      }
      n += snprintf(buffer_out + n, smf84out_dcblrecl - n, "],");
      memcpy(buffer_out, &n, sizeof(n));

      /* resource usage sections */
      smf84out_dcblrecl = put(smf84out_dcb, &buffer_out);
      n = 4 + snprintf(buffer_out + 4, smf84out_dcblrecl - 4,
        "  \"SMF84RSU\": [");

      if (smf84fmt_opts & OPT_RESOURCE) {
        r84rsuj2 = (R84RSUJ2 *) \
          ((uint32_t) smf84jru + (smf84jru -> R84J2RRO));

        for (i = 0; i < smf84jru -> R84J2RRN; i++) {
          /* emit comma/newline to separate resources */
          if (i) {
            n += snprintf(buffer_out + n, smf84out_dcblrecl - n, ",");
            memcpy(buffer_out, &n, sizeof(n));

            smf84out_dcblrecl = put(smf84out_dcb, &buffer_out);
            n = 4 + snprintf(buffer_out + 4, smf84out_dcblrecl - 4,
              "               ");
          }
          n += snprintf(buffer_out + n, smf84out_dcblrecl - n,
            "{"
            "\"R84RSU_NAME\": \"%.8s\", "
            "\"R84RSU_LIMIT\": %d, "
            "\"R84RSU_INUSE\": %d, "
            "\"R84RSU_LOW\": %d, "
            "\"R84RSU_HIGH\": %d, "
            "\"R84RSU_WARN\": %d, "
            "\"R84RSU_FLG1\": \"%02X\","
            "\"R84RSU_OVER\": %d, "
            "\"R84RSU_AVERAGE\": %d"
            "}",
            rtrim(r84rsuj2 -> R84RSU_NAME, R84RSU_NAME_SIZE),
            r84rsuj2 -> R84RSU_LIMIT,
            r84rsuj2 -> R84RSU_INUSE,
            r84rsuj2 -> R84RSU_LOW,
            r84rsuj2 -> R84RSU_HIGH,
            r84rsuj2 -> R84RSU_WARN,
            r84rsuj2 -> R84RSU_FLG1,
            r84rsuj2 -> R84RSU_OVER,
            r84rsuj2 -> R84RSU_AVERAGE);

          r84rsuj2 = (R84RSUJ2 *) \
            ((uint32_t) r84rsuj2 + (smf84jru -> R84J2RRL));
        }
      }
      n += snprintf(buffer_out + n, smf84out_dcblrecl - n, "]");
      memcpy(buffer_out, &n, sizeof(n));

      /* emit right brace */
      smf84out_dcblrecl = put(smf84out_dcb, &buffer_out);
      n = 4 + snprintf(buffer_out + 4, smf84out_dcblrecl - 4, " }");
      memcpy(buffer_out, &n, sizeof(n));
    }
  }

  /* emit outer left bracket */
  smf84out_dcblrecl = put(smf84out_dcb, &buffer_out);
  n = 4 + snprintf(buffer_out + 4, smf84out_dcblrecl - 4, "]");
  memcpy(buffer_out, &n, sizeof(n));

  log_message("  Read %d records (%d SMF 84.21 records) from SMF84IN",
    records_count, records84_count);
  log_message("Leaving format_records_json() ...");

  return format_records_rc;
}

/*********************************************************************/
/* Record formatting - misc                                          */
/*********************************************************************/

static char *rtrim(char *str, size_t length) {
  /*
  Remove trailing whitespace from the given string.
  */
  while(length && isspace(str[--length]))
    str[length] = '\0';

  return str;
}

static char *format_smftime(char buffer[16], uint32_t smftime) {
  /*
  Converts time in terms of hundreds of seconds elapsed since midnight
  into a human-readable string of the form HH:MM:SS.hh .
  */
  unsigned int seconds;
  unsigned int minutes;
  unsigned int hours;

  /* convert hundreds of seconds into seconds */
  seconds = smftime / 100;

  /* compute number of hours since midnight */
  hours = seconds / 3600;
  seconds -= 3600 * hours;

  /* compute number of minutes since start of hour */
  minutes = seconds / 60;

  /* compute number of seconds since start of minute */
  seconds -= 60 * minutes;

  /* format time string into given buffer */
  snprintf(buffer, 16, "%02.2d:%02.2d:%02.2d.%02.2d",
    hours, minutes, seconds, smftime % 100);

  return buffer;
}

static char *format_smftime2(char buffer[16], uint32_t smftime) {
  /*
  Converts a time in the form 0xHHMMSSTF into a human-readable string
  of the form "HH:MM:SS.hh".
  */
  unsigned int tseconds;
  unsigned int seconds;
  unsigned int minutes;
  unsigned int hours;

  /* SMF times are such a pain */
  tseconds = 10 * ((smftime >>  4) & 0x0F);
  seconds  =  1 * ((smftime >>  8) & 0x0F) +
             10 * ((smftime >> 12) & 0x0F);
  minutes  =  1 * ((smftime >> 16) & 0x0F) +
             10 * ((smftime >> 20) & 0x0F);
  hours    =  1 * ((smftime >> 24) & 0x0F);
             10 * ((smftime >> 28) & 0x0F);

  /* format time string into given buffer */
  snprintf(buffer, 16, "%02.2d:%02.2d:%02.2d.%02.2d",
    hours, minutes, seconds, tseconds);

  return buffer;
}

static char *format_smftime3(char buffer[16], uint32_t smftime) {
  /*
  Converts a time in the form 0x00SSSTTF into a human-readable string
  of the form "HH:MM:SS.hh".
  */
  unsigned int hseconds;
  unsigned int seconds;
  unsigned int minutes = 0;
  unsigned int hours = 0;

  /* SMF times are such a pain */
  hseconds =   1 * ((smftime >>  4) & 0x0F) +
              10 * ((smftime >>  8) & 0x0F);
  seconds  =   1 * ((smftime >> 12) & 0x0F) +
              10 * ((smftime >> 16) & 0x0F) +
             100 * ((smftime >> 20) & 0x0F);

  /* minutes */
  while (seconds >= 60) {
    minutes += 1;
    seconds -= 60;
  }

  /* format time string into given buffer */
  snprintf(buffer, 16, "%02.2d:%02.2d:%02.2d.%02.2d",
    hours, minutes, seconds, hseconds);

  return buffer;
}

static char *format_smfdate(char buffer[16], uint32_t smfdate) {
  /*
  Converts a date record of the form 0x0YYYDDDF into a human-readable
  string of the form "YYYY/MM/DD".
  */
  unsigned int year;
  unsigned int month;
  unsigned int day;

  int month_days[12] = {31,28,31,30,31,30,31,31,30,31,30,31};

  /* convert hex year into decimal */
  year = 1900 + 100 * ((smfdate >> 24) & 0x0F) +
                 10 * ((smfdate >> 20) & 0x0F) +
                  1 * ((smfdate >> 16) & 0x0F);

  /* convert hex day into decimal */
  day = 100 * ((smfdate >> 12) & 0x0F) +
         10 * ((smfdate >>  8) & 0x0F) +
          1 * ((smfdate >>  4) & 0x0F);

  /* convert julian date into sane date */
  if ((year % 4 == 0) && ((year % 100 == 0) && (year % 400 == 0)))
    month_days[1] += 1;

  for (month = 0; (day > month_days[month]) && (month < 12); month++)
    day -= month_days[month];

  /* format date string into given buffer */
  snprintf(buffer, 16, "%02.2d/%02.2d/%02.2d", year, 1 + month, day);

  return buffer;
}

/*********************************************************************/
/* Assembly - misc                                                   */
/*********************************************************************/

static void *obtain24(size_t size, int subpool) {
  /*
  Obtain 24-bit storage. Also initializes it to nulls.
  */
  void *obtain_ptr;

  /* GETMAIN the storage */
  __asm(" STORAGE OBTAIN"
        ",ADDR=%0"
        ",LENGTH=(%1)"
        ",LOC=24"
        ",SP=(%2)"
        // output
        : "+m"(obtain_ptr)
        // input
        : "r"(size),
          "r"(subpool)
        // clobbers
        : "r0", "r1", "r14", "r15"
        );

  /* initialize to 0s */
  memset(obtain_ptr, 0, size);

  return obtain_ptr;
}

static void release24(void *ptr, size_t size, int subpool) {
  /*
  Release 24-bit storage.
  */
  void *obtain_ptr;

  /* GETMAIN the storage */
  __asm(" STORAGE RELEASE"
        ",ADDR=%0"
        ",LENGTH=(%1)"
        ",SP=(%2)"
        // output
        : "+m"(ptr)
        // input
        : "r"(size),
          "r"(subpool)
        // clobbers
        : "r0", "r1", "r14", "r15"
        );

  //issue_wto("obtain_rc = %d", obtain_rc);
}

static void log_message(const char *fmt, ...) {
  /*
  Log a message to the SYSPRINT dataset. Arguments are substituted into
  a format string using vsnprintf(). Message length is limited to the
  LRECL of the SYSPRINT dataset, minus 4 bytes for the RCB.
  */
  uint16_t sysprint_dcblrecl;
  uint16_t n = 4;

  char datetime[16];

  va_list args;

  /* check that SYSPRINT is open */
  if (sysprint_dcb) {

    /* obtain the next output buffer */
    sysprint_dcblrecl = put(sysprint_dcb, &sysprint_buffer);
    memset(sysprint_buffer, 0, sysprint_dcblrecl);

    /* prepend message with a timestamp */
    /*
    __asm(" TIME MIC,%0,LINKAGE=SYSTEM,DATETYPE=DDMMYYYY"
          : : "=m"(datetime));
    */

    /* do substitions - silent truncation */
    va_start(args, fmt);
    n = MIN(sysprint_dcblrecl, n + vsnprintf(sysprint_buffer + n,
      sysprint_dcblrecl - n, fmt, args));
    va_end(args);

    /* set length of the record */
    memcpy(sysprint_buffer, &n, sizeof(n));
  }
}

/*********************************************************************/
/* Assembly - I/O                                                    */
/*********************************************************************/

static int32_t open_read(DCB *dcb) {
  /*
  OPEN a dataset for INPUT given a pointer to a DCB.
  */
  int32_t open_rc;

  /* define and copy in OPEN parameter list */
  __asm(" OPEN (,),MF=L" : "DS"(open_parm_ds));
  open_parm_ds = OPEN_PARM_DS;

  /* OPEN the dataset */
  __asm(" OPEN ((%1),INPUT),MODE=31,MF=(E,(%2))\n"
        " ST 15,%0"
        // output
        : "=m"(open_rc)
        // input
        : "r"(dcb),
          "r"(&open_parm_ds)
        // clobbers
        : "r0", "r1", "r14", "r15"
        );

  //issue_wto("open_rc = %d", open_rc);

  return open_rc;
}

static int32_t open_write(DCB *dcb) {
  /*
  OPEN a dataset for OUTPUT given a pointer to a DCB.
  */
  int32_t open_rc;

  /* define and copy in OPEN parameter list */
  __asm(" OPEN (,),MF=L" : "DS"(open_parm_ds));
  open_parm_ds = OPEN_PARM_DS;

  /* OPEN the dataset */
  __asm(" OPEN ((%1),OUTPUT),MODE=31,MF=(E,(%2))\n"
        " ST 15,%0"
        // output
        : "=m"(open_rc)
        // input
        : "r"(dcb),
          "r"(&open_parm_ds)
        // clobbers
        : "r0", "r1", "r14", "r15"
        );

  //issue_wto("open_rc = %d", open_rc);

  return open_rc;
}

static int32_t close(DCB *dcb) {
  /*
  CLOSE a dataset given a pointer to a DCB.
  */
  int32_t close_rc;

  /* define and copy in CLOSE parameter list */
  __asm(" CLOSE (,),MF=L" : "DS"(close_parm_ds));
  close_parm_ds = CLOSE_PARM_DS;

  /* CLOSE the dataset */
  __asm(" CLOSE ((%1),FREE),MODE=31,MF=(E,(%2))\n"
        " ST 15,%0"
        // output
        : "=m"(close_rc)
        // input
        : "r"(dcb),
          "r"(&close_parm_ds)
        // clobbers
        : "r0", "r1", "r14", "r15"
        );

  return close_rc;
}

static uint16_t put(DCB *dcb, char **buffer) {
  /*
  Performs a locate-mode PUT to the given DCB. Pointer to the buffer is
  returned in buffer. Returns the buffer length (DCBLRECL). Copies the
  length of the record into the RCB.
  */
  uint16_t dcblrecl;

  /* locate-mode PUT */
  __asm(" PUSH USING\n"
        " USING IHADCB,%1\n"
        " PUT (%1)\n"
        " MVC 0(2,(%2)),DCBLRECL\n"
        " ST 1,%0\n"
        " POP USING"
        // output
        : "+m"(*buffer)
        // input
        : "r"(dcb),
          "r"(&dcblrecl)
        // clobbers
        : "r0", "r1", "r14", "r15"
        );

  //issue_wto("dcblrecl = %d", dcblrecl);

  return dcblrecl;
}

static uint16_t get(DCB *dcb, char **buffer) {
  /*
  Performs a locate-mode GET from the given DCB. Pointer to the buffer
  is returned in buffer. Returns the buffer length (DCBLRECL). If the
  end of file is encountered, returns -1.
  */
  uint16_t dcblrecl = EOF;

  __asm(" PUSH USING\n"
        " USING IHADCB,%1\n"
        " GET (%1)\n"
        " MVC 0(2,(%2)),DCBLRECL\n"
        " ST 1,%0\n"
        " POP USING"
        // output
        : "+m"(*buffer)
        // input
        : "r"(dcb),
          "r"(&dcblrecl)
        // clobbers
        : "r0", "r1", "r14", "r15"
        );

  __asm("GET_EOF EQU *");

  return dcblrecl;
}

static int32_t issue_wto(const char *fmt, ...) {
  /*
  Issue a WTO to the console. Arguments are substituted into a format
  string using vsnprintf(). Message is truncated to 80 characters.
  */
  int32_t wto_rc;

  char wto_msg_text[WTO_MAX + 1];
  Wto wto_msg;
  va_list args;

  char jobname[16];

  /* define and copy in WTO parameter list */
  __asm(" WTO TEXT=(0),MF=L" : "DS"(wto_parm_ds));
  wto_parm_ds = WTO_PARM_DS;

  /* do substitions and package message for WTO - silent truncation */
  va_start(args, fmt);
  vsnprintf(wto_msg_text, WTO_MAX, fmt, args);
  va_end(args);

  /* get the jobname that this program is running under */

  /* prepend message with SMF84FMT */
  wto_msg.length = MIN(snprintf(wto_msg.text, WTO_MAX, "SMF84FMT: %s",
                    wto_msg_text), WTO_MAX);

  /* issue the WTO */
  __asm(" WTO TEXT=%1,MF=(E,(%2))\n"
        " ST 15,%0"
        // output
        : "=m"(wto_rc)
        // input
        : "m"(wto_msg),
          "r"(&wto_parm_ds)
        // clobbers
        : "r0", "r1", "r14", "r15"
        );

  return wto_rc;
}

