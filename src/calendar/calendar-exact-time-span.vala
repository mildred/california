/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Calendar {

/**
 * An immutable representation of a span of calendar time.
 *
 * This is conceptually similar to {@link DateSpan}, but (currently) doesn't allow for iteration.
 *
 * Note that there's no checking for matching Timezones; in the future, these times may be
 * normalized to UTC.
 */

public class ExactTimeSpan : BaseObject, Gee.Comparable<ExactTimeSpan>, Gee.Hashable<ExactTimeSpan> {
    /**
     * Starting {@link ExactTime} of the span.
     *
     * start_exact_time will always be earlier to or equal to {@link end_exact_time}.
     */
    public ExactTime start_exact_time { get; private set; }
    
    /**
     * Ending {@link ExactTime} of the span.
     *
     * end_exact_time will always be later than or equal to {@link start_exact_time}.
     */
    public ExactTime end_exact_time { get; private set; }
    
    /**
     * Starting {@link Calendar.Date} of the {@link ExactTimeSpan}.
     *
     * @see end_date
     */
    public Date start_date { get; private set; }
    
    /**
     * Ending {@link Calendar.Date} of the {@link ExactTimeSpan}.
     *
     * @see start_date
     */
    public Date end_date { get; private set; }
    
    /**
     * The {@link Duration} of the {@link ExactTimeSpan}.
     */
    public Duration duration { owned get { return new Duration(0, 0, 0, end_exact_time.difference(start_exact_time)); } }
    
    /**
     * Convenience property indicating if the {@link ExactTimeSpan} falls on a single calendar day
     */
    public bool is_same_day { get { return start_date.equal_to(end_date); } }
    
    public ExactTimeSpan(ExactTime start_exact_time, ExactTime end_exact_time) {
        if (start_exact_time.compare_to(end_exact_time) <= 0) {
            this.start_exact_time = start_exact_time;
            this.end_exact_time = end_exact_time;
        } else {
            this.start_exact_time = end_exact_time;
            this.end_exact_time = start_exact_time;
        }
        
        start_date = new Date.from_exact_time(start_exact_time);
        end_date = new Date.from_exact_time(end_exact_time);
    }
    
    public ExactTimeSpan.from_date_span(DateSpan span, Timezone tz) {
        this (span.earliest_exact_time(tz), span.latest_exact_time(tz));
    }
    
    /**
     * Returns the {@link DateSpan} of this exact time span.
     */
    public Calendar.DateSpan get_date_span() {
        return new Calendar.DateSpan(start_date, end_date);
    }
    
    /**
     * Returns a new {@link ExactTimeSpan} with both {@link start_date_time} and
     * {@link end_date_time} converted to the supplied {@link Timezone}.
     */
    public ExactTimeSpan to_timezone(Timezone new_tz) {
        return new ExactTimeSpan(start_exact_time.to_timezone(new_tz),
            end_exact_time.to_timezone(new_tz));
    }
    
    /**
     * Compares the {@link start_exact_time} of two {@link ExactTimeSpan}s.
     */
    public int compare_to(ExactTimeSpan other) {
        return start_exact_time.compare_to(other.start_exact_time);
    }
    
    public bool equal_to(ExactTimeSpan other) {
        if (this == other)
            return true;
        
        return start_exact_time.equal_to(other.start_exact_time)
            && end_exact_time.equal_to(other.end_exact_time);
    }
    
    public uint hash() {
        return start_exact_time.hash() ^ end_exact_time.hash();
    }
    
    public override string to_string() {
        return "%s::%s".printf(start_exact_time.to_string(), end_exact_time.to_string());
    }
}

}

