/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

/**
 * Simple initialization/termination guard functions for the various units (submodules) within
 * California.
 *
 * These guards are not thread-safe, as the unit init/termination functions are intended to be
 * called from the application's primary thread.
 */
 
namespace California.InitGuard {

/**
 * Called from the unit's init() function.
 *
 * @return true if the init() function should continue initialization.
 */

public bool do_init(ref int init_count) {
    return init_count++ == 0;
}

/**
 * Called from the unit's terminate() function.
 *
 * @return true if the terminate() function should continue termination.
 */

public bool do_terminate(ref int init_count) {
    bool zeroed = --init_count == 0;
    
    // block underflow
    init_count = init_count.clamp(0, int.MAX);
    
    return zeroed;
}

}
