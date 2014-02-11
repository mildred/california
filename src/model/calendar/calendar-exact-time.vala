/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Calendar {

/**
 * An immutable representation of an exact moment of time on a particular calendar day.
 *
 * This uses GLib's DateTime class but adds some extra logic useful to California.
 *
 * "Exact" is limited, of course, to the precision of DateTime, but it's close enough for our needs.
 */

public class ExactTime : BaseObject, Gee.Comparable<ExactTime>, Gee.Hashable<ExactTime> {
    public Year year { owned get { return new Year(date_time.get_year()); } }
    
    public Month month { owned get { return Month.for_checked(date_time.get_month()); } }
    
    public DayOfMonth day_of_month { owned get { return DayOfMonth.for_checked(date_time.get_day_of_month()); } }
    
    public int hour { get { return date_time.get_hour(); } }
    
    public int minute { get { return date_time.get_minute(); } }
    
    public int second { get { return date_time.get_second(); } }
    
    public bool is_dst { get { return date_time.is_daylight_savings(); } }
    
    private DateTime date_time;
    
    public ExactTime(TimeZone tz, Date date, WallTime time) {
        init(tz, date.year.value, date.month.value, date.day_of_month.value,
            time.hour, time.minute, time.second);
    }
    
    public ExactTime.full(TimeZone tz, int year, int month, int day, int hour, int minute,
        double second) {
        init(tz, year, month, day, hour, minute, second);
    }
    
    public ExactTime.now(TimeZone tz) {
        date_time = new DateTime.now(tz);
        if (date_time == null)
            error("DateTime.now failed");
    }
    
    public ExactTime.from_date_time(DateTime date_time) {
        this.date_time = date_time;
    }
    
    private void init(TimeZone tz, int year, int month, int day, int hour, int minute, double second) {
        date_time = new DateTime(tz, year, month, day, hour, minute, second);
        if (date_time == null) {
            error("Invalid specified DateTime: %02d/%02d/%d %02d:%02d:%02lf",
                day, month, year, hour, minute, second);
        }
    }
    
    /**
     * Returns a new {@link ExactTime} adjusted from this ExactTime by the specifed quantity of time.
     *
     * Subtraction (adjusting to a past time) is acheived by using a negative quantity.
     */
    public ExactTime adjust_time(int quantity, TimeUnit unit) {
        if (quantity == 0)
            return this;
        
        switch (unit) {
            case TimeUnit.HOUR:
                return new ExactTime.from_date_time(date_time.add_hours(quantity));
            
            case TimeUnit.MINUTE:
                return new ExactTime.from_date_time(date_time.add_minutes(quantity));
            
            case TimeUnit.SECOND:
                return new ExactTime.from_date_time(date_time.add_seconds(quantity));
            
            default:
                assert_not_reached();
        }
    }
    
    /**
     * Returns a new {@link ExactTime} adjusted from this ExactTime by the specifed quantity of time.
     *
     * Subtraction (adjusting to a past date) is acheived by using a negative quantity.
     */
    public ExactTime adjust_date(int quantity, DateUnit unit) {
        if (quantity == 0)
            return this;
        
        switch (unit) {
            case DateUnit.YEAR:
                return new ExactTime.from_date_time(date_time.add_years(quantity));
            
            case DateUnit.MONTH:
                return new ExactTime.from_date_time(date_time.add_months(quantity));
            
            case DateUnit.WEEK:
                return new ExactTime.from_date_time(date_time.add_weeks(quantity));
            
            case DateUnit.DAY:
                return new ExactTime.from_date_time(date_time.add_days(quantity));
            
            default:
                assert_not_reached();
        }
    }
    
    /**
     * See DateTime.to_unix_time.
     */
    public time_t to_time_t() {
        return (time_t) date_time.to_unix();
    }
    
    /**
     * See DateTime.to_timezone.
     */
    public ExactTime to_timezone(TimeZone tz) {
        return new ExactTime.from_date_time(date_time.to_timezone(tz));
    }
    
    /**
     * Returns prettified, localized user-visible date string of an {@link ExactTime}.
     */
    public string to_pretty_date_string(Date.PrettyFlag date_flags) {
        return new Date.from_exact_time(this).to_pretty_string(date_flags);
    }
    
    /**
     * Returns prettified, localized user-visible time string of an {@link ExactTime}.
     */
    public string to_pretty_time_string(WallTime.PrettyFlag time_flags) {
        return new WallTime.from_exact_time(this).to_pretty_string(time_flags);
    }
     
    
    public int compare_to(ExactTime other) {
        return date_time.compare(other.date_time);
    }
    
    public bool equal_to(ExactTime other) {
        return date_time.equal(other.date_time);
    }
    
    public uint hash() {
        return date_time.hash();
    }
    
    public override string to_string() {
        return date_time.to_string();
    }
}

}

