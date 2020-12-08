HEADERS=netinet/ip_var.h netinet/ip_icmp.h netinet/in_systm.h netinet/ip.h

# Symbols needed by ping code
PINGSYMS=-DBIG_ENDIAN=1 -DLITTLE_ENDIAN=2 -DBYTE_ORDER=BIG_ENDIAN \
-DMAXHOSTNAMELEN=260

SYMS=-D_ALL_SOURCE -DMVSOEPORT $(PINGSYMS)

CFLAGS=-Wc,xplink -O2 $(SYMS) -I .
LDFLAGS=-Wl,xplink,edit=no

all: ping

ping: ping.c $(HEADERS)
	c89 -o ping $(CFLAGS) $(LDFLAGS) ping.c

clean:
	rm -f ping *.o *.dbg
