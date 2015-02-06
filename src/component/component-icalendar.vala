/* Copyright 2014-2015 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Component {

/**
 * An immutable representation of an iCalendar VCALENDAR component.
 *
 * Note that a iCalendar is not considered an {@link Instance}; it's a container which holds
 * Instances.  Although iCalendar is immutable, there is no guarantee that the Instances it
 * hold will be.
 *
 * Also note that iCalendar currently is not associated with a {@link Backing.CalendarSource}.
 * If the feature is ever added where a CalendarSource can cough up its entire VCALENDAR,
 * then that might make sense.
 *
 * See [[https://tools.ietf.org/html/rfc5545#section-3.6]].
 */

public class iCalendar : BaseObject {
    /**
     * Default METHOD when one is not supplied with iCalendar.
     *
     * NONE is not viable, as some backends will choke and require one.  PUBLISH is a good
     * general METHOD for VCALENDARs lacking a METHOD.
     *
     * @see method
     */
    public const iCal.icalproperty_method DEFAULT_METHOD = iCal.icalproperty_method.PUBLISH;
    
    /**
     * The VCALENDAR's PRODID.
     *
     * See [[https://tools.ietf.org/html/rfc5545#section-3.7.3]]
     */
    public string? prodid { get; private set; default = null; }
    
    /**
     * The VCALENDAR's VERSION.
     *
     * See [[https://tools.ietf.org/html/rfc5545#section-3.7.4].  In particular,
     * read the Purpose section.
     */
    public string? version { get; private set; default = null; }
    
    /**
     * The VCALENDAR's METHOD.
     *
     * See [[https://tools.ietf.org/html/rfc5545#section-3.7.2]]
     */
    public iCal.icalproperty_method method { get; private set; default = DEFAULT_METHOD; }
    
    /**
     * The VCALENDAR's CALSCALE.
     *
     * See [[https://tools.ietf.org/html/rfc5545#section-3.7.1]]
     */
    public string? calscale { get; private set; default = null; }
    
    /**
     * VEVENTS within the VCALENDAR.
     *
     * Don't add {@link Event} objects directly to this list.
     */
    public Gee.List<Event> events { get; private set; default = new Gee.ArrayList<Event>(); }
    
    /**
     * The iCal VCALENDAR this iCalendar represents.
     */
    private iCal.icalcomponent _ical_component;
    public iCal.icalcomponent ical_component { get { return _ical_component; } }
    
    /**
     * Returns the iCal source for this {@link iCalendar}.
     */
    public string source { get { return ical_component.as_ical_string(); } }
    
    /**
     * Creates a new {@link iCalendar}.
     *
     * As iCalendar is currently immutable, {@link Instance}s must be added here.  It's possible
     * later modifications will allow for Instances to be added and removed dynamically.
     */
    public iCalendar(iCal.icalproperty_method method, string? prodid, string? version, string? calscale,
        Gee.Collection<Instance>? instances) {
        this.prodid = prodid;
        this.version = version;
        this.calscale = calscale;
        this.method = method;
        
        _ical_component = new iCal.icalcomponent(iCal.icalcomponent_kind.VCALENDAR_COMPONENT);
        
        if (prodid != null && !String.is_empty(prodid)) {
            iCal.icalproperty prop = new iCal.icalproperty(iCal.icalproperty_kind.PRODID_PROPERTY);
            prop.set_prodid(prodid);
            _ical_component.add_property(prop);
        }
        
        if (version != null && !String.is_empty(version)) {
            iCal.icalproperty prop = new iCal.icalproperty(iCal.icalproperty_kind.VERSION_PROPERTY);
            prop.set_version(version);
            _ical_component.add_property(prop);
        }
        
        if (calscale != null && !String.is_empty(calscale)) {
            iCal.icalproperty prop = new iCal.icalproperty(iCal.icalproperty_kind.CALSCALE_PROPERTY);
            prop.set_calscale(prodid);
            _ical_component.add_property(prop);
        }
        
        // METHOD is required ... not checking for NONE, if that's how the user wants to go, so
        // be it
        iCal.icalproperty prop = new iCal.icalproperty(iCal.icalproperty_kind.METHOD_PROPERTY);
        prop.set_method(method);
        _ical_component.add_property(prop);
        
        //
        // contained components
        //
        
        foreach (Instance instance in instances) {
            // store copies because ownership is not being transferred
            _ical_component.add_component(instance.ical_component.clone());
            
            Event? event = instance as Event;
            if (event != null)
                events.add(event);
        }
    }
    
    /**
     * Create an {@link iCalendar} representation of an existing iCal component.
     *
     * @throws ComponentError.INVALID if root is not a VCALENDAR.
     */
    private iCalendar.take(owned iCal.icalcomponent root) throws Error {
        if (root.isa() != iCal.icalcomponent_kind.VCALENDAR_COMPONENT)
            throw new ComponentError.INVALID("Not a VCALENDAR");
        
        //
        // VCALENDAR properties
        //
        
        unowned iCal.icalproperty? prop = root.get_first_property(iCal.icalproperty_kind.PRODID_PROPERTY);
        if (prop != null)
            prodid = prop.get_prodid();
        
        prop = root.get_first_property(iCal.icalproperty_kind.VERSION_PROPERTY);
        if (prop != null)
            version = prop.get_version();
        
        prop = root.get_first_property(iCal.icalproperty_kind.CALSCALE_PROPERTY);
        if (prop != null)
            calscale = prop.get_calscale();
        
        // METHOD is important ... if not present, be sure it's set (important for adding, some
        // backends may require its presence)
        prop = root.get_first_property(iCal.icalproperty_kind.METHOD_PROPERTY);
        if (prop != null)
            method = prop.get_method();
        else
            root.set_method(DEFAULT_METHOD);
        
        //
        // Contained components
        //
        
        // VEVENTS
        unowned iCal.icalcomponent? child_component = root.get_first_component(
            iCal.icalcomponent_kind.VEVENT_COMPONENT);
        while (child_component != null) {
            events.add(Instance.convert(null, child_component) as Event);
            child_component = root.get_next_component(iCal.icalcomponent_kind.VEVENT_COMPONENT);
        }
        
        // take ownership
        _ical_component = (owned) root;
    }
    
    /**
     * Returns an appropriate {@link Calendar} instance for the string of iCalendar data.
     *
     * @throws ComponentError if data is unrecognized
     */
    public static iCalendar parse(string? str) throws Error {
        if (String.is_empty(str))
            throw new ComponentError.INVALID("Empty VCALENDAR string");
        
        iCal.icalcomponent? ical_component = iCal.icalparser.parse_string(str);
        if (ical_component == null)
            throw new ComponentError.INVALID("Unable to parse VCALENDAR (%db)".printf(str.length));
        
        return new iCalendar.take((owned) ical_component);
    }
    
    public override string to_string() {
        return "iCalendar|%s|%s|%s|%s (%d events)".printf(prodid, version, calscale, method.to_string(),
            events.size);
    }
}

}

