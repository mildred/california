/* Copyright 2014-2015 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Calendar {

/**
 * An immutable span or range of consecutive calendar {@link Date}s.
 *
 * Span is not currently designed for {@link ExactTime} resolution or to be used as the base
 * class of {@link ExactTimeSpan}.  It's possible this will change in the future.
 *
 * @see DiscreteUnit
 * @see UnitSpan
 */

public abstract class Span : BaseObject {
    public const string PROP_START_DATE = "start-date";
    public const string PROP_END_DATE = "end-date";
    public const string PROP_IS_SAME_DAY = "is-same-day";
    public const string PROP_DURATION = "duration";
    
    private class SpanIterator : BaseObject, Collection.SimpleIterator<Date> {
        private Date first;
        private Date last;
        private Date? current = null;
        
        public SpanIterator(Span span) {
            first = span.start_date;
            last = span.end_date;
        }
        
        public new Date get() {
            return current;
        }
        
        public bool next() {
            if (current == null)
                current = first;
            else if (current.compare_to(last) < 0)
                current = current.next();
            else
                return false;
            
            return true;
        }
        
        public override string to_string() {
            return "SpanIterator %s::%s".printf(first.to_string(), last.to_string());
        }
    }
    
    /**
     * Returns the earliest {@link Date} within the {@link Span}.
     */
    private Date? _start_date = null;
    public virtual Date start_date { get { return _start_date; } }
    
    /**
     * Returns the latest {@link Date} within the {@link Span}.
     */
    private Date? _end_date = null;
    public virtual Date end_date { get { return _end_date; } }
    
    /**
     * Convenience property indicating if the {@link Span} spans only one day.
     */
    public bool is_same_day { get { return start_date.equal_to(end_date); } }
    
    /**
     * Returns the {@link Duration} this {@link Span} represents.
     */
    public Duration duration { owned get { return new Duration(end_date.difference(start_date).abs() + 1); } }
    
    protected Span(Date start_date, Date end_date) {
        init_span(start_date, end_date);
    }
    
    /**
     * Create an unintialized {@link Span) on the presumption that {@link start_date} and
     * {@link end_date} are overridden or that the child class needs to do more work before
     * providing a date span.
     *
     * Because it's sometimes inconvenient to generate the necessary {@link Date}s until the
     * subclass's constructor completes, Span allows for itself to be created empty assuming
     * that the subclass will call {@link init_span} as soon as it's finished initializing.
     *
     * init_span() must be called.  Span will not function properly when uninitialized.
     */
    protected Span.uninitialized() {
    }
    
    /**
     * @see Span.uninitialized
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
     * Returns the earliest {@link ExactTime} for this {@link Span}.
     *
     * @see Date.earliest_exact_time
     */
    public ExactTime earliest_exact_time(Timezone tz) {
        return new ExactTime(tz, start_date, WallTime.earliest);
    }
    
    /**
     * Returns the latest {@link ExactTime} for this {@link Span}.
     *
     * @see Date.latest_exact_time
     */
    public ExactTime latest_exact_time(Timezone tz) {
        return new ExactTime(tz, end_date, WallTime.latest);
    }
    
    /**
     * Converts the {@link Span} into a {@link DateSpan}.
     */
    public DateSpan to_date_span() {
        return new DateSpan.from_span(this);
    }
    
    /**
     * Converts the {@link Span} into a {@link WeekSpan} using the supplied {@link FirstOfWeek}.
     *
     * Dates covering a partial week are included.
     */
    public WeekSpan to_week_span(FirstOfWeek first_of_week) {
        return new WeekSpan.from_span(this, first_of_week);
    }
    
    /**
     * Converts the {@link Span} into a {@link MonthSpan}.
     *
     * Dates covering a partial month are included.
     */
    public MonthSpan to_month_span() {
        return new MonthSpan.from_span(this);
    }
    
    /**
     * Converts the {@link Span} into a {@link YearSpan}.
     *
     * Dates coverting a partial year are included.
     */
    public YearSpan to_year_span() {
        return new YearSpan.from_span(this);
    }
    
    /**
     * Returns an {@link ExactTimeSpan} for this {@link Span}.
     */
    public ExactTimeSpan to_exact_time_span(Timezone tz) {
        return new ExactTimeSpan(earliest_exact_time(tz), latest_exact_time(tz));
    }
    
    /**
     * Returns a {@link DateSpan} with starting and ending points within the boundary specified
     * (inclusive).
     *
     * If this {@link Span} is within the clamped dates, this object may be returned.
     *
     * This method will not expand a DateSpan to meet the clamp range.
     */
    public DateSpan clamp_between(Span span) {
        Date new_start = (start_date.compare_to(span.start_date) < 0) ? span.start_date : start_date;
        Date new_end = (end_date.compare_to(span.end_date) > 0) ? span.end_date : end_date;
        
        return new DateSpan(new_start, new_end);
    }
    
    /**
     * Returns a {@link DateSpan} that covers the time of this {@link Span} and the supplied
     * {@link Date}.
     *
     * If the Date is within the existing Span, a DateSpan for this Span is returned, i.e. this
     * is just like calling {@link to_date_span}.
     */
    public DateSpan expand(Calendar.Date expansion) {
        Date new_start = (expansion.compare_to(start_date) < 0) ? expansion : start_date;
        Date new_end = (expansion.compare_to(end_date) > 0) ? expansion : end_date;
        
        return new DateSpan(new_start, new_end);
    }
    
    /**
     * Returns a {@link DateSpan} that represents this {@link Span} with the {@link start_date}
     * set to the supplied {@link Date}.
     *
     * If the new start_date is the same or later than the {@link end_date}, a one-day Span is
     * returned that matches the supplied Date.
     *
     * If the new start date is outside the range of this Span, a DateSpan for this Span is
     * returned, i.e. this is just like calling {@link to_date_span}.
     *
     * @see reduce_from_end
     */
    public DateSpan reduce_from_start(Calendar.Date new_start_date) {
        if (!has_date(new_start_date))
            return to_date_span();
        
        return new DateSpan(new_start_date, end_date);
    }
    
    /**
     * Returns a {@link DateSpan} that represents this {@link Span} with the {@link end_date}
     * set to the supplied {@link Date}.
     *
     * If the new end_date is the same or earlier than the {@link start_date}, a one-day Span is
     * returned that matches the supplied Date.
     *
     * If the new end date is outside the range of this Span, a DateSpan for this Span is
     * returned, i.e. this is just like calling {@link to_date_span}.
     *
     * @see reduce_from_start
     */
    public DateSpan reduce_from_end(Calendar.Date new_end_date) {
        if (!has_date(new_end_date))
            return to_date_span();
        
        return new DateSpan(start_date, new_end_date);
    }
    
    /**
     * True if the {@link Span} contains the specified {@link Date}.
     */
    public bool has_date(Date date) {
        int compare = start_date.compare_to(date);
        if (compare == 0)
            return true;
        else if (compare > 0)
            return false;
        
        return end_date.compare_to(date) >= 0;
    }
    
    /**
     * Returns a {@link Collection.SimpleIterator} of all the {@link Date}s in the
     * {@link Span}'s range of time.
     */
    public Collection.SimpleIterator<Date> date_iterator() {
        return new SpanIterator(this);
    }
}

}

