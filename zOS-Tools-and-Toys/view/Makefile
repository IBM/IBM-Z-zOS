# Copyright 1997, IBM Corporation                                        *
#
# Makefile for 'view' utility
#
#    Designed for use on IBM Unix System Services.
#    Jason M. Heim
#

# 'make' or 'make all' to compile, 'make clean' to remove all .o's and binary

# By default this will build in the same directory the files are in, you will
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
