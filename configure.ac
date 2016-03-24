AC_INIT([california], [0.4.0], [jim@yorba.org], [california])
AC_CONFIG_SRCDIR([Makefile.am])
AC_CONFIG_HEADERS([config/config.h])
AC_CONFIG_MACRO_DIR([m4])
AC_CONFIG_AUX_DIR([config])

AM_INIT_AUTOMAKE([dist-xz no-dist-gzip subdir-objects])
AM_MAINTAINER_MODE

AC_PROG_CC
AM_PROG_CC_C_O

AC_PATH_PROG(VALAC, valac, valac)
AC_SUBST(VALAC)
AM_PROG_VALAC(0.24.0)

AC_PATH_PROG(GLIB_COMPILE_RESOURCES, glib-compile-resources)

IT_PROG_INTLTOOL([0.35.0])
GETTEXT_PACKAGE=california
AC_SUBST(GETTEXT_PACKAGE)

AC_SUBST(CFLAGS)
AC_SUBST(CPPFLAGS)
AC_SUBST(LDFLAGS)

GLIB_REQUIRED=2.38.0
GTK_REQUIRED=3.12.2
GEE_REQUIRED=0.10.5
ECAL_REQUIRED=3.13.90
LIBSOUP_REQUIRED=2.44
GDATA_REQUIRED=0.14.0
GOA_REQUIRED=3.8.3
GOBJECT_INTROSPECTION_REQUIRED=1.38.0

PKG_CHECK_MODULES(CALIFORNIA, [
	glib-2.0 >= $GLIB_REQUIRED
	gobject-2.0 >= $GLIB_REQUIRED
	gtk+-3.0 >= $GTK_REQUIRED
	gee-0.8 >= $GEE_REQUIRED
	libecal-1.2 >= $ECAL_REQUIRED
	libsoup-2.4 >= $LIBSOUP_REQUIRED
	libgdata >= $GDATA_REQUIRED
	goa-1.0 >= $GOA_REQUIRED
	gobject-introspection-1.0 >= $GOBJECT_INTROSPECTION_REQUIRED
])

AC_SUBST(CALIFORNIA_CFLAGS)
AC_SUBST(CALIFORNIA_LIBS)

GLIB_GSETTINGS
YELP_HELP_INIT

#
# system capabilities
#

# _NL_TIME_FIRST_WEEKDAY is an enum and not a define
AC_MSG_CHECKING([for _NL_TIME_FIRST_WEEKDAY])
AC_LINK_IFELSE([AC_LANG_PROGRAM([[#include <langinfo.h>]],
                                [[char c;
                                  c = *((unsigned char *)  nl_langinfo(_NL_TIME_FIRST_WEEKDAY));]])],
               [california_ok=yes], [california_ok=no])
AC_MSG_RESULT($california_ok)
AM_CONDITIONAL(HAVE__NL_TIME_FIRST_WEEKDAY, test "$california_ok" = "yes")

# xdg-utils (specifically, xdg-email)
AC_CHECK_PROG([XDG_EMAIL], [xdg-email], [yes], [no])
AS_IF([test "x$XDG_EMAIL" != xyes], [AC_MSG_ERROR([xdg-email required. Please install xdg-utils package.])])

#
# configure switches
#
# Unity support
#

AC_MSG_CHECKING([Unity support])
AC_ARG_ENABLE(
	unity,
	[  --enable-unity          enable Unity support [[default=disabled]]],
	[ unity=$enableval ],
	[ unity=no ]
)

AC_MSG_RESULT($unity)
AM_CONDITIONAL(ENABLE_UNITY, test "x$unity" = "xyes")

#
# Fatal warnings (valac only)
#

AC_MSG_CHECKING([fatal Vala warnings])
AC_ARG_ENABLE(
    fatal,
    [  --disable-fatal         disable fatal warnings from Vala compiler [[default=enabled]]],
    [ fatal=$enableval ],
    [ fatal=yes ]
)

AC_MSG_RESULT($fatal)
AM_CONDITIONAL(DISABLE_FATAL_WARNINGS, test "x$fatal" = "xno")

#
# /configure switches
#

AC_CONFIG_FILES([
	Makefile
	src/Makefile
	po/Makefile.in
	help/Makefile
	data/california.desktop.in
])

AC_OUTPUT

AC_MSG_RESULT([
Options:
	Unity support:		$unity
	Fatal Vala warnings:	$fatal
])

