/* Copyright 2014-2015 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Tests {

private class CalendarMonthOfYear : UnitTest.Harness {
    public CalendarMonthOfYear() {
        add_case("difference-same", difference_same);
        add_case("difference-negative", difference_negative);
        add_case("difference-positive", difference_positive);
    }
    
    protected override void setup() throws Error {
        Calendar.init();
    }
    
    protected override void teardown() {
        Calendar.terminate();
    }
    
    private bool difference_same() throws Error {
        Calendar.MonthOfYear jan = new Calendar.MonthOfYear(Calendar.Month.JAN, new Calendar.Year(2014));
        Calendar.MonthOfYear jan2 = new Calendar.MonthOfYear(Calendar.Month.JAN, new Calendar.Year(2014));
        
        return jan.difference(jan2) == 0;
    }
    
    private bool difference_negative() throws Error {
        Calendar.MonthOfYear jan = new Calendar.MonthOfYear(Calendar.Month.JAN, new Calendar.Year(2014));
        Calendar.MonthOfYear dec = new Calendar.MonthOfYear(Calendar.Month.DEC, new Calendar.Year(2013));
        
        return jan.difference(dec) == -1;
    }
    
    private bool difference_positive() throws Error {
        Calendar.MonthOfYear jan = new Calendar.MonthOfYear(Calendar.Month.JAN, new Calendar.Year(2014));
        Calendar.MonthOfYear feb = new Calendar.MonthOfYear(Calendar.Month.FEB, new Calendar.Year(2014));
        
        return jan.difference(feb) == 1;
    }
}

}

