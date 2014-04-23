/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

/**
 * A grab bag of utility classes for working with GTK.
 */

namespace California.Toolkit {

private int init_count = 0;

public void init() throws Error {
    if (!Unit.do_init(ref init_count))
        return;
    
    Calendar.init();
}

public void terminate() {
    if (!Unit.do_terminate(ref init_count))
        return;
    
    Calendar.terminate();
}

/**
 * Spin the GTK event loop until all pending events are completed.
 */
public void spin_event_loop() {
    while (Gtk.events_pending())
        Gtk.main_iteration();
}

}
