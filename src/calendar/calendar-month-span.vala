/* Copyright 2014-2015 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Calendar {

/**
 * An immutable representation of a span of {@link MonthOfYear}s.
 */

public class MonthSpan : UnitSpan<MonthOfYear> {
    /**
     * Create a span of {@link MonthOfYear}s corresponding to the start and end months.
     */
    public MonthSpan(MonthOfYear first, MonthOfYear last) {
        base (first, last, first.start_date, last.end_date);
    }
    
    /**
     * Create a span of {@link MonthOfYear}s starting from the specified starting month.
     */
    public MonthSpan.count(MonthOfYear first, int count) {
        MonthOfYear last = first.adjust(count);
        
        base (first, last, first.start_date, last.end_date);
    }
    
    /**
     * Create a span of {@link MonthOfYear}s from the start and end of a {@link Span}.
     *
     * The month of the Span's start_date and the month of Span's end_date are used to determine
     * the MonthSpan.
     */
    public MonthSpan.from_span(Span span) {
        MonthOfYear first = span.start_date.month_of_year();
        MonthOfYear last = span.end_date.month_of_year();
        
        base (first, last, first.start_date, last.end_date);
    }
    
    /**
     * @inheritDoc
     */
    public override bool contains(MonthOfYear month) {
        return (first.compare_to(month) <= 0) && (last.compare_to(month) >= 0);
    }
    
    public override string to_string() {
        return "months of %s".printf(to_date_span().to_string());
    }
}

}
