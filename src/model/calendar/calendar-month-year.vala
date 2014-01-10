/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Calendar {

/**
 * An immutable representation of a {@link Month} and a {@link Year}.
 */

public class MonthYear : BaseObject {
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
     * Returns the number of days in the month for the specified year.
     */
    public int days_in_month() {
        return month.to_date_month().get_days_in_month(year.to_date_year());
    }
    
    /**
     * Returns the last {@link DayOfMonth} for the specified year.
     */
    public DayOfMonth last_day_of_month() {
        try {
            return DayOfMonth.for(days_in_month());
        } catch (CalendarError calerr) {
            error("Invalid days in month %s: %s", to_string(), calerr.message);
        }
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
    
    public override string to_string() {
        return "%s %s".printf(month.to_string(), year.to_string());
    }
}

}

