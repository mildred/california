/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

/**
 * A simplified data model of the iCalendar component scheme.
 *
 * This model is intended to limit the exposure of libical to the rest of the application, while
 * also GObject-ifying it and making its information available in a Vala-friendly manner.
 *
 * See [[https://tools.ietf.org/html/rfc5545]]
 */

namespace California.Component {

private int init_count = 0;

public void init() throws Error {
    if (!Unit.do_init(ref init_count))
        return;
    
    // external unit init
    Calendar.init();
}

public void terminate() {
    if (!Unit.do_terminate(ref init_count))
        return;
    
    Calendar.terminate();
}

}

