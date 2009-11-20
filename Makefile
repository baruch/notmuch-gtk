VALA_SRC=$(wildcard src/*.vala)
VALA_CFLAGS=-g

all: notmuch_gtk

notmuch_gtk: $(VALA_SRC) Makefile
	valac $(VALA_CFLAGS) -o notmuch_gtk $(VALA_SRC)
