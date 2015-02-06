/* Copyright 2014-2015 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Collection {

private int init_count = 0;

public void init() throws Error {
    if (!Unit.do_init(ref init_count))
        return;
}

public void terminate() {
    if (!Unit.do_terminate(ref init_count))
        return;
}

/**
 * Returns true if the Collection is null or empty (zero elements).
 */
public inline bool is_empty(Gee.Collection? c) {
    return c == null || c.size == 0;
}

/**
 * Returns true if the two Collections contains all the same elements and the same number of elements.
 */
public bool equal<G>(Gee.Collection<G>? a, Gee.Collection<G>? b) {
    if ((a == null || b == null) && a != b)
        return false;
    
    if (a == b)
        return true;
    
    if (size(a) != size(b))
        return false;
    
    return a.contains_all(b);
}

/**
 * Returns the size of the Collection, zero if null.
 */
public inline int size(Gee.Collection? c) {
    return !is_empty(c) ? c.size : 0;
}

}

