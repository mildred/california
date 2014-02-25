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
        
        DateTime dt_stamp = new DateTime(ical_component, iCal.icalproperty_kind.DTSTAMP_PROPERTY);
        if (!dt_stamp.is_date)
            dtstamp = dt_stamp.to_exact_time();
        
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
     * Convenience method to convert a {@link Calendar.Date} to an iCal DATE.
     */
    protected static void date_to_ical(Calendar.Date date, iCal.icaltimetype *ical_dt) {
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
    
    /**
     * Convenience method to convert a {@link Calendar.DateSpan} to a pair of iCal DATEs.
     *
     * dtend_inclusive indicates whether the dt_end should be treated as inclusive or exclusive
     * of the span.  See the iCal specification for information on how each component should
     * treat the situation.
     */
    protected static void date_span_to_ical(Calendar.DateSpan date_span, bool dtend_inclusive,
        iCal.icaltimetype *ical_dtstart, iCal.icaltimetype *ical_dtend) {
        date_to_ical(date_span.start_date, ical_dtstart);
        date_to_ical(date_span.end_date.adjust(dtend_inclusive ? 0 : 1, Calendar.DateUnit.DAY),
            ical_dtend);
    }
    
    /**
     * Convenience method to convert a {@link Calendar.ExactTime} to an iCal DATE-TIME.
     */
    protected static void exact_time_to_ical(Calendar.ExactTime exact_time, iCal.icaltimetype *ical_dt) {
        ical_dt->year = exact_time.year.value;
        ical_dt->month = exact_time.month.value;
        ical_dt->day = exact_time.day_of_month.value;
        ical_dt->hour = exact_time.hour;
        ical_dt->minute = exact_time.minute;
        ical_dt->second = exact_time.second;
        ical_dt->is_utc = 0;
        ical_dt->is_date = 0;
        ical_dt->is_daylight = exact_time.is_dst ? 1 : 0;
        ical_dt->zone = iCal.icaltimezone.get_builtin_timezone_from_offset(exact_time.utc_offset,
            exact_time.tzid);
    }
    
    /**
     * Convenience method to convert a {@link Calendar.ExactTimeSpan} to a pair of iCal DATE-TIMEs.
     */
    protected static void exact_time_span_to_ical(Calendar.ExactTimeSpan exact_time_span,
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

