/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Manager {

/**
 * The Calendar Manager main window.
 */

public class Window : Toolkit.DeckWindow {
    private static Manager.Window? instance = null;
    
    private Window(Gtk.Window? parent) {
        base (parent);
        
        deck.add_cards(iterate<Toolkit.Card>(new CalendarList()).to_array_list());
    }
    
    public static void display(Gtk.Window? parent) {
        // only allow one instance at a time
        if (instance != null) {
            instance.present_with_time(Gdk.CURRENT_TIME);
            
            return;
        }
        
        instance = new Manager.Window(parent);
        instance.show_all();
        instance.run();
        instance.destroy();
        
        instance = null;
    }
}

}

