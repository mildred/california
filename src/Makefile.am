NULL =

AM_CPPFLAGS = \
	$(CALIFORNIA_CFLAGS) \
	-include $(CONFIG_HEADER) \
	$(NULL)

bin_PROGRAMS = california

california_VALASOURCES = \
	activator/activator.vala \
	activator/activator-instance.vala \
	activator/activator-instance-list.vala \
	activator/activator-window.vala \
	\
	activator/webcal/activator-webcal.vala \
	activator/webcal/activator-webcal-pane.vala \
	\
	application/california-application.vala \
	application/california-resource.vala \
	application/main.vala \
	\
	backing/backing.vala \
	backing/backing-calendar-source.vala \
	backing/backing-calendar-source-subscription.vala \
	backing/backing-calendar-subscription-manager.vala \
	backing/backing-error.vala \
	backing/backing-manager.vala \
	backing/backing-source.vala \
	backing/backing-store.vala \
	backing/backing-webcal-subscribable.vala \
	\
	backing/eds/backing-eds-calendar-source.vala \
	backing/eds/backing-eds-calendar-source-subscription.vala \
	backing/eds/backing-eds-store.vala \
	\
	base/base-object.vala \
	base/base-unit.vala \
	\
	calendar/calendar.vala \
	calendar/calendar-date-span.vala \
	calendar/calendar-day-of-month.vala \
	calendar/calendar-day-of-week.vala \
	calendar/calendar-date.vala \
	calendar/calendar-dbus.vala \
	calendar/calendar-error.vala \
	calendar/calendar-exact-time.vala \
	calendar/calendar-exact-time-span.vala \
	calendar/calendar-first-of-week.vala \
	calendar/calendar-month.vala \
	calendar/calendar-month-of-year.vala \
	calendar/calendar-olson-zone.vala \
	calendar/calendar-span.vala \
	calendar/calendar-system.vala \
	calendar/calendar-timezone.vala \
	calendar/calendar-unit.vala \
	calendar/calendar-wall-time.vala \
	calendar/calendar-week.vala \
	calendar/calendar-week-span.vala \
	calendar/calendar-year.vala \
	\
	collection/collection-simple-iterator.vala \
	collection/collection-simple-iterable.vala \
	\
	component/component.vala \
	component/component-date-time.vala \
	component/component-error.vala \
	component/component-event.vala \
	component/component-instance.vala \
	component/component-uid.vala \
	component/component-vtype.vala \
	\
	host/host.vala \
	host/host-calendar-popup.vala \
	host/host-color-chooser-popup.vala \
	host/host-create-update-event.vala \
	host/host-interaction.vala \
	host/host-main-window.vala \
	host/host-modal-window.vala \
	host/host-popup.vala \
	host/host-show-event.vala \
	\
	manager/manager.vala \
	manager/manager-calendar-list.vala \
	manager/manager-calendar-list-item.vala \
	manager/manager-window.vala \
	\
	util/util-gfx.vala \
	util/util-memory.vala \
	util/util-string.vala \
	util/util-uri.vala \
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
	rc/activator-list.ui \
	rc/app-menu.interface \
	rc/calendar-manager-list.ui \
	rc/calendar-manager-list-item.ui \
	rc/create-update-event.ui \
	rc/show-event.ui \
	rc/webcal-subscribe.ui \
	$(NULL)

california_OPTIONAL_VALAFLAGS =

if ENABLE_UNITY
california_OPTIONAL_VALAFLAGS += --define ENABLE_UNITY
endif

california_VALAFLAGS = \
	--fatal-warnings -g --enable-checking --vapidir $(top_srcdir)/vapi --target-glib=2.38 \
	--gresources=california-resources.xml \
	$(california_OPTIONAL_VALAFLAGS) \
	--pkg gtk+-3.0 \
	--pkg gio-2.0 \
	--pkg posix \
	--pkg gee-0.8 \
	--pkg libedataserver-1.2 \
	--pkg libecal-1.2 \
	--pkg libical \
	--pkg libsoup-2.4 \
	$(NULL)

california_CFLAGS = \
	-DGETTEXT_PACKAGE=\""california"\" \
	-DPREFIX=\"$(prefix)\" \
	$(NULL)

LIBS = \
	-lm \
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
