/* Copyright 2014-2015 Yorba Foundation
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
private bool mgr_init = false;
private Error? mgr_err = null;

public void init() throws Error {
    if (!Unit.do_init(ref init_count))
        return;
    
    // external unit init
    Calendar.init();
    Component.init();
    
    // internal class init
    Manager.init();
    
    // Register all Stores here
    Manager.instance.register(new EdsStore());
    
    // open Manager, pumping event loop until it completes (possibly w/ error)
    Manager.instance.open_async.begin(null, on_backing_manager_opened);
    
    while (!mgr_init)
        Gtk.main_iteration();
    
    if (mgr_err != null)
        throw mgr_err;
}

public void terminate() {
    if (!Unit.do_terminate(ref init_count))
        return;
    
    Manager.terminate();
    
    Component.terminate();
    Calendar.terminate();
}

private void on_backing_manager_opened(Object? source, AsyncResult result) {
    try {
        Backing.Manager.instance.open_async.end(result);
    } catch (Error err) {
        mgr_err = err;
    }
    
    // sentinel to init() that open_async is complete
    mgr_init = true;
}

}

