/**********************************************************************/
/* COPYRIGHT IBM CORP. 2000,2014                                      */
/**********************************************************************/
/* Program:   rexx                                                    */
/* Function:  shell utility to run a rexx program                     */
/* Syntax:    rexx {arg...}                                           */
/*        or  rexx -f file {arg...}                                   */
/*        or  rexx -c "rexx statements" {arg...}                      */
/*                                                                    */
/*   If no options are specified the rexx program is read from stdin  */
/*                                                                    */
/*   rexx -f file    file points to the rexx program                  */
/*                   //data.set is supported                          */
/*                   data.set must be a fully qualified name and may  */
/*                   include a member name. ex:                       */
/*                     rexx -f //hlq.some.exec                        */
/*                     rexx -f '//hlq.execs(mypgm)'                   */
/*                   #! is supported.  as the first line use          */
/*                        #! rexx -f                                  */
/*                                                                    */
/*   rexx -c stmts   stmts is the rexx program. ex:                   */
/*                   rexx -c 'do i=1 to __argv.0;say __argv.i;end' hi */
/*                                                                    */
/* Notes:     __argv.1 contains the program name                      */
/*              if stdin is used the name used is /dev/fd0            */
/*              if -c is used the name used is -c                     */
/*                                                                    */
/*            REXX as a comment is not required in the first line     */
/*                                                                    */
/* Install:   This program is source distributed.  Copy the source    */
/*            into an HFS file rexx.c and compile: c89 -o rexx rexx.c */
/*            Copy rexx to a directory in your PATH with mode 0755.   */
/*                                                                    */
/* Change Activity:                                                   */
/*    04/01/00 initial                                                */
/*    11/12/00 support for loading execs from a data set              */
/*    02/05/14 -c -f options, allow non-pds dsn, dynamic DD name      */
/*    02/10/14 allow multiple lines for -c                            */
/*                                                                    */
/* Contact: Bill Schoen (wjs@us.ibm.com)                              */
/**********************************************************************/
#pragma runopts(trap(off),stack(24K,4K,ANYWHERE))
#pragma strings(readonly)
#define PROGNAME "rexx "

#define _XOPEN_SOURCE
#include <stdlib.h>
#include <ctype.h>
#include <stdio.h>
#include <fcntl.h>
#include <string.h>

typedef int EXTF();
#pragma linkage(EXTF,OS)

/* initial max line length and number of lines */
#define MAXLN 80
#define MAXR  100

/**********************************************************************/
/* TSO REXX partial structures                                        */
/**********************************************************************/
#define ENDTAB(a) memset(a,0xff,8)

typedef struct s_argl {
   char *arg;
   long arglen;
   } ARGL;

typedef struct s_eval {
   long rsvd1;
   long size;
   long len;
   long rsvd2;
   char rslt[250];
   } EVAL;

typedef struct s_exet {
   int  entrycount;
   EXTF *init;
   EXTF *usrload;
   EXTF *load;
   EXTF *excom;
   EXTF *exec;
   EXTF *iorout;
   EXTF *inout;
   EXTF *jcl;
   EXTF *rlt;
   EXTF *usrstk;
   EXTF *stk;
   EXTF *subcom;
   EXTF *term;
   EXTF *ic;
   EXTF *usrmsgid;
   EXTF *msgid;
   EXTF *usrid;
   EXTF *uid;
   EXTF *terma;
   EXTF *say;
   } EXET;

typedef struct s_envb {
   char rsvd[20];
   char *user;
   char *wkblk;
   EXET *exet;
   } ENVB;

typedef struct s_recs {
   char *rec;                       /* pointer to record              */
   long len;                        /* length of record               */
   } RECS;

typedef struct s_inst {
   char acro[8];                    /* IRXINSTB                       */
   long hdrlen;                     /* length of header = 128         */
   char rsvd1[4];                   /*                                */
   RECS *recs;                      /* ptr to recs table              */
   long recslen;                    /* length of recs table           */
   char member[8];                  /* name of exec                   */
   char ddname[8];                  /* dd name used to load           */
   char subcom[8];                  /* name of initial command env    */
   char rsvd2[4];                   /*                                */
   long dsnlen;                     /* length of dsn field            */
   char dsn[45];                    /* dsn                            */
   char dsnmem[10];                 /* (member)                       */
   char rsvd4[2];                   /* rsvd, must be 0x00             */
   char *path;                      /* pathname extention             */
   long pathlen;                    /* pathname length                */
   char rsvd3[8];                   /* rsvd, must be 0x00             */
   } INST;

#define acroINST "IRXINSTB"

typedef struct s_execblk {
   char acro[8];
   long length;
   long rsvd;
   char mem[8];
   char ddname[8];
   char subcom[8];
   char *dsn;
   long dsnlen;
   /* verify length before using following fields                     */
   char *path;
   long pathlen;
   char rsvd2[8];
   } EXECBLK;

/**********************************************************************/
/* external references                                                */
/**********************************************************************/

#pragma  csect(code,"REXXC")
#pragma  csect(static,"REXXS")

extern char **environ;

/**********************************************************************/
void usage() {
   fprintf(stderr,"usage: rexx -c command | -f file\n");
   exit(254);
   }

/**********************************************************************/
void cknull(void *ptr) {
   if (!ptr) {
      fprintf(stderr,"storage allocation failed\n");
      exit(254);
      }
   return;
   }

/**********************************************************************/
void newline(RECS **recs,int *nrecs,int r,int *maxln) {
   if (*recs==NULL) {     /* initial allocation for recs array needed */
      *recs=(RECS *)malloc(MAXR*sizeof(RECS));
      cknull(*recs);
      *nrecs=MAXR;
      }
   if (r>=*nrecs) {
      *nrecs+=MAXR;                       /* extend max lines       */
      *recs=(RECS *)realloc(*recs,*nrecs*sizeof(RECS));
      cknull(*recs);
      }
   (*recs)[r].rec=(char *)malloc(MAXLN);  /* initialize new line */
   cknull((*recs)[r].rec);
   *maxln=MAXLN;
   (*recs)[r].len=0;
   }

/**********************************************************************/
void catline(RECS **recs,int r,int *maxln,int k) {
   if ((*recs)[r].len>=*maxln) {
      *maxln+=MAXLN;                   /* extend this line buffer*/
      (*recs)[r].rec=(char *)realloc((*recs)[r].rec,*maxln);
      cknull((*recs)[r].rec);
      }
   (*recs)[r].rec[(*recs)[r].len++]=k; /* add char to end of line */
   }

/**********************************************************************/
/* main()                                                             */
/**********************************************************************/
int main(int argc, char **argv) {
char *compiled=PROGNAME "COMPILED AT " __TIME__ " ON " __DATE__;
RECS *recs=NULL;                    /* record array                   */
FILE *fd;                           /* file struct                    */
int  pathlen;                       /* length of program path         */
int  lns;                           /* lines in exec                  */
int  nrecs;                         /* number of rec slots            */
int  maxln;                         /* max line length                */
int  i,j,k,r,c;                     /* temps                          */
INST *inst,*pinst=NULL;             /* in-storage control block       */
char *word;                         /* ptr to exec parm string        */
char *end;                          /* ptr to end of exec parm string */
ARGL argl[2];                       /* argument list                  */
ARGL *pargl=argl;                   /* ptr to ARGL                    */
EVAL eval;                          /* evaluation block               */
EVAL *peval=&eval;                  /* ptr to EVAL                    */
EXTF *irxexec;                      /* addr of irxexec routine        */
EXTF *irxterm;                      /* addr of irxterm routine        */
EXTF *irxsay;                       /* addr of irxsay routine         */
EXTF *bpxwrbld;                     /* environment build routine      */
long parmlen;                       /* length of flattened parm       */
ENVB *penvb;                        /* pointer to environment block   */
long rcinit;                        /* init env return code           */
long maxprm=0;                      /* max size of flattened parm     */
char rxwork[16000];                 /* i/o table                      */
char *prm;                          /* buf for flattened parms        */
char *pprm;                         /* work ptr                       */
char *pgm;                          /* ptr to exec name               */
int  envc;                          /* num environ variables          */
int  **envl;                        /* environ len ptr array          */
char **env=&*environ;               /* environ var ptr array          */
char dsn[44];                       /* dsn for exec                   */
int  dsnl;                          /* dsn length                     */
char member[9];                     /* member name                    */
EXTF *bpxwdyn;
char alloc[256];
EXECBLK execblk,*execblkp=&execblk;
char *copt=NULL;
char *fopt=NULL;

   /*******************************************************************/
   /* parse options                                                   */
   /*******************************************************************/
   opterr = 0;
   optind = 0;
   while ((c=getopt (argc,argv,"c:f:"))!=-1)
      switch (c) {
         case 'c':
            copt=optarg;
            break;
         case 'f':
            fopt=optarg;
            break;
         default:
            usage();
         }
     if (copt && fopt) usage();
     if (copt==NULL && fopt==NULL)
        fopt="/dev/fd0";

   /*******************************************************************/
   /* load routines                                                   */
   /*******************************************************************/
   irxexec=(EXTF *)fetch("IRXEXEC");
   irxterm=(EXTF *)fetch("IRXTERM");
   bpxwrbld=(EXTF *)fetch("BPXWRBLD");

   /*******************************************************************/
   /* locate program name and args                                    */
   /*******************************************************************/
   i=argc;                          /* number of args                 */
   pgm=copt?"-c":fopt?fopt:argv[optind];
   pathlen=strlen(pgm);
   if (memcmp(pgm,"//",2))      /* not // then not data set */
      dsnl=0;
    else {                      /* else dataset.  get dsn and member  */
      for (i=2;i<46 && pgm[i] && pgm[i]!='(';i++)
         dsn[i-2]=toupper(pgm[i]);
      dsnl=i-2;
      dsn[dsnl]=0;
      memset(member,' ',8);
      if (pgm[i]=='(')
         for (k=0,i++;k<8 && pgm[i] && pgm[i]!=')';i++,k++)
            member[k]=toupper(pgm[i]);
      }

   /*******************************************************************/
   /* build rexx environment                                          */
   /*******************************************************************/
   for (envc=0;environ[envc]!=NULL;envc++);
   envl=(int **)malloc(envc*4+4);
   cknull(envl);
   for (i=0;i<envc;i++)
      envl[i]=(int *)(&environ[i][0])-1;
   envl[envc]=NULL;

   j=optind-1;
   argv[j]=pgm;
   rcinit=bpxwrbld(rxwork,
                   argc-j,&argv[j],
                   envc,envl,env,
                   &penvb);         /* returned ptr to env block      */
   if (rcinit!=0) {
      fprintf(stderr,"rexx environment not created rc=%d\n",rcinit);
      exit(254);
      }

   /*******************************************************************/
   /* flatten parms to a string as expected by an exec                */
   /*******************************************************************/
   pprm=prm=malloc(4096);
   cknull(prm);
   maxprm=4096;
   for (i=argc,j=optind;j<i;j++) {       /* make real args 1 string   */
      k=strlen(argv[j]);
      if ((pprm+k+1)>(prm+maxprm)) {     /* make sure arg fits        */
         maxprm+= k<4096 ? 4096 : k+1;   /* bump at least 4K          */
         r=pprm-prm;
         prm=realloc(prm,maxprm);
         cknull(prm);
         pprm=prm+r;
         }
      memcpy(pprm,argv[j],k);
      pprm+=k;
      if (j!=argc-1) {  /* insert 1 space between args */
         *pprm=' ';
         pprm++;
         }
      }
   *pprm='\0';
   parmlen=pprm-prm;                /* parm length                    */
   word=prm;                        /* start ptr                      */
   end=word+parmlen;                /* ptr to end                     */

   /*******************************************************************/
   /* build arg list for irxexec                                      */
   /*******************************************************************/
   argl[0].arg=word;                /* parm to exec                   */
   argl[0].arglen=end-word;         /* length of parm                 */
   ENDTAB(&argl[1]);                /* end of list                    */

   if (dsnl) {                            /* for dataset use execload */
   /*******************************************************************/
   /* load exec from a data set                                       */
   /*******************************************************************/
   typedef struct s_rtarg {
      short len;
      char str[260];
      } RTARG;
   RTARG ddname = {9,"rtddn"};
   bpxwdyn=(EXTF *)fetch("BPXWDYN ");
   strcpy(alloc,"alloc shr msg(2) da(");
   strcat(alloc,dsn);
   strcat(alloc,")");
   i=bpxwdyn(alloc,&ddname);
   if (i) {
      fprintf(stderr,"allocation error %d(%X)\n   %s\n",i,i,alloc);
      exit(254);
      }
   memset(&execblk,0,sizeof(EXECBLK));
   memcpy(execblk.acro,"IRXEXECB",8);
   execblk.length=sizeof(EXECBLK);
   memcpy(execblk.mem,member,8);
   execblk.dsn=dsn;
   execblk.dsnlen=dsnl;
   memcpy(execblk.subcom,"        ",8);
   memcpy(execblk.ddname,ddname.str,8);
   i=penvb->exet->load("LOAD    ",
                       &execblkp,
                       &pinst,
                       &penvb
                       );
   for (j=7;j>0 && ddname.str[j]==' ';j--)
      ddname.str[j]=0;
   strcpy(alloc,"free fi(");
   strcat(alloc,ddname.str);
   strcat(alloc,")");
   j=bpxwdyn(alloc);
   if (i) {
      member[8]=0;
      fprintf(stderr,"EXEC load failed %d; "
                     "dsn=%s member=%s\n",i,dsn,member);
      exit(254);
      }
   }

   else
   if (copt) {
   /*******************************************************************/
   /* load exec from the -c option                                    */
   /*******************************************************************/
   for (r=0;*copt;r++,copt++) {             /* scan the copt string */
      newline(&recs,&nrecs,r,&maxln);       /* setup for next line  */
      for (;*copt && *copt!='\n';copt++)    /* copy in the line     */
         catline(&recs,r,&maxln,*copt);
      }
   lns=r;
   }

   else {
   /*******************************************************************/
   /* load exec from a pathname                                       */
   /*******************************************************************/
   fd=fopen(pgm,"r");
   if (!fd) {
      perror("open failed");
      exit(254);
      }
   for (r=0,k=0;k!=EOF;r++) {               /* build recs array       */
      newline(&recs,&nrecs,r,&maxln);
      for (;(k=getc(fd))!=EOF && k!='\n';)   /* get next line         */
         catline(&recs,r,&maxln,k);
      }
   fclose(fd);
   if (recs[r].len==0)  /* eliminate eof line */
      r--;
   /* if first non-blank on first line is # then blank the line */
   for (i=0;i<recs[0].len && recs[0].rec[i]==' ';i++);
   if (recs[0].rec[i]=='#')
      recs[0].len=0;
   lns=r;
   }

   /*******************************************************************/
   /* build the in-storage Block for irxexec                          */
   /*******************************************************************/
   if (!pinst) {
      inst=(INST *)malloc(sizeof(INST)+pathlen);
      cknull(inst);
      memset(inst,'\0',sizeof(INST));
      memcpy(inst->acro,acroINST,8);
      inst->hdrlen=sizeof(INST);
      inst->recs=recs;
      inst->recslen=lns*sizeof(RECS);
      memset(inst->member,' ',8);
      memcpy(inst->member,pgm,pathlen>8 ? 8 : pathlen);
      memcpy(inst->ddname,"PATH    ",8);
      memset(inst->subcom,' ',8);
      inst->dsnlen=pathlen>44 ? 44 : pathlen;
      memset(inst->dsn,' ',44);
      memcpy(inst->dsn,pgm,inst->dsnlen);
      inst->path=sizeof(INST)+(char *)inst;
      inst->pathlen=pathlen;
      memcpy(inst->path,pgm,pathlen);
      pinst=inst;
      }

   /*******************************************************************/
   /* build the Evaluation Block for irxexec                          */
   /*******************************************************************/
   memset(&eval,'\0',sizeof(EVAL));
   eval.size=sizeof(EVAL)/8;

   /*******************************************************************/
   /* execute the exec                                                */
   /*******************************************************************/
   irxexec(0,                       /* preloaded exec                 */
           &pargl,                  /* arg list to exec               */
           0x80000000,              /* invoked as command             */
           &pinst,                  /* in storage control block       */
           0,                       /* no cppl                        */
           &peval,                  /* evaluation block               */
           0,                       /* no work area                   */
           0);                      /* no user area                   */

   /*******************************************************************/
   /* terminate environment and return result                         */
   /*******************************************************************/
   irxterm();
   irxterm();
   for (i=j=0;i<eval.len && eval.rslt[i]>' ';i++) {
      if (eval.rslt[i]<'0' || eval.rslt[i]>'9') /* numeric only       */
         exit(255);
      j=10*j + (eval.rslt[i] - '0'); /* convert to binary             */
      if (j>255)                     /* range 0-255                   */
         exit(255);
      };
   exit(j);                          /* return status                 */
}
