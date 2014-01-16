/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Backing {

/**
 * An abstract representation of a backing source of calendar information.
 *
 * @see Manager
 * @see Source
 */

public abstract class CalendarSource : Source {
    protected CalendarSource(string desc) {
        base (desc);
    }
}

}

