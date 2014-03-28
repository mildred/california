/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Host {

/**
 * A GtkDialog with no visible action area.
 *
 * This is designed for UI panes that want to control their own interaction with the user (in
 * particular, button placement) but need all the benefits interaction-wise of GtkDialog.
 *
 * It's expected this will go away when we move to GTK+ 3.12 and can use GtkPopovers for these
 * interactions.
 */

public class ModalWindow : Gtk.Dialog {
    public Gtk.Box content_area { get; private set; }
    
    private Interaction? primary = null;
    private Gtk.ResponseType response_type = Gtk.ResponseType.CLOSE;
    
    public ModalWindow(Gtk.Window? parent) {
        transient_for = parent;
        modal = true;
        resizable = false;
        
        content_area = (Gtk.Box) get_content_area();
        content_area.margin = 8;
        content_area.add.connect(on_content_added);
        content_area.remove.connect(on_content_removed);
        
        get_action_area().visible = false;
        get_action_area().no_show_all = true;
    }
    
    private void on_content_added(Gtk.Widget widget) {
        Interaction? interaction = widget as Interaction;
        if (interaction != null) {
            if (primary == null)
                primary = interaction;
            
            interaction.completed.connect(on_interaction_completed);
            interaction.dismissed.connect(on_interaction_dismissed);
        }
    }
    
    private void on_content_removed(Gtk.Widget widget) {
        Interaction? interaction = widget as Interaction;
        if (interaction != null) {
            if (primary == interaction)
                primary = null;
            
            interaction.completed.disconnect(on_interaction_completed);
            interaction.dismissed.disconnect(on_interaction_dismissed);
        }
    }
    
    private void on_interaction_completed() {
        response_type = Gtk.ResponseType.OK;
    }
    
    private void on_interaction_dismissed() {
        response(response_type);
    }
    
    public override void show() {
        base.show();
        
        // the default widget is lost in the shuffle, reestablish its primacy
        if (primary != null && primary.default_widget != null)
            primary.default_widget.grab_default();
    }
}

}

