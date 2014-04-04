/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Activator {

/**
 * A modal window for selecting and managing {@link Activator.Instance} workflows.
 */

public class Window : Host.ModalWindow {
    private static Activator.Window? instance = null;
    
    private Deck deck = new Deck();
    
    private Window(Gtk.Window? parent) {
        base (parent);
        
        // The Deck is pre-populated with each of their Cards, with the InstanceList jumping to
        // the right set when asked to (and acting as home)
        Gee.List<Card> cards = new Gee.ArrayList<Card>();
        cards.add(new InstanceList());
        foreach (Instance activator in activators)
            cards.add_all(activator.create_cards(null));
        
        deck.add_cards(cards);
        
        content_area.add(deck);
    }
    
    public static void display(Gtk.Window? parent) {
        // only allow one instance at a time
        if (instance != null) {
            instance.present_with_time(Gdk.CURRENT_TIME);
            
            return;
        }
        
        instance = new Activator.Window(parent);
        instance.show_all();
        instance.run();
        instance.destroy();
        
        instance = null;
    }
}

}

