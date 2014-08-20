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
    
    public new Component.Event? event { get; private set; default = null; }
    
    public bool edit_required { get; private set; default = false; }
    
    public Gtk.Widget? default_widget { get { return create_button; } }
    
    public Gtk.Widget? initial_focus { get { return details_entry; } }
    
    [GtkChild]
    private Gtk.Label when_label;
    
    [GtkChild]
    private Gtk.Label when_text_label;
    
    [GtkChild]
    private Gtk.Entry details_entry;
    
    [GtkChild]
    private Gtk.Label example_label;
    
    [GtkChild]
    private Gtk.ComboBoxText calendar_combo_box;
    
    [GtkChild]
    private Gtk.Box action_button_box;
    
    [GtkChild]
    private Gtk.Button create_button;
    
    private Toolkit.ComboBoxTextModel<Backing.CalendarSource> model;
    private Toolkit.EntryClearTextConnector clear_text_connector = new Toolkit.EntryClearTextConnector();
    
    public QuickCreateEvent() {
        // create and initialize combo box model
        model = new Toolkit.ComboBoxTextModel<Backing.CalendarSource>(calendar_combo_box,
            (cal) => cal.title);
        foreach (Backing.CalendarSource calendar_source in
            Backing.Manager.instance.get_sources_of_type<Backing.CalendarSource>()) {
            if (calendar_source.visible && !calendar_source.read_only)
                model.add(calendar_source);
        }
        
        clear_text_connector.connect_to(details_entry);
        details_entry.bind_property("text", create_button, "sensitive", BindingFlags.SYNC_CREATE,
            transform_text_to_sensitivity);
        
        action_button_box.get_style_context().add_class(Gtk.STYLE_CLASS_LINKED);
        action_button_box.get_style_context().add_class(Gtk.STYLE_CLASS_RAISED);
    }
    
    private bool transform_text_to_sensitivity(Binding binding, Value source_value, ref Value target_value) {
        target_value = from_string(details_entry.text).any(ch => !ch.isspace());
        
        return true;
    }
    
    public void jumped_to(Toolkit.Card? from, Toolkit.Card.Jump reason, Value? message) {
        event = (message != null) ? message as Component.Event : null;
        
        // if initial date/times supplied, reveal to the user and change the example
        string eg;
        if (event != null && (event.date_span != null || event.exact_time_span != null)) {
            when_label.visible = when_text_label.visible = true;
            when_label.no_show_all = when_text_label.no_show_all = false;
            when_text_label.label = event.get_event_time_pretty_string(Calendar.Date.PrettyFlag.NONE,
                Calendar.ExactTimeSpan.PrettyFlag.ALLOW_MULTILINE, Calendar.Timezone.local);
            if (event.date_span != null)
                eg = _("Example: Dinner at Tadich Grill 7:30pm");
            else
                eg = _("Example: Dinner at Tadich Grill");
        } else {
            when_label.visible = when_text_label.visible = false;
            when_label.no_show_all = when_text_label.no_show_all = true;
            eg = _("Example: Dinner at Tadich Grill 7:30pm tomorrow");
        }
        
        example_label.label = "<small><i>%s</i></small>".printf(eg);
        
        // make first item active
        calendar_combo_box.active = 0;
    }
    
    [GtkCallback]
    private void on_help_button_clicked() {
        try {
            Gtk.show_uri(null, Application.QUICK_ADD_HELP_URL, Gtk.get_current_event_time());
        } catch (Error err) {
            Application.instance.error_message("Error opening help: %s".printf(err.message));
        }
    }
    
    [GtkCallback]
    private void on_create_button_clicked() {
        // shouldn't be sensitive if no text
        string details = details_entry.text.strip();
        if (String.is_empty(details))
            return;
        
        Component.DetailsParser parser = new Component.DetailsParser(details, model.active,
            event);
        event = parser.event;
        
        // create if possible, otherwise jump to editor
        if (event.is_valid(true))
            create_event_async.begin(null);
        else
            edit_event();
    }
    
    [GtkCallback]
    private void on_edit_button_clicked() {
        // empty text okay
        string details = details_entry.text.strip();
        if (!String.is_empty(details)) {
            Component.DetailsParser parser = new Component.DetailsParser(details, model.active,
                event);
            event = parser.event;
        }
        
        // always edit
        edit_event();
    }
    
    private void edit_event() {
        // Must pass some kind of event to create/update, so use blank if required
        if (event == null)
            event = new Component.Event.blank();
        
        // ensure it's at least valid
        if (!event.is_valid(false))
            event.set_event_date_span(Calendar.System.today.to_date_span());
        
        edit_required = true;
        
        notify_user_closed();
    }
    
    private async void create_event_async(Cancellable? cancellable) {
        if (event.calendar_source == null) {
            notify_failure(_("Unable to create event: calendar must be specified"));
            
            return;
        }
        
        Gdk.Cursor? cursor = Toolkit.set_busy(this);
        
        Error? create_err = null;
        try {
            yield event.calendar_source.create_component_async(event, cancellable);
        } catch (Error err) {
            create_err = err;
        }
        
        Toolkit.set_unbusy(this, cursor);
        
        if (create_err == null)
            notify_success();
        else
            notify_failure(_("Unable to create event: %s").printf(create_err.message));
    }
}

}

