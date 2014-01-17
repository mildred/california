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

public class DateSpan : BaseObject, Gee.Traversable<Date>, Gee.Iterable<Date> {
    private class DateSpanIterator : BaseObject, Gee.Traversable<Date>, Gee.Iterator<Date> {
        public bool read_only { get { return true; } }
        public bool valid { get { return current != null; } }
        
        public DateSpan owner;
        public Date first;
        public Date last;
        public Date? current = null;
        
        public DateSpanIterator(DateSpan owner) {
            this.owner = owner;
            first = owner.start_date;
            last = owner.end_date;
        }
        
        public new Date get() {
            return current;
        }
        
        public bool has_next() {
            return (current == null) ? true : current.compare_to(last) < 0;
        }
        
        public bool next() {
            if (current == null)
                current = first;
            else if (current.compare_to(last) < 0)
                current = current.adjust(1, Unit.DAY);
            else
                return false;
            
            return true;
        }
        
        public void remove() {
            error("DateSpanIterator is read-only");
        }
        
        public bool @foreach(Gee.ForallFunc<Date> fn) {
            if (current == null)
                current = first;
            
            while (current.compare_to(last) <= 0) {
                if (!fn(current))
                    return false;
                
                current = current.adjust(1, Unit.DAY);
            }
            
            return true;
        }
        
        public override string to_string() {
            return "DateSpanIterator %s::%s".printf(first.to_string(), last.to_string());
        }
    }
    
    /**
     * The first {@link Date} of the span.
     *
     * start_date will always be chronologically earlier or the same as end_date.
     */
    public Date start_date { get; private set; }
    
    /**
     * The last {@link Date} of the span.
     *
     * end_date will always be chronologically later or the same as start_date.
     */
    public Date end_date { get; private set; }
    
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
            this.start_date = start_date;
            this.end_date = end_date;
        } else {
            this.start_date = end_date;
            this.end_date = start_date;
        }
    }
    
    /**
     * Returns true if the {@link Date} is within the {@link DateSpan}.
     */
    public bool contains(Date date) {
        return (start_date.compare_to(date) <= 0) && (end_date.compare_to(date) >= 0);
    }
    
    /**
     * Returns an Iterator for all {@link Date}s in the {@link DateSpan}.
     */
    public Gee.Iterator<Date> iterator() {
        return new DateSpanIterator(this);
    }
    
    /**
     * Iterates over each {@link Date} in the {@link DateSpan}, invoking the function for each
     * one until it returns false or all Dates are exhausted.
     *
     * @returns The last return value of the function.
     */
    public bool @foreach(Gee.ForallFunc<Date> fn) {
        return iterator().foreach(fn);
    }
    
    /**
     * Returns a {@link WeekSpan} for each {@link Week} (full and partial) in the {@link DateSpan}.
     */
    public WeekSpan weeks(FirstOfWeek first_of_week) {
        return new WeekSpan(this, first_of_week);
    }
    
    /**
     * Returns the earliest DateTime for this {@link DateSpan}.
     *
     * @see Date.earliest_date_time
     */
    public DateTime earliest_date_time(TimeZone tz) {
        return start_date.earliest_date_time(tz);
    }
    
    /**
     * Returns the latest DateTime for this {@link DateSpan}.
     *
     * @see Date.latest_date_time
     */
    public DateTime latest_date_time(TimeZone tz) {
        return end_date.latest_date_time(tz);
    }
    
    public override string to_string() {
        return "%s::%s".printf(start_date.to_string(), end_date.to_string());
    }
}

}
