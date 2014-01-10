/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Calendar {

/**
 * An immutable 1-based representation of a day of a month.
 *
 * Since no month is associated with this object, acceptable values are from {@link MIN} to
 * {@link MAX}, 1 to 31.
 */

public class DayOfMonth : BaseObject {
    public const int MIN = 1;
    public const int MAX = 31;
    
    private static DayOfMonth?[] days = new DayOfMonth[MAX - MIN + 1];
    
    /**
     * Returns the 1-based value for this day of the month.
     */
    public int value { get; private set; }
    
    /**
     * Returns the day number as an informal (no leading zero) string.
     */
    public string informal_number { get; private set; }
    
    /**
     * Returns the day number as a formal (leading zero) string.
     */
    public string formal_number { get; private set; }
    
    private DayOfMonth(int value) throws CalendarError {
        if (value < MIN || value > MAX)
            throw new CalendarError.INVALID("Invalid day of month %d", value);
        
        this.value = value;
        informal_number = "%d".printf(value);
        formal_number = "%02d".printf(value);
    }
    
    /**
     * Returns a {@link DayOfMonth} for the supplied 1-based value.
     */
    public static DayOfMonth for(int value) throws CalendarError {
        int index = value - 1;
        
        if (index < 0 || index >= days.length)
            throw new CalendarError.INVALID("Invalid day of month (index) %d", value);
        
        if (days[index] == null)
            days[index] = new DayOfMonth(value);
        
        return days[index];
    }
    
    /**
     * Returns the first day of the month for any month.
     */
    public static DayOfMonth first() {
        try {
            return for(MIN);
        } catch (CalendarError calerr) {
            error("First of month unavailable: %s", calerr.message);
        }
    }
    
    public inline DateDay to_date_day() {
        return (DateDay) value;
    }
    
    public override string to_string() {
        return "%02d".printf(value);
    }
}

}

