/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Calendar {

/**
 * An immutable representation of a span of {@link MonthOfYear}s.
 *
 * This class provides methods that can turn a {@link DateSpan} an iteration of MonthOfYear objects.
 * Partial months are included; the caller needs to do their own clamping if they want to avoid
 * days outside of the DateSpan.
 */

public class MonthSpan : BaseObject, Collection.SimpleIterable<MonthOfYear>, Span<MonthOfYear>,
    Gee.Comparable<MonthSpan>, Gee.Hashable<MonthSpan> {
    private class MonthSpanIterator : BaseObject, Collection.SimpleIterator<MonthOfYear> {
        public MonthOfYear first;
        public MonthOfYear last;
        public MonthOfYear? current = null;
        
        public MonthSpanIterator(MonthSpan owner) {
            first = owner.start();
            last = owner.end();
        }
        
        public new MonthOfYear get() {
            return current;
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
        
        public override string to_string() {
            return "MonthSpanIterator %s::%s".printf(first.to_string(), last.to_string());
        }
    }
    
    /**
     * The {@link DateSpan} of the {@link MonthOfYear}s.
     */
    public DateSpan dates { get; private set; }
    
    /**
     * inheritDoc
     */
    public Date start_date { owned get { return dates.start_date; } }
    
    /**
     * inheritDoc
     */
    public Date end_date { owned get { return dates.end_date; } }
    
    /**
     * Create a span of {@link MonthOfYear}s corresponding to the {@link DateSpan}.
     */
    public MonthSpan(DateSpan dates) {
        this.dates = dates;
    }
    
    /**
     * Create a span of {@link MonthOfYear}s corresponding to the start and end months.
     */
    public MonthSpan.from_months(MonthOfYear start, MonthOfYear end) {
        dates = new DateSpan(start.start_date, end.end_date);
    }
    
    /**
     * Create an arbitrary span of {@link MonthOfYear}s starting from the specified starting month.
     */
    public MonthSpan.count(MonthOfYear start, int count) {
        dates = new DateSpan(start.start_date, start.adjust(count).end_date);
    }
    
    /**
     * inheritDoc
     */
    public MonthOfYear start() {
        return dates.start_date.month_of_year();
    }
    
    /**
     * inheritDoc
     */
    public MonthOfYear end() {
        return dates.end_date.month_of_year();
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
    public bool has(MonthOfYear month) {
        return (start().compare_to(month) <= 0) && (end().compare_to(month) >= 0);
    }
    
    /**
     * Returns an Iterator for each {@link MonthOfYear} (full and partial) in the {@link MonthSpan}.
     */
    public Collection.SimpleIterator<MonthOfYear> iterator() {
        return new MonthSpanIterator(this);
    }
    
    /**
     * Compares two {@link MonthSpan}s by their {@link start_date}.
     */
    public int compare_to(MonthSpan other) {
        return start_date.compare_to(other.start_date);
    }
    
    public bool equal_to(MonthSpan other) {
        if (this == other)
            return true;
        
        return start_date.equal_to(other.start_date) && end_date.equal_to(other.end_date);
    }
    
    public uint hash() {
        return start_date.hash() ^ end_date.hash();
    }
    
    public override string to_string() {
        return "months of %s".printf(dates.to_string());
    }
}

}
