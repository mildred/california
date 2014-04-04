/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California {

/**
 * A {@link Mutable} is an Object which can internally change state (i.e. is no immutable).
 */

public interface Mutable : Object {
    /**
     * Fired when important internal state has changed.
     *
     * This can be used by collections and other containers to update their own state, such as
     * re-sorting or re-applying filters.
     */
    public signal void mutated();
}

}

