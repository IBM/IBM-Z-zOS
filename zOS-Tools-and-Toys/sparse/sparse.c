/*--------------------------------------------------------------*/
/* Program: sparse                                              */
/* Purpose: Creates sparse files.                               */
/* Owner  : Steve Stiert                                        */
/* Date   : 09/09/99                                            */
/*                                                              */
/* Compile using :                                              */
/*                                                              */
/*     c99 -o sparse -Wc,xplink -Wl,xplink,edit=no sparse.c     */
/*--------------------------------------------------------------*/
#define _LARGE_FILES 1     /* enable support for large files         */
#define _XOPEN_SOURCE
#define _POSIX_SOURCE
#define _OE_SOCKETS

#include <sys/types.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <unistd.h>

#define ONEKILOBYTE  0x400
#define ONEMEGABYTE  0x100000
#define ONEGIGABYTE  0x40000000

/*-------------------------------------*/
/* Prototypes                          */
/*-------------------------------------*/
int usage(int frc);
unsigned long long getnum(char * numstr);
char * display_errno(int num);

/*-------------------------------------*/
/* Global Variables                    */
/*-------------------------------------*/
int opt;
int fopt=0;   /* filename option */
int vopt=0;   /* keep option */
int ropt=0;   /* repeat string */
int lopt=0;   /* line numbers */
int sopt=0;   /* keep option */


int main(int argc, char *argv[])
{
 int rc;
 int strlen;
 int n, left;
 unsigned long long lineno=0;
 unsigned long long size;
 unsigned long long total;
 unsigned long long offset;
 char filename[1024];
 char repeat_str[1024];
 char last_str[1024+20];
 char string[1024];
 size_t amount;

 FILE * fd;

 const char* optionstr = "f:lr:s:v";

/*----------------------------------------------------------------------------*/
/* Initialize some things...                                                  */
/*----------------------------------------------------------------------------*/
 filename[0]='\0';
 size= 512;

/*----------------------------------------------------------------------------*/
/* Parse options.  Note: option flags are initialized to their default value  */
/* when they are first declared.                                              */
/*----------------------------------------------------------------------------*/
 while ((opt=getopt(argc, argv, optionstr)) != -1)
   {
    switch(opt)
      {
       /*---------------------------------------------------*/
       /* f: Specify filename.                              */
       /*---------------------------------------------------*/
       case 'f': strcpy(filename,optarg);
                 fopt=1;
                 break;

       /*---------------------------------------------------*/
       /* l: verbose output option                          */
       /*---------------------------------------------------*/
       case 'l': lopt=1;
                 break;

       /*---------------------------------------------------*/
       /* r: Specify a repeat string.                       */
       /*---------------------------------------------------*/
       case 'r': strcpy(repeat_str,optarg);
                 ropt=1;
                 if ((strlen(repeat_str))>1022)
                   {
                    fprintf(stderr,"sparse: Repeat string cannot exceed 1022.  Yours is %u.\n",
                                   strlen(repeat_str));
                    exit(usage(1));
                   }
                 /*
                 if (ropt && (repeat_str[0]=='\0'))
                   {
                    fprintf(stderr,"sparse: You must specify a repeat string on the -r option.\n");
                    exit(usage(1));
                   }
                     */
                 break;

       /*---------------------------------------------------*/
       /* s: size option.                                   */
       /*---------------------------------------------------*/
       case 's': vopt=1;
                 switch (optarg[0])
                  {
                   case 'g': size=ONEGIGABYTE * getnum(optarg+1);
                             break;
                   case 'm': size=ONEMEGABYTE * getnum(optarg+1);
                             break;
                   case 'k': size=ONEKILOBYTE * getnum(optarg+1);
                             break;
                   default:  size=getnum(optarg);
                  }
                 break;

       /*---------------------------------------------------*/
       /* v: verbose output option                          */
       /*---------------------------------------------------*/
       case 'v': vopt=1;
                 break;

       default:  exit(usage(1));
                 break;
      }
   }


/*----------------------------------------------------------------------------*/
/* Sanity checks.                                                             */
/*----------------------------------------------------------------------------*/
if (!fopt)
  {
   fprintf(stderr,"sparse: A filename must be specified with the -f option\n");
   exit(usage(1));
  }

if (vopt)
  {
   fprintf(stderr,"sparse: filename=\"%s\"\n",filename);
   fprintf(stderr,"        size    =%llu (0x%llX)\n",size,size);
   if (ropt)
     fprintf(stderr,"        repeat string=\"%s\"\n",repeat_str);
   if (lopt)
     fprintf(stderr,"        line # option=Yes\n");
  }

/*---------------------------------------------------------------------*/
/* Check if specified file exists, if so, then call open with read     */
/* option (we don't want to destroy a file!).  If not, then open with  */
/* write option.                                                       */
/*---------------------------------------------------------------------*/
 if ( access(filename,F_OK)==0 )
   {                               /* exists */
    if (vopt)
      fprintf(stderr,"sparse: %s exists, overwriting.\n",filename);
   }

 fd=fopen(filename, "w");

 if (fd==NULL)
   {
    fprintf(stderr,"sparse: could not open \"%s\", errno=%d (%s)\n",
            filename,errno, display_errno(errno));
    exit(1);
   }
 if (vopt)
   {
    fprintf(stderr,"sparse: Successfully opened %s\n", filename);
   }


/*=====================================================================*/
/* If the -r option is used, fill up the file with repetitions of the  */
/* repeat string.  Truncate the last line if necessary.  Prefix the    */
/* line number if -l specified.                                        */
/*=====================================================================*/
 if (ropt)
   {
    if (vopt)
      {
       fprintf(stderr,"sparse: writing repeat string to file.\n");
      }

    total=0;
    lineno=0;
    while (total < size)
      {
       ++lineno;
       if (lopt)
         {
          n= fprintf(fd,"%llu %s\n",lineno,repeat_str);
         }
        else
          n= fprintf(fd,"%s\n",repeat_str);

       if (n<0)
         {
          fprintf(stderr,"sparse: error writing repeat string. errno=%d (%s)\n",
                  filename,errno, display_errno(errno));
          exit(1);
         }
       total+=n;

       /*---------------------------------------------------------*/
       /* if we are getting close to the end, calculate if there  */
       /* is enough space to .  For performance reasons, we don't */
       /* want to calculate the actual length every time.         */
       /*---------------------------------------------------------*/
       if ( (total+n) > size)
         {
          ++lineno;
          if (lopt)
            {
             sprintf(last_str,"%llu %s\n",lineno,repeat_str);
            }
           else
             sprintf(last_str,"%s\n",repeat_str);

          last_str[(size-total)-1]='\0';
          n= fprintf(fd,"%s\n",last_str);
          total+=n;
         }
      }


    fprintf(stderr,"sparse: %llu lines written.\n",lineno);
   }

/*=====================================================================*/
/* Else, we are creating a sparse file.                                */
/*=====================================================================*/
 else
   {
   /*------------------------------------------------------------------*/
   /* Write a string to the beginning of the file.                     */
   /*------------------------------------------------------------------*/
    sprintf(string,"This is a sparse file of size %llu\n",size);
    amount= fwrite(string, 1, strlen(string),fd);
    if (amount!=strlen(string))
      {
       fprintf(stderr,"sparse: writing header string to file failed.\n");
       fprintf(stderr,"        amount=%d, errno=%d (%s)\n",amount,
                               errno, display_errno(errno));
       exit(1);
      }

    if (vopt)
      {
       fprintf(stderr,"sparse: wrote %d header string bytes to file.\n",amount);
      }

   /*---------------------------------------------------------------------*/
   /* Write a trailer string at the end of the file.  The total file size */
   /* must be size, so we must subtract the size of the end record.       */
   /*---------------------------------------------------------------------*/
    sprintf(string,"\nEnd of sparse file of size %llu\n",size);
    offset=size-strlen(string);
    if ( (rc= fseeko(fd,offset, SEEK_SET))!=0)
      {
       fprintf(stderr,"sparse: fseeko failed.\n");
       fprintf(stderr,"        offset=%llu, errno=%d (%s)\n",offset,
                               errno, display_errno(errno));
       exit(1);
      }
    if (vopt)
      {
       fprintf(stderr,"sparse: fseeko %llu successful\n",offset);
      }

    amount= fwrite(string, 1, strlen(string),fd);
    if (amount!=strlen(string))
      {
       fprintf(stderr,"sparse: writing trailer string to file failed.\n");
       fprintf(stderr,"        amount=%d, errno=%d (%s)\n",amount,
                               errno, display_errno(errno));
       exit(1);
      }
    if (vopt)
      {
       fprintf(stderr,"sparse: wrote %d trailer string bytes to file.\n",amount);
      }

   }  /*--  end sparse file creation ----------------------------------*/


/*---------------------------------------------------------------------*/
/* Close file.                                                         */
/*---------------------------------------------------------------------*/
 fclose(fd);
 if (vopt)
   {
    fprintf(stderr,"sparse: closing %s\n",filename);
   }

exit(rc);
}


/*=====================================================================*/
/* Function: getnum                                                    */
/* Purpose : Converts a character string into an unsigned int.         */
/*---------------------------------------------------------------------*/
unsigned long long getnum(char * numstr)
{
 unsigned long long num;
 char * outstr;

 num= strtoull(numstr,&outstr,0);
 if (strlen(outstr)!=0)
   num=-1;

 return(num);
}


/*----------------------------------------------------------*/
/* Function: display_errno                                  */
/* Purpose:  Converts an errno value into an errno name     */
/*----------------------------------------------------------*/
char * display_errno(int num)
{
 switch (num)
   {
    case 0     : return("no error"); break;
    case EACCES   : return("EACCES"); break;
    case EAGAIN   : return("EAGAIN"); break;
    case EBUSY    : return("EBUSY"); break;
    case EEXIST   : return("EEXIST"); break;
    case EINTR    : return("EINTR"); break;
    case EINVAL   : return("EINVAL"); break;
    case EIO      : return("EIO"); break;
    case EISDIR   : return("EISDIR"); break;
    case ELOOP    : return("ELOOP"); break;
    case EMFILE   : return("EMFILE"); break;
    case ENAMETOOLONG: return("ENAMETOOLONG"); break;
    case ENFILE   : return("ENFILE"); break;
    case ENOENT   : return("ENOENT"); break;
    case ENOMEM   : return("ENOMEM"); break;
    case ENOSPC   : return("ENOSPC"); break;
    case ENOSYS   : return("ENOSYS"); break;
    case ENOTDIR  : return("ENOTDIR"); break;
    case ENXIO    : return("ENXIO"); break;
    case EOVERFLOW: return("EOVERFLOW"); break;
    case EPERM    : return("EPERM"); break;
    case EROFS    : return("EROFS"); break;
    default:     return("unknown");
   }
}


/*=====================================================================*/
/* Function: usage                                                     */
/* Purpose : Displays help.                                            */
/*---------------------------------------------------------------------*/
int usage(int frc)
{
 fprintf(stderr,"sparse [-vl] [-s size] [-r repeat] -f filename             \n");
 fprintf(stderr,"                                                                    \n");
 fprintf(stderr," -f filename : Name of file to create.                              \n");
 fprintf(stderr," -s size     : size of file to create.  Size can be prefaced with   \n");
 fprintf(stderr,"               one of the following letters:                        \n");
 fprintf(stderr,"                 k: size is in kilobytes                            \n");
 fprintf(stderr,"                 m: size is in megabytes                            \n");
 fprintf(stderr,"                 g: size is in gigabytes                            \n");
 fprintf(stderr,"               Example: sparse -s g3 -f testfile                    \n");
 fprintf(stderr," -r string   : Specify a string to be repeated until the file       \n");
 fprintf(stderr,"               reaches the required size.   Turns off sparse file.  \n");
 fprintf(stderr,"               Max string length=1022.                              \n");
 fprintf(stderr," -l          : Prefix a line number before each repeat string in the\n");
 fprintf(stderr,"               format \"lineno repeat_str\"                         \n");
 fprintf(stderr," -v          : Verbose                                              \n");
 return(frc);
}

