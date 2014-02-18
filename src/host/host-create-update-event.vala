/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Host {

/**
 * A blank "form" of widgets for the user to enter or update event details.
 */

[GtkTemplate (ui = "/org/yorba/california/rc/create-update-event.ui")]
public class CreateUpdateEvent : Gtk.Grid {
    private const int START_HOUR = 0;
    private const int END_HOUR = 23;
    private const int MIN_DIVISIONS = 15;
    
    [GtkChild]
    private Gtk.Label title_label;
    
    [GtkChild]
    private Gtk.Entry summary_entry;
    
    [GtkChild]
    private Gtk.Button dtstart_date_button;
    
    [GtkChild]
    private Gtk.ComboBoxText dtstart_time_combo;
    
    [GtkChild]
    private Gtk.Button dtend_date_button;
    
    [GtkChild]
    private Gtk.ComboBoxText dtend_time_combo;
    
    [GtkChild]
    private Gtk.CheckButton all_day_toggle;
    
    [GtkChild]
    private Gtk.ComboBoxText calendar_combo;
    
    [GtkChild]
    private Gtk.Button accept_button;
    
    private new Component.Event event;
    private Gee.HashMap<string, Calendar.WallTime> time_map = new Gee.HashMap<string, Calendar.WallTime>();
    private Gee.List<Backing.CalendarSource> calendar_sources;
    private Backing.CalendarSource? original_calendar_source;
    private Backing.CalendarSource? selected_calendar_source;
    private Calendar.DateSpan selected_date_span;
    private bool is_update = false;
    
    public signal void create_event(Component.Event event);
    
    public signal void update_event(Backing.CalendarSource? original_source, Component.Event event);
    
    public CreateUpdateEvent(Calendar.ExactTimeSpan initial) {
        event = new Component.Event.blank();
        event.set_event_exact_time_span(initial);
        original_calendar_source = null;
        
        init();
    }
    
    public CreateUpdateEvent.all_day(Calendar.DateSpan initial) {
        event = new Component.Event.blank();
        event.set_event_date_span(initial);
        original_calendar_source = null;
        
        init();
    }
    
    public CreateUpdateEvent.update(Component.Event event) {
        this.event = event;
        original_calendar_source = event.calendar_source;
        
        title_label.label = _("Update Event");
        accept_button.label = _("_Update");
        is_update = true;
        
        init();
    }
    
    private void init() {
        if (event.summary != null)
            summary_entry.text = event.summary;
        
        // date/date-time must be set in the Event prior to this call
        Calendar.WallTime initial_start_time, initial_end_time;
        if (event.exact_time_span != null) {
            all_day_toggle.active = false;
            selected_date_span = event.exact_time_span.get_date_span();
            initial_start_time = new Calendar.WallTime.from_exact_time(event.exact_time_span.start_exact_time);
            initial_end_time = new Calendar.WallTime.from_exact_time(event.exact_time_span.end_exact_time);
        } else {
            assert(event.date_span != null);
            
            all_day_toggle.active = true;
            selected_date_span = event.date_span;
            initial_start_time = new Calendar.WallTime.from_exact_time(Calendar.now());
            initial_end_time = new Calendar.WallTime.from_exact_time(
                Calendar.now().adjust_time(1, Calendar.TimeUnit.HOUR));
        }
        
        dtstart_date_button.label = selected_date_span.start_date.to_standard_string();
        dtend_date_button.label = selected_date_span.end_date.to_standard_string();
        
        // initialize start and end time (as in, wall clock time)
        Calendar.WallTime current = new Calendar.WallTime(START_HOUR, Calendar.WallTime.MIN_MINUTE, 0);
        Calendar.WallTime end = new Calendar.WallTime(END_HOUR, Calendar.WallTime.MAX_MINUTE, 0);
        int index = 0;
        int dtstart_active_index = -1, dtend_active_index = -1;
        bool rollover = false;
        while (current.compare_to(end) <= 0 && !rollover) {
            string fmt = current.to_pretty_string(Calendar.WallTime.PrettyFlag.NONE);
            
            dtstart_time_combo.append_text(fmt);
            dtend_time_combo.append_text(fmt);
            
            // use the latest time for each end of the span to initialize combo boxes, looking for
            // exact match, otherwise taking the *next* index (to default to the future slot, not
            // one that's past)
            int cmp = initial_start_time.compare_to(current);
            if (cmp == 0)
                dtstart_active_index = index;
            else if (cmp > 0)
                dtstart_active_index = index + 1;
            
            cmp = initial_end_time.compare_to(current);
            if (cmp == 0)
                dtend_active_index = index;
            else if (cmp > 0)
                dtend_active_index = index + 1;
            
            index++;
            
            time_map.set(fmt, current);
            current = current.adjust(MIN_DIVISIONS, Calendar.TimeUnit.MINUTE, out rollover);
        }
        
        // set initial indices, careful to avoid overrun
        dtstart_time_combo.set_active(dtstart_active_index.clamp(0, index - 1));
        dtend_time_combo.set_active(dtend_active_index.clamp(0, index - 1));
        
        // hide start/end time widgets if an all-day event ..."no-show-all" needed to avoid the
        // merciless effects of show_all()
        all_day_toggle.bind_property("active", dtstart_time_combo, "visible",
            BindingFlags.INVERT_BOOLEAN | BindingFlags.SYNC_CREATE);
        dtstart_time_combo.no_show_all = true;
        all_day_toggle.bind_property("active", dtend_time_combo, "visible",
            BindingFlags.INVERT_BOOLEAN | BindingFlags.SYNC_CREATE);
        dtend_time_combo.no_show_all = true;
        
        // initialize available calendars
        calendar_sources = Backing.Manager.instance.get_sources_of_type<Backing.CalendarSource>();
        index = 0;
        int calendar_source_index = 0;
        foreach (Backing.Source source in calendar_sources) {
            calendar_combo.append_text(source.title);
            if (source == event.calendar_source)
                calendar_source_index = index;
            
            index++;
        }
        
        // keep attribute up-to-date
        calendar_combo.notify["active"].connect(() => {
            if (calendar_combo.active >= 0 && calendar_combo.active < calendar_sources.size)
                selected_calendar_source = calendar_sources[calendar_combo.active];
            else
                selected_calendar_source = null;
        });
        
        // set now that handlers are in place
        calendar_combo.set_active(calendar_source_index);
        
        // create button is active only if summary is filled out; all other fields (so far)
        // guarantee valid values at all times
        summary_entry.bind_property("text-length", accept_button, "sensitive",
            BindingFlags.SYNC_CREATE);
    }
    
    [GtkCallback]
    private void on_date_button_clicked(Gtk.Button button) {
    }
    
    [GtkCallback]
    private void on_accept_clicked() {
        if (selected_calendar_source == null)
            return;
        
        event.calendar_source = selected_calendar_source;
        event.summary = summary_entry.text;
        
        if (all_day_toggle.active) {
            event.set_event_date_span(selected_date_span);
        } else {
            // use existing timezone unless not specified in original event
            TimeZone tz = (event.exact_time_span != null) ? event.exact_time_span.start_exact_time.tz
                : new TimeZone.local();
            event.set_event_exact_time_span(
                new Calendar.ExactTimeSpan(
                    new Calendar.ExactTime(tz, selected_date_span.start_date,
                        time_map.get(dtstart_time_combo.get_active_text())),
                    new Calendar.ExactTime(tz, selected_date_span.end_date,
                        time_map.get(dtend_time_combo.get_active_text()))
                )
            );
        }
        
        if (is_update)
            update_event(original_calendar_source, event);
        else
            create_event(event);
    }
}

}
