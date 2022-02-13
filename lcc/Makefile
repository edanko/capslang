# Wedit Makefile for project capslang
SRCDIR=e:\src\github.com\edanko\capslang
CFLAGS=-I"c:\lcc\include"  -O 
CC=$(LCCROOT)\bin\lcc.exe
LINKER=$(LCCROOT)\bin\lcclnk.exe
OBJS=\
	caps-min.obj

LIBS=
EXE=caps-min.exe

$(EXE):	$(OBJS) Makefile
	$(LINKER)  -s -subsystem windows -o $(SRCDIR)\lcc\caps-min.exe $(OBJS) $(LIBS)

# Build caps-min.c
CAPS-MIN_C=\

caps-min.obj: $(CAPS-MIN_C) $(SRCDIR)\caps-min.c
	$(CC) -c $(CFLAGS) $(SRCDIR)\caps-min.c

link:
	$(LINKER)  -s -subsystem windows -o $(SRCDIR)\lcc\caps-min.exe $(OBJS) $(LIBS)

clean:
	del $(OBJS) caps-min.exe
