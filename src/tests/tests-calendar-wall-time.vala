/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Tests {

internal class CalendarWallTime : UnitTest.Harness {
    public CalendarWallTime() {
        add_case("round-down-perverse", round_down_perverse);
        add_case("round-down-zero", round_down_zero);
        add_case("round-down-hour-no-change", round_down_hour_no_change);
        add_case("round-down-hour-change", round_down_hour_change);
        add_case("round-down-minute", round_down_minute);
        add_case("round-down-second", round_down_second);
    }
    
    protected override void setup() throws Error {
        Calendar.init();
    }
    
    protected override void teardown() {
        Calendar.terminate();
    }
    
    private bool round_down_perverse() throws Error {
        Calendar.WallTime wall_time = new Calendar.WallTime(10, 12, 14);
        Calendar.WallTime round_down = wall_time.round_down(-1, Calendar.TimeUnit.MINUTE);
        
        return wall_time.equal_to(round_down);
    }
    
    private bool round_down_zero() throws Error {
        Calendar.WallTime wall_time = new Calendar.WallTime(10, 12, 14);
        Calendar.WallTime round_down = wall_time.round_down(0, Calendar.TimeUnit.HOUR);
        
        return wall_time.equal_to(round_down);
    }
    
    private bool round_down_hour_no_change() throws Error {
        Calendar.WallTime wall_time = new Calendar.WallTime(10, 12, 14);
        Calendar.WallTime round_down = wall_time.round_down(2, Calendar.TimeUnit.HOUR);
        
        return round_down.hour == 10 && round_down.minute == 0 && round_down.second == 0;
    }
    
    private bool round_down_hour_change() throws Error {
        Calendar.WallTime wall_time = new Calendar.WallTime(9, 12, 14);
        Calendar.WallTime round_down = wall_time.round_down(2, Calendar.TimeUnit.HOUR);
        
        return round_down.hour == 8 && round_down.minute == 0 && round_down.second == 0;
    }
    
    private bool round_down_minute() throws Error {
        Calendar.WallTime wall_time = new Calendar.WallTime(10, 12, 14);
        Calendar.WallTime round_down = wall_time.round_down(10, Calendar.TimeUnit.MINUTE);
        
        return round_down.hour == 10 && round_down.minute == 10 && round_down.second == 0;
    }
    
    private bool round_down_second() throws Error {
        Calendar.WallTime wall_time = new Calendar.WallTime(10, 12, 16);
        Calendar.WallTime round_down = wall_time.round_down(15, Calendar.TimeUnit.SECOND);
        
        return round_down.hour == 10 && round_down.minute == 12 && round_down.second == 15;
    }
}

}

