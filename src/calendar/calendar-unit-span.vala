/* Copyright 2014-2015 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Calendar {

/**
 * An arbitrary, immutable span of {@link Unit}s.
 *
 * @see DateSpan
 * @see MonthSpan
 * @see WeekSpan
 * @see YearSpan
 */

public abstract class UnitSpan<G> : Span, Collection.SimpleIterable<G>, Gee.Comparable<UnitSpan>,
    Gee.Hashable<UnitSpan> {
    public const string PROP_FIRST = "first";
    public const string PROP_LAST = "last";
    
    /**
     * This relies on the fact that Unit<G> is, in fact, G, i.e. Week is a
     * Unit<Week>.  This will blow-up if that's every not true.
     */
    private class UnitSpanIterator<G> : BaseObject, Collection.SimpleIterator<G> {
        public Unit<G> first;
        public Unit<G> last;
        public Unit<G>? current = null;
        
        public UnitSpanIterator(G first, G last) {
            this.first = (Unit<G>) first;
            this.last = (Unit<G>) last;
        }
        
        public new G get() {
            return (G) current;
        }
        
        public bool next() {
            if (current == null)
                current = first;
            else if (current.start_date.compare_to(last.start_date) < 0)
                current = (Unit<G>) current.adjust(1);
            else
                return false;
            
            return true;
        }
        
        public override string to_string() {
            return "UnitSpanIterator %s::%s".printf(first.to_string(), last.to_string());
        }
    }
    
    /**
     * The earliest delinated unit of time within the {@link UnitSpan}.
     */
    public G first { get; private set; }
    
    /**
     * The latest delineated unit of time within the {@link UnitSpan}.
     */
    public G last { get; private set; }
    
    protected UnitSpan(G first, G last, Date start_date, Date end_date) {
        base (start_date, end_date);
        
        this.first = first;
        this.last = last;
    }
    
    /**
     * True if the {@link UnitSpan} contains the specified unit of time.
     *
     * This is named to conform to Vala's rule for automatic syntax support.  This allows for the
     * ''in'' operator to function on UnitSpans.
     *
     * To determine if the UnitSpan contains a {@link Date}, convert it to a {@link DateSpan} with
     * {@link Span.to_date_span} and call its contains() method.
     */
    public abstract bool contains(G unit);
    
    /**
     * Returns a {@link Collection.SimpleIterator} of the {@link UnitSpan}'s unit of time.
     */
    public Collection.SimpleIterator<G> iterator() {
        return new UnitSpanIterator<G>(first, last);
    }
    
    /**
     * Compares two {@link UnitSpan}s by their {@link start_date}s.
     */
    public int compare_to(UnitSpan other) {
        return start_date.compare_to(other.start_date);
    }
    
    /**
     * Returns true if both {@link UnitSpan}s are equal.
     *
     * "Equal" is defined as having the same {@link start_date} and {@link end_date}.  That means
     * a {@link MonthSpan} and a {@link YearSpan} may be equal if the months span exactly the
     * same years.
     */
    public bool equal_to(UnitSpan other) {
        if (this == other)
            return true;
        
        return start_date.equal_to(other.start_date) && end_date.equal_to(other.end_date);
    }
    
    public uint hash() {
        return start_date.hash() ^ end_date.hash();
    }
}

}

