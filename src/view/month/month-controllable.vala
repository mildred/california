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
    
    // day of week labels are stored in the -1 row
    private const int DOW_ROW = -1;
    
    public const string PROP_MONTH_OF_YEAR = "month-of-year";
    public const string PROP_SHOW_OUTSIDE_MONTH = "show-outside-month";
    
    // Delegate for walking only Cells in the Grid.  Return true to keep iterating.
    private delegate bool CellCallback(Cell cell);
    
    /**
     * The month and year being displayed.
     *
     * Defaults to the current month and year.
     */
    public Calendar.MonthOfYear month_of_year { get; private set; }
    
    /**
     * @inheritDoc
     */
    public Calendar.FirstOfWeek first_of_week { get; set; }
    
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
    private Gdk.EventType button_press_type = Gdk.EventType.NOTHING;
    private Gdk.Point button_press_point = Gdk.Point();
    
    public Controllable() {
        column_homogeneous = true;
        column_spacing = 0;
        row_homogeneous = false;
        row_spacing = 0;
        
        // prep the grid with a fixed number of rows and columns
        for (int row = 0; row < ROWS; row++)
            insert_row(0);
        
        for (int col = 0; col < COLS; col++)
            insert_column(0);
        
        // pre-add grid elements for days of the week along the top row (using -1 as the row so the
        // remainder of grid is "naturally" zero-based rows)
        for (int col = 0; col < COLS; col++) {
            Gtk.Label dow_cell = new Gtk.Label(null);
            dow_cell.margin_top = 2;
            dow_cell.margin_bottom = 2;
            
            attach(dow_cell, col, DOW_ROW, 1, 1);
        }
        
        // pre-add grid elements for every cell, which are updated when the MonthYear changes
        for (int row = 0; row < ROWS; row++) {
            for (int col = 0; col < COLS; col++) {
                // mouse events are enabled in Cell's constructor, not here
                Cell cell = new Cell(this, row, col);
                cell.expand = true;
                cell.events |= Gdk.EventMask.BUTTON_PRESS_MASK & Gdk.EventMask.BUTTON1_MOTION_MASK;
                cell.button_press_event.connect(on_cell_button_event);
                cell.button_release_event.connect(on_cell_button_event);
                cell.motion_notify_event.connect(on_cell_motion_event);
                
                attach(cell, col, row, 1, 1);
            }
        }
        
        notify[PROP_MONTH_OF_YEAR].connect(on_month_of_year_changed);
        notify[PROP_FIRST_OF_WEEK].connect(update_first_of_week);
        notify[PROP_SHOW_OUTSIDE_MONTH].connect(update_cells);
        
        // update now that signal handlers are in place
        month_of_year = Calendar.System.today.month_of_year();
        first_of_week = Calendar.FirstOfWeek.SUNDAY;
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
        Calendar.MonthOfYear now = Calendar.System.today.month_of_year();
        if (!now.equal_to(month_of_year))
            month_of_year = now;
        
        assert(date_to_cell.has_key(Calendar.System.today));
        
        return date_to_cell.get(Calendar.System.today);
    }
    
    /**
     * @inheritDoc
     */
    public void unselect_all() {
        foreach_cell((cell) => {
            cell.selected = false;
            
            return true;
        });
    }
    
    private Cell get_cell(int row, int col) {
        assert(row >= 0 && row < ROWS);
        assert(col >= 0 && col < COLS);
        
        return (Cell) get_child_at(col, row);
    }
    
    private void foreach_cell(CellCallback callback) {
        foreach (unowned Gtk.Widget widget in get_children()) {
            // watch for Gtk.Labels across the top
            unowned Cell? cell = widget as Cell;
            if (cell != null && !callback(cell))
                return;
        }
    }
    
    // Must be in coordinates of the Gtk.Grid, not a Cell
    private Cell? translate_to_cell(int grid_x, int grid_y) {
        // TODO: A proper hit-detection algorithm would be better here
        Cell? hit = null;
        foreach_cell((cell) => {
            int cell_x, cell_y;
            if (!translate_coordinates(cell, grid_x, grid_y, out cell_x, out cell_y))
                return true;
            
            if (cell.is_hit(cell_x, cell_y))
                hit = cell;
            
            return hit == null;
        });
        
        return hit;
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
    
    private void update_first_of_week() {
        // set label text in day of week row
        int col = 0;
        foreach (Calendar.DayOfWeek dow in Calendar.DayOfWeek.iterator(first_of_week)) {
            Gtk.Label dow_cell = (Gtk.Label) get_child_at(col++, DOW_ROW);
            dow_cell.label = dow.abbrev_name;
        }
        
        // requires updating all the cells as well, since all dates have to be shifted
        update_cells();
    }
    
    private void on_month_of_year_changed() {
        current_label = month_of_year.full_name;
        is_viewing_today = month_of_year.equal_to(Calendar.System.today.month_of_year());
        
        // default date is first of month unless displaying current month, in which case it's
        // current date
        try {
            default_date = is_viewing_today ? Calendar.System.today
                : month_of_year.date_for(month_of_year.first_day_of_month());
        } catch (CalendarError calerr) {
            // this should always work
            error("Unable to set default date for %s: %s", month_of_year.to_string(), calerr.message);
        }
        
        update_cells();
        
        // generate new ExactTimeSpan window for all calendar subscriptions
        Calendar.ExactTimeSpan window = new Calendar.ExactTimeSpan.from_date_span(month_of_year,
            Calendar.Timezone.local);
        
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
    
    private bool on_cell_button_event(Gtk.Widget widget, Gdk.EventButton event) {
        // only interested in left-clicks
        if (event.button != 1)
            return false;
        
        // NOTE: widget is the *pressed* widget, even for "release" events, no matter where the release
        // occurs ... this signal handler is fired from Cells, never the GtkLabels across the top
        // of the grid
        Cell press_cell = (Cell) widget;
        
        switch (event.type) {
            case Gdk.EventType.BUTTON_PRESS:
            case Gdk.EventType.2BUTTON_PRESS:
            case Gdk.EventType.3BUTTON_PRESS:
                button_press_type = event.type;
                button_press_point.x = (int) event.x;
                button_press_point.y = (int) event.y;
            break;
            
            case Gdk.EventType.BUTTON_RELEASE:
                // The GDK coordinates are relative to the pressed Cell, so translate to the GtkGrid
                int grid_x, grid_y;
                if (!press_cell.translate_coordinates(this, (int) event.x, (int) event.y, out grid_x,
                    out grid_y)) {
                    return false;
                }
                
                // Now translate the released coordinates back to the right Cell, if it is a Cell
                Cell? release_cell = translate_to_cell(grid_x, grid_y);
                
                // if released on a non-Cell, reset state and exit
                if (release_cell == null) {
                    unselect_all();
                    button_press_type = Gdk.EventType.NOTHING;
                    button_press_point = {};
                    
                    return false;
                }
                
                // translate release point coordinates into the coordinates of the released cell
                Gdk.Point button_release_point = Gdk.Point();
                if (!press_cell.translate_coordinates(release_cell, (int) event.x, (int) event.y,
                    out button_release_point.x, out button_release_point.y)) {
                    return false;
                }
                
                bool stop_propagation = false;
                switch (button_press_type) {
                    case Gdk.EventType.BUTTON_PRESS:
                        stop_propagation = on_cell_single_click((Cell) widget, button_press_point,
                            release_cell, button_release_point);
                    break;
                    
                    case Gdk.EventType.2BUTTON_PRESS:
                        stop_propagation = on_cell_double_click((Cell) widget, button_press_point,
                            release_cell, button_release_point);
                    break;
                }
                
                // reset, but don't de-select the view controller might be in charge of that
                button_press_type = Gdk.EventType.NOTHING;
                button_press_point = {};
                
                return stop_propagation;
        }
        
        return false;
    }
    
    private bool on_cell_single_click(Cell press_cell, Gdk.Point press_point,
        Cell release_cell, Gdk.Point release_point) {
        bool stop_propagation = false;
        
        // if pressed and released on the same cell, display the event at the released location
        if (press_cell == release_cell) {
            Component.Event? event = release_cell.get_event_at(release_point);
            if (event != null) {
                request_display_event(event, release_cell, release_point);
                stop_propagation = true;
            }
        } else if (press_cell.date != null && release_cell.date != null) {
            // create multi-day event
            request_create_all_day_event(new Calendar.DateSpan(press_cell.date, release_cell.date),
                release_cell, release_point);
            stop_propagation = true;
        } else {
            // make sure to clear selections if no action is taken
            unselect_all();
        }
        
        return stop_propagation;
    }
    
    private bool on_cell_double_click(Cell press_cell, Gdk.Point press_point, Cell release_cell,
        Gdk.Point release_point) {
        // only interested in double-clicking on the same cell
        if (press_cell != release_cell)
            return false;
        
        // if an existing event is double-clicked, ignore, as the single click handler is displaying
        // it (but stop propagation)
        if (release_cell.get_event_at(release_point) != null)
            return true;
        
        // if no date, still avoid propagating event
        if (release_cell.date == null)
            return true;
        
        // TODO: Define default time better
        Calendar.ExactTime start;
        if(release_cell.date.equal_to(Calendar.System.today)) {
            start = new Calendar.ExactTime.now(Calendar.Timezone.local);
        } else {
            start = new Calendar.ExactTime(Calendar.Timezone.local, release_cell.date,
                new Calendar.WallTime(13, 0, 0));
        }
        
        Calendar.ExactTime end = start.adjust_time(1, Calendar.TimeUnit.HOUR);
        
        request_create_timed_event(new Calendar.ExactTimeSpan(start, end), release_cell, release_point);
        
        // stop propagation
        return true;
    }
    
    private bool on_cell_motion_event(Gtk.Widget widget, Gdk.EventMotion event) {
        // Because using button 1 motion mask, widget is always the original cell the button-pressed
        // event originated at
        Cell press_cell = (Cell) widget;
        
        // turn Cell coordinates into GtkGrid coordinates
        int grid_x, grid_y;
        if (!press_cell.translate_coordinates(this, (int) event.x, (int) event.y, out grid_x, out grid_y))
            return false;
        
        // get the cell the pointer is currently over ... if not found or the same as the original,
        // do nothing
        Cell? hover_cell = translate_to_cell(grid_x, grid_y);
        if (hover_cell == null || hover_cell == press_cell)
            return false;
        
        // both must have dates as well
        if (press_cell.date == null || hover_cell.date == null)
            return false;
        
        // mark two cells and all in-between as selected, being sure to mark any previous selected
        // as unselected
        Calendar.DateSpan span = new Calendar.DateSpan(press_cell.date, hover_cell.date);
        foreach_cell((cell) => {
            cell.selected = (cell.date != null) ? cell.date in span : false;
            
            return true;
        });
        
        return true;
    }
}

}

