/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Calendar {

/**
 * An immutable 1-based representation of a month of year.
 *
 * This is a more functional object than the {@link Month} enum, which is provided for naming (code)
 * convenience.
 */

public class Month : BaseObject {
    public const int JAN = 1;
    public const int FEB = 2;
    public const int MAR = 3;
    public const int APR = 4;
    public const int MAY = 5;
    public const int JUN = 6;
    public const int JUL = 7;
    public const int AUG = 8;
    public const int SEP = 9;
    public const int OCT = 10;
    public const int NOV = 11;
    public const int DEC = 12;
    
    public const int MIN = JAN;
    public const int MAX = DEC;
    
    private static Month?[] months = new Month[MAX - MIN + 1];
    
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
    
    private Month(int value) throws CalendarError {
        this.value = value;
        
        // GLib's Date.strftime requires a fullly-formed struct to get strings, so fake it
        // and stash
        GLib.Date date = GLib.Date();
        date.set_day((DateDay) 1);
        date.set_month(to_date_month());
        date.set_year((DateYear) 2014);
        
        char[] buf = new char[64];
        date.strftime(buf, "%b");
        abbrev_name = (string) buf;
        
        buf = new char[64];
        date.strftime(buf, "%B");
        full_name = (string) buf;
        
        informal_number = "%d".printf(value);
        formal_number = "%02d".printf(value);
    }
    
    /**
     * Returns a {@link Month} for the specified 1-based month.
     */
    public static Month for(int value) throws CalendarError {
        int index = value - 1;
        
        if (index < 0 || index >= months.length)
            throw new CalendarError.INVALID("Invalid month of year (index) %d", value);
        
        if (months[index] == null)
            months[index] = new Month(value);
        
        return months[index];
    }
    
    public inline DateMonth to_date_month() {
        return (DateMonth) value;
    }
    
    public override string to_string() {
        return abbrev_name;
    }
}

}

