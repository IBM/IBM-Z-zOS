/*
 * Copyright 2022, IBM Corporation
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
#include <stdlib.h>
#include <stddef.h>
#include <string.h>
#include <strings.h>
#include <ctype.h>
#include <stdio.h>
#include <unistd.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <time.h>
#include <sys/time.h>

/*
 * Declare some structures for R_PKIServ callable service
 */
typedef struct _triplet {
    char            fieldName[12];
    u_int           dlen;
    char            data[1];
} triplet;

typedef struct _certID {
    char            len;
    char            data[80];
} certID;

typedef struct _gencertFSPL {
    char            eye[8];
    int             certPlistLen;
    char          * certPlist;
    certID        * certid;
} gencertFSPL;

typedef struct _keyID {
    char            len;
    char            data[40];
} keyID;

typedef struct _exportFSPL {
    char            eye[8];
    int             certBufLen;
    char          * certBuf;
    certID        * certid;
    keyID         * keyid;
} exportFSPL;


/*
 * Global varaibles
 */
int         verbose;
int         quiet;

/*
 * Local function prototypes
 */
void       displayCPL(char * cpl, int cpllen);
void       updateCPL(char * data, unsigned int * len, char * value);
void       usage(char * pgmname);

#pragma map(rpkiserv, "IRRSPX00")
#pragma linkage(rpkiserv, OS)
int rpkiserv( void    * workarea
            , u_int   * alet1
            , u_int   * safrc
            , u_int   * alet2
            , u_int   * racfrc
            , u_int   * alet3
            , u_int   * racfrsn
            , u_int   * numparms
            , short   * fc
            , u_int   * attrs
            , char    * logstr
            , u_int   * plver
            , void    * fspl
            , char    * domain
            );

/*
 * Handy macros
 */
#ifndef max
#define max(a,b) (((a) > (b)) ? (a) : (b))
#endif

#ifndef min
#define min(a,b) (((a) < (b)) ? (a) : (b))
#endif

#define HEXDUMP(title, ptr, len) { \
   int i; \
   printf("%s\n", title); \
   for(i=0; i < len; i++) { \
      if ((i%32) == 0) printf("\n+%4.4x", i); \
      if ((i%4) == 0) printf(" "); \
      printf("%2.2x", ptr[i]); \
   } \
   printf("\n"); \
}

#define MAXCPSIZE    65536
#define MAXCSRSIZE   4096

/*
 * Local constants
 */
#define GENCERT     0x0001
#define EXPORT      0x0002

/*
 * GENCERT parameters
*/
#define SN   0
#define UA   1
#define UN   2
#define EA   3
#define M    4
#define DQ   5
#define UID  6
#define CN   7
#define T    8
#define DN   9
#define OU   10
#define BC   11
#define O    12
#define JL   13
#define JS   14
#define JC   15
#define ST   16
#define L    17
#define SP   18
#define PC   19
#define C    20
#define IP   21
#define URI  22
#define AE   23
#define DOM  24
#define AO   25
#define KU   26
#define XKU  27
#define HIM  28
#define CP   29
#define AIA  30
#define CE   31
#define CRIT 32
#define PP   33
#define NB   34
#define NA   35
#define NE   36
#define USR  37
#define RQ   38
#define KA   39
#define KS   40

char * const opts[] = {
   "sn"
 , "ua"
 , "un"
 , "ea"
 , "m"
 , "dq"
 , "uid"
 , "cn"
 , "t"
 , "dn"
 , "ou"
 , "bc"
 , "o"
 , "jl"
 , "js"
 , "jc"
 , "st"
 , "l"
 , "sp"
 , "pc"
 , "c"
 , "ip"
 , "uri"
 , "ae"
 , "dom"
 , "ao"
 , "ku"
 , "xku"
 , "him"
 , "cp"
 , "aia"
 , "ce"
 , "crit"
 , "pp"
 , "nb"
 , "na"
 , "ne"
 , "usr"
 , "rq"
 , "ka"
 , "ks"
 , NULL
};

const char Requestor[12]    = "Requestor   ";
const char PassPhrase[12]   = "PassPhrase  ";
const char SerialNumber[12] = "SerialNumber";
const char UnstructAddr[12] = "UnstructAddr";
const char UnstructName[12] = "UnstructName";
const char EmailAddr[12]    = "EmailAddr   ";
const char Mail[12]         = "Mail        ";
const char DNQualifier[12]  = "DNQualifier ";
const char Uid[12]          = "Uid         ";
const char CommonName[12]   = "CommonName  ";
const char Title[12]        = "Title       ";
const char DomainName[12]   = "DomainName  ";
const char OrgUnit[12]      = "OrgUnit     ";
const char Org[12]          = "Org         ";
const char Street[12]       = "Street      ";
const char Locality[12]     = "Locality    ";
const char StateProv[12]    = "StateProv   ";
const char PostalCode[12]   = "PostalCode  ";
const char Country[12]      = "Country     ";
const char AltIPAddr[12]    = "AltIPAddr   ";
const char AltURI[12]       = "AltURI      ";
const char AltEmail[12]     = "AltEmail    ";
const char AltDomain[12]    = "AltDomain   ";
const char AltOther[12]     = "AltOther    ";
const char KeyUsage[12]     = "KeyUsage    ";
const char ExtKeyUsage[12]  = "ExtKeyUsage ";
const char KeySize[12]      = "KeySize     ";
const char NotBefore[12]    = "NotBefore   ";
const char NotAfter[12]     = "NotAfter    ";
const char NotifyEmail[12]  = "NotifyEmail ";
const char UserId[12]       = "UserId      ";
const char HostIdMap[12]    = "HostIdMap   ";
const char CertPolicies[12] = "CertPolicies";
const char AuthInfoAcc[12]  = "AuthInfoAcc ";
const char Critical[12]     = "Critical    ";
const char CustomExt[12]    = "CustomExt   ";
const char Email[12]        = "Email       ";
const char SignWith[12]     = "SignWith    ";
const char Label[12]        = "Label       ";
const char KeyAlg[12]       = "KeyAlg      ";
const char BusinessCat[12]  = "BusinessCat ";
const char JurCountry[12]   = "JurCountry  ";
const char JurStateProv[12] = "JurStateProv";
const char JurLocality[12]  = "JurLocality ";

const char begin[] = "-----BEGIN CERTIFICATE-----\n";
const char end[]   = "-----END CERTIFICATE-----\n";


/*
 * Start of program
 */
int main(int argc, char ** argv) {
  char                  workarea[1024];
  u_int                 alet;
  u_int                 safrc;
  u_int                 racfrc;
  u_int                 racfrsn;
  int                   rc;
  short                 fc;
  u_int                 attrs;
  u_int                 vers;
  u_int                 numparms;
  char                  logString[80];
  char                  tbuf[200];
  char                * certPList;
  char                * diagInfo = NULL;
  u_int               * diagInfoLen = NULL;
  gencertFSPL           fspl;
  certID                cid;
  char                * p10buf = NULL;
  u_int                 p10buflen = 0;
  char                * certbuf = NULL;
  exportFSPL            xfspl;
  keyID                 kid;
  int                   i;
  int                   z;
  char                * cp;
  char                * ptr;
  char                * p;
  char                  pp[33];
  u_int                 pplen = 0;
  int                   c;
  char                * subopts = NULL;
  char                * retval  = NULL;
  char                  domName[9];
  char                  tmplName[9];
  u_int                 gcpLen = 0;
  triplet             * gcp = NULL;
  u_int                 status;
  char                * semi;
  int                   dashs = 0;
  int                   dashK = 0;
  int                   dashc = 0;
  char                * ifn  = NULL;
  FILE                * fptr = NULL;
  int                   readlen = 0;
  char                * certfn  = NULL;
  FILE                * certfp = NULL;
  int                   isBase64 = 0;
  char                  wmode[3];
  struct stat           info;
  struct timeval        tvs,
                        tvf;
  struct timezone       tzs,
                        tzf;
  u_int                 pkikeygen = 0;
  verbose = 0;
  quiet = 0;
  bzero(tmplName, sizeof(tmplName));
  bzero(&fspl, sizeof(fspl));
  bzero(&cid, sizeof(cid));
  bzero(&kid, sizeof(kid));
  bzero(wmode, sizeof(wmode));
  bzero(pp, sizeof(pp));
  bzero(logString, sizeof(logString));
  memset(domName, 0x00, sizeof(domName));

  if (NULL == (certPList=(char*)malloc(MAXCPSIZE))) {
     printf("\nmalloc of certPlist failed, see ya\n");
     return(1);
  }

  fc = GENCERT;

  attrs = 0x80000000;

  /*
   * Setup the CertPList and add the required first
   * entry: DiagInfo as an 80 byte record
   */
  gcp = (triplet *)certPList;
  gcpLen = 0;
  memcpy(gcp->fieldName, "DiagInfo    ", 12);
  gcp->dlen = 80;
  memset(gcp->data, 0x00, 80);
  memcpy(gcp->data, "GENCERT", 8);
  diagInfoLen = &gcp->dlen;
  diagInfo = gcp->data;
  gcpLen += 96;
  gcp = (triplet *)(certPList+gcpLen);

  /*
   * Now parse the input parameters
   */
  optind   = 1; /* start getopt() scan at beginning of argv */
  opterr   = 1;
  optopt   = 0;
  while ((c = getopt(argc, argv, ":c:t:K:D:s:v")) != EOF) {
     switch (c) {
      case 'c':
          if ((optarg != NULL) && (optarg[0] != '-')) {
             dashc = 1;
             subopts = optarg;
             while(*subopts != '\0') {
                switch(getsubopt(&subopts, opts, &retval)) {
                  case CN:
                     if (retval == NULL) {
                        printf( "Syntax error: %s requires a value!\n"
                              , opts[CN]);
                        usage(argv[0]);
                        return(1);
                     }
                     memcpy(gcp->fieldName, CommonName, 12);
                     if (MAXCPSIZE < gcpLen + strlen(retval)) {
                        printf("Wow!, ran out of room in certPList(%d)"
                               ", see ya!\n", MAXCPSIZE);
                        return(1);
                     }
                     updateCPL(gcp->data, &(gcp->dlen), retval);
                     gcpLen += 12 + sizeof(gcp->dlen) + gcp->dlen;
                     gcp = (triplet *)(certPList+gcpLen);
                     break;
                  case PP:
                     if (retval == NULL) {
                        printf( "Syntax error: %s requires a value!\n"
                              , opts[PP]);
                        usage(argv[0]);
                        return(1);
                     }
                     memcpy(gcp->fieldName, PassPhrase, 12);
                     if (MAXCPSIZE < gcpLen + strlen(retval)) {
                        printf("Wow!, ran out of room in certPList(%d)"
                               ", see ya!\n", MAXCPSIZE);
                        return(1);
                     }
                     updateCPL(gcp->data, &(gcp->dlen), retval);
                     gcpLen += 12 + sizeof(gcp->dlen) + gcp->dlen;
                     gcp = (triplet *)(certPList+gcpLen);
                     updateCPL(pp, &pplen, retval);
                     break;
                  case SN:
                     if (retval == NULL) {
                        printf( "Syntax error: %s requires a value!\n"
                              , opts[SN]);
                        usage(argv[0]);
                        return(1);
                     }
                     memcpy(gcp->fieldName, SerialNumber, 12);
                     if (MAXCPSIZE < gcpLen + strlen(retval)) {
                        printf("Wow!, ran out of room in certPList(%d)"
                               ", see ya!\n", MAXCPSIZE);
                        return(1);
                     }
                     updateCPL(gcp->data, &(gcp->dlen), retval);
                     gcpLen += 12 + sizeof(gcp->dlen) + gcp->dlen;
                     gcp = (triplet *)(certPList+gcpLen);
                     break;
                  case UA:
                     if (retval == NULL) {
                        printf( "Syntax error: %s requires a value!\n"
                              , opts[UA]);
                        usage(argv[0]);
                        return(1);
                     }
                     memcpy(gcp->fieldName, UnstructAddr, 12);
                     if (MAXCPSIZE < gcpLen + strlen(retval)) {
                        printf("Wow!, ran out of room in certPList(%d)"
                               ", see ya!\n", MAXCPSIZE);
                        return(1);
                     }
                     updateCPL(gcp->data, &(gcp->dlen), retval);
                     gcpLen += 12 + sizeof(gcp->dlen) + gcp->dlen;
                     gcp = (triplet *)(certPList+gcpLen);
                     break;
                  case UN:
                     if (retval == NULL) {
                        printf( "Syntax error: %s requires a value!\n"
                              , opts[UA]);
                        usage(argv[0]);
                        return(1);
                     }
                     memcpy(gcp->fieldName, UnstructName, 12);
                     if (MAXCPSIZE < gcpLen + strlen(retval)) {
                        printf("Wow!, ran out of room in certPList(%d)"
                               ", see ya!\n", MAXCPSIZE);
                        return(1);
                     }
                     updateCPL(gcp->data, &(gcp->dlen), retval);
                     gcpLen += 12 + sizeof(gcp->dlen) + gcp->dlen;
                     gcp = (triplet *)(certPList+gcpLen);
                     break;
                  case EA:
                     if (retval == NULL) {
                        printf( "Syntax error: %s requires a value!\n"
                              , opts[EA]);
                        usage(argv[0]);
                        return(1);
                     }
                     memcpy(gcp->fieldName, EmailAddr, 12);
                     if (MAXCPSIZE < gcpLen + strlen(retval)) {
                        printf("Wow!, ran out of room in certPList(%d)"
                               ", see ya!\n", MAXCPSIZE);
                        return(1);
                     }
                     updateCPL(gcp->data, &(gcp->dlen), retval);
                     gcpLen += 12 + sizeof(gcp->dlen) + gcp->dlen;
                     gcp = (triplet *)(certPList+gcpLen);
                     break;
                  case M:
                     if (retval == NULL) {
                        printf( "Syntax error: %s requires a value!\n"
                              , opts[M]);
                        usage(argv[0]);
                        return(1);
                     }
                     memcpy(gcp->fieldName, Mail, 12);
                     if (MAXCPSIZE < gcpLen + strlen(retval)) {
                        printf("Wow!, ran out of room in certPList(%d)"
                               ", see ya!\n", MAXCPSIZE);
                        return(1);
                     }
                     updateCPL(gcp->data, &(gcp->dlen), retval);
                     gcpLen += 12 + sizeof(gcp->dlen) + gcp->dlen;
                     gcp = (triplet *)(certPList+gcpLen);
                     break;
                  case DQ:
                     if (retval == NULL) {
                        printf( "Syntax error: %s requires a value!\n"
                              , opts[DQ]);
                        usage(argv[0]);
                        return(1);
                     }
                     memcpy(gcp->fieldName, DNQualifier, 12);
                     if (MAXCPSIZE < gcpLen + strlen(retval)) {
                        printf("Wow!, ran out of room in certPList(%d)"
                               ", see ya!\n", MAXCPSIZE);
                        return(1);
                     }
                     updateCPL(gcp->data, &(gcp->dlen), retval);
                     gcpLen += 12 + sizeof(gcp->dlen) + gcp->dlen;
                     gcp = (triplet *)(certPList+gcpLen);
                     break;
                  case UID:
                     if (retval == NULL) {
                        printf( "Syntax error: %s requires a value!\n"
                              , opts[UID]);
                        usage(argv[0]);
                        return(1);
                     }
                     memcpy(gcp->fieldName, Uid, 12);
                     if (MAXCPSIZE < gcpLen + strlen(retval)) {
                        printf("Wow!, ran out of room in certPList(%d)"
                               ", see ya!\n", MAXCPSIZE);
                        return(1);
                     }
                     updateCPL(gcp->data, &(gcp->dlen), retval);
                     gcpLen += 12 + sizeof(gcp->dlen) + gcp->dlen;
                     gcp = (triplet *)(certPList+gcpLen);
                     break;
                  case DN:
                     if (retval == NULL) {
                        printf( "Syntax error: %s requires a value!\n"
                              , opts[DQ]);
                        usage(argv[0]);
                        return(1);
                     }
                     memcpy(gcp->fieldName, DomainName, 12);
                     if (MAXCPSIZE < gcpLen + strlen(retval)) {
                        printf("Wow!, ran out of room in certPList(%d)"
                               ", see ya!\n", MAXCPSIZE);
                        return(1);
                     }
                     updateCPL(gcp->data, &(gcp->dlen), retval);
                     gcpLen += 12 + sizeof(gcp->dlen) + gcp->dlen;
                     gcp = (triplet *)(certPList+gcpLen);
                     break;
                  case T:
                     if (retval == NULL) {
                        printf( "Syntax error: %s requires a value!\n"
                              , opts[T]);
                        usage(argv[0]);
                        return(1);
                     }
                     memcpy(gcp->fieldName, Title, 12);
                     if (MAXCPSIZE < gcpLen + strlen(retval)) {
                        printf("Wow!, ran out of room in certPList(%d)"
                               ", see ya!\n", MAXCPSIZE);
                        return(1);
                     }
                     updateCPL(gcp->data, &(gcp->dlen), retval);
                     gcpLen += 12 + sizeof(gcp->dlen) + gcp->dlen;
                     gcp = (triplet *)(certPList+gcpLen);
                     break;
                  case OU:
                     if (retval == NULL) {
                        printf( "Syntax error: %s requires a value!\n"
                              , opts[OU]);
                        usage(argv[0]);
                        return(1);
                     }
                     memcpy(gcp->fieldName, OrgUnit, 12);
                     if (MAXCPSIZE < gcpLen + strlen(retval)) {
                        printf("Wow!, ran out of room in certPList(%d)"
                               ", see ya!\n", MAXCPSIZE);
                        return(1);
                     }
                     updateCPL(gcp->data, &(gcp->dlen), retval);
                     gcpLen += 12 + sizeof(gcp->dlen) + gcp->dlen;
                     gcp = (triplet *)(certPList+gcpLen);
                     break;
                  case O:
                     if (retval == NULL) {
                        printf("Syntax error: %s requires a value!\n"
                              , opts[O]);
                        usage(argv[0]);
                        return(1);
                     }
                     memcpy(gcp->fieldName, Org, 12);
                     if (MAXCPSIZE < gcpLen + strlen(retval)) {
                        printf("Wow!, ran out of room in certPList(%d)"
                               ", see ya!\n", MAXCPSIZE);
                        return(1);
                     }
                     updateCPL(gcp->data, &(gcp->dlen), retval);
                     gcpLen += 12 + sizeof(gcp->dlen) + gcp->dlen;
                     gcp = (triplet *)(certPList+gcpLen);
                     break;
                  case ST:
                     if (retval == NULL) {
                        printf("Syntax error: %s requires a value!\n"
                              , opts[ST]);
                        usage(argv[0]);
                        return(1);
                     }
                     memcpy(gcp->fieldName, Street, 12);
                     if (MAXCPSIZE < gcpLen + strlen(retval)) {
                        printf("Wow!, ran out of room in certPList(%d)"
                               ", see ya!\n", MAXCPSIZE);
                        return(1);
                     }
                     updateCPL(gcp->data, &(gcp->dlen), retval);
                     gcpLen += 12 + sizeof(gcp->dlen) + gcp->dlen;
                     gcp = (triplet *)(certPList+gcpLen);
                     break;
                  case L:
                     if (retval == NULL) {
                        printf( "Syntax error: %s requires a value!\n"
                              , opts[L]);
                        usage(argv[0]);
                        return(1);
                     }
                     memcpy(gcp->fieldName, Locality, 12);
                     if (MAXCPSIZE < gcpLen + strlen(retval)) {
                        printf("Wow!, ran out of room in certPList(%d)"
                               ", see ya!\n", MAXCPSIZE);
                        return(1);
                     }
                     updateCPL(gcp->data, &(gcp->dlen), retval);
                     gcpLen += 12 + sizeof(gcp->dlen) + gcp->dlen;
                     gcp = (triplet *)(certPList+gcpLen);
                     break;
                  case SP:
                     if (retval == NULL) {
                        printf( "Syntax error: %s requires a value!\n"
                              , opts[SP]);
                        usage(argv[0]);
                        return(1);
                     }
                     memcpy(gcp->fieldName, StateProv, 12);
                     if (MAXCPSIZE < gcpLen + strlen(retval)) {
                        printf("Wow!, ran out of room in certPList(%d)"
                               ", see ya!\n", MAXCPSIZE);
                        return(1);
                     }
                     updateCPL(gcp->data, &(gcp->dlen), retval);
                     gcpLen += 12 + sizeof(gcp->dlen) + gcp->dlen;
                     gcp = (triplet *)(certPList+gcpLen);
                     break;
                  case PC:
                     if (retval == NULL) {
                        printf("Syntax error: %s requires a value!\n"
                              , opts[PC]);
                        usage(argv[0]);
                        return(1);
                     }
                     memcpy(gcp->fieldName, PostalCode, 12);
                     if (MAXCPSIZE < gcpLen + strlen(retval)) {
                        printf("Wow!, ran out of room in certPList(%d)"
                               ", see ya!\n", MAXCPSIZE);
                        return(1);
                     }
                     updateCPL(gcp->data, &(gcp->dlen), retval);
                     gcpLen += 12 + sizeof(gcp->dlen) + gcp->dlen;
                     gcp = (triplet *)(certPList+gcpLen);
                     break;
                  case C:
                     if (retval == NULL) {
                        printf( "Syntax error: %s requires a value!\n"
                              , opts[C]);
                        usage(argv[0]);
                        return(1);
                     }
                     memcpy(gcp->fieldName, Country, 12);
                     if (MAXCPSIZE < gcpLen + strlen(retval)) {
                        printf("Wow!, ran out of room in certPList(%d)"
                               ", see ya!\n", MAXCPSIZE);
                        return(1);
                     }
                     updateCPL(gcp->data, &(gcp->dlen), retval);
                     gcpLen += 12 + sizeof(gcp->dlen) + gcp->dlen;
                     gcp = (triplet *)(certPList+gcpLen);
                     break;
                  case IP:
                     if (retval == NULL) {
                        printf( "Syntax error: %s requires a value!\n"
                              , opts[IP]);
                        usage(argv[0]);
                        return(1);
                     }
                     memcpy(gcp->fieldName, AltIPAddr, 12);
                     if (MAXCPSIZE < gcpLen + strlen(retval)) {
                        printf("Wow!, ran out of room in certPList(%d)"
                               ", see ya!\n", MAXCPSIZE);
                        return(1);
                     }
                     updateCPL(gcp->data, &(gcp->dlen), retval);
                     gcpLen += 12 + sizeof(gcp->dlen) + gcp->dlen;
                     gcp = (triplet *)(certPList+gcpLen);
                     break;
                  case URI:
                     if (retval == NULL) {
                        printf( "Syntax error: %s requires a value!\n"
                              , opts[URI]);
                        usage(argv[0]);
                        return(1);
                     }
                     memcpy(gcp->fieldName, AltURI, 12);
                     if (MAXCPSIZE < gcpLen + strlen(retval)) {
                        printf("Wow!, ran out of room in certPList(%d)"
                               ", see ya!\n", MAXCPSIZE);
                        return(1);
                     }
                     updateCPL(gcp->data, &(gcp->dlen), retval);
                     gcpLen += 12 + sizeof(gcp->dlen) + gcp->dlen;
                     gcp = (triplet *)(certPList+gcpLen);
                     break;
                  case AE:
                     if (retval == NULL) {
                        printf( "Syntax error: %s requires a value!\n"
                              , opts[AE]);
                        usage(argv[0]);
                        return(1);
                     }
                     memcpy(gcp->fieldName, AltEmail, 12);
                     if (MAXCPSIZE < gcpLen + strlen(retval)) {
                        printf("Wow!, ran out of room in certPList(%d)"
                               ", see ya!\n", MAXCPSIZE);
                        return(1);
                     }
                     updateCPL(gcp->data, &(gcp->dlen), retval);
                     gcpLen += 12 + sizeof(gcp->dlen) + gcp->dlen;
                     gcp = (triplet *)(certPList+gcpLen);
                     break;
                  case DOM:
                     if (retval == NULL) {
                        printf( "Syntax error: %s requires a value!\n"
                              , opts[DOM]);
                        usage(argv[0]);
                        return(1);
                     }
                     memcpy(gcp->fieldName, AltDomain, 12);
                     if (MAXCPSIZE < gcpLen + strlen(retval)) {
                        printf("Wow!, ran out of room in certPList(%d)"
                               ", see ya!\n", MAXCPSIZE);
                        return(1);
                     }
                     updateCPL(gcp->data, &(gcp->dlen), retval);
                     gcpLen += 12 + sizeof(gcp->dlen) + gcp->dlen;
                     gcp = (triplet *)(certPList+gcpLen);
                     break;
                  case AO:
                     if (retval == NULL) {
                        printf( "Syntax error: %s requires a value!\n"
                              , opts[AO]);
                        usage(argv[0]);
                        return(1);
                     }
                     memcpy(gcp->fieldName, AltOther, 12);
                     if (MAXCPSIZE < gcpLen + strlen(retval)) {
                        printf("Wow!, ran out of room in certPList(%d)"
                               ", see ya!\n", MAXCPSIZE);
                        return(1);
                     }
                     if ((semi = strstr(retval, ";")) != NULL) {
                        *semi = ','; /* Replace the semi with a comma */
                     } else {
                        printf("Syntax error: %s doesn't have a "
                               "semicolon separating the OID from "
                               "value!\n", retval);
                        return(1);
                     }
                     updateCPL(gcp->data, &(gcp->dlen), retval);
                     gcpLen += 12 + sizeof(gcp->dlen) + gcp->dlen;
                     gcp = (triplet *)(certPList+gcpLen);
                     break;
                  case KU:
                     if (retval == NULL) {
                        printf( "Syntax error: %s requires a value!\n"
                              , opts[KU]);
                        usage(argv[0]);
                        return(1);
                     }
                     memcpy(gcp->fieldName, KeyUsage, 12);
                     if (MAXCPSIZE < gcpLen + strlen(retval)) {
                        printf("Wow!, ran out of room in certPList(%d)"
                               ", see ya!\n", MAXCPSIZE);
                        return(1);
                     }
                     strcpy(gcp->data, retval);
                     gcp->dlen = strlen(gcp->data);
                     gcpLen += 12 + sizeof(gcp->dlen) + gcp->dlen;
                     gcp = (triplet *)(certPList+gcpLen);
                     break;
                  case XKU:
                     if (retval == NULL) {
                        printf( "Syntax error: %s requires a value!\n"
                              , opts[XKU]);
                        usage(argv[0]);
                        return(1);
                     }
                     memcpy(gcp->fieldName, ExtKeyUsage, 12);
                     if (MAXCPSIZE < gcpLen + strlen(retval)) {
                        printf("Wow!, ran out of room in certPList(%d)"
                              ", see ya!\n", MAXCPSIZE);
                        return(1);
                     }
                     strcpy(gcp->data, retval);
                     gcp->dlen = strlen(gcp->data);
                     gcpLen += 12 + sizeof(gcp->dlen) + gcp->dlen;
                     gcp = (triplet *)(certPList+gcpLen);
                     break;
                  case CE:
                     if (retval == NULL) {
                        printf( "Syntax error: %s requires a value!\n"
                              , opts[CE]);
                        usage(argv[0]);
                        return(1);
                     }
                     memcpy(gcp->fieldName, CustomExt, 12);
                     if (MAXCPSIZE < gcpLen + strlen(retval)) {
                        printf("Wow!, ran out of room in certPList(%d)"
                               ", see ya!\n", MAXCPSIZE);
                        return(1);
                     }
                     /*
                      * Might need special processing to handle commas
                      */
                     cp = strdup(retval);
                     ptr = cp;
                     for (z=0; z < 3; z++) {
                        ptr = strstr(ptr, ":");
                        if (ptr != NULL) {
                          *ptr = ',';
                        }
                        else break;
                     }
                     updateCPL(gcp->data, &(gcp->dlen), cp);
                     gcpLen += 12 + sizeof(gcp->dlen) + gcp->dlen;
                     gcp = (triplet *)(certPList+gcpLen);
                     break;
                  case KS:
                     if (retval == NULL) {
                        printf("Syntax error: %s requires a value!\n"
                              , opts[KS]);
                        usage(argv[0]);
                        return(1);
                     }
                     memcpy(gcp->fieldName, KeySize, 12);
                     if (MAXCPSIZE < gcpLen + strlen(retval)) {
                        printf("Wow!, ran out of room in certPList(%d)"
                               ", see ya!\n", MAXCPSIZE);
                        return(1);
                     }
                     strcpy(gcp->data, retval);
                     gcp->dlen = strlen(gcp->data);
                     gcpLen += 12 + sizeof(gcp->dlen) + gcp->dlen;
                     gcp = (triplet *)(certPList+gcpLen);
                     pkikeygen = 1;
                     break;
                  case NB:
                     if (retval == NULL) {
                        printf( "Syntax error: %s requires a value!\n"
                              , opts[NB]);
                        usage(argv[0]);
                        return(1);
                     }
                     memcpy(gcp->fieldName, NotBefore, 12);
                     if (MAXCPSIZE < gcpLen + strlen(retval)) {
                        printf("Wow!, ran out of room in certPList(%d)"
                               ", see ya!\n", MAXCPSIZE);
                        return(1);
                     }
                     strcpy(gcp->data, retval);
                     gcp->dlen = strlen(gcp->data);
                     gcpLen += 12 + sizeof(gcp->dlen) + gcp->dlen;
                     gcp = (triplet *)(certPList+gcpLen);
                     break;
                  case NA:
                     if (retval == NULL) {
                        printf( "Syntax error: %s requires a value!\n"
                              , opts[NA]);
                        usage(argv[0]);
                        return(1);
                     }
                     memcpy(gcp->fieldName, NotAfter, 12);
                     if (MAXCPSIZE < gcpLen + strlen(retval)) {
                        printf("Wow!, ran out of room in certPList(%d)"
                               ", see ya!\n", MAXCPSIZE);
                        return(1);
                     }
                     strcpy(gcp->data, retval);
                     gcp->dlen = strlen(gcp->data);
                     gcpLen += 12 + sizeof(gcp->dlen) + gcp->dlen;
                     gcp = (triplet *)(certPList+gcpLen);
                     break;
                  case NE:
                     if (retval == NULL) {
                        printf("Syntax error: %s requires a value!\n"
                              , opts[NE]);
                        usage(argv[0]);
                        return(1);
                     }
                     memcpy(gcp->fieldName, NotifyEmail, 12);
                     if (MAXCPSIZE < gcpLen + strlen(retval)) {
                        printf("Wow!, ran out of room in certPList(%d)"
                               ", see ya!\n", MAXCPSIZE);
                        return(1);
                     }
                     updateCPL(gcp->data, &(gcp->dlen), retval);
                     gcpLen += 12 + sizeof(gcp->dlen) + gcp->dlen;
                     gcp = (triplet *)(certPList+gcpLen);
                     break;
                  case USR:
                     if (retval == NULL) {
                        printf("Syntax error: %s requires a value!\n"
                              , opts[USR]);
                        usage(argv[0]);
                        return(1);
                     }
                     memcpy(gcp->fieldName, UserId, 12);
                     if (MAXCPSIZE < gcpLen + strlen(retval)) {
                        printf("Wow!, ran out of room in certPList(%d)"
                               ", see ya!\n", MAXCPSIZE);
                        return(1);
                     }
                     updateCPL(gcp->data, &(gcp->dlen), retval);
                     gcpLen += 12 + sizeof(gcp->dlen) + gcp->dlen;
                     gcp = (triplet *)(certPList+gcpLen);
                     break;
                  case HIM:
                     if (retval == NULL) {
                        printf("Syntax error: %s requires a value!\n"
                              , opts[HIM]);
                        usage(argv[0]);
                        return(1);
                     }
                     memcpy(gcp->fieldName, HostIdMap, 12);
                     if (MAXCPSIZE < gcpLen + strlen(retval)) {
                        printf("Wow!, ran out of room in certPList(%d)"
                               ", see ya!\n", MAXCPSIZE);
                        return(1);
                     }
                     updateCPL(gcp->data, &(gcp->dlen), retval);
                     gcpLen += 12 + sizeof(gcp->dlen) + gcp->dlen;
                     gcp = (triplet *)(certPList+gcpLen);
                     break;
                  case RQ:
                     if (retval == NULL) {
                        printf("Syntax error: %s requires a value!\n"
                              , opts[RQ]);
                        usage(argv[0]);
                        return(1);
                     }
                     memcpy(gcp->fieldName, Requestor, 12);
                     if (MAXCPSIZE < gcpLen + strlen(retval)) {
                        printf("Wow!, ran out of room in certPList(%d)"
                               ", see ya!\n", MAXCPSIZE);
                        return(1);
                     }
                     updateCPL(gcp->data, &(gcp->dlen), retval);
                     gcpLen += 12 + sizeof(gcp->dlen) + gcp->dlen;
                     gcp = (triplet *)(certPList+gcpLen);
                     break;
                  case CP:
                     if (retval == NULL) {
                        printf( "Syntax error: %s requires a value!\n"
                              , opts[CP]);
                        usage(argv[0]);
                        return(1);
                     }
                     memcpy(gcp->fieldName, CertPolicies, 12);
                     if (MAXCPSIZE < gcpLen + strlen(retval)) {
                        printf("Wow!, ran out of room in certPList(%d)"
                               ", see ya!\n", MAXCPSIZE);
                        return(1);
                     }
                     strcpy(gcp->data, retval);
                     gcp->dlen = strlen(gcp->data);
                     gcpLen += 12 + sizeof(gcp->dlen) + gcp->dlen;
                     gcp = (triplet *)(certPList+gcpLen);
                     break;
                  case AIA:
                     if (retval == NULL) {
                        printf( "Syntax error: %s requires a value!\n"
                              , opts[AIA]);
                        usage(argv[0]);
                        return(1);
                     }
                     memcpy(gcp->fieldName, AuthInfoAcc, 12);
                     if (MAXCPSIZE < gcpLen + strlen(retval)) {
                        printf("Wow!, ran out of room in certPList(%d)"
                              ", see ya!\n", MAXCPSIZE);
                        return(1);
                     }
                     if ((semi = strstr(retval, ";")) != NULL) {
                        *semi = ','; /* Replace the semi with a comma */
                     } else {
                        printf("Syntax error: %s doesn't have a "
                               "semicolon separating the acessMethod "
                               "from accessLocation!\n", retval);
                     }
                     if ((semi = strstr(retval, ":")) != NULL) {
                        *semi = '=';  /* Replace the 1st ':' with '=' */
                     } else {
                        printf("Syntax error: %s doesn't have a colon "
                               "separating the URI/URL from "
                               "accessLocation!\n", retval);
                     }
                     updateCPL(gcp->data, &(gcp->dlen), retval);
                     gcpLen += 12 + sizeof(gcp->dlen) + gcp->dlen;
                     gcp = (triplet *)(certPList+gcpLen);
                     break;
                  case CRIT:
                     if (retval == NULL) {
                        printf("Syntax error: %s requires a value!\n"
                              , opts[CRIT]);
                        usage(argv[0]);
                        return(1);
                     }
                     memcpy(gcp->fieldName, Critical, 12);
                     if (MAXCPSIZE < gcpLen + strlen(retval)) {
                        printf("Wow!, ran out of room in certPList(%d)"
                               ", see ya!\n", MAXCPSIZE);
                        return(1);
                     }
                     strcpy(gcp->data, retval);
                     gcp->dlen = strlen(gcp->data);
                     gcpLen += 12 + sizeof(gcp->dlen) + gcp->dlen;
                     gcp = (triplet *)(certPList+gcpLen);
                     break;
                  case KA:
                     if (retval == NULL) {
                        printf("Syntax error: %s requires a value!\n"
                              , opts[KA]);
                        usage(argv[0]);
                        return(1);
                     }
                     memcpy(gcp->fieldName, KeyAlg, 12);
                     if (MAXCPSIZE < gcpLen + strlen(retval)) {
                        printf("Wow!, ran out of room in certPList(%d), "
                               "see ya!\n", MAXCPSIZE);
                        return(1);
                     }
                     strcpy(gcp->data, retval);
                     gcp->dlen = strlen(gcp->data);
                     gcpLen += 12 + sizeof(gcp->dlen) + gcp->dlen;
                     gcp = (triplet *)(certPList+gcpLen);
                     break;
                  case BC:
                     if (retval == NULL) {
                        printf("Syntax error: %s requires a value!\n"
                              , opts[BC]);
                        usage(argv[0]);
                        return(1);
                     }
                     memcpy(gcp->fieldName, BusinessCat, 12);
                     if (MAXCPSIZE < gcpLen + strlen(retval)) {
                        printf("Wow!, ran out of room in certPList(%d)"
                               ", see ya!\n", MAXCPSIZE);
                        return(1);
                     }
                     updateCPL(gcp->data, &(gcp->dlen), retval);
                     gcpLen += 12 + sizeof(gcp->dlen) + gcp->dlen;
                     gcp = (triplet *)(certPList+gcpLen);
                     break;
                  case JC:
                     if (retval == NULL) {
                        printf( "Syntax error: %s requires a value!\n"
                              , opts[JC]);
                        usage(argv[0]);
                        return(1);
                     }
                     memcpy(gcp->fieldName, JurCountry, 12);
                     if (MAXCPSIZE < gcpLen + strlen(retval)) {
                        printf("Wow!, ran out of room in certPList(%d)"
                               ", see ya!\n", MAXCPSIZE);
                        return(1);
                     }
                     updateCPL(gcp->data, &(gcp->dlen), retval);
                     gcpLen += 12 + sizeof(gcp->dlen) + gcp->dlen;
                     gcp = (triplet *)(certPList+gcpLen);
                     break;
                  case JS:
                     if (retval == NULL) {
                        printf("Syntax error: %s requires a value!\n"
                              , opts[JS]);
                        usage(argv[0]);
                        return(1);
                     }
                     memcpy(gcp->fieldName, JurStateProv, 12);
                     if (MAXCPSIZE < gcpLen + strlen(retval)) {
                        printf("Wow!, ran out of room in certPList(%d)"
                               ", see ya!\n", MAXCPSIZE);
                        return(1);
                     }
                     updateCPL(gcp->data, &(gcp->dlen), retval);
                     gcpLen += 12 + sizeof(gcp->dlen) + gcp->dlen;
                     gcp = (triplet *)(certPList+gcpLen);
                     break;
                  case JL:
                     if (retval == NULL) {
                        printf("Syntax error: %s requires a value!\n"
                              , opts[JL]);
                        usage(argv[0]);
                        return(1);
                     }
                     memcpy(gcp->fieldName, JurLocality, 12);
                     if (MAXCPSIZE < gcpLen + strlen(retval)) {
                        printf("Wow!, ran out of room in certPList(%d)"
                               ", see ya!\n", MAXCPSIZE);
                        return(1);
                     }
                     updateCPL(gcp->data, &(gcp->dlen), retval);
                     gcpLen += 12 + sizeof(gcp->dlen) + gcp->dlen;
                     gcp = (triplet *)(certPList+gcpLen);
                     break;
                  default:
                     printf("Syntax error: %s is not a valid "
                            "suboption!\n", subopts);
                     usage(argv[0]);
                     return(1);
                     break;
                }
             }
          } else {
             printf("\nYou MUST specify suboptions when -c is "
                    "entered\n");
             usage(argv[0]);
             return(1);
          }
          break;
      case 't':
          if ((optarg != NULL) && (optarg[0] != '-')) {
             strncpy( tmplName, optarg, min(strlen(optarg)
                    , (sizeof(tmplName)-1)));
          } else {
             printf("\nYou MUST specify a Template nickname when -t "
                    "is entered\n");
             usage(argv[0]);
             return(1);
          }
          break;
      case 'K':
          if ((optarg != NULL) && (optarg[0] != '-')) {
             dashK = 1;

             ifn = optarg;
             /* Open the pkcs10 file, quit if fails*/
             fptr = fopen(ifn, "r");
             if (fptr == NULL) {
                 printf("Unable to open %s: %s\n",
                        ifn, strerror(errno));
                 free(p10buf);
                 return 1;
             }
             /* if the input is a dataset */
             if (0 == strncmp(ifn, "//", 2)) {
                 /* Obtain storage to contain cert data        */
                 p10buf = (char *)malloc(MAXCSRSIZE);
                 if (p10buf == NULL) {
                    printf("Failed to get %d bytes data for CSR "
                           "dataset contents\n", MAXCSRSIZE);
                    return 1;
                 }
                 readlen = MAXCSRSIZE;
             } else {
                 /* Get input PKCS#10 file statistics. quit if fails */
                 if (stat(ifn, &info) != 0) {
                    printf("stat failed for pkcs10 file=[%s]\n", ifn);
                    return 1;
                 }

                 /* Make sure pkcs10 file is in fact a file */
                 if (S_ISREG(info.st_mode) == 0) {
                    printf( "certificate file=[%s] is not a regular "
                            "file\n"
                          , ifn);
                    return 1;
                 }

                 /* Obtain storage to contain cert data        */
                 p10buf = (char *)malloc(info.st_size);
                 if (p10buf == NULL) {
                    printf("Failed to get %d bytes data for cert "
                           "buffer\n", info.st_size);
                    return 1;
                 }
                 readlen = info.st_size;
             }

             /* Read the pkcs10  file, quit if fails*/
             p10buflen = fread(p10buf, 1, readlen, fptr);
             if (p10buflen == 0) {
                 printf("Unable to read %s: %s\n",
                        optarg, strerror(errno));
                 fclose(fptr);
                 free(p10buf);
                 return 1;
             }
             fclose(fptr);

          } else {
             printf("\nYou MUST specify a filename "
                    "with the -K option\n");
             usage(argv[0]);
             return(1);
          }
          break;
      case 'D':
          if ((optarg != NULL) && (optarg[0] != '-')) {
             domName[0] = strlen(optarg);
             if (domName[0] == 0) {
                printf("\nError, You must supply a CA domain name "
                       "after the -D option\n");
                usage(argv[0]);
                return(1);
             } else {
                memcpy(&domName[1], optarg,
                      (domName[0] < (sizeof(domName)-1))
                         ? domName[0] : sizeof(domName)-1
                      );
             }
          } else {
             printf("\nYou MUST specify a CA Domain name when -D "
                    "is entered\n");
             usage(argv[0]);
             return(1);
          }
          break;
      case 'v':
          verbose = 1;
          break;
      case 's':
          dashs = 1;
          if ((optarg != NULL) && (optarg[0] != '-')) {
             /*
              * Get input file name for where to save the cert
              */
             certfn = optarg;
          } else {
                 printf("\nYou MUST specify a filename to store the cert "
                        "with the -s option\n");
                 usage(argv[0]);
                 return(1);
          }
          break;
      case ':':
        printf( "\nYou MUST specify a value with the -%c option\n"
              , optopt);
        usage(argv[0]);
        return(1);
      case '?':
          usage(argv[0]);
          return(1);
      case '-':
          break;
      default:
          printf("\ndefault hit in getopt loop(%c)\n",c);
          usage(argv[0]);
          return(1);
     }
  }
  if ((dashK == 0) && (dashc == 0)) {
     printf("Both -K and -c are not specified.\n");
     usage(argv[0]);
     return(1);
  }


  if (pkikeygen == 1) {
    if ((dashs == 0) && (dashK == 0)) {
      printf("You chose not to save the output cert.\n");
    }
    if (dashK == 1) {
      printf("The input CSR is ignored since key size is specified.\n");
    }
  }
  else {
    if ((dashs == 0) && (dashK == 1)) {
      printf("You forgot to use -s to save the output cert.\n");
      usage(argv[0]);
      return(1);
    }
    if (dashK == 0) {
      printf("Need to supply a CSR or specify key size in -c.\n");
      usage(argv[0]);
      return(1);
    }
  }

  /*
   * Add SignWith to the CertPList
   */
  gcp = (triplet *)(certPList+gcpLen);
  memcpy(gcp->fieldName, "SignWith    ", 12);
  strcpy(gcp->data, "PKI:");
  gcp->dlen = strlen(gcp->data);
  gcpLen += 12 + sizeof(gcp->dlen) + gcp->dlen;

  /*
   * Add PublicKey to the CertPList if it is not pki keygen case
   */
  if (pkikeygen == 0) {
    gcp = (triplet *)(certPList+gcpLen);
    memcpy(gcp->fieldName, "PublicKey   ", 12);
    memcpy(gcp->data, p10buf, p10buflen);
    gcp->dlen = p10buflen;
    gcpLen += 12 + sizeof(gcp->dlen) + gcp->dlen;
  }
  safrc = racfrc = racfrsn = vers = alet = 0;

  if (domName[0] == 0)
     numparms = 5;
  else
     numparms = 6;

  logString[0] = strlen(tmplName);
  memcpy(&logString[1], tmplName, strlen(tmplName));

  if (fc == GENCERT) {
    memcpy(fspl.eye, "gencert ", 8);
  }

  fspl.certPlist = certPList;
  fspl.certPlistLen = gcpLen;

  cid.len = sizeof(cid.data);
  bzero(cid.data, sizeof(cid.data));
  fspl.certid = &cid;

  if (verbose)
     displayCPL(fspl.certPlist, fspl.certPlistLen);

  rc = gettimeofday(&tvs, &tzs);

  rpkiserv( workarea
          , &alet
          , &safrc
          , &alet
          , &racfrc
          , &alet
          , &racfrsn
          , &numparms
          , &fc
          , &attrs
          , logString
          , &vers
          , &fspl
          , domName
          );

  rc = gettimeofday(&tvf, &tzf);

  if (verbose) {
    if (tvf.tv_sec == tvs.tv_sec) {
      printf( "Gencert took %ld.%.06ld seconds\n"
            , 0 , (tvf.tv_usec-tvs.tv_usec));
    } else {
      if (tvf.tv_usec < tvs.tv_usec) {
        printf( "Gencert took %ld.%.06ld seconds\n"
              , (tvf.tv_sec-tvs.tv_sec)-1
              , ((tvf.tv_usec+1000000)-tvs.tv_usec));
      } else {
        printf( "Gencert took %ld.%.06ld seconds\n"
              , (tvf.tv_sec-tvs.tv_sec)
              , (tvf.tv_usec-tvs.tv_usec));
      }
    }
  }

  if (verbose)
    printf("\nGencert returned, safrc=%d, racfrc=%d, racfrsn=%d\n"
           , safrc, racfrc, racfrsn);

  if (safrc == 0 | safrc == 4) { /* if Gencert succeeds */
    if (cid.len > 0) {  /* if tranaction ID is returned */
        printf( "Gencert succeeded: Transaction ID = [%.*s]\n"
              , cid.len, cid.data);
      /*
       * Do an export so that the generated certificate can be
       * posted to LDAP for any follow up processes PKI performs.
       */

      /*
       * Since we are done with the CertPList buffer from
       * the gencert, we will repurpose the heap
       * storage for the certificate buffer of the export
       */
       certbuf = certPList;

       safrc = racfrc = racfrsn = attrs = alet = 0;
       vers = 1;

       fc = EXPORT;
       bzero(tbuf, sizeof(tbuf));
       sprintf( tbuf
               , "Calling R_PKIServ to export certificate ID %.*s"
               , cid.len
               , cid.data
              );
       logString[0] = strlen(tbuf);
       memcpy(&logString[1], tbuf, strlen(tbuf));
       memcpy(xfspl.eye,"EXPORT  ",sizeof(xfspl.eye));
       xfspl.certBuf = certbuf;
       xfspl.certBufLen = MAXCPSIZE;
       xfspl.keyid = &kid;
       if (pplen != 0) {
           strncpy(&cid.data[cid.len], pp, pplen);
           cid.len += pplen;
       }
       xfspl.certid = &cid;
       rpkiserv( workarea
                , &alet
                , &safrc
                , &alet
                , &racfrc
                , &alet
                , &racfrsn
                , &numparms
                , &fc
                , &attrs
                , logString
                , &vers
                , &xfspl
                , domName
               );
       if (verbose)
         printf("\nExport returned, safrc=%d, racfrc=%d, racfrsn=%d\n"
                 , safrc, racfrc, racfrsn);
       if (safrc > 0) {
         printf("\nExport Failed, safrc=%d, racfrc=%d, racfrsn=%d\n"
                 , safrc, racfrc, racfrsn);

       } else {
            printf("Export completed successfully\n");
       }


    /* Save the exoprted cert to a file */
    if (dashs == 1) {
       if (0 == strncmp( xfspl.certBuf, "-----", 5)) {
          isBase64 = 1;
          strcpy(wmode, "w,recfm=vb");
       } else {
          isBase64 = 0;
          strcpy(wmode, "wb,recfm=vb");
       }

       if (verbose) {
         if (isBase64)
            printf("Base64 cert/pkcs#7:\n%.*s"
                   , xfspl.certBufLen, xfspl.certBuf);
         else
            HEXDUMP( "certbuffer returned by EXPORT:"
                    , xfspl.certBuf, xfspl.certBufLen);
       }
       if (NULL == (certfp = fopen(certfn, wmode))) {
          printf( "\nError opening cert output file: %s - %s\n"
                , certfn, strerror(errno));
       } else {
           if (1 != fwrite( xfspl.certBuf, xfspl.certBufLen
                           , 1, certfp)) {
               perror("\nFailed writing certificate file");
           } else {
               printf( "\nCertificate written to file %s\n"
                        , certfn);
           }
           fclose(certfp);
       }
      } /* output to a file */

    } else {
        printf("Gencert succeeded, But no Transaction ID "
               "returned!\n");
        printf("Therefore can not perform export and thus "
               "can not save the cert to a file.\n");
      }
  } else if (safrc > 4) {
      printf( "\nGencert Failed, safrc=%d, racfrc=%d, "
              "racfrsn=%d\n"
              , safrc, racfrc, racfrsn);
      printf("\nDiagInfo=[%.*s]\n", *diagInfoLen, diagInfo);
      free(certPList);
      return rc;
    }

  free(p10buf);
  free(certPList);
  return(0);

}

void updateCPL(char * data, unsigned int * len, char * value) {
   int  i;
   int  x;
   int  z;
   char hexbuf[3];
   char tstr[11];

   *len = 0;
   for (i=0, z=0; i < strlen(value); i++) {
      if (0 == strncmp(&value[i], "0x", 2)) {
         strncpy(hexbuf, &value[i+2], 2);
         hexbuf[2] = '\0';
         sscanf(hexbuf, "%x", &x);
         data[z++] = x;
         i += 3;
         (*len)++;
      } else if (0 == strncmp(&value[i], "%d", 2)) {
         sprintf(tstr, "%d", time(NULL));
         strcpy(&data[z], tstr);
         z += strlen(tstr);
         (*len) += strlen(tstr);
         i++;
      } else {
         data[z++] = value[i];
         (*len)++;
      }
   }
}

void displayCPL(char * cpl, int cpllen) {
   triplet * p;
   int       offset = 0;

   p = (triplet *)cpl;
   printf("CertPlist content:\n");
   while (offset < cpllen) {
      printf( "Fieldname = %.12s: Length = %8.8x: Data=[%.*s]\n"
            , p->fieldName, p->dlen, p->dlen, p->data);
      offset += (16 + p->dlen);
      p = (triplet *)(cpl+offset);
   }
}

void usage(char * pgmname) {

   printf("\nThis utility is to request a certificate from PKI Services,\n");
   printf("by providing a CSR or let the PKI daemon to generate the key.\n");
   printf("The certificate package can be saved in a specified file or dataset,\n");
   printf("which is required if input is a CSR.\n");
   printf("\n");
   printf("Usage: %s\n", pgmname);
   printf("          {-K <input file or dataset containing CSR in PKCS#10 format>]\n", pgmname);
   printf("          [-c rq=...,cn=...,ku=...,eku=,..,dom=...,] -s <output file>}\n");
   printf("         |\n");
   printf("          {-c rq=<emailAddr>,ks=<keySize>,ka=<keyAlg>,pp=<passp>,\n");
   printf("              [cn=...,ku=...,eku=,..,dom=...,] [-s <output file>]}\n");
   printf("          [-D <CA Domain>]\n");
   printf("          [-t <template nickname>]\n");
   printf("          [-v]\n");
   printf("          \n");
   printf("\t  Sub options for -c (certificate parameter list) in the format of \n");
   printf("\t  keyword=value pair list separated by commas\n");
   printf("\t      (keyword with * can be repeated with multiple keyword=value pairs)\n");
   printf("\t      (value with blanks needed to be quoted)\n");
   printf("\t  Acceptable Keywords for -c:\n");
   printf("\t   1. Subject distinguish name values:\n");
   printf("\t    sn  - SerialNumber e.g sn=29437810\n");
   printf("\t    ua  - UnstructAddr e.g ua=\'Cisco 36xx Router\'\n");
   printf("\t    ua  - UnstructName e.g un=\'descriptive text\'\n");
   printf("\t    ea  - EmailAddr    e.g ea=gumby@loony.toons\n");
   printf("\t    m   - Mail         e.g m=bugs@loony.toons\n");
   printf("\t    dq  - DNQualifier  e.g dq=\'domain qualifier\'\n");
   printf("\t    uid - Uid          e.g uid=mega\n");
   printf("\t    cn  - CommonName   e.g cn=\'Foghorn Leghorn\'\n");
   printf("\t    t   - Title        e.g t=\'The Hammer\'\n");
   printf("\t    dn  - DomainName   e.g dn=www.loony.toons\n");
   printf("\t    ou* - OrgUnit      e.g ou=MyOrgUnit1,ou=MyOrgUnit2\n");
   printf("\t    bc  - BusinessCat  e.g bc=\'Health Organization\'\n");
   printf("\t    o   - Org          e.g o=\'The Bros Org\'\n");
   printf("\t    jl  - JurLocality  e.g jl=Poughkeepsie\n");
   printf("\t    js  - JurStateProv e.g js=\'New York\'\n");
   printf("\t    jc  - JurCountry   e.g jc=US\n");
   printf("\t    st  - Street       e.g st=\'2455 Cartoon Lane\'\n");
   printf("\t    l   - Locality     e.g l=\'Dutchess County\'\n");
   printf("\t    sp  - StateProv    e.g sp=\'New York'\n");
   printf("\t    pc  - PostalCode   e.g pc=12601\n");
   printf("\t    c   - Country      e.g c=US\n");
   printf("\n");
   printf("\t   2. Certificate extension values:\n");
   printf("\t    ip*  - AltIPAddr    e.g ip=27.26.25.24,ip=27.26.25.23\n");
   printf("\t    uri* - AltURI       e.g uri=http://www.pokey.com\n");
   printf("\t    ae*  - AltEmail     e.g ae=fredflint@bedrock.com\n");
   printf("\t    dom* - AltDomain    e.g dom=www.sys1.com,dom=www.sys2.com\n");
   printf("\t    ao   - AltOther     e.g ao=\'1.2.3.4;acb123xyz\'\n");
   printf("\t    ku*  - KeyUsage     e.g ku=certsign,ku=docsign\n");
   printf("\t    xku* - ExtKeyUsage  e.g xku=ocspsigning\n");
   printf("\t    ce*  - CustomExt    e.g ce=\'1.2.3.4,n,int,1234\'\n");
   printf("\t    cp   - CertPolicy   e.g cp=\'1 3 5\'\n");
   printf("\t    aia* - AuthInfoAcc  e.g aia=ocsp;URL:http://<host[:port]>/PKIServ/public-cgi/caocsp\n");
   printf("\t    crit*- Critical     e.g crit=KeyUsage\n");
   printf("\t    him* - HostIdMap    e.g him=pokey@gumbymvs\n");
   printf("\n");
   printf("\t   3. Other certificate parameter list values:\n");
   printf("\t    pp  - PassPhrase   e.g pp=secretPassPhrase\n");
   printf("\t    nb  - NotBefore    e.g nb=1\n");
   printf("\t    na  - NotAfter     e.g na=365\n");
   printf("\t    ne  - NotifyEmail  e.g ne=hammer@loony.toons\n");
   printf("\t    usr - Userid       e.g usr=joeuser\n");
   printf("\t    rq  - Requestor    e.g rq=\'My Friendly Name\'\n");
   printf("\t                       e.g rq=joeuser@aabank.com, if -K is not specified\n");
   printf("\n");
   printf("\t Other options:\n");
   printf("\t  -D <CA Domain>\n");
   printf("\t     The CA Domain name of the PKI instance, as indicated in pkiserv.envar\n");
   printf("\n");
   printf("\t  -t <template nickname>\n");
   printf("\t      The nickname of the Template to use, as indicated in the PKI template file\n");
   printf("\n");
   printf("\t  -v Verbose mode - extra info displayed\n");
   printf("\n");
   printf("\t Examples:\n");
   printf("\t 1. Provide a PKCS10(CSR) for certificate generation:\n");
   printf("\t gencert -K myserver.csr -D subca1 -s \"//\'myserver.cer\'\"\n");
   printf("\n");
   printf("\t 2. Let PKI Services generate the key pair for the certificate\n");
   printf("\t gencert -c rq=joeuser@aabank.com,ks=2048,ka=rsa,cn=myserver,o=test,\n");
   printf("\t c=us,ku=handshake,xku=clientauth,ip=1.2.3.4,ip=5.6.7.8,\n");
   printf("\t dom=myserver1.com,dom=myserver2.com,pp=secret -D subca1 -s \"//\'myserver.p12\'\"\n");
   printf("\n");

}


