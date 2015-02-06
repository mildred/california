/* Copyright 2014-2015 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Manager {

/**
 * The Calendar Manager main window.
 */

public class Window : Toolkit.DeckWindow {
    private CalendarList calendar_list = new CalendarList();
    
    private Window(Gtk.Window? window) {
        base (window, null);
        
        deck.add_cards(iterate<Toolkit.Card>(calendar_list, new RemoveCalendar()).to_array_list());
        Activator.prepare_deck(deck, null);
    }
    
    public static void display(Gtk.Window? window) {
        Manager.Window instance = new Manager.Window(window);
        
        instance.show_all();
        instance.run();
        instance.destroy();
    }
    
    public override bool key_release_event(Gdk.EventKey event) {
        // F2 with no modifiers means rename currenly selected item
        if (event.keyval != Gdk.Key.F2 || event.state != 0)
            return base.key_release_event(event);
        
        if (calendar_list.selected == null)
            return base.key_release_event(event);
        
        calendar_list.selected.rename();
        
        // don't propagate
        return true;
    }
}

}

