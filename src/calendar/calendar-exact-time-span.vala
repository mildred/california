/* Copyright 2014-2015 Yorba Foundation
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
        ALLOW_MULTILINE,
        /**
         * Include timezone information in the string.
         */
        INCLUDE_TIMEZONE
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
     * Same as {@link to_timezone} with {@link System.timezone} passed as the {@link Timezone}.
     */
    public ExactTimeSpan to_local() {
        return to_timezone(System.timezone);
    }
    
    /**
     * Returns true if the {@link ExactTime} is in this {@link ExactTimeSpan}.
     */
    public bool contains(ExactTime exact_time) {
        return start_exact_time.compare_to(exact_time) <= 0
            && end_exact_time.compare_to(exact_time) >= 0;
    }
    
    private static bool coincides_with_compare(Calendar.ExactTime start, Calendar.ExactTime end,
        Calendar.ExactTime exact_time) {
        return start.compare_to(exact_time) <= 0 && end.compare_to(exact_time) >= 0;
    }
    
    /**
     * Returns true if there's a union between the two {@link ExactTimeSpan}s.
     *
     * Note that a time span ending at the exact same time as the other starts (with one-second
     * accuracy) does ''not'' count as overlapping, i.e. the end times are exclusive.
     */
    public bool coincides_with(ExactTimeSpan other) {
        Calendar.ExactTime end_excl = end_exact_time.adjust_time(-1, TimeUnit.SECOND);
        Calendar.ExactTime other_end_excl = other.end_exact_time.adjust_time(-1, TimeUnit.SECOND);
        
        return coincides_with_compare(start_exact_time, end_excl, other.start_exact_time)
            || coincides_with_compare(start_exact_time, end_excl, other_end_excl)
            || coincides_with_compare(other.start_exact_time, other_end_excl, start_exact_time)
            || coincides_with_compare(other.start_exact_time, other_end_excl, end_excl);
    }
    
    /**
     * Returns an {@link ExactTimeSpan} expanded to include the supplied {@link ExactTime}.
     *
     * If the expanded_time is within this ExactTimeSpan, this object is returned.
     */
    public ExactTimeSpan expand(ExactTime expanded_time) {
        if (contains(expanded_time))
            return this;
        
        // if supplied time before start of span, that becomes the new start time
        if (expanded_time.compare_to(start_exact_time) < 0)
            return new ExactTimeSpan(expanded_time, end_exact_time);
        
        // prior tests guarantee supplied time is after end of this span
        assert(expanded_time.compare_to(end_exact_time) > 0);
        
        return new ExactTimeSpan(start_exact_time, expanded_time);
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
        bool include_timezone = (time_flags & PrettyFlag.INCLUDE_TIMEZONE) != 0;
        
        if (!start_date.year.equal_to(Calendar.System.today.year)
            || !end_date.year.equal_to(Calendar.System.today.year)) {
            date_flags |= Calendar.Date.PrettyFlag.INCLUDE_YEAR;
        }
        
        if (is_same_day) {
            string pretty_start_time = start_exact_time.to_pretty_time_string(Calendar.WallTime.PrettyFlag.NONE);
            string pretty_end_time = end_exact_time.to_pretty_time_string(Calendar.WallTime.PrettyFlag.NONE);
            
            string timespan;
            if (!include_timezone) {
                // A span of time, i.e. "3:30pm to 4:30pm"
                timespan = _("%s to %s").printf(pretty_start_time, pretty_end_time);
            } else if (start_exact_time.tzid == end_exact_time.tzid) {
                // A span of time followed by the timezone, i.e. "3:30pm to 4:30pm EST"
                timespan = _("%s to %s %s").printf(pretty_start_time, pretty_end_time,
                    start_exact_time.tzid);
            } else {
                // A span of time with each timezone's indicated, i.e.
                // "12:30AM EDT to 2:30PM EST"
                timespan = _("%s %s to %s %s").printf(pretty_start_time, start_exact_time.tzid,
                    pretty_end_time, end_exact_time.tzid);
            }
            
            // Single-day timed event, print "<full date>, <full start time> to <full end time>",
            // including year if not current year
            
            // Date and time, i.e. "September 13, 4:30pm"
            return _("%s, %s").printf(start_date.to_pretty_string(date_flags), timespan);
        }
        
        if (allow_multiline && !include_timezone) {
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
        } else if (allow_multiline && include_timezone) {
            // Multi-day timed event, print "<full time>, <full date>" on both lines,
            // including year if either not current year,
            // *and* including timezone
            // Prints two full time and date strings on separate lines, i.e.:
            // 12 January 2012, 3:30pm PST
            // 13 January 2013, 6:30am PST
            return _("%s, %s %s\n%s, %s %s").printf(
                start_exact_time.to_pretty_date_string(date_flags),
                start_exact_time.to_pretty_time_string(Calendar.WallTime.PrettyFlag.NONE),
                start_exact_time.tzid,
                end_exact_time.to_pretty_date_string(date_flags),
                end_exact_time.to_pretty_time_string(Calendar.WallTime.PrettyFlag.NONE),
                end_exact_time.tzid);
        }
        
        if (include_timezone) {
            // Prints full time and date strings on a single line with timezone, i.e.:
            // 12 January 2012, 3:30pm PST to 13 January 2013, 6:30am PST
            return _("%s, %s %s to %s, %s %s").printf(
                    start_exact_time.to_pretty_date_string(date_flags),
                    start_exact_time.to_pretty_time_string(Calendar.WallTime.PrettyFlag.NONE),
                    start_exact_time.tzid,
                    end_exact_time.to_pretty_date_string(date_flags),
                    end_exact_time.to_pretty_time_string(Calendar.WallTime.PrettyFlag.NONE),
                    end_exact_time.tzid);
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

