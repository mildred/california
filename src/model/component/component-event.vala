/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Component {

/**
 * A mutable representation of an iCalendar Event.
 *
 * See [[https://tools.ietf.org/html/rfc5545#section-3.6.1]]
 */

public class Event : Instance, Gee.Comparable<Event> {
    public const string PROP_SUMMARY = "summary";
    public const string PROP_DESCRIPTION = "description";
    public const string PROP_DATE_TIME_SPAN = "date-time-span";
    public const string PROP_DATE_SPAN = "date-span";
    
    /**
     * Summary (title) of {@link Event}.
     */
    public string? summary { get; private set; default = null; }
    
    /**
     * Description of {@link Event}.
     */
    public string? description { get; private set; default = null; }
    
    /**
     * {@link Calendar.ExactTimeSpan} of the {@link Event}'s dtstart and dtend.
     *
     * This is only non-null if the VEVENT specifies a DATE-TIME for both properties, otherwise
     * {@link date_span} will be specified.
     */
    public Calendar.ExactTimeSpan? exact_time_span { get; private set; default = null;}
    
    /**
     * {@link Calendar.DateSpan} of the {@link Event}'s dtstart and dtend.
     *
     * This is only non-null if the VEVENT defines a DATE for one or both properties.  Generally
     * this indicates an "all day" or multi-day event.
     */
    public Calendar.DateSpan? date_span { get; private set; default = null; }
    
    /**
     * Convenience property for determining if an all-day event or not.
     */
    public bool is_all_day { get { return exact_time_span == null; } }
    
    /**
     * Create an {@link Event} {@link Component} from an EDS CalComponent object.
     *
     * Throws a BackingError if the E.CalComponent's VTYPE is not VEVENT.
     */
    public Event(Backing.CalendarSource calendar_source, E.CalComponent eds_component) throws Error {
        base (calendar_source, eds_component, E.CalComponentVType.EVENT);
        
        // remainder of state is initialized in update()
    }
    
    /**
     * @inheritDoc
     */
    public override void update(E.CalComponent eds_component) throws Error {
        base.update(eds_component);
        
        E.CalComponentText text;
        eds_component.get_summary(out text);
        summary = text.value;
        
        // Events can hold at most one description
        unowned SList<E.CalComponentText?> text_list;
        eds_component.get_description_list(out text_list);
        if (text_list != null && text_list.data != null)
            description = text_list.data.value;
        E.CalComponent.free_text_list(text_list);
        
        E.CalComponentDateTime eds_dtstart = {};
        E.CalComponentDateTime eds_dtend = {};
        try {
            eds_component.get_dtstart(ref eds_dtstart);
            eds_component.get_dtend(ref eds_dtend);
            
            // convert start and end DATE/DATE-TIMEs to internal values ... note that VEVENT dtend
            // is non-inclusive (see https://tools.ietf.org/html/rfc5545#section-3.6.1)
            Calendar.DateSpan? date_span;
            Calendar.ExactTimeSpan? exact_time_span;
            Instance.DateFormat format = ical_to_span(false, eds_dtstart.value, eds_dtstart.tzid,
                eds_dtend.value, eds_dtend.tzid, out exact_time_span, out date_span);
            switch (format) {
                case DateFormat.DATE_TIME:
                    this.exact_time_span = exact_time_span;
                break;
                
                case DateFormat.DATE:
                    this.date_span = date_span;
                break;
                
                default:
                    assert_not_reached();
            }
        } finally {
            // TODO: Ok to free dt structs that haven't been filled-in?
            E.CalComponent.free_datetime(eds_dtstart);
            E.CalComponent.free_datetime(eds_dtend);
        }
    }
    
    /**
     * Returns a {@link Calendar.DateSpan} for the {@link Event}.
     *
     * This will return a DateSpan whether the Event is a DATE or DATE-TIME VEVENT.
     */
    public Calendar.DateSpan get_event_date_span() {
        return date_span ?? new Calendar.DateSpan.from_exact_time_span(exact_time_span);
    }
    
    /**
     * Compares an {@link Event} to another and returns which is chronologically first.
     *
     * The method attempts to compare DATE-TIMEs first, then DATEs, coercing a DATE-TIME into a DATE
     * if necessary.
     *
     * If both events have the same chronological time, they're sorted by summary in lexographical
     * order.
     *
     * {@link dtstamp} is the third comparison attempted.  In general, dtstamp is the time the
     * {@link Component} was created.
     *
     * Finally, UIDs are used to stabilize the sort.
     *
     * @inheritDoc
     */
    public int compare_to(Event other) {
        if (this == other)
            return 0;
        
        // starting time
        int compare;
        if (exact_time_span != null && other.exact_time_span != null)
            compare = exact_time_span.compare_to(other.exact_time_span);
        else if (date_span != null && other.date_span != null)
            compare = date_span.compare_to(other.date_span);
        else if (exact_time_span != null)
            compare = new Calendar.DateSpan.from_exact_time_span(exact_time_span).compare_to(other.date_span);
        else
            compare = date_span.compare_to(new Calendar.DateSpan.from_exact_time_span(other.exact_time_span));
        
        if (compare != 0)
            return compare;
        
        // summary
        compare = strcmp(summary, other.summary);
        if (compare != 0)
            return compare;
        
        // dtstamp
        compare = dtstamp.compare_to(other.dtstamp);
        if (compare != 0)
            return compare;
        
        // stabilize with UIDs
        return uid.compare_to(other.uid);
    }
    
    public override string to_string() {
        return "Event \"%s\" (%s)".printf(summary,
            exact_time_span != null ? exact_time_span.to_string() : date_span.to_string());
    }
}

}

