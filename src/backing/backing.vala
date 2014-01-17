/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

/**
 * "Backing" refers to storage mediums that hold and distribute calendar events.
 *
 * The backing {@link Source} may be of many varieties: a public calendar read-only to the user,
 * a personal calendar the user may update, or a shared calendar the user may or may not have
 * rights to modify (but must present credentials to view).
 *
 * A Source is merely an interface to accessing and querying this storage medium.  The interface
 * converts its data into California-specific data objects (or vice-versa) and signals when changes
 * are detected.
 *
 * {@link Store}s provide lists of available or subscribed to Sources.  They're available from the
 @ {@link Manager}.
 *
 * {@link Backing.init} should be invoked prior to using any class in this namespace.  Call
 * {@link Backing.terminate} when the application is closing.
 */

namespace California.Backing {

private int init_count = 0;

public void init() {
    if (!InitGuard.do_init(ref init_count))
        return;
    
    // external unit init
    Calendar.init();
    Component.init();
    
    // internal class init
    Manager.init();
    
    // Register all Stores here
    Manager.instance.register(new EdsStore());
}

public void terminate() {
    if (!InitGuard.do_terminate(ref init_count))
        return;
    
    Manager.terminate();
    
    Component.terminate();
    Calendar.terminate();
}

}

