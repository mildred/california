/* Copyright 2014-2015 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

/**
 * The Calendar Manager, an interactive window for the user to add, configure, and remove
 * calendar subscriptions.
 */

namespace California.Manager {

private int init_count = 0;

public void init() throws Error {
    if (!Unit.do_init(ref init_count))
        return;
    
    Backing.init();
    Toolkit.init();
}

public void terminate() {
    if (!Unit.do_terminate(ref init_count))
        return;
    
    Backing.terminate();
    Toolkit.terminate();
}

}
