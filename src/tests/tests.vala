/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Tests {

public int run(string[] args) {
    UnitTest.Harness.register(new QuickAdd());
    UnitTest.Harness.register(new CalendarDate());
    UnitTest.Harness.register(new CalendarMonthSpan());
    UnitTest.Harness.register(new CalendarMonthOfYear());
    
    return UnitTest.Harness.exec_all();
}

}

