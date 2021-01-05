view - a multi-mode text viewer utility

usage:  view [-?] [-a] [-c] [-t] [-x] <filename>

        -?  =  Display help details.
        -a  =  Display ASCII translation.
        -c  =  Turns on case-sensitivity in search mode.
        -t  =  Turns on line-truncation mode.
        -x  =  Display hex codes for characters.


runtime commands:

        t   =  Top of file          (also Home key)
        b   =  Bottom of file       (also End key)
        p   =  Previous page        (also PgUp key)
        n   =  Next page            (also PgDn key)
        u   =  Up one line          (also up arrow key)
        d   =  Down one line        (also down arrow key)
        x   =  toggle heX mode
        s   =  enter Search mode    (hit enter key when done)
        Tab =  search again for last search string
        g   =  Goto line            <enter line number>
        q   =  Quit program


required programs:  none **


description:

'view' is a text viewer that can handle both EBCDIC (IBM-1047) and 
ASCII (ISO8859-1) files.  It will load files of any type, and attempt
to format them based on which mode used (default: ebcdic).  any
characters that are not understood will be substituted with an 
upside-down question mark.  


details on flags:

  -a  -  this will load the file in ascii mode, display it using the ascii
         code page.  with binary files it will still insert the formats
         of ascii TAB and CR characters.  the user cannot toggle this mode.

  -c  -  this turns on case-sensitivity when the user searches in the file.
         the default is case-insensitive. the user cannot toggle this mode.

  -t  -  this causes the load process to truncate lines that are longer than
         the width of the screen.  characters that go past the edge of the
         screen are not taken into account in this mode, and thus cannot be
         searched or scrolled into.  the default mode is to wrap the line.
         a wrapped line ends in a '\' backslash character.  the user cannot
         toggle this mode.

  -x  -  this will load the file and immediately toggle into hex mode.  
         in hex mode each line is expanded into three extra lines that show
         the two 'nibbles' of each byte, and a blank line for ease in 
         reading.  this mode can be toggled off and on with 'x'.


details on commands:

   t  -  go to the first line in the file.  <Home>

   b  -  go to the last line in the file.   <End>
   
   p  -  go up one page.                    <PgUp>

   n  -  go down one page.                  <PgDn>

   u  -  go up one line.                    <UpArrow>

   d  -  go down one line.                  <DownArrow>
   
   x  -  toggle hex mode. 

   g  -  goto line.  enter the number of the line you wish to go to, 
         followed by <Enter>.

   s  -  begin searching.  type the search string at the following prompt
         and it will search forward in the file from the current position.
         press <Enter> to leave, or <Tab> to search again for the same
         search string.

<Tab> -  search again for the last search string entered.

   q  -  quit out of the program.



limitations:

only one file at a time.
cannot toggle ascii, truncation, or case-sensitive mode.
not an editor.


** 'view' attempts to invoke 'stty' to determine the screen size, but it 
   is not necessary in order to run.  if the call fails, it will assume
   80 by 24 mode.  'stty' must list the rows & columns to take advantage
   of other screen sizes.


written by:

Jason M. Heim <heim@us.ibm.com>

Copyright 1997 IBM Corp.
 
