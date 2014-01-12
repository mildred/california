/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Calendar {

/**
 * An immutable representation of a calendar year.
 *
 * Because of limitations in GLib's Date representation, years before 1 are unsupported.  Maximum
 * value is described as thousands of years from now.
 */

public class Year : DateSpan, Gee.Comparable<Year>, Gee.Hashable<Year> {
    /**
     * The year as an integer.
     */
    public int value { get; private set; }
    
    public Year(int value) {
        base.uninitialized();
        
        assert(value >= 1);
        
        this.value = value;
        
        try {
            init_span(new Date(DayOfMonth.first(), Month.JAN, this),
                new Date(new MonthOfYear(Month.DEC, this).last_day_of_month(), Month.DEC, this));
        } catch (CalendarError calerr) {
            error("Unable to generate start/end dates of year %s: %s", to_string(), calerr.message);
        }
    }
    
    internal Year.from_gdate(GLib.Date gdate) {
        assert(gdate.valid());
        
        this(gdate.get_year());
    }
    
    /**
     * Create a {@link Year} for the current time in the specified timezone.
     */
    public static Year current(TimeZone tz = new TimeZone.local()) {
        DateTime now = new DateTime.now(tz);
        
        return new Year(now.get_year());
    }
    
    public int compare_to(Year other) {
        return value - other.value;
    }
    
    public bool equal_to(Year other) {
        return value == other.value;
    }
    
    public uint hash() {
        return value;
    }
    
    internal DateYear to_date_year() {
        return (DateYear) value;
    }
    
    public override string to_string() {
        return value.to_string();
    }
}

}

