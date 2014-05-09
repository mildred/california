/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Tests {

private class CalendarDate : UnitTest.Harness {
    public CalendarDate() {
        add_case("clamp-start", clamp_start);
        add_case("clamp-end", clamp_end);
        add_case("clamp-both", clamp_both);
        add_case("clamp-neither", clamp_neither);
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
    
    private Calendar.DateSpan span_from_today(int start_days, int end_days) {
        return new Calendar.DateSpan(from_today(start_days), from_today(end_days));
    }
    
    private bool clamp_start() throws Error {
        Calendar.DateSpan span = span_from_today(0, 5);
        Calendar.DateSpan clamp = span_from_today(1, 5);
        Calendar.DateSpan adj = span.clamp_between(clamp);
        
        return adj.start_date.equal_to(clamp.start_date) && adj.end_date.equal_to(span.end_date);
    }
    
    private bool clamp_end() throws Error {
        Calendar.DateSpan span = span_from_today(0, 5);
        Calendar.DateSpan clamp = span_from_today(0, 4);
        Calendar.DateSpan adj = span.clamp_between(clamp);
        
        return adj.start_date.equal_to(span.start_date) && adj.end_date.equal_to(clamp.end_date);
    }
    
    private bool clamp_both() throws Error {
        Calendar.DateSpan span = span_from_today(0, 5);
        Calendar.DateSpan clamp = span_from_today(1, 4);
        Calendar.DateSpan adj = span.clamp_between(clamp);
        
        return adj.start_date.equal_to(clamp.start_date) && adj.end_date.equal_to(clamp.end_date);
    }
    
    private bool clamp_neither() throws Error {
        Calendar.DateSpan span = span_from_today(0, 5);
        Calendar.DateSpan clamp = span_from_today(-1, 6);
        Calendar.DateSpan adj = span.clamp_between(clamp);
        
        return adj.start_date.equal_to(span.start_date) && adj.end_date.equal_to(span.end_date);
    }
}

}

