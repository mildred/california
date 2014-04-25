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
    public const string PROP_EXACT_TIME_SPAN = "exact-time-span";
    public const string PROP_DATE_SPAN = "date-span";
    public const string PROP_IS_ALL_DAY = "is-all-day";
    public const string PROP_LOCATION = "location";
    public const string PROP_STATUS = "status";
    
    public enum Status {
        TENTATIVE,
        CONFIRMED,
        CANCELLED
    }
    
    /**
     * Summary (title) of {@link Event}.
     */
    public string? summary { get; set; default = null; }
    
    /**
     * Description of {@link Event}.
     */
    public string? description { get; set; default = null; }
    
    /**
     * {@link Calendar.ExactTimeSpan} of the {@link Event}'s dtstart and dtend.
     *
     * This is only non-null if the VEVENT specifies a DATE-TIME for both properties, otherwise
     * {@link date_span} will be specified.
     *
     * @see set_exact_time_span
     */
    public Calendar.ExactTimeSpan? exact_time_span { get; private set; default = null;}
    
    /**
     * {@link Calendar.DateSpan} of the {@link Event}'s dtstart and dtend.
     *
     * This is only non-null if the VEVENT defines a DATE for one or both properties.  Generally
     * this indicates an "all day" or multi-day event.
     *
     * @see set_date_span
     */
    public Calendar.DateSpan? date_span { get; private set; default = null; }
    
    /**
     * Convenience property for determining if an all-day event or not.
     */
    public bool is_all_day { get; private set; }
    
    /**
     * Location of an {@link Event}.
     */
    public string? location { get; set; default = null; }
    
    /**
     * Status (confirmation) of an {@link Event}.
     */
    public Status status { get; set; default = Status.CONFIRMED; }
    
    /**
     * Create an {@link Event} {@link Component} from an EDS CalComponent object.
     *
     * Throws a BackingError if the E.CalComponent's VTYPE is not VEVENT.
     */
    public Event(Backing.CalendarSource? calendar_source, iCal.icalcomponent ical_component) throws Error {
        base (calendar_source, ical_component, iCal.icalcomponent_kind.VEVENT_COMPONENT);
        
        // remainder of state is initialized in update_from_component()
        
        // watch for changes to mutable properties, update ical_component when they change
        notify.connect(on_notify);
    }
    
    /**
     * Creates a "blank" {@link Event} with a generated {@link uid}.
     *
     * A {@link Calendar.DateSpan} or a {@link Calendar.ExactTimeSpan} must be specified in order
     * to generate a minimally-valid Event.
     */
    public Event.blank() {
        base.blank(iCal.icalcomponent_kind.VEVENT_COMPONENT);
        
        notify.connect(on_notify);
    }
    
    /**
     * @inheritDoc
     */
    protected override void update_from_component(iCal.icalcomponent ical_component) throws Error {
        base.update_from_component(ical_component);
        
        summary = ical_component.get_summary();
        description = ical_component.get_description();
        
        DateTime dt_start = new DateTime(ical_component, iCal.icalproperty_kind.DTSTART_PROPERTY);
        DateTime dt_end = new DateTime(ical_component, iCal.icalproperty_kind.DTEND_PROPERTY);
        // convert start and end DATE/DATE-TIMEs to internal values ... note that VEVENT dtend
        // is non-inclusive (see https://tools.ietf.org/html/rfc5545#section-3.6.1)
        Calendar.DateSpan? date_span;
        Calendar.ExactTimeSpan? exact_time_span;
        DateTime.to_span(dt_start, dt_end, false, out date_span, out exact_time_span);
        if (exact_time_span != null) {
            set_event_exact_time_span(exact_time_span);
        } else {
            assert(date_span != null);
            set_event_date_span(date_span);
        }
        
        // need to set this here because on_notify() doesn't update inside full update
        is_all_day = (date_span != null);
        
        location = ical_component.get_location();
        
        switch (ical_component.get_status()) {
            case iCal.icalproperty_status.TENTATIVE:
                status = Status.TENTATIVE;
            break;
            
            case iCal.icalproperty_status.CANCELLED:
                status = Status.CANCELLED;
            break;
            
            case iCal.icalproperty_status.CONFIRMED:
            default:
                status = Status.CONFIRMED;
            break;
        }
    }
    
    private void on_notify(ParamSpec pspec) {
        // ignore if inside a full update
        if (in_full_update)
            return;
        
        bool altered = true;
        switch (pspec.name) {
            case PROP_SUMMARY:
                ical_component.set_summary(summary);
            break;
            
            case PROP_DESCRIPTION:
                ical_component.set_description(description);
            break;
            
            case PROP_EXACT_TIME_SPAN:
            case PROP_DATE_SPAN:
                // set_exact_time_span() and set_date_span() guarantee that only one of the other
                // will be set, but the change isn't atomic and it's possible that both will be
                // set or unset
                if ((date_span == null && exact_time_span == null)
                    || (date_span != null && exact_time_span != null)) {
                    return;
                }
                
                // DTEND is non-inclusive for VEVENTs, see
                // https://tools.ietf.org/html/rfc5545#section-3.6.1
                iCal.icaltimetype ical_dtstart = {};
                iCal.icaltimetype ical_dtend = {};
                if (exact_time_span != null)
                    exact_time_span_to_ical(exact_time_span, &ical_dtstart, &ical_dtend);
                else
                    date_span_to_ical(date_span, false, &ical_dtstart, &ical_dtend);
                
                ical_component.set_dtstart(ical_dtstart);
                ical_component.set_dtend(ical_dtend);
                
                // updating here guarantees it's always accurate
                is_all_day = (date_span != null);
            break;
            
            case PROP_LOCATION:
                ical_component.set_location(location);
            break;
            
            case PROP_STATUS:
                switch(status) {
                    case Status.TENTATIVE:
                        ical_component.set_status(iCal.icalproperty_status.TENTATIVE);
                    break;
                    
                    case Status.CANCELLED:
                        ical_component.set_status(iCal.icalproperty_status.CANCELLED);
                    break;
                    
                    case Status.CONFIRMED:
                    default:
                        ical_component.set_status(iCal.icalproperty_status.CONFIRMED);
                    break;
                }
            break;
            
            default:
                altered = false;
            break;
        }
        
        if (altered)
            notify_altered(false);
    }
    
    /**
     * Returns a {@link Calendar.DateSpan} for the {@link Event}.
     *
     * This will return a DateSpan whether the Event is a DATE or DATE-TIME VEVENT.
     */
    public Calendar.DateSpan get_event_date_span(Calendar.Timezone? tz) {
        if (date_span != null)
            return date_span;
        
        return new Calendar.DateSpan.from_exact_time_span(
            tz != null ? exact_time_span.to_timezone(tz) : exact_time_span);
    }
    
    /**
     * Sets the {@link Event} as a DATE VEVENT.
     *
     * {@link date_span} will be set and {@link exact_time_span} will be unset.
     *
     * @see set_event_exact_time_span
     */
    public void set_event_date_span(Calendar.DateSpan date_span) {
        this.date_span = date_span;
        exact_time_span = null;
    }
    
    /**
     * Sets the {@link Event} as a DATE-TIME VEVENT.
     *
     * {@link exact_time_span} will be set and {@link date_span} will be unset.
     *
     * @see set_event_date_span
     */
    public void set_event_exact_time_span(Calendar.ExactTimeSpan exact_time_span) {
        this.exact_time_span = exact_time_span;
        date_span = null;
    }
    
    /**
     * @inheritDoc
     */
    public override bool is_valid() {
        return base.is_valid() && (date_span != null || exact_time_span != null);
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
        
        // sort all-day events before timed events
        if (is_all_day && !other.is_all_day)
            return -1;
        
        if (!is_all_day && other.is_all_day)
            return 1;
        
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
        
        // if recurring, go by sequence number, as the UID and RID are the same for all instances
        if (is_recurring) {
            compare = sequence - other.sequence;
            if (compare != 0)
                return compare;
        }
        
        // stabilize with UIDs
        return uid.compare_to(other.uid);
    }
    
    public override bool equal_to(Component.Instance other) {
        Component.Event? other_event = other as Component.Event;
        if (other_event == null)
            return false;
        
        if (this == other_event)
            return true;
        
        if (is_recurring != other_event.is_recurring)
            return false;
        
        if (is_recurring && !rid.equal_to(other_event.rid))
            return false;
        
        if (sequence != other_event.sequence)
            return false;
        
        if (exact_time_span != null && other_event.exact_time_span != null
            && !exact_time_span.equal_to(other_event.exact_time_span)) {
            return false;
        }
        
        if (date_span != null && other_event.date_span != null
            && !date_span.equal_to(other_event.date_span)) {
            return false;
        }
        
        if (exact_time_span != null
            && other_event.date_span != null
            && !new Calendar.DateSpan.from_exact_time_span(exact_time_span).equal_to(other_event.date_span)) {
            return false;
        }
        
        if (date_span != null
            && other_event.exact_time_span != null
            && !date_span.equal_to(new Calendar.DateSpan.from_exact_time_span(other_event.exact_time_span))) {
            return false;
        }
        
        return base.equal_to(other);
    }
    
    public override uint hash() {
        return uid.hash() ^ ((rid != null) ? rid.hash() : 0) ^ sequence;
    }
    
    public override string to_string() {
        return "Event %s/rid=%s/%d \"%s\" (%s)".printf(
            uid.to_string(),
            (rid != null) ? rid.to_string() : "(no-recurring)",
            sequence,
            summary,
            exact_time_span != null ? exact_time_span.to_string() : date_span.to_string());
    }
}

}

