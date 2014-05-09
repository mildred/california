/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Calendar {

/**
 * Represents an immutable arbitrary span of consecutive {@link Date}s.
 *
 * Although DateSpan is technically a {@link UnitSpan} of Dates, it's such a fundamental way of
 * representing any unit of dates that {@link Span} offers a conversion method.  Thus, a
 * {@link Week} is a {@link DiscreteUnit} but it can easily be converted into a {@link DateSpan}.
 * The only reason Week does not inherit from DateSpan -- indeed, all units of calendar time don't
 * inherit from DateSpan -- is to avoid inheritance problems and circularities.  (Another way to
 * look at things is that Span is a lightweight DateSpan.)
 */

public class DateSpan : UnitSpan<Date> {
    /**
     * Create a {@link DateSpan} with the specified start and end dates.
     */
    public DateSpan(Date start_date, Date end_date) {
        base (start_date, end_date, start_date, end_date);
    }
    
    /**
     * Create a {@link DateSpan} from a {@link Span}.
     */
    public DateSpan.from_span(Span span) {
        base (span.start_date, span.end_date, span.start_date, span.end_date);
    }
    
    /**
     * Create a {@link DateSpan} from the {@link ExactTimeSpan}.
     */
    public DateSpan.from_exact_time_span(ExactTimeSpan exact_time_span) {
        Date start_date = new Date.from_exact_time(exact_time_span.start_exact_time);
        Date end_date = new Date.from_exact_time(exact_time_span.end_exact_time);
        
        base(start_date, end_date, start_date, end_date);
    }
    
    /**
     * Adjusts the start of the {@link DateSpan} preserving the span duration.
     *
     * Since DateSpan always guarantees the {@link start_date} will be before the {@link end_date},
     * it's sometimes desirable to manipulate the start_date and preserve the duration between its
     * original value and the end_date.
     *
     * @see adjust_end_date
     */
    public DateSpan adjust_start_date(Calendar.Date new_start_date) {
        int diff = start_date.difference(end_date);
        
        return new DateSpan(new_start_date, new_start_date.adjust(diff));
    }
    
    /**
     * Adjusts the end of the {@link DateSpan} preserving the span duration.
     *
     * Since DateSpan always guarantees the {@link start_date} will be before the {@link end_date},
     * it's sometimes desirable to manipulate the end_date and preserve the duration between its
     * original value and the start_date.
     *
     * @see adjust_start_date
     */
    public DateSpan adjust_end_date(Calendar.Date new_end_date) {
        int diff = end_date.difference(start_date);
        
        return new DateSpan(new_end_date.adjust(diff), new_end_date);
    }
    
    /**
     * @inheritDoc
     */
    public override bool contains(Date date) {
        return has_date(date);
    }
    
    public override string to_string() {
        return "%s::%s".printf(start_date.to_string(), end_date.to_string());
    }
}

}
