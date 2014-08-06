/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Host {

[GtkTemplate (ui = "/org/yorba/california/rc/event-time-settings.ui")]
public class EventTimeSettings : Gtk.Box, Toolkit.Card {
    public const string ID = "CaliforniaHostEventTimeSettings";
    
    public class Message : Object {
        public Calendar.DateSpan? date_span { get; private set; default = null; }
        
        public Calendar.ExactTimeSpan? exact_time_span { get; private set; default = null; }
        
        public bool is_all_day { get { return exact_time_span == null; } }
        
        public Message.for_date_span(Calendar.DateSpan date_span) {
            reset_date_span(date_span);
        }
        
        public Message.for_exact_time_span(Calendar.ExactTimeSpan exact_time_span) {
            reset_exact_time_span(exact_time_span);
        }
        
        public Message.from_event(Component.Event event) {
            if (event.is_all_day)
                reset_date_span(event.date_span);
            else
                reset_exact_time_span(event.exact_time_span);
        }
        
        public void reset_date_span(Calendar.DateSpan date_span) {
            this.date_span = date_span;
            exact_time_span = null;
        }
        
        public void reset_exact_time_span(Calendar.ExactTimeSpan exact_time_span) {
            date_span = null;
            this.exact_time_span = exact_time_span;
        }
        
        public Calendar.DateSpan get_event_date_span(Calendar.Timezone? tz) {
        if (date_span != null)
            return date_span;
        
        return new Calendar.DateSpan.from_exact_time_span(
            tz != null ? exact_time_span.to_timezone(tz) : exact_time_span);
        }
    }
    
    [GtkChild]
    private Gtk.Label summary_label;
    
    [GtkChild]
    private Gtk.Box from_box;
    
    [GtkChild]
    private Gtk.Box to_box;
    
    [GtkChild]
    private Gtk.CheckButton all_day_checkbutton;
    
    [GtkChild]
    private Gtk.Button ok_button;
    
    public string card_id { get { return ID; } }
    public string? title { get { return null; } }
    public Gtk.Widget? default_widget { get { return null; } }
    public Gtk.Widget? initial_focus { get { return null; } }
    
    private Message? message = null;
    private DateTimeWidget from_widget = new DateTimeWidget();
    private DateTimeWidget to_widget = new DateTimeWidget();
    
    public EventTimeSettings() {
        // need to manually pack the date/time widgets
        from_box.pack_start(from_widget);
        to_box.pack_start(to_widget);
        
        from_widget.notify[DateTimeWidget.PROP_DATE].connect(on_from_changed);
        from_widget.notify[DateTimeWidget.PROP_WALL_TIME].connect(on_from_changed);
        to_widget.notify[DateTimeWidget.PROP_DATE].connect(on_to_changed);
        to_widget.notify[DateTimeWidget.PROP_WALL_TIME].connect(on_to_changed);
        all_day_checkbutton.notify["active"].connect(on_update_summary);
        
        from_widget.bind_property(DateTimeWidget.PROP_OUT_OF_RANGE, ok_button, "sensitive",
            BindingFlags.SYNC_CREATE, transform_oor_to_sensitive);
        to_widget.bind_property(DateTimeWidget.PROP_OUT_OF_RANGE, ok_button, "sensitive",
            BindingFlags.SYNC_CREATE, transform_oor_to_sensitive);
        
        all_day_checkbutton.bind_property("active", from_widget, DateTimeWidget.PROP_ENABLE_TIME,
            BindingFlags.SYNC_CREATE | BindingFlags.INVERT_BOOLEAN);
        all_day_checkbutton.bind_property("active", to_widget, DateTimeWidget.PROP_ENABLE_TIME,
            BindingFlags.SYNC_CREATE | BindingFlags.INVERT_BOOLEAN);
        
        Calendar.System.instance.is_24hr_changed.connect(on_update_summary);
    }
    
    ~EventTimeSettings() {
        Calendar.System.instance.is_24hr_changed.disconnect(on_update_summary);
    }
    
    private bool transform_oor_to_sensitive(Binding binding, Value source_value, ref Value target_value) {
        target_value = !to_widget.out_of_range && !from_widget.out_of_range;
        
        return true;
    }
    
    public void jumped_to(Toolkit.Card? from, Toolkit.Card.Jump reason, Value? message_value) {
        message = (Message) message_value;
        
        Calendar.DateSpan date_span = message.get_event_date_span(Calendar.Timezone.local);
        from_widget.date = date_span.start_date;
        to_widget.date = date_span.end_date;
        
        // only set wall time if not all day; let old wall times float so user can return to them
        // later while Deck is active
        if (message.exact_time_span != null) {
            Calendar.ExactTimeSpan time_span = message.exact_time_span.to_timezone(Calendar.Timezone.local);
            from_widget.wall_time = time_span.start_exact_time.to_wall_time();
            to_widget.wall_time = time_span.end_exact_time.to_wall_time();
        } else {
            // set to defaults in case user wants to change from all-day to timed event
            from_widget.wall_time = Calendar.System.now.to_wall_time().round(15, Calendar.TimeUnit.MINUTE,
                null);
            if (date_span.is_same_day) {
                // one-hour event is default
                to_widget.wall_time = from_widget.wall_time.adjust(1, Calendar.TimeUnit.HOUR, null);
            } else {
                // different days, same time on each day
                to_widget.wall_time = from_widget.wall_time;
            }
        }
        
        all_day_checkbutton.active = (message.exact_time_span == null);
    }
    
    [GtkCallback]
    private void on_cancel_button_clicked() {
        jump_back();
    }
    
    [GtkCallback]
    private void on_ok_button_clicked() {
        if (all_day_checkbutton.active)
            message.reset_date_span(get_date_span());
        else
            message.reset_exact_time_span(get_exact_time_span());
        
        jump_to_card_by_name(CreateUpdateEvent.ID, message);
    }
    
    // This does not respect the all-day checkbox
    private Calendar.DateSpan get_date_span() {
        return new Calendar.DateSpan(from_widget.date, to_widget.date);
    }
    
    // This does not respect the all-day checkbox
    private Calendar.ExactTimeSpan get_exact_time_span() {
        return new Calendar.ExactTimeSpan(
            new Calendar.ExactTime(Calendar.System.timezone, from_widget.date, from_widget.wall_time),
            new Calendar.ExactTime(Calendar.System.timezone, to_widget.date, to_widget.wall_time)
        );
    }
    
    private void on_update_summary() {
        Calendar.Date.PrettyFlag date_flags = Calendar.Date.PrettyFlag.NONE;
        Calendar.ExactTimeSpan.PrettyFlag time_flags = Calendar.ExactTimeSpan.PrettyFlag.NONE;
        
        if (all_day_checkbutton.active)
            summary_label.label = get_date_span().to_pretty_string(date_flags);
        else
            summary_label.label = get_exact_time_span().to_pretty_string(date_flags, time_flags);
    }
    
    private void on_from_changed() {
        // clamp to_widget to not allow earlier date/times than from_widget
        to_widget.floor = new Calendar.ExactTime(Calendar.System.timezone, from_widget.date,
            from_widget.wall_time);
        
        on_update_summary();
    }
    
    private void on_to_changed() {
        // clamp from_widget to not allow later date/times than to_widget
        from_widget.ceiling = new Calendar.ExactTime(Calendar.System.timezone, to_widget.date,
            to_widget.wall_time);
        
        on_update_summary();
    }
}

}

