# Property of IBM      
# Copyright IBM Corp. 1994, 1998
# All Rights Reserved.
#
# Title: Makefile 
#
# Purpose: Make the getuids utility
#
# Author: Marc J. Warden <mwarden@us.ibm.com>
#

.SUFFIX:

CC=c99
CFLAGS=-O2 -Wc,xplink,inline
LDFLAGS=-Wl,xplink,edit=no

Files = getuids.c \
	getuids.man1 \
	makefile \
	README

all: getuids

clean:
	rm -f *.o getuids

clobber: clean
	rm readmvs writemvs libmvs.a

list:
	@echo ${Files}
