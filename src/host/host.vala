/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

/**
 * The application host (or controller).
 *
 * Host's concerns are to present and manipulate {@link View}s and offer common services to them.
 */

namespace California.Host {

private int init_count = 0;

public void init() throws Error {
    if (!Unit.do_init(ref init_count))
        return;
    
    // unit initialization
    View.init();
    Backing.init();
    Calendar.init();
}

public void terminate() {
    if (!Unit.do_terminate(ref init_count))
        return;
    
    View.terminate();
    Backing.terminate();
    Calendar.terminate();
}

}

