/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Component {

/**
 * An iCalendar component that has a definitive instance within a calendar.
 *
 * By "instance", this means {@link Event}s, To-Do's, Journals, and Free/Busy components.
 * Alarms are contained within Instance components, and TimeZones are handled separately.
 *
 * Instance also offers a number of methods to convert iCal structures into internal objects.
 */

public abstract class Instance : BaseObject {
    public enum DateFormat {
        DATE_TIME,
        DATE
    }
    
    /**
     * The date-time stamp of the {@link Instance}.
     *
     * See [[https://tools.ietf.org/html/rfc5545#section-3.8.7.2]]
     */
    public DateTime dtstamp { get; private set; }
    
    /**
     * The {@link UID} of the {@link Instance}.
     */
    public UID uid { get; private set; }
    
    /**
     * Only available if created with {@link Instance.from_eds_component}.
     */
    protected E.CalComponent? eds_component { get; private set; default = null; }
    
    /**
     * An {@link Instance} gleaned from an EDS calendar component object.
     */
    protected Instance(E.CalComponent eds_component) throws CalendarError {
        this.eds_component = eds_component;
        
        unowned string uid_string;
        eds_component.get_uid(out uid_string);
        uid = new UID(uid_string);
        
        iCal.icaltimetype ical_dtstamp;
        eds_component.get_dtstamp(out ical_dtstamp);
        dtstamp = ical_to_datetime(&ical_dtstamp);
    }
    
    /**
     * Convert an iCal.icaltimetype to a GLib.DateTime or {@link Calendar.Date}, depending on the
     * stored information.
     *
     * @returns {@link DateFormat} indicating if Date or DateTime holds a reference.  The other
     * will always be null.  In no case will both be null.
     * @throws CalendarError if the supplied values are out-of-range
     */
    public static DateFormat ical_to_datetime_or_date(iCal.icaltimetype *ical_dt, out DateTime? date_time,
        out Calendar.Date? date) throws CalendarError {
        if (iCal.icaltime_is_date(*ical_dt) == 0) {
            date_time = ical_to_datetime(ical_dt);
            date = null;
            
            return DateFormat.DATE_TIME;
        }
        
        date = ical_to_date(ical_dt);
        date_time = null;
        
        return DateFormat.DATE;
    }
    
    /**
     * Convert an iCal.icaltimetype to a GLib.DateTime.
     *
     * @throws CalendarError if the supplied values are out-of-range or is a DATE.
     */
    public static DateTime ical_to_datetime(iCal.icaltimetype *ical_dt) throws CalendarError {
        if (iCal.icaltime_is_date(*ical_dt) != 0) {
            throw new CalendarError.INVALID("iCalendar time type must be DATE-TIME: %s",
                iCal.icaltime_as_ical_string(*ical_dt));
        }
        
        DateTime date_time = new DateTime(ical_to_timezone(ical_dt), ical_dt.year, ical_dt.month,
            ical_dt.day, ical_dt.hour, ical_dt.minute, ical_dt.second);
        if (date_time == null) {
            throw new CalendarError.INVALID("Invalid iCalendar time: %s",
                iCal.icaltime_as_ical_string(*ical_dt));
        }
        
        return date_time;
    }
    
    /**
     * Convert an iCal.icaltimetype to a {@link Calendar.Date}.
     *
     * @throws CalendarError if the supplied values are out-of-range or is a DATE-TIME.
     */
    public static Calendar.Date ical_to_date(iCal.icaltimetype *ical_dt) throws CalendarError {
        if (iCal.icaltime_is_date(*ical_dt) == 0) {
            throw new CalendarError.INVALID("iCalendar time type must be DATE: %s",
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
     * Convert two iCal.icaltimetypes into a {@link Calendar.DateSpan} or a {@link Calendar.DateTimeSpan}
     * depending on what they represent.
     *
     * Note that if one is a {@link Calendar.Date} and the other is a DateTime, the DateTime is
     * coerced into Date and a DateSpan is returned.
     *
     * @returns {@link DateFormat} indicating if a DateSpan or a DateTimeSpan was returned via
     * the out parameters.  The other will always be null.  In no case will both be null.
     * @throws CalendarError if any value is out-of-range.
     */
    public static DateFormat ical_to_span(iCal.icaltimetype *ical_start_dt, iCal.icaltimetype *ical_end_dt,
        out Calendar.DateTimeSpan date_time_span, out Calendar.DateSpan date_span) throws CalendarError {
        DateTime? start_date_time;
        Calendar.Date? start_date;
        ical_to_datetime_or_date(ical_start_dt, out start_date_time, out start_date);
        
        DateTime? end_date_time;
        Calendar.Date? end_date;
        ical_to_datetime_or_date(ical_end_dt, out end_date_time, out end_date);
        
        // if both DATE-TIME, easy peasy
        if (start_date_time != null && end_date_time != null) {
            date_time_span = new Calendar.DateTimeSpan(start_date_time, end_date_time);
            date_span = null;
            
            return DateFormat.DATE_TIME;
        }
        
        // if one or the other DATE-TIME, coerce to DATE
        if (start_date_time != null) {
            // end is a DATE, do coercion
            assert(end_date != null);
            
            start_date = new Calendar.Date.from_date_time(start_date_time);
            start_date_time = null;
        } else if (end_date_time != null) {
            // start is a DATE, do coercion
            assert(start_date != null);
            
            end_date = new Calendar.Date.from_date_time(end_date_time);
            end_date_time = null;
        }
        
        date_span = new Calendar.DateSpan(start_date, end_date);
        date_time_span = null;
        
        return DateFormat.DATE;
    }
}

}

