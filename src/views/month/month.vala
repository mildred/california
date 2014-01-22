/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

/**
 * Views for displaying calendar information by the month.
 */

namespace California.Views.Month {

private int init_count = 0;

public void init() throws Error {
    if (!Unit.do_init(ref init_count))
        return;
    
    // unit initialization
    Calendar.init();
    Component.init();
    
    // internal initialization
    Cell.init();
}

public void terminate() {
    if (!Unit.do_terminate(ref init_count))
        return;
    
    Cell.terminate();
    
    Component.terminate();
    Calendar.terminate();
}

}
