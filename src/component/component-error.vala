/* Copyright 2014-2015 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California {

/**
 * Errors related to the iCalendar component implementation.
 */

public errordomain ComponentError {
    /**
     * An invalid value or out-of-bounds error.
     */
    INVALID,
    /**
     * A mismatch of some kind (DATE for DATE-TIME, etc.)
     */
    MISMATCH,
    /**
     * A value, parameter, or property is unavailable.
     */
    UNAVAILABLE
}

}

