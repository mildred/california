/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Component {

/**
 * A blank iCalendar component to create components on the {@link Backing.Source}.
 */

public class Blank : BaseObject {
    public VType vtype { get; private set; }
    
    public string? summary { get; set; default = null; }
    
    public string? description { get; set; default = null; }
    
    public Calendar.DateSpan? date_span { get; private set; default = null; }
    
    public Calendar.DateTimeSpan? date_time_span { get; private set; default = null; }
    
    public TimeZone timezone { get; private set; default = new TimeZone.local(); }
    
    public Blank(VType vtype) {
        this.vtype = vtype;
    }
    
    public void set_start_end_date(Calendar.DateSpan date_span, TimeZone timezone = new TimeZone.local()) {
        this.date_span = date_span;
        this.timezone = timezone;
        date_time_span = null;
    }
    
    public void set_start_end_date_time(Calendar.DateTimeSpan date_time_span,
        TimeZone timezone = new TimeZone.local()) {
        this.date_time_span = date_time_span;
        this.timezone = timezone;
        date_span = null;
    }
    
    internal iCal.icalcomponent to_ical_component() {
        iCal.icalcomponent ical_component = new iCal.icalcomponent(vtype.to_kind());
        
        if (summary != null)
            ical_component.set_summary(summary);
        
        if (description != null)
            ical_component.set_description(description);
        
        if (date_span != null) {
            iCal.icaltimetype dtstart = {0};
            date_to_ical_date(date_span.start_date, ref dtstart);
            ical_component.set_dtstart(dtstart);
            
            iCal.icaltimetype dtend = {0};
            date_to_ical_date(date_span.end_date, ref dtend);
            ical_component.set_dtend(dtend);
        }
        
        if (date_time_span != null) {
            iCal.icaltimetype dtstart = {0};
            date_time_to_ical_date_time(date_time_span.start_date_time, ref dtstart);
            ical_component.set_dtstart(dtstart);
            
            iCal.icaltimetype dtend = {0};
            date_time_to_ical_date_time(date_time_span.end_date_time, ref dtend);
            ical_component.set_dtend(dtend);
        }
        
        return ical_component;
    }
    
    private void date_to_ical_date(Calendar.Date date, ref iCal.icaltimetype ical_date) {
        ical_date.year = date.year.value;
        ical_date.month = date.month.value;
        ical_date.day = date.day_of_month.value;
        ical_date.hour = 0;
        ical_date.minute = 0;
        ical_date.second = 0;
        ical_date.is_utc = 0;
        ical_date.is_date = 1;
        ical_date.is_daylight = 0;
        ical_date.zone = iCal.icaltimezone.get_builtin_timezone_from_tzid(
            get_tzname(date.to_date_time(timezone, 0, 0, 0), timezone));
    }
    
    private void date_time_to_ical_date_time(DateTime date_time, ref iCal.icaltimetype ical_date_time) {
        ical_date_time.year = date_time.get_year();
        ical_date_time.month = date_time.get_month();
        ical_date_time.day = date_time.get_day_of_month();
        ical_date_time.hour = date_time.get_hour();
        ical_date_time.minute = date_time.get_minute();
        ical_date_time.second = date_time.get_second();
        ical_date_time.is_utc = 0;
        ical_date_time.is_date = 0;
        ical_date_time.is_daylight = date_time.is_daylight_savings() ? 1 : 0;
        ical_date_time.zone = iCal.icaltimezone.get_builtin_timezone_from_tzid(
            get_tzname(date_time, timezone));
    }
    
    private unowned string get_tzname(DateTime date_time, TimeZone tz) {
        TimeType time_type = date_time.is_daylight_savings() ? TimeType.DAYLIGHT : TimeType.STANDARD;
        int interval = tz.find_interval(time_type, date_time.to_unix());
        
        // get abbreviation of DateTime's interval, if not available, fallback on 0 interval
        // (generally LMT)
        return (interval != -1) ? tz.get_abbreviation(interval) : tz.get_abbreviation(0);
    }
    
    public override string to_string() {
        return "(new component instance)";
    }
}

}

