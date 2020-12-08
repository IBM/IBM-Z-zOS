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
*   l_unix.c                                           *
*                                                      *
*      version 1.1                                     *
*      last modified by Jason M. Heim, 8/15/98         *
*      heim@us.ibm.com                                 *
*      IBM 1997                                        *
*                                                      *
*   this file contains the main function definitions   *
*   that may/will need special treatment on porting    *
*                                                      *
*   makes extensive use of the curses library          *
*                                                      *
\******************************************************/

#define _XOPEN_SOURCE
#include <stdio.h>
#include <string.h>
#include <memory.h>
#include <termios.h>
#include <ctype.h>
#include <sys/types.h>
#include <signal.h>
#include <curses.h>
#include "l_unix.h"

/* global - can not be put in view.h */
static struct termios savemodes;  /* used to handle unbuffered i/o      */


/* this function moves down one page */
void page_down(void)
{
   int c = 0;
   int d;
   if(hexmode) d=(LINES-1)/4;
   else d=(LINES-1);
   while(c < d && topline->next->next->next->next){
      topline = topline->next->next->next->next;
      c++;
   }
}

/* this function moves up one page */
void page_up(void)
{
   int c=0;
   int d;
   if(hexmode) d=(LINES-1)/4;
   else d=(LINES-1);
   while(c < d && topline->prev){
      topline = topline->prev->prev->prev->prev;
      c++;
   }
}

/* this determines if global searchstr is in the param string str */
char strinstr(line_t * l)
{
  char rc = 0;
  int c;
  int s;
  char *str;
  char *strnxt;
  int len;
  line_t *ln;

  ln = l->next->next->next->next;
  if(ln && l->num == ln->num){ 
    len = COLS-1;
    str = (char *) malloc(COLS+searchlen);
    strncpy(str, l->line, COLS-1);
    strncpy(&str[COLS-1], ln->line, searchlen);
    str[COLS+searchlen] = '\0';
  } else{
    len = COLS - searchlen -1;
    str = l->line;
  }
  /* outer loop - param str */
  c=searchpos;
  searchpos = 0;
  for(; c<len && !rc; c++){
    s = 0;     /* initialize inner search */
    while(1){  
      if(ucase[searchstr[s]] != ucase[str[c+s]]) break;  /* if different move on */
      else{      
	s++;                                  /* increment searchstr       */
	if(s >= searchlen){                   /* if we searched the length */
	  rc = 1;                             /*     we found it,          */
	  searchpos = c+s;                  /*     remember where        */
	  break;                              /*     and leave             */
        }
      }
    }
  }
  return(rc);
}

/* this function prints string str at position (x,y) */
void print_at_pos(char * str, int x, int y)
{
   int len,c;
   len = strlen(str);
   for(c=0;c<len;c++) mvaddch(y, x+c, str[c]);
}

/* this is a refresh routine that prints out the current screen from topline
       it returns the next command character to be interpreted */
char rescreen(void)
{
   int c, linesout, linesblank, x, y;
   long int lastline;
   line_t * search;
   char tmp;

   linesout = LINES - 1;                 /* used often, store for speed        */
   search = topline;                     /* start at current topline           */
   for(c = 0; c < linesout; c++){        /* loop through the screenlines       */
      mvaddstr(c,0,search->line);
      if(!search->next) break;
      if(!hexmode)if(!search->next->next->next->next) break;
      if(hexmode)search = search->next;  /*   else go to the next line         */
      else search = search->next->next->next->next;
   }
   /* if we are not at the last line then back up one line */
   if(hexmode)
     if(search->next) search = search->prev;
   else if(search->next && search->next->next->next->next) search = search->prev;
   for(c++; c < linesout; c++){          /* print out buffering blank lines    */
      mvaddstr(0, c, blankline);         /*   if necessary                     */
   }
   move(LINES,0);                        /* position for message               */
   refresh();                            /* curses refresh display routine     */
   printf("%s\r", blankline);            /* clean the message line             */

   /* depending on global variable settings output an appropriate message */
   if(searching){                        
      if(searchfnd){
	printf(" Searching:  %s", searchstr);
	fflush(stdout); 
	printf("\r"); 
	if(searchlen){ 
	  x = stdscr->_curx;
	  y = stdscr->_cury;
	  if(searchpos >= COLS) move(1+(3*hexmode), searchpos - COLS + 1);
	  else move(0, searchpos);
	  refresh();
	  move(y, x);
	  tmp = getcmd();
	  refresh();
	  return(tmp);
	}  
      } else {
	printf(" Not found:  %s", searchstr);
	fflush(stdout); 
	printf("\r");   
      }  
   } else if(gotoing) {
     printf(" Goto line:  %ld", gotonum);
     fflush(stdout); 
     printf("\r");   
   } else {
     printf("[%s - %ld to %ld of %ld]", filename, topline->num, 
	    search->num, linelist.numlines);
     fflush(stdout); 
     printf("\r");   
   }  
   return(getcmd());  /* get the next command and return it                      */
}

/* this function reads uses getchar() to read unbuffered input from the keyboard
     and processes the keystrokes */
/* PORTABILITY NOTE:  these values are very specific to IBM OpenEdition's keyboard
     handling, and may not respond as expected on other systems */ 
char getcmd(void)
{
   char c, junk;
   c = getchar();
   if (c == 39){      /* this is the escape key or escape sequence */
      c = 0;
      junk = getchar();
      if(junk == 173 && !searching){  /* if we are searching an escape sequence */
         junk = getchar();            /*    should get us out of search mode    */
         if(junk == 193) c = UP;
         else if(junk == 193) c = UP; 
         else if(junk == 194) c = DOWN; 
         else if(junk == 245){ c = PGUP; junk = getchar(); }
         else if(junk == 246){ c = PGDN; junk = getchar(); }
         else if(junk == 241){ c = HOME; junk = getchar(); }
         else if(junk == 244){ c = END; junk = getchar(); }
      }
   } else if(c == 5) c = NEXT;       
   else if(c == ' ' && !searching) c = PGDN;
   return(c);
}

/* reads in another line from the file, if any, else return NULL */
char * get_next_line(FILE *fp)
{
   char* line;                  /* the new line pointer */
   char junk;
   char templine[1024];         /* temporary storage    */
   char templine1[1024];        /* temporary storage    */
   char templine2[1024];        /* temporary storage    */
   int chars;                   /* counter variable     */
   char c;                      /* temporary storage    */
   chars = 0;                   /* initialize counter   */
   if(!feof(fp))c=fgetc(fp);    /* get the first character if any  */
   else return(NULL);           /* else return NULL                */
   while(currmap[c] != '\n' && !feof(fp) && chars < COLS){
      if(currmap[c] == '\t'){             /* manually indent on a tab character */
	junk = chars+(4-(chars%4));
	templine[chars] = ' ';
	templine1[chars] = lnibble(c);
	templine2[chars] = rnibble(c);
	chars++;
	for(; chars < junk; chars++){
	  templine[chars] = ' ';
	  templine1[chars] = ' ';
	  templine2[chars] = ' ';
	  if(chars >= COLS-1) break;
        }
      }else{
	if(!stdchar[currmap[c]]) templine[chars] = NON_STD_CHAR;
	else templine[chars] = currmap[c];
	templine1[chars] = lnibble(c);
	templine2[chars] = rnibble(c);
	chars++;
      }
      c=fgetc(fp);
      if(chars == COLS-1 && currmap[c] != '\n' && !feof(fp) && !trunc_line){
	templine[chars] = '\\';
	templine1[chars] = ' ';
	templine2[chars] = ' ';
        templine[chars+1] = '\0';
        templine1[chars+1] = '\0';
        templine2[chars+1] = '\0';
	line = (char *)malloc(sizeof(char)*(COLS+1));  /* allocate line */
	strcpy(line,templine);
	add_line(line,linelist.numlines+1);
	linelist.tail->hexline = 1;
	line = (char *)malloc(sizeof(char)*(COLS+1));  /* allocate line */
	strcpy(line,templine1);
	add_line(line,linelist.numlines+1);
	linelist.tail->hexline = 1;
	line = (char *)malloc(sizeof(char)*(COLS+1));  /* allocate line */
	strcpy(line,templine2);
	add_line(line,linelist.numlines+1);
	linelist.tail->hexline = 1;
	line = (char *)malloc(sizeof(char)*(COLS+1));  /* allocate line */
	strcpy(line,blankline);
	add_line(line,linelist.numlines+1);
	linelist.tail->hexline = 1;
        chars = 0;
      }
   } 
   if(currmap[c] == '\n'){
     templine[chars]=' ';
     templine1[chars] = lnibble(c);
     templine2[chars] = rnibble(c);
     chars++;
   }  
   while(chars < COLS){         /* this loop fills the rest of     */
     templine[chars]=' ';      /*    the columns with whitespace  */
     templine1[chars] = ' ';
     templine2[chars] = ' ';
     chars++;
   }
   /* if the line is longer than the number of columns, truncate it */
   if(currmap[c]!='\n' && !feof(fp) && trunc_line) 
     while(c!='\n' && !feof(fp)) c = fgetc(fp); 
   templine[chars] = '\0';    /* standard string termination     */
   templine1[chars] = '\0';    /* standard string termination     */
   templine2[chars] = '\0';    /* standard string termination     */
   line = (char *)malloc(sizeof(char)*(COLS+1));  /* allocate line */
   strcpy(line,templine);       /* copy the temporary storage      */
   add_line(line, linelist.numlines+1);  /* add the new line */
   line = (char *)malloc(sizeof(char)*(COLS+1));  /* allocate line */
   strcpy(line,templine1);       /* copy the temporary storage      */
   add_line(line, linelist.numlines+1);  /* add the new line */
   linelist.tail->hexline = 1;
   line = (char *)malloc(sizeof(char)*(COLS+1));  /* allocate line */
   strcpy(line,templine2);       /* copy the temporary storage      */
   add_line(line, linelist.numlines+1);  /* add the new line */
   linelist.tail->hexline = 1;
   line = (char *)malloc(sizeof(char)*(COLS+1));  /* allocate line */
   strcpy(line,blankline);       /* copy the temporary storage      */
   add_line(line, linelist.numlines+1);  /* add the new line */
   linelist.tail->hexline = 1;
   return(line);
}

/* used to switch to unbuffered input mode */
int hide_io(void)
{
   struct termios modmodes;
   if(tcgetattr(fileno(stdin), &savemodes) < 0) return -1;
   havemodes = 1;
   modmodes = savemodes;
   modmodes.c_lflag &= ~ICANON;
   modmodes.c_lflag &= ~ECHO;
   modmodes.c_cc[VMIN] = 1;
   modmodes.c_cc[VTIME] = 0;
   return tcsetattr(fileno(stdin), 0, &modmodes);
}

/* used to return to regular input mode */
int show_io(void)
{
   if(!havemodes) return 0;
   return tcsetattr(fileno(stdin), 0, &savemodes);
}

/* graceful termination */
void terminate(int sig)
{
   if(sig) fprintf(stderr, "\nTerminated with signal %d\n", sig);
   mvcur(0, COLS-1, LINES-1, 0);
   endwin();
   putchar('\r');
   exit(sig);            
}

/* graceful termination */
void terminatep(int sig)
{
   if(sig) fprintf(stderr, "\nTerminated with signal %d\n", sig);
   exit(sig);            
}

/* this function is use to spin a little bar to indicate a load in progress */
void load_prog_ind(int s){
  printf("\r Loading %s (%c)", filename, searchpi[s]);
  fflush(stdout);                       /* displays stdio message */
} 

/* creates the linelist and reads into it */
void read_file_into_linelist(FILE *fp)
{
   char * next;              /* holds the pointer to the line */   
   int c;                    /* counter                       */
   blankline = (char *)malloc(sizeof(char)*(COLS+1));
   for(c=0;c<COLS;c++){
      blankline[c] = ' ';    /* fill in the global blankline  */
   }
   blankline[COLS]='\0';     /* standard string termination   */
   linelist.numlines = 0;    /* initialize the linelist       */
   linelist.head = NULL;
   linelist.tail = NULL;
   next = get_next_line(fp); /* get the first line            */
   c=0;
   while(next){              /* loop until NULL               */
      linelist.numlines++;   /* increment the number of lines */
      if(!(linelist.numlines%2048) && !pipedoutput){
	load_prog_ind(c);
	c++;
	c=c%4;
      }	
      next = get_next_line(fp);  /* get next line             */
   }
}

/* initializes the case globals for character formatting */
void initialize(void)
{
   int c;
   int col, lin;
   char pipeline[100];
   char *srch;
   FILE * fp;

   col=0; lin=0;
   fp = popen("stty", "r");
   if(fp){
     fgets(pipeline, 100, fp);
     while(!feof(fp)){
       if(!strncmp("rows", pipeline, 4)){
	 sscanf(pipeline, "rows = %d, columns = %d", &lin, &col);
       }
       fgets(pipeline, 100, fp);
     }
     if(col && lin){
       lin--;
       sprintf(pipeline, "%d\0", col);
       setenv("COLUMNS", pipeline, 1);
       sprintf(pipeline, "%d\0", lin);
       setenv("LINES", pipeline, 1);
     }  
   }  

   initscr();                 /* initialize curses screen       */

   signal(SIGINT, terminate); /* where to go on control-C       */
   signal(SIGSEGV, terminate);
   for(c=0;c<256;c++){
       ucase[c]=c;
       NOCHANGE[c]=c;
       stdchar[c]=0;
   }
   if(asciimode) currmap = ATOEMAP;
   else currmap = NOCHANGE;

   if(!case_sens){
     ucase['a'] = 'A';
     ucase['b'] = 'B';
     ucase['c'] = 'C';
     ucase['d'] = 'D';
     ucase['e'] = 'E';
     ucase['f'] = 'F';
     ucase['g'] = 'G';
     ucase['h'] = 'H';
     ucase['i'] = 'I';
     ucase['j'] = 'J';
     ucase['k'] = 'K';
     ucase['l'] = 'L';
     ucase['m'] = 'M';
     ucase['n'] = 'N';
     ucase['o'] = 'O';
     ucase['p'] = 'P';
     ucase['q'] = 'Q';
     ucase['r'] = 'R';
     ucase['s'] = 'S';
     ucase['t'] = 'T';
     ucase['u'] = 'U';
     ucase['v'] = 'V';
     ucase['w'] = 'W';
     ucase['x'] = 'X';
     ucase['y'] = 'Y';
     ucase['z'] = 'Z';
   }  
   /* this is a list of all of the standard characters available on a 101 key 
      keyboard.  characters outside of this can cause an uncontrollable core dump
      that kicks the user back out to a prompt without turning back on normal 
      console i/o, which can be very frustrating */
   stdchar['`'] = '`';
   stdchar['1'] = '1';
   stdchar['2'] = '2';
   stdchar['3'] = '3';
   stdchar['4'] = '4';
   stdchar['5'] = '5';
   stdchar['6'] = '6';
   stdchar['7'] = '7';
   stdchar['8'] = '8';
   stdchar['9'] = '9';
   stdchar['0'] = '0';
   stdchar['-'] = '-';
   stdchar['='] = '=';
   stdchar['q'] = 'q';
   stdchar['w'] = 'w';
   stdchar['e'] = 'e';
   stdchar['r'] = 'r';
   stdchar['t'] = 't';
   stdchar['y'] = 'y';
   stdchar['u'] = 'u';
   stdchar['i'] = 'i';
   stdchar['o'] = 'o';
   stdchar['p'] = 'p';
   stdchar['['] = '[';
   stdchar[']'] = ']';
   stdchar['\\'] = '\\';
   stdchar['a'] = 'a';
   stdchar['s'] = 's';
   stdchar['d'] = 'd';
   stdchar['f'] = 'f';
   stdchar['g'] = 'g';
   stdchar['h'] = 'h';
   stdchar['j'] = 'j';
   stdchar['k'] = 'k';
   stdchar['l'] = 'l';
   stdchar[';'] = ';';
   stdchar['\''] = '\'';
   stdchar['z'] = 'z';
   stdchar['x'] = 'x';
   stdchar['c'] = 'c';
   stdchar['v'] = 'v';
   stdchar['b'] = 'b';
   stdchar['n'] = 'n';
   stdchar['m'] = 'm';
   stdchar[','] = ',';
   stdchar['.'] = '.';
   stdchar['/'] = '/';
   stdchar['~'] = '~';
   stdchar['!'] = '!';
   stdchar['@'] = '@';
   stdchar['#'] = '#';
   stdchar['$'] = '$';
   stdchar['%'] = '%';
   stdchar['^'] = '^';
   stdchar['&'] = '&';
   stdchar['*'] = '*';
   stdchar['('] = '(';
   stdchar[')'] = ')';
   stdchar['_'] = '_';
   stdchar['+'] = '+';
   stdchar['Q'] = 'Q';
   stdchar['W'] = 'W';
   stdchar['E'] = 'E';
   stdchar['R'] = 'R';
   stdchar['T'] = 'T';
   stdchar['Y'] = 'Y';
   stdchar['U'] = 'U';
   stdchar['I'] = 'I';
   stdchar['O'] = 'O';
   stdchar['P'] = 'P';
   stdchar['{'] = '{';
   stdchar['}'] = '}';
   stdchar['|'] = '|';
   stdchar['A'] = 'A';
   stdchar['S'] = 'S';
   stdchar['D'] = 'D';
   stdchar['F'] = 'F';
   stdchar['G'] = 'G';
   stdchar['H'] = 'H';
   stdchar['J'] = 'J';
   stdchar['K'] = 'K';
   stdchar['L'] = 'L';
   stdchar[':'] = ':';
   stdchar['\"'] = '\"';
   stdchar['Z'] = 'Z';
   stdchar['X'] = 'X';
   stdchar['C'] = 'C';
   stdchar['V'] = 'V';
   stdchar['B'] = 'B';
   stdchar['N'] = 'N';
   stdchar['M'] = 'M';
   stdchar['<'] = '<';
   stdchar['>'] = '>';
   stdchar['?'] = '?';
   stdchar['\n'] = '\n';
   stdchar[' '] = ' ';
   stdchar['\t'] = '\t';
}

/* initializes the case globals for character formatting */
/* version for pipe */
void initializep(void)
{
   int c;
   COLS = 79;
   pipedoutput=1;
   signal(SIGINT, terminatep); /* where to go on control-C       */
   signal(SIGSEGV, terminatep);
   for(c=0;c<256;c++){
       NOCHANGE[c]=c;
       stdchar[c]=NON_STD_CHAR;
   }
   if(asciimode) currmap = ATOEMAP;
   else currmap = NOCHANGE;
   /* this is a list of all of the standard characters available on a 101 key 
      keyboard.  characters outside of this can cause an uncontrollable core dump
      that kicks the user back out to a prompt without turning back on normal 
      console i/o, which can be very frustrating */
   stdchar['`'] = '`';
   stdchar['1'] = '1';
   stdchar['2'] = '2';
   stdchar['3'] = '3';
   stdchar['4'] = '4';
   stdchar['5'] = '5';
   stdchar['6'] = '6';
   stdchar['7'] = '7';
   stdchar['8'] = '8';
   stdchar['9'] = '9';
   stdchar['0'] = '0';
   stdchar['-'] = '-';
   stdchar['='] = '=';
   stdchar['q'] = 'q';
   stdchar['w'] = 'w';
   stdchar['e'] = 'e';
   stdchar['r'] = 'r';
   stdchar['t'] = 't';
   stdchar['y'] = 'y';
   stdchar['u'] = 'u';
   stdchar['i'] = 'i';
   stdchar['o'] = 'o';
   stdchar['p'] = 'p';
   stdchar['['] = '[';
   stdchar[']'] = ']';
   stdchar['\\'] = '\\';
   stdchar['a'] = 'a';
   stdchar['s'] = 's';
   stdchar['d'] = 'd';
   stdchar['f'] = 'f';
   stdchar['g'] = 'g';
   stdchar['h'] = 'h';
   stdchar['j'] = 'j';
   stdchar['k'] = 'k';
   stdchar['l'] = 'l';
   stdchar[';'] = ';';
   stdchar['\''] = '\'';
   stdchar['z'] = 'z';
   stdchar['x'] = 'x';
   stdchar['c'] = 'c';
   stdchar['v'] = 'v';
   stdchar['b'] = 'b';
   stdchar['n'] = 'n';
   stdchar['m'] = 'm';
   stdchar[','] = ',';
   stdchar['.'] = '.';
   stdchar['/'] = '/';
   stdchar['~'] = '~';
   stdchar['!'] = '!';
   stdchar['@'] = '@';
   stdchar['#'] = '#';
   stdchar['$'] = '$';
   stdchar['%'] = '%';
   stdchar['^'] = '^';
   stdchar['&'] = '&';
   stdchar['*'] = '*';
   stdchar['('] = '(';
   stdchar[')'] = ')';
   stdchar['_'] = '_';
   stdchar['+'] = '+';
   stdchar['Q'] = 'Q';
   stdchar['W'] = 'W';
   stdchar['E'] = 'E';
   stdchar['R'] = 'R';
   stdchar['T'] = 'T';
   stdchar['Y'] = 'Y';
   stdchar['U'] = 'U';
   stdchar['I'] = 'I';
   stdchar['O'] = 'O';
   stdchar['P'] = 'P';
   stdchar['{'] = '{';
   stdchar['}'] = '}';
   stdchar['|'] = '|';
   stdchar['A'] = 'A';
   stdchar['S'] = 'S';
   stdchar['D'] = 'D';
   stdchar['F'] = 'F';
   stdchar['G'] = 'G';
   stdchar['H'] = 'H';
   stdchar['J'] = 'J';
   stdchar['K'] = 'K';
   stdchar['L'] = 'L';
   stdchar[':'] = ':';
   stdchar['\"'] = '\"';
   stdchar['Z'] = 'Z';
   stdchar['X'] = 'X';
   stdchar['C'] = 'C';
   stdchar['V'] = 'V';
   stdchar['B'] = 'B';
   stdchar['N'] = 'N';
   stdchar['M'] = 'M';
   stdchar['<'] = '<';
   stdchar['>'] = '>';
   stdchar['?'] = '?';
   stdchar['\n'] = '\n';
   stdchar[' '] = ' ';
   stdchar['\t'] = '\t';
}
/* end of file l_unix.c */


