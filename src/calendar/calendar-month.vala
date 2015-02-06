/* Copyright 2014-2015 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Calendar {

/**
 * An immutable one-based representation of a month of year.
 */

public class Month : BaseObject, Gee.Comparable<Month>, Gee.Hashable<Month> {
    public static Month JAN;
    public static Month FEB;
    public static Month MAR;
    public static Month APR;
    public static Month MAY;
    public static Month JUN;
    public static Month JUL;
    public static Month AUG;
    public static Month SEP;
    public static Month OCT;
    public static Month NOV;
    public static Month DEC;
    
    private static Gee.Map<string, Month> parse_map;
    
    public const int MIN = 1;
    public const int MAX = 12;
    public const int COUNT = MAX - MIN + 1;
    
    private static Month[]? months = null;
    
    /**
     * The one-based integer value of this month.
     */
    public int value { get; private set; }
    
    /**
     * A locale-specific abbreviated name for the month.
     */
    public string abbrev_name { get; private set; }
    
    /**
     * A local-specific full name for the month.
     */
    public string full_name { get; private set; }
    
    /**
     * The month number as an informal (no leading zero) string.
     */
    public string informal_number { get; private set; }
    
    /**
     * The month number as a formal (leading zero) string.
     */
    public string formal_number { get; private set; }
    
    private Month(int value) {
        assert(value >= MIN && value <= MAX);
        
        this.value = value;
        
        // GLib's Date.strftime requires a fully-formed struct to get strings, so fake it
        // and stash
        GLib.Date date = GLib.Date();
        date.clear();
        date.set_dmy(1, to_date_month(), 2014);
        
        char[] buf = new char[64];
        date.strftime(buf, FMT_MONTH_ABBREV);
        abbrev_name = (string) buf;
        
        date.strftime(buf, FMT_MONTH_FULL);
        full_name = (string) buf;
        
        informal_number = "%d".printf(value);
        formal_number = "%02d".printf(value);
    }
    
    internal static void init() {
        parse_map = new Gee.HashMap<string, Month>(String.ci_hash, String.ci_equal);
        
        months = new Month[COUNT];
        for (int ctr = MIN; ctr <= MAX; ctr++) {
            Month month = new Month(ctr);
            months[ctr - MIN] = month;
            
            // build parse map of abbreviated and full name to the Month
            parse_map.set(month.abbrev_name, month);
            parse_map.set(month.full_name, month);
        }
        
        JAN = months[0];
        FEB = months[1];
        MAR = months[2];
        APR = months[3];
        MAY = months[4];
        JUN = months[5];
        JUL = months[6];
        AUG = months[7];
        SEP = months[8];
        OCT = months[9];
        NOV = months[10];
        DEC = months[11];
    }
    
    internal static void terminate() {
        parse_map = null;
        months = null;
        JAN = FEB = MAR = APR = MAY = JUN = JUL = AUG = SEP = OCT = NOV = DEC = null;
    }
    
    /**
     * Returns a {@link Month} for the specified 1-based month.
     */
    public static Month for(int value) throws CalendarError {
        int index = value - MIN;
        
        if (index < 0 || index >= months.length)
            throw new CalendarError.INVALID("Invalid month of year value %d", value);
        
        return months[index];
    }
    
    /**
     * For situations where the month value had better be correct (i.e. not from an external source,
     * such as a network response, file, or user input).
     */
    internal static Month for_checked(int value) {
        try {
            return for(value);
        } catch (CalendarError calerr) {
            error("Unable to fetch Month for value %d: %s", value, calerr.message);
        }
    }
    
    internal static Month from_gdate(GLib.Date gdate) {
        assert(gdate.valid());
        
        return for_checked(gdate.get_month());
    }
    
    /**
     * Compares the supplied string with all translated {@link Month} names, both {@link abbrev_name}
     * and {@link full_name}.
     *
     * parse() is case-insensitive.
     */
    public static Month? parse(string str) {
        return parse_map.get(str);
    }
    
    internal inline DateMonth to_date_month() {
        return (DateMonth) value;
    }
    
    public int compare_to(Month other) {
        return value - other.value;
    }
    
    public bool equal_to(Month other) {
        return this == other;
    }
    
    public uint hash() {
        return value;
    }
    
    public override string to_string() {
        return abbrev_name;
    }
}

}

