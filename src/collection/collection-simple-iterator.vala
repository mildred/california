/* Copyright 2014-2015 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Collection {

/**
 * A simple iterator interface that comports with Vala's foreach keyword.
 *
 * Vala's foreach only requires that an object have an iterator() method that returns an object
 * with two methods: {@link next} and {@link get}.  This interface sets that up for classes to
 * use.
 *
 * This is not a substitute for a Gee.Iterator, but that class offers a lot of extra functionality
 * (such as removing elements) that's not always necessary or desireable.
 *
 * @see SimpleIterable
 */

public interface SimpleIterator<G> : BaseObject {
    /**
     * Returns true if {@link get} will return a new value.
     *
     * Vala's foreach operator is "off-track", meaning next will be called first, then get.
     */
    public abstract bool next();
    
    /**
     * Returns the current item in the iteration.
     */
    public abstract new G get();
    
    /**
     * Provided merely to allow classes or objects to provide parameterized iterators.
     *
     * Thus, this object can be passed to foreach and it will be iterated.
     */
    public SimpleIterator<G> iterator() {
        return this;
    }
}

}

