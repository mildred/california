/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

/**
 * Activators are front-ends (both UI and transport logic) to the various ways a calendar may be
 * located or discovered and subscribed to.
 *
 * Because locating the calendar is a different task than managing a calendar subscription, and
 * because the same Activator can work with multiple {@link Backing.Store}s, they are decoupled
 * from the {@link Backing} unit.  For example, a Google Activator could locate the user's account
 * calendar and hand it off to EDS or a GData back-end.
 */

namespace California.Activator {

private int init_count = 0;

private Gee.TreeSet<Instance> activators;

public void init() throws Error {
    if (!Unit.do_init(ref init_count))
        return;
    
    Backing.init();
    
    activators = new Gee.TreeSet<Instance>(activator_comparator);
    
    // All Instances that work with EDS
    Backing.EdsStore? eds_store = Backing.Manager.instance.get_store_of_type<Backing.EdsStore>()
        as Backing.EdsStore;
    assert(eds_store != null);
    activators.add(new WebCalActivator(_("Web calendar (.ics)"), eds_store));
}

public void terminate() {
    if (!Unit.do_terminate(ref init_count))
        return;
    
    activators = null;
    
    Backing.terminate();
}

private int activator_comparator(Instance a, Instance b) {
    return String.stricmp(a.title, b.title);
}

}

