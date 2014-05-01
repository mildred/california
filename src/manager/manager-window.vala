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
    
    private CalendarList calendar_list = new CalendarList();
    
    private Window(Gtk.Window? parent) {
        base (parent, null);
        
        deck.add_cards(iterate<Toolkit.Card>(calendar_list).to_array_list());
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

