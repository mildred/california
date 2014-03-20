/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Manager {

/**
 * An interactive list item in a {@link CalendarList}.
 */

[GtkTemplate (ui = "/org/yorba/california/rc/calendar-manager-list-item.ui")]
public class CalendarListItem : Gtk.Grid {
    private const int COLOR_DIM = 16;
    
    public Backing.CalendarSource source { get; private set; }
    
    [GtkChild]
    private Gtk.CheckButton visible_check_button;
    
    [GtkChild]
    private Gtk.Label title_label;
    
    [GtkChild]
    private Gtk.Button color_button;
    
    public CalendarListItem(Backing.CalendarSource source) {
        this.source = source;
        
        source.bind_property(Backing.Source.PROP_TITLE, title_label, "label",
            BindingFlags.SYNC_CREATE);
        source.bind_property(Backing.Source.PROP_VISIBLE, visible_check_button, "active",
            BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
        
        on_color_changed();
        source.notify[Backing.Source.PROP_COLOR].connect(on_color_changed);
    }
    
    private void on_color_changed() {
        Gdk.Pixbuf pixbuf = new Gdk.Pixbuf(Gdk.Colorspace.RGB, false, 8, COLOR_DIM, COLOR_DIM);
        pixbuf.fill(Gfx.rgba_to_pixel(source.color_as_rgba()));
        
        color_button.set_image(new Gtk.Image.from_pixbuf(pixbuf));
    }
    
    [GtkCallback]
    private void on_color_button_clicked() {
        Host.ColorChooserPopup popup = new Host.ColorChooserPopup(color_button, source.color_as_rgba());
        
        popup.selected.connect((rgba) => {
            source.set_color_to_rgba(rgba);
        });
        
        popup.dismissed.connect(() => {
            popup.destroy();
        });
        
        popup.show_all();
    }
}

}

