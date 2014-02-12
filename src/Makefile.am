NULL =

AM_CPPFLAGS = \
	$(CALIFORNIA_CFLAGS) \
	-include $(CONFIG_HEADER) \
	$(NULL)

bin_PROGRAMS = california

california_VALASOURCES = \
	application/california-application.vala \
	application/california-resource.vala \
	application/main.vala \
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
	base/base-object.vala \
	base/base-unit.vala \
	\
	collection/collection-simple-iterator.vala \
	collection/collection-simple-iterable.vala \
	\
	host/host.vala \
	host/host-create-event.vala \
	host/host-main-window.vala \
	host/host-show-event.vala \
	\
	model/calendar/calendar.vala \
	model/calendar/calendar-date-span.vala \
	model/calendar/calendar-day-of-month.vala \
	model/calendar/calendar-day-of-week.vala \
	model/calendar/calendar-date.vala \
	model/calendar/calendar-error.vala \
	model/calendar/calendar-exact-time.vala \
	model/calendar/calendar-exact-time-span.vala \
	model/calendar/calendar-first-of-week.vala \
	model/calendar/calendar-month.vala \
	model/calendar/calendar-month-of-year.vala \
	model/calendar/calendar-span.vala \
	model/calendar/calendar-unit.vala \
	model/calendar/calendar-wall-time.vala \
	model/calendar/calendar-week.vala \
	model/calendar/calendar-week-span.vala \
	model/calendar/calendar-year.vala \
	\
	model/component/component.vala \
	model/component/component-error.vala \
	model/component/component-event.vala \
	model/component/component-instance.vala \
	model/component/component-blank.vala \
	model/component/component-uid.vala \
	model/component/component-vtype.vala \
	\
	util/util-string.vala \
	\
	view/view.vala \
	view/view-controllable.vala \
	\
	view/month/month.vala \
	view/month/month-cell.vala \
	view/month/month-controllable.vala \
	\
	$(NULL)

california_SOURCES = \
	$(california_VALASOURCES) \
	california-resources.c \
	$(NULL)

california_RC = \
	rc/app-menu.interface \
	rc/create-event.ui \
	rc/show-event.ui \
	$(NULL)

california_VALAFLAGS = \
	--fatal-warnings -g --enable-checking --vapidir $(top_srcdir)/vapi --target-glib=2.38 \
	--gresources=california-resources.xml \
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
