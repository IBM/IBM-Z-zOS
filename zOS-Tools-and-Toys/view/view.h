/************************************************************************\
* Copyright 1997, IBM Corporation                                        *
* All rights reserved                                                    *
*                                                                        *
* Distribute freely, except: don't remove my name from the source or     *
* documentation (don't take credit for my work), mark your changes       *
* (don't get me blamed for your possible bugs), don't alter or           *
* remove this notice.  No fee may be charged if you distribute the       *
* package (except for such things as the price of a disk or tape,        *
* postage, etc.).  No warranty of any kind, express or implied, is       *
* included with this software; use at your own risk, responsibility      *
* for damages (if any) to anyone resulting from the use of this          *
* software rests entirely with the user.                                 *
*                                                                        *
* Send me bug reports, bug fixes, enhancements, requests, flames,        *
* etc.  I can be reached as follows:                                     *
*                                                                        *
*          jason m. heim      heim@us.ibm.com                            *
\************************************************************************/

/******************************************************\ 
*   view.h                                             *
*                                                      *
*      version 1.1                                     *
*      last modified by Jason M. Heim, 8/24/97         *
*      heim@us.ibm.com                                 *
*      IBM 1997                                        *
*                                                      *
*   this is the header file for the main function file *
*                                                      *
\******************************************************/


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





