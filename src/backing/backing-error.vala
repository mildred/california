/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Backing {

/**
 * {@link Backing}-specific error conditions.
 */

public errordomain BackingError {
    /**
     * The method or object is unavailable due to a state change (not open or removed).
     */
    UNAVAILABLE
}

}

