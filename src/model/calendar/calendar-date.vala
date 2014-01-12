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
    }
    
    /**
     * Creates a {@link Date} for the DateTime.
     */
    public Date.date_time(DateTime date_time) {
        day_of_month = DayOfMonth.for_checked(date_time.get_day_of_month());
        month = Month.for_checked(date_time.get_month());
        year = new Year(date_time.get_year());
        
        gdate.set_dmy(day_of_month.to_date_day(), month.to_date_month(), year.to_date_year());
        assert(gdate.valid());
        
        day_of_week = DayOfWeek.from_gdate(gdate);
    }
    
    /**
     * Creates a {@link Date} that corresponds to the current time in the specified timezone.
     */
    public Date.now(TimeZone tz = new TimeZone.local()) {
        this.date_time(new DateTime.now(tz));
    }
    
    internal Date.from_gdate(GLib.Date gdate) {
        assert(gdate.valid());
        
        this.gdate = gdate;
        
        day_of_week = DayOfWeek.from_gdate(gdate);
        day_of_month = DayOfMonth.from_gdate(gdate);
        month = Month.from_gdate(gdate);
        year = new Year.from_gdate(gdate);
    }
    
    /**
     * Returns true if the {@link Date} corresponds with the current time.
     */
    public bool is_now(TimeZone tz = new TimeZone.local()) {
        return equal_to(new Date.now(tz));
    }
    
    /**
     * Returns the {@link Week} the {@link Date} falls in.
     */
    public Week week_of(FirstOfWeek first) {
        // calc how many days this Date is ahead of the first day of its week
        int ahead = day_of_week.ordinal(first) - first.as_day_of_week().ordinal(first);
        assert(ahead >= 0);
        
        Date start;
        if (ahead == 0) {
            start = this;
        } else {
            GLib.Date clone = gdate;
            clone.subtract_days(ahead);
            start = new Date.from_gdate(clone);
        }
        
        // add six days and that's the last day of the week
        Date end = start.adjust(DayOfWeek.COUNT - 1, Unit.DAY);
        
        // get the numeric week of the year of this date
        int week_of_year;
        switch (first) {
            case FirstOfWeek.MONDAY:
                week_of_year = (int) gdate.get_monday_week_of_year();
            break;
            
            case FirstOfWeek.SUNDAY:
                week_of_year = (int) gdate.get_sunday_week_of_year();
            break;
            
            default:
                assert_not_reached();
        }
        
        // get the numeric week of the month of this date (using weeks of the year to calculate)
        GLib.Date first_of_month = GLib.Date();
        first_of_month.set_dmy(1, month.to_date_month(), year.to_date_year());
        assert(first_of_month.valid());
        
        int week_of_month;
        switch (first) {
            case FirstOfWeek.MONDAY:
                week_of_month = week_of_year - ((int) first_of_month.get_monday_week_of_year()) + 1;
            break;
            
            case FirstOfWeek.SUNDAY:
                week_of_month = week_of_year - ((int) first_of_month.get_sunday_week_of_year()) + 1;
            break;
            
            default:
                assert_not_reached();
        }
        
        return new Week(start, end, week_of_month, week_of_year, month_of_year(), first);
    }
    
    /**
     * Returns the {@link MonthOfYear} the {@link Date} falls in.
     */
    public MonthOfYear month_of_year() {
        return new MonthOfYear(month, year);
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
                    clone.subtract_days(-quantity);
            break;
            
            case Unit.WEEK:
                if (quantity > 0)
                    clone.add_days(quantity * DayOfWeek.COUNT);
                else
                    clone.subtract_days((-quantity) * DayOfWeek.COUNT);
            break;
            
            case Unit.MONTH:
                if (quantity > 0)
                    clone.add_months(quantity);
                else
                    clone.subtract_months(-quantity);
            break;
            
            case Unit.YEAR:
                if (quantity > 0)
                    clone.add_years(quantity);
                else
                    clone.subtract_years(-quantity);
            break;
            
            default:
                assert_not_reached();
        }
        
        return new Date.from_gdate(clone);
    }
    
    /**
     * Returns a {@link Date} clamped between the two supplied Dates, inclusive.
     */
    public Date clamp(Date min, Date max) {
        GLib.Date clone = gdate;
        clone.clamp(min.gdate, max.gdate);
        
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

