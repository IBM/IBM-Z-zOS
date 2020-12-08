/*
 *  Author: John Pfuntner
 *  Program: ifind
 *
 *  Copyright 1994, IBM Corporation
 *  All rights reserved
 *
 *  Purpose: Locates files in a filesystem with the same
 *  inode as a specified filename or inode.
 *
 *  Syntax: ifind {filename|inode} [...]
 */

#define _OPEN_SYS
#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <dirent.h>
#include <errno.h>
#include <sys/mntent.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdlib.h>

#define true 1
#define false 0

int get_stat(char *dir, char *file, struct stat *Stat) {
  char *name;
  int ret;
  strcpy(name=(char*)malloc(strlen(dir)+strlen(file)+2), dir);
  strcat(name, "/");
  strcat(name, file);
  ret = lstat(name, Stat);
  free(name);
  return ret;
}

char *strrchrn(char *s, int c, int pos) {
  for (pos--; pos > 0; pos--)
    if (s[pos] == c) return s+pos;
  return NULL;
}

char *resolve(char *dir, char *fn, int len, char *buf) {
  int i;
  char *s;

  if (dir != NULL) {
    strcpy(buf, dir);
    strcat(buf, "/");
    strcat(buf, fn);
    return buf; /* hopefully, this is already "normalized" */
  }
  if (fn[0] == '/')
    strcpy(buf, fn);
  else {
    if (getcwd(buf, len) == NULL) return NULL;
    strcat(buf, "/");
    strcat(buf, fn);
  }

  /* now, we need to "normalize" the pathname by removing
     things like "//", "/./", and "/../". */

  i=0;
  while (i < strlen(buf)) {
    if (strncmp(buf+i, "//", 2) == 0)
      strcpy(buf+i, buf+i+1);
    else if (strncmp(buf+i, "/./", 3) == 0)
      strcpy(buf+i, buf+i+2);
    else if (strncmp(buf+i, "/../", 4) == 0) {
      if ((s = strrchrn(buf, '/' , i)) == NULL) return NULL;
      else if (s == buf) { /* is '/../' at beginning of string? */
        strcpy(buf, buf+3);
        i = 0;
      }
      else { /* '/../' is somewhere after beginning of string */
        /* turn "/a/../b" into "/b" */
        strcpy(s, buf+i+3);
        i = s-buf;
      }
    }
    else i++;
  }
  return buf;
}

long traverse(char *pref, char *suff, dev_t device, ino_t o_inode,
              char *o_fn) {
  DIR *stream;
  struct dirent *dirent;
  struct stat Stat;
  char *dir;
  char path[1024];
  long error;
  int found, done, i;

  if (strlen(suff) > 0) {
    dir = (char*) malloc(strlen(pref)+strlen(suff)+2);
    if (strcmp(pref, "/") == 0)
      strcpy(dir, "");
    else
      strcpy(dir, pref);
    strcat(dir, "/");
    strcat(dir, suff);
  }
  else
    dir = pref;

  error = 0;
  if ((stream = opendir(dir)) == NULL) {
    if ((errno == EACCES) || (errno == EPERM))
      fprintf(stderr, "cannot access %s\n", dir);
    else {
      fprintf(stderr, "opendir() error for %s: %s\n", dir,
              strerror(errno));
      error++;
    }
  }

  errno = 0;
  if (stream != NULL) {

    done = false;
    while (!done) {
      errno = 0;
      if ((dirent = readdir(stream)) == NULL) {
        if (errno == 0) done = true;
        else if ((errno == EACCES) || (errno == EPERM))
          fprintf(stderr, "readdir() cannot access entry in %s\n", dir);
        else {
          fprintf(stderr, "readdir() error in %s directory: %s\n",
                  dir, strerror(errno));
          error++;
        }
      }
      else {
        errno = 0;
        if (get_stat(dir, dirent->d_name, &Stat) != 0)
          error++;
        else if (S_ISDIR(Stat.st_mode)) {
          if ((strcmp(dirent->d_name, ".")  != 0) &&
              (strcmp(dirent->d_name, "..") != 0) &&
              (Stat.st_dev == device))
            error += traverse(dir, dirent->d_name, device, o_inode,
                              o_fn);
        }
        else if ((Stat.st_ino == o_inode) && (Stat.st_dev == device)) {
          if (o_fn == NULL) found = true;
          else {
            if (resolve(dir, dirent->d_name, sizeof(path),
                        path) == NULL) {
              fprintf(stderr,
                      "cannot obtain absolute pathname of %s/%s: %s\n",
                      dir, dirent->d_name, strerror(errno));
              found = false;
              error++;
            }
            else found = strcmp(path, o_fn) != 0;
          }
          if (found)
            printf("%s/%s\n", dir, dirent->d_name);
        }
      }
    }
  }

  if ((stream != NULL) && (closedir(stream) != 0) && (!errno)) {
    fprintf(stderr, "closedir() error for %s: %s\n", dir,
            strerror(errno));
    error++;
  }

  if (strlen(suff) > 0) free(dir);

  return error;
}

char *mount_point(dev_t device) {
  int entries, entry;
  struct {
    struct w_mnth   header;
    struct w_mntent mount_table[10];
  } work_area;
  static char path[1024];

  memset(&work_area, 0x00, sizeof(work_area));
  do {
    if ((entries = w_getmntent((char *) &work_area,
                               sizeof(work_area))) == -1) {
      perror("w_getmntent() error");
      return NULL;
    }
    else for (entry=0; entry<entries; entry++) {
      if (device == work_area.mount_table[entry].mnt_dev)
        return strcpy(path,
                      work_area.mount_table[entry].mnt_mountpoint);
    }
  } while (entries > 0);
  return NULL;
}

int main(int argc, char **argv) {
  int found, i, errors=0;
  struct stat st;
  char digits[]="0123456789";
  char *mntpt, path[1024];

  for (i=1; i<argc; i++) /* argv[i] is either an inode or a filename */
    if (strspn(argv[i], digits) == strlen(argv[i])) { /* inode */

      /* we need to start searching at the mountpoint of */
      /* the current working directory                   */

      if (stat(".", &st) != 0) {
        perror("cannot stat() current working directory");
        errors++;
      }
      else if ((mntpt = mount_point(st.st_dev)) == NULL)
        errors++;
      else {
        fprintf(stderr, "searching for files with inode of %s in %s\n",
                argv[i], mntpt);
        errors += traverse(mntpt, "", st.st_dev, atoi(argv[i]), NULL);
      }
    }
    else { /* assume filename */

      /* we need to get absolute pathname so we don't list the
         specified file.  We only want to see OTHER files that
         have the same inode. */

      if (resolve(NULL, argv[i], sizeof(path), path) == NULL) {
        fprintf(stderr, "cannot obtain absolute pathname of %s: %s\n",
                argv[i], strerror(errno));
        errors++;
      }

      else {
        /* now we work on the inode and f/s device number */
        if (stat(argv[i], &st) != 0) {
          fprintf(stderr, "cannot stat %s: %s\n", argv[i], &st,
                  strerror(errno));
          errors++;
        }
        else if ((mntpt = mount_point(st.st_dev)) == NULL)
          errors++;
        else {
          fprintf(stderr,
                  "searching for links of %s (inode %d) in %s\n",
                  path, st.st_ino, mntpt);
          errors += traverse(mntpt, "", st.st_dev, st.st_ino, path);
        } /* got mount point */
      } /* got absolute pathname */
    } /* this must be a filename */

  return errors;
}
