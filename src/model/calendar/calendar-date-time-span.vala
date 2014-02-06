/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Calendar {

/**
 * An immutable representation of a span of time.
 *
 * This is conceptually similar to {@link DateSpan}, but (currently) doesn't allow for iteration.
 *
 * Note that there's no checking for matching TimeZones; in the future, these times may be
 * normalized to UTC.
 */

public class DateTimeSpan : BaseObject, Gee.Comparable<DateTimeSpan>, Gee.Hashable<DateTimeSpan> {
    /**
     * Starting DateTime of the span.
     *
     * start_date_time will always be earlier to or equal to {@link end_date_time}.
     */
    public DateTime start_date_time { get; private set; }
    
    /**
     * Ending DateTime of the span.
     *
     * end_date_time will always be later than or equal to {@link start_date_time}.
     */
    public DateTime end_date_time { get; private set; }
    
    /**
     * Starting {@link Calendar.Date} of the {@link DateTimeSpan}.
     *
     * @see end_date
     */
    public Date start_date { get; private set; }
    
    /**
     * Ending {@link Calendar.Date} of the {@link DateTimeSpan}.
     *
     * @see start_date
     */
    public Date end_date { get; private set; }
    
    public DateTimeSpan(DateTime start_date_time, DateTime end_date_time) {
        if (start_date_time.compare(end_date_time) <= 0) {
            this.start_date_time = start_date_time;
            this.end_date_time = end_date_time;
        } else {
            this.start_date_time = end_date_time;
            this.end_date_time = start_date_time;
        }
        
        start_date = new Date.from_date_time(start_date_time);
        end_date = new Date.from_date_time(end_date_time);
    }
    
    public DateTimeSpan.from_date_span(DateSpan span, TimeZone tz) {
        this (span.earliest_date_time(tz), span.latest_date_time(tz));
    }
    
    /**
     * Compares the {@link start_date_time} of two {@link DateTimeSpan}s.
     */
    public int compare_to(DateTimeSpan other) {
        return start_date_time.compare(other.start_date_time);
    }
    
    public bool equal_to(DateTimeSpan other) {
        if (this == other)
            return true;
        
        return start_date_time.equal(other.start_date_time) && end_date_time.equal(other.end_date_time);
    }
    
    public uint hash() {
        return start_date_time.hash() ^ end_date_time.hash();
    }
    
    public override string to_string() {
        return "%s::%s".printf(start_date_time.to_string(), end_date_time.to_string());
    }
}

}

