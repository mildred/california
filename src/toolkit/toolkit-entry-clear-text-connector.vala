/* Copyright 2014-2015 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Toolkit {

/**
 * This connector attaches signal handling to (a) display a "clear text" icon when the GtkEntry
 * has text and (b) clear the entry when the icon is pressed.
 */

public class EntryClearTextConnector : BaseObject {
    private Gee.HashMap<Gtk.Entry, Binding> entries = new Gee.HashMap<Gtk.Entry, Binding>();
    
    public EntryClearTextConnector() {
    }
    
    ~EntryClearTextConnector() {
        traverse_safely<Gtk.Entry>(entries.keys).iterate(disconnect_from);
    }
    
    public void connect_to(Gtk.Entry entry) {
        if (entries.has_key(entry))
            return;
        
        Binding binding = entry.bind_property("text", entry, "secondary-icon-name", BindingFlags.SYNC_CREATE,
            transform_text_to_icon_name);
        entry.icon_release.connect(on_entry_icon_released);
        
        entries.set(entry, binding);
    }
    
    public void disconnect_from(Gtk.Entry entry) {
        Binding binding;
        if (!entries.unset(entry, out binding))
            return;
        
        California.BaseObject.unbind_property(ref binding);
        entry.icon_release.disconnect(on_entry_icon_released);
    }
    
    private bool transform_text_to_icon_name(Binding binding, Value source_value, ref Value target_value) {
        if (String.is_empty((string) source_value)) {
            target_value = "";
        } else {
            target_value = ((Gtk.Entry) binding.source).get_direction() == Gtk.TextDirection.RTL
                ? "edit-clear-rtl-symbolic" : "edit-clear-symbolic";
        }
        
        return true;
    }
    
    private void on_entry_icon_released(Gtk.Entry entry, Gtk.EntryIconPosition icon, Gdk.Event event) {
        if (icon == Gtk.EntryIconPosition.SECONDARY)
            entry.text = "";
    }
    
    public override string to_string() {
        return get_type().name();
    }
}

}

