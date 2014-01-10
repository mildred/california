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
 */

public class Date : BaseObject, Gee.Comparable<Date> {
    public DayOfMonth day { get; private set; }
    public Month month { get; private set; }
    public Year year { get; private set; }
    
    private GLib.Date date;
    
    public Date(DayOfMonth day, Month month, Year year) throws CalendarError {
        this.day = day;
        this.month = month;
        this.year = year;
        
        date.set_day(day.to_date_day());
        date.set_month(month.to_date_month());
        date.set_year(year.to_date_year());
        if (!date.valid()) {
            throw new CalendarError.INVALID("Invalid day/month/year %s/%s/%s", day.to_string(),
                month.to_string(), year.to_string());
        }
    }
    
    public int compare_to(Date other) {
        return (this != other) ? date.compare(other.date) : 0;
    }
    
    public override string to_string() {
        return "%s-%s-%s".printf(year.to_string(), month.to_string(), day.to_string());
    }
}

}

