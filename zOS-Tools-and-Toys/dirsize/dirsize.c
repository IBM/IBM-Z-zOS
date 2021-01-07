/**********************************************************************
** Copyright 1998-2020 IBM Corp.
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
** -----------------------------------------------------------------
**
**  Author: John Pfuntner <pfuntner@pobox.com>
**  Program: dirsize
**
**  Purpose: Display contents of a directory or
**  directories, showing subdirectory structure and the
**  number of bytes in each directory.
**
**  Syntax: dirsize [-i] [-v] [dir ... ]
**
**********************************************************************/

#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <dirent.h>
#include <errno.h>

#define true 1
#define false 0

int verbose=false;
int ignoreMissingSymlinks=false;

struct uniq {
  dev_t dev;
  ino_t node;
  struct uniq *next;
} *uniques=NULL;

void unique_init() {
  struct uniq *temp;

  while (uniques != NULL) {
    temp = uniques;
    uniques = uniques->next;
    free(temp);
  }
}

int unique(struct stat Stat) {
  struct uniq *temp;

  /* have we counted this file before? */

  for (temp = uniques; temp != NULL; temp = temp->next)
    if ((Stat.st_dev == temp->dev) && (Stat.st_ino == temp->node))
      return false; /* not unique */

  /* unique */

  if (verbose) printf("inode %d (dev %d) is unique %d\n", Stat.st_ino, Stat.st_dev, Stat.st_size);

  temp = (struct uniq*) malloc(sizeof(struct uniq));
  temp->next = uniques;
  temp->dev  = Stat.st_dev;
  temp->node = Stat.st_ino;
  uniques    = temp;
  return true;
}

int ignore(char *dir, char *file) {
  struct stat Stat;
  char *name;
  int ret;

  if (!ignoreMissingSymlinks) return false;
  strcpy(name=(char*)malloc(strlen(dir)+strlen(file)+2), dir);
  strcat(name, "/");
  strcat(name, file);
  ret = lstat(name, &Stat);
  free(name);
  return ((ret == 0) && (S_ISLNK(Stat.st_mode)));
}

int get_stat(char *dir, char *file, struct stat *Stat) {
  char *name;
  int ret;
  strcpy(name=(char*)malloc(strlen(dir)+strlen(file)+2), dir);
  strcat(name, "/");
  strcat(name, file);
  ret = stat(name, Stat);
  free(name);
  return ret;
}

double traverse(char *pref, char *suff, int depth) {
  DIR *stream;
  struct dirent *dirent;
  struct stat Stat;
  char *dir, *newname;
  double temp, ret;
  int done, i;

  if (strlen(suff) > 0) {
    dir = (char*) malloc(strlen(pref)+strlen(suff)+2);
    if (strcmp(pref, "/") == 0)
      strcpy(dir, "");
    else
      strcpy(dir, pref);
    strcat(dir, "/");
    strcat(dir, suff);
  }
  else {
    dir = pref;
    unique_init();
  }

  ret = 0;
  if ((stream = opendir(dir)) == NULL) {
    if ((errno == EACCES) || (errno == EPERM))
      fprintf(stderr, "cannot access %s\n", dir);
    else {
      fprintf(stderr, "opendir() error for %s: %s\n", dir,
              strerror(errno));
      ret = -1;
    }
  }

  errno = 0;
  if (stream != NULL) {

    /* do subdirectories first */

    done = false;
    while ((!done) && (ret != -1)) {
      errno = 0;
      if ((dirent = readdir(stream)) == NULL) {
        if (errno == 0) done = true;
        else if ((errno == EACCES) || (errno == EPERM))
          fprintf(stderr, "readdir() cannot access entry in %s\n", dir);
        else {
          fprintf(stderr, "readdir() error in %s directory: %s\n",
                  dir, strerror(errno));
          ret = -1;
          done = true;
        }
      }
      else {
        errno = 0;
        if (get_stat(dir, dirent->d_name, &Stat) != 0) {
          if (!ignore(dir, dirent->d_name)) {
            fprintf(stderr, "stat() error for %s/%s: %s\n",
                    dir, dirent->d_name, strerror(errno));
            ret = -1;
            done = true;
          }
        }
        else if (S_ISDIR(Stat.st_mode)) {
          if ((strcmp(dirent->d_name, ".")  != 0) &&
              (strcmp(dirent->d_name, "..") != 0)) {
            if ((temp = traverse(dir, dirent->d_name, depth+1)) == -1) {
              ret = -1;
              done = true;
            }
            else {
              ret += temp;
              if (verbose) printf("traverse(%s) now %.0f\n", dir, ret);
            }
          }
        }
      }
    }

    if (ret != -1) {

      /* now go back and pick up remaining files we haven't seen yet */

      rewinddir(stream);
      done = false;
      while ((!done) && (ret != -1)) {
        errno = 0;
        if ((dirent = readdir(stream)) == NULL) {
          if (errno == 0) done = true;
          else if ((errno != EACCES) && (errno != EPERM)) {
            fprintf(stderr, "readdir() error in %s directory: %s\n",
                    dir, strerror(errno));
            ret = -1;
            done = true;
          }
        }
        else {
          errno = 0;
          if (get_stat(dir, dirent->d_name, &Stat) != 0) {
            if (!ignore(dir, dirent->d_name)) {
              fprintf(stderr, "stat() error for %s/%s: %s\n",
                      dir, dirent->d_name, strerror(errno));
              ret = -1;
              done = true;
            }
          }
          else if ((!S_ISDIR(Stat.st_mode)) && unique(Stat)) {
            ret += Stat.st_size;
            if (verbose) printf("traverse(%s) now %.0f\n", dir, ret);
          }
        }
      }
    }
  }

  if ((stream != NULL) && (closedir(stream) != 0) && (ret != -1)) {
    fprintf(stderr, "closedir() error for %s: %s\n", dir,
            strerror(errno));
    return -1;
  }

  if (ret != -1) {
    for (i=0; i<depth; i++)
      printf("  ");
    printf("%s contains %.0f bytes\n", dir, ret);
  }

  if (strlen(suff) > 0) free(dir);

  return ret;
}

syntax(char *pgm) {
  fprintf(stderr, "%s: {-i} {-v} {dir ...}\n", pgm);
  exit(1);
}

main(int argc, char **argv) {
  int c;
  extern int optind;

  setbuf(stdout, NULL);
  setbuf(stderr, NULL);

  while ((c = getopt(argc, argv, "iv")) != -1) {
    switch (c) {
      case 'i': ignoreMissingSymlinks ^= true; break;
      case 'v': verbose ^= true; break;
      default: syntax(argv[0]);
    }
  }

  if (optind >= argc) traverse(".", "", 0);
  else while (optind < argc) {
    traverse(argv[optind], "", 0);
    optind++;
    if (optind < argc) puts("------------------------------------------------");
  }
}
