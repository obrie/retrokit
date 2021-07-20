PREFIX = /usr/lib
CC = cc
CFLAGS = -Wall -O2 -I$(PREFIX)/include
LDFLAGS = -L$(PREFIX)/lib

all: pdf
%.o: %.c
	$(CC) -c $(CFLAGS) $<
clean:
	-rm -f *.o pdf

# pdf support using mupdf
pdf: pdf.o
	$(CC) -o $@ $^ $(LDFLAGS) -lmupdf -lmupdf-third -lm
