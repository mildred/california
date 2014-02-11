/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Host {

/**
 * A blank "form" of widgets for the user to enter or edit event details.
 */

[GtkTemplate (ui = "/org/yorba/california/rc/create-event.ui")]
public class CreateEvent : Gtk.Grid {
    public const string PROP_NEW_EVENT = "new-event";
    public const string PROP_CALENDAR_SOURCE = "calendar-source";
    
    private const int START_HOUR = 0;
    private const int END_HOUR = 23;
    private const int MIN_DIVISIONS = 15;
    
    /**
     * Set to a {@link Component.Blank} when all required fields are set and the user presses the
     * Create button.
     */
    public Component.Blank? new_event { get; private set; default = null; }
    
    /**
     * Set as the user selects {@link Backing.CalendarSource}s.
     */
    public Backing.CalendarSource? calendar_source { get; private set; default = null; }
    
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
    private Gtk.Button create_button;
    
    private Gee.HashMap<string, Calendar.WallTime> time_map = new Gee.HashMap<string, Calendar.WallTime>();
    private Calendar.Date start_date;
    private Calendar.Date end_date;
    private Gee.List<Backing.CalendarSource> calendar_sources;
    
    public CreateEvent(Calendar.ExactTimeSpan initial) {
        // initialize start and end *dates*
        start_date = initial.start_date;
        dtstart_date_button.label = initial.start_date.to_standard_string();
        
        end_date = initial.end_date;
        dtend_date_button.label = initial.end_date.to_standard_string();
        
        // initialize start and end *time* (as in, wall clock time)
        Calendar.WallTime initial_start = new Calendar.WallTime.from_exact_time(initial.start_exact_time);
        Calendar.WallTime initial_end = new Calendar.WallTime.from_exact_time(initial.end_exact_time);
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
            int cmp = initial_start.compare_to(current);
            if (cmp == 0)
                dtstart_active_index = index;
            else if (cmp > 0)
                dtstart_active_index = index + 1;
            
            cmp = initial_end.compare_to(current);
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
        
        // hide start/end time widgets if an all-day event
        all_day_toggle.bind_property("active", dtstart_time_combo, "visible",
            BindingFlags.INVERT_BOOLEAN | BindingFlags.SYNC_CREATE);
        all_day_toggle.bind_property("active", dtend_time_combo, "visible",
            BindingFlags.INVERT_BOOLEAN | BindingFlags.SYNC_CREATE);
        
        // initialize available calendars
        calendar_sources = Backing.Manager.instance.get_sources_of_type<Backing.CalendarSource>();
        foreach (Backing.Source source in calendar_sources)
            calendar_combo.append_text(source.title);
        
        // keep attribute up-to-date
        calendar_combo.notify["active"].connect(() => {
            if (calendar_combo.active >= 0 && calendar_combo.active < calendar_sources.size)
                calendar_source = calendar_sources[calendar_combo.active];
            else
                calendar_source = null;
        });
        
        // set now that hanlder is in place
        calendar_combo.set_active(0);
        
        // create button is active only if summary is filled out; all other fields (so far)
        // guarantee valid values at all times
        summary_entry.bind_property("text-length", create_button, "sensitive",
            BindingFlags.SYNC_CREATE);
    }
    
    [GtkCallback]
    private void on_date_button_clicked(Gtk.Button button) {
    }
    
    [GtkCallback]
    private void on_create_clicked() {
        if (calendar_source == null)
            return;
        
        Component.Blank blank = new Component.Blank(Component.VType.EVENT);
        blank.summary = summary_entry.text;
        
        if (all_day_toggle.active) {
            blank.set_start_end_date(new Calendar.DateSpan(start_date, end_date));
        } else {
            TimeZone tz = new TimeZone.local();
            blank.set_start_end_exact_time(
                new Calendar.ExactTimeSpan(
                    new Calendar.ExactTime(tz, start_date, time_map.get(dtstart_time_combo.get_active_text())),
                    new Calendar.ExactTime(tz, end_date, time_map.get(dtend_time_combo.get_active_text()))
                )
            );
        }
        
        // only set now, as the "notify" signal is used to inform caller that user is ready
        new_event = blank;
    }
}

}
