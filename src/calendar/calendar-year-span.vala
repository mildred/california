/* Copyright 2014-2015 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Calendar {

/**
 * An immutable representation of a span of {@link Year}s.
 */

public class YearSpan : UnitSpan<Year> {
    /**
     * Create a span of {@link Year}s corresponding to the start and end years.
     */
    public YearSpan(Year first, Year last) {
        base (first, last, first.start_date, last.end_date);
    }
    
    /**
     * Create a span of {@link Years}s starting from the specified starting month.
     */
    public YearSpan.count(Year first, int count) {
        Year last = first.adjust(count);
        
        base (first, last, first.start_date, last.end_date);
    }
    
    /**
     * Create a span of {@link Year}s from the start and end of a {@link Span}.
     *
     * The year of the Span's start_date and the month of Span's end_date are used to determine
     * the YearSpan.
     */
    public YearSpan.from_span(Span span) {
        Year first = span.start_date.year;
        Year last = span.end_date.year;
        
        base (first, last, first.start_date, last.end_date);
    }
    
    /**
     * @inheritDoc
     */
    public override bool contains(Year year) {
        return (first.compare_to(year) <= 0) && (last.compare_to(year) >= 0);
    }
    
    public override string to_string() {
        return "months of %s".printf(to_date_span().to_string());
    }
}

}

