/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Tests {

private class QuickAdd : UnitTest.Harness {
    public QuickAdd() {
        add_case("summary", summary);
        add_case("summary-location", summary_location);
        add_case("with-12hr-time", with_12hr_time);
        add_case("with-24hr-time", with_24hr_time);
        add_case("with-day-of-week", with_day_of_week);
        add_case("with-delay", with_delay);
        add_case("with-duration", with_duration);
        add_case("with-delay-and-duration", with_delay_and_duration);
        add_case("indeterminate-time", indeterminate_time);
        add_case("dialog-example", dialog_example);
    }
    
    protected override void setup() throws Error {
        Component.init();
        Calendar.init();
    }
    
    protected override void teardown() {
        Component.terminate();
        Calendar.terminate();
    }
    
    private bool summary() throws Error {
        Component.DetailsParser parser = new Component.DetailsParser("meet with Alice", null);
        
        return parser.event.summary == "meet with Alice"
            && parser.event.location == null
            && parser.event.exact_time_span == null
            && parser.event.date_span == null;
    }
    
    private bool summary_location() throws Error {
        Component.DetailsParser parser = new Component.DetailsParser("meet with Alice at Bob's", null);
        
        return parser.event.summary == "meet with Alice at Bob's"
            && parser.event.location == "Bob's"
            && parser.event.exact_time_span == null
            && parser.event.date_span == null;
    }
    
    private bool with_12hr_time() throws Error {
        return with_time(new Component.DetailsParser("dinner at 7pm with Alice", null));
    }
    
    private bool with_24hr_time() throws Error {
        return with_time(new Component.DetailsParser("dinner at 1900 with Alice", null));
    }
    
    private bool with_time(Component.DetailsParser parser) {
        Calendar.ExactTime time = new Calendar.ExactTime(
            Calendar.System.timezone,
            Calendar.System.today,
            new Calendar.WallTime(19, 0, 0)
        );
        
        return parser.event.summary == "dinner with Alice"
            && parser.event.location == null
            && parser.event.exact_time_span.start_exact_time.equal_to(time)
            && parser.event.exact_time_span.end_exact_time.equal_to(time.adjust_time(1, Calendar.TimeUnit.HOUR));
    }
    
    private bool with_day_of_week() throws Error {
        Component.DetailsParser parser = new Component.DetailsParser("dinner Monday at Bob's with Alice", null);
        
        return parser.event.summary == "dinner at Bob's with Alice"
            && parser.event.location == "Bob's with Alice"
            && parser.event.date_span.start_date.day_of_week == Calendar.DayOfWeek.MON;
    }
    
    private bool with_delay() throws Error {
        Component.DetailsParser parser = new Component.DetailsParser("meet Alice in 3 hours", null);
        
        Calendar.WallTime start = new Calendar.WallTime.from_exact_time(Calendar.System.now).adjust(
            3, Calendar.TimeUnit.HOUR, null);
        Calendar.WallTime end = start.adjust(1, Calendar.TimeUnit.HOUR, null);
        
        assert(parser.event.summary == "meet Alice");
        assert(new Calendar.WallTime.from_exact_time(parser.event.exact_time_span.start_exact_time).equal_to(start));
        assert(new Calendar.WallTime.from_exact_time(
                parser.event.exact_time_span.start_exact_time).adjust(1, Calendar.TimeUnit.HOUR, null).equal_to(end));
        
        return true;
    }
    
    private bool with_duration() throws Error {
        Component.DetailsParser parser = new Component.DetailsParser("meet Alice for 2 hrs", null);
        
        Calendar.WallTime start = new Calendar.WallTime.from_exact_time(Calendar.System.now);
        Calendar.WallTime end = start.adjust(2, Calendar.TimeUnit.HOUR, null);
        
        return parser.event.summary == "meet Alice"
            && new Calendar.WallTime.from_exact_time(parser.event.exact_time_span.start_exact_time).equal_to(start)
            && new Calendar.WallTime.from_exact_time(parser.event.exact_time_span.end_exact_time).equal_to(end);
    }
    
    private bool with_delay_and_duration() throws Error {
        Component.DetailsParser parser = new Component.DetailsParser("meet Alice in 3 hours for 30 min", null);
        
        Calendar.WallTime start = new Calendar.WallTime.from_exact_time(Calendar.System.now.adjust_time(3, Calendar.TimeUnit.HOUR));
        Calendar.WallTime end = start.adjust(30, Calendar.TimeUnit.MINUTE, null);
        
        return parser.event.summary == "meet Alice"
            && new Calendar.WallTime.from_exact_time(parser.event.exact_time_span.start_exact_time).equal_to(start)
            && new Calendar.WallTime.from_exact_time(parser.event.exact_time_span.end_exact_time).equal_to(end);
    }
    
    private bool indeterminate_time() throws Error {
        Component.DetailsParser parser = new Component.DetailsParser("meet Alice 4", null);
        
        return parser.event.summary == "meet Alice 4"
            && parser.event.exact_time_span == null
            && parser.event.date_span == null;
    }
    
    private bool dialog_example() throws Error {
        Component.DetailsParser parser = new Component.DetailsParser(
            "Dinner at Tadich Grill 7:30pm tomorrow", null);
        
        Calendar.ExactTime time = new Calendar.ExactTime(
            Calendar.System.timezone,
            Calendar.System.today.next(),
            new Calendar.WallTime(19, 30, 0)
        );
        
        return parser.event.summary == "Dinner at Tadich Grill"
            && parser.event.location == "Tadich Grill"
            && parser.event.exact_time_span.start_exact_time.equal_to(time)
            && parser.event.exact_time_span.end_exact_time.equal_to(time.adjust_time(1, Calendar.TimeUnit.HOUR));
    }
}

}

