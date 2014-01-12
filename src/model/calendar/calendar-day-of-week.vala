/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Calendar {

/**
 * An immutable one-based representation of a day of a week (Monday, Tuesday, etc.).
 *
 * Neither Monday nor Sunday are hard-defined as the first day of the week.  Accessing these
 * objects via for() requires the caller to specify which is their definition of the first weekday.
 */

public class DayOfWeek : BaseObject, Gee.Hashable<DayOfWeek> {
    public static DayOfWeek MON;
    public static DayOfWeek TUE;
    public static DayOfWeek WED;
    public static DayOfWeek THU;
    public static DayOfWeek FRI;
    public static DayOfWeek SAT;
    public static DayOfWeek SUN;
    
    public const int MIN = 1;
    public const int MAX = 7;
    public const int COUNT = MAX - MIN + 1;
    
    private static DayOfWeek[]? days_of_week_monday = null;
    private static DayOfWeek[]? days_of_week_sunday = null;
    
    /**
     * The abbreviated locale-specific name for the day of the week.
     */
    public string abbrev_name { get; private set; }
    
    /**
     * The full locale-specific name for the day of the week.
     */
    public string full_name { get; private set; }
    
    private int value_monday;
    private int value_sunday;
    
    private DayOfWeek(int value, string abbrev_name, string full_name) {
        assert(value >= MIN && value <= MAX);
        
        // internally, Monday is default the first day of the week
        value_monday = value;
        value_sunday = (value % COUNT) + 1;
        this.abbrev_name = abbrev_name;
        this.full_name = full_name;
    }
    
    internal static void init() {
        // Because ctime won't cough up the strings easily, get them out by walking a full week
        // of days (doesn't matter where we start, as long as they're valid days) and stash the
        // locale-specific strings to pass to the constructor
        GLib.Date date = GLib.Date();
        date.set_dmy(1, 1, 2014);
        
        // GLib.Weekday is 1-based, Monday first, so these arrays are the same
        string[] abbrevs = new string[COUNT];
        string[] fulls = new string[COUNT];
        char[] buf = new char[64];
        for (int ctr = MIN; ctr <= MAX; ctr++) {
            assert(date.valid());
            
            // GLib.Weekday is 1-based, Monday first
            int offset = (int) date.get_weekday() - 1;
            assert(offset >= 0 && offset < COUNT);
            
            date.strftime(buf, "%a");
            abbrevs[offset] = (string) buf;
            
            date.strftime(buf, "%A");
            fulls[offset] = (string) buf;
            
            date.add_days(1);
        }
        
        // Following GLib's lead, days of week Monday-first is straightforward
        days_of_week_monday = new DayOfWeek[COUNT];
        for (int ctr = MIN; ctr <= MAX; ctr++)
            days_of_week_monday[ctr - MIN] = new DayOfWeek(ctr, abbrevs[ctr - MIN], fulls[ctr - MIN]);
        
        MON = days_of_week_monday[0];
        TUE = days_of_week_monday[1];
        WED = days_of_week_monday[2];
        THU = days_of_week_monday[3];
        FRI = days_of_week_monday[4];
        SAT = days_of_week_monday[5];
        SUN = days_of_week_monday[6];
        
        // now fill in the Sunday-first array using the already-built objects
        days_of_week_sunday = new DayOfWeek[COUNT];
        days_of_week_sunday[0] = SUN;
        days_of_week_sunday[1] = MON;
        days_of_week_sunday[2] = TUE;
        days_of_week_sunday[3] = WED;
        days_of_week_sunday[4] = THU;
        days_of_week_sunday[5] = FRI;
        days_of_week_sunday[6] = SAT;
    }
    
    internal static void terminate() {
        days_of_week_monday = days_of_week_sunday = null;
        MON = TUE = WED = THU = FRI = SAT = SUN = null;
    }
    
    /**
     * Returns the day of the week for the specified one-based value.
     */
    public static DayOfWeek for(int value, FirstOfWeek first_of_week) throws CalendarError {
        int index = value - MIN;
        
        if (index < 0 || index >= COUNT)
            throw new CalendarError.INVALID("Invalid day of week value %d", value);
        
        switch (first_of_week) {
            case FirstOfWeek.MONDAY:
                return days_of_week_monday[index];
            
            case FirstOfWeek.SUNDAY:
                return days_of_week_sunday[index];
            
            default:
                assert_not_reached();
        }
    }
    
    /**
     * Should only be used by internal calls when value is known to be safe and doesn't originate
     * from external sources, like a file, network, or user-input.
     */
    internal static DayOfWeek for_checked(int value, FirstOfWeek first_of_week) {
        try {
            return for(value, first_of_week);
        } catch (CalendarError calerr) {
            error("%s", calerr.message);
        }
    }
    
    internal static DayOfWeek from_gdate(GLib.Date date) {
        assert(date.valid());
        
        // GLib.Weekday is Monday-first
        return for_checked(date.get_weekday(), FirstOfWeek.MONDAY);
    }
    
    /**
     * The one-based ordinal value of the day of the week, depended on what the definition of
     * the first day of the week.
     */
    public int ordinal(FirstOfWeek first_of_week) {
        switch (first_of_week) {
            case FirstOfWeek.MONDAY:
                return value_monday;
            
            case FirstOfWeek.SUNDAY:
                return value_sunday;
            
            default:
                assert_not_reached();
        }
    }
    
    public bool equal_to(DayOfWeek other) {
        return this == other;
    }
    
    public uint hash() {
        return direct_hash(this);
    }
    
    public override string to_string() {
        return full_name;
    }
}

}

