/* Copyright 2014-2015 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Calendar {

/**
 * An immutable representation of a {@link Month} of a {@link Year}.
 */

public class MonthOfYear : Unit<MonthOfYear>, Gee.Comparable<MonthOfYear>, Gee.Hashable<MonthOfYear> {
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
    
    /**
     * Full name for user display.
     */
    public string full_name { get; private set; }
    
    /**
     * Abbreviated name for user display.
     */
    public string abbrev_name { get; private set; }
    
    public MonthOfYear(Month month, Year year) {
        base.uninitialized(DateUnit.MONTH);
        
        this.month = month;
        this.year = year;
        days_in_month = month.to_date_month().get_days_in_month(year.to_date_year());
        
        try {
            init_span(date_for(first_day_of_month()), date_for(last_day_of_month()));
        } catch (CalendarError calerr) {
            error("Unable to generate first/last days of month for %s: %s", to_string(), calerr.message);
        }
        
        full_name = start_date.format(FMT_MONTH_YEAR_FULL);
        abbrev_name = start_date.format(FMT_MONTH_YEAR_ABBREV);
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
     * @inheritDoc
     */
    public override MonthOfYear adjust(int quantity) {
        return start_date.adjust_by(quantity, DateUnit.MONTH).month_of_year();
    }
    
    /**
     * @inheritDoc
     */
    public override int difference(MonthOfYear other) {
        int compare = compare_to(other);
        if (compare == 0)
            return 0;
        
        // TODO: Iterating sucks, but it will have to suffice for now.
        int count = 0;
        MonthOfYear current = this;
        for (;;) {
            current = (compare > 0) ? current.previous() : current.next();
            count += (compare > 0) ? -1 : 1;
            
            if (current.equal_to(other))
                return count;
        }
    }
    
    public int compare_to(MonthOfYear other) {
        return (this != other) ? start_date.compare_to(other.start_date) : 0;
    }
    
    public bool equal_to(MonthOfYear other) {
        return compare_to(other) == 0;
    }
    
    public uint hash() {
        // 4 bits for month (1 - 12)
        return (year.value << 4) | month.value;
    }
    
    public override string to_string() {
        return "%s %s".printf(month.to_string(), year.to_string());
    }
}

}

