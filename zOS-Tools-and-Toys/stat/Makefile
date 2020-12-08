# Makefile for 'view' utility
#
#    designed for use on IBM Unix System Services.
#    


# 'make' or 'make all' to compile, 'make clean' to remove all .o's and binary

# by default this will build in the same directory the files are in, you will
# have to modify it if you wish to do otherwise

CC      = c89
CFLAGS  = -c -O2 -Wc,xplink
LDFLAGS = -Wl,xplink,edit=no
OBJS    = stat.o
TARGET = stat

# --------------------------------------------------

all: $(TARGET)

$(TARGET): $(OBJS) 
	@echo 'Linking...'
	$(CC) -o $(TARGET) $(LDFLAGS) $(OBJS)

stat.o: stat.c
	$(CC) -o stat.o $(CFLAGS) stat.c
clean:
	rm -f *.o 
	rm -f $(TARGET)
