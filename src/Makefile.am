NULL = 

AM_CPPFLAGS = \
	$(CALIFORNIA_CFLAGS) \
	-include $(CONFIG_HEADER) \
	$(NULL)

bin_PROGRAMS = california

california_SOURCES = \
	main.vala \
	$(NULL)

california_VALAFLAGS = \
	--fatal-warnings -g --enable-checking --thread \
	--pkg glib-2.0

california_LDADD = \
	$(CALIFORNIA_LIBS) \
	$(NULL)

EXTRA_DIST = \
	$(NULL)

CLEANFILES = \
	$(NULL)

DISTCLEANFILES = \
	$(california_SOURCES:%.vala=%.c) \
	$(NULL)

