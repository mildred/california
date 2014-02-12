/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Collection {

/**
 * A simple interface for a class that wants to expose read-only iteration of contained elements.
 *
 * Vala's foreach keyword requires only that an object offer an {@link iterator} method that
 * returns an object with next() and get() methods.  SimpleIterable merely guarantees the former.
 *
 * @see SimpleIterator
 */

public interface SimpleIterable<G> : BaseObject {
    /**
     * Returns a {@link SimpleIterator} that can be used with Vala's foreach keyword.
     */
    public abstract SimpleIterator<G> iterator();
}

}

