/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Calendar {

/**
 * An immutable representation of a {@link Month} of a {@link Year}.
 */

public class MonthOfYear : DateSpan, Gee.Comparable<MonthOfYear>, Gee.Hashable<MonthOfYear> {
    /**
     * The {@link Month} of the associated {@link Year}.
     */
    public Month month { get; private set; }
    
    /**
     * The {@link Year}.
     */
    public Year year { get; private set; }
    
    /**
     * The number of days in the month.
     */
    public int days_in_month { get; private set; }
    
    public MonthOfYear(Month month, Year year) {
        base.uninitialized();
        
        this.month = month;
        this.year = year;
        days_in_month = month.to_date_month().get_days_in_month(year.to_date_year());
        
        try {
            init_span(date_for(first_day_of_month()), date_for(last_day_of_month()));
        } catch (CalendarError calerr) {
            error("Unable to generate first/last days of month for %s: %s", to_string(), calerr.message);
        }
    }
    
    /**
     * Returns the {@link MonthYear} for the current time in the specified timezone.
     */
    public MonthOfYear.now(TimeZone tz = new TimeZone.local()) {
        this(Month.current(tz), new Year.now(tz));
    }
    
    /**
     * Returns the first {@link DayOfMonth} for the month in the associated year.
     */
    public DayOfMonth first_day_of_month() {
        return DayOfMonth.first();
    }
    
    /**
     * Returns the last {@link DayOfMonth} for the month in the associated year.
     */
    public DayOfMonth last_day_of_month() {
        return DayOfMonth.for_checked(days_in_month);
    }
    
    /**
     * Returns the day of the week for the {@link DayOfMonth} for the month in the associated
     * year.
     */
    public Date date_for(DayOfMonth day_of_month) throws CalendarError {
        return new Date(day_of_month, month, year);
    }
    
    /**
     * Returns a {@link MonthOfYear} adjusted a quantity of months from this one.
     *
     * Subtraction (adjusting to a past date) is acheived by using a negative quantity.
     */
    public MonthOfYear adjust(int quantity) {
        return start_date.adjust(quantity, Unit.MONTH).month_of_year();
    }
    
    public int compare_to(MonthOfYear other) {
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
    
    public bool equal_to(MonthOfYear other) {
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

