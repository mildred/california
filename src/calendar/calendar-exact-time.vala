/* Copyright 2014-2015 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Calendar {

/**
 * An immutable representation of an exact moment of time on a particular calendar day.
 *
 * This uses GLib's DateTime class but adds some extra logic useful to California, including
 * storing the {@link Timezone} used to generate the DateTime and making this object work well with
 * Gee.
 *
 * "Exact" is limited, of course, to the precision of DateTime, but it's close enough for our needs.
 */

public class ExactTime : BaseObject, Gee.Comparable<ExactTime>, Gee.Hashable<ExactTime> {
    public Year year { owned get { return new Year(date_time.get_year()); } }
    public Month month { owned get { return Month.for_checked(date_time.get_month()); } }
    public DayOfMonth day_of_month { owned get { return DayOfMonth.for_checked(date_time.get_day_of_month()); } }
    
    /**
     * Zero-based hour of day.
     */
    public int hour { get { return date_time.get_hour(); } }
    
    /**
     * Zero-based minute of {@link hour}.
     */
    public int minute { get { return date_time.get_minute(); } }
    
    /**
     * Zero-based second of the [@link minute}.
     */
    public int second { get { return date_time.get_second(); } }
    
    /**
     * True if daylight savings is in effect at this moment of time.
     */
    public bool is_dst { get { return date_time.is_daylight_savings(); } }
    
    /**
     * The {@link Timezone} used to generate this moment of time.
     *
     * @see to_timezone
     */
    public Timezone tz { get; private set; }
    
    /**
     * A human-oriented string representing the current time's time zone as an abbreviation.
     *
     * This value should ''not'' be used to generate an {@link OlsonZone}.
     *
     * @see tz
     */
    public unowned string tzid { get { return date_time.get_timezone_abbreviation(); } }
    
    /**
     * The offset (in seconds) from UTC.
     */
    public int32 utc_offset { get { return (int32) (date_time.get_utc_offset() / 1000000L); } }
    
    private DateTime date_time;
    
    public ExactTime(Timezone tz, Date date, WallTime time) {
        try {
            init(tz, date.year.value, date.month.value, date.day_of_month.value,
                time.hour, time.minute, time.second);
        } catch (CalendarError calerr) {
            // this uses checked objects, so shouldn't happen
            error("%s", calerr.message);
        }
    }
    
    public ExactTime.full(Timezone tz, int year, int month, int day, int hour, int minute,
        double second) throws CalendarError {
        init(tz, year, month, day, hour, minute, second);
    }
    
    public ExactTime.now(Timezone tz) {
        date_time = new DateTime.now(tz.time_zone);
        if (date_time == null)
            error("DateTime.now failed");
        this.tz = tz;
    }
    
    public ExactTime.from_date_time(DateTime date_time, Timezone tz) {
        this.date_time = date_time;
        this.tz = tz;
    }
    
    private void init(Timezone tz, int year, int month, int day, int hour, int minute, double second)
        throws CalendarError {
        date_time = new DateTime(tz.time_zone, year, month, day, hour, minute, second);
        if (date_time == null) {
            throw new CalendarError.INVALID("Invalid specified DateTime: %02d/%02d/%d %02d:%02d:%02lf",
                day, month, year, hour, minute, second);
        }
        this.tz = tz;
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
                return new ExactTime.from_date_time(date_time.add_hours(quantity), tz);
            
            case TimeUnit.MINUTE:
                return new ExactTime.from_date_time(date_time.add_minutes(quantity), tz);
            
            case TimeUnit.SECOND:
                return new ExactTime.from_date_time(date_time.add_seconds(quantity), tz);
            
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
                return new ExactTime.from_date_time(date_time.add_years(quantity), tz);
            
            case DateUnit.MONTH:
                return new ExactTime.from_date_time(date_time.add_months(quantity), tz);
            
            case DateUnit.WEEK:
                return new ExactTime.from_date_time(date_time.add_weeks(quantity), tz);
            
            case DateUnit.DAY:
                return new ExactTime.from_date_time(date_time.add_days(quantity), tz);
            
            default:
                assert_not_reached();
        }
    }
    
    /**
     * Returns the difference (in seconds) between this {@link ExactTime} and another ExactTime.
     *
     * If the supplied ExactTime is earlier than this one, a negative value will be returned.
     */
    public int64 difference(ExactTime other) {
        return date_time.difference(other.date_time) / TimeSpan.SECOND;
    }
    
    /**
     * Clamp the {@link ExactTime} between a supplied floor and ceiling ExactTime.
     *
     * If null is passed for either value, it will be ignored (effectively making clamp() work like
     * a floor() or ceiling() method).  If null is passed for both, the current ExactTime is
     * returned.
     *
     * Results are indeterminate if a floor chronologically later than a ceiling is passed in.
     */
    public ExactTime clamp(ExactTime? floor, ExactTime? ceiling) {
        ExactTime clamped = this;
        
        if (floor != null && clamped.compare_to(floor) < 0)
            clamped = floor;
        
        if (ceiling != null && clamped.compare_to(ceiling) > 0)
            clamped = ceiling;
        
        return clamped;
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
    public ExactTime to_timezone(Timezone new_tz) {
        return new ExactTime.from_date_time(date_time.to_timezone(new_tz.time_zone), new_tz);
    }
    
    /**
     * Same as {@link to_timezone} with {@link System.timezone} passed as the {@link Timezone}.
     */
    public ExactTime to_local() {
        return to_timezone(System.timezone);
    }
    
    /**
     * Returns the {@link WallTime} for the {@link ExactTime}.
     */
    public WallTime to_wall_time() {
        return new WallTime(hour, minute, second);
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
        return to_wall_time().to_pretty_string(time_flags);
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
    
    /**
     * See DateTime.format() for specifiers.
     */
    public string format(string fmt) {
        return date_time.format(fmt);
    }
    
    public override string to_string() {
        return "%s/%s".printf(date_time.to_string(), tz.to_string());
    }
}

}

