#######################################################################
## Makefile                                                          ##
##   Author: Nick Becker                                             ##
##   Created: 15 February, 2018                                      ##
##   License: apache-2.0 (Apache License 2.0)                        ##
##     URL: https://www.apache.org/licenses/LICENSE-2.0              ##
#######################################################################
## Beginning of Copyright and License                                ##
##                                                                   ##
## Copyright 2017 IBM Corp.                                          ##
##                                                                   ##
## Licensed under the Apache License, Version 2.0 (the "License");   ##
## you may not use this file except in compliance with the License.  ##
## You may obtain a copy of the License at                           ##
##                                                                   ##
## http://www.apache.org/licenses/LICENSE-2.0                        ##
##                                                                   ##
## Unless required by applicable law or agreed to in writing,        ##
## software distributed under the License is distributed on an       ##
## "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,      ##
## either express or implied.  See the License for the specific      ##
## language governing permissions and limitations under the License. ##
##                                                                   ##
## End of Copyright and License                                      ##
#######################################################################

# compiler
CC = c99
CFLAGS = -S -Wc,metal,longname,nosearch -I /usr/include/metal

# assembler
AS = as
ASFLAGS = -mrent -mgoff -aegms

# linker/binder
LD = ld
LDFLAGS  = -brent
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
