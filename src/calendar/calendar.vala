/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

/**
 * Calendar data modeling.
 *
 * Almost all of the classes here are immutable and defined as GObjects to make them easier to use
 * in Vala and with support libraries.  The "core" logic relies heavily on GLib's Date, Time, and
 * DateTime classes.
 *
 * {@link Calendar.init} should be invoked prior to using any class in this namespace.  Call
 * {@link Calendar.terminate} when the application is closing.
 */

namespace California.Calendar {

private int init_count = 0;

private static unowned string FMT_MONTH_YEAR_FULL;
private static unowned string FMT_MONTH_YEAR_ABBREV;
private static unowned string FMT_MONTH_FULL;
private static unowned string FMT_MONTH_ABBREV;
private static unowned string FMT_DAY_OF_WEEK_FULL;
private static unowned string FMT_DAY_OF_WEEK_ABBREV;
private static unowned string FMT_FULL_DATE;
private static unowned string FMT_PRETTY_DATE;
private static unowned string FMT_PRETTY_DATE_NO_YEAR;
private static unowned string FMT_PRETTY_DATE_ABBREV;
private static unowned string FMT_PRETTY_DATE_ABBREV_NO_YEAR;

public void init() throws Error {
    if (!California.Unit.do_init(ref init_count))
        return;
    
    // TODO: Properly fetch these from gettext() so the user's locale is respected (not just their
    // language)
    // TODO: Translator comments explaining these are strftime formatted strings
    FMT_MONTH_YEAR_FULL = _("%B %Y");
    FMT_MONTH_YEAR_ABBREV = _("%b %Y");
    FMT_MONTH_FULL = _("%B");
    FMT_MONTH_ABBREV = _("%b");
    FMT_DAY_OF_WEEK_FULL = _("%A");
    FMT_DAY_OF_WEEK_ABBREV = _("%a");
    FMT_FULL_DATE = _("%x");
    FMT_PRETTY_DATE = _("%A, %B %e, %Y");
    FMT_PRETTY_DATE_NO_YEAR = _("%A, %B %e");
    FMT_PRETTY_DATE_ABBREV = _("%a, %b %e, %Y");
    FMT_PRETTY_DATE_ABBREV_NO_YEAR = _("%a, %b %e");
    
    // This init() throws an IOError, so perform before others to prevent unnecessary unwinding
    System.preinit();
    
    // internal initialization
    OlsonZone.init();
    DayOfWeek.init();
    DayOfMonth.init();
    Month.init();
    WallTime.init();
    System.init();
    Timezone.init();
}

public void terminate() {
    if (!California.Unit.do_terminate(ref init_count))
        return;
    
    Timezone.terminate();
    System.terminate();
    WallTime.terminate();
    Month.terminate();
    DayOfMonth.terminate();
    DayOfWeek.terminate();
    OlsonZone.terminate();
}

}
