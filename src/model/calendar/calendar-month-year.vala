/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Calendar {

/**
 * An immutable representation of a {@link Month} and a {@link Year}.
 */

public class MonthYear : BaseObject, Gee.Comparable<MonthYear>, Gee.Hashable<MonthYear> {
    /**
     * The {@link Month} of the associated {@link Year}.
     */
    public Month month { get; private set; }
    
    /**
     * The {@link Year}.
     */
    public Year year { get; private set; }
    
    public MonthYear(Month month, Year year) {
        this.month = month;
        this.year = year;
    }
    
    /**
     * Returns the current {@link MonthYear}.
     */
    public static MonthYear current(TimeZone tz = new TimeZone.local()) {
        return new MonthYear(Month.current(tz), Year.current(tz));
    }
    
    /**
     * Returns the number of days in the month for the specified year.
     */
    public int days_in_month() {
        return month.to_date_month().get_days_in_month(year.to_date_year());
    }
    
    /**
     * Returns the first {@link DayOfMonth} for the month in the associated year.
     */
    public DayOfMonth first_day_of_month() {
        return DayOfMonth.for_checked(1);
    }
    
    /**
     * Returns the last {@link DayOfMonth} for the month in the associated year.
     */
    public DayOfMonth last_day_of_month() {
        return DayOfMonth.for_checked(days_in_month());
    }
    
    /**
     * Returns the day of the week for the {@link DayOfMonth} for the month in the associated
     * year.
     */
    public Date date_for(DayOfMonth day_of_month) throws CalendarError {
        return new Date(day_of_month, month, year);
    }
    
    /**
     * Returns a {@link DateRange} representing the first to last day of the month for a given year.
     */
    public DateRange to_date_range() {
        try {
            Date start = new Date(DayOfMonth.first(), month, year);
            Date end = new Date(last_day_of_month(), month, year);
            
            return new DateRange(start, end);
        } catch (CalendarError calerr) {
            error("Unable to generate date range for %s %s: %s", to_string(), year.to_string(),
                calerr.message);
        }
    }
    
    public int compare_to(MonthYear other) {
        if (this == other)
            return 0;
        
        int cmp = year.compare_to(other.year);
        if (cmp != 0)
            return cmp;
        
        cmp = month.compare_to(other.month);
        if (cmp != 0)
            return cmp;
        
        return 0;
    }
    
    public bool equal_to(MonthYear other) {
        if (this == other)
            return true;
        
        return month.equal_to(other.month) && year.equal_to(other.year);
    }
    
    public uint hash() {
        // assuming month's hash is its value -- pretty good assumption -- give it 4 bits of space
        // for its value 1 - 12
        return (year.hash() << 4) | month.hash();
    }
    
    public override string to_string() {
        return "%s %s".printf(month.to_string(), year.to_string());
    }
}

}

