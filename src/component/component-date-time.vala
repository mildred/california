/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Component {

public class DateTime : BaseObject {
    /**
     * The TZID for the iCal component and property kind.
     *
     * TZID in libical means Olson city timezone.  A null zone indicates floating time or a DATE.
     *
     * @see is_floating_time
     * @see is_date
     */
    public Calendar.OlsonZone? zone { get; private set; default = null; }
    
    /**
     * Indicates if this {@link DateTime} is for UTC time.
     */
    public bool is_utc { get { return iCal.icaltime_is_utc(dt) != 0; } }
    
    /**
     * Indicates if this {@link DateTime} is "floating" time.
     *
     * See [[https://tools.ietf.org/html/rfc5545#section-3.8.3.1]]
     */
    public bool is_floating { get { return zone == null && !is_date; } }
    
    /**
     * Indicates if this is a DATE rather than a DATE-TIME.
     *
     * See [[https://tools.ietf.org/html/rfc5545#section-3.3.4]]
     */
    public bool is_date { get { return iCal.icaltime_is_date(dt) != 0; } }
    
    /**
     * The DATE-TIME for the iCal component and property kind.
     */
    public iCal.icaltimetype dt;
    
    /**
     * Creates a new {@link DateTime} for the iCal component of the property kind.
     *
     * Note that DTSTART_PROPERTY, DTEND_PROPERTY, and DTSTAMP_PROPERTY are the only properties
     * currently supported.
     */
    public DateTime(iCal.icalcomponent ical_component, iCal.icalproperty_kind ical_prop_kind)
        throws ComponentError {
        unowned iCal.icalproperty? prop = ical_component.get_first_property(ical_prop_kind);
        if (prop == null)
            throw new ComponentError.UNAVAILABLE("No property of kind %s", ical_prop_kind.to_string());
        
        switch (ical_prop_kind) {
            case iCal.icalproperty_kind.DTSTAMP_PROPERTY:
                dt = prop.get_dtstamp();
            break;
            
            case iCal.icalproperty_kind.DTSTART_PROPERTY:
                dt = prop.get_dtstart();
            break;
            
            case iCal.icalproperty_kind.DTEND_PROPERTY:
                dt = prop.get_dtend();
            break;
            
            default:
                assert_not_reached();
        }
        
        if (iCal.icaltime_is_null_time(dt) != 0)
            throw new ComponentError.INVALID("DATE-TIME for %s is null time", ical_prop_kind.to_string());
        
        if (iCal.icaltime_is_valid_time(dt) == 0)
            throw new ComponentError.INVALID("DATE-TIME for %s is invalid", ical_prop_kind.to_string());
        
        unowned iCal.icalparameter? param = prop.get_first_parameter(iCal.icalparameter_kind.TZID_PARAMETER);
        if (param != null)
            zone = new Calendar.OlsonZone(param.get_tzid());
    }
    
    /**
     * Converts the stored iCal DATE-TIME to an {@link Calendar.ExactTime}.
     *
     * Returns null if {@link is_date} is true.
     */
    public Calendar.ExactTime? to_exact_time() throws CalendarError{
        if (is_date)
            return null;
        
        return new Calendar.ExactTime.full(get_timezone(), dt.year, dt.month, dt.day, dt.hour,
            dt.minute, dt.second);
    }
    
    /**
     * Converts the stored iCal DATE to a {@link Calendar.Date}.
     *
     * Returns null if {@link is_date} is false.
     */
    public Calendar.Date? to_date() throws CalendarError {
        if (!is_date)
            return null;
        
        return new Calendar.Date(Calendar.DayOfMonth.for(dt.day), Calendar.Month.for(dt.month),
            new Calendar.Year(dt.year));
    }
    
    /**
     * Returns a {@link Timezone} for the DATE-TIME.
     *
     * Returns null if {@link is_date} is true.  Returns the local timezone if {@link is_floating}
     * is true.  Returns the timezone for UTC if {@link is_utc} is true.
     */
    public Calendar.Timezone? get_timezone() {
        if (is_date)
            return null;
        
        if (is_utc)
            return Calendar.Timezone.utc;
        
        if (is_floating || zone == null)
            return Calendar.Timezone.local;
        
        return new Calendar.Timezone(zone);
    }
    
    /**
     * Convert two {@link DateTime}s into a {@link Calendar.DateSpan} or a
     * {@link Calendar.ExactTimeSpan} depending on what they represent.
     *
     * dtend_inclusive indicates whether the dt_end should be treated as inclusive or exclusive
     * of the span.  See the iCal specification for information on how each component should
     * treat the situation.  Exclusive only works for DATE values.
     *
     * One out parameter will be non-null depending on the supplied values.  In no case will both
     * be null unless an Error is thrown.
     *
     * @throws CalendarError if any value is invalid or out-of-range.
     */
    public static void to_span(DateTime dt_start, DateTime dt_end, bool dtend_inclusive,
        out Calendar.DateSpan date_span, out Calendar.ExactTimeSpan exact_time_span) throws CalendarError {
        Calendar.ExactTime? start_exact_time = null;
        Calendar.Date? start_date = null;
        if (dt_start.is_date)
            start_date = dt_start.to_date();
        else
            start_exact_time = dt_start.to_exact_time();
        
        Calendar.ExactTime? end_exact_time = null;
        Calendar.Date? end_date = null;
        if (dt_end.is_date)
            end_date = dt_end.to_date();
        else
            end_exact_time = dt_end.to_exact_time();
        
        // if both DATE-TIME, easy peasy
        if (start_exact_time != null && end_exact_time != null) {
            exact_time_span = new Calendar.ExactTimeSpan(start_exact_time, end_exact_time);
            date_span = null;
            
            return;
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
    }
    
    public override string to_string() {
        try {
            if (is_date)
                return "DATE:%s".printf(to_date().to_string());
            else
                return "DATE-TIME:%s".printf(to_exact_time().to_string());
        } catch (CalendarError calerr) {
            return "Invalid DATE-TIME:%s".printf(calerr.message);
        }
    }
}

}

