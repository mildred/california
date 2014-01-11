/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Calendar {

/**
 * An immutable one-based representation of a day of a week (Monday, Tuesday, etc.).
 *
 * Monday is defined as the first day of the week (one).
 */

public class DayOfWeek : SimpleValue {
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
    
    private static DayOfWeek[]? days_of_week = null;
    
    /**
     * The abbreviated locale-specific name for the day of the week.
     */
    public string abbrev_name { get; private set; }
    
    /**
     * The full locale-specific name for the day of the week.
     */
    public string full_name { get; private set; }
    
    private DayOfWeek(int value, string abbrev_name, string full_name) {
        base (value, MIN, MAX);
        
        this.abbrev_name = abbrev_name;
        this.full_name = full_name;
    }
    
    internal static void init() {
        // Because ctime won't cough up the strings easily, get them out by walking a full week
        // of days (doesn't matter where we start, as long as they're valid days) and stash the
        // locale-specific strings to pass to the constructor
        GLib.Date date = GLib.Date();
        date.set_dmy(1, 1, 2014);
        
        string[] abbrevs = new string[COUNT];
        string[] fulls = new string[COUNT];
        char[] buf = new char[64];
        for (int ctr = MIN; ctr <= MAX; ctr++) {
            assert(date.valid());
            
            // GLib.Weekday is 1-based
            int offset = (int) date.get_weekday() - MIN;
            assert(offset >= 0 && offset < COUNT);
            
            date.strftime(buf, "%a");
            abbrevs[offset] = (string) buf;
            
            date.strftime(buf, "%A");
            fulls[offset] = (string) buf;
            
            date.add_days(1);
        }
        
        days_of_week = new DayOfWeek[COUNT];
        for (int ctr = MIN; ctr <= MAX; ctr++)
            days_of_week[ctr - MIN] = new DayOfWeek(ctr, abbrevs[ctr - MIN], fulls[ctr - MIN]);
        
        MON = days_of_week[0];
        TUE = days_of_week[1];
        WED = days_of_week[2];
        THU = days_of_week[3];
        FRI = days_of_week[4];
        SAT = days_of_week[5];
        SUN = days_of_week[6];
    }
    
    internal static void terminate() {
        days_of_week = null;
    }
    
    /**
     * Returns the day of the week for the specified one-based value.
     */
    public static DayOfWeek for(int value) throws CalendarError {
        int index = value - MIN;
        
        if (index < 0 || index >= days_of_week.length)
            throw new CalendarError.INVALID("Invalid day of week value %d", value);
        
        return days_of_week[index];
    }
    
    /**
     * Should only be used by internal calls when value is known to be safe and doesn't originate
     * from external sources, like a file, network, or user-input.
     */
    internal static DayOfWeek for_checked(int value) {
        try {
            return for(value);
        } catch (CalendarError calerr) {
            error("%s", calerr.message);
        }
    }
    
    internal static DayOfWeek from_gdate(GLib.Date date) {
        assert(date.valid());
        
        return for_checked(date.get_weekday());
    }
    
    public override string to_string() {
        return full_name;
    }
}

}

