/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.View.Month {

/**
 * A Gtk.Grid widget that displays a month's worth of days as cells.
 *
 * @see Cell
 */

public class Controllable : Gtk.Grid, View.Controllable {
    // days of the week
    public const int COLS = Calendar.DayOfWeek.COUNT;
    // calendar weeks to be displayed at any one time
    public const int ROWS = 6;
    
    public const string PROP_MONTH_OF_YEAR = "month-of-year";
    public const string PROP_FIRST_OF_WEEK = "first-of-week";
    public const string PROP_SHOW_OUTSIDE_MONTH = "show-outside-month";
    
    /**
     * The month and year being displayed.
     *
     * Defaults to the current month and year.
     */
    public Calendar.MonthOfYear month_of_year { get; private set; }
    
    /**
     * The set first day of the week.
     */
    public Calendar.FirstOfWeek first_of_week { get; set; default = Calendar.FirstOfWeek.SUNDAY; }
    
    /**
     * Show days outside the current month.
     */
    public bool show_outside_month { get; set; default = true; }
    
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
    public Calendar.Date default_date { get; protected set; }
    
    private Gee.HashMap<Calendar.Date, Cell> date_to_cell = new Gee.HashMap<Calendar.Date, Cell>();
    private Gee.ArrayList<Backing.CalendarSourceSubscription> subscriptions = new Gee.ArrayList<
        Backing.CalendarSourceSubscription>();
    
    public Controllable() {
        column_homogeneous = true;
        column_spacing = 0;
        row_homogeneous = true;
        row_spacing = 0;
        
        // prep the grid with a fixed number of rows and columns
        for (int row = 0; row < ROWS; row++)
            insert_row(0);
        
        for (int col = 0; col < COLS; col++)
            insert_column(0);
        
        // pre-add grid elements for every cell, which are updated when the MonthYear changes
        for (int row = 0; row < ROWS; row++) {
            for (int col = 0; col < COLS; col++) {
                // mouse events are enabled in Cell's constructor, not here
                Cell cell = new Cell(this, row, col);
                cell.button_press_event.connect(on_cell_clicked);
                
                attach(cell, col, row, 1, 1);
            }
        }
        
        notify[PROP_MONTH_OF_YEAR].connect(on_month_of_year_changed);
        notify[PROP_FIRST_OF_WEEK].connect(update_cells);
        notify[PROP_SHOW_OUTSIDE_MONTH].connect(update_cells);
        
        // update now that signal handlers are in place
        month_of_year = Calendar.today.month_of_year();
    }
    
    /**
     * @inheritDoc
     */
    public void next() {
        month_of_year = month_of_year.adjust(1);
    }
    
    /**
     * @inheritDoc
     */
    public void prev() {
        month_of_year = month_of_year.adjust(-1);
    }
    
    /**
     * @inheritDoc
     */
    public Gtk.Widget today() {
        // since changing the date is expensive in terms of adding/removing subscriptions, only
        // update the property if it's actually different
        Calendar.MonthOfYear now = Calendar.today.month_of_year();
        if (!now.equal_to(month_of_year))
            month_of_year = now;
        
        assert(date_to_cell.has_key(Calendar.today));
        
        return date_to_cell.get(Calendar.today);
    }
    
    private Cell get_cell(int row, int col) {
        assert(row >= 0 && row < ROWS);
        assert(col >= 0 && col < COLS);
        
        return (Cell) get_child_at(col, row);
    }
    
    private void update_week(int row, Calendar.Week week) {
        foreach (Calendar.Date date in week) {
            int col = date.day_of_week.ordinal(first_of_week) - 1;
            
            Cell cell = get_cell(row, col);
            
            // if the date is in the month or configured to show days outside the month, set
            // the cell to show that date; otherwise, it'll be cleared
            cell.clear();
            cell.date = (date in month_of_year) || show_outside_month ? date : null;
            
            // add to map for quick lookups
            date_to_cell.set(date, cell);
        }
    }
    
    private void update_cells() {
        // clear mapping
        date_to_cell.clear();
        
        // create a WeekSpan for the first week of the month to the last displayed week (not all
        // months will fill all displayed weeks, but some will)
        Calendar.WeekSpan span = new Calendar.WeekSpan.count(month_of_year.weeks(first_of_week).start(),
            ROWS - 1);
        
        // fill in weeks of the displayed month
        int row = 0;
        foreach (Calendar.Week week in span)
            update_week(row++, week);
    }
    
    private void on_month_of_year_changed() {
        current_label = month_of_year.full_name;
        is_viewing_today = month_of_year.equal_to(Calendar.today.month_of_year());
        
        // default date is first of month unless displaying current month, in which case it's
        // current date
        try {
            default_date = is_viewing_today ? Calendar.today
                : month_of_year.date_for(month_of_year.first_day_of_month());
        } catch (CalendarError calerr) {
            // this should always work
            error("Unable to set default date for %s: %s", month_of_year.to_string(), calerr.message);
        }
        
        update_cells();
        
        // generate new ExactTimeSpan window for all calendar subscriptions
        Calendar.ExactTimeSpan window = new Calendar.ExactTimeSpan.from_date_span(month_of_year,
            new TimeZone.local());
        
        // clear current subscriptions and generate new subscriptions for new window
        subscriptions.clear();
        foreach (Backing.Store store in Backing.Manager.instance.get_stores()) {
            foreach (Backing.Source source in store.get_sources_of_type<Backing.CalendarSource>()) {
                Backing.CalendarSource calendar = (Backing.CalendarSource) source;
                calendar.subscribe_async.begin(window, null, on_subscribed);
            }
        }
    }
    
    private void on_subscribed(Object? source, AsyncResult result) {
        Backing.CalendarSource calendar = (Backing.CalendarSource) source;
        
        try {
            Backing.CalendarSourceSubscription subscription = calendar.subscribe_async.end(result);
            subscriptions.add(subscription);
            
            subscription.event_discovered.connect(on_event_added);
            subscription.event_added.connect(on_event_added);
            subscription.event_removed.connect(on_event_removed);
            subscription.event_dropped.connect(on_event_removed);
            
            // this will start signals firing for event changes
            subscription.start();
        } catch (Error err) {
            debug("Unable to subscribe to %s: %s", calendar.to_string(), err.message);
        }
    }
    
    private void on_event_added(Component.Event event) {
        // add event to every date it represents
        foreach (Calendar.Date date in event.get_event_date_span()) {
            Cell? cell = date_to_cell.get(date);
            if (cell != null)
                cell.add_event(event);
        }
    }
    
    private void on_event_removed(Component.Event event) {
        foreach (Calendar.Date date in event.get_event_date_span()) {
            Cell? cell = date_to_cell.get(date);
            if (cell != null)
                cell.remove_event(event);
        }
    }
    
    private bool on_cell_clicked(Gtk.Widget widget, Gdk.EventButton event) {
        // only interested in left-clicks
        if (event.button != 1)
            return false;
        
        switch (event.type) {
            case Gdk.EventType.BUTTON_PRESS:
                return on_cell_single_clicked((Cell) widget, event);
            
            case Gdk.EventType.2BUTTON_PRESS:
                return on_cell_double_clicked((Cell) widget, event);
            
            default:
                return false;
        }
    }
    
    private bool on_cell_single_clicked(Cell cell, Gdk.EventButton button_event) {
        Gdk.Point location = Gdk.Point() { x = (int) button_event.x, y = (int) button_event.y };
        
        Component.Event? event = cell.get_event_at(location);
        if (event != null)
            request_display_event(event, cell, location);
        
        // stop propagation if event found
        return (event != null);
    }
    
    private bool on_cell_double_clicked(Cell cell, Gdk.EventButton button_event) {
        Gdk.Point location = Gdk.Point() { x = (int) button_event.x, y = (int) button_event.y };
        
        // if an existing event is double-clicked, ignore, as the single click handler is displaying
        // it (but stop propagation)
        if (cell.get_event_at(location) != null)
            return true;
        
        // if no date, still avoid propagating event
        if (cell.date == null)
            return true;
        
        // TODO: Define default time better
        Calendar.ExactTime start;
        if(cell.date.equal_to(Calendar.today))
            start = new Calendar.ExactTime.now(new TimeZone.local());
        else
            start = new Calendar.ExactTime(new TimeZone.local(), cell.date, new Calendar.WallTime(13, 0, 0));
        
        Calendar.ExactTime end = start.adjust_time(1, Calendar.TimeUnit.HOUR);
        
        request_create_event(new Calendar.ExactTimeSpan(start, end), cell, location);
        
        // stop propagation
        return true;
    }
}

}

