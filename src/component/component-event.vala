/* Copyright 2014-2015 Yorba Foundation
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
    public bool is_all_day {
        get {
            return date_span != null && exact_time_span == null;
        }
    }
    
    /**
     * Convenience property for determining if {@link Event} spans one or more full days.
     */
    public bool is_day_spanning {
        get {
            return is_all_day || exact_time_span.duration.days >= 1;
        }
    }
    
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
    public Event.blank(Backing.CalendarSource? calendar_source = null) {
        base.blank(iCal.icalcomponent_kind.VEVENT_COMPONENT, calendar_source);
        
        notify.connect(on_notify);
    }
    
    /**
     * @inheritDoc
     */
    protected override void update_from_component(iCal.icalcomponent ical_component, UID? supplied_uid)
        throws Error {
        base.update_from_component(ical_component, supplied_uid);
        
        summary = ical_component.get_summary();
        description = ical_component.get_description();
        
        DateTime dt_start = new DateTime(ical_component, iCal.icalproperty_kind.DTSTART_PROPERTY);
        
        // DTSTART is required for a valid VEVENT but DTEND is not.  See
        // https://tools.ietf.org/html/rfc5545#section-3.6.1 for how a missing DTEND is treated
        // when interpreting a VEVENT.
        DateTime? dt_end = null;
        try {
            dt_end = new DateTime(ical_component, iCal.icalproperty_kind.DTEND_PROPERTY);
        } catch (ComponentError comperr) {
            // if UNAVAILABLE, fall through and follow interpretation rules in iCal spec
            if (!(comperr is ComponentError.UNAVAILABLE))
                throw comperr;
        }
        
        // If no DTEND, look for a DURATION
        if (dt_end == null) {
            try {
                dt_end = dt_start.adjust_duration(ical_component, iCal.icalproperty_kind.DTEND_PROPERTY);
            } catch (ComponentError comperr) {
                // fall through
            }
        }
        
        bool dtend_inclusive = false;
        if (dt_end == null) {
            // For DTSTART w/ DATE, treat DTEND as one-day event; for DATETIME, use DTSTART for DTEND.
            // Because DTEND is non-inclusive in VEVENTs, that means use the same value in both cases
            // and just don't convert as non-inclusive
            dt_end = dt_start;
            dtend_inclusive = true;
        }
        
        // convert start and end DATE/DATE-TIMEs to internal values ... note that VEVENT dtend
        // is non-inclusive (see https://tools.ietf.org/html/rfc5545#section-3.6.1)
        Calendar.DateSpan? date_span;
        Calendar.ExactTimeSpan? exact_time_span;
        DateTime.to_span(dt_start, dt_end, dtend_inclusive, out date_span, out exact_time_span);
        if (exact_time_span != null) {
            set_event_exact_time_span(exact_time_span);
        } else {
            assert(date_span != null);
            set_event_date_span(date_span);
        }
        
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
                remove_all_properties(iCal.icalproperty_kind.SUMMARY_PROPERTY);
                ical_component.set_summary(summary);
            break;
            
            case PROP_DESCRIPTION:
                remove_all_properties(iCal.icalproperty_kind.DESCRIPTION_PROPERTY);
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
                
                remove_all_properties(iCal.icalproperty_kind.DTSTART_PROPERTY);
                ical_component.set_dtstart(ical_dtstart);
                
                remove_all_properties(iCal.icalproperty_kind.DTEND_PROPERTY);
                ical_component.set_dtend(ical_dtend);
            break;
            
            case PROP_LOCATION:
                remove_all_properties(iCal.icalproperty_kind.LOCATION_PROPERTY);
                ical_component.set_location(location);
            break;
            
            case PROP_STATUS:
                remove_all_properties(iCal.icalproperty_kind.STATUS_PROPERTY);
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
     * @inheritDoc
     */
    public override Component.Instance clone(Backing.Source? clone_source) throws Error {
        Backing.CalendarSource clone_calendar_source = null;
        if (clone_source != null) {
            clone_calendar_source = clone_source as Backing.CalendarSource;
            if (clone_calendar_source == null)
                throw new BackingError.INVALID("Supplied backing source for clone not a CalendarSource");
        } else {
            clone_calendar_source = calendar_source;
        }
        
        Component.Event cloned_event = new Component.Event(clone_calendar_source, ical_component);
        if (master != null)
            cloned_event.master = new Component.Event(clone_calendar_source, master.ical_component);
        
        return cloned_event;
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
        freeze_notify();
        
        this.date_span = date_span;
        exact_time_span = null;
        
        thaw_notify();
    }
    
    /**
     * Sets the {@link Event} as a DATE-TIME VEVENT.
     *
     * {@link exact_time_span} will be set and {@link date_span} will be unset.
     *
     * @see set_event_date_span
     */
    public void set_event_exact_time_span(Calendar.ExactTimeSpan exact_time_span) {
        freeze_notify();
        
        this.exact_time_span = exact_time_span;
        date_span = null;
        
        thaw_notify();
    }
    
    /**
     * Adjusts the dates of an {@link Event} while preserving {@link WallTime}, if present.
     *
     * This will preserve the DATE/DATE-TIME aspect of an Event while adjusting the start and
     * end {@link Calendar.Date}s.  If a DATE Event, then this is functionally equivalent to
     * {@link set_event_date_span}.  If a DATE-TIME event, then this is like
     * {@link set_event_exact_time_span} but without the hassle of preserving start and end times
     * while changing the dates.
     */
    public void adjust_start_date(Calendar.Date new_start_date) {
        // generate a new end date that is the same chronological distance from the original start
        // date
        Calendar.DateSpan orig_dates = get_event_date_span(null);
        int diff = orig_dates.start_date.difference(new_start_date);
        if (diff == 0)
            return;
        
        Calendar.Date new_end_date = orig_dates.end_date.adjust(diff);
        
        if (is_all_day) {
            set_event_date_span(new Calendar.DateSpan(new_start_date, new_end_date));
            
            return;
        }
        
        Calendar.ExactTime new_start_time = new Calendar.ExactTime(
            exact_time_span.start_exact_time.tz,
            new_start_date,
            exact_time_span.start_exact_time.to_wall_time()
        );
        
        Calendar.ExactTime new_end_time = new Calendar.ExactTime(
            exact_time_span.end_exact_time.tz,
            new_end_date,
            exact_time_span.end_exact_time.to_wall_time()
        );
        
        set_event_exact_time_span(new Calendar.ExactTimeSpan(new_start_time, new_end_time));
    }
    
    /**
     * Convert an {@link Event} from an all-day to a timed event by only adding the time.
     *
     * Returns with no changes if {@link is_all_day} is false.
     */
    public void all_day_to_timed_event(Calendar.WallTime start_time, Calendar.WallTime end_time,
        Calendar.Timezone timezone) {
        if (!is_all_day)
            return;
        
        // create exact time span using these parameters
        set_event_exact_time_span(
            new Calendar.ExactTimeSpan(
                new Calendar.ExactTime(timezone, date_span.start_date, start_time),
                new Calendar.ExactTime(timezone, date_span.end_date, end_time)
            )
        );
    }
    
    /**
     * Convert an {@link Event} from a timed event to an all-day event by removing the time.
     *
     * Returns with no changes if {@link is_all_day} is true.
     */
    public void timed_to_all_day_event() {
        if (!is_all_day)
            set_event_date_span(get_event_date_span(null));
    }
    
    /**
     * Returns a prettified string describing the {@link Event}'s time span in as concise and
     * economical manner possible.
     *
     * @return null if no time/date information is specified
     */
    public string? get_event_time_pretty_string(Calendar.Date.PrettyFlag date_flags,
        Calendar.ExactTimeSpan.PrettyFlag time_flags, Calendar.Timezone timezone) {
        if (date_span == null && exact_time_span == null)
            return null;
        
        // if any dates are not in current year, display year in all dates
        Calendar.DateSpan date_span = get_event_date_span(timezone);
        if (!date_span.start_date.year.equal_to(Calendar.System.today.year)
            || !date_span.end_date.year.equal_to(Calendar.System.today.year)) {
            date_flags |= Calendar.Date.PrettyFlag.INCLUDE_YEAR;
        }
        
        // if all day, just use the DateSpan's pretty string
        if (is_all_day)
            return date_span.to_pretty_string(date_flags);
        
        return exact_time_span.to_timezone(timezone).to_pretty_string(date_flags, time_flags);
    }
    
    /**
     * @inheritDoc
     */
    public override bool is_valid(bool and_useful) {
        if (and_useful && String.is_empty(summary))
            return false;
        
        return base.is_valid(and_useful) && (date_span != null || exact_time_span != null);
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
        
        // rid
        if (rid != null && other.rid != null) {
            compare = rid.compare_to(other.rid);
            if (compare != 0)
                return compare;
        }
        
        // summary
        compare = strcmp(summary, other.summary);
        if (compare != 0)
            return compare;
        
        // dtstamp
        compare = dtstamp.compare_to(other.dtstamp);
        if (compare != 0)
            return compare;
        
        // use sequence number if available
        compare = sequence - other.sequence;
        if (compare != 0)
            return compare;
        
        // calendar source
        if (calendar_source != null && other.calendar_source != null) {
            compare = calendar_source.compare_to(other.calendar_source);
            if (compare != 0)
                return compare;
        }
        
        // stabilize with UIDs
        return uid.compare_to(other.uid);
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

