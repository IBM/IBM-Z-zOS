
CDEFS=-D_ALL_SOURCE -D_OPEN_SYS -D_OPEN_THREADS

C89_CFLAGS=-Wc,list,off,noshow,so\($*.lst\)

LDFLAGS=-0 -Wl,map,list,msglevel=0,term=no,xref

all: gencert

clean:
	rm -f *.map *.lst *.o \
		gencert

gencert: gencert.o
	c89 $(LDFLAGS) -o $@ $< >$@.map

%.o: %.c
	c89 -c $(C89_CFLAGS) $(CDEFS) $<



