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
*   view.c                                             *
*                                                      *
*      version 1.1                                     *
*      orignal code by Jason M. Heim, 8/8/97           *
*      last modified by Jason M. Heim, 10/24/97        *
*      heim@us.ibm.com                                 *
*      IBM 1997                                        *
*                                                      *
*   this file contains the main function definitions   *
*   that [supposedly] comply with ANSI standards       *
*                                                      *
\******************************************************/


#include <stdio.h>
#include <string.h>
#include <sys/stat.h>
#include "view.h"

/*************************************************************** main       */

int main(int argc, char** argv)
{
  FILE * fp;
  int filenum = 0;
  int argnum, fnfound;
  struct stat st;
  struct stat sto;
  
  if(fstat(fileno(stdin), &st) != 0) perror("stat() error\n");
  if(fstat(fileno(stdout), &sto) != 0) perror("stat() error\n");
  argnum = 1;
  while(argnum < argc){
    fnfound = process_arg(argv[argnum]);
    if(fnfound)filenum = argnum;
    argnum++;
  }
  if(!filenum && !(S_ISFIFO(st.st_mode) || S_ISREG(st.st_mode))) usage();
  else if(S_ISFIFO(st.st_mode) || S_ISREG(st.st_mode)) {
    fp = stdin;                                   /* being used in a pipe     */
    filename = from_stdin;
  } else{
    fp = fopen(argv[filenum], "r");  /* get the file pointer to this filename */
    if(!fp){  /* if the file could not be opened, say so and exit */
      fprintf(stderr, "Could not access file %s.\n\n", argv[filenum]);
      exit(1);
    }
    filename = argv[filenum];
  }

  /* return control to the keyboard after a stdin pipe */
  if(!S_ISFIFO(sto.st_mode) && !S_ISREG(sto.st_mode)){
    initialize();
    read_file_into_linelist(fp);  /* reads the file into the global var 'linelist' */
    if(fp == stdin) stdin = freopen("/dev/tty", "r", stdin);   
    mainloop();                   /* main processing done here                     */
    terminate(0);                 /* cleanup                                       */
  } else {
    initializep();
    read_file_into_linelist(fp);  /* reads the file into the global var 'linelist' */
    pipeout();
  }  
  
  return(0);
}

/*************************************************************** functions  */

/* this processes command-line arguments */
int process_arg(char * arg){
  int i=1;
  if(arg[0] == '-'){
    while(arg[i]){
      if(arg[i] == 'a') asciimode = 1;
      else if(arg[i] == 'c') case_sens = 1;
      else if(arg[i] == 'x') hexmode = 1;
      else if(arg[i] == '?') usagehelp();
      else if(arg[i] == 't') trunc_line = 1;
      else usage();
      i++;
    }  
    return(0);
  } 
  return(1);
}      

/* this function is used to spin a little bar to indicate a search in progress */
void search_prog_ind(int s){
  printf(" Searching%c  %s", searchpi[s], searchstr);
  fflush(stdout);                       /* displays stdio message */
  printf("\r");                         /* reset line             */
} 

/* this is the linear search algorithm, starting from the given line_t *search */
void search(line_t *search)
{
   int c,d;
   searchfnd = 0;
   c=0;d=0;
   if(searchlen){                         /* if there is anything to search for */
      searchfnd = strinstr(search);        /* look in first line                 */
      printf("\r%s\r", blankline);        /* clear search line                  */
      while(search && !searchfnd){        /* loop and keep looking until found  */
	c++;
	search = search->next->next->next->next;  /*     or out of lines        */
	if(search)searchfnd = strinstr(search);
	if(!(c%2048)){
	  c=0;
	  search_prog_ind(d);
	  d++;
	  d=d%4;
	}  
      }
      printf("\r");
      fflush(stdout);
      if(searchfnd) topline = search;     /* if found set the global topline    */
   } else searchfnd = 1;                  /* if there is nothing to search for  */
}                                         /*     set this for the default msg   */   

/* converts a character to a long integer digit */
long int digit(char c)
{
   if(c == '0') return(0);
   return((long int)(c - '1' + 1));
}

/* sets global topline to the given line number */
void goto_line(long int l)
{
   line_t *search;
   search = linelist.head;
   if(l<1) l = 1;
   if(l>linelist.numlines) l = linelist.numlines;
   while(search && search->num !=l) search = search->next;
   topline = search;
}

void pipeout(void)
{
  line_t *search;
  char * l;
  search = linelist.head;
  while(search){
    l = search->line;
    while(*l){
      if(!search->hexline) printf("%c", *l);
      else printf("%c", *l);
      l++;
    }
    printf("\n");
    search = search->next;
    if(!hexmode) while(search && search->hexline) search = search->next;
  }
  fflush(stdout);
}

/* processes a given character command */
char process_cmd(char cmd)
{
   char rc = 0;
   int x, c = 0;
   if(!searching && !gotoing){  /* normal mode routines */
      /* handles up, down, page up, page down, topline, and bottom line */
      if(cmd == UP && topline->prev)
	topline = topline->prev->prev->prev->prev;
      else if(cmd == DOWN && topline->next->next->next->next)
	topline = topline->next->next->next->next;
      else if(cmd == PGDN){ 
         if(!topline->next) rc = 1;      /* quit by default if user pages out */
         else page_down();
      } else if(cmd == PGUP) page_up();
      else if(cmd == HOME) topline = linelist.head;
      else if(cmd == END) topline = linelist.tail->prev->prev->prev;
      else if(cmd == QUIT) rc = 1;      /* exiting return code on quit command */
      else if(cmd == SEARCH){           /* performs new search                 */
         searching = 1;
         searchlen = 0;
	 searchpos = 0;
         searchstr[0] = '\0';
         search1st = topline;
         searchfnd = 1;
      } else if(cmd == NEXT && searchlen){  /* performs search of last searchstr */
         searching = 1;
	 search1st = topline;
	 search(search1st);
      } else if(cmd == GOTO) {              /* switches to goto-line mode  */
         gotoing = 1;
         gotonum = 0;
      } else if(cmd == HEX) {
	 hexmode = (hexmode ? 0 : 1);
      } 
   } else if(searching){     /* these are the searching routines */
      if(cmd == NEXT && search1st->next && searchfnd){  /* search again on NEXT */
	searchpos -= searchlen-1;
	search(topline);
      } else if(!cmd || cmd == '\n' || cmd == '\r') searching = 0; /* exit search */
      else if(cmd == '\b'){  /* delete last character in searchstr, back up */
         if(searchlen){
	    searchpos = 0;
            searchlen--;
            searchstr[searchlen] = '\0';
            if(!searchlen)topline = search1st;
            search(search1st);
         }
      } else if(searchlen < MAX_SEARCHLEN-1 && searchfnd){               
	/* else add the new character to the search string */
	if(!stdchar[cmd]) cmd = NON_STD_CHAR;
	searchstr[searchlen] = cmd;
	searchpos -= searchlen;
	searchlen++;
	searchstr[searchlen] = '\0';   
	search(topline);
      }
   }  /* otherwise we must be in goto mode, handle key as follows:  */
   else if((cmd < '1' || cmd > '9') && cmd != '0' && cmd != '\b'){
      goto_line(gotonum);   /* on a non-digit exit goto-line    */
      gotoing = 0;          /*     mode and go to gotonum       */
   }  /* if user backs up adjust the gotonum */
   else if(cmd == '\b') gotonum /= 10; 
   else { /* else add the new digit to gotonum */
      gotonum = 10*gotonum + digit(cmd);
   }
   return(rc);
}

/* this is the main looping routine */
void mainloop(void)
{
   int count = 0;
   char done = 0;
   topline = linelist.head;
   hide_io();
   while(!done) done = process_cmd(rescreen());
   show_io();
}

/* gracefully exits if the program is used incorrectly */
void usage(void)
{
   fprintf(stderr, "\nUsage:  view [-?] [-a] [-c] [-t] [-x] <filename>\n\n");
   exit(-1);
}

/* longer help on how to use view */
void usagehelp(void)
{
   fprintf(stderr, "\nUsage:  view [-?] [-a] [-c] [-t] [-x] <filename>\n\n");
   fprintf(stderr, "        -?  =  Display this help file.\n");
   fprintf(stderr, "        -a  =  Display ASCII translation.\n");
   fprintf(stderr, "        -c  =  Turns on case-sensitivity in search mode.\n");
   fprintf(stderr, "        -t  =  Turns on line-truncation mode.\n");
   fprintf(stderr, "        -x  =  Display hex codes for characters.\n");
   fprintf(stderr, "\nRuntime commands:\n\n");
   fprintf(stderr, "        t   =  Top of file          (also Home key)\n");
   fprintf(stderr, "        b   =  Bottom of file       (also End key)\n");
   fprintf(stderr, "        p   =  Previous page        (also PgUp key)\n");
   fprintf(stderr, "        n   =  Next page            (also PgDn key)\n");
   fprintf(stderr, "        u   =  Up one line          (also up arrow key)\n");
   fprintf(stderr, "        d   =  Down one line        (also down arrow key)\n");
   fprintf(stderr, "        x   =  Toggle hex mode\n");
   fprintf(stderr, "        s   =  Enter search mode   ");
   fprintf(stderr, " (hit enter key when done)\n");
   fprintf(stderr, "        Tab =  Search again for last search string\n");
   fprintf(stderr, "        g   =  Goto line            <enter line number>\n");
   fprintf(stderr, "        q   =  Quit program\n\n");
   exit(1);
}

/* allocates a new node of line_t and applies given values to the struct */
line_t *new_line(char* newline, long int numline)
{
   line_t *temp;
   temp = (line_t*)malloc(sizeof(line_t));  /* allocate the space         */
   temp->line = newline;                    /* add the line               */
   temp->num = numline;                     /* add the number of the line */
   temp->next = NULL;                       /* make a lonely node         */
   temp->prev = NULL;
   temp->hexline = 0;
   return(temp);
}

/* adds a line to the global linelist with given parameters */
void add_line(char * newline, long int numline)
{
   line_t* temp;
   temp = new_line(newline, numline);       /* get the new node with these values */
   if(!linelist.head){                      /* if the list is empty               */
      linelist.head = temp;                 /*    then both the head and          */
      linelist.tail = temp;                 /*    the tail are the new node       */
   } else {                                 /* else                               */
      linelist.tail->next = temp;           /*    add node to the end             */
      temp->prev = linelist.tail;           /*    make end the previous node      */
      linelist.tail = temp;                 /*    make new node the end           */
   }
}

/* end of file view.c */ 
