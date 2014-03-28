/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Host {

[GtkTemplate (ui = "/org/yorba/california/rc/activator-list.ui")]
public class ActivatorList : Gtk.Grid, Host.Interaction {
    private class ActivatorListItem : Gtk.Label {
        public Backing.Activator activator;
        
        public ActivatorListItem(Backing.Activator activator) {
            this.activator = activator;
            
            label = activator.title;
            xalign = 0.0f;
            margin = 4;
        }
    }
    
    public Gtk.Widget? default_widget { get { return add_button; } }
    
    [GtkChild]
    private Gtk.ListBox listbox;
    
    [GtkChild]
    private Gtk.Button add_button;
    
    public signal void selected(Backing.Activator activator);
    
    public ActivatorList() {
        foreach (Backing.Activator activator in Backing.Manager.instance.get_activators())
            listbox.add(new ActivatorListItem(activator));
        
        show_all();
    }
    
    [GtkCallback]
    private void on_listbox_row_activated(Gtk.ListBoxRow? row) {
        if (row != null)
            selected(((ActivatorListItem) row.get_child()).activator);
    }
    
    [GtkCallback]
    private void on_add_button_clicked() {
        on_listbox_row_activated(listbox.get_selected_row());
    }
    
    [GtkCallback]
    private void on_cancel_button_clicked() {
        dismissed(true);
    }
}

}

