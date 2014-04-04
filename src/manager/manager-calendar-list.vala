/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Manager {

/**
 * A list of available calendars and basic configuration controls.
 */

[GtkTemplate (ui = "/org/yorba/california/rc/calendar-manager-list.ui")]
public class CalendarList : Gtk.Grid, Toolkit.Card {
    public const string ID = "CalendarList";
    
    public string card_id { get { return ID; } }
    
    public string? title { get { return null; } }
    
    public Gtk.Widget? default_widget { get { return null; } }
    
    public Gtk.Widget? initial_focus { get { return calendar_list_box; } }
    
    [GtkChild]
    private Gtk.ListBox calendar_list_box;
    
    public CalendarList() {
        // if already open, initialize now
        if (Backing.Manager.instance.is_open)
            init();
        
        // otherwise, initialize when it does open
        Backing.Manager.instance.notify[Backing.Manager.PROP_IS_OPEN].connect(on_manager_opened_closed);
    }
    
    ~CalendarList() {
        Backing.Manager.instance.notify[Backing.Manager.PROP_IS_OPEN].disconnect(on_manager_opened_closed);
    }
    
    public void jumped_to(Toolkit.Card? from, Value? message) {
    }
    
    private void on_manager_opened_closed() {
        if (Backing.Manager.instance.is_open)
            init();
        else
            clear();
    }
    
    private void init() {
        assert(Backing.Manager.instance.is_open);
        
        foreach (Backing.CalendarSource source in
            Backing.Manager.instance.get_sources_of_type<Backing.CalendarSource>()) {
            calendar_list_box.add(new CalendarListItem(source));
        }
    }
    
    private void clear() {
        foreach (unowned Gtk.Widget child in calendar_list_box.get_children()) {
            if (child is CalendarListItem)
                calendar_list_box.remove(child);
        };
    }
    
    [GtkCallback]
    private void on_calendar_list_box_row_activated(Gtk.ListBoxRow row) {
        CalendarListItem item = (CalendarListItem) row.get_child();
        debug("activated %s", item.source.to_string());
    }
    
    [GtkCallback]
    private void on_close_button_clicked() {
        dismissed(true);
    }
}

}

