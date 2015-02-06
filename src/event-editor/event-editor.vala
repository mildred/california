/* Copyright 2014-2015 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.EventEditor {

private int init_count = 0;

public void init() throws Error {
    if (!Unit.do_init(ref init_count))
        return;
    
    Toolkit.init();
    Calendar.init();
    Backing.init();
    Component.init();
    Host.init();
}

public void terminate() {
    if (!Unit.do_terminate(ref init_count))
        return;
    
    Host.terminate();
    Component.terminate();
    Backing.terminate();
    Calendar.terminate();
    Toolkit.terminate();
}

}

