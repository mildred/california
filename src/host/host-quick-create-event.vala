/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Host {

[GtkTemplate (ui = "/org/yorba/california/rc/quick-create-event.ui")]
public class QuickCreateEvent : Gtk.Grid, Toolkit.Card {
    public const string ID = "QuickCreateEvent";
    
    public string card_id { get { return ID; } }
    
    public string? title { get { return null; } }
    
    public Component.Event? parsed_event { get; private set; default = null; }
    
    public Gtk.Widget? default_widget { get { return create_button; } }
    
    public Gtk.Widget? initial_focus { get { return details_entry; } }
    
    [GtkChild]
    private Gtk.Entry details_entry;
    
    [GtkChild]
    private Gtk.ComboBoxText calendar_combo_box;
    
    [GtkChild]
    private Gtk.Button create_button;
    
    private Toolkit.ComboBoxTextModel<Backing.CalendarSource> model;
    
    public QuickCreateEvent() {
        // create and initialize combo box model
        model = new Toolkit.ComboBoxTextModel<Backing.CalendarSource>(calendar_combo_box,
            (cal) => cal.title);
        foreach (Backing.CalendarSource calendar_source in
            Backing.Manager.instance.get_sources_of_type<Backing.CalendarSource>()) {
            if (calendar_source.visible && !calendar_source.read_only)
                model.add(calendar_source);
        }
        
        // make first item active
        calendar_combo_box.active = 0;
        
        details_entry.bind_property("text-length", create_button, "sensitive", BindingFlags.SYNC_CREATE,
            xform_text_length_to_sensitive);
    }
    
    private bool xform_text_length_to_sensitive(Binding binding, Value source_value, ref Value target_value) {
        target_value = !String.is_empty(details_entry.text);
        
        return true;
    }
    
    public void jumped_to(Toolkit.Card? from, Value? message) {
    }
    
    [GtkCallback]
    private void on_details_entry_icon_release(Gtk.Entry entry, Gtk.EntryIconPosition icon,
        Gdk.Event event) {
        // check for clear icon being pressed
        if (icon == Gtk.EntryIconPosition.SECONDARY)
            details_entry.text = "";
    }
    
    [GtkCallback]
    private void on_cancel_button_clicked() {
        notify_user_closed();
    }
    
    [GtkCallback]
    private void on_create_button_clicked() {
        Component.DetailsParser parser = new Component.DetailsParser(details_entry.text, model.active);
        parsed_event = parser.event;
        
        notify_success();
    }
}

}

