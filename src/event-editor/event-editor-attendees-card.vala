/* Copyright 2014-2015 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.EventEditor {

[GtkTemplate (ui = "/org/yorba/california/rc/event-editor-attendees-card.ui")]
public class AttendeesCard : Gtk.Box, Toolkit.Card {
    public const string ID = "CaliforniaEventEditorAttendees";
    
    private class Message : Object {
        public Component.Event event;
        public Backing.CalendarSource calendar_source;
        
        public Message(Component.Event event, Backing.CalendarSource calendar_source) {
            this.event = event;
            this.calendar_source = calendar_source;
        }
    }
    
    private class AttendeePresentation : Gtk.Box {
        public Component.Person attendee { get; private set; }
        
        private Gtk.Button invite_button = new Gtk.Button();
        
        public AttendeePresentation(Component.Person attendee) {
            Object (orientation: Gtk.Orientation.HORIZONTAL, spacing: 4);
            
            this.attendee = attendee;
            
            invite_button.relief = Gtk.ReliefStyle.NONE;
            invite_button.clicked.connect(on_invite_clicked);
            update_invite_button();
            
            Gtk.Label email_label = new Gtk.Label(attendee.full_mailbox);
            Toolkit.set_label_xalign(email_label, 0.0f);
            
            add(invite_button);
            add(email_label);
        }
        
        private void on_invite_clicked() {
            attendee.send_invite = !attendee.send_invite;
            update_invite_button();
        }
        
        private void update_invite_button() {
            invite_button.image = new Gtk.Image.from_icon_name(
                attendee.send_invite ? "mail-unread-symbolic" : "mail-read-symbolic",
                Gtk.IconSize.BUTTON);
            
            invite_button.tooltip_text = attendee.send_invite ? _("Send invite") : _("Don't send invite");
        }
    }
    
    public string card_id { get { return ID; } }
    
    public string? title { get { return null; } }
    
    public Gtk.Widget? default_widget { get { return accept_button; } }
    
    public Gtk.Widget? initial_focus { get { return organizer_entry; } }
    
    [GtkChild]
    private Gtk.Entry organizer_entry;
    
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
    private Backing.CalendarSource? calendar_source = null;
    private Toolkit.ListBoxModel<Component.Person> guest_model;
    private Toolkit.EntryClearTextConnector entry_clear_connector = new Toolkit.EntryClearTextConnector();
    
    public AttendeesCard() {
        guest_model = new Toolkit.ListBoxModel<Component.Person>(guest_listbox, model_presentation);
        
        organizer_entry.bind_property("text", accept_button, "sensitive", BindingFlags.SYNC_CREATE,
            transform_to_accept_sensitive);
        guest_model.bind_property(Toolkit.ListBoxModel.PROP_SIZE, accept_button, "sensitive",
            BindingFlags.SYNC_CREATE, transform_to_accept_sensitive);
        
        add_guest_entry.bind_property("text", add_guest_button, "sensitive", BindingFlags.SYNC_CREATE,
            transform_add_guest_text_to_button);
        
        guest_model.bind_property(Toolkit.ListBoxModel.PROP_SELECTED, remove_guest_button, "sensitive",
            BindingFlags.SYNC_CREATE, transform_list_selected_to_button);
        
        entry_clear_connector.connect_to(organizer_entry);
        entry_clear_connector.connect_to(add_guest_entry);
    }
    
    private bool transform_to_accept_sensitive(Binding binding, Value source_value, ref Value target_value) {
        if (guest_model.size > 0 || !String.is_empty(organizer_entry.text))
            target_value = Email.is_valid_mailbox(organizer_entry.text);
        else
            target_value = true;
        
        return true;
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
    
    public static Value? make_message(Component.Event event, Backing.CalendarSource calendar_source) {
        return new Message(event, calendar_source);
    }
    
    public void jumped_to(Toolkit.Card? from, Toolkit.Card.Jump reason, Value? message_value) {
        Message message = (Message) message_value;
        
        event = message.event;
        calendar_source = message.calendar_source;
        
        // clear list and add all attendees who are not organizers
        guest_model.clear();
        guest_model.add_many(traverse<Component.Person>(event.attendees)
            .filter(attendee => !event.organizers.contains(attendee))
            .to_array_list()
        );
        
        // clear organizer entry and populate from supplied information
        organizer_entry.text = "";
        
        // we only support one organizer, so use first one in form, otherwise use default from
        // calendar source
        if (!event.organizers.is_empty)
            organizer_entry.text = traverse<Component.Person>(event.organizers).first().mailbox;
        else if (!String.is_empty(calendar_source.mailbox))
            organizer_entry.text = calendar_source.mailbox;
        
        // if organizer has been filled-in, give focus to guest entry
        if (String.is_empty(organizer_entry.text))
            organizer_entry.grab_focus();
        else
            add_guest_entry.grab_focus();
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
    
    private Component.Person? make_person(string text, Component.Person.Relationship relationship) {
        string mailbox = text.strip();
        if (!Email.is_valid_mailbox(mailbox))
            return null;
        
        try {
            return new Component.Person(relationship, Email.generate_mailto_uri(mailbox));
        } catch (Error err) {
            debug("Unable to generate mailto from \"%s\": %s", mailbox, err.message);
            
            return null;
        }
    }
    
    [GtkCallback]
    private void on_add_guest_button_clicked() {
        // add to model (which adds to listbox) and clear entry
        Component.Person? attendee = make_person(add_guest_entry.text, Component.Person.Relationship.ATTENDEE);
        if (attendee != null)
            guest_model.add(attendee);
        
        add_guest_entry.text = "";
    }
    
    [GtkCallback]
    private void on_remove_guest_button_clicked() {
        if (guest_model.selected != null)
            guest_model.remove(guest_model.selected);
    }
    
    [GtkCallback]
    private void on_accept_button_clicked() {
        // organizer required if one or more guests invited
        Component.Person? organizer = null;
        if (guest_model.size > 0) {
            organizer = make_person(organizer_entry.text, Component.Person.Relationship.ORGANIZER);
            if (organizer == null)
                return;
        }
        
        // remove organizer if no guests, set organizer if guests
        event.clear_organizers();
        if (organizer != null)
            event.add_organizers(iterate<Component.Person>(organizer).to_array_list());
        
        // add all guests as attendees
        event.clear_attendees();
        event.add_attendees(guest_model.all());
        
        jump_to_card_by_id(MainCard.ID, MainCard.make_message_event(event));
    }
    
    [GtkCallback]
    private void on_cancel_button_clicked() {
        jump_back();
    }
    
    private Gtk.Widget model_presentation(Component.Person person) {
        return new AttendeePresentation(person);
    }
}

}

