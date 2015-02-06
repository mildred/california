/* Copyright 2014-2015 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Tests {

private class QuickAdd : UnitTest.Harness {
    public QuickAdd() {
        add_case("null-details", null_details);
        add_case("blank", blank);
        add_case("punct", punct);
        add_case("summary", summary);
        add_case("summary-with-blanks", summary_with_blanks);
        add_case("summary-with-punct", summary_with_punct);
        add_case("summary-location", summary_location);
        add_case("valid-no-summary", valid_no_summary);
        add_case("with-12hr-time", with_12hr_time);
        add_case("with-24hr-time", with_24hr_time);
        add_case("with-24hr-time-no-preposition", with_24hr_time_no_preposition);
        add_case("with-day-of-week", with_day_of_week);
        add_case("with-delay", with_delay);
        add_case("with-duration", with_duration);
        add_case("with-delay-and-duration", with_delay_and_duration);
        add_case("indeterminate-time", indeterminate_time);
        add_case("dialog-example", dialog_example);
        add_case("yesterday", yesterday);
        add_case("today", today);
        add_case("noon", noon);
        add_case("midnight", midnight);
        add_case("pm1230", pm1230);
        add_case("bogus-time", bogus_time);
        add_case("zero-hour", zero_hour);
        add_case("oh-twenty-four-hours", oh_twenty_four_hours);
        add_case("midnight-to-one", midnight_to_one);
        add_case("separate-am", separate_am);
        add_case("separate-pm", separate_pm);
        add_case("start-date-ordinal", start_date_ordinal);
        add_case("end-date-ordinal", end_date_ordinal);
        add_case("simple-and", simple_and);
        add_case("this-weekend", this_weekend);
        add_case("numeric-md", numeric_md);
        add_case("numeric-dm", numeric_dm);
        add_case("numeric-mdy", numeric_mdy);
        add_case("numeric-dmy", numeric_dmy);
        add_case("numeric-mdyyyy", numeric_mdyyyy);
        add_case("numeric-dmyyyy", numeric_dmyyyy);
        add_case("numeric-dot", numeric_dot);
        add_case("numeric-leading-zeros", numeric_leading_zeroes);
        add_case("street-address_3", street_address_3);
        add_case("street-address_3a", street_address_3a);
        add_case("street-address_4", street_address_4);
        add_case("time-range-both-meridiem", time_range_both_meridiem);
        add_case("time-range-one-meridiem", time_range_one_meridiem);
        add_case("time-range-24hr", time_range_24hr);
        add_case("time-range-no-meridiem", time_range_no_meridiem);
        add_case("atsign-location", atsign_location);
        add_case("atsign-time", atsign_time);
        add_case("hash-location", hash_location);
        add_case("hash-time", hash_time);
        add_case("quoted", quoted);
        add_case("open-quoted", open_quoted);
        add_case("quoted-atsign", quoted_atsign);
        add_case("quoted-hash", quoted_hash);
        add_case("ymd-dm", ymd_dm);
    }
    
    protected override void setup() throws Error {
        Component.init();
        Calendar.init();
    }
    
    protected override void teardown() {
        Component.terminate();
        Calendar.terminate();
    }
    
    // Guaranteeing a future time of day in Quick Add is tricky for a variety of reasons, but if
    // a date is specified without a year, then the DetailsParser should pick a date that is today
    // in the future
    private bool is_today_or_future(Component.Event event) {
        if (event.date_span == null && event.exact_time_span == null)
            return false;
        
        return event.get_event_date_span(Calendar.Timezone.local).start_date.compare_to(Calendar.System.today) >= 0;
    }
    
    private bool null_details() throws Error {
        Component.DetailsParser parser = new Component.DetailsParser(null, null);
        
        return !parser.event.is_valid(false);
    }
    
    private bool blank() throws Error {
        Component.DetailsParser parser = new Component.DetailsParser(" ", null);
        
        return !parser.event.is_valid(false);
    }
    
    private bool punct() throws Error {
        Component.DetailsParser parser = new Component.DetailsParser("&", null);
        
        return !parser.event.is_valid(false)
            && parser.event.summary == "&";
    }
    
    private bool summary() throws Error {
        Component.DetailsParser parser = new Component.DetailsParser("meet with Alice", null);
        
        return parser.event.summary == "meet with Alice"
            && parser.event.location == null
            && parser.event.exact_time_span == null
            && parser.event.date_span == null;
    }
    
    private bool summary_with_blanks() throws Error {
        Component.DetailsParser parser = new Component.DetailsParser("   meet  with   Alice    ", null);
        
        return parser.event.summary == "meet with Alice"
            && parser.event.location == null
            && parser.event.exact_time_span == null
            && parser.event.date_span == null;
    }
    
    private bool summary_with_punct() throws Error {
        Component.DetailsParser parser = new Component.DetailsParser("meet with Alice & Bob", null);
        
        return parser.event.summary == "meet with Alice & Bob"
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
    
    private bool valid_no_summary(out string? dump) throws Error {
        Component.DetailsParser parser = new Component.DetailsParser("7pm to 9pm", null);
        
        dump = parser.event.source;
        
        // valid but not "useful"
        return parser.event.is_valid(false)
            && !parser.event.is_valid(true)
            && California.String.is_empty(parser.event.summary)
            && parser.event.exact_time_span != null
            && is_today_or_future(parser.event);
    }
    
    private bool with_12hr_time() throws Error {
        return with_time(new Component.DetailsParser("dinner at 7pm with Alice", null));
    }
    
    private bool with_24hr_time() throws Error {
        return with_time(new Component.DetailsParser("dinner at 19:00 with Alice", null));
    }
    
    private bool with_24hr_time_no_preposition(out string? dump) throws Error {
        return with_time(new Component.DetailsParser("19:00 dinner with Alice", null), out dump);
    }
    
    private bool with_time(Component.DetailsParser parser, out string? dump = null) {
        Calendar.ExactTime time = new Calendar.ExactTime(
            Calendar.System.timezone,
            Calendar.System.today,
            new Calendar.WallTime(19, 0, 0)
        );
        
        dump = parser.event.source;
        
        return parser.event.summary == "dinner with Alice"
            && parser.event.location == null
            && parser.event.exact_time_span.start_exact_time.equal_to(time)
            && parser.event.exact_time_span.end_exact_time.equal_to(time.adjust_time(1, Calendar.TimeUnit.HOUR))
            && is_today_or_future(parser.event);
    }
    
    private bool with_day_of_week() throws Error {
        Component.DetailsParser parser = new Component.DetailsParser("dinner Monday at Bob's with Alice", null);
        
        return parser.event.summary == "dinner at Bob's with Alice"
            && parser.event.location == "Bob's with Alice"
            && parser.event.date_span.start_date.day_of_week == Calendar.DayOfWeek.MON
            && is_today_or_future(parser.event);
    }
    
    private bool with_delay() throws Error {
        Component.DetailsParser parser = new Component.DetailsParser("meet Alice in 3 hours", null);
        
        Calendar.WallTime start = Calendar.System.now.to_wall_time().adjust(3, Calendar.TimeUnit.HOUR, null);
        Calendar.WallTime end = start.adjust(1, Calendar.TimeUnit.HOUR, null);
        
        assert(parser.event.summary == "meet Alice");
        assert(parser.event.exact_time_span.start_exact_time.to_wall_time().equal_to(start));
        assert(parser.event.exact_time_span.start_exact_time.to_wall_time().adjust(1, Calendar.TimeUnit.HOUR, null).equal_to(end));
        
        return is_today_or_future(parser.event);
    }
    
    private bool with_duration() throws Error {
        Component.DetailsParser parser = new Component.DetailsParser("meet Alice for 2 hrs", null);
        
        Calendar.WallTime start = Calendar.System.now.to_wall_time();
        Calendar.WallTime end = start.adjust(2, Calendar.TimeUnit.HOUR, null);
        
        return parser.event.summary == "meet Alice"
            && parser.event.exact_time_span.start_exact_time.to_wall_time().equal_to(start)
            && parser.event.exact_time_span.end_exact_time.to_wall_time().equal_to(end)
            && is_today_or_future(parser.event);
    }
    
    private bool with_delay_and_duration() throws Error {
        Component.DetailsParser parser = new Component.DetailsParser("meet Alice in 3 hours for 30 min", null);
        
        Calendar.WallTime start = Calendar.System.now.adjust_time(3, Calendar.TimeUnit.HOUR).to_wall_time();
        Calendar.WallTime end = start.adjust(30, Calendar.TimeUnit.MINUTE, null);
        
        return parser.event.summary == "meet Alice"
            && parser.event.exact_time_span.start_exact_time.to_wall_time().equal_to(start)
            && parser.event.exact_time_span.end_exact_time.to_wall_time().equal_to(end)
            && is_today_or_future(parser.event);
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
            && parser.event.exact_time_span.end_exact_time.equal_to(time.adjust_time(1, Calendar.TimeUnit.HOUR))
            && is_today_or_future(parser.event);
    }
    
    private bool yesterday() throws Error {
        Component.DetailsParser parser = new Component.DetailsParser(
            "Dinner at Tadich Grill 7:30pm yesterday", null);
        
        Calendar.ExactTime time = new Calendar.ExactTime(
            Calendar.System.timezone,
            Calendar.System.today.previous(),
            new Calendar.WallTime(19, 30, 0)
        );
        
        return parser.event.summary == "Dinner at Tadich Grill"
            && parser.event.location == "Tadich Grill"
            && parser.event.exact_time_span.start_exact_time.equal_to(time)
            && parser.event.exact_time_span.end_exact_time.equal_to(time.adjust_time(1, Calendar.TimeUnit.HOUR))
            && !is_today_or_future(parser.event);
    }
    
    private bool today() throws Error {
        Component.DetailsParser parser = new Component.DetailsParser(
            "Dinner at Tadich Grill 7:30pm today", null);
        
        Calendar.ExactTime time = new Calendar.ExactTime(
            Calendar.System.timezone,
            Calendar.System.today,
            new Calendar.WallTime(19, 30, 0)
        );
        
        return parser.event.summary == "Dinner at Tadich Grill"
            && parser.event.location == "Tadich Grill"
            && parser.event.exact_time_span.start_exact_time.equal_to(time)
            && parser.event.exact_time_span.end_exact_time.equal_to(time.adjust_time(1, Calendar.TimeUnit.HOUR))
            && is_today_or_future(parser.event);
    }
    
    private bool noon() throws Error {
        Component.DetailsParser parser = new Component.DetailsParser(
            "Lunch noon to 1:30pm", null);
        
        Calendar.ExactTime start = new Calendar.ExactTime(Calendar.Timezone.local, Calendar.System.today,
            new Calendar.WallTime(12, 0, 0));
        Calendar.ExactTime end = new Calendar.ExactTime(Calendar.Timezone.local, Calendar.System.today,
            new Calendar.WallTime(13, 30, 0));
        
        return parser.event.summary == "Lunch"
            && parser.event.exact_time_span.start_exact_time.equal_to(start)
            && parser.event.exact_time_span.end_exact_time.equal_to(end)
            && is_today_or_future(parser.event);
    }
    
    private bool midnight() throws Error {
        Component.DetailsParser parser = new Component.DetailsParser(
            "Dinner 11pm to midnight", null);
        
        Calendar.ExactTime start = new Calendar.ExactTime(Calendar.Timezone.local, Calendar.System.today,
            new Calendar.WallTime(23, 0, 0));
        Calendar.ExactTime end = new Calendar.ExactTime(Calendar.Timezone.local, Calendar.System.today.next(),
            new Calendar.WallTime(0, 0, 0));
        
        return parser.event.summary == "Dinner"
            && parser.event.exact_time_span.start_exact_time.equal_to(start)
            && parser.event.exact_time_span.end_exact_time.equal_to(end)
            && is_today_or_future(parser.event);
    }
    
    private bool pm1230() throws Error {
        Component.DetailsParser parser = new Component.DetailsParser(
            "12:30pm Friday Lunch with Eric and Charles", null);
        
        Calendar.Date friday = Calendar.System.today.upcoming(true,
            date => date.day_of_week.equal_to(Calendar.DayOfWeek.FRI));
        
        Calendar.ExactTime start = new Calendar.ExactTime(Calendar.Timezone.local, friday,
            new Calendar.WallTime(12, 30, 0));
        Calendar.ExactTime end = new Calendar.ExactTime(Calendar.Timezone.local, friday,
            new Calendar.WallTime(13, 30, 0));
        
        return parser.event.summary == "Lunch with Eric and Charles"
            && parser.event.exact_time_span.start_exact_time.equal_to(start)
            && parser.event.exact_time_span.end_exact_time.equal_to(end)
            && is_today_or_future(parser.event);
    }
    
    private bool bogus_time() throws Error {
        Component.DetailsParser parser = new Component.DetailsParser(
            "Dinner 25:00", null);
        
        return parser.event.summary == "Dinner 25:00"
            && parser.event.exact_time_span == null
            && parser.event.date_span == null;
    }
    
    private bool zero_hour() throws Error {
        Component.DetailsParser parser = new Component.DetailsParser(
            "Dinner 00:00", null);
        
        Calendar.ExactTime start = new Calendar.ExactTime(Calendar.Timezone.local, Calendar.System.today.next(),
            new Calendar.WallTime(0, 0, 0));
        Calendar.ExactTime end = new Calendar.ExactTime(Calendar.Timezone.local, Calendar.System.today.next(),
            new Calendar.WallTime(1, 0, 0));
        
        return parser.event.summary == "Dinner"
            && parser.event.exact_time_span.start_exact_time.equal_to(start)
            && parser.event.exact_time_span.end_exact_time.equal_to(end)
            && is_today_or_future(parser.event);
    }
    
    private bool oh_twenty_four_hours() throws Error {
        Component.DetailsParser parser = new Component.DetailsParser(
            "Dinner 24:00", null);
        
        Calendar.ExactTime start = new Calendar.ExactTime(Calendar.Timezone.local, Calendar.System.today.next(),
            new Calendar.WallTime(0, 0, 0));
        Calendar.ExactTime end = new Calendar.ExactTime(Calendar.Timezone.local, Calendar.System.today.next(),
            new Calendar.WallTime(1, 0, 0));
        
        return parser.event.summary == "Dinner"
            && parser.event.exact_time_span.start_exact_time.equal_to(start)
            && parser.event.exact_time_span.end_exact_time.equal_to(end)
            && is_today_or_future(parser.event);
    }
    
    private bool midnight_to_one() throws Error {
        Component.DetailsParser parser = new Component.DetailsParser(
            "Dinner midnight to 1am", null);
        
        Calendar.ExactTime start = new Calendar.ExactTime(Calendar.Timezone.local, Calendar.System.today.next(),
            new Calendar.WallTime(0, 0, 0));
        Calendar.ExactTime end = new Calendar.ExactTime(Calendar.Timezone.local, Calendar.System.today.next(),
            new Calendar.WallTime(1, 0, 0));
        
        return parser.event.summary == "Dinner"
            && parser.event.exact_time_span.start_exact_time.equal_to(start)
            && parser.event.exact_time_span.end_exact_time.equal_to(end)
            && is_today_or_future(parser.event);
    }
    
    private bool separate_am() throws Error {
        Component.DetailsParser parser = new Component.DetailsParser(
            "Dinner at 1 pm with Denny", null);
        
        Calendar.ExactTime start = new Calendar.ExactTime(Calendar.Timezone.local, Calendar.System.today,
            new Calendar.WallTime(13, 0, 0));
        
        return parser.event.summary == "Dinner with Denny"
            && parser.event.exact_time_span.start_exact_time.equal_to(start)
            && is_today_or_future(parser.event);
    }
    
    private bool separate_pm() throws Error {
        Component.DetailsParser parser = new Component.DetailsParser(
            "Dinner at 11 am", null);
        
        Calendar.ExactTime start = new Calendar.ExactTime(Calendar.Timezone.local, Calendar.System.today,
            new Calendar.WallTime(11, 0, 0));
        
        return parser.event.summary == "Dinner"
            && parser.event.exact_time_span.start_exact_time.equal_to(start)
            && is_today_or_future(parser.event);
    }
    
    private Calendar.Date future_may(int dom) throws Error {
        Calendar.Date date = new Calendar.Date(Calendar.DayOfMonth.for(dom), Calendar.Month.MAY,
            Calendar.System.today.year);
        if (date.difference(Calendar.System.today) > 0)
            date = date.adjust_by(1, Calendar.DateUnit.YEAR);
        
        return date;
    }
    
    private bool start_date_ordinal(out string? dump) throws Error {
        Component.DetailsParser parser = new Component.DetailsParser(
            "Dinner May 1st", null);
        
        dump = parser.event.source;
        
        return parser.event.summary == "Dinner"
            && parser.event.date_span.start_date.equal_to(future_may(1))
            && is_today_or_future(parser.event);
    }
    
    private bool end_date_ordinal(out string? dump) throws Error {
        Component.DetailsParser parser = new Component.DetailsParser(
            "Off-site May 1st to May 2nd", null);
        
        dump = parser.event.source;
        
        return parser.event.summary == "Off-site"
            && parser.event.date_span.start_date.equal_to(future_may(1))
            && parser.event.date_span.end_date.equal_to(future_may(2))
            && is_today_or_future(parser.event);
    }
    
    private bool simple_and(out string? dump) throws Error {
        Component.DetailsParser parser = new Component.DetailsParser(
            "Manga & Anime Festival Saturday and Sunday at Airport Hyatt, Shelbyville", null);
        
        dump = parser.event.source;
        
        return parser.event.summary == "Manga & Anime Festival at Airport Hyatt, Shelbyville"
            && parser.event.location == "Airport Hyatt, Shelbyville"
            && parser.event.is_all_day
            && parser.event.date_span.start_date.day_of_week == Calendar.DayOfWeek.SAT
            && parser.event.date_span.end_date.day_of_week == Calendar.DayOfWeek.SUN
            && is_today_or_future(parser.event);
    }
    
    private bool this_weekend(out string? dump) throws Error {
        Component.DetailsParser parser = new Component.DetailsParser(
            "Manga & Anime Festival this weekend at Airport Hyatt, Shelbyville", null);
        
        dump = parser.event.source;
        
        return parser.event.summary == "Manga & Anime Festival at Airport Hyatt, Shelbyville"
            && parser.event.location == "Airport Hyatt, Shelbyville"
            && parser.event.is_all_day
            && parser.event.date_span.start_date.day_of_week == Calendar.DayOfWeek.SAT
            && parser.event.date_span.end_date.day_of_week == Calendar.DayOfWeek.SUN
            && is_today_or_future(parser.event);
    }
    
    private bool numeric_md(out string? dump) throws Error {
        Calendar.System.date_ordering = Calendar.DateOrdering.MDY;
        Calendar.System.date_separator = "/";
        Component.DetailsParser parser = new Component.DetailsParser(
            "7/2 Offsite", null);
        
        dump = parser.event.source;
        
        return parser.event.summary == "Offsite"
            && parser.event.is_all_day
            && parser.event.date_span.duration.days == 1
            && parser.event.date_span.start_date.month == Calendar.Month.JUL
            && parser.event.date_span.start_date.day_of_month.value == 2
            && is_today_or_future(parser.event);
    }
    
    private bool numeric_dm(out string? dump) throws Error {
        Calendar.System.date_ordering = Calendar.DateOrdering.DMY;
        Calendar.System.date_separator = "/";
        Component.DetailsParser parser = new Component.DetailsParser(
            "2/7 Offsite", null);
        
        dump = parser.event.source;
        
        return parser.event.summary == "Offsite"
            && parser.event.is_all_day
            && parser.event.date_span.duration.days == 1
            && parser.event.date_span.start_date.month == Calendar.Month.JUL
            && parser.event.date_span.start_date.day_of_month.value == 2
            && is_today_or_future(parser.event);
    }
    
    private bool numeric_mdy(out string? dump) throws Error {
        Calendar.System.date_ordering = Calendar.DateOrdering.MDY;
        Calendar.System.date_separator = "/";
        Component.DetailsParser parser = new Component.DetailsParser(
            "7/2/14 Offsite", null);
        
        dump = parser.event.source;
        
        return parser.event.summary == "Offsite"
            && parser.event.is_all_day
            && parser.event.date_span.duration.days == 1
            && parser.event.date_span.start_date.month == Calendar.Month.JUL
            && parser.event.date_span.start_date.day_of_month.value == 2
            && parser.event.date_span.start_date.year.value == 2014;
    }
    
    private bool numeric_dmy(out string? dump) throws Error {
        Calendar.System.date_ordering = Calendar.DateOrdering.DMY;
        Calendar.System.date_separator = "/";
        Component.DetailsParser parser = new Component.DetailsParser(
            "2/7/14 Offsite", null);
        
        dump = parser.event.source;
        
        return parser.event.summary == "Offsite"
            && parser.event.is_all_day
            && parser.event.date_span.duration.days == 1
            && parser.event.date_span.start_date.month == Calendar.Month.JUL
            && parser.event.date_span.start_date.day_of_month.value == 2
            && parser.event.date_span.start_date.year.value == 2014;
    }
    
    private bool numeric_mdyyyy(out string? dump) throws Error {
        Calendar.System.date_ordering = Calendar.DateOrdering.MDY;
        Calendar.System.date_separator = "/";
        Component.DetailsParser parser = new Component.DetailsParser(
            "7/2/2014 Offsite", null);
        
        dump = parser.event.source;
        
        return parser.event.summary == "Offsite"
            && parser.event.is_all_day
            && parser.event.date_span.duration.days == 1
            && parser.event.date_span.start_date.month == Calendar.Month.JUL
            && parser.event.date_span.start_date.day_of_month.value == 2
            && parser.event.date_span.start_date.year.value == 2014;
    }
    
    private bool numeric_dmyyyy(out string? dump) throws Error {
        Calendar.System.date_ordering = Calendar.DateOrdering.DMY;
        Calendar.System.date_separator = "/";
        Component.DetailsParser parser = new Component.DetailsParser(
            "2/7/2014 Offsite", null);
        
        dump = parser.event.source;
        
        return parser.event.summary == "Offsite"
            && parser.event.is_all_day
            && parser.event.date_span.duration.days == 1
            && parser.event.date_span.start_date.month == Calendar.Month.JUL
            && parser.event.date_span.start_date.day_of_month.value == 2
            && parser.event.date_span.start_date.year.value == 2014;
    }
    
    private bool numeric_dot(out string? dump) throws Error {
        Calendar.System.date_ordering = Calendar.DateOrdering.MDY;
        Calendar.System.date_separator = ".";
        Component.DetailsParser parser = new Component.DetailsParser(
            "7.2.14 Offsite", null);
        
        dump = parser.event.source;
        
        return parser.event.summary == "Offsite"
            && parser.event.is_all_day
            && parser.event.date_span.duration.days == 1
            && parser.event.date_span.start_date.month == Calendar.Month.JUL
            && parser.event.date_span.start_date.day_of_month.value == 2
            && parser.event.date_span.start_date.year.value == 2014;
    }
    
    private bool numeric_leading_zeroes(out string? dump) throws Error {
        Calendar.System.date_ordering = Calendar.DateOrdering.MDY;
        Calendar.System.date_separator = "/";
        Component.DetailsParser parser = new Component.DetailsParser(
            "07/02/14 Offsite", null);
        
        dump = parser.event.source;
        
        return parser.event.summary == "Offsite"
            && parser.event.is_all_day
            && parser.event.date_span.duration.days == 1
            && parser.event.date_span.start_date.month == Calendar.Month.JUL
            && parser.event.date_span.start_date.day_of_month.value == 2
            && parser.event.date_span.start_date.year.value == 2014;
    }
    
    private bool street_address_3(out string? dump) throws Error {
        Component.DetailsParser parser = new Component.DetailsParser(
            "6:30pm Alice at Burrito Shack, 450 Main", null);
        
        dump = parser.event.source;
        
        return parser.event.summary == "Alice at Burrito Shack, 450 Main"
            && parser.event.location == "Burrito Shack, 450 Main"
            && !parser.event.is_all_day
            && parser.event.exact_time_span.start_exact_time.hour == 18
            && parser.event.exact_time_span.start_exact_time.minute == 30
            && is_today_or_future(parser.event);
    }
    
    private bool street_address_3a(out string? dump) throws Error {
        Component.DetailsParser parser = new Component.DetailsParser(
            "Friday 6:30pm meet eric at 431 natoma", null);
        
        dump = parser.event.source;
        
        return parser.event.summary == "meet eric at 431 natoma"
            && parser.event.location == "431 natoma"
            && !parser.event.is_all_day
            && parser.event.exact_time_span.start_exact_time.hour == 18
            && parser.event.exact_time_span.start_exact_time.minute == 30
            && parser.event.exact_time_span.start_date.day_of_week == Calendar.DayOfWeek.FRI
            && parser.event.exact_time_span.duration.hours == 1
            && is_today_or_future(parser.event);
    }
    
    private bool street_address_4(out string? dump) throws Error {
        Component.DetailsParser parser = new Component.DetailsParser(
            "6:30pm Alice at Burrito Shack, 1235 Main", null);
        
        dump = parser.event.source;
        
        return parser.event.summary == "Alice at Burrito Shack, 1235 Main"
            && parser.event.location == "Burrito Shack, 1235 Main"
            && !parser.event.is_all_day
            && parser.event.exact_time_span.start_exact_time.hour == 18
            && parser.event.exact_time_span.start_exact_time.minute == 30
            && is_today_or_future(parser.event);
    }
    
    private bool test_time_range(string details, out string? dump) throws Error {
        Component.DetailsParser parser = new Component.DetailsParser(details, null);
        
        dump = parser.event.source;
        
        return parser.event.summary == "Opus Affair"
            && !parser.event.is_all_day
            && parser.event.exact_time_span.start_exact_time.hour == 18
            && parser.event.exact_time_span.start_exact_time.minute == 0
            && parser.event.exact_time_span.end_exact_time.hour == 21
            && parser.event.exact_time_span.end_exact_time.minute == 0
            && is_today_or_future(parser.event);
    }
    
    private bool time_range_both_meridiem(out string? dump) throws Error {
        return test_time_range("6p-9p Opus Affair", out dump);
    }
    
    private bool time_range_one_meridiem(out string? dump) throws Error {
        return test_time_range("6-9p Opus Affair", out dump);
    }
    
    private bool time_range_24hr(out string? dump) throws Error {
        return test_time_range("18:00-21:00 Opus Affair", out dump);
    }
    
    private bool time_range_no_meridiem(out string? dump) throws Error {
        Component.DetailsParser parser = new Component.DetailsParser(
            "6-9 Opus Affair", null);
        
        dump = parser.event.source;
        
        return parser.event.summary == "6-9 Opus Affair"
            && !parser.event.is_valid(false);
    }
    
    private bool atsign_location(out string? dump) throws Error {
        Component.DetailsParser parser = new Component.DetailsParser(
            "Dinner @ Tadich Grill 7pm", null);
        
        dump = parser.event.source;
        
        return parser.event.summary == "Dinner @ Tadich Grill"
            && parser.event.location == "Tadich Grill"
            && !parser.event.is_all_day
            && parser.event.exact_time_span.start_exact_time.hour == 19
            && parser.event.exact_time_span.start_exact_time.minute == 0
            && parser.event.exact_time_span.end_exact_time.hour == 20
            && parser.event.exact_time_span.end_exact_time.minute == 0
            && parser.event.exact_time_span.get_date_span().equal_to(Calendar.System.today.to_date_span())
            && is_today_or_future(parser.event);
    }
    
    private bool atsign_time(out string? dump) throws Error {
        Component.DetailsParser parser = new Component.DetailsParser(
            "Dinner @ 7pm", null);
        
        dump = parser.event.source;
        
        return parser.event.summary == "Dinner"
            && parser.event.location == null
            && !parser.event.is_all_day
            && parser.event.exact_time_span.start_exact_time.hour == 19
            && parser.event.exact_time_span.start_exact_time.minute == 0
            && parser.event.exact_time_span.end_exact_time.hour == 20
            && parser.event.exact_time_span.end_exact_time.minute == 0
            && parser.event.exact_time_span.get_date_span().equal_to(Calendar.System.today.to_date_span())
            && is_today_or_future(parser.event);
    }
    
    private bool hash_location(out string? dump) throws Error {
        Component.DetailsParser parser = new Component.DetailsParser(
            "Dinner # Tadich Grill 7pm", null);
        
        dump = parser.event.source;
        
        return parser.event.summary == "Dinner"
            && parser.event.location == "Tadich Grill"
            && !parser.event.is_all_day
            && parser.event.exact_time_span.start_exact_time.hour == 19
            && parser.event.exact_time_span.start_exact_time.minute == 0
            && parser.event.exact_time_span.end_exact_time.hour == 20
            && parser.event.exact_time_span.end_exact_time.minute == 0
            && parser.event.exact_time_span.get_date_span().equal_to(Calendar.System.today.to_date_span())
            && is_today_or_future(parser.event);
    }
    
    private bool hash_time(out string? dump) throws Error {
        Component.DetailsParser parser = new Component.DetailsParser(
            "Dinner # 7pm", null);
        
        dump = parser.event.source;
        
        return parser.event.summary == "Dinner"
            && parser.event.location == null
            && !parser.event.is_all_day
            && parser.event.exact_time_span.start_exact_time.hour == 19
            && parser.event.exact_time_span.start_exact_time.minute == 0
            && parser.event.exact_time_span.end_exact_time.hour == 20
            && parser.event.exact_time_span.end_exact_time.minute == 0
            && parser.event.exact_time_span.get_date_span().equal_to(Calendar.System.today.to_date_span())
            && is_today_or_future(parser.event);
    }
    
    private bool quoted(out string? dump) throws Error {
        Component.DetailsParser parser = new Component.DetailsParser(
            "\"Live at Budokon\" at The Roxy 7pm", null);
        
        dump = parser.event.source;
        
        return parser.event.summary == "\"Live at Budokon\" at The Roxy"
            && parser.event.location == "The Roxy"
            && !parser.event.is_all_day
            && parser.event.exact_time_span.start_exact_time.hour == 19
            && parser.event.exact_time_span.start_exact_time.minute == 0
            && parser.event.exact_time_span.end_exact_time.hour == 20
            && parser.event.exact_time_span.end_exact_time.minute == 0
            && parser.event.exact_time_span.get_date_span().equal_to(Calendar.System.today.to_date_span())
            && is_today_or_future(parser.event);
    }
    
    private bool open_quoted(out string? dump) throws Error {
        Component.DetailsParser parser = new Component.DetailsParser(
            "\"Live at Budokon", null);
        
        dump = parser.event.source;
        
        return parser.event.summary == "\"Live at Budokon"
            && parser.event.location == null;
    }
    
    private bool quoted_atsign(out string? dump) throws Error {
        Component.DetailsParser parser = new Component.DetailsParser(
            "\"Live at Budokon\" @ The Roxy 7pm", null);
        
        dump = parser.event.source;
        
        return parser.event.summary == "\"Live at Budokon\" @ The Roxy"
            && parser.event.location == "The Roxy"
            && !parser.event.is_all_day
            && parser.event.exact_time_span.start_exact_time.hour == 19
            && parser.event.exact_time_span.start_exact_time.minute == 0
            && parser.event.exact_time_span.end_exact_time.hour == 20
            && parser.event.exact_time_span.end_exact_time.minute == 0
            && parser.event.exact_time_span.get_date_span().equal_to(Calendar.System.today.to_date_span())
            && is_today_or_future(parser.event);
    }
    
    private bool quoted_hash(out string? dump) throws Error {
        Component.DetailsParser parser = new Component.DetailsParser(
            "\"Live at Budokon\" # The Roxy 7pm", null);
        
        dump = parser.event.source;
        
        return parser.event.summary == "\"Live at Budokon\""
            && parser.event.location == "The Roxy"
            && !parser.event.is_all_day
            && parser.event.exact_time_span.start_exact_time.hour == 19
            && parser.event.exact_time_span.start_exact_time.minute == 0
            && parser.event.exact_time_span.end_exact_time.hour == 20
            && parser.event.exact_time_span.end_exact_time.minute == 0
            && parser.event.exact_time_span.get_date_span().equal_to(Calendar.System.today.to_date_span())
            && is_today_or_future(parser.event);
    }
    
    // See https://bugzilla.gnome.org/show_bug.cgi?id=735096
    private bool ymd_dm(out string? dump) throws Error {
        Calendar.DateOrdering saved = Calendar.System.date_ordering;
        Calendar.System.date_ordering = Calendar.DateOrdering.YMD;
        
        Component.DetailsParser parser = new Component.DetailsParser(
            "Meeting at 9/6", null);
        
        Calendar.System.date_ordering = saved;
        
        dump = parser.event.source;
        
        return parser.event.summary == "Meeting"
            && California.String.is_empty(parser.event.location)
            && parser.event.is_all_day
            && parser.event.date_span.start_date.day_of_month.value == 9
            && parser.event.date_span.start_date.month.value == 6
            && is_today_or_future(parser.event);
    }
}

}

