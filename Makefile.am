NULL = 

# Build in these directories:

SUBDIRS = \
	src \
	po \
	$(NULL)

californiadocdir = ${prefix}/doc/california
californiadoc_DATA = \
	ChangeLog \
	README \
	COPYING \
	AUTHORS \
	INSTALL \
	NEWS\
	$(NULL)

EXTRA_DIST = \
	$(californiadoc_DATA) \
	intltool-extract.in \
	intltool-merge.in \
	intltool-update.in\
	$(NULL)

DISTCLEANFILES = \
	configure \
	config.guess \
	config.h.in \
	config.h.in~ \
	config.sub \
	intltool-extract \
	intltool-extract.in \
	intltool-merge \
	intltool-merge.in \
	intltool-update \
	intltool-update.in \
	Makefile.in \
	po/.intltool-merge-cache \
	$(NULL)

EXTRADIST = \
	autogen.sh \
	$(NULL)

devclean:
	$(MAKE) -C src devclean

