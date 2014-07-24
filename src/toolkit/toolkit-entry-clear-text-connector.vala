/* Copyright 2014 Yorba Foundation
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
    public Gtk.Entry entry { get; private set; }
    
    private Binding text_binding;
    
    public EntryClearTextConnector(Gtk.Entry entry) {
        this.entry = entry;
        
        text_binding = entry.bind_property("text", entry, "secondary-icon-name", BindingFlags.SYNC_CREATE,
            transform_text_to_icon_name);
        entry.icon_release.connect(on_entry_icon_released);
    }
    
    ~EntryClearTextConnector() {
        text_binding.unref();
        entry.icon_release.disconnect(on_entry_icon_released);
    }
    
    private bool transform_text_to_icon_name(Binding binding, Value source_value, ref Value target_value) {
        if (String.is_empty((string) source_value)) {
            target_value = "";
        } else {
            target_value = entry.get_direction() == Gtk.TextDirection.RTL
                ? "edit-clear-rtl-symbolic" : "edit-clear-symbolic";
        }
        
        return true;
    }
    
    private void on_entry_icon_released(Gtk.EntryIconPosition icon, Gdk.Event event) {
        if (icon == Gtk.EntryIconPosition.SECONDARY)
            entry.text = "";
    }
    
    public override string to_string() {
        return get_type().name();
    }
}

}

