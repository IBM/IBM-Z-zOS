/**********************************************************************
** Copyright 1999-2023 IBM Corp.
**
**  Licensed under the Apache License, Version 2.0 (the "License");
**  you may not use this file except in compliance with the License.
**  You may obtain a copy of the License at
**
**     http://www.apache.org/licenses/LICENSE-2.0
**
**  Unless required by applicable law or agreed to in writing,
**  software distributed under the License is distributed on an
**  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
**  either express or implied. See the License for the specific
**  language governing permissions and limitations under the
**  License.
**
** -----------------------------------------------------------------
**
** Disclaimer of Warranties:
**
**   The following enclosed code is sample code created by IBM
**   Corporation.  This sample code is not part of any standard
**   IBM product and is provided to you solely for the purpose
**   of assisting you in the development of your applications.
**   The code is provided "AS IS", without warranty of any kind.
**   IBM shall not be liable for any damages arising out of your
**   use of the sample code, even if they have been advised of
**   the possibility of such damages.
**
***********************************************************************/
/*--------------------------------------------------------------*/
/* Program: sparse                                              */
/* Purpose: Creates sparse files.                               */
/* Author : Steve Stiert                                        */
/* Date   : 09/09/99                                            */
/*                                                              */
/* Compile using :                                              */
/*                                                              */
/*     xlc -o sparse -Wc,xplink -Wl,xplink,edit=no sparse.c     */
/*--------------------------------------------------------------*/
#define _LARGE_FILES 1 /* enable support for large files         */
#define _POSIX_SOURCE
#define _XOPEN_SOURCE 600

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <unistd.h>

#define VERSION_MAJOR 1
#define VERSION_MINOR 1

#define ONEKILOBYTE 0x400
#define ONEMEGABYTE 0x100000
#define ONEGIGABYTE 0x40000000

/**
 * @brief Display usage information.
 *
 */
void usage(void) {

  fprintf(stderr, "sparse [-lv] [-s size] [-r repeat] -f filename\n");
  fprintf(stderr, "                                                                    \n");
  fprintf(stderr, " -f filename : Name of file to create.                              \n");
  fprintf(stderr, " -l          : Prefix a line number before each repeat string in the\n");
  fprintf(stderr, "               format \"lineno repeat_str\"                         \n");
  fprintf(stderr, " -r string   : Specify a string to be repeated until the file       \n");
  fprintf(stderr, "               reaches the required size.   Turns off sparse file.  \n");
  fprintf(stderr, "               Max string length=1022.                              \n");
  fprintf(stderr, " -s size     : size of file to create.  Size can be prefaced with   \n");
  fprintf(stderr, "               one of the following letters:                        \n");
  fprintf(stderr, "                 k: size is in kilobytes                            \n");
  fprintf(stderr, "                 m: size is in megabytes                            \n");
  fprintf(stderr, "                 g: size is in gigabytes                            \n");
  fprintf(stderr, "               Example: sparse -s g3 -f testfile                    \n");
  fprintf(stderr, " -v          : Enable verbose output.                               \n");
  fprintf(stderr, " -V          : Display version information.                         \n");
}

/**
 * @brief Converts a character string into an unsigned long long.
 *
 * @param numstr Character string containing a number.
 * @return Converted numeric value of the string, or -1 on error.
 */
unsigned long long getnum(char *numstr) {
  unsigned long long num;
  char *outstr;

  num = strtoull(numstr, &outstr, 0);
  if (strlen(outstr) != 0)
    num = -1;

  return (num);
}

/**
 * @brief Main program.
 *
 * @param argc
 * @param argv
 * @return int
 */
int main(int argc, char *argv[]) {
  int rc;
  int n, left;
  unsigned long long lineno = 0;
  unsigned long long size;
  unsigned long long total;
  unsigned long long offset;
  char filename[1024] = {0};
  char repeat_str[1024];
  char last_str[1024 + 20];
  char string[1024];
  size_t amount = 512;

  FILE *fd;

  int opt;
  int fopt = 0; /* filename option */
  int vopt = 0; /* verbose option */
  int ropt = 0; /* repeat string */
  int lopt = 0; /* line numbers */
  int sopt = 0; /* size option */

  /*----------------------------------------------------------------------------*/
  /* Parse options.  Note: option flags are initialized to their default value  */
  /* when they are first declared.                                              */
  /*----------------------------------------------------------------------------*/
  while ((opt = getopt(argc, argv, "f:lr:s:vV")) != -1) {
    switch (opt) {
    /*---------------------------------------------------*/
    /* f: Specify filename.                              */
    /*---------------------------------------------------*/
    case 'f':
      strcpy(filename, optarg);
      fopt = 1;
      break;

    /*---------------------------------------------------*/
    /* l: line option                                    */
    /*---------------------------------------------------*/
    case 'l':
      lopt = 1;
      break;

    /*---------------------------------------------------*/
    /* r: Specify a repeat string.                       */
    /*---------------------------------------------------*/
    case 'r':
      strcpy(repeat_str, optarg);
      ropt = 1;
      if ((strlen(repeat_str)) > 1022) {
        fprintf(stderr,
                "sparse: Repeat string cannot exceed 1022.  Yours is %lu.\n",
                strlen(repeat_str));
        usage();
        exit(1);
      }
      /*
      if (ropt && (repeat_str[0]=='\0'))
        {
         fprintf(stderr,"sparse: You must specify a repeat string on the -r
      option.\n"); exit(usage(1));
        }
          */
      break;

    /*---------------------------------------------------*/
    /* s: size option.                                   */
    /*---------------------------------------------------*/
    case 's':
      switch (tolower(optarg[0])) {
      case 'g':
        size = ONEGIGABYTE * getnum(optarg + 1);
        break;
      case 'm':
        size = ONEMEGABYTE * getnum(optarg + 1);
        break;
      case 'k':
        size = ONEKILOBYTE * getnum(optarg + 1);
        break;
      default:
        size = getnum(optarg);
      }
      break;

    /*---------------------------------------------------*/
    /* v: verbose output option                          */
    /*---------------------------------------------------*/
    case 'v':
      vopt = 1;
      break;

    case 'V':
      printf("sparse v%d.%d\n", VERSION_MAJOR, VERSION_MINOR);
      exit(0);
      break;

    default:
      usage();
      exit(1);
      break;
    }
  }

  /*----------------------------------------------------------------------------*/
  /* Sanity checks.                                                             */
  /*----------------------------------------------------------------------------*/
  if (!fopt) {
    fprintf(stderr,
            "sparse: A filename must be specified with the -f option\n");
    usage();
    exit(1);
  }

  if (vopt) {
    fprintf(stderr, "sparse: filename=\"%s\"\n", filename);
    fprintf(stderr, "        size    =%llu (0x%llX)\n", size, size);
    if (ropt)
      fprintf(stderr, "        repeat string=\"%s\"\n", repeat_str);
    if (lopt)
      fprintf(stderr, "        line # option=Yes\n");
  }

  /*---------------------------------------------------------------------*/
  /* Check if specified file exists, if so, then call open with read     */
  /* option (we don't want to destroy a file!).  If not, then open with  */
  /* write option.                                                       */
  /*---------------------------------------------------------------------*/
  if (access(filename, F_OK) == 0) { /* exists */
    if (vopt)
      fprintf(stderr, "sparse: %s exists, overwriting.\n", filename);
  }

  fd = fopen(filename, "w");

  if (fd == NULL) {
    fprintf(stderr, "sparse: could not open \"%s\", errno=%d (%s)\n", filename,
            errno, strerror(errno));
    exit(1);
  }
  if (vopt) {
    fprintf(stderr, "sparse: Successfully opened %s\n", filename);
  }

  /*=====================================================================*/
  /* If the -r option is used, fill up the file with repetitions of the  */
  /* repeat string.  Truncate the last line if necessary.  Prefix the    */
  /* line number if -l specified.                                        */
  /*=====================================================================*/
  if (ropt) {
    if (vopt) {
      fprintf(stderr, "sparse: writing repeat string to file.\n");
    }

    total = 0;
    lineno = 0;
    while (total < size) {
      ++lineno;
      if (lopt) {
        n = fprintf(fd, "%llu %s\n", lineno, repeat_str);
      } else
        n = fprintf(fd, "%s\n", repeat_str);

      if (n < 0) {
        fprintf(stderr, "sparse: error writing repeat string. errno=%d (%s)\n",
                errno, strerror(errno));
        exit(1);
      }
      total += n;

      /*---------------------------------------------------------*/
      /* if we are getting close to the end, calculate if there  */
      /* is enough space to .  For performance reasons, we don't */
      /* want to calculate the actual length every time.         */
      /*---------------------------------------------------------*/
      if ((total + n) > size) {
        ++lineno;
        if (lopt) {
          sprintf(last_str, "%llu %s\n", lineno, repeat_str);
        } else
          sprintf(last_str, "%s\n", repeat_str);

        last_str[(size - total) - 1] = '\0';
        n = fprintf(fd, "%s\n", last_str);
        total += n;
      }
    }

    fprintf(stderr, "sparse: %llu lines written.\n", lineno);
  }

  /*=====================================================================*/
  /* Else, we are creating a sparse file.                                */
  /*=====================================================================*/
  else {
    /*------------------------------------------------------------------*/
    /* Write a string to the beginning of the file.                     */
    /*------------------------------------------------------------------*/
    snprintf(string, sizeof(string), "This is a sparse file of size %llu\n",
             size);
    amount = fwrite(string, 1, strlen(string), fd);
    if (amount != strlen(string)) {
      fprintf(stderr, "sparse: writing header string to file failed.\n");
      fprintf(stderr, "        amount=%ld, errno=%d (%s)\n", amount, errno,
              strerror(errno));
      exit(1);
    }

    if (vopt) {
      fprintf(stderr, "sparse: wrote %ld header string bytes to file.\n",
              amount);
    }

    /*---------------------------------------------------------------------*/
    /* Write a trailer string at the end of the file.  The total file size */
    /* must be size, so we must subtract the size of the end record.       */
    /*---------------------------------------------------------------------*/
    snprintf(string, sizeof(string), "\nEnd of sparse file of size %llu\n",
             size);
    offset = size - strlen(string);
    if ((rc = fseeko(fd, offset, SEEK_SET)) != 0) {
      fprintf(stderr, "sparse: fseeko failed.\n");
      fprintf(stderr, "        offset=%llu, errno=%d (%s)\n", offset, errno,
              strerror(errno));
      exit(1);
    }
    if (vopt) {
      fprintf(stderr, "sparse: fseeko %llu successful\n", offset);
    }

    amount = fwrite(string, 1, strlen(string), fd);
    if (amount != strlen(string)) {
      fprintf(stderr, "sparse: writing trailer string to file failed.\n");
      fprintf(stderr, "        amount=%ld, errno=%d (%s)\n", amount, errno,
              strerror(errno));
      exit(1);
    }
    if (vopt) {
      fprintf(stderr, "sparse: wrote %ld trailer string bytes to file.\n",
              amount);
    }

  } /*--  end sparse file creation ----------------------------------*/

  /*---------------------------------------------------------------------*/
  /* Close file.                                                         */
  /*---------------------------------------------------------------------*/
  fclose(fd);
  if (vopt) {
    fprintf(stderr, "sparse: closing %s\n", filename);
  }

  exit(rc);
}
