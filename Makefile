VALA_SRC=$(wildcard src/*.vala)
VALA_CFLAGS=-g --pkg gtk+-2.0 --pkg gio-unix-2.0 --pkg gio-2.0

all: notmuch_gtk

notmuch_gtk: $(VALA_SRC) Makefile
	valac $(VALA_CFLAGS) -o notmuch_gtk $(VALA_SRC)

clean:
	-rm -f notmuch_gtk $(wildcard src/*.c)

.PHONY: clean all
