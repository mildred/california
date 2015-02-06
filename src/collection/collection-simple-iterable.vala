/* Copyright 2014-2015 Yorba Foundation
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

[GenericAccessors]
public interface SimpleIterable<G> : BaseObject {
    /**
     * Returns a {@link SimpleIterator} that can be used with Vala's foreach keyword.
     */
    public abstract SimpleIterator<G> iterator();
    
    /**
     * Returns all the items in the {@link SimpleIterable} as a single Gee.List.
     */
    public Gee.List<G> as_list(owned Gee.EqualDataFunc<G>? equal_func = null) {
        Gee.List<G> list = new Gee.ArrayList<G>((owned) equal_func);
        
        SimpleIterator<G> iter = iterator();
        while (iter.next())
            list.add(iter.get());
        
        return list;
    }
}

}

