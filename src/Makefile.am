NULL = 

AM_CPPFLAGS = \
	$(CALIFORNIA_CFLAGS) \
	-include $(CONFIG_HEADER) \
	$(NULL)

bin_PROGRAMS = california

california_VALASOURCES = \
	main.vala \
	application/california-application.vala \
	components/main-window.vala \
	$(NULL)

california_SOURCES = \
	$(california_VALASOURCES) \
	california-resources.c \
	$(NULL)

california_RC = \
	rc/app-menu.interface

california_VALAFLAGS = \
	--fatal-warnings -g --enable-checking --thread \
	--pkg gtk+-3.0 \
	--pkg gio-2.0 \
	--pkg posix \
	$(NULL)

california_CFLAGS = \
	-DGETTEXT_PACKAGE=\""california"\" \
	$(NULL)

california-resources.c: $(california_RC) california-resources.xml
	$(GLIB_COMPILE_RESOURCES) --target="$@" --generate-source california-resources.xml

california_LDADD = \
	$(CALIFORNIA_LIBS) \
	$(NULL)

EXTRA_DIST = \
	california-resources.xml \
	$(california_RC) \
	$(NULL)

CLEANFILES = \
	california-resources.c \
	$(NULL)

DISTCLEANFILES = \
	Makefile.in \
	$(NULL)

.PHONY: devclean
devclean: clean
	rm -f california_vala.stamp
	rm -f $(california_VALASOURCES:%.vala=%.c)

