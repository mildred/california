/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California {

/**
 * A base class for debugging and monitoring.
 */

public abstract class BaseObject : Object {
    public BaseObject() {
    }
    
    /**
     * Returns a string representation of the object ''for debugging and logging only''.
     *
     * String conversion for other purposes (user labels, serialization, etc.) should be handled
     * by other appropriately-named methods.
     */
    public abstract string to_string();
}

}

