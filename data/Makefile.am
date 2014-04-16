data_desktopdir = $(datadir)/applications
data_desktop_in_files = data/california.desktop.in
data_desktop_DATA = $(data_desktop_in_files:.desktop.in=.desktop)

EXTRA_DIST += \
	$(data_desktop_in_files) \
	$(NULL)

CLEANFILES += \
	$(data_desktop_DATA) \
	$(NULL)

DISTCLEANFILES += \
	$(data_desktop_DATA) \
	$(NULL)

GITIGNOREFILES += \
	$(data_desktop_in_files) \
	$(data_desktop_DATA) \
	$(NULL)
