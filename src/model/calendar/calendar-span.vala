/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Calendar {

/**
 * An immutable generic span or range of consecutive calendar dates.
 *
 * The Span is delineated by specific lengths of time (such as {@link Date}, {@link Week}, or
 * {@link Month} and is required to be Traversable and Iterable by the same.
 *
 * Since the start and end Date of a Span may fall within the larger delineated unit of time,
 * the contract is that partial units will always be returned.  If the caller wants to only deal
 * with full units within this Span, they must check all returned values.
 *
 * Although not specified, it's expected that all Spans will also implement Gee.Comparable and
 * Gee.Hashable.
 *
 * Span is not designed for DateTime resolution.
 *
 * @see DateSpan
 * @see WeekSpan
 * @see MonthSpan
 */

public interface Span<G> : Object, Gee.Traversable<G>, Gee.Iterable<G> {
    /**
     * Returns the earliest {@link Date} within the {@link Span}.
     */
    public abstract Date start_date { owned get; }
    
    /**
     * Returns the latest {@link Date} within the {@link Span}.
     */
    public abstract Date end_date { owned get; }
    
    /**
     * The earliest delinated unit of time within the {@link Span}.
     */
    public abstract G start();
    
    /**
     * The latest delineated unit of time within the {@link Span}.
     */
    public abstract G end();
    
    /**
     * Returns the earliest DateTime for this {@link Span}.
     *
     * @see Date.earliest_date_time
     */
    public DateTime earliest_date_time(TimeZone tz) {
        return start_date.earliest_date_time(tz);
    }
    
    /**
     * Returns the latest DateTime for this {@link Span}.
     *
     * @see Date.latest_date_time
     */
    public DateTime latest_date_time(TimeZone tz) {
        return end_date.latest_date_time(tz);
    }
    
    /**
     * true if the {@link Span} contains the specified {@link Date}.
     *
     * This is named to conform to Vala's rule for automatic syntax support.  This allows for the
     * ''in'' operator to function on Spans, but only for Dates (which is perceived as a common
     * operation).
     *
     * @see has
     */
    public abstract bool contains(Date date);
    
    /**
     * true if the {@link Span} contains the specified unit of time.
     *
     * @see contains
     */
    public abstract bool has(G unit);
}

}

