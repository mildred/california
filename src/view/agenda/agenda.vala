/* Copyright 2014-2015 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.View.Agenda {

private int init_count = 0;

public void init() throws Error {
    if (!Unit.do_init(ref init_count))
        return;
    
    Toolkit.init();
    Calendar.init();
    
    // internal unit init
    DateRow.init();
    EventRow.init();
}

public void terminate() {
    if (!Unit.do_terminate(ref init_count))
        return;
    
    EventRow.terminate();
    DateRow.terminate();
    
    Calendar.terminate();
    Toolkit.terminate();
}

}

