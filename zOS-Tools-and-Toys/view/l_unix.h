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
*   l_unix.h                                           *
*                                                      *
*      version 1.1                                     *
*      last modified by Jason M. Heim, 10/24/97        *
*      heim@us.ibm.com                                 *
*      IBM 1997                                        *
*                                                      *
*   this is the header file for non-ANSI function file *
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
#define lnibble(x) hexchars[x/16];
#define rnibble(x) hexchars[x%16];
/*************************************************************** typedefs   */

/* line_t - this is a node in a linked list of individual lines */
typedef struct line_s{
   char* line;          /* the line of text               */
   long int num;          /* the number of the current line */
   char hexline;
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

void read_file_into_linelist(FILE * fp);
char * get_next_line(FILE * fp);
void update_screen(void);
char getcmd(void);
void print_at_pos(char* str, int x, int y);
char rescreen(void);
int hide_io(void);
int show_io(void);
void terminate(int);
void initialize(void);
void page_down(void);
void page_up(void);
char strinstr(line_t *l);

/*************************************************************** globals    */ 
extern list_t linelist;             /* the linked list of 'lines'           */
extern line_t *topline;             /* pointer to the top line in the list  */
extern line_t *botline;             /* pointer to the bot line in the list  */
extern char * blankline;            /* a string of whitespace characters    */
extern char * filename;             /* the current file being viewed        */
extern int havemodes;               /* remembers if unbuffered i/o is on    */
extern char searchstr[];            /* current searching string             */
extern int searchlen;               /* current searching string length      */
extern char searching;              /* boolean - search mode                */
extern int searchpos;               /* where the search string is           */
extern line_t * search1st;          /* line that searching starts from      */
extern char searchfnd;              /* boolean - search mode successful     */
extern char gotoing;                /* boolean - goto-line mode             */
extern long int gotonum;            /* line number to go to                 */
extern char case_sens;              /* boolean - case-sensitive mode        */
extern char trunc_line;             /* boolean - allow any character in     */
extern char ucase[];                /* uppercase translate table            */
extern char stdchar[];              /* boolean string - stdchar[c] is       */
                                    /*   true when c is from the standard   */
                                    /*   keyboard character set             */
extern char searchpi[];

extern char *currmap;
extern char NOCHANGE[];
extern char *othermap;
extern char hexmode;
extern char asciimode;
extern char pipedoutput;

static char hexchars[16] = {
  '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F'
}  ;

static char ATOEMAP[256] = {
      0,  1,  2,  3, 55, 45, 46, 47, 22,  5, 21, 11, 12, 13, 14, 15,
     16, 17, 18, 19, 60, 61, 50, 38, 24, 25, 63, 39, 28, 29, 30, 31,
     64, 90,127,123, 91,108, 80,125, 77, 93, 92, 78,107, 96, 75, 97,
    240,241,242,243,244,245,246,247,248,249,122, 94, 76,126,110,111,
    124,193,194,195,196,197,198,199,200,201,209,210,211,212,213,214,
    215,216,217,226,227,228,229,230,231,232,233,173,224,189, 95,109,
    121,129,130,131,132,133,134,135,136,137,145,146,147,148,149,150,
    151,152,153,162,163,164,165,166,167,168,169,192, 79,208,161,  7,
     32, 33, 34, 35, 36, 37,  6, 23, 40, 41, 42, 43, 44,  9, 10, 27,
     48, 49, 26, 51, 52, 53, 54,  8, 56, 57, 58, 59,  4, 20, 62,255,
     65,170, 74,177,159,178,106,181,187,180,154,138,176,202,175,188,
    144,143,234,250,190,160,182,179,157,218,155,139,183,184,185,171,
    100,101, 98,102, 99,103,158,104,116,113,114,115,120,117,118,119,
    172,105,237,238,235,239,236,191,128,253,254,251,252,186,174, 89,
     68, 69, 66, 70, 67, 71,156, 72, 84, 81, 82, 83, 88, 85, 86, 87,
    140, 73,205,206,203,207,204,225,112,221,222,219,220,141,142,223
};

static char ETOAMAP[256] = {
      0,  1,  2,  3,156,  9,134,127,151,141,142, 11, 12, 13, 14, 15,
     16, 17, 18, 19,157, 10,  8,135, 24, 25,146,143, 28, 29, 30, 31,
    128,129,130,131,132,133, 23, 27,136,137,138,139,140,  5,  6,  7,
    144,145, 22,147,148,149,150,  4,152,153,154,155, 20, 21,158, 26,
     32,160,226,228,224,225,227,229,231,241,162, 46, 60, 40, 43,124,
     38,233,234,235,232,237,238,239,236,223, 33, 36, 42, 41, 59, 94,
     45, 47,194,196,192,193,195,197,199,209,166, 44, 37, 95, 62, 63,
    248,201,202,203,200,205,206,207,204, 96, 58, 35, 64, 39, 61, 34,
    216, 97, 98, 99,100,101,102,103,104,105,171,187,240,253,254,177,
    176,106,107,108,109,110,111,112,113,114,170,186,230,184,198,164,
    181,126,115,116,117,118,119,120,121,122,161,191,208, 91,222,174,
    172,163,165,183,169,167,182,188,189,190,221,168,175, 93,180,215,
    123, 65, 66, 67, 68, 69, 70, 71, 72, 73,173,244,246,242,243,245,
    125, 74, 75, 76, 77, 78, 79, 80, 81, 82,185,251,252,249,250,255,
     92,247, 83, 84, 85, 86, 87, 88, 89, 90,178,212,214,210,211,213,
     48, 49, 50, 51, 52, 53, 54, 55, 56, 57,179,219,220,217,218,159
};

