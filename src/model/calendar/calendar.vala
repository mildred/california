/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

/**
 * Calendar data modeling.
 *
 * Most of the classes here are immutable and defined as GObjects to make them easier to use in
 * Vala and with support libraries.  The "core" logic relies heavily on GLib's Date, Time, and
 * DateTime classes.
 *
 * {@link Calendar.init} should be invoked prior to using any class in this namespace.  Call
 * {@link Calendar.terminate} when the application is closing.
 */

namespace California.Calendar {

/**
 * The current date according to the local timezone.
 *
 * This currently does not update as the program executes.
 */
public Date today;

private int init_count = 0;

private static string FMT_MONTH_YEAR_FULL;
private static string FMT_MONTH_YEAR_ABBREV;
private static string FMT_MONTH_FULL;
private static string FMT_MONTH_ABBREV;
private static string FMT_DAY_OF_WEEK_FULL;
private static string FMT_DAY_OF_WEEK_ABBREV;

public void init() {
    if (init_count++ > 0)
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
    
    DayOfWeek.init();
    DayOfMonth.init();
    Month.init();
    
    // TODO: Tie this into the event loop so it's properly updated; also make it a property of
    // an instance so it can be monitored
    today = new Date.now();
}

public void terminate() {
    if (--init_count > 0)
        return;
    
    today = null;
    
    Month.terminate();
    DayOfMonth.terminate();
    DayOfWeek.terminate();
    
    FMT_MONTH_YEAR_FULL = null;
    FMT_MONTH_YEAR_ABBREV = null;
    FMT_MONTH_FULL = null;
    FMT_MONTH_ABBREV = null;
    FMT_DAY_OF_WEEK_FULL = null;
    FMT_DAY_OF_WEEK_ABBREV = null;
}

}
