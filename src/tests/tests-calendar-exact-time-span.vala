/* Copyright 2014-2015 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Tests {

internal class CalendarExactTimeSpan : UnitTest.Harness {
    public CalendarExactTimeSpan() {
        add_case("coincide-true", coincide_true);
        add_case("coincide-true-reversed", coincide_true_reversed);
        add_case("coincide-false", coincide_false);
        add_case("coincide-false-reversed", coincide_false_reversed);
        add_case("coincide-end-start-same", coincide_end_start_same);
        add_case("coincide-start-end-same", coincide_start_end_same);
        add_case("coincide-same", coincide_same);
    }
    
    protected override void setup() throws Error {
        Calendar.init();
    }
    
    protected override void teardown() {
        Calendar.terminate();
    }
    
    private Calendar.ExactTime mktime(string str) {
        Calendar.WallTime? wall_time = Calendar.WallTime.parse(str, null);
        assert(wall_time != null);
        
        return new Calendar.ExactTime(Calendar.Timezone.local, Calendar.System.today, wall_time);
    }
    
    private Calendar.ExactTimeSpan mkspan(string start, string end) {
        return new Calendar.ExactTimeSpan(mktime(start), mktime(end));
    }
    
    private bool coincide_true() throws Error {
        return mkspan("1pm", "2pm").coincides_with(mkspan("1:30pm", "2:30pm"));
    }
    
    private bool coincide_true_reversed() throws Error {
        return mkspan("1:30pm", "2:30pm").coincides_with(mkspan("1pm", "2pm"));
    }
    
    private bool coincide_false() throws Error {
        return !mkspan("1pm", "2pm").coincides_with(mkspan("2:30pm", "3:30pm"));
    }
    
    private bool coincide_false_reversed() throws Error {
        return !mkspan("2:30pm", "3:30pm").coincides_with(mkspan("1pm", "2pm"));
    }
    
    private bool coincide_end_start_same() throws Error {
        return !mkspan("1pm", "2pm").coincides_with(mkspan("2pm", "3pm"));
    }
    
    private bool coincide_start_end_same() throws Error {
        return !mkspan("2pm", "3pm").coincides_with(mkspan("1pm", "2pm"));
    }
    
    private bool coincide_same() throws Error {
        return mkspan("2pm", "3pm").coincides_with(mkspan("2pm", "3pm"));
    }
}

}

