/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Calendar {

/**
 * An immutable representation of a single date in time (year/month/day).
 *
 * This is primarily a GObject-ification of GLib's Date struct, with the added restriction that
 * this class is immutable.  This means this object is incapable of representing a DMY prior to
 * Year 1 (BCE).
 *
 * GLib.Date has many powerful features for representing a calenday day, but it's interface is
 * inconvenient when working in Vala.  It can also exist in an uninitialized and an invalid
 * state.  It's desired to avoid both of those.  It is also not an Object, has no signals or
 * properties, doesn't work well with Gee, and is mutable.  This class attempts to solve these
 * issues.
 */

public class Date : BaseObject, Gee.Comparable<Date>, Gee.Hashable<Date> {
    public DayOfWeek day_of_week { get; private set; }
    public DayOfMonth day_of_month { get; private set; }
    public Month month { get; private set; }
    public Year year { get; private set; }
    
    /**
     * One-based week of the month this date falls on if weeks start with Monday.
     *
     * Zero if the date is before the first Monday of the year.
     */
    public int week_of_the_month_monday { get; private set; }
    /**
     * One-based week of the month this date falls on if weeks start with Sunday.
     *
     * Zero if the date is before the first Sunday of the year.
     */
    public int week_of_the_month_sunday { get; private set; }
    /**
     * One-based week of the year this date falls on if weeks start with Monday.
     *
     * Zero if the date is before the first Monday of the year.
     */
    public int week_of_the_year_monday { get; private set; }
    /**
     * One-based week of the year this date falls on if weeks start with Sunday.
     *
     * Zero if the date is before the first Sunday of the year.
     */
    public int week_of_the_year_sunday { get; private set; }
    
    private GLib.Date gdate;
    
    /**
     * Creates a new {@link Date} object for the day, month, and year.
     *
     * @throws CalendarError if an invalid calendar day
     */
    public Date(DayOfMonth day_of_month, Month month, Year year) throws CalendarError {
        gdate.set_dmy(day_of_month.to_date_day(), month.to_date_month(), year.to_date_year());
        if (!gdate.valid()) {
            throw new CalendarError.INVALID("Invalid day/month/year %s/%s/%s", day_of_month.to_string(),
                month.to_string(), year.to_string());
        }
        
        day_of_week = DayOfWeek.from_gdate(gdate);
        this.day_of_month = day_of_month;
        this.month = month;
        this.year = year;
        
        init();
    }
    
    internal Date.from_gdate(GLib.Date gdate) {
        assert(gdate.valid());
        
        this.gdate = gdate;
        
        day_of_week = DayOfWeek.from_gdate(gdate);
        day_of_month = DayOfMonth.from_gdate(gdate);
        month = Month.from_gdate(gdate);
        year = new Year.from_gdate(gdate);
        
        init();
    }
    
    private void init() {
        assert(gdate.valid());
        
        week_of_the_year_monday = (int) gdate.get_monday_week_of_year();
        week_of_the_year_sunday = (int) gdate.get_sunday_week_of_year();
        
        GLib.Date first = GLib.Date();
        first.set_dmy(1, month.to_date_month(), year.to_date_year());
        assert(first.valid());
        
        week_of_the_month_monday = week_of_the_year_monday - ((int) first.get_monday_week_of_year()) + 1;
        assert(week_of_the_month_monday > 0);
        week_of_the_month_sunday = week_of_the_year_sunday - ((int) first.get_sunday_week_of_year()) + 1;
        assert(week_of_the_month_sunday > 0);
    }
    
    public bool within_month_year(MonthOfYear month_year) {
        return month.equal_to(month_year.month) && year.equal_to(month_year.year);
    }
    
    /**
     * Returns a new {@link Date} adjusted from this Date by the specifed quantity of time.
     *
     * Subtraction (adjusting to a past date) is acheived by using a negative quantity.
     */
    public Date adjust(int quantity, Unit unit) {
        if (quantity == 0)
            return this;
        
        GLib.Date clone = gdate;
        switch (unit) {
            case Unit.DAY:
                if (quantity > 0)
                    clone.add_days(quantity);
                else
                    clone.subtract_days(quantity);
            break;
            
            case Unit.WEEK:
                if (quantity > 0)
                    clone.add_days(quantity * DayOfWeek.COUNT);
                else
                    clone.subtract_days(quantity * DayOfWeek.COUNT);
            break;
            
            case Unit.MONTH:
                if (quantity > 0)
                    clone.add_months(quantity);
                else
                    clone.subtract_months(quantity);
            break;
            
            case Unit.YEAR:
                if (quantity > 0)
                    clone.add_years(quantity);
                else
                    clone.subtract_years(quantity);
            break;
            
            default:
                assert_not_reached();
        }
        
        return new Date.from_gdate(clone);
    }
    
    public int compare_to(Date other) {
        return (this != other) ? gdate.compare(other.gdate) : 0;
    }
    
    public bool equal_to(Date other) {
        return compare_to(other) == 0;
    }
    
    public uint hash() {
        return gdate.get_julian();
    }
    
    public string format(string fmt) {
        // TODO: This isn't a guaranteed way to allocate space, but without parsing fmt (and
        // accounting for locale-specific string lengths), I'm not sure of a better way
        char[] buf = new char[256];
        gdate.strftime(buf, fmt);
        
        return (string) buf;
    }
    
    public override string to_string() {
        return format("%x");
    }
}

}

