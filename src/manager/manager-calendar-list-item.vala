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
    public Backing.CalendarSource source { get; private set; }
    
    [GtkChild]
    private Gtk.CheckButton visible_check_button;
    
    [GtkChild]
    private Gtk.Label title_label;
    
    public CalendarListItem(Backing.CalendarSource source) {
        this.source = source;
        
        source.bind_property(Backing.Source.PROP_TITLE, title_label, "label",
            BindingFlags.SYNC_CREATE);
        source.bind_property(Backing.Source.PROP_VISIBLE, visible_check_button, "active",
            BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
    }
}

}

