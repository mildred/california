/* Copyright 2014-2015 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Tests {

internal class CalendarWallTime : UnitTest.Harness {
    public CalendarWallTime() {
        add_case("round-zero", round_zero);
        add_case("round-down-hour-no-change", round_down_hour_no_change);
        add_case("round-down-hour-change", round_down_hour_change);
        add_case("round-down-minute", round_down_minute);
        add_case("round-down-second", round_down_second);
        add_case("round-down-no-rollover", round_down_no_rollover);
        add_case("round-up-hour-no-change", round_up_hour_no_change);
        add_case("round-up-hour-change", round_up_hour_change);
        add_case("round-up-minute", round_up_minute);
        add_case("round-up-second", round_up_second);
        add_case("round-up-rollover", round_up_rollover);
    }
    
    protected override void setup() throws Error {
        Calendar.init();
    }
    
    protected override void teardown() {
        Calendar.terminate();
    }
    
    private bool round_zero() throws Error {
        Calendar.WallTime wall_time = new Calendar.WallTime(10, 12, 14);
        bool rollover;
        Calendar.WallTime rounded = wall_time.round(0, Calendar.TimeUnit.HOUR, out rollover);
        
        return !rollover && wall_time.equal_to(rounded);
    }
    
    private bool round_down_hour_no_change() throws Error {
        Calendar.WallTime wall_time = new Calendar.WallTime(10, 12, 14);
        bool rollover;
        Calendar.WallTime round_down = wall_time.round(-2, Calendar.TimeUnit.HOUR, out rollover);
        
        return !rollover && round_down.hour == 10 && round_down.minute == 0 && round_down.second == 0;
    }
    
    private bool round_down_hour_change() throws Error {
        Calendar.WallTime wall_time = new Calendar.WallTime(9, 12, 14);
        bool rollover;
        Calendar.WallTime round_down = wall_time.round(-2, Calendar.TimeUnit.HOUR, out rollover);
        
        return !rollover && round_down.hour == 8 && round_down.minute == 0 && round_down.second == 0;
    }
    
    private bool round_down_minute() throws Error {
        Calendar.WallTime wall_time = new Calendar.WallTime(10, 12, 14);
        bool rollover;
        Calendar.WallTime round_down = wall_time.round(-10, Calendar.TimeUnit.MINUTE, out rollover);
        
        return !rollover && round_down.hour == 10 && round_down.minute == 10 && round_down.second == 0;
    }
    
    private bool round_down_second() throws Error {
        Calendar.WallTime wall_time = new Calendar.WallTime(10, 12, 16);
        bool rollover;
        Calendar.WallTime round_down = wall_time.round(-15, Calendar.TimeUnit.SECOND, out rollover);
        
        return !rollover && round_down.hour == 10 && round_down.minute == 12 && round_down.second == 15;
    }
    
    private bool round_down_no_rollover() throws Error {
        Calendar.WallTime wall_time = Calendar.WallTime.earliest;
        bool rollover;
        Calendar.WallTime round_down = wall_time.round(-15, Calendar.TimeUnit.SECOND, out rollover);
        
        return !rollover && round_down.equal_to(wall_time);
    }
    
    private bool round_up_hour_no_change() throws Error {
        Calendar.WallTime wall_time = new Calendar.WallTime(10, 12, 14);
        bool rollover;
        Calendar.WallTime round_up = wall_time.round(2, Calendar.TimeUnit.HOUR, out rollover);
        
        return !rollover && round_up.hour == 10 && round_up.minute == 0 && round_up.second == 0;
    }
    
    private bool round_up_hour_change() throws Error {
        Calendar.WallTime wall_time = new Calendar.WallTime(9, 12, 14);
        bool rollover;
        Calendar.WallTime round_up = wall_time.round(2, Calendar.TimeUnit.HOUR, out rollover);
        
        return !rollover && round_up.hour == 10 && round_up.minute == 0 && round_up.second == 0;
    }
    
    private bool round_up_minute() throws Error {
        Calendar.WallTime wall_time = new Calendar.WallTime(10, 12, 14);
        bool rollover;
        Calendar.WallTime round_up = wall_time.round(10, Calendar.TimeUnit.MINUTE, out rollover);
        
        return !rollover && round_up.hour == 10 && round_up.minute == 20 && round_up.second == 0;
    }
    
    private bool round_up_second() throws Error {
        Calendar.WallTime wall_time = new Calendar.WallTime(10, 12, 16);
        bool rollover;
        Calendar.WallTime round_up = wall_time.round(15, Calendar.TimeUnit.SECOND, out rollover);
        
        return !rollover && round_up.hour == 10 && round_up.minute == 12 && round_up.second == 30;
    }
    
    private bool round_up_rollover() throws Error {
        Calendar.WallTime wall_time = new Calendar.WallTime(23, 55, 16);
        bool rollover;
        Calendar.WallTime round_up = wall_time.round(15, Calendar.TimeUnit.MINUTE, out rollover);
        
        return rollover && round_up.hour == 0 && round_up.minute == 0 && round_up.second == 0;
    }
}

}

