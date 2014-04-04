/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Toolkit {

/**
 * A GtkDialog with no visible action area.
 *
 * This is designed for UI panes that want to control their own interaction with the user (in
 * particular, button placement) but need all the benefits interaction-wise of GtkDialog.
 *
 * It's expected this will go away when we move to GTK+ 3.12 and can use GtkPopovers for these
 * interactions.
 */

public class DeckWindow : Gtk.Dialog {
    public Deck deck { get; private set; default = new Deck(); }
    
    private Gtk.ResponseType response_type = Gtk.ResponseType.CLOSE;
    
    public DeckWindow(Gtk.Window? parent) {
        transient_for = parent;
        modal = true;
        resizable = false;
        
        deck.dismissed.connect(on_deck_dismissed);
        deck.completed.connect(on_deck_completed);
        
        Gtk.Box content_area = (Gtk.Box) get_content_area();
        content_area.margin = 8;
        content_area.add(deck);
        
        get_action_area().visible = false;
        get_action_area().no_show_all = true;
    }
    
    private void on_deck_completed() {
        response_type = Gtk.ResponseType.OK;
    }
    
    private void on_deck_dismissed() {
        response(response_type);
    }
}

}

