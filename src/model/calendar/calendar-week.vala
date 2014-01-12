/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Calendar {

/**
 * An immutable representation of a calendar week, meaning the {@link start_date} is the first
 * day of the week (as defined by {@link FirstOfWeek} and the {@link end_date) is six days after
 * that.
 *
 * As a {@link DateSpan}, it's possible for the start and end date to "bleed" into other months and
 * years.
 *
 * Due to the rigid definition of a Week, they cannot be created off-the-cuff.  Use
 * {@link Date.week_of} to obtain a Week for a particular calendar day.
 */

public class Week : DateSpan, Gee.Hashable<Week> {
    /**
     * The one-based week of the month (1 to 5).
     */
    public int week_of_month { get; private set; }
    
    /**
     * The one-based week of the year (1 to 52).
     */
    public int week_of_year { get; private set; }
    
    /**
     * The {@link Month} of the {@link Year} the week falls in.
     *
     * It's possible days within this week fall outside this Month or even this Year.  This Month
     * and Year is what {@link week_of_the_month} and {@link week_of_the_year} refer to.
     */
    public MonthOfYear month_of_year { get; private set; }
    
    /**
     * How this object defines the first day of the week.
     */
    public FirstOfWeek first_of_week { get; private set; }
    
    /**
     * Important: Week does not validate that start and end are in fact the start and end of the
     * calendar week.
     */
    internal Week(Date start, Date end, int week_of_month, int week_of_year, MonthOfYear month_of_year,
        FirstOfWeek first_of_week) {
        base (start, end);
        
        this.week_of_month = week_of_month;
        this.week_of_year = week_of_year;
        this.month_of_year = month_of_year;
        this.first_of_week = first_of_week;
    }
    
    /**
     * Returns a {@link Week} adjusted a quantity of weeks from this one.
     *
     * The first day of the week is preserved in the new Week.
     *
     * Subtraction (adjusting to a past date) is acheived by using a negative quantity.
     */
    public Week adjust(int quantity) {
        return start_date.adjust(quantity, Unit.WEEK).week_of(first_of_week);
    }
    
    public bool equal_to(Week other) {
        if (this == other)
            return true;
        
        return (week_of_year == other.week_of_year) && month_of_year.equal_to(other.month_of_year);
    }
    
    public uint hash() {
        // give 6 bits for the week of the year (1 - 52)
        return (month_of_year.year.value << 6) | week_of_year;
    }
    
    public override string to_string() {
        return "week %d of %s (%s)".printf(week_of_year, month_of_year.to_string(), base.to_string());
    }
}

}

