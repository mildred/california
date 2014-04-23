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
    public Deck deck { get; private set; }
    
    public DeckWindow(Gtk.Window? parent, Deck? starter_deck) {
        this.deck = starter_deck ?? new Deck();
        
        transient_for = parent;
        modal = true;
        resizable = false;
        
        deck.dismiss.connect(on_deck_dismissed);
        deck.success.connect(on_deck_success);
        deck.failure.connect(on_deck_failure);
        
        Gtk.Box content_area = (Gtk.Box) get_content_area();
        content_area.margin = 8;
        content_area.add(deck);
        
        get_action_area().visible = false;
        get_action_area().no_show_all = true;
    }
    
    ~DeckWindow() {
        deck.dismiss.disconnect(on_deck_dismissed);
        deck.success.disconnect(on_deck_success);
        deck.failure.disconnect(on_deck_failure);
    }
    
    private void on_deck_dismissed(bool user_request, bool final) {
        if (final)
            response(Gtk.ResponseType.CLOSE);
    }
    
    private void on_deck_success() {
        response(Gtk.ResponseType.OK);
    }
    
    private void on_deck_failure(string? user_message) {
        if (!String.is_empty(user_message))
            Application.instance.error_message(user_message);
        
        response(Gtk.ResponseType.CLOSE);
    }
}

}

