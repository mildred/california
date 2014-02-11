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
 * words, components which allocate a specific span of time within a calendar.  Some of thse
 * components may be recurring, in which case any particular instance is merely a generated
 * representation of that recurrance.
 *
 * Alarms are contained within Instance components.  Timezones are handled separately.
 *
 * Instance also offers a number of methods to convert iCal structures into internal objects.
 */

public abstract class Instance : BaseObject, Gee.Hashable<Instance> {
    public enum DateFormat {
        DATE_TIME,
        DATE
    }
    
    /**
     * The {@link Backing.CalendarSource} this {@link Instance} originated from.
     */
    public Backing.CalendarSource calendar_source { get; private set; }
    
    /**
     * The date-time stamp of the {@link Instance}.
     *
     * See [[https://tools.ietf.org/html/rfc5545#section-3.8.7.2]]
     */
    public Calendar.ExactTime dtstamp { get; private set; }
    
    /**
     * The {@link UID} of the {@link Instance}.
     */
    public UID uid { get; private set; }
    
    /**
     * The current backing EDS component being represented by this {@link Instance}.
     */
    protected E.CalComponent eds_component { get; private set; }
    
    /**
     * An {@link Instance} gleaned from an EDS calendar component object.
     *
     * This contructor will call {@link update}, which gives the subclass a single code path for
     * updating its properties and internal state.  Anything which should not be updated by an
     * external invocation of update() (such as immutable data) should update that state after
     * the base constructor returns.
     *
     * If the E.CalComponent's VTYPE does not match the subclasses' VTYPE, ComponentError.MISMATCH
     * is thrown.
     */
    protected Instance(Backing.CalendarSource calendar_source, E.CalComponent eds_component,
        E.CalComponentVType subclass_vtype) throws Error {
        if (subclass_vtype != eds_component.get_vtype()) {
            throw new ComponentError.MISMATCH("Cannot create VTYPE %s from component of VTYPE %s",
                subclass_vtype.to_string(), eds_component.get_vtype().to_string());
        }
        
        this.calendar_source = calendar_source;
        // although base update() sets this, set it here in case it's referred to by the subclass
        // as the "old" component during it's update()
        this.eds_component = eds_component;
        
        unowned string uid_string;
        eds_component.get_uid(out uid_string);
        uid = new UID(uid_string);
        
        iCal.icaltimetype ical_dtstamp;
        eds_component.get_dtstamp(out ical_dtstamp);
        dtstamp = ical_to_exact_time(&ical_dtstamp);
        
        update(eds_component);
    }
    
    /**
     * Updates the {@link Instance} with information from the E.CalComponent.
     *
     * The Instance will update whatever changes it discovers from this new component and fire
     * signals to update subscribers.
     *
     * This is also called by the Instance base class constructor to give subclasses a single
     * code path for updating their state.  It's highly recommended the subclass call the base
     * class update() first to allow it to do basic sanity checking before proceeding to update
     * its own state.
     *
     * @throws BackingError if eds_component is not for this Instance.
     */
    public virtual void update(E.CalComponent eds_component) throws Error {
        unowned string uid_string;
        eds_component.get_uid(out uid_string);
        Component.UID uid = new Component.UID(uid_string);
        
        if (!this.uid.equal_to(uid)) {
            throw new BackingError.MISMATCH("Attempt to update component %s with component %s",
                this.uid.to_string(), uid.to_string());
        }
    }
    
    /**
     * Returns an appropriate {@link Component} instance for the iCalendar component.
     *
     * @returns null if the component is not represented in this namespace (yet).
     */
    public static Component.Instance? convert(Backing.CalendarSource calendar_source,
        E.CalComponent eds_component) throws Error {
        switch (eds_component.get_vtype()) {
            case E.CalComponentVType.EVENT:
                return new Event(calendar_source, eds_component);
            
            default:
                debug("Unable to construct component %s: unimplemented",
                    eds_component.get_vtype().to_string());
                
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
    public static Calendar.ExactTime ical_to_exact_time(iCal.icaltimetype *ical_dt) throws Error {
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
     */
    public static TimeZone ical_to_timezone(iCal.icaltimetype *ical_dt) {
        if (iCal.icaltime_is_utc(*ical_dt) != 0)
            return new TimeZone.utc();
        else if (ical_dt->zone == null)
            return new TimeZone.local();
        else
            return new TimeZone(ical_dt->zone->get_tznames());
    }
    
    /**
     * Convert two iCal.icaltimetypes into a {@link Calendar.DateSpan} or a {@link Calendar.ExactTimeSpan}
     * depending on what they represent.
     *
     * Note that if one is a {@link Calendar.Date} and the other is a {@link ExactTime}, the
     *  ExactTime is coerced into Date and a DateSpan is returned.
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
    
    public bool equal_to(Instance other) {
        return (this != other) ? uid.equal_to(other.uid) : true;
    }
    
    public uint hash() {
        return uid.hash();
    }
}

}

