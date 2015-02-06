/* Copyright 2014-2015 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

/**
 * Views for displaying calendar information by the week.
 */

namespace California.View.Week {

private int init_count = 0;

public void init() throws Error {
    if (!Unit.do_init(ref init_count))
        return;
    
    // unit initialization
    Calendar.init();
    Backing.init();
    Component.init();
    Toolkit.init();
    View.Common.init();
}

public void terminate() {
    if (!Unit.do_terminate(ref init_count))
        return;
    
    View.Common.terminate();
    Toolkit.terminate();
    Component.terminate();
    Backing.terminate();
    Calendar.terminate();
}

}

