NULL =

AM_CPPFLAGS = \
	$(CALIFORNIA_CFLAGS) \
	-include $(CONFIG_HEADER) \
	$(NULL)

bin_PROGRAMS = california

california_VALASOURCES = \
	main.vala \
	\
	application/california-application.vala \
	application/resource.vala \
	\
	backing/backing.vala \
	backing/backing-calendar-source.vala \
	backing/backing-calendar-source-subscription.vala \
	backing/backing-error.vala \
	backing/backing-manager.vala \
	backing/backing-source.vala \
	backing/backing-store.vala \
	\
	backing/eds/backing-eds-calendar-source.vala \
	backing/eds/backing-eds-calendar-source-subscription.vala \
	backing/eds/backing-eds-store.vala \
	\
	base/base-init-guard.vala \
	base/base-object.vala \
	\
	components/main-window.vala \
	components/month-grid.vala \
	components/month-grid-cell.vala \
	\
	model/calendar/calendar.vala \
	model/calendar/calendar-date-span.vala \
	model/calendar/calendar-day-of-month.vala \
	model/calendar/calendar-day-of-week.vala \
	model/calendar/calendar-date.vala \
	model/calendar/calendar-error.vala \
	model/calendar/calendar-first-of-week.vala \
	model/calendar/calendar-month.vala \
	model/calendar/calendar-month-of-year.vala \
	model/calendar/calendar-unit.vala \
	model/calendar/calendar-week.vala \
	model/calendar/calendar-week-span.vala \
	model/calendar/calendar-year.vala \
	\
	model/component/component.vala \
	model/component/component-instance.vala \
	model/component/component-event.vala \
	model/component/component-uid.vala \
	\
	$(NULL)

california_SOURCES = \
	$(california_VALASOURCES) \
	california-resources.c \
	$(NULL)

california_RC = \
	rc/app-menu.interface

california_VALAFLAGS = \
	--fatal-warnings -g --enable-checking --vapidir $(top_srcdir)/vapi\
	--pkg gtk+-3.0 \
	--pkg gio-2.0 \
	--pkg posix \
	--pkg gee-0.8 \
	--pkg libedataserver-1.2 \
	--pkg libecal-1.2 \
	--pkg libical \
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

GITIGNOREFILES = \
	$(california_VALASOURCES:%.vala=%.c) \
	$(NULL)

.PHONY: devclean
devclean: clean
	rm -f california_vala.stamp
	rm -f $(california_VALASOURCES:%.vala=%.c)

-include $(top_srcdir)/git.mk
