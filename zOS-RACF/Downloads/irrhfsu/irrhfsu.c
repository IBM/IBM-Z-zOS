
/**********************************************************************/
/* hfsu : C program which unloads the security data of HFS files in   */
/*        a manner compatible with that of the IRRDBU00 utility.      */
/*                                                                    */
/* Copyright Copyright IBM Corporation, 2000                          */
/* Author: Bruce Wells  brwells@us.ibm.com                            */
/*                                                                    */
/* This program contains code made available by IBM Corporation on    */
/* an AS IS basis. Any one receiving these programs is considered to  */
/* be licensed under IBM copyrights to use the IBM-provided source    */
/* code in any way he or she deems fit, including copying it,         */
/* compiling it, modifying it, and redistributing it, with or without */
/* modifications, except that it may be neither sold nor incorporated */
/* within a product that is sold.  No license under any IBM patents   */
/* or patent applications is to be implied from this copyright        */
/* license.                                                           */
/*                                                                    */
/* The software is provided "as-is", and IBM disclaims all warranties,*/
/* express or implied, including but not limited to implied warranties*/
/* of merchantibility or fitness for a particular purpose.  IBM shall */
/* not be liable for any direct, indirect, incidental, special or     */
/* consequential damages arising out of this agreement or the use or  */
/* operation of the software.                                         */
/*                                                                    */
/* A user of this program should understand that IBM cannot provide   */
/* technical support for the program and will not be responsible for  */
/* any consequences of use of the program.                            */
/*                                                                    */
/* Change Activity:                                                   */
/*                                                                    */
/* $L0=HFSU    HRF2608 000301 PDBRW1: Original Code               @L0A*/
/*                                                                    */
/* Change Description:                                                */
/*                                                                    */
/* A000000-999999  Original Code                                      */
/*                                                                    */
/**********************************************************************/

#define _XOPEN_SOURCE
#define _OPEN_SYS
#define _POSIX_SOURCE
#include <stdio.h>
#include <time.h>
#include <sys/stat.h>
#define __UU
#include <ftw.h>
#include <pwd.h>
#include <grp.h>

int  traverse (const char *file);
int  unload (const char *file, const struct stat *st, int type);
char* mapit(const char idtype, int idvalue);
FILE *stream;

/********************************************************************/
/* Declarations associated with the uid/user and gid/group caches   */
/********************************************************************/
const int maxcache = 10;    /* max no. of cache elements */
struct cachelem {           /* structure of a cache element */
  struct cachelem *prev;   /* ptr to previous element */
  struct cachelem *next;   /* ptr to next element */
  int id;                  /* uid or gid value */
  char name[9];            /* associated user ID or group name */
};
struct cachelem *uidcache = 0;     /* ptr to head of uid cache */
struct cachelem *gidcache = 0;     /* ptr to head of gid cache */
int uidcount,gidcount;      /* no. elements in uid,gid cache */

char *outvalue = NULL;
const char usertype = 'U';
const char grouptype = 'G';



/**********************************************************************/
/* main:                                                              */
/*    Read the input arguments and see if -f filename was             */
/*    specified.  If so, see if it refers to an MVS data set.         */
/*    If so, insert quotes into the path name. Open the output        */
/*    file, if specified. Else use stdout. Then, invoke the           */
/*    tree traversal routine for each specified file/directory.       */
/*                                                                    */
/*    When done, free storage associated with the uid/gid cache       */
/*    mechanisms.                                                     */
/**********************************************************************/
int
main(int argc, register char **argv)
{
   int ret,ret2;
   char outfile[50];
   struct cachelem *tempptr;
   struct cachelem *nextptr;
   struct stat* info;

   uidcount =0;
   gidcount =0;
   stream = stdout;
   ++argv;
   if (argc > 2)
      if (strcmp(*argv,"-f")==0)
       {
         ++argv;
         if (strncmp("//",*argv,2)==0)
          {
            strcpy(outfile,"//");
            strcat(outfile,"'");
            strcat(outfile,&(argv[0][2]));
            strcat(outfile,"'");
          }
         else strcpy(outfile,*argv);

         stream = fopen(outfile,"a,lrecl=4096,recfm=vb");
         ++argv;
       }


   if (stream == 0) {
     perror("IRR67700I fopen() error on output file\n");
     exit(2);
   }

   /* Allocate storage for uid/gid name string */
   outvalue = (char *)malloc(9);

   for (; *argv != NULL; ++argv)
      ret |= traverse(*argv);

   ret2 = fclose(stream);

   /* Release storage for uid/gid name string */
   free(outvalue);

   /* Release uid cache storage */
   for (tempptr = uidcache ; uidcount ; tempptr = nextptr)
      {
         nextptr = tempptr->next;
         free(tempptr);
         --uidcount;
      }

   /* Release gid cache storage */
   for (tempptr = gidcache ; gidcount ; tempptr = nextptr)
      {
         nextptr = tempptr->next;
         free(tempptr);
         --gidcount;
      }

   return (ret);
}

/**********************************************************************/
/* traverse:                                                          */
/*    Use the C library function ftw() to invoke the unload routine   */
/*    for every object in the subtree specified by the input file.    */
/*    The input can be a single file, in which case its contents      */
/*    are unloaded.                                                   */
/**********************************************************************/
int
traverse(const char *file)
{
   if (ftw(file, unload, 10) < 0)
      {
         perror("IRR67701I ftw() error\n");
         return (1);
      }
   return (0);
}

/**********************************************************************/
/* unload:                                                            */
/*    Unload the security contents of the file into the output file.  */
/*    The data is taken from the stat structure passed in by ftw.     */
/*    In addition, UIDs are mapped into RACF user IDs and GIDs are    */
/*    mapped into RACF group names.                                   */
/**********************************************************************/
int
unload(const char *file, const struct stat *st, int type)
{
   char *tempval;
   char *filetype;
   struct tm *timeptr;
   int i,ch;
   char dest[11];
   int p_ret;

   switch (type)
   {
      case FTW_NS:
         fprintf(stderr,"IRR67702I stat() could not be executed" \
                        " on %s. Possible search error on parent" \
                        " directory.\n",file);
         break;

      case FTW_DNR:
         fprintf(stderr,"IRR67703I Unable to read directory %s\n",file);
         break;

      case FTW_D:
      case FTW_F:
      case FTW_SL:
             /* HFBD_RECORD_TYPE - Type of this "IRRDBU00" record     */
             /*                                                       */
             /* For each file, we will check the fprintf return code  */
             /* once to see if we're still ok.  If not, exit.  For    */
             /* example, if the output file runs out of space, this   */
             /* program would chug merrily on unless we detect this   */
             /* and stop.  Theoretically, any of the following fprintf*/
             /* statements could fail, and with buffering, it is hard */
             /* to predict, so we will just check once for every file.*/
             p_ret = fprintf(stream,"0900");
             if (p_ret < 0)
               {
                 perror("IRR67704I fprintf() error while writing to" \
                        " output file\n");
                 return (5);   /* Arbitary number... */
               }
             /* HFBD_NAME - path name of file being unloaded          */
             fprintf(stream," %-1023.1023s",file);
             /* HFBD_INODE - inode (file serial number)               */
             fprintf(stream," %010u",st->st_ino);
             /* HFBD_FILE_TYPE - type of file                         */
             if (S_ISREG(st->st_mode))
                filetype="FILE    ";
             else if (S_ISDIR(st->st_mode))
                filetype="DIR     ";
             else if (S_ISSOCK(st->st_mode))
                filetype="SOCKET  ";
             else if (S_ISEXTL(st->st_mode,st->st_genvalue))
                filetype="EXTLINK ";
             else if (S_ISLNK(st->st_mode))
                filetype="SYMLINK ";
             else if (S_ISFIFO(st->st_mode))
                filetype="FIFO    ";
             else if (S_ISBLK(st->st_mode))
                filetype="BLOCK   ";
             else if (S_ISCHR(st->st_mode))
                filetype="CHAR    ";
             else
                filetype="        ";
             fprintf(stream," %s",filetype);


             /* HFBD_FILE_OWN_UID - owning UID                        */
             fprintf(stream," %010u",st->st_uid);
             /* HFBD_FILE_OWN_UNAM - corresponding RACF user ID       */
             fprintf(stream," %-8s",mapit(usertype,st->st_uid));
             /* HFBD_FILE_OWN_GID - owning GID                        */
             fprintf(stream," %010u",st->st_gid);
             /* HFBD_FILE_OWN_GNAM - corresponding RACF group name    */
             fprintf(stream," %-8s",mapit(grouptype,st->st_gid));

             /* HFBD_S_ISUID - set-uid bit                            */
             (st->st_mode & S_ISUID)?
                 fprintf(stream," YES "): fprintf(stream," NO  ");
             /* HFBD_S_ISGID - set-gid bit                            */
             (st->st_mode & S_ISGID)?
                 fprintf(stream," YES "): fprintf(stream," NO  ");
             /* HFBD_S_ISVTX - sticky bit                             */
             (st->st_mode & S_ISVTX)?
                 fprintf(stream," YES "): fprintf(stream," NO  ");
             /* HFBD_OWN_READ - owner read permission bit             */
             (st->st_mode & S_IRUSR)?
                 fprintf(stream," YES "): fprintf(stream," NO  ");
             /* HFBD_OWN_WRITE - owner write permission bit           */
             (st->st_mode & S_IWUSR)?
                 fprintf(stream," YES "): fprintf(stream," NO  ");
             /* HFBD_OWN_EXEC - owner search/execute permission bit   */
             (st->st_mode & S_IXUSR)?
                 fprintf(stream," YES "): fprintf(stream," NO  ");
             /* HFBD_GRP_READ - group read permission bit             */
             (st->st_mode & S_IRGRP)?
                 fprintf(stream," YES "): fprintf(stream," NO  ");
             /* HFBD_GRP_WRITE - group write permission bit           */
             (st->st_mode & S_IWGRP)?
                 fprintf(stream," YES "): fprintf(stream," NO  ");
             /* HFBD_GRP_EXEC - group search/execute permission bit   */
             (st->st_mode & S_IXGRP)?
                 fprintf(stream," YES "): fprintf(stream," NO  ");
             /* HFBD_OTH_READ - other read permission bit             */
             (st->st_mode & S_IROTH)?
                 fprintf(stream," YES "): fprintf(stream," NO  ");
             /* HFBD_OTH_WRITE - other write permission bit           */
             (st->st_mode & S_IWOTH)?
                 fprintf(stream," YES "): fprintf(stream," NO  ");
             /* HFBD_OTH_EXEC - other search/execute permission bit   */
             (st->st_mode & S_IXOTH)?
                 fprintf(stream," YES "): fprintf(stream," NO  ");

             /* HFBD_APF - APF authorization setting                  */
             (S_ISAPF_AUTH(st->st_mode,st->st_genvalue))?
                 fprintf(stream," YES "): fprintf(stream," NO  ");
             /* HFBD_PROGRAM - program control setting                */
             (S_ISPROG_CTL(st->st_mode,st->st_genvalue))?
                 fprintf(stream," YES "): fprintf(stream," NO  ");
             /* HFBD_SHAREAS - runs in shared address space setting.  */
             /*   This is a "negative" flag so the tests are reversed */
             (S_ISNO_SHAREAS(st->st_mode,st->st_genvalue))?
                 fprintf(stream," NO  "): fprintf(stream," YES ");

             /* HFBD_AAUD_READ - auditor read setting                 */
             if ((st->st_auditoraudit & (AUDTREADFAIL+AUDTREADSUCC))
                  == (AUDTREADFAIL+AUDTREADSUCC) )
               tempval = "ALL     ";
             else if (st->st_auditoraudit & AUDTREADFAIL)
               tempval = "FAIL    ";
             else if (st->st_auditoraudit & AUDTREADSUCC)
               tempval = "SUCCESS ";
             else
               tempval = "NONE    ";
             fprintf(stream," %s",tempval);
             /* HFBD_AAUD_WRITE - auditor write setting               */
             if ((st->st_auditoraudit & (AUDTWRITEFAIL+AUDTWRITESUCC))
                  == (AUDTWRITEFAIL+AUDTWRITESUCC) )
               tempval = "ALL     ";
             else if (st->st_auditoraudit & AUDTWRITEFAIL)
               tempval = "FAIL    ";
             else if (st->st_auditoraudit & AUDTWRITESUCC)
               tempval = "SUCCESS ";
             else
               tempval = "NONE    ";
             fprintf(stream," %s",tempval);
             /* HFBD_AAUD_EXEC - auditor execute setting              */
             if ((st->st_auditoraudit & (AUDTEXECFAIL+AUDTEXECSUCC))
                  == (AUDTEXECFAIL+AUDTEXECSUCC) )
               tempval = "ALL     ";
             else if (st->st_auditoraudit & AUDTEXECFAIL)
               tempval = "FAIL    ";
             else if (st->st_auditoraudit & AUDTEXECSUCC)
               tempval = "SUCCESS ";
             else
               tempval = "NONE    ";
             fprintf(stream," %s",tempval);

             /* HFBD_UAUD_READ - owner read setting                   */
             if ((st->st_useraudit & (AUDTREADFAIL+AUDTREADSUCC))
                  == (AUDTREADFAIL+AUDTREADSUCC) )
               tempval = "ALL     ";
             else if (st->st_useraudit & AUDTREADFAIL)
               tempval = "FAIL    ";
             else if (st->st_useraudit & AUDTREADSUCC)
               tempval = "SUCCESS ";
             else
               tempval = "NONE    ";
             fprintf(stream," %s",tempval);
             /* HFBD_UAUD_WRITE - owner write setting                 */
             if ((st->st_useraudit & (AUDTWRITEFAIL+AUDTWRITESUCC))
                  == (AUDTWRITEFAIL+AUDTWRITESUCC) )
               tempval = "ALL     ";
             else if (st->st_useraudit & AUDTWRITEFAIL)
               tempval = "FAIL    ";
             else if (st->st_useraudit & AUDTWRITESUCC)
               tempval = "SUCCESS ";
             else
               tempval = "NONE    ";
             fprintf(stream," %s",tempval);
             /* HFBD_UAUD_EXEC - owner execute setting                */
             if ((st->st_useraudit & (AUDTEXECFAIL+AUDTEXECSUCC))
                  == (AUDTEXECFAIL+AUDTEXECSUCC) )
               tempval = "ALL     ";
             else if (st->st_useraudit & AUDTEXECFAIL)
               tempval = "FAIL    ";
             else if (st->st_useraudit & AUDTEXECSUCC)
               tempval = "SUCCESS ";
             else
               tempval = "NONE    ";
             fprintf(stream," %s",tempval);

             /* HFBD_AUDIT_ID - RACF audit id for this file           */
             fprintf(stream," ");
             for (i=0;i<sizeof(st->st_auditid);++i)
               fprintf(stream,"%02X",(int)st->st_auditid[i]);

             /* HFBD_FID - file identifier                            */
             fprintf(stream," ");
             for (i=0;i<sizeof(st->st_fid);++i)
               fprintf(stream,"%02X",(int)st->st_fid[i]);

             /* HFBD_CREATE_DATE - file create date                   */
             timeptr = localtime(&st->st_createtime);
             ch = strftime(dest,sizeof(dest),"%Y-%m-%d",timeptr);
             fprintf(stream," %s",dest);
             /* HFBD_CREATE_TIME - file create time                   */
             ch = strftime(dest,sizeof(dest),"%H:%M:%S",timeptr);
             fprintf(stream," %s",dest);
             /* HFBD_LASTREF_DATE - file last access date             */
             timeptr = localtime(&st->st_atime);
             ch = strftime(dest,sizeof(dest),"%Y-%m-%d",timeptr);
             fprintf(stream," %s",dest);
             /* HFBD_LASTREF_TIME - file last access date             */
             ch = strftime(dest,sizeof(dest),"%H:%M:%S",timeptr);
             fprintf(stream," %s",dest);
             /* HFBD_LASTCHG_DATE - file last status change date      */
             timeptr = localtime(&st->st_ctime);
             ch = strftime(dest,sizeof(dest),"%Y-%m-%d",timeptr);
             fprintf(stream," %s",dest);
             /* HFBD_LASTCHG_TIME - file last status change date      */
             ch = strftime(dest,sizeof(dest),"%H:%M:%S",timeptr);
             fprintf(stream," %s",dest);
             /* HFBD_LASTDAT_DATE - file last data modification date  */
             timeptr = localtime(&st->st_mtime);
             ch = strftime(dest,sizeof(dest),"%Y-%m-%d",timeptr);
             fprintf(stream," %s",dest);
             /* HFBD_LASTDAT_TIME - file last data modification date  */
             ch = strftime(dest,sizeof(dest),"%H:%M:%S",timeptr);
             fprintf(stream," %s",dest);

             /* HFBD_NUMBER_LINKS - number of links to file           */
             fprintf(stream," %010u",st->st_nlink);


             /* Add a newline character at end of record              */
             fprintf(stream,"\n");
         break;


      default:
         break;
   }
   return (0);
}

/**********************************************************************/
/* mapit:                                                             */
/*    Map the input uid to a RACF user ID, or an input gid to a RACF  */
/*    group name.  A local cache is maintained.  It contains the      */
/*    mappings for the 10 most recently encountered uids and gids.    */
/*    When a match is found, it is moved to the front of the linked   */
/*    list.  When a new entry is needed, it is placed at the head of  */
/*    the list, and if maxcache entries already exist, the last one   */
/*    is removed. Because files within a directory generally have the */
/*    same owner, this should drastically reduce the number of calls  */
/*    to the user/group database, and hence, pathlength and RACF I/O. */
/**********************************************************************/
char*
mapit(const char idtype, int idvalue)
{
   int match = 0;
   int toobig = 0;
   struct passwd *p;
   struct group *grp;
   struct cachelem **cacheptr;    /* ptr to head of relevant cache */
   struct cachelem *tempptr;      /* ptr to current cache element  */

   /* Get cache type appropriate to input type (user or group) */
   if (idtype == usertype)
      cacheptr = &uidcache;
   else
      cacheptr = &gidcache;

   /* Scan the cache for a match on the input uid/gid  */
   for (tempptr = *cacheptr ; tempptr ; tempptr = tempptr->next) {

     if (tempptr->id == idvalue)
       {
        strcpy(outvalue,tempptr->name);
        /* If the cache element is not already at the head of the list,
           move it there now.                                         */
        if (tempptr != *cacheptr)
         {
           /* Dequeue the matched element */
           (tempptr->prev)->next = tempptr->next;
           (tempptr->next)->prev = tempptr->prev;
           /* Insert matched element at head of queue */
           tempptr->prev = (*cacheptr)->prev;
           tempptr->next = *cacheptr;
           ((*cacheptr)->prev)->next = tempptr;
           (*cacheptr)->prev = tempptr;
           *cacheptr = tempptr;
         }
        match = 1;
        break;
       }

     /* Bail out if we've come full circle in the linked list      */
     if (tempptr->next == *cacheptr)
        break;
   }

   /* If no match was found, call to map the id to a name.  Create a */
   /* new cache element and insert it at the front of the list.      */
   if (!match)
    {
     /* Map the id to a name  */
     if (idtype == usertype)
       if ((p = getpwuid(idvalue)) == NULL)
          strcpy(outvalue,"        ");
       else
          strcpy(outvalue,p->pw_name);
     else
       if ((grp = getgrgid(idvalue)) == NULL)
          strcpy(outvalue,"        ");
       else
          strcpy(outvalue,grp->gr_name);

     /* Create a new cache element  */
     tempptr = (struct cachelem*)malloc(sizeof(struct cachelem));
     tempptr->id = idvalue;
     strcpy(tempptr->name,outvalue);

     /* If the cache exists, insert new element as 1st element */
     if (*cacheptr)
      {
       /* Set new element's next and prev ptrs */
       tempptr->prev = (*cacheptr)->prev;
       tempptr->next = *cacheptr;
       /* Set last element's prev ptr to new element   */
       ((*cacheptr)->prev)->next = tempptr;
       /* Set original first's prev ptr to new element */
       (*cacheptr)->prev = tempptr;
       /* Set cache head to new element  */
       *cacheptr = tempptr;
       /* increment the cache counter */
       if (idtype == usertype)
         if (uidcount < maxcache)
           ++uidcount;
         else
           toobig = 1;
       else
         if (gidcount < maxcache)
           ++gidcount;
         else
           toobig = 1;

       /* If maxcache elements has been exceeded, dequeue and free the
          last element.                                               */
       if (toobig)
        {
         tempptr = (*cacheptr)->prev;
         (tempptr->prev)->next = tempptr->next;
         (tempptr->next)->prev = tempptr->prev;
         free(tempptr);
        }
      }
     /* Nothing in cache yet. Initialize cache ptr to this new element,
        and set the element's next and prev ptr to itself.            */
     else
      {
       *cacheptr = tempptr;
       tempptr->next = tempptr;
       tempptr->prev = tempptr;
       if (idtype == usertype)
         uidcount = 1;
       else
         gidcount = 1;
      }
    }

   return(outvalue);
 }
