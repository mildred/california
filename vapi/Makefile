
all: libecal-1.2.vapi

.PHONY: clean
clean:
	rm -f libecal-1.2.vapi libecal-1.2/libecal-1.2.gi

libecal-1.2/libecal-1.2.gi:
	vala-gen-introspect libecal-1.2 libecal-1.2

libecal-1.2.vapi: libecal-1.2/libecal-1.2.gi libical.vapi
	vapigen --vapidir=. --pkg=glib-2.0 --pkg=gio-2.0 --pkg=libical --pkg libedataserver-1.2  --library libecal-1.2 libecal-1.2/libecal-1.2.gi libecal-1.2/libecal-1.2-custom.vala

