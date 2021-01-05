/**********************************************************************
** Copyright 1997-2020 IBM Corp.
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
**   view.h
**
**      version 1.1
**      last modified by Jason M. Heim, 8/24/97
**      heim@us.ibm.com
**
**   This is the header file for the main function file
**
**********************************************************************/

#define UP 'u'
#define DOWN 'd'
#define HOME 't'
#define END 'b'
#define PGUP 'p'
#define PGDN 'n'
#define SEARCH 's'
#define LINE 'l'
#define NEXT '\t'
#define QUIT 'q'
#define GOTO 'g'
#define HEX 'x'

#define MAX_SEARCHLEN 48
#define NON_STD_CHAR 171
/*************************************************************** typedefs   */

/* line_t - this is a node in a linked list of individual lines */
typedef struct line_s{
   char* line;          /* the line of text               */
   long int num;        /* the number of the line         */
   char hexline;         /* boolean - is this hex stuff?   */
   struct line_s *next; /* pointer to the next line       */
   struct line_s *prev; /* pointer to the previous line   */
} line_t;

/* list_t - this is the head-tail linked list */
typedef struct list_s{
   line_t *head;        /* head of the list            */
   line_t *tail;        /* tail of the list            */
   long int numlines;     /* number of lines in the list */
} list_t;

/*************************************************************** prototypes */
void pipeout(void);
void usage(void);
void usagehelp(void);
char process_cmd(char c);
line_t *new_line(char * newline, long int numb);
void add_line(char * newline, long int numb);
void mainloop(void);
int process_arg(char *c);
char strinstr(line_t *l);

/************************************************************ globals    */
list_t linelist;                  /* the linked list of 'lines'          */
line_t *topline;                  /* pointer to the top line in the list */
line_t *botline;                  /* pointer to the bot line in the list */
char * blankline;                 /* a string of whitespace characters   */
char * filename;                  /* the current file being viewed       */
int havemodes = 0;                /* remembers if unbuffered i/o is on   */
char searchstr[MAX_SEARCHLEN];    /* current searching string            */
int searchlen = 0;                /* current searching string length     */
char searching = 0;               /* boolean - search mode               */
int searchpos = 0;                /* where the search string is          */
line_t * search1st;               /* line that searching starts from     */
char searchfnd = 0;               /* boolean - search mode successful    */
char gotoing = 0;                 /* boolean - goto-line mode            */
long int gotonum;                 /* line number to go to                */
char case_sens = 0;               /* boolean - case-sensitive mode       */
char asciimode = 0;
char hexmode = 0;
char trunc_line = 0;              /* boolean - allow any character in    */
char ucase[256];                  /* uppercase translate table           */
char stdchar[256];                /* boolean string - stdchar[c] is      */
                                  /*   true when c is from the standard  */
                                  /*   keyboard character set            */
char searchpi[5] = "|/-\\\0";     /* progress indicating animator        */
char from_stdin[6] = "stdin\0";   /* if input comes from stdin           */
char *currmap;
char NOCHANGE[256];
char * othermap;
extern char * ATOEMAP;
char pipedoutput = 0;





