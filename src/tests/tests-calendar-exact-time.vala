/* Copyright 2014-2015 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Tests {

internal class CalendarExactTime : UnitTest.Harness {
    private Calendar.ExactTime? now;
    private Calendar.ExactTime? past;
    private Calendar.ExactTime? future;
    
    public CalendarExactTime() {
        add_case("clamp-floor-unaltered", clamp_floor_unaltered);
        add_case("clamp-floor-altered", clamp_floor_altered);
        add_case("clamp-ceiling-unaltered", clamp_ceiling_unaltered);
        add_case("clamp-ceiling-altered", clamp_ceiling_altered);
        add_case("clamp-both-unaltered", clamp_both_unaltered);
        add_case("clamp-both-altered", clamp_both_altered);
    }
    
    protected override void setup() throws Error {
        Calendar.init();
        
        now = Calendar.System.now;
        past = now.adjust_time(-1, Calendar.TimeUnit.MINUTE);
        future = now.adjust_time(1, Calendar.TimeUnit.MINUTE);
    }
    
    protected override void teardown() {
        now = past = future = null;
        
        Calendar.terminate();
    }
    
    private bool clamp_floor_unaltered() throws Error {
        return now.clamp(past, null).equal_to(now);
    }
    
    private bool clamp_floor_altered() throws Error {
        return now.clamp(future, null).equal_to(future);
    }
    
    private bool clamp_ceiling_unaltered() throws Error {
        return now.clamp(null, future).equal_to(now);
    }
    
    private bool clamp_ceiling_altered() throws Error {
        return now.clamp(null, past).equal_to(past);
    }
    
    private bool clamp_both_unaltered() throws Error {
        return now.clamp(past, future).equal_to(now);
    }
    
    private bool clamp_both_altered() throws Error {
        return now.clamp(past, past).equal_to(past);
    }
}

}

