/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Component {

/**
 * A mutable iCalendar component that has a definitive instance within a calendar.
 *
 * By "instance", this means {@link Event}s, To-Do's, Journals, and Free/Busy components.  In other
 * words, components which allocate a specific item within a calendar.  Some of thse
 * components may be recurring, in which case any particular instance is merely a generated
 * representation of that recurrance.
 *
 * Mutability is achieved two separate ways.  One is to call {@link full_update} supplying a new
 * iCal component to update an existing one (verified by UID and RID).  This will update all
 * fields.
 *
 * The second is to update the mutable properties themselves, which will then update the underlying
 * iCal component.
 *
 * Alarms are contained within Instance components.  Timezones are handled separately.
 *
 * Instance also offers a number of methods to convert iCal structures into internal objects.
 */

public abstract class Instance : BaseObject, Gee.Hashable<Instance> {
    public const string PROP_CALENDAR_SOURCE = "calendar-source";
    public const string PROP_DTSTAMP = "dtstamp";
    public const string PROP_UID = "uid";
    public const string PROP_ICAL_COMPONENT = "ical-component";
    
    protected const string PROP_IN_FULL_UPDATE = "in-full-update";
    
    public enum DateFormat {
        DATE_TIME,
        DATE
    }
    
    /**
     * The {@link Backing.CalendarSource} this {@link Instance} originated from.
     *
     * This will initialize as null if created as a {@link blank} Instance.
     */
    public Backing.CalendarSource? calendar_source { get; set; default = null; }
    
    /**
     * The date-time stamp of the {@link Instance}.
     *
     * Any update to the Instance will result in this being updated as well.  It cannot be set
     * manually.
     *
     * See [[https://tools.ietf.org/html/rfc5545#section-3.8.7.2]]
     *
     * @see notify_altered
     */
    public Calendar.ExactTime? dtstamp { get; private set; default = null; }
    
    /**
     * The {@link UID} of the {@link Instance}.
     *
     * This element is immutable, as it represents the identify of this Instance.
     */
    public UID uid { get; private set; }
    
    /**
     * The iCal component being represented by this {@link Instance}.
     */
    private iCal.icalcomponent _ical_component;
    public iCal.icalcomponent ical_component { get { return _ical_component; } }
    
    /**
     * True if inside {@link full_update}.
     *
     * Subclasses want to ignore updates to various properties (their own and {@link Instance}'s)
     * if this is true.
     */
    protected bool in_full_update { get; private set; default = false; }
    
    /**
     * Fired when an {@link Instance} is altered in any way.
     *
     * Although "notify" is probably good enough for most situations (and tells the subscriber
     * which property changed), there's no guarantee that all fields in subclasses of Instance
     * will be stored in properties, so this is the final word on knowing when an Instance has
     * been altered.
     *
     * Subclasses should use {@link notify_altered} rather than firing this signal directly.
     */
    public signal void altered(bool from_full_update);
    
    /**
     * An {@link Instance} representing an iCal component.
     *
     * This contructor will call {@link full_update}, which gives the subclass a single code path
     *for updating its properties and internal state.  Anything which should not be updated by an
     * external invocation of full_update() (such as immutable data) should update that state after
     * the base constructor returns.
     */
    protected Instance(Backing.CalendarSource calendar_source, iCal.icalcomponent ical_component,
        iCal.icalcomponent_kind kind) throws Error {
        if (ical_component.isa() != kind) {
            throw new ComponentError.MISMATCH("Cannot create VTYPE %s from component of VTYPE %s",
                kind.to_string(), ical_component.isa().to_string());
        }
        
        this.calendar_source = calendar_source;
        // although base update() sets this, set it here in case it's referred to by the subclasses
        // as the "old" component during it's update()
        _ical_component = ical_component.clone();
        
        // this needs to be stored before calling update() or the equality check there will fail
        uid = new UID(_ical_component.get_uid());
        
        full_update(_ical_component);
    }
    
    /**
     * Creates a blank {@link Instance} for a new iCal component with a generated {@link uid}.
     *
     * Unlike the primary constructor, this will not call {@link full_update}.
     */
    protected Instance.blank(iCal.icalcomponent_kind kind) {
        _ical_component = new iCal.icalcomponent(kind);
        uid = Component.UID.generate();
        _ical_component.set_uid(uid.value);
    }
    
    /**
     * Fires the {@link altered} signal, allowing for subclasses to update internal state before
     * or after the trigger.
     */
    protected virtual void notify_altered(bool from_full_update) {
        altered(from_full_update);
        
        // only update dtstamp if not altered by a full update (as dtstamp is updated there)
        if (from_full_update)
            return;
        
        dtstamp = Calendar.now();
        
        iCal.icaltimetype ical_dtstamp = {};
        exact_time_to_ical(dtstamp, &ical_dtstamp);
        ical_component.set_dtstamp(ical_dtstamp);
    }
    
    /**
     * Updates the {@link Instance} with information from the E.CalComponent.
     *
     * The Instance will update whatever changes it discovers from this new component and fire
     * signals to update subscribers.
     *
     * This is also called by the Instance base class constructor to give subclasses a single
     * code path for updating their state.
     *
     * @throws BackingError if eds_component is not for this Instance.
     */
    public void full_update(iCal.icalcomponent ical_component) throws Error {
        in_full_update = true;
        
        bool notify = false;
        try {
            update_from_component(ical_component);
            notify = true;
        } finally {
            in_full_update = false;
            
            // notify when !in_full_update
            if (notify)
                notify_altered(true);
        }
    }
    
    /**
     * The "real" update method that should be overridden by subclasses to update their fields.
     *
     * It's highly recommended the subclass call the base class update_from_component() first to
     * allow it to do basic sanity checking before proceeding to update its own state.
     *
     * @see full_update
     */
    protected virtual void update_from_component(iCal.icalcomponent ical_component) throws Error {
        Component.UID other_uid = new Component.UID(ical_component.get_uid());
        if (!uid.equal_to(other_uid)) {
            throw new BackingError.MISMATCH("Attempt to update component %s with component %s",
                this.uid.to_string(), other_uid.to_string());
        }
        
        iCal.icaltimetype ical_dtstamp = ical_component.get_dtstamp();
        dtstamp = ical_to_exact_time(&ical_dtstamp);
        
        if (_ical_component != ical_component)
            _ical_component = ical_component.clone();
    }
    
    /**
     * Returns an appropriate {@link Component} instance for the iCalendar component.
     *
     * @returns null if the component is not represented in this namespace (yet).
     */
    public static Component.Instance? convert(Backing.CalendarSource calendar_source,
        iCal.icalcomponent ical_component) throws Error {
        switch (ical_component.isa()) {
            case iCal.icalcomponent_kind.VEVENT_COMPONENT:
                return new Event(calendar_source, ical_component);
            
            default:
                debug("Unable to construct component %s: unimplemented",
                    ical_component.isa().to_string());
                
                return null;
        }
    }
    
    /**
     * Convert an iCal.icaltimetype to a GLib.DateTime or {@link Calendar.Date}, depending on the
     * stored information.
     *
     * @returns {@link DateFormat} indicating if Date or DateTime holds a reference.  The other
     * will always be null.  In no case will both be null.
     * @throws CalendarError if the supplied values are out-of-range.
     */
    public static DateFormat ical_to_datetime_or_date(iCal.icaltimetype *ical_dt,
        out Calendar.ExactTime? exact_time, out Calendar.Date? date) throws Error {
        if (iCal.icaltime_is_date(*ical_dt) == 0) {
            exact_time = ical_to_exact_time(ical_dt);
            date = null;
            
            return DateFormat.DATE_TIME;
        }
        
        date = ical_to_date(ical_dt);
        exact_time = null;
        
        return DateFormat.DATE;
    }
    
    /**
     * Convert an iCal.icaltimetype to an {@link Calendar.ExactTime}.
     *
     * @throws CalendarError if the supplied values are out-of-range or invalid, ComponentError
     * if a DATE rather than a DATE-TIME.
     */
    public static Calendar.ExactTime ical_to_exact_time(iCal.icaltimetype *ical_dt)
        throws Error {
        if (iCal.icaltime_is_date(*ical_dt) != 0) {
            throw new ComponentError.INVALID("iCalendar time type must be DATE-TIME: %s",
                iCal.icaltime_as_ical_string(*ical_dt));
        }
        
        return new Calendar.ExactTime.full(ical_to_timezone(ical_dt), ical_dt.year, ical_dt.month,
            ical_dt.day, ical_dt.hour, ical_dt.minute, ical_dt.second);
    }
    
    /**
     * Convert an iCal.icaltimetype to a {@link Calendar.Date}.
     *
     * @throws CalendarError if the supplied values are out-of-range or invalid, ComponentError
     * if a DATE-TIME rather than a DATE.
     */
    public static Calendar.Date ical_to_date(iCal.icaltimetype *ical_dt) throws Error {
        if (iCal.icaltime_is_date(*ical_dt) == 0) {
            throw new ComponentError.INVALID("iCalendar time type must be DATE: %s",
                iCal.icaltime_as_ical_string(*ical_dt));
        }
        
        return new Calendar.Date(Calendar.DayOfMonth.for(ical_dt.day),
            Calendar.Month.for(ical_dt.month), new Calendar.Year(ical_dt.year));
    }
    
    /**
     * Convert's an iCal.icaltimetype's timezone into a GLib.TimeZone.
     *
     * TODO: This is currently broken with EDS, which supplies the TZID out-of-band.
     */
    public static TimeZone ical_to_timezone(iCal.icaltimetype *ical_dt) {
        // use libical's if not supplied
        string? tzid = iCal.icaltime_get_tzid(*ical_dt);
        if (!String.is_empty(tzid))
            return new TimeZone(tzid);
        else if (iCal.icaltime_is_utc(*ical_dt) != 0)
            return new TimeZone.utc();
        else
            return new TimeZone.local();
    }
    
    /**
     * Convert two iCal.icaltimetypes into a {@link Calendar.DateSpan} or a {@link Calendar.ExactTimeSpan}
     * depending on what they represent.
     *
     * dtend_inclusive indicates whether the ical_end_dt should be treated as inclusive or exclusive
     * of the span.  See the iCalendar specification for information on how each component should
     * treat the situation.  Exclusive only works for DATE values.
     *
     * @returns {@link DateFormat} indicating if a DateSpan or a ExactTimeSpan was returned via
     * the out parameters.  The other will always be null.  In no case will both be null.
     * @throws CalendarError if any value is invalid or out-of-range.
     */
    public static DateFormat ical_to_span(bool dtend_inclusive, iCal.icaltimetype *ical_start_dt,
        iCal.icaltimetype *ical_end_dt, out Calendar.ExactTimeSpan exact_time_span,
        out Calendar.DateSpan date_span) throws Error {
        if (ical_start_dt == null)
            throw new ComponentError.INVALID("NULL ical_start_dt");
        
        if (ical_end_dt == null)
            throw new ComponentError.INVALID("NULL ical_end_dt");
        
        Calendar.ExactTime? start_exact_time;
        Calendar.Date? start_date;
        ical_to_datetime_or_date(ical_start_dt, out start_exact_time, out start_date);
        
        Calendar.ExactTime? end_exact_time;
        Calendar.Date? end_date;
        ical_to_datetime_or_date(ical_end_dt, out end_exact_time, out end_date);
        
        // if both DATE-TIME, easy peasy
        if (start_exact_time != null && end_exact_time != null) {
            exact_time_span = new Calendar.ExactTimeSpan(start_exact_time, end_exact_time);
            date_span = null;
            
            return DateFormat.DATE_TIME;
        }
        
        // if one or the other DATE-TIME, coerce to DATE
        if (start_exact_time != null) {
            // end is a DATE, do coercion
            assert(end_date != null);
            
            start_date = new Calendar.Date.from_exact_time(start_exact_time);
            start_exact_time = null;
        } else if (end_exact_time != null) {
            // start is a DATE, do coercion
            assert(start_date != null);
            
            end_date = new Calendar.Date.from_exact_time(end_exact_time);
            end_exact_time = null;
        }
        
        // if exclusive, drop back one day
        if (!dtend_inclusive)
            end_date = end_date.adjust(-1, Calendar.DateUnit.DAY);
        
        date_span = new Calendar.DateSpan(start_date, end_date);
        exact_time_span = null;
        
        return DateFormat.DATE;
    }
    
    public static void date_to_ical(Calendar.Date date, iCal.icaltimetype *ical_dt) {
        ical_dt->year = date.year.value;
        ical_dt->month = date.month.value;
        ical_dt->day = date.day_of_month.value;
        ical_dt->hour = 0;
        ical_dt->minute = 0;
        ical_dt->second = 0;
        ical_dt->is_utc = 0;
        ical_dt->is_date = 1;
        ical_dt->is_daylight = 0;
        ical_dt->zone = null;
    }
    
    public static void date_span_to_ical(Calendar.DateSpan date_span, iCal.icaltimetype *ical_dtstart,
        iCal.icaltimetype *ical_dtend) {
        date_to_ical(date_span.start_date, ical_dtstart);
        date_to_ical(date_span.end_date, ical_dtend);
    }
    
    public static void exact_time_to_ical(Calendar.ExactTime exact_time, iCal.icaltimetype *ical_dt) {
        ical_dt->year = exact_time.year.value;
        ical_dt->month = exact_time.month.value;
        ical_dt->day = exact_time.day_of_month.value;
        ical_dt->hour = exact_time.hour;
        ical_dt->minute = exact_time.minute;
        ical_dt->second = exact_time.second;
        ical_dt->is_utc = 0;
        ical_dt->is_date = 0;
        ical_dt->is_daylight = exact_time.is_dst ? 1 : 0;
        ical_dt->zone = iCal.icaltimezone.get_builtin_timezone_from_tzid(exact_time.tzid);
    }
    
    public static void exact_time_span_to_ical(Calendar.ExactTimeSpan exact_time_span,
        iCal.icaltimetype *ical_dtstart, iCal.icaltimetype *ical_dtend) {
        exact_time_to_ical(exact_time_span.start_exact_time, ical_dtstart);
        exact_time_to_ical(exact_time_span.end_exact_time, ical_dtend);
    }
    
    /**
     * Equality is defined as {@link Component.Instance}s having the same UID (and, when available,
     * RID), nothing more.
     */
    public bool equal_to(Instance other) {
        return (this != other) ? uid.equal_to(other.uid) : true;
    }
    
    public uint hash() {
        return uid.hash();
    }
}

}

