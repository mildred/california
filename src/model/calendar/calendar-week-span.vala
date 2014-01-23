/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Calendar {

/**
 * An immutable representation of a span of {@link Week}s.
 *
 * This class provides methods that can turn a {@link DateSpan} an iteration of Week objects.
 * Partial weeks are included; the caller needs to do their own clamping if they want to avoid
 * days outside of the DateSpan.
 */

public class WeekSpan : BaseObject, Gee.Traversable<Week>, Gee.Iterable<Week>, Span<Week> {
    private class WeekSpanIterator : BaseObject, Gee.Traversable<Week>, Gee.Iterator<Week> {
        public bool read_only { get { return true; } }
        public bool valid { get { return current != null; } }
        
        public WeekSpan owner;
        public Week first;
        public Week last;
        public Week? current = null;
        
        public WeekSpanIterator(WeekSpan owner) {
            this.owner = owner;
            first = owner.start();
            last = owner.end();
        }
        
        public new Week get() {
            return current;
        }
        
        public bool has_next() {
            return (current == null) ? true : current.start_date.compare_to(last.start_date) < 0;
        }
        
        public bool next() {
            if (current == null)
                current = first;
            else if (current.start_date.compare_to(last.start_date) < 0)
                current = current.adjust(1);
            else
                return false;
            
            return true;
        }
        
        public void remove() {
            error("WeekSpanIterator is read-only");
        }
        
        public bool @foreach(Gee.ForallFunc<Week> fn) {
            if (current == null)
                current = first;
            
            while (current.start_date.compare_to(last.start_date) <= 0) {
                if (!fn(current))
                    return false;
                
                current = current.adjust(1);
            }
            
            return true;
        }
        
        public override string to_string() {
            return "WeekSpanIterator %s::%s".printf(first.to_string(), last.to_string());
        }
    }
    
    /**
     * The {@link DateSpan} of thw {@link Week}s.
     */
    public DateSpan dates { get; private set; }
    
    /**
     * The defined first day of the week.
     */
    public FirstOfWeek first_of_week { get; private set; }
    
    /**
     * inheritDoc
     */
    public Date start_date { owned get { return dates.start_date; } }
    
    /**
     * inheritDoc
     */
    public Date end_date { owned get { return dates.end_date; } }
    
    /**
     * Create a span of {@link Week}s corresponding to the {@link DateSpan} according to
     * {@link FirstOfWeek}'s definition of a week's starting day.
     */
    public WeekSpan(DateSpan dates, FirstOfWeek first_of_week) {
        this.dates = dates;
        this.first_of_week = first_of_week;
    }
    
    /**
     * Create an arbitrary span of {@link Week}s starting from the specified {@link Week}.
     *
     * Week's first-of-week is preserved.
     */
    public WeekSpan.count(Week start, int count) {
        dates = new DateSpan(start.start_date, start.adjust(count).end_date);
        first_of_week = start.first_of_week;
    }
    
    /**
     * inheritDoc
     */
    public Week start() {
        return dates.start_date.week_of(first_of_week);
    }
    
    /**
     * inheritDoc
     */
    public Week end() {
        return dates.end_date.week_of(first_of_week);
    }
    
    /**
     * @inheritDoc
     */
    public bool contains(Date date) {
        return dates.contains(date);
    }
    
    /**
     * @inheritDoc
     */
    public bool has(Week week) {
        return (start().compare_to(week) <= 0) && (end().compare_to(week) >= 0);
    }
    
    /**
     * Returns an Iterator for each {@link Week} (full and partial) in the {@link WeekSpan}.
     */
    public Gee.Iterator<Week> iterator() {
        return new WeekSpanIterator(this);
    }
    
    /**
     * Iterates over every {@link Week} in the {@link WeekSpan}, invoking the function for each
     * until it returns false or the weeks are exhausted.
     *
     * @returns The last return value of fn.
     */
    public bool @foreach(Gee.ForallFunc<Week> fn) {
        return iterator().foreach(fn);
    }
    
    public override string to_string() {
        return "weeks of %s".printf(dates.to_string());
    }
}

}
