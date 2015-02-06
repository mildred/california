/* Copyright 2014-2015 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.View.Agenda {

public class Controller : BaseObject, View.Controllable {
    public const string PROP_CURRENT_SPAN = "current-span";
    
    public const string VIEW_ID = "agenda";
    
    private class Container : Gtk.ScrolledWindow, View.Container {
        private unowned Controllable _owner;
        public unowned Controllable owner { get { return _owner; } }
        
        public Container(Controller controller, Gtk.Widget child) {
            _owner = controller;
            
            add_with_viewport(child);
        }
    }
    
    /**
     * @inheritDoc
     */
    public string id { get { return VIEW_ID; } }
    
    /**
     * @inheritDoc
     */
    public string title { get { return _("Agenda"); } }
    
    /**
     * @inheritDoc
     */
    public string current_label { get; protected set; }
    
    /**
     * @inheritDoc
     */
    public bool is_viewing_today { get; protected set; }
    
    /**
     * @inheritDoc
     */
    public ChronologyMotion motion { get { return ChronologyMotion.VERTICAL; } }
    
    /**
     * @inheritDoc
     */
    public bool in_transition { get; protected set; }
    
    /**
     * {@link View.Palette} for the entire view.
     */
    public View.Palette palette { get; private set; }
    
    /**
     * Current {@link Calendar.DateSpan} being displayed.
     */
    public Calendar.DateSpan current_span { get; private set; }
    
    private Container container;
    private Backing.CalendarSubscriptionManager? subscriptions = null;
    private Gtk.ListBox listbox = new Gtk.ListBox();
    private Toolkit.ListBoxModel<Calendar.Date> listbox_model;
    private LoadMoreRow load_more_row;
    
    public Controller(View.Palette palette) {
        this.palette = palette;
        
        container = new Container(this, listbox);
        Toolkit.unity_fixup_background(container);
        
        listbox_model = new Toolkit.ListBoxModel<Calendar.Date>(listbox, model_presentation);
        
        // Don't prelight the DateRows, as they can't be selected or activated
        listbox_model.row_added.connect((row, item) => {
            Toolkit.prevent_prelight(row);
        });
        
        listbox.selection_mode = Gtk.SelectionMode.NONE;
        listbox.activate_on_single_click = false;
        
        // this will initialize current_span
        reset_subscriptions(
            new Calendar.DateSpan(
                Calendar.System.today,
                Calendar.System.today.adjust_by(2, Calendar.DateUnit.MONTH)
            )
        );
        
        // LoadMoreRow is persistent and always sorts to the end of the list (see model_presentation)
        // (need to add after setting current_span in reset_subscriptions)
        load_more_row = new LoadMoreRow(this);
        load_more_row.load_more.connect(on_load_more);
        listbox_model.add(Calendar.Date.latest);
    }
    
    /**
     * @inheritDoc
     */
    public View.Container get_container() {
        return container;
    }
    
    /**
     * @inheritDoc
     */
    public void next() {
        reduce_subscriptions_start(current_span.start_date.adjust_by(1, Calendar.DateUnit.DAY));
    }
    
    /**
     * @inheritDoc
     */
    public void previous() {
        expand_subscriptions(current_span.start_date.adjust_by(-1, Calendar.DateUnit.DAY));
    }
    
    /**
     * @inheritDoc
     */
    public void today() {
        reset_subscriptions(new Calendar.DateSpan(Calendar.System.today, current_span.end_date));
    }
    
    /**
     * @inheritDoc
     */
    public void unselect_all() {
        // no notion of selection in Agenda view
    }
    
    /**
     * @inheritDoc
     */
    public Gtk.Widget? get_widget_for_date(Calendar.Date date) {
        return listbox_model.get_widget_for_item(date);
    }
    
    private Gtk.Widget model_presentation(Calendar.Date date) {
        if (date.equal_to(Calendar.Date.latest))
            return load_more_row;
        
        DateRow date_row = new DateRow(this, date);
        date_row.empty.connect(on_date_row_empty);
        
        return date_row;
    }
    
    private void on_date_row_empty(DateRow date_row) {
        listbox_model.remove(date_row.date);
    }
    
    private void on_load_more() {
        expand_subscriptions(current_span.end_date.adjust_by(1, Calendar.DateUnit.MONTH));
    }
    
    private Iterable<DateRow> traverse_date_rows() {
        return traverse<Calendar.Date>(listbox_model.all())
            .map_nonnull<DateRow>(date => listbox_model.get_widget_for_item(date) as DateRow);
    }
    
    // Make existing DateRow widgets visible depending on if they're in the current_span; don't
    // remove them to allow them to continue to receive event notifications in case the window is
    // widened again to show them
    private void show_hide_date_rows() {
        traverse_date_rows()
            .iterate(date_row => date_row.visible = date_row.date in current_span);
    }
    
    private void clear_date_rows() {
        traverse_date_rows()
            .iterate(date_row => listbox_model.remove(date_row.date));
    }
    
    private void reset_subscriptions(Calendar.DateSpan new_span) {
        current_span = new_span;
        
        clear_date_rows();
        
        subscriptions = new Backing.CalendarSubscriptionManager(
            current_span.to_exact_time_span(Calendar.Timezone.local));
        
        subscriptions.calendar_added.connect(on_calendar_added);
        subscriptions.calendar_removed.connect(on_calendar_removed);
        subscriptions.instance_added.connect(on_instance_added_or_altered);
        subscriptions.instance_removed.connect(on_instance_removed);
        
        subscriptions.start_async.begin();
        
        update_view_details();
    }
    
    private void expand_subscriptions(Calendar.Date expansion) {
        current_span = current_span.expand(expansion);
        
        // make previously invisible widgets (due to window reduction) visible again if in new span
        show_hide_date_rows();
        
        // to avoid adding a lot of little expansions (which is expensive), add them a month at a
        // time ... first check if subscription expansion even necessary, and if so, on which ends
        // of the span ... first, convert to DateSpan
        Calendar.DateSpan sub_span = new Calendar.DateSpan.from_exact_time_span(
            subscriptions.window.to_timezone(Calendar.Timezone.local));
        
        bool expanded = false;
        
        // if necessary, walk the subscription start date back one month from requested date
        if (!(current_span.start_date in sub_span)) {
            Calendar.Date new_sub_start = sub_span.start_date.adjust_by(-1, Calendar.DateUnit.MONTH);
            if (current_span.start_date.compare_to(new_sub_start) < 0)
                new_sub_start = current_span.start_date;
            
            subscriptions.expand_window_async.begin(
                new_sub_start.to_exact_time_span(Calendar.Timezone.local).start_exact_time);
            expanded = true;
        }
        
        // do the same for the subscription end date
        if (!(current_span.end_date in sub_span)) {
            Calendar.Date new_sub_end = sub_span.end_date.adjust_by(1, Calendar.DateUnit.MONTH);
            if (current_span.end_date.compare_to(new_sub_end) > 0)
                new_sub_end = current_span.end_date;
            
            subscriptions.expand_window_async.begin(
                new_sub_end.to_exact_time_span(Calendar.Timezone.local).end_exact_time);
            expanded = true;
        }
        
        if (expanded)
            debug("Agenda subscription window expanded to %s", subscriptions.window.to_string());
        
        update_view_details();
    }
    
    private void reduce_subscriptions_start(Calendar.Date new_start) {
        current_span = current_span.reduce_from_start(new_start);
        
        // make previously invisible widgets (due to window reduction) visible again if in new span
        show_hide_date_rows();
        
        update_view_details();
    }
    
    private void update_view_details() {
        current_label = current_span.start_date.to_pretty_string(
            Calendar.Date.PrettyFlag.ABBREV
            | Calendar.Date.PrettyFlag.INCLUDE_YEAR
            | Calendar.Date.PrettyFlag.NO_TODAY
        );
        is_viewing_today = current_span.start_date.equal_to(Calendar.System.today);
    }
    
    private void on_calendar_added(Backing.CalendarSource calendar) {
        calendar.notify[Backing.Source.PROP_VISIBLE].connect(on_calendar_visibility_changed);
    }
    
    private void on_calendar_removed(Backing.CalendarSource calendar) {
        calendar.notify[Backing.Source.PROP_VISIBLE].disconnect(on_calendar_visibility_changed);
    }
    
    private void on_calendar_visibility_changed(Object o, ParamSpec pspec) {
        Backing.CalendarSource calendar = (Backing.CalendarSource) o;
        
        traverse_date_rows()
            .iterate(date_row => date_row.notify_calendar_visibility_changed(calendar));
    }
    
    private void on_instance_added_or_altered(Component.Instance instance) {
        Component.Event? event = instance as Component.Event;
        if (event == null)
            return;
        
        foreach (Calendar.Date date in event.get_event_date_span(Calendar.Timezone.local)) {
            // Add dates on-demand; not all dates are listed in Agenda view
            if (!listbox_model.contains(date))
                listbox_model.add(date);
            
            DateRow date_row = (DateRow) listbox_model.get_widget_for_item(date);
            date_row.add_event(event);
            
            // possible to be notified of Event outside of current_span; see reduce_subscriptions()
            date_row.visible = date in current_span;
        }
    }
    
    private void on_instance_removed(Component.Instance instance) {
        Component.Event? event = instance as Component.Event;
        if (event == null)
            return;
        
        foreach (Calendar.Date date in event.get_event_date_span(Calendar.Timezone.local)) {
            if (!listbox_model.contains(date))
                continue;
            
            DateRow date_row = (DateRow) listbox_model.get_widget_for_item(date);
            date_row.remove_event(event);
        }
    }
    
    public override string to_string() {
        return classname;
    }
}

}

