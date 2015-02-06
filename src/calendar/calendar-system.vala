/* Copyright 2014-2015 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Calendar {

/**
 * A singleton offering system-based calendar and time information and updates of important changes.
 *
 * Most of System's properties are static as a convenience for callers (to avoid having to always
 * reference {@link instance}).  Since static properties have no notification mechanism, callers
 * interested in being notified of changes must subscribe to the instance's particular signals,
 * i.e. {@link zone_changed}.
 */

public class System : BaseObject {
    public const string PROP_SYSTEM_FIRST_OF_WEEK = "system-first-of-week";
    
    private const string CLOCK_FORMAT_SCHEMA = "org.gnome.desktop.interface";
    private const string CLOCK_FORMAT_KEY = "clock-format";
    private const string CLOCK_FORMAT_24H = "24h";
    
    private const int CHECK_DATE_PRIORITY = Priority.LOW;
    private const int MIN_CHECK_DATE_INTERVAL_SEC = 1;
    private const int MAX_CHECK_DATE_INTERVAL_SEC = 30;
    
    public static System instance { get; private set; }
    
    /**
     * The current date according to the local timezone.
     *
     * @see today_changed
     */
    public static Date today { get; private set; }
    
    /**
     * Returns the current {@link ExactTime} of the local {@link Timezone}.
     */
    public static ExactTime now {
        owned get {
            return new ExactTime.now(Timezone.local);
        }
    }
    
    /**
     * If the current user is configured to use 12 or 24-hour time.
     */
    public static bool is_24hr { get; private set; }
    
    /**
     * The user's locale's {@link DateOrdering}.
     *
     * Date ordering may be set, but this is only for unit testing (hence there's no signal
     * reporting its change).  The application shouldn't set this and let the value be determined
     * at startup.
     *
     * @see date_separator
     */
    public static DateOrdering date_ordering { get; set; }
    
    /**
     * The user's locale's date separator character.
     *
     * Generally this is expected to be a slash ("/"), a dot ("."), or a dash ("-').  Not all
     * cultures use consistent separators (i.e. Chinese uses marks indicating year, day, and month).
     * It's assumed this is merely a common (or common enough) character to be used when displaying
     * or parsing dates.
     *
     * Like {@link date_ordering}, this may be set for unit testing, but the application should
     * let this be determined at startup.
     */
    public static string date_separator { get; set; }
    
    /**
     * Returns the system's configured zone as an {@link OlsonZone}.
     */
    public static OlsonZone zone { get; private set; }
    
    /**
     * The current system {@link Timezone}.
     *
     * @see timezone_changed
     * @see Timezone.utc
     */
    public static Timezone timezone { get; private set; }
    
    /**
     * The user's preferred start of the week.
     *
     * Unlike most of the other properties here (which are determined by examining and monitoring
     * the system), this is a combination of a user preference (configured by the outer application)
     * and a system/locale setting.  It's stored here because it's something that many components
     * in {@link Calendar} need access to and passing it around throughout the stack is
     * inconvenient.  However, many of the "basic" classes (such as {@link Date} and
     * {@link DayOfWeek}) still ask for it as a parameter to remain flexible.  In the case of
     * {@link Week}, it ''must'' store it, as its span of days is strictly determined by the
     * decision, which can change at runtime.
     *
     * When {@link Calendar.System} is first created, it's initialized to
     * {@link system_first_of_week}.  The outer application may pull an overriding value from the
     * configuration and override the original value.  (The outer application may want to have some
     * way to store "use system default" as a possible value.)
     *
     * @see first_of_week_changed
     */
    private static FirstOfWeek _first_of_week = FirstOfWeek.DEFAULT;
    public static FirstOfWeek first_of_week {
        get {
            return _first_of_week;
        }
        
        set {
            if (_first_of_week == value)
                return;
            
            FirstOfWeek old_fow = _first_of_week;
            _first_of_week = value;
            
            instance.first_of_week_changed(old_fow, _first_of_week);
        }
    }
    
    /**
     * System-defined (or locale-defined) start of the week.
     *
     * @see first_of_week
     */
    public FirstOfWeek system_first_of_week { get; private set; }
    
    private static DBus.timedated timedated_service;
    private static DBus.Properties timedated_properties;
    
    /**
     * Fired when {@link today} changes.
     *
     * This indicates that the system time has crossed midnight (potentially either direction since
     * clock adjustments can happen for a variety of reasons).
     */
    public signal void today_changed(Calendar.Date old_today, Calendar.Date new_today);
    
    /**
     * Fired when {@link is_24hr} changes.
     *
     * This means the user has changed the their clock format configuration.
     */
    public signal void is_24hr_changed(bool new_is_24hr);
    
    /**
     * Fired when {@link zone} changes.
     *
     * This generally indicates that the user has changed system time zone manually or that the
     * system detected the change through geolocation services.
     */
    public signal void zone_changed(OlsonZone old_zone, OlsonZone new_zone);
    
    /**
     * Fired when {@link local_timezone} changes due to system configuration changes.
     */
    public signal void timezone_changed(Timezone old_timezone, Timezone new_timezone);
    
    /**
     * Fired when {@link first_of_week} changes due to user configuration.
     */
    public signal void first_of_week_changed(FirstOfWeek old_fow, FirstOfWeek new_fow);
    
    private GLib.Settings system_clock_format_schema = new GLib.Settings(CLOCK_FORMAT_SCHEMA);
    private Scheduled scheduled_date_timer;
    
    private System() {
        zone = new OlsonZone(timedated_service.timezone);
        timezone = new Timezone(zone);
        debug("Local zone: %s", zone.to_string());
        
        // to be notified of changes as they occur
        timedated_properties.properties_changed.connect(on_timedated_properties_changed);
        
        // monitor 12/24-hr setting for changes and update
        is_24hr = system_clock_format_schema.get_string(CLOCK_FORMAT_KEY) == CLOCK_FORMAT_24H;
        system_clock_format_schema.changed[CLOCK_FORMAT_KEY].connect(() => {
            bool new_is_24hr = system_clock_format_schema.get_string(CLOCK_FORMAT_KEY) == CLOCK_FORMAT_24H;
            if (new_is_24hr != is_24hr) {
                is_24hr = new_is_24hr;
                is_24hr_changed(is_24hr);
            }
        });
        
        // timezone change can potentially update "today"; unless there's a system event we can
        // trap to indicate when the date has changed, use the event loop to check once every so
        // often, but also attempt to calculate time until midnight to change along with it ...
        // this may seem wasteful, but since the date can change for a lot of reasons (user
        // intervention, clock drift, NTP, etc.) this is a simple way to stay on top of things
        today = new Date.now(Timezone.local);
        scheduled_date_timer = new Scheduled.once_after_sec(next_check_today_interval_sec(),
            check_today_changed, CHECK_DATE_PRIORITY);
        
        // determine the date ordering and separator by using strftime's response
        Calendar.Date unique_date;
        try {
            unique_date = new Calendar.Date(Calendar.DayOfMonth.for_checked(3),
                Calendar.Month.for_checked(4), new Calendar.Year(2001));
        } catch (Error err) {
            error("Unable to generate test date 3/4/2001: %s", err.message);
        }
        
        string formatted = unique_date.format("%x");
        
        int a, b, c;
        char first_separator, second_separator;
        if (formatted.scanf("%d%c%d%c%d", out a, out first_separator, out b, out second_separator, out c) == 5) {
            // convert four-digit year to two-digit
            a = (a == 2001) ? 1 : a;
            b = (b == 2001) ? 1 : b;
            c = (c == 2001) ? 1 : c;
            
            if (a == 3 && b == 4 && c == 1)
                date_ordering = DateOrdering.DMY;
            else if (a == 4 && b == 3 && c == 1)
                date_ordering = DateOrdering.MDY;
            else if (a == 1 && b == 3 && c == 4)
                date_ordering = DateOrdering.YDM;
            else if (a == 1 && b == 4 && c == 3)
                date_ordering = DateOrdering.YMD;
            else
                date_ordering = DateOrdering.DEFAULT;
        } else {
            // couldn't determine
            date_ordering = DateOrdering.DEFAULT;
        }
        
        // use first separator as date separator ... do some sanity checking here
        switch (first_separator) {
            case '/':
            case '.':
            case '-':
                date_separator = first_separator.to_string();
            break;
            
            default:
                date_separator = "/";
            break;
        }
        
        debug("Date ordering: %s, separator: %s (formatted=%s)", date_ordering.to_string(),
            date_separator.to_string(), formatted);
        
        // Borrowed liberally (but not exactly) from GtkCalendar; see gtk_calendar_init
#if HAVE__NL_TIME_FIRST_WEEKDAY
        debug("Using _NL_TIME_FIRST_WEEKDAY for system first of week");
        
        // 1-based day (1 == Sunday)
        int first_weekday = Langinfo.lookup_int(Langinfo.Item.INT_TIME_FIRST_WEEKDAY);
        
        // I haven't the foggiest what this is returning, but note that Nov 30 1997 is a Sunday and
        // Dec 01 1997 is a Monday.
        int week_origin = (int) Langinfo.lookup(Langinfo.Item.TIME_WEEK_1STDAY);
        
        // values are translated into 0-based day (as per gtkcalendar.c), 0 == Sunday
        int week_1stday;
        switch (week_origin) {
            case 19971130:
                week_1stday = 0;
            break;
            
            case 19971201:
                week_1stday = 1;
            break;
            
            default:
                warning("Unknown value of _NL_TIME_WEEK_1STDAY: %d (%Xh)", week_origin, week_origin);
                week_1stday = 0;
            break;
        }
        
        // this yields a 0-based value, 0 == Sunday
        int week_start = (week_1stday + first_weekday - 1) % 7;
        
        // convert into our first day of week value
        switch (week_start) {
            case 0:
                system_first_of_week = FirstOfWeek.SUNDAY;
            break;
            
            case 1:
                system_first_of_week = FirstOfWeek.MONDAY;
            break;
            
            default:
                warning("Unknown week start value, using default: %d", week_start);
                system_first_of_week = FirstOfWeek.DEFAULT;
            break;
        }
#else
        debug("_NL_TIME_FIRST_WEEKDAY unavailable for system first of week");
        
        // For now, just use the default.  Later, user will be able to configure this.
        system_first_of_week = FirstOfWeek.DEFAULT;
#endif
        
        debug("System first day of week: %s", system_first_of_week.to_string());
    }
    
    internal static void preinit() throws IOError {
        timedated_service = Bus.get_proxy_sync(BusType.SYSTEM, DBus.timedated.NAME,
            DBus.timedated.OBJECT_PATH);
        timedated_properties = Bus.get_proxy_sync(BusType.SYSTEM, DBus.Properties.NAME,
            DBus.timedated.OBJECT_PATH);
    }
    
    internal static void init() {
        instance = new System();
        
        // initialize, application may override (can't do this in ctor due to how first_of_week
        // setter is built)
        first_of_week = instance.system_first_of_week;
    }
    
    internal static void terminate() {
        instance = null;
        timedated_service = null;
        timedated_properties = null;
    }
    
    private void on_timedated_properties_changed(string interf,
        HashTable<string, Variant> changed_properties_values, string[] changed_properties) {
        if (changed_properties_values.contains(DBus.timedated.PROP_TIMEZONE)
            || DBus.timedated.PROP_TIMEZONE in changed_properties) {
            OlsonZone old_zone = zone;
            zone = new OlsonZone(timedated_service.timezone);
            debug("New local zone: %s", zone.to_string());
            
            Timezone old_timezone = timezone;
            timezone = new Timezone(zone);
            
            // fire signals last in case a subscriber monitoring zone thinks that local_timezone
            // has also changed
            zone_changed(old_zone, zone);
            timezone_changed(old_timezone, timezone);
            
            // update current date, if necessary
            update_today();
        }
    }
    
    private int next_check_today_interval_sec() {
        // get the amount of time until midnight, adding one back to account for the second needed
        // to cross into the next day, and another one because this isn't rocket science but a
        // best-effort kind of thing
        ExactTime last_sec_of_day = new ExactTime(Timezone.local, today, WallTime.latest);
        int64 sec_to_midnight = last_sec_of_day.difference(new ExactTime.now(Timezone.local)) + 2;
        
        // clamp values to (a) ensure zero is never passed to Timeout.add_seconds(), which could
        // cause brief racing around midnight if close (but not close enough) to the appointed hour,
        // and (b) not too far out in case the user changes the date and would like to see the
        // change in California at some reasonable interval
        return (int) sec_to_midnight.clamp(MIN_CHECK_DATE_INTERVAL_SEC, MAX_CHECK_DATE_INTERVAL_SEC);
    }
    
    // See note in constructor for logic behind this SourceFunc
    private void check_today_changed() {
        update_today();
        
        // reschedule w/ the next interval
        scheduled_date_timer = new Scheduled.once_after_sec(next_check_today_interval_sec(),
            check_today_changed, CHECK_DATE_PRIORITY);
    }
    
    private void update_today() {
        Date new_today = new Date.now(Timezone.local);
        if (new_today.equal_to(today))
            return;
        
        Date old_today = today;
        today = new_today;
        debug("Date changed: %s", new_today.to_string());
        
        today_changed(old_today, new_today);
    }
    
    public override string to_string() {
        return get_class().get_type().name();
    }
}

}

