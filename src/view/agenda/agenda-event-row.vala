/* Copyright 2014-2015 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.View.Agenda {

[GtkTemplate (ui = "/org/yorba/california/rc/view-agenda-event-row.ui")]
private class EventRow : Gtk.Box, Toolkit.MutableWidget {
    private const Calendar.WallTime.PrettyFlag TIME_PRETTY_FLAGS = Calendar.WallTime.PrettyFlag.NONE;
    
    private static Gtk.SizeGroup time_label_size_group;
    
    public new Component.Event event { get; private set; }
    
    [GtkChild]
    private Gtk.EventBox time_eventbox;
    
    [GtkChild]
    private Gtk.Label time_label;
    
    [GtkChild]
    private Gtk.EventBox summary_eventbox;
    
    [GtkChild]
    private Gtk.Label summary_label;
    
    [GtkChild]
    private Gtk.Image guests_icon;
    
    [GtkChild]
    private Gtk.Image recurring_icon;
    
    private Controller owner;
    private Toolkit.ButtonConnector button_connector = new Toolkit.ButtonConnector();
    private Toolkit.MotionConnector motion_connector = new Toolkit.MotionConnector();
    
    public EventRow(Controller owner, Component.Event event) {
        this.owner = owner;
        this.event = event;
        
        // all time labels are the same width
        time_label_size_group.add_widget(time_label);
        
        // capture motion and mouse clicks for both labels
        button_connector.connect_to(time_eventbox);
        button_connector.connect_to(summary_eventbox);
        motion_connector.connect_to(time_eventbox);
        motion_connector.connect_to(summary_eventbox);
        
        button_connector.clicked.connect(on_event_clicked);
        button_connector.double_clicked.connect(on_event_double_clicked);
        motion_connector.entered.connect(on_event_entered_exited);
        motion_connector.exited.connect(on_event_entered_exited);
        motion_connector.motion.connect(on_event_motion);
        
        // watch for changes to the event
        event.notify[Component.Event.PROP_SUMMARY].connect(update_ui);
        event.notify[Component.Event.PROP_DATE_SPAN].connect(update_ui);
        event.notify[Component.Event.PROP_EXACT_TIME_SPAN].connect(update_ui);
        event.notify[Component.Event.PROP_LOCATION].connect(update_ui);
        event.notify[Component.Instance.PROP_ATTENDEES].connect(update_ui);
        event.notify[Component.Instance.PROP_ORGANIZERS].connect(update_ui);
        event.notify[Component.Instance.PROP_RRULE].connect(update_ui);
        
        // watch for changes to the calendar (which is immutable for the lifetime of the Event
        // instances)
        event.calendar_source.notify[Backing.Source.PROP_COLOR].connect(update_ui);
        
        // .. and assume that all property changes cause sort-order changes (no reliable way to
        // know exactly when for now)
        event.altered.connect(() => { mutated(); });
        
        // .. date formatting changes
        Calendar.System.instance.is_24hr_changed.connect(update_ui);
        Calendar.System.instance.zone_changed.connect(update_ui);
        Calendar.System.instance.timezone_changed.connect(update_ui);
        
        update_ui();
    }
    
    ~EventRow() {
        event.notify[Component.Event.PROP_SUMMARY].disconnect(update_ui);
        event.notify[Component.Event.PROP_DATE_SPAN].disconnect(update_ui);
        event.notify[Component.Event.PROP_EXACT_TIME_SPAN].disconnect(update_ui);
        event.notify[Component.Event.PROP_LOCATION].disconnect(update_ui);
        event.notify[Component.Instance.PROP_ATTENDEES].disconnect(update_ui);
        event.notify[Component.Instance.PROP_ORGANIZERS].disconnect(update_ui);
        event.notify[Component.Instance.PROP_RRULE].disconnect(update_ui);
        
        event.calendar_source.notify[Backing.Source.PROP_COLOR].disconnect(update_ui);
        
        Calendar.System.instance.is_24hr_changed.disconnect(update_ui);
        Calendar.System.instance.zone_changed.disconnect(update_ui);
        Calendar.System.instance.timezone_changed.disconnect(update_ui);
    }
    
    internal static void init() {
        time_label_size_group = new Gtk.SizeGroup(Gtk.SizeGroupMode.HORIZONTAL);
    }
    
    internal static void terminate() {
        time_label_size_group = null;
    }
    
    private void update_ui() {
        if (event.is_all_day) {
            time_label.label = _("All day");
        } else {
            Calendar.ExactTimeSpan time_span = event.exact_time_span.to_timezone(Calendar.Timezone.local);
            
            // hex value is an endash
            time_label.label = "%s &#x2013; %s".printf(
                time_span.start_exact_time.to_wall_time().to_pretty_string(TIME_PRETTY_FLAGS),
                time_span.end_exact_time.to_wall_time().to_pretty_string(TIME_PRETTY_FLAGS)
            );
        }
        
        if (!String.is_empty(event.location)) {
            // hex value is an endash
            summary_label.label = "<span color=\"%s\">%s</span> &#x2013; %s".printf(
                event.calendar_source.color, GLib.Markup.escape_text(event.summary),
                GLib.Markup.escape_text(event.location));
        } else {
            summary_label.label = "<span color=\"%s\">%s</span>".printf(
                event.calendar_source.color, GLib.Markup.escape_text(event.summary));
        }
        
        // only show guests icon if attendees include someone not an organizer
        guests_icon.visible = traverse<Component.Person>(event.attendees)
            .filter(person => !event.organizers.contains(person))
            .is_nonempty();
        recurring_icon.visible = event.rrule != null;
    }
    
    private bool on_event_clicked(Toolkit.ButtonEvent details) {
        owner.request_display_event(event, details.widget, details.press_point);
        
        return Toolkit.STOP;
    }
    
    private bool on_event_double_clicked(Toolkit.ButtonEvent details) {
        owner.request_edit_event(event, details.widget, details.press_point);
        
        return Toolkit.STOP;
    }
    
    private void on_event_entered_exited(Toolkit.MotionEvent details) {
        // when entering or leaving cell, reset the cursor
        Toolkit.set_toplevel_cursor(details.widget, null);
    }
    
    private void on_event_motion(Toolkit.MotionEvent details) {
        // if hovering over an event, show the "hyperlink" cursor
        Toolkit.set_toplevel_cursor(details.widget, Gdk.CursorType.HAND1);
    }
}

}

