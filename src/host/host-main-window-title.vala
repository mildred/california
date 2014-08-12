/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Host {

[GtkTemplate (ui = "/org/yorba/california/rc/main-window-title.ui")]
internal class MainWindowTitle : Gtk.Grid {
    [GtkChild]
    public Gtk.Button next_button;
    
    [GtkChild]
    public Gtk.Button prev_button;
    
    [GtkChild]
    public Gtk.Image next_image;
    
    [GtkChild]
    public Gtk.Image prev_image;
    
    [GtkChild]
    public Gtk.Label title_label;
    
    public MainWindowTitle() {
        if (get_direction() == Gtk.TextDirection.RTL) {
            prev_image.icon_name = "go-previous-rtl-symbolic";
            next_image.icon_name = "go-next-rtl-symbolic";
        }
    }
}

}

