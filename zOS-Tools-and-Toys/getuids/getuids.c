#define _XOPEN_SOURCE_EXTENDED 1
#define _XOPEN_SOURCE

/*
 * Property of IBM
 * Copyright IBM Corp. 1995, 1998
 * All Rights Reserved.
 *
 * Title: getuids.c
 *
 * Purpose: getuids mainline.  Report on z/OS UNIX users
 *
 * Author: Marc J. Warden <mwarden@us.ibm.com>
 *
 */

#include <stdio.h>
#include <pwd.h>
#include <grp.h>
#include <errno.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define TSIZE 500
#define TGROW 100

struct Apasswd {
	struct passwd A;
	char *pw_grpname;
};

struct Apasswd *bld_t(int*);
void	pw_cpy(struct Apasswd *, struct passwd *);
void	do_reports(struct Apasswd *t, int ents);
int	cf_uid(const void *, const void *);
int	cf_gid(const void *, const void *);
int	cf_nam(const void *, const void *);

struct FLAGS {
	int SORTBYUID:1;
	int DUPUID:1;
	int SORTBYNAME:1;
	int DUPGID:1;
	int H:1;	/* no headers, better for sed/awk */
	int Z:1;	/* the usual helpful debug stuff  */
} flags = {0, 0, 0, 0, 1, 0};

#define sortbyuid	flags.SORTBYUID
#define dupuid		flags.DUPUID
#define sortbyname	flags.SORTBYNAME
#define dupgid		flags.DUPGID
#define h		flags.H
#define z		flags.Z

char *pad = " ";
const char *getoptstr=":abcdehz";
char *cmmd = "";
int tgrow=TGROW;
int tsize=TSIZE;

int main(int argc, char *argv[])
{
	extern char *optarg;
	extern int optind, opterr, optopt;
	int opt;
	struct Apasswd *t;
	int i=0, ents=0;
	cmmd = argv[0];

	h = 1;	/* headings on by default */
	while ((opt = getopt(argc, argv, getoptstr)) != -1) {
		switch (opt) {
			case 'a':	sortbyuid=1;
					break;
			case 'b':	dupuid=1;
					break;
			case 'c':	sortbyname=1;
					break;
			case 'd':	dupgid=1;
					break;
			case 'e':	h=0;
					pad="\t";
					break;
			case 'z':	z=1;
					break;
            case 'h':
			default:	
			fprintf(stderr, 
				"%s usage:\n\n"
				"getuids [-a] [-b] [-c] [-d] [-e] [-h]\n\n"
				"  -a   produce ID listing sorted by UID\n"
				"       (This report contains HOME and PROGRAM)\n"
				"  -b   produce ID listing of shared UIDs\n"
				"  -c   produce ID listing sorted by LOGNAME\n"
				"  -d   produce ID listing of shared GIDs\n"
				"  -e   supress headings and column alignment\n"
                "  -h   display this help message\n"
				"\n"
				"If no options are specified, all reports are produced\n"
				"WITH headings.\n",
				cmmd);
			exit(1);
		}
	}
	if (!sortbyuid && !dupuid && !sortbyname && !dupgid)
		sortbyuid = dupuid = sortbyname = dupgid = 1;

	t = bld_t(&ents);

	do_reports(t, ents);

	free(t);
	t=NULL;
	return 0;
}
struct Apasswd *bld_t(int *ents) {
	struct Apasswd *t, *new;
	struct passwd *id;
	int i=0;
	if ((t = (struct Apasswd *)malloc(tsize * sizeof(struct Apasswd))) == NULL) {
		fprintf(stderr, "%s: malloc() failed.  %s\n", cmmd, strerror(errno));
		exit(1);
	}
	errno=0;
	setpwent();
	
	errno=0;
	while (id = getpwent()) {
		if (errno) {
			fprintf(stderr, "%s: getpwent() failed.  %s\n", cmmd, strerror(errno));
			endpwent();
			free(t);
			exit(1);
		}
		if (z)
			fprintf(stderr, "%d,%5d,%s\n", i, id->pw_uid, id->pw_name); 

		pw_cpy(&(t[i]), id);
		if (z) 
			fprintf(stderr, "%d, %5d-=-%s\n", i, t[i].A.pw_uid, t[i].A.pw_name);
		if (++i > (tsize-1) ) {
			tsize+=tgrow;
			if ((new=realloc(t, tsize * sizeof(struct Apasswd))) == NULL) {
				fprintf(stderr, 
					"%s: realloc() failed.  %s\n", 
					cmmd, strerror(errno));
				free(t);
				endpwent();
				exit(1);
			} else
				t=new;
		}
		errno=0;
	}
	*ents=--i;
	endpwent();
	return t;
}

void do_reports(struct Apasswd *t, int ents) {
	int i;

	if (sortbyuid || dupuid) 
		qsort(t, ents, sizeof(struct Apasswd), cf_uid);
	if (sortbyuid) {
		if (h)
			printf("-- Report of users sorted by UID --\n"
				"      uid        gid  username/groupname home program\n");
		for (i=0; i<ents; i++)
			printf(h ?	"%9d %9d %s/%s %s %s\n" 
				 :	"%d\t%d\t%s\t%s\t%s\t%s\n", 
					t[i].A.pw_uid, t[i].A.pw_gid, 
					t[i].A.pw_name, t[i].pw_grpname, t[i].A.pw_dir, t[i].A.pw_shell);
	}
	if (dupuid) {
		if (h)
			printf("-- Report of shared UID --\n");
		for (i=0; i<ents; i++) {
			printf(h ? "UID %9d:\t%s"
				 :      "%d\t%s", t[i].A.pw_uid, t[i].A.pw_name);
			while (i < ents && t[i].A.pw_uid == t[i+1].A.pw_uid) {
				i++;
				printf(h ? "\t%s" : ",%s", t[i].A.pw_name);
			}
			printf("\n");
		}
	}
	if (sortbyname) {
		qsort(t, ents, sizeof(struct Apasswd), cf_nam);
		if (h)
			printf("-- Report of users sorted by NAME --\n"
				 "  name   uid\n");
		for (i=0; i<ents; i++)
			printf(h ? "%s\t%9d\n"
				 : "%s\t%d\n", t[i].A.pw_name, t[i].A.pw_uid);
	}
	if (dupgid) {
		if (h)
			printf("-- Report of shared GID --\n");
		qsort(t, ents, sizeof(struct Apasswd), cf_gid);
		for (i=0; i<ents; i++) {
			printf(h ? "GID %9d(%s):\t%s"
				 : "%d\t%s\t%s", t[i].A.pw_gid, t[i].pw_grpname, t[i].A.pw_name);
			while (i < ents && t[i].A.pw_gid == t[i+1].A.pw_gid) {
				i++;
				printf(h ? "\t%s"
					 : ",%s", t[i].A.pw_name);
			}
			printf("\n");
		}
	}
}

int cf_uid(const void *s1, const void *s2)
{
	return ((struct Apasswd *)s1)->A.pw_uid - ((struct Apasswd *)s2)->A.pw_uid;
}

int cf_nam(const void *s1, const void *s2)
{
	return strcmp( ((struct Apasswd *)s1)->A.pw_name, ((struct Apasswd *)s2)->A.pw_name);
}

int cf_gid(const void *s1, const void *s2)
{
	return ((struct Apasswd *)s1)->A.pw_gid - ((struct Apasswd *)s2)->A.pw_gid;
}

void pw_cpy(struct Apasswd *new, struct passwd * old)
{
	struct group *G;
	new->A.pw_name=strdup(old->pw_name);
	new->A.pw_uid=old->pw_uid;
	new->A.pw_gid=old->pw_gid;
	new->A.pw_dir=strdup(old->pw_dir);
	new->A.pw_shell=strdup(old->pw_shell);
	if ((G = getgrgid(new->A.pw_gid)) == NULL) 
		new->pw_grpname = "no grpname";
	else
		new->pw_grpname = strdup(G->gr_name);
}
