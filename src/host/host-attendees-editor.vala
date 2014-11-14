/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Host {

[GtkTemplate (ui = "/org/yorba/california/rc/attendees-editor.ui")]
public class AttendeesEditor : Gtk.Box, Toolkit.Card {
    public const string ID = "CaliforniaHostAttendeesEditor";
    
    public string card_id { get { return ID; } }
    
    public string? title { get { return null; } }
    
    public Gtk.Widget? default_widget { get { return accept_button; } }
    
    public Gtk.Widget? initial_focus { get { return add_guest_entry; } }
    
    [GtkChild]
    private Gtk.Entry add_guest_entry;
    
    [GtkChild]
    private Gtk.Button add_guest_button;
    
    [GtkChild]
    private Gtk.ListBox guest_listbox;
    
    [GtkChild]
    private Gtk.Button remove_guest_button;
    
    [GtkChild]
    private Gtk.Button accept_button;
    
    private new Component.Event? event = null;
    private Toolkit.ListBoxModel<Component.Person> guest_model;
    
    public AttendeesEditor() {
        guest_model = new Toolkit.ListBoxModel<Component.Person>(guest_listbox, model_presentation);
        
        add_guest_entry.bind_property("text", add_guest_button, "sensitive", BindingFlags.SYNC_CREATE,
            transform_add_guest_text_to_button);
        guest_model.bind_property(Toolkit.ListBoxModel.PROP_SELECTED, remove_guest_button, "sensitive",
            BindingFlags.SYNC_CREATE, transform_list_selected_to_button);
    }
    
    private bool transform_add_guest_text_to_button(Binding binding, Value source_value,
        ref Value target_value) {
        target_value = Email.is_valid_mailbox(add_guest_entry.text);
        
        return true;
    }
    
    private bool transform_list_selected_to_button(Binding binding, Value source_value,
        ref Value target_value) {
        target_value = guest_model.selected != null;
        
        return true;
    }
    
    public void jumped_to(Toolkit.Card? from, Toolkit.Card.Jump reason, Value? message) {
        event = message as Component.Event;
        if (event == null)
            return;
        
        // clear list and add all attendees who are not organizers
        guest_model.clear();
        guest_model.add_many(traverse<Component.Person>(event.attendees)
            .filter(attendee => !event.organizers.contains(attendee))
            .to_array_list()
        );
    }
    
    [GtkCallback]
    private bool on_add_guest_entry_focus_in_event() {
        accept_button.has_default = false;
        add_guest_button.has_default = true;
        
        return false;
    }
    
    [GtkCallback]
    private bool on_add_guest_entry_focus_out_event() {
        add_guest_button.has_default = false;
        accept_button.has_default = true;
        
        return false;
    }
    
    [GtkCallback]
    private void on_add_guest_button_clicked() {
        string mailbox = add_guest_entry.text.strip();
        if (!Email.is_valid_mailbox(mailbox))
            return;
        
        try {
            // add to model (which adds to listbox) and clear entry
            guest_model.add(new Component.Person(Component.Person.Relationship.ATTENDEE,
                Email.generate_mailto_uri(mailbox)));
            add_guest_entry.text = "";
        } catch (Error err) {
            debug("Unable to generate mailto from \"%s\": %s", mailbox, err.message);
        }
    }
    
    [GtkCallback]
    private void on_remove_guest_button_clicked() {
        if (guest_model.selected != null)
            guest_model.remove(guest_model.selected);
    }
    
    [GtkCallback]
    private void on_accept_button_clicked() {
        event.clear_attendees();
        event.add_attendees(guest_model.all());
        
        jump_to_card_by_name(CreateUpdateEvent.ID, event);
    }
    
    [GtkCallback]
    private void on_cancel_button_clicked() {
        jump_back();
    }
    
    private Gtk.Widget model_presentation(Component.Person person) {
        Gtk.Label label = new Gtk.Label(person.full_mailbox);
        label.xalign = 0.0f;
        
        return label;
    }
}

}

