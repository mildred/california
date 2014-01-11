/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

/**
 * Calendar data modeling.
 *
 * Most of the classes here are immutable and defined as GObjects to make them easier to use in
 * Vala and with support libraries.  The "core" logic relies heavily on GLib's Date, Time, and
 * DateTime classes.
 */

namespace California.Calendar {

private int init_count = 0;

public void init() {
    if (init_count++ > 0)
        return;
    
    DayOfWeek.init();
    DayOfMonth.init();
    Month.init();
}

public void terminate() {
    if (--init_count > 0)
        return;
    
    Month.terminate();
    DayOfMonth.terminate();
    DayOfWeek.terminate();
}

}
