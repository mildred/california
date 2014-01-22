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

public class Event : Instance {
    /**
     * Summary (title) of {@link Event}.
     */
    public string? summary { get; private set; default = null; }
    
    /**
     * Description of {@link Event}.
     */
    public string? description { get; private set; default = null; }
    
    /**
     * {@link Calendar.DateTimeSpan} of the {@link Event}'s dtstart and dtend.
     *
     * This is only non-null if the VEVENT specifies a DATE-TIME for both properties, otherwise
     * {@link date_span} will be specified.
     */
    public Calendar.DateTimeSpan? date_time_span { get; private set; default = null;}
    
    /**
     * {@link Calendate.DateSpan} of the {@link Event}'s dtstart and dtend.
     *
     * This is only non-null if the VEVENT defines a DATE for one or both properties.  Generally
     * this indicates an "all day" or multi-day event.
     */
    public Calendar.DateSpan? date_span { get; private set; default = null; }
    
    /**
     * Create an {@link Event} {@link Component} from an EDS CalComponent object.
     */
    public Event(E.CalComponent eds_component) throws CalendarError {
        base (eds_component);
        
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
            Calendar.DateTimeSpan? date_time_span;
            switch (ical_to_span(false, eds_dtstart.value, eds_dtend.value, out date_time_span, out date_span)) {
                case DateFormat.DATE_TIME:
                    this.date_time_span = date_time_span;
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
        return date_span ?? new Calendar.DateSpan.from_date_time_span(date_time_span);
    }
    
    public override string to_string() {
        return "Event %s %s".printf(summary,
            date_time_span != null ? date_time_span.to_string() : date_span.to_string());
    }
}

}

