/* Copyright 2014-2015 Yorba Foundation
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

private Gee.List<Instance> activators;

public void init() throws Error {
    if (!Unit.do_init(ref init_count))
        return;
    
    Backing.init();
    Toolkit.init();
    
    activators = new Gee.ArrayList<Instance>();
    
    // All Instances that work with EDS
    Backing.EdsStore? eds_store = Backing.Manager.instance.get_store_of_type<Backing.EdsStore>()
        as Backing.EdsStore;
    assert(eds_store != null);
    activators.add(new WebCal.ActivatorInstance(_("Web calendar (.ics or webcal:)"), eds_store));
    activators.add(new Google.ActivatorInstance(_("Google Calendar"), eds_store));
    activators.add(new CalDAV.ActivatorInstance(_("CalDAV"), eds_store));
}

public void terminate() {
    if (!Unit.do_terminate(ref init_count))
        return;
    
    activators = null;
    
    Backing.terminate();
    Toolkit.terminate();
}

/**
 * Adds all known {@link Instance}s to the supplied {@link Toolkit.Deck} (each having their own set
 * of {@link Toolkit.Card}s) as well as an {@link InstanceList} Card.
 */
public Toolkit.Deck prepare_deck(Toolkit.Deck deck, Soup.URI? supplied_uri) {
    deck.add_card(new InstanceList());
    deck.add_cards(traverse<Instance>(activators)
        .bloom<Toolkit.Card>(instance => instance.create_cards(supplied_uri))
        .to_array_list()
    );
    
    return deck;
}

}

