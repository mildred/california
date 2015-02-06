/* Copyright 2014-2015 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Calendar {

/**
 * An immutable representation of a span of {@link Week}s.
 */

public class WeekSpan : UnitSpan<Week> {
    /**
     * The defined first day of the week for the weeks in the span.
     */
    public FirstOfWeek first_of_week { get; private set; }
    
    /**
     * Create a span of {@link Week}s from the start and end week.
     *
     * The start week's {@link FirstOfWeek} is used.  The end week is converted if it uses a
     * different first of week value.
     */
    public WeekSpan(Week first, Week last) {
        base (first, last, first.start_date, last.end_date.week_of(first.first_of_week).end_date);
        
        first_of_week = first.first_of_week;
    }
    
    /**
     * Create an arbitrary span of {@link Week}s starting from the specified {@link Week}.
     *
     * start's first-of-week is preserved.
     */
    public WeekSpan.count(Week first, int count) {
        Week last = first.adjust(count);
        
        base (first, last, first.start_date, last.end_date);
        
        first_of_week = first.first_of_week;
    }
    
    /**
     * Create a span of {@link Week}s corresponding to the {@link DateSpan} according to
     * {@link FirstOfWeek}'s definition of a week's starting day.
     */
    public WeekSpan.from_span(Span span, FirstOfWeek first_of_week) {
        Week first = span.start_date.week_of(first_of_week);
        Week last = span.end_date.week_of(first_of_week);
        
        base (first, last, first.start_date, last.end_date);
        
        this.first_of_week = first_of_week;
    }
    
    /**
     * @inheritDoc
     */
    public override bool contains(Week week) {
        return (first.compare_to(week) <= 0) && (last.compare_to(week) >= 0);
    }
    
    public override string to_string() {
        return "weeks of %s".printf(to_date_span().to_string());
    }
}

}
