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
private static unowned string FMT_AM;
private static unowned string FMT_BRIEF_AM;
private static unowned string FMT_PM;
private static unowned string FMT_BRIEF_PM;
private static unowned string FMT_12HOUR_MIN_MERIDIEM;
private static unowned string FMT_12HOUR_MIN_SEC_MERIDIEM;
private static unowned string FMT_24HOUR_MIN;
private static unowned string FMT_24HOUR_MIN_SEC;

public void init() throws Error {
    if (!California.Unit.do_init(ref init_count))
        return;
    
    // Ripped from Shotwell proposed patch for localizing time (http://redmine.yorba.org/issues/2462)
    // courtesy Marcel Stimberg.  Another example may be found here:
    // http://bazaar.launchpad.net/~indicator-applet-developers/indicator-datetime/trunk.12.10/view/head:/src/utils.c
    
    // Because setlocale() is a process-wide setting, need to cache strings at startup, otherwise
    // risk problems with threading
    
    string? messages_locale = Intl.setlocale(LocaleCategory.MESSAGES, null);
    string? time_locale = Intl.setlocale(LocaleCategory.TIME, null);
    
    // LANGUAGE must be unset before changing locales, as it trumps all the LC_* variables
    string? language_env = Environment.get_variable("LANGUAGE");
    if (language_env != null)
        Environment.unset_variable("LANGUAGE");
    
    // Swap LC_TIME's setting into LC_MESSAGE's.  This allows performing lookups of time-based values
    // from a different translation file, useful in mixed-locale settings
    if (time_locale != null)
        Intl.setlocale(LocaleCategory.MESSAGES, time_locale);
    
    // These are not marked for translation because they involve no ordering of format specifiers
    // and strftime handles translating them to the locale
    FMT_MONTH_FULL = "%B";
    FMT_MONTH_ABBREV = "%b";
    FMT_DAY_OF_WEEK_FULL = "%A";
    FMT_DAY_OF_WEEK_ABBREV = "%a";
    FMT_FULL_DATE = "%x";
    
    /// The month and year according to locale preferences, i.e. "March 2014"
    /// See http://www.cplusplus.com/reference/ctime/strftime/ for format reference
    FMT_MONTH_YEAR_FULL = _("%B %Y");
    
    /// The abbreviated month and year according to locale preferences, i.e. "Mar 2014"
    /// See http://www.cplusplus.com/reference/ctime/strftime/ for format reference
    FMT_MONTH_YEAR_ABBREV = _("%b %Y");
    
    /// A "pretty" date according to locale preferences, i.e. "Monday, March 10, 2014"
    /// See http://www.cplusplus.com/reference/ctime/strftime/ for format reference
    FMT_PRETTY_DATE = _("%A, %B %e, %Y");
    
    /// A "pretty" date with no year according to locale preferences, i.e. "Monday, March 10"
    /// See http://www.cplusplus.com/reference/ctime/strftime/ for format reference
    FMT_PRETTY_DATE_NO_YEAR = _("%A, %B %e");
    
    /// A "pretty" date abbreviated according to locale preferences, i.e. "Mon, Mar 10, 2014"
    /// See http://www.cplusplus.com/reference/ctime/strftime/ for format reference
    FMT_PRETTY_DATE_ABBREV = _("%a, %b %e, %Y");
    
    /// A "pretty" date abbreviated and no year according to locale preferences, i.e.
    /// "Mon, Mar 10"
    /// See http://www.cplusplus.com/reference/ctime/strftime/ for format reference
    FMT_PRETTY_DATE_ABBREV_NO_YEAR = _("%a, %b %e");
    
    /// Ante meridiem
    /// (Please translate even if 24-hour clock used in your locale; this allows for GNOME time
    /// format user settings to be honored)
    FMT_AM = _("am");
    
    /// Brief ante meridiem, i.e. "am" -> "a"
    /// (Please translate even if 24-hour clock used in your locale; this allows for GNOME time
    /// format user settings to be honored)
    FMT_BRIEF_AM = _("a");
    
    /// Post meridiem
    /// (Please translate even if 24-hour clock used in your locale; this allows for GNOME time
    /// format user settings to be honored)
    FMT_PM = _("pm");
    
    /// Brief post meridiem, i.e. "pm" -> "p"
    /// (Please translate even if 24-hour clock used in your locale; this allows for GNOME time
    /// format user settings to be honored)
    FMT_BRIEF_PM = _("p");
    
    /// The 12-hour time with minute and meridiem ("am" or "pm"), i.e. "5:06pm"
    /// (Please translate even if 24-hour clock used in your locale; this allows for GNOME time
    /// format user settings to be honored)
    FMT_12HOUR_MIN_MERIDIEM = _("%d:%02d%s");
    
    /// The 12-hour time with minute, seconds, and meridiem ("am" or "pm"), i.e. "5:06:31pm"
    /// (Please translate even if 24-hour clock used in your locale; this allows for GNOME time
    /// format user settings to be honored)
    FMT_12HOUR_MIN_SEC_MERIDIEM = _("%d:%02d:%02d%s");
    
    /// The 24-hour time with minutes, i.e. "17:06"
    FMT_24HOUR_MIN = _("%d:%02d");
    
    /// The 24-hour time with minutes and seconds, i.e. "17:06:31"
    FMT_24HOUR_MIN_SEC = _("%d:%02d:%02d");
    
    // return LC_MESSAGES back to proper locale and return LANGUAGE environment variable
    if (messages_locale != null)
        Intl.setlocale(LocaleCategory.MESSAGES, messages_locale);
    if (language_env != null)
        Environment.set_variable("LANGUAGE", language_env, true);
    
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
