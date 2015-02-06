/* Copyright 2014-2015 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.EventEditor {

/**
 * A blank "form" of widgets for the user to enter or update event details that relies on other
 * {@link Toolkit.Card}s in the {@link Toolkit.Deck} to perform more sophisticated editing.
 */

[GtkTemplate (ui = "/org/yorba/california/rc/event-editor-main-card.ui")]
public class MainCard : Gtk.Grid, Toolkit.Card {
    public const string ID = "CaliforniaEventEditorMainCard";
    
    private const int START_HOUR = 0;
    private const int END_HOUR = 23;
    private const int MIN_DIVISIONS = 15;
    
    private const string FAMILY_NORMAL = "normal";
    private const string FAMILY_RECURRING = "recurring";
    
    public string card_id { get { return ID; } }
    
    public string? title { get { return null; } }
    
    public Gtk.Widget? default_widget { get { return accept_button; } }
    
    public Gtk.Widget? initial_focus { get { return summary_entry; } }
    
    [GtkChild]
    private Gtk.Entry summary_entry;
    
    [GtkChild]
    private Gtk.Label time_summary_label;
    
    [GtkChild]
    private Gtk.Entry location_entry;
    
    [GtkChild]
    private Gtk.Label organizer_label;
    
    [GtkChild]
    private Gtk.Label organizer_text;
    
    [GtkChild]
    private Gtk.Label attendees_text;
    
    [GtkChild]
    private Gtk.TextView description_textview;
    
    [GtkChild]
    private Gtk.ComboBoxText calendar_combo;
    
    [GtkChild]
    private Gtk.Label recurring_explanation_label;
    
    [GtkChild]
    private Gtk.Box rotating_button_box_container;
    
    public bool is_update { get; set; default = false; }
    
    private new Component.Event event = new Component.Event.blank();
    private DateTimeCard.Message? dt = null;
    private Toolkit.ComboBoxTextModel<Backing.CalendarSource> calendar_model;
    private bool first_message = true;
    
    private Toolkit.RotatingButtonBox rotating_button_box = new Toolkit.RotatingButtonBox();
    private Toolkit.EntryClearTextConnector clear_text_connector = new Toolkit.EntryClearTextConnector();
    
    private Gtk.Button accept_button = new Gtk.Button();
    private Gtk.Button cancel_button = new Gtk.Button.with_mnemonic(_("_Cancel"));
    private Gtk.Button update_all_button = new Gtk.Button.with_mnemonic(_("Save A_ll Events"));
    private Gtk.Button update_this_button = new Gtk.Button.with_mnemonic(_("Save _This Event"));
    private Gtk.Button cancel_recurring_button = new Gtk.Button.with_mnemonic(_("_Cancel"));
    
    public MainCard() {
        // create button is active only if summary is filled out; all other fields (so far)
        // guarantee valid values at all times
        clear_text_connector.connect_to(summary_entry);
        summary_entry.bind_property("text", accept_button, "sensitive", BindingFlags.SYNC_CREATE,
            transform_summary_to_accept);
        
        clear_text_connector.connect_to(location_entry);
        
        // use model to control calendars combo box
        calendar_model = Host.build_calendar_source_combo_model(calendar_combo);
        
        accept_button.can_default = true;
        accept_button.has_default = true;
        accept_button.get_style_context().add_class("suggested-action");
        
        accept_button.clicked.connect(on_accept_button_clicked);
        cancel_button.clicked.connect(on_cancel_button_clicked);
        update_all_button.clicked.connect(on_update_all_button_clicked);
        update_this_button.clicked.connect(on_update_this_button_clicked);
        cancel_recurring_button.clicked.connect(on_cancel_recurring_button_clicked);
        
        organizer_text.query_tooltip.connect(on_organizer_text_query_tooltip);
        organizer_text.has_tooltip = true;
        
        attendees_text.query_tooltip.connect(on_attendees_text_query_tooltip);
        attendees_text.has_tooltip = true;
        
        rotating_button_box.pack_end(FAMILY_NORMAL, cancel_button);
        rotating_button_box.pack_end(FAMILY_NORMAL, accept_button);
        
        rotating_button_box.pack_end(FAMILY_RECURRING, cancel_recurring_button);
        rotating_button_box.pack_end(FAMILY_RECURRING, update_all_button);
        rotating_button_box.pack_end(FAMILY_RECURRING, update_this_button);
        
        // The cancel-recurring-update button looks big compared to other buttons, so allow for the
        // ButtonBox to reduce it in size
        rotating_button_box.get_family_container(FAMILY_RECURRING).child_set_property(cancel_recurring_button,
            "non-homogeneous", true);
        
        rotating_button_box.expand = true;
        rotating_button_box.halign = Gtk.Align.FILL;
        rotating_button_box.valign = Gtk.Align.END;
        rotating_button_box_container.add(rotating_button_box);
        
        Calendar.System.instance.is_24hr_changed.connect(on_update_time_summary);
    }
    
    ~MainCard() {
        Calendar.System.instance.is_24hr_changed.disconnect(on_update_time_summary);
    }
    
    private bool transform_summary_to_accept(Binding binding, Value source_value, ref Value target_value) {
        target_value = summary_entry.text_length > 0 && (event != null ? event.is_valid(false) : false);
        
        return true;
    }
    
    public static Value? make_message_event(Component.Event event) {
        return event;
    }
    
    public static Value? make_message_date_time(DateTimeCard.Message date_time) {
        return date_time;
    }
    
    public void jumped_to(Toolkit.Card? from, Toolkit.Card.Jump reason, Value? message) {
        // if no message, leave everything as it is (i.e. jumped back to)
        if (message == null)
            return;
        
        if (message.type() == typeof(DateTimeCard.Message)) {
            dt = (DateTimeCard.Message) message;
        } else {
            event = (Component.Event) message;
            if (dt == null)
                dt = new DateTimeCard.Message.from_event(event);
        }
        
        // set combo to event's calendar, but only if first (initial) message; since the selected
        // calendar is maintained outside of the event and only applied when Save/Create is pressed,
        // don't want to update it every time this card is brought to the top
        if (first_message) {
            if (event.calendar_source != null) {
                calendar_model.set_item_active(event.calendar_source);
            } else {
                calendar_model.set_item_default_active();
                is_update = false;
            }
            
            first_message = false;
        }
        
        update_controls();
    }
    
    private void update_controls() {
        if (event.summary != null)
            summary_entry.text = event.summary;
        else
            summary_entry.text = "";
        
        on_update_time_summary();
        
        location_entry.text = event.location ?? "";
        description_textview.buffer.text = event.description ?? "";
        
        // Only show "Organizer" and associated text if something to show
        organizer_text.label = traverse<Component.Person>(event.organizers)
            .sort()
            .to_string(stringify_persons);
        bool has_organizer = !String.is_empty(organizer_text.label);
        organizer_label.visible = organizer_text.visible = has_organizer;
        organizer_label.no_show_all = organizer_text.no_show_all = !has_organizer;
        
        // Don't count organizers as attendees
        attendees_text.label = traverse<Component.Person>(event.attendees)
            .filter(attendee => !event.organizers.contains(attendee))
            .sort()
            .to_string(stringify_persons);
        if (String.is_empty(attendees_text.label)) {
            // "None" as in "no people"
            attendees_text.label = _("None");
        }
        
        Component.Event master = event.is_master_instance ? event : (Component.Event) event.master;
        
        // if RecurrenceRule.explain() returns null, means it cannot express the RRULE, which
        // should be made clear here
        string? explanation = null;
        if (master.rrule != null) {
            explanation = master.rrule.explain(master.get_event_date_span(Calendar.Timezone.local).start_date);
            if (explanation == null)
                explanation = _("It's complicated…");
        }
        
        recurring_explanation_label.label = explanation ?? _("Never");
        
        accept_button.label = is_update ? _("_Save") : _("C_reate");
        accept_button.use_underline = true;
        
        rotating_button_box.family = FAMILY_NORMAL;
    }
    
    private bool on_organizer_text_query_tooltip(Gtk.Widget widget, int x, int y, bool keyboard,
        Gtk.Tooltip tooltip) {
        if (!organizer_text.get_layout().is_ellipsized())
            return false;
        
        tooltip.set_text(traverse<Component.Person>(event.organizers)
            .sort()
            .to_string(stringify_persons_tooltip));
        
        return true;
    }
    
    private bool on_attendees_text_query_tooltip(Gtk.Widget widget, int x, int y, bool keyboard,
        Gtk.Tooltip tooltip) {
        if (!attendees_text.get_layout().is_ellipsized())
            return false;
        
        tooltip.set_text(traverse<Component.Person>(event.attendees)
            .filter(attendee => !event.organizers.contains(attendee))
            .sort()
            .to_string(stringify_persons_tooltip));
        
        return true;
    }
    
    private string? stringify_persons(Component.Person person, bool is_first, bool is_last) {
        // Email address followed by common separator, i.e. "alice@example.com, bob@example.com"
        return !is_last ? _("%s, ").printf(person.full_mailbox) : person.full_mailbox;
    }
    
    private string? stringify_persons_tooltip(Component.Person person, bool is_first, bool is_last) {
        return !is_last ? "%s\n".printf(person.full_mailbox) : person.full_mailbox;
    }
    
    private void on_update_time_summary() {
        // use the Message, not the Event, to load this up
        time_summary_label.visible = true;
        if (dt.date_span != null) {
            time_summary_label.label = dt.date_span.to_pretty_string(Calendar.Date.PrettyFlag.NONE);
        } else if (dt.exact_time_span != null) {
            time_summary_label.label = dt.exact_time_span.to_timezone(Calendar.Timezone.local).to_pretty_string(
                Calendar.Date.PrettyFlag.NONE, Calendar.ExactTimeSpan.PrettyFlag.NONE);
        } else {
            time_summary_label.visible = false;
        }
    }
    
    [GtkCallback]
    private void on_recurring_button_clicked() {
        // update the component with what's in the controls now
        update_component(event, true);
        
        // send off to recurring editor
        jump_to_card_by_id(RecurringCard.ID, RecurringCard.make_message(event));
    }
    
    [GtkCallback]
    private void on_edit_time_button_clicked() {
        if (dt == null)
            dt = new DateTimeCard.Message.from_event(event);
        
        // save changes with what's in the component now
        update_component(event, true);
        
        jump_to_card_by_id(DateTimeCard.ID, DateTimeCard.make_message(dt));
    }
    
    [GtkCallback]
    private void on_attendees_button_clicked() {
        if (calendar_model.active != null)
            jump_to_card_by_id(AttendeesCard.ID, AttendeesCard.make_message(event, calendar_model.active));
    }
    
    private void on_accept_button_clicked() {
        if (calendar_model.active == null)
            return;
        
        // if updating a recurring event, need to ask about update scope
        if (event.is_generated_instance && is_update) {
            rotating_button_box.family = FAMILY_RECURRING;
            
            return;
        }
        
        // create/update this instance of the event
        create_update_event(event, true);
    }
    
    // TODO: Now that a clone is being used for editing, can directly bind controls properties to
    // Event's properties and update that way ... doesn't quite work when updating the master event,
    // however
    private void update_component(Component.Event target, bool replace_dtstart) {
        target.summary = summary_entry.text;
        target.location = location_entry.text;
        target.description = description_textview.buffer.text;
        
        // if updating the master, don't replace the dtstart/dtend, but do want to adjust it from
        // DATE to DATE-TIME or vice-versa
        if (!replace_dtstart) {
            if (target.is_all_day != dt.is_all_day) {
                if (dt.is_all_day) {
                    target.timed_to_all_day_event();
                } else {
                    target.all_day_to_timed_event(
                        dt.exact_time_span.start_exact_time.to_wall_time(),
                        dt.exact_time_span.end_exact_time.to_wall_time(),
                        Calendar.Timezone.local
                    );
                }
                
                return;
            }
        }
        
        if (dt.is_all_day)
            target.set_event_date_span(dt.date_span);
        else
            target.set_event_exact_time_span(dt.exact_time_span);
    }
    
    private void create_update_event(Component.Event target, bool replace_dtstart) {
        update_component(target, replace_dtstart);
        
        if (is_update)
            update_event_async.begin(target, null);
        else
            create_event_async.begin(target, null);
    }
    
    private void on_cancel_button_clicked() {
        notify_user_closed();
    }
    
    private void on_update_all_button_clicked() {
        create_update_event(event.is_master_instance ? event : (Component.Event) event.master, false);
    }
    
    private void on_update_this_button_clicked() {
        create_update_event(event, true);
    }
    
    private void on_cancel_recurring_button_clicked() {
        rotating_button_box.family = FAMILY_NORMAL;
    }
    
    private async void create_event_async(Component.Event target, Cancellable? cancellable) {
        if (calendar_model.active == null) {
            report_error(_("Unable to create event: calendar must be specified"));
            
            return;
        }
        
        Gdk.Cursor? cursor = Toolkit.set_busy(this);
        
        Error? create_err = null;
        try {
            yield calendar_model.active.create_component_async(target, cancellable);
        } catch (Error err) {
            create_err = err;
        }
        
        Toolkit.set_unbusy(this, cursor);
        
        invite_attendees(calendar_model.active, target, true);
        
        if (create_err == null)
            notify_success();
        else
            report_error(_("Unable to create event: %s").printf(create_err.message));
    }
    
    private async void update_event_async(Component.Event target, Cancellable? cancellable) {
        if (calendar_model.active == null) {
            report_error(_("Unable to update event: calendar must be specified"));
            
            return;
        }
        
        // no original calendar source, then not an update or a move but a create
        if (target.calendar_source == null) {
            yield create_event_async(target, cancellable);
            
            return;
        }
        
        Gdk.Cursor? cursor = Toolkit.set_busy(this);
        
        Error? update_err = null;
        if (calendar_model.active == target.calendar_source) {
            // straight-up update
            try {
                yield target.calendar_source.update_component_async(target, cancellable);
            } catch (Error err) {
                update_err = err;
            }
        } else {
            // move event from one calendar to another ... start with create on new calendar
            try {
                yield calendar_model.active.create_component_async(target, cancellable);
            } catch (Error err) {
                update_err = err;
            }
            
            // only delete old one if new one created ... the new one will be reported via a
            // calendar subscription and added to the main display that way
            if (update_err == null) {
                try {
                    yield target.calendar_source.remove_all_instances_async(target.uid, cancellable);
                } catch (Error err) {
                    update_err = err;
                }
            }
        }
        
        Toolkit.set_unbusy(this, cursor);
        
        // PUBLISH is used to update an existing event
        invite_attendees(calendar_model.active, target, false);
        
        if (update_err == null)
            notify_success();
        else
            report_error(_("Unable to update event: %s").printf(update_err.message));
    }
    
    private void invite_attendees(Backing.CalendarSource calendar_source, Component.Event event,
        bool is_create) {
        // if the server handles this, don't duplicate effort
        if (calendar_source.server_sends_invites)
            return;
        
        // Make list of invitees, which are attendees who are not organizers
        Gee.List<Component.Person> invitees = traverse<Component.Person>(event.attendees)
            .filter(attendee => !event.organizers.contains(attendee))
            .filter(attendee => attendee.send_invite)
            .sort()
            .to_array_list();
        
        // no invitees, no invites
        if (invitees.size == 0)
            return;
        
        // TODO: Differentiate between instance updates and master updates
        Component.iCalendar ics = event.export_master(iCal.icalproperty_method.REQUEST);
        
        // export .ics to temporary directory so the filename is a pristine "invite.ics"
        string? temporary_filename = null;
        try {
            // "invite.ics" is the name of the file for an event invite delivered via email ...
            // please translate but keep the .ics extension, as that's common to most calendar
            // applications
            temporary_filename = File.new_for_path(DirUtils.make_tmp("california-XXXXXX")).get_child(_("invite.ics")).get_path();
            FileUtils.set_contents(temporary_filename, ics.source);
            
            // ensure this file is only readable by the user
            FileUtils.chmod(temporary_filename, (int) (Posix.S_IRUSR | Posix.S_IWUSR));
        } catch (Error err) {
            Application.instance.error_message(deck.get_toplevel() as Gtk.Window,
                _("Unable to export .ics to %s: %s").printf(
                    temporary_filename ?? "(filename not generated)", err.message));
            
            return;
        }
        
        //
        // send using xdg-email, *not* Gtk.show_uri() w/ a mailto: URI, as handling attachments
        // is best left to xdg-email
        //
        
        string[] argv = new string[0];
        argv += "xdg-email";
        argv += "--utf8";
        
        foreach (Component.Person invitee in invitees)
            argv += invitee.mailbox;
        
        argv += "--subject";
        if (String.is_empty(event.summary)) {
            argv += is_create ? _("Event invitation") : _("Updated event invitation");
        } else if (String.is_empty(event.location)) {
            argv += (is_create ? _("Invitation: %s") : _("Updated invitation: %s")).printf(event.summary);
        } else {
            // Invitation: <summary> at <location>
            argv += (is_create ? _("Invitation: %s at %s") : _("Updated invitation: %s at %s")).printf(
                event.summary, event.location);
        }
        
        argv += "--body";
        argv += generate_invite_body(event, is_create);
        
        argv += "--attach";
        argv += temporary_filename;
        
        try {
            Pid child_pid;
            Process.spawn_async(null, argv, null, SpawnFlags.SEARCH_PATH, null, out child_pid);
            Process.close_pid(child_pid);
        } catch (SpawnError err) {
            Application.instance.error_message(deck.get_toplevel() as Gtk.Window,
                _("Unable to launch mail client: %s").printf(err.message));
        }
    }
    
    private static string generate_invite_body(Component.Event event, bool is_create) {
        StringBuilder builder = new StringBuilder();
        
        // Salutations for an email
        append_line(builder, _("Hello,"));
        append_line(builder);
        append_line(builder, is_create
            ? _("Attached is an invitation to a new event:")
            : _("Attached is an updated event invitation:")
        );
        append_line(builder);
        
        // Summary
        if (!String.is_empty(event.summary))
            append_line(builder, event.summary);
        
        // Date/Time span
        string? pretty_time = event.get_event_time_pretty_string(
            Calendar.Date.PrettyFlag.NO_TODAY | Calendar.Date.PrettyFlag.INCLUDE_OTHER_YEAR,
            Calendar.ExactTimeSpan.PrettyFlag.INCLUDE_TIMEZONE,
            Calendar.Timezone.local
        );
        if (!String.is_empty(pretty_time)) {
            // Date/time of an event
            append_line(builder, _("When: %s").printf(pretty_time));
        }
        
        // Recurrences
        if (event.rrule != null) {
            string? rrule_explanation = event.rrule.explain(event.get_event_date_span(Calendar.Timezone.local).start_date);
            if (!String.is_empty(rrule_explanation))
                append_line(builder, rrule_explanation);
        }
        
        // Location
        if (!String.is_empty(event.location)) {
            // Location of an event
            append_line(builder, _("Where: %s").printf(event.location));
        }
        
        // Organizer (only list one)
        Component.Person? organizer = null;
        if (!event.organizers.is_empty) {
            organizer = traverse<Component.Person>(event.organizers)
                .sort()
                .first();
            // Who organized (scheduled or planned) the event
            append_line(builder, _("Organizer: %s").printf(organizer.full_mailbox));
        }
        
        // Attendees (strip Organizer from list)
        Gee.List<Component.Person> attendees = traverse<Component.Person>(event.attendees)
            .filter(person => organizer == null || !person.equal_to(organizer))
            .sort()
            .to_array_list();
        if (attendees.size > 0) {
            // People attending event
            append_line(builder, ngettext("Guest: %s", "Guests: %s", attendees.size).printf(
                traverse<Component.Person>(attendees).to_string(stringify_people)));
        }
        
        // Description
        if (!String.is_empty(event.description)) {
            append_line(builder);
            append_line(builder, event.description);
        }
        
        return builder.str;
    }
    
    private static void append_line(StringBuilder builder, string? str = null) {
        if (!String.is_empty(str))
            builder.append(str);
        
        builder.append("\n");
    }
    
    private static string? stringify_people(Component.Person person, bool is_first, bool is_last) {
        // Email separator, i.e. "alice@example.com, bob@example.com"
        return !is_last ? _("%s, ").printf(person.full_mailbox) : person.full_mailbox;
    }
}

}
