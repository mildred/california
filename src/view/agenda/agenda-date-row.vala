/* Copyright 2014-2015 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.View.Agenda {

[GtkTemplate (ui = "/org/yorba/california/rc/view-agenda-date-row.ui")]
private class DateRow : Gtk.Box {
    private const Calendar.Date.PrettyFlag DATE_PRETTY_FLAGS =
        Calendar.Date.PrettyFlag.INCLUDE_OTHER_YEAR;
    
    private static Gtk.SizeGroup date_label_size_group;
    
    public Calendar.Date date { get; private set; }
    
    public int size { get { return listbox_model.size; } }
    
    [GtkChild]
    private Gtk.Label date_label;
    
    [GtkChild]
    private Gtk.ListBox event_listbox;
    
    private unowned Controller owner;
    private Toolkit.ListBoxModel<Component.Event> listbox_model;
    
    public signal void empty();
    
    public DateRow(Controller owner, Calendar.Date date) {
        this.owner = owner;
        this.date = date;
        
        listbox_model = new Toolkit.ListBoxModel<Component.Event>(event_listbox, model_presentation,
            model_filter);
        listbox_model.notify[Toolkit.ListBoxModel.PROP_SIZE].connect(on_listbox_model_size_changed);
        
        // Don't prelight the DateRows, as they can't be selected or activated
        listbox_model.row_added.connect((row, item) => {
            Toolkit.prevent_prelight(row);
        });
        
        // all date labels are same width
        date_label_size_group.add_widget(date_label);
        
        // Because some date text labels are relative (i.e. "Today"), refresh when the date changes
        Calendar.System.instance.today_changed.connect(update_ui);
        
        update_ui();
    }
    
    ~DateRow() {
        Calendar.System.instance.today_changed.disconnect(update_ui);
    }
    
    internal static void init() {
        date_label_size_group = new Gtk.SizeGroup(Gtk.SizeGroupMode.HORIZONTAL);
    }
    
    internal static void terminate() {
        date_label_size_group = null;
    }
    
    private void update_ui() {
        date_label.label = date.to_pretty_string(DATE_PRETTY_FLAGS);
    }
    
    private void on_listbox_model_size_changed() {
        if (listbox_model.size == 0)
            empty();
    }
    
    public void add_event(Component.Event event) {
        if (!listbox_model.add(event))
            return;
        
        // watch for date changes, which affect if the event is represented here
        event.notify[Component.Event.PROP_DATE_SPAN].connect(on_event_date_changed);
        event.notify[Component.Event.PROP_EXACT_TIME_SPAN].connect(on_event_date_changed);
    }
    
    public void remove_event(Component.Event event) {
        if (!listbox_model.remove(event))
            return;
        
        event.notify[Component.Event.PROP_DATE_SPAN].disconnect(on_event_date_changed);
        event.notify[Component.Event.PROP_EXACT_TIME_SPAN].disconnect(on_event_date_changed);
    }
    
    private void on_event_date_changed(Object o, ParamSpec pspec) {
        Component.Event event = (Component.Event) o;
        
        if (!(date in event.get_event_date_span(Calendar.Timezone.local)))
            remove_event(event);
    }
    
    public void notify_calendar_visibility_changed(Backing.CalendarSource calendar_source) {
        foreach (Component.Event event in listbox_model.all()) {
            if (event.calendar_source == calendar_source)
                listbox_model.mutated(event);
        }
    }
    
    private Gtk.Widget model_presentation(Component.Event event) {
        return new EventRow(owner, event);
    }
    
    private bool model_filter(Component.Event event) {
        return event.calendar_source.visible;
    }
}

}

