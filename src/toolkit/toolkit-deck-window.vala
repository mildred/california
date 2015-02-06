/* Copyright 2014-2015 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Toolkit {

/**
 * A GtkDialog with no visible action area that holds {@link Deck}s.
 *
 * This is designed for UI panes that want to control their own interaction with the user (in
 * particular, button placement) but need all the benefits interaction-wise of GtkDialog.
 */

public class DeckWindow : Gtk.Dialog {
    public Deck deck { get; private set; }
    
    public DeckWindow(Gtk.Window? parent, Deck? starter_deck) {
        this.deck = starter_deck ?? new Deck();
        
        transient_for = parent;
        modal = true;
        resizable = false;
        set_titlebar((Gtk.Widget) null);
        
        deck.dismiss.connect(on_deck_dismissed);
        
        Gtk.Box content_area = (Gtk.Box) get_content_area();
        content_area.margin = 8;
        content_area.add(deck);
        
        get_action_area().visible = false;
        get_action_area().no_show_all = true;
    }
    
    ~DeckWindow() {
        deck.dismiss.disconnect(on_deck_dismissed);
    }
    
    private void on_deck_dismissed(Card.DismissReason reason) {
        Gtk.ResponseType response_type;
        switch (reason) {
            case Card.DismissReason.SUCCESS:
                response_type = Gtk.ResponseType.OK;
            break;
            
            case Card.DismissReason.USER_CLOSED:
                response_type = Gtk.ResponseType.CANCEL;
            break;
            
            default:
                response_type = Gtk.ResponseType.CLOSE;
            break;
        }
        
        response(response_type);
    }
}

}

