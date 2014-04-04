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
    private Gtk.ColorButton color_button;
    
    public CalendarListItem(Backing.CalendarSource source) {
        this.source = source;
        
        has_tooltip = true;
        
        source.bind_property(Backing.Source.PROP_TITLE, title_label, "label",
            BindingFlags.SYNC_CREATE);
        source.bind_property(Backing.Source.PROP_VISIBLE, visible_check_button, "active",
            BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
        
        on_color_changed();
        source.notify[Backing.Source.PROP_COLOR].connect(on_color_changed);
    }
    
    public override bool query_tooltip(int x, int y, bool keyboard_mode, Gtk.Tooltip tooltip) {
        // no tooltip if text is entirely shown
        if (!title_label.get_layout().is_ellipsized())
            return false;
        
        tooltip.set_text(source.title);
        
        return true;
    }
    
    private void on_color_changed() {
        color_button.set_color(source.color_as_rgb());
    }
}

}

