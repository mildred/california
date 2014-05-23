data_desktopdir = $(datadir)/applications
data_desktop_in_files = data/california.desktop.in
data_desktop_DATA = $(data_desktop_in_files:.desktop.in=.desktop)

data_appdatadir = $(datadir)/appdata
data_appdata_DATA = data/california.appdata.xml

EXTRA_DIST += \
	$(data_desktop_in_files) \
	data/california.appdata.xml \
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
