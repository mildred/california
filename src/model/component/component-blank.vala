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
    
    public Calendar.ExactTimeSpan? exact_time_span { get; private set; default = null; }
    
    public TimeZone timezone { get; private set; default = new TimeZone.local(); }
    
    public Blank(VType vtype) {
        this.vtype = vtype;
    }
    
    public void set_start_end_date(Calendar.DateSpan date_span, TimeZone timezone = new TimeZone.local()) {
        this.date_span = date_span;
        this.timezone = timezone;
        exact_time_span = null;
    }
    
    public void set_start_end_exact_time(Calendar.ExactTimeSpan exact_time_span,
        TimeZone timezone = new TimeZone.local()) {
        this.exact_time_span = exact_time_span;
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
        
        if (exact_time_span != null) {
            iCal.icaltimetype dtstart = {0};
            exact_time_to_ical_date_time(exact_time_span.start_exact_time, ref dtstart);
            ical_component.set_dtstart(dtstart);
            
            iCal.icaltimetype dtend = {0};
            exact_time_to_ical_date_time(exact_time_span.end_exact_time, ref dtend);
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
            get_tzname(date.earliest_exact_time(timezone), timezone));
    }
    
    private void exact_time_to_ical_date_time(Calendar.ExactTime exact_time,
        ref iCal.icaltimetype ical_date_time) {
        ical_date_time.year = exact_time.year.value;
        ical_date_time.month = exact_time.month.value;
        ical_date_time.day = exact_time.day_of_month.value;
        ical_date_time.hour = exact_time.hour;
        ical_date_time.minute = exact_time.minute;
        ical_date_time.second = exact_time.second;
        ical_date_time.is_utc = 0;
        ical_date_time.is_date = 0;
        ical_date_time.is_daylight = exact_time.is_dst ? 1 : 0;
        ical_date_time.zone = iCal.icaltimezone.get_builtin_timezone_from_tzid(
            get_tzname(exact_time, timezone));
    }
    
    private unowned string get_tzname(Calendar.ExactTime exact_time, TimeZone tz) {
        TimeType time_type = exact_time.is_dst ? TimeType.DAYLIGHT : TimeType.STANDARD;
        int interval = tz.find_interval(time_type, exact_time.to_time_t());
        
        // get abbreviation of DateTime's interval, if not available, fallback on 0 interval
        // (generally LMT)
        return (interval != -1) ? tz.get_abbreviation(interval) : tz.get_abbreviation(0);
    }
    
    public override string to_string() {
        return "(new component instance)";
    }
}

}

