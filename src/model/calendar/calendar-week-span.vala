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

public class WeekSpan : BaseObject, Gee.Traversable<Week>, Gee.Iterable<Week> {
    private class WeekSpanIterator : BaseObject, Gee.Traversable<Week>, Gee.Iterator<Week> {
        public bool read_only { get { return true; } }
        public bool valid { get { return current != null; } }
        
        public DateSpan owner;
        public Week first;
        public Week last;
        public Week? current = null;
        
        public WeekSpanIterator(DateSpan owner, FirstOfWeek first_of_week) {
            this.owner = owner;
            first = owner.start_date.week_of(first_of_week);
            last = owner.end_date.week_of(first_of_week);
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
     * Create a span of {@link Week}s corresponding to the {@link DateSpan} according to
     * {@link FirstOfWeek}'s definition of a week's starting day.
     */
    public WeekSpan(DateSpan dates, FirstOfWeek first_of_week) {
        this.dates = dates;
        this.first_of_week = first_of_week;
    }
    
    /**
     * Returns an Iterator for each {@link Week} (full and partial) in the {@link WeekSpan}.
     */
    public Gee.Iterator<Week> iterator() {
        return new WeekSpanIterator(dates, first_of_week);
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
