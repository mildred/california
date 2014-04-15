/* Copyright 2014 Yorba Foundation
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
    public iCal.icalproperty_method method { get; private set; default = iCal.icalproperty_method.NONE; }
    
    /**
     * The VCALENDAR's CALSCALE.
     *
     * See [[https://tools.ietf.org/html/rfc5545#section-3.7.1]]
     */
    public string? calscale { get; private set; default = null; }
    
    /**
     * VEVENTS within the VCALENDAR.
     */
    public Gee.List<Event> events { get; private set; default = new Gee.ArrayList<Event>(); }
    
    /**
     * The iCal VCALENDAR this iCalendar represents.
     */
    private iCal.icalcomponent _ical_component;
    public iCal.icalcomponent ical_component { get { return _ical_component; } }
    
    /**
     * Create an {@link iCalendar} representation of the iCal component.
     *
     * @throws ComponentError.INVALID if root is not a VCALENDAR.
     */
    private iCalendar(owned iCal.icalcomponent root) throws Error {
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
        
        prop = root.get_first_property(iCal.icalproperty_kind.METHOD_PROPERTY);
        if (prop != null)
            method = prop.get_method();
        
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
        
        return new iCalendar((owned) ical_component);
    }
    
    public override string to_string() {
        return "iCalendar|%s|%s|%s|%s (%d events)".printf(prodid, version, calscale, method.to_string(),
            events.size);
    }
}

}

