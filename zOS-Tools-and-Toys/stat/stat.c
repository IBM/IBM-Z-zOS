/**********************************************************************
** Copyright 1994-2020 IBM Corp.
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
**  Author: John Pfuntner <pfuntner@pobox.com>
**  Program: stat
**  Version: 1.1
**
**  Purpose: Displays stat() information on specified
**  filenames.
**
**  Syntax: stat file [...]
**
**  change history:
**    version 1.0: July 1994: original release
**    version 1.1: July 1997: fixed <stat.h> include
***********************************************************************/

#define _OPEN_SYS
#include <sys/mntent.h>
#include <sys/types.h>
#include <stdio.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <errno.h>
#include <pwd.h>
#include <grp.h>
#include <time.h>
#include <unistd.h>
#include <string.h>

#define false 0
#define true  1

static char unknown[]="Unknown";

char *my_ctime(time_t *T) {
  struct tm t;
  static char ret[80];

  t = *localtime(T);
  strftime(ret, sizeof(ret), "%a %b %d %Y %r %Z\n", &t);
  return ret;
}

char *clone(char *s) {
  char *ret;
  if ((ret = (char*) malloc(strlen(s)+1)) != NULL)
    strcpy(ret, s);
  return ret;
}

char *getuser(uid_t uid) {
  struct passwd *pw;
  char *ret;

  if ((pw = getpwuid(uid)) == NULL) {
    perror("getpwuid() error");
    ret = unknown;
  }
  else ret = clone(pw->pw_name);
  return ret;
}

char *getgroup(gid_t gid) {
  struct group *grp;
  char *ret;

  if ((grp = getgrgid(gid)) == NULL) {
    perror("getgrgid() error");
    ret = unknown;
  }
  else ret = clone(grp->gr_name);
  return ret;
}

char *get_filesys_name(dev_t devnum) {

  int entries, entry;

  char *ret;

  struct {
    struct w_mnth   header;
    struct w_mntent mount_table[10];
  } work_area;

  ret = NULL;

  memset(&work_area, 0x00, sizeof(work_area));
  do {
    if ((entries = w_getmntent((char *) &work_area,
                               sizeof(work_area))) == -1)
      perror("w_getmntent() error");

    else for (entry=0; entry<entries; entry++)
      if (devnum == work_area.mount_table[entry].mnt_dev)
        ret = clone(work_area.mount_table[entry].mnt_fsname);

  } while ((entries > 0) && (ret == NULL));

  return ret;
}

char *strrchrn(char *s, int c, int pos) {
  for (pos--; pos > 0; pos--)
    if (s[pos] == c) return s+pos;
  return NULL;
}

char *resolve(char *fn, char *buf, int len) {
  int i;
  char *s;

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
    else if (strcmp(buf+i, "/.") == 0)
      buf[i] = 0x00;
    else if (strcmp(buf+i, "/..") == 0) {
      if ((s = strrchrn(buf, '/' , i)) == NULL) return NULL;
      *s = 0x00;
      i = 0;
    }
    else i++;
  }
  return buf;
}

void report(char *fn) {
  struct stat st;
  char perm[4], path[1024], X[2], *fs;

  struct { unsigned dir:1;
           unsigned reg:1;
         } flags;

  flags.reg = false;
  flags.dir = false;
  strcpy(X, "X");

  if (stat(fn, &st) != 0)
    fprintf(stderr, "stat() error for %s: %s\n", fn, strerror(errno));
  else {
    printf("Info for '%s':\n", fn);
    if (resolve(fn, path, sizeof(path)) != NULL)
      printf("  The absolute pathname is '%s'\n", path);
    if (S_ISBLK(st.st_mode))
      puts("  It is a block special file");
    else if (S_ISCHR(st.st_mode))
           puts("  It is a character special file");
    else if (S_ISDIR(st.st_mode)) {
           puts("  It is a directory");
           flags.dir = true;
           strcpy(X, "S");
         }
    else if (S_ISFIFO(st.st_mode))
           puts("  It is a FIFO");
    else if (S_ISREG(st.st_mode)) {
           puts("  It is a regular file");
           flags.reg = true;
         }
    else puts("  Cannot determine the type of file");

    printf("  inode: %d, device id: %d ",
           (int) st.st_ino, (int) st.st_dev);
    if ((fs = get_filesys_name(st.st_dev)) != NULL)
      printf("(%s)\n", fs);
    else puts("(unknown f/s)");

    printf("  Permissions: ");

    printf("User: ");
    strcpy(perm, "");
    if (st.st_mode & S_IRUSR)
      strcat(perm, "R");
    if (st.st_mode & S_IWUSR)
      strcat(perm, "W");
    if (st.st_mode & S_IXUSR)
      strcat(perm, X);
    if (strcmp(perm, "") == 0)
      printf("none, ");
    else printf("%s, ", perm);

    printf("Group: ");
    strcpy(perm, "");
    if (st.st_mode & S_IRGRP)
      strcat(perm, "R");
    if (st.st_mode & S_IWGRP)
      strcat(perm, "W");
    if (st.st_mode & S_IXGRP)
      strcat(perm, X);
    if (strcmp(perm, "") == 0)
      printf("none, ");
    else printf("%s, ", perm);

    printf("Other: ");
    strcpy(perm, "");
    if (st.st_mode & S_IROTH)
      strcat(perm, "R");
    if (st.st_mode & S_IWOTH)
      strcat(perm, "W");
    if (st.st_mode & S_IXOTH)
      strcat(perm, X);
    if (strcmp(perm, "") == 0)
      printf("none\n");
    else printf("%s\n", perm);

    if (st.st_mode & S_ISUID)
      puts("  ===> The setuid bit is on.");
    if (st.st_mode & S_ISGID)
      puts("  ===> The setgid bit is on.");
    if (st.st_mode & S_ISVTX)
      puts("  ===> The sticky bit is on.");

    if (!flags.dir)
      printf("  There are %d links to this file\n", st.st_nlink);

    printf("  Owning user: %s (%d)    Owning group %s (%d)\n",
           getuser(st.st_uid),  (int) st.st_uid,
           getgroup(st.st_gid), (int) st.st_gid);

    if (flags.reg)
      printf("  The file has %ld bytes\n", (long) st.st_size);

    printf("  Created:  %s", my_ctime(&st.st_createtime));
    printf("  Accessed: %s", my_ctime(&st.st_atime));
    printf("  ctime:    %s", my_ctime(&st.st_ctime));
    printf("  mtime:    %s", my_ctime(&st.st_mtime));
  }
}

main(int argc, char **argv) {
  int i;

  for (i=1; i<argc; i++) {
    if (i>1) puts("");
    report(argv[i]);
  }
}
