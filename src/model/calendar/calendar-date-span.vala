/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Calendar {

/**
 * Represents an immutable span of consecutive {@link Date}s.
 *
 * A DateSpan may be naturally iterated over its {@link Date}s.  It also provides iterators for
 * {@link Week}s.
 */

public class DateSpan : BaseObject, Util.SimpleIterable<Date>, Span<Date>, Gee.Comparable<DateSpan>,
    Gee.Hashable<DateSpan> {
    private class DateSpanIterator : BaseObject, Util.SimpleIterator<Date> {
        public Date first;
        public Date last;
        public Date? current = null;
        
        public DateSpanIterator(DateSpan owner) {
            first = owner.start_date;
            last = owner.end_date;
        }
        
        public new Date get() {
            return current;
        }
        
        public bool next() {
            if (current == null)
                current = first;
            else if (current.compare_to(last) < 0)
                current = current.adjust(1, DateUnit.DAY);
            else
                return false;
            
            return true;
        }
        
        public override string to_string() {
            return "DateSpanIterator %s::%s".printf(first.to_string(), last.to_string());
        }
    }
    
    /**
     * @inheritDoc
     */
    private Date _start_date;
    public Date start_date { owned get { return _start_date; } }
    
    /**
     * @inheritDoc
     */
    private Date _end_date;
    public Date end_date { owned get { return _end_date; } }
    
    /**
     * Convenience property indicating if the {@link DateSpan} spans only one day.
     */
    public bool is_same_day { get { return start_date.equal_to(end_date); } }
    
    /**
     * Create a {@link DateSpan} with the specified start and end dates.
     *
     * DateSpan will arrange the two dates so start_date is chronologically earlier (or the same
     * as) the end_date.
     */
    public DateSpan(Date start_date, Date end_date) {
        init_span(start_date, end_date);
    }
    
    /**
     * Create a {@link DateSpan} from the {@link ExactTimeSpan}.
     */
    public DateSpan.from_exact_time_span(ExactTimeSpan exact_time_span) {
        init_span(new Date.from_exact_time(exact_time_span.start_exact_time),
            new Date.from_exact_time(exact_time_span.end_exact_time));
    }
    
    /**
     * Create an unintialized {@link DateSpan).
     *
     * Because it's sometimes inconvenient to generate the necessary {@link Date}s until the
     * subclass's constructor completes, DateSpan allows for itself to be created empty assuming
     * that the subclass will call {@link init_span} as soon as it's finished initializing.
     *
     * init_span() must be called.  DateSpan will not function properly when uninitialized.
     */
    protected DateSpan.uninitialized() {
    }
    
    /**
     * Initialize the {@link DateSpan} with s start and end date.
     *
     * DateSpan will sort the start and end to ensure that start is chronologically prior
     * to end.
     */
    protected void init_span(Date start_date, Date end_date) {
        if (start_date.compare_to(end_date) <= 0) {
            _start_date = start_date;
            _end_date = end_date;
        } else {
            _start_date = end_date;
            _end_date = start_date;
        }
    }
    
    /**
     * @inheritDoc
     */
    public Date start() {
        return _start_date;
    }
    
    /**
     * @inheritDoc
     */
    public Date end() {
        return _end_date;
    }
    
    /**
     * @inheritDoc
     */
    public bool contains(Date date) {
        return (start_date.compare_to(date) <= 0) && (end_date.compare_to(date) >= 0);
    }
    
    /**
     * @inheritDoc
     */
    public bool has(Date date) {
        return contains(date);
    }
    
    /**
     * Returns an Iterator for all {@link Date}s in the {@link DateSpan}.
     */
    public Util.SimpleIterator<Date> iterator() {
        return new DateSpanIterator(this);
    }
    
    /**
     * Returns a {@link WeekSpan} for each {@link Week} (full and partial) in the {@link DateSpan}.
     */
    public WeekSpan weeks(FirstOfWeek first_of_week) {
        return new WeekSpan(this, first_of_week);
    }
    
    /**
     * Compares two {@link DateSpan}s by their {@link start_date}.
     */
    public int compare_to(DateSpan other) {
        return start_date.compare_to(other.start_date);
    }
    
    public bool equal_to(DateSpan other) {
        if (this == other)
            return true;
        
        return start_date.equal_to(other.start_date) && end_date.equal_to(other.end_date);
    }
    
    public uint hash() {
        return start_date.hash() ^ end_date.hash();
    }
    
    public override string to_string() {
        return "%s::%s".printf(start_date.to_string(), end_date.to_string());
    }
}

}
