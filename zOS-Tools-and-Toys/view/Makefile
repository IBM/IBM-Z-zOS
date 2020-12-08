# Copyright 1997, IBM Corporation                                        *
# All rights reserved                                                    *
#                                                                        *
# Distribute freely, except: don't remove my name from the source or     *
# documentation (don't take credit for my work), mark your changes       *
# (don't get me blamed for your possible bugs), don't alter or           *
# remove this notice.  No fee may be charged if you distribute the       *
# package (except for such things as the price of a disk or tape,        *
# postage, etc.).  No warranty of any kind, express or implied, is       *
# included with this software; use at your own risk, responsibility      *
# for damages (if any) to anyone resulting from the use of this          *
# software rests entirely with the user.                                 *
#                                                                        *
# Send me bug reports, bug fixes, enhancements, requests, flames,        *
# etc.  I can be reached as follows:                                     *
#                                                                        *
#          jason m. heim      heim@us.ibm.com                            *
#                                                                        *
#------------------------------------------------------------------------*
#
# Makefile for 'view' utility
#
#    designed for use on IBM Unix System Services.
#    Jason M. Heim
#    

# i have had trouble with curses when trying to compile on releases 4
# and below of IBM U.S.S.  please use release 5 or higher for your build.

# 'make' or 'make all' to compile, 'make clean' to remove all .o's and binary

# by default this will build in the same directory the files are in, you will
# have to modify it if you wish to do otherwise

# the binary file 'view' does not load any helper files, and can be copied to 
# /bin, /usr/bin, or other global $PATH to install.  it should be owned by
# ROOT and in mode 0755.

CC      = c89
CFLAGS  = -c -O2 -Wc,xplink
LDFLAGS = -Wl,xplink,edit=no
OBJS    = l_unix.o view.o
LIBS    = -lcurses 
TARGET = view

# --------------------------------------------------

all: $(TARGET)

$(TARGET): $(OBJS) 
	@echo 'Linking...'
	$(CC) -o $(TARGET) $(LDFLAGS) $(OBJS) $(LIBS)

view.o: view.c
	$(CC) -o view.o $(CFLAGS) view.c 

l_unix.o: l_unix.c
	@echo 'Building dependencies...'
	$(CC) -o l_unix.o $(CFLAGS) l_unix.c

clean:
	rm -f *.o 
	rm -f $(TARGET)
