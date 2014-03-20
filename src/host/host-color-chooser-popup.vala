/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Host {

/**
 * A simple {@link Popup} window featuring only a GtkColorChooser.
 */

public class ColorChooserPopup : Popup {
    private Gtk.ColorChooserWidget color_chooser = new Gtk.ColorChooserWidget();
    
    public signal void selected(Gdk.RGBA rgba);
    
    public ColorChooserPopup(Gtk.Widget relative_to, Gdk.RGBA initial_rgba) {
        base (relative_to);
        
        color_chooser.rgba = initial_rgba;
        color_chooser.use_alpha = false;
        color_chooser.show_editor = false;
        color_chooser.margin = 8;
        
        color_chooser.color_activated.connect((rgba) => {
            selected(rgba);
            dismissed();
        });
        
        add(color_chooser);
    }
}

}

