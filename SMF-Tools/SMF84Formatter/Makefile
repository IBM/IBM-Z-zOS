#######################################################################
#* smf84fmt.c                                                        ##
##   Author: Nick Becker                                             ##
##   Created: 15 February, 2018                                      ##
##   License: apache-2.0 (Apache License 2.0)                        ##
##     URL: https://www.apache.org/licenses/LICENSE-2.0              ##
#######################################################################

# compiler
CC = c99
CFLAGS = -S -Wc,metal,longname,nosearch -I /usr/include/metal

# assembler
AS = as
ASFLAGS = -mrent -mgoff -aegms

# linker/binder
LD = ld
LDFLAGS  = -bac=1 -brent
LDFLAGSR = -S "//'SYS1.CSSLIB'"

STEPLIB = <YOUR.LINKLIB.HERE>

#default rule
all: smf84fmt

# cleanup rules
clean:
	rm -f *.o *.s

cleanall:
	rm -f *.o *.s

# compilations
%.s: %.c
	$(CC) $(CFLAGS) $<

# assemblies
%.o: %.s
	$(AS) $(ASFLAGS) -o $@ $< >$(<:.s=.asmlst)

# linkedit/binds
smf84fmt: smf84fmt.o
	$(LD) $(LDFLAGS) $(LDFLAGSR) -o $@ $<
	$(LD) $(LDFLAGS) $(LDFLAGSR) -o "//'$(STEPLIB)($@)'" $<
