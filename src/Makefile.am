AM_CPPFLAGS = \
	$(CALIFORNIA_CFLAGS) \
	-include $(CONFIG_HEADER) \
	$(NULL)

bin_PROGRAMS = california

# This ensures that all ./configure switches and detected configuration variances are accounted for
# when compiling the Vala files.  However, this also means Vala is required to build California.
california_vala.stamp: ../config.status

california_VALASOURCES = \
	activator/activator.vala \
	activator/activator-instance.vala \
	activator/activator-instance-list.vala \
	\
	activator/caldav/caldav-activator-instance.vala \
	activator/caldav/caldav-subscribe.vala \
	\
	activator/generic/generic-subscribe.vala \
	\
	activator/google/google-activator-instance.vala \
	activator/google/google-authenticating-pane.vala \
	activator/google/google-calendar-list-pane.vala \
	activator/google/google-login-pane.vala \
	\
	activator/webcal/webcal-activator-instance.vala \
	activator/webcal/webcal-subscribe.vala \
	\
	application/california-application.vala \
	application/california-commandline.vala \
	application/california-resource.vala \
	application/california-settings.vala \
	application/main.vala \
	\
	backing/backing.vala \
	backing/backing-caldav-subscribable.vala \
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
	calendar/calendar-date-ordering.vala \
	calendar/calendar-dbus.vala \
	calendar/calendar-duration.vala \
	calendar/calendar-error.vala \
	calendar/calendar-exact-time.vala \
	calendar/calendar-exact-time-span.vala \
	calendar/calendar-first-of-week.vala \
	calendar/calendar-month.vala \
	calendar/calendar-month-of-year.vala \
	calendar/calendar-month-span.vala \
	calendar/calendar-olson-zone.vala \
	calendar/calendar-span.vala \
	calendar/calendar-system.vala \
	calendar/calendar-timezone.vala \
	calendar/calendar-unit.vala \
	calendar/calendar-unit-span.vala \
	calendar/calendar-wall-time.vala \
	calendar/calendar-week.vala \
	calendar/calendar-week-span.vala \
	calendar/calendar-year.vala \
	calendar/calendar-year-span.vala \
	\
	collection/collection.vala \
	collection/collection-iterable.vala \
	collection/collection-lookahead-stack.vala \
	collection/collection-simple-iterator.vala \
	collection/collection-simple-iterable.vala \
	\
	component/component.vala \
	component/component-date-time.vala \
	component/component-details-parser.vala \
	component/component-error.vala \
	component/component-event.vala \
	component/component-icalendar.vala \
	component/component-instance.vala \
	component/component-person.vala \
	component/component-recurrence-rule.vala \
	component/component-uid.vala \
	component/component-vtype.vala \
	\
	event-editor/event-editor.vala \
	event-editor/event-editor-attendees-card.vala \
	event-editor/event-editor-date-time-card.vala \
	event-editor/event-editor-date-time-widget.vala \
	event-editor/event-editor-deck.vala \
	event-editor/event-editor-main-card.vala \
	event-editor/event-editor-recurring-card.vala \
	\
	host/host.vala \
	host/host-calendar-list-item.vala \
	host/host-import-calendar.vala \
	host/host-main-window.vala \
	host/host-main-window-title.vala \
	host/host-quick-create-event.vala \
	host/host-show-event.vala \
	\
	manager/manager.vala \
	manager/manager-calendar-list.vala \
	manager/manager-calendar-list-item.vala \
	manager/manager-remove-calendar.vala \
	manager/manager-window.vala \
	\
	tests/tests.vala \
	tests/tests-calendar-date.vala \
	tests/tests-calendar-exact-time.vala \
	tests/tests-calendar-exact-time-span.vala \
	tests/tests-calendar-month-of-year.vala \
	tests/tests-calendar-month-span.vala \
	tests/tests-calendar-wall-time.vala \
	tests/tests-iterable.vala \
	tests/tests-quick-add.vala \
	tests/tests-quick-add-recurring.vala \
	tests/tests-string.vala \
	\
	toolkit/toolkit.vala \
	toolkit/toolkit-button-connector.vala \
	toolkit/toolkit-button-event.vala \
	toolkit/toolkit-calendar-popup.vala \
	toolkit/toolkit-card.vala \
	toolkit/toolkit-combo-box-text-model.vala \
	toolkit/toolkit-deck.vala \
	toolkit/toolkit-deck-popover.vala \
	toolkit/toolkit-deck-window.vala \
	toolkit/toolkit-editable-label.vala \
	toolkit/toolkit-entry-clear-text-connector.vala \
	toolkit/toolkit-entry-filter-connector.vala \
	toolkit/toolkit-event-connector.vala \
	toolkit/toolkit-listbox-model.vala \
	toolkit/toolkit-motion-connector.vala \
	toolkit/toolkit-motion-event.vala \
	toolkit/toolkit-mutable-widget.vala \
	toolkit/toolkit-popup.vala \
	toolkit/toolkit-region-manager.vala \
	toolkit/toolkit-rotating-button-box.vala \
	toolkit/toolkit-stack-model.vala \
	\
	util/util.vala \
	util/util-email.vala \
	util/util-gfx.vala \
	util/util-markup.vala \
	util/util-memory.vala \
	util/util-numeric.vala \
	util/util-scheduled.vala \
	util/util-string.vala \
	util/util-uri.vala \
	\
	unit-test/unit-test-harness.vala \
	\
	view/view.vala \
	view/view-chronology-motion.vala \
	view/view-container.vala \
	view/view-controllable.vala \
	view/view-palette.vala \
	\
	view/agenda/agenda.vala \
	view/agenda/agenda-controller.vala \
	view/agenda/agenda-date-row.vala \
	view/agenda/agenda-event-row.vala \
	view/agenda/agenda-load-more-row.vala \
	\
	view/common/common.vala \
	view/common/common-events-cell.vala \
	view/common/common-instance-container.vala \
	\
	view/month/month.vala \
	view/month/month-cell.vala \
	view/month/month-controller.vala \
	view/month/month-grid.vala \
	\
	view/week/week.vala \
	view/week/week-all-day-cell.vala \
	view/week/week-controller.vala \
	view/week/week-day-pane.vala \
	view/week/week-grid.vala \
	view/week/week-hour-runner.vala \
	view/week/week-pane.vala \
	\
	$(NULL)

california_SOURCES = \
	$(california_VALASOURCES) \
	california-resources.c \
	$(NULL)

california_RC = \
	rc/activator-generic-subscribe.ui \
	rc/activator-google-authenticating-pane.ui \
	rc/activator-google-calendar-list-pane.ui \
	rc/activator-google-login-pane.ui \
	rc/activator-instance-list.ui \
	rc/app-menu.interface \
	rc/event-editor-attendees-card.ui \
	rc/event-editor-date-time-card.ui \
	rc/event-editor-date-time-widget.ui \
	rc/event-editor-main-card.ui \
	rc/event-editor-recurring-card.ui \
	rc/host-calendar-list-item.ui \
	rc/host-import-calendar.ui \
	rc/host-main-window-title.ui \
	rc/host-quick-create-event.ui \
	rc/host-show-event.ui \
	rc/manager-calendar-list.ui \
	rc/manager-calendar-list-item.ui \
	rc/manager-remove-calendar.ui \
	rc/view-agenda-date-row.ui \
	rc/view-agenda-event-row.ui \
	rc/view-agenda-load-more-row.ui \
	rc/window-menu.interface \
	$(NULL)

california_OPTIONAL_VALAFLAGS =

if ENABLE_UNITY
california_OPTIONAL_VALAFLAGS += --define ENABLE_UNITY
endif

if HAVE__NL_TIME_FIRST_WEEKDAY
california_OPTIONAL_VALAFLAGS += --define HAVE__NL_TIME_FIRST_WEEKDAY
endif

if !DISABLE_FATAL_WARNINGS
california_OPTIONAL_VALAFLAGS += --fatal-warnings
endif

california_VALAFLAGS = \
	--debug --enable-checking --vapidir $(top_srcdir)/vapi --target-glib=2.38 \
	--enable-deprecated \
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
	--pkg libgdata \
	--pkg Goa-1.0 \
	--pkg langinfo \
	$(NULL)

# Note that code for SOURCE_ROOT_DIR must be changed if this file is moved to different directory
SOURCE_ROOT_DIR = `cd ..; pwd`

california_CFLAGS = \
	-DGETTEXT_PACKAGE=\""california"\" \
	-DPREFIX=\"$(prefix)\" \
	-DSOURCE_ROOT_DIR=\"$(SOURCE_ROOT_DIR)\" \
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
