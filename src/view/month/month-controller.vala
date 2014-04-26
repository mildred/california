/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.View.Month {

/**
 * The {@link View.Controllable} for a Month View of the user's calendars.
 *
 * The Controller holds a GtkStack of {@link Grid}s which it "flips" back and forth through as
 * the user navigates the calendar.
 */

public class Controller : BaseObject, View.Controllable {
    public const string PROP_MONTH_OF_YEAR = "month-of-year";
    public const string PROP_SHOW_OUTSIDE_MONTH = "show-outside-month";
    
    // Slower than default to make more apparent to user what's occurring
    private const int TRANSITION_DURATION_MSEC = 500;
    
    // number of Grids to keep in GtkStack and cache (in terms of months) ... this should be an
    // even number, as it is halved to determine neighboring months depths
    private const int CACHE_NEIGHBORS_COUNT = 4;
    
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
    
    private Gtk.Grid master_grid = new Gtk.Grid();
    private Gtk.Stack stack = new Gtk.Stack();
    private Gee.HashMap<Calendar.MonthOfYear, Grid> month_grids = new Gee.HashMap<Calendar.MonthOfYear, Grid>();
    
    public Controller() {
        master_grid.column_homogeneous = true;
        master_grid.column_spacing = 0;
        master_grid.row_homogeneous = false;
        master_grid.row_spacing = 0;
        master_grid.expand = true;
        
        stack.transition_duration = TRANSITION_DURATION_MSEC;
        
        // insert labels for days of the week across top of master grid
        for (int col = 0; col < Grid.COLS; col++) {
            Gtk.Label dow_label = new Gtk.Label(null);
            dow_label.margin_top = 2;
            dow_label.margin_bottom = 2;
            
            // update label if first-of-week changes
            int dow_col = col + Calendar.DayOfWeek.MIN;
            notify[PROP_FIRST_OF_WEEK].connect(() => {
                Calendar.DayOfWeek dow = Calendar.DayOfWeek.for_checked(dow_col, first_of_week);
                dow_label.label = dow.abbrev_name;
            });
            
            master_grid.attach(dow_label, col, 0, 1, 1);
        }
        
        // the stack is what flips between the month grids (it's inserted empty here, changes to
        // first_of_week are what fill the stack with Grids and select which to display)
        master_grid.attach(stack, 0, 1, Grid.COLS, 1);
        
        notify[PROP_MONTH_OF_YEAR].connect(on_month_of_year_changed);
        Calendar.System.instance.today_changed.connect(on_today_changed);
        
        // update now that signal handlers are in place ... do first_of_week first since more heavy
        // processing is done when month_of_year changes
        first_of_week = Calendar.FirstOfWeek.SUNDAY;
        month_of_year = Calendar.System.today.month_of_year();
    }
    
    ~Controller() {
        Calendar.System.instance.today_changed.disconnect(on_today_changed);
    }
    
    // Creates a new Grid for the MonthOfYear, storing locally and adding to the GtkStack.  Will
    // reuse existing Grids whenever possible.
    private void ensure_month_grid_exists(Calendar.MonthOfYear month_of_year) {
        if (month_grids.has_key(month_of_year))
            return;
        
        Grid month_grid = new Grid(this, month_of_year);
        month_grid.show_all();
        
        // add to local store and to the GtkStack itself
        month_grids.set(month_of_year, month_grid);
        stack.add_named(month_grid, month_grid.id);
    }
    
    // Performs Grid caching by ensuring that Grids are available for the current, next, and
    // previous month and that Grids outside that range are dropped.  The current chronological
    // month is never discarded.
    private void update_month_grid_cache() {
        Calendar.MonthSpan cache_span = new Calendar.MonthSpan.from_months(
            month_of_year.adjust(0 - (CACHE_NEIGHBORS_COUNT / 2)),
            month_of_year.adjust(CACHE_NEIGHBORS_COUNT / 2));
        
        // trim cache
        Gee.MapIterator<Calendar.MonthOfYear, Grid> iter = month_grids.map_iterator();
        while (iter.next()) {
            Calendar.MonthOfYear grid_moy = iter.get_key();
            
            // always keep current month
            if (grid_moy.equal_to(Calendar.System.today.month_of_year()))
                continue;
            
            // keep if grid is in cache span
            if (cache_span.has(grid_moy))
                continue;
            
            // drop, remove from GtkStack and local storage
            stack.remove(iter.get_value());
            iter.unset();
        }
        
        // ensure all-months in span are available
        foreach (Calendar.MonthOfYear moy in cache_span)
            ensure_month_grid_exists(moy);
    }
    
    private unowned Grid? get_current_month_grid() {
        return (Grid?) stack.get_visible_child();
    }
    
    /**
     * @inheritDoc
     */
    public void next() {
        month_of_year = month_of_year.next();
    }
    
    /**
     * @inheritDoc
     */
    public void prev() {
        month_of_year = month_of_year.previous();
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
        
        // current should be set by the month_of_year being set
        Grid? current_grid = get_current_month_grid();
        assert(current_grid != null);
        
        // this grid better have a cell with this date in it
        Cell? cell = current_grid.get_cell_for_date(Calendar.System.today);
        assert(cell != null);
        
        return cell;
    }
    
    /**
     * @inheritDoc
     */
    public void unselect_all() {
        Grid? current_grid = get_current_month_grid();
        if (current_grid != null)
            current_grid.unselect_all();
    }
    
    /**
     * @inheritDoc
     */
    public Gtk.Widget get_container() {
        return master_grid;
    }
    
    private void update_is_viewing_today() {
        is_viewing_today = month_of_year.equal_to(Calendar.System.today.month_of_year());
    }
    
    private void on_today_changed() {
        // don't update view but indicate if it's still in view
        update_is_viewing_today();
    }
    
    private void on_month_of_year_changed() {
        current_label = month_of_year.full_name;
        update_is_viewing_today();
        
        // default date is first of month unless displaying current month, in which case it's
        // current date
        try {
            default_date = is_viewing_today ? Calendar.System.today
                : month_of_year.date_for(month_of_year.first_day_of_month());
        } catch (CalendarError calerr) {
            // this should always work
            error("Unable to set default date for %s: %s", month_of_year.to_string(), calerr.message);
        }
        
        // set up transition to give appearance of moving chronologically through the pages of
        // a calendar
        Grid? current_grid = get_current_month_grid();
        if (current_grid != null) {
            Calendar.MonthOfYear current_moy = current_grid.month_of_year;
            int compare = month_of_year.compare_to(current_moy);
            if (compare < 0)
                stack.transition_type = Gtk.StackTransitionType.SLIDE_RIGHT;
            else if (compare > 0)
                stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT;
            else
                return;
        }
        
        // because grid cache is populated/trimmed after sliding month into view, ensure the
        // desired month already exists
        ensure_month_grid_exists(month_of_year);
        
        // make visible using proper transition type
        stack.set_visible_child(month_grids.get(month_of_year));
        
        // now update the cache to store current month and neighbors ... do this after doing above
        // comparison because this update affects the GtkStack, which may revert to another page
        // when the cache is trimmed, making the notion of "current" indeterminate; the most
        // visible symptom of this is navigating far from today's month then clicking the Today
        // button and no transition occurs because, when the cache is trimmed, today's month is
        // the current child ... to avoid dropping the Widget before the transition completes,
        // wait before doing this; 3.12's "transition-running" property would be useful here
        Idle.add(() => {
            update_month_grid_cache();
            
            return false;
        }, Priority.LOW);
    }
    
    public override string to_string() {
        return "Month.Controller for %s".printf(month_of_year.to_string());
    }
}

}

