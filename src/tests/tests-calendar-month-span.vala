/* Copyright 2014-2015 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Tests {

private class CalendarMonthSpan : UnitTest.Harness {
    public CalendarMonthSpan() {
        add_case("todays-month", todays_month);
        add_case("contains-date", contains_date);
        add_case("has-month", has_month);
        add_case("iterator", iterator);
        add_case("in-operator", in_operator);
    }
    
    protected override void setup() throws Error {
        Calendar.init();
    }
    
    protected override void teardown() {
        Calendar.terminate();
    }
    
    private Calendar.Date from_today(int days) {
        return Calendar.System.today.adjust(days);
    }
    
    private bool todays_month() throws Error {
        Calendar.MonthSpan span = new Calendar.MonthSpan.from_span(
            new Calendar.DateSpan(from_today(0), from_today(0)));
        
        return span.first.equal_to(Calendar.System.today.month_of_year())
            && span.last.equal_to(Calendar.System.today.month_of_year());
    }
    
    private bool contains_date() throws Error {
        Calendar.Date first = new Calendar.Date(Calendar.DayOfMonth.for_checked(1), Calendar.Month.JAN, new Calendar.Year(2014));
        Calendar.Date last = new Calendar.Date(Calendar.DayOfMonth.for_checked(30), Calendar.Month.JAN, new Calendar.Year(2014));
        Calendar.MonthSpan span = new Calendar.MonthSpan.from_span(new Calendar.DateSpan(first, last));
        
        return span.has_date(first.adjust(15));
    }
    
    private bool has_month() throws Error {
        Calendar.Date first = new Calendar.Date(Calendar.DayOfMonth.for_checked(1), Calendar.Month.JAN, new Calendar.Year(2014));
        Calendar.Date last = new Calendar.Date(Calendar.DayOfMonth.for_checked(30), Calendar.Month.MAR, new Calendar.Year(2014));
        Calendar.MonthSpan span = new Calendar.MonthSpan.from_span(new Calendar.DateSpan(first, last));
        
        return span.contains(new Calendar.MonthOfYear(Calendar.Month.FEB, new Calendar.Year(2014)));
    }
    
    private bool iterator() throws Error {
        Calendar.Date first = new Calendar.Date(Calendar.DayOfMonth.for_checked(1), Calendar.Month.JAN, new Calendar.Year(2014));
        Calendar.Date last = new Calendar.Date(Calendar.DayOfMonth.for_checked(30), Calendar.Month.JUN, new Calendar.Year(2014));
        Calendar.MonthSpan span = new Calendar.MonthSpan.from_span(new Calendar.DateSpan(first, last));
        
        Calendar.Month[] months = {
            Calendar.Month.JAN,
            Calendar.Month.FEB,
            Calendar.Month.MAR,
            Calendar.Month.APR,
            Calendar.Month.MAY,
            Calendar.Month.JUN,
        };
        
        int ctr = 0;
        foreach (Calendar.MonthOfYear moy in span) {
            if (moy.month != months[ctr++])
                return false;
            
            if (moy.year.value != 2014)
                return false;
        }
        
        return ctr == 6;
    }
    
    private bool in_operator() throws Error {
        Calendar.Date first = new Calendar.Date(Calendar.DayOfMonth.for_checked(1), Calendar.Month.JAN, new Calendar.Year(2014));
        Calendar.Date last = new Calendar.Date(Calendar.DayOfMonth.for_checked(30), Calendar.Month.MAR, new Calendar.Year(2014));
        Calendar.MonthSpan span = new Calendar.MonthSpan.from_span(new Calendar.DateSpan(first, last));
        Calendar.MonthOfYear month = new Calendar.MonthOfYear(Calendar.Month.FEB, new Calendar.Year(2014));
        
        return month in span;
    }
}

}

