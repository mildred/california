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
     * Pretty-printing flags for {@link to_pretty_string}.
     */
    [Flags]
    public enum PrettyFlag {
        NONE = 0,
        /**
         * Use multiple lines to format string if lengthy.
         */
        ALLOW_MULTILINE
    }
    
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
    
    public ExactTimeSpan.from_span(Span span, Timezone tz) {
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
     * Returns true if the {@link ExactTime} is in this {@link ExactTimeSpan}.
     */
    public bool contains(ExactTime exact_time) {
        return start_exact_time.compare_to(exact_time) <= 0
            && end_exact_time.compare_to(exact_time) >= 0;
    }
    
    /**
     * Returns a prettified string describing the {@link Event}'s time span in as concise and
     * economical manner possible.
     *
     * The supplied {@link Date} pretty flags are applied to the two Date strings.  If either of
     * the {@link DateSpan} crosses a year boundary, the INCLUDE_YEAR flag is automatically added.
     */
    public string to_pretty_string(Calendar.Date.PrettyFlag date_flags, PrettyFlag time_flags) {
        bool allow_multiline = (time_flags & PrettyFlag.ALLOW_MULTILINE) != 0;
        
        if (!start_date.year.equal_to(Calendar.System.today.year)
            || !end_date.year.equal_to(Calendar.System.today.year)) {
            date_flags |= Calendar.Date.PrettyFlag.INCLUDE_YEAR;
        }
        
        if (is_same_day) {
            // A span of time, i.e. "3:30pm to 4:30pm"
            string timespan = _("%s to %s").printf(
                start_exact_time.to_pretty_time_string(Calendar.WallTime.PrettyFlag.NONE),
                end_exact_time.to_pretty_time_string(Calendar.WallTime.PrettyFlag.NONE));
            
            // Single-day timed event, print "<full date>, <full start time> to <full end time>",
            // including year if not current year
            return "%s, %s".printf(start_date.to_pretty_string(date_flags), timespan);
        }
        
        if (allow_multiline) {
            // Multi-day timed event, print "<full time>, <full date>" on both lines,
            // including year if either not current year
            // Prints two full time and date strings on separate lines, i.e.:
            // 12 January 2012, 3:30pm
            // 13 January 2013, 6:30am
            return _("%s, %s\n%s, %s").printf(
                start_exact_time.to_pretty_date_string(date_flags),
                start_exact_time.to_pretty_time_string(Calendar.WallTime.PrettyFlag.NONE),
                end_exact_time.to_pretty_date_string(date_flags),
                end_exact_time.to_pretty_time_string(Calendar.WallTime.PrettyFlag.NONE));
        }
        
        // Prints full time and date strings on a single line, i.e.:
        // 12 January 2012, 3:30pm to 13 January 2013, 6:30am
        return _("%s, %s to %s, %s").printf(
                start_exact_time.to_pretty_date_string(date_flags),
                start_exact_time.to_pretty_time_string(Calendar.WallTime.PrettyFlag.NONE),
                end_exact_time.to_pretty_date_string(date_flags),
                end_exact_time.to_pretty_time_string(Calendar.WallTime.PrettyFlag.NONE));
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

