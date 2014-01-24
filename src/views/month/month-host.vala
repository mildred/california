/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Views.Month {

/**
 * A Gtk.Grid widget that displays a month's worth of days as cells.
 *
 * @see Cell
 */

public class Host : Gtk.Grid {
    // days of the week
    public const int COLS = Calendar.DayOfWeek.COUNT;
    // weeks of the month
    public const int ROWS = 6;
    
    public const string PROP_MONTH_OF_YEAR = "month-of-year";
    public const string PROP_FIRST_OF_WEEK = "first-of-week";
    public const string PROP_SHOW_OUTSIDE_MONTH = "show-outside-month";
    
    /**
     * The month and year being displayed.
     *
     * Defaults to the current month and year.
     */
    public Calendar.MonthOfYear month_of_year { get; set; default = new Calendar.MonthOfYear.now(); }
    
    /**
     * The set first day of the week.
     */
    public Calendar.FirstOfWeek first_of_week { get; set; default = Calendar.FirstOfWeek.SUNDAY; }
    
    /**
     * Show days outside the current month.
     */
    public bool show_outside_month { get; set; default = true; }
    
    private Gee.HashMap<Calendar.Date, Cell> date_to_cell = new Gee.HashMap<Calendar.Date, Cell>();
    
    /**
     * If MonthYear is not supplied, the current date is used.
     */
    public Host(Calendar.MonthOfYear? month_of_year) {
        column_homogeneous = true;
        column_spacing = 0;
        row_homogeneous = true;
        row_spacing = 0;
        
        if (month_of_year != null)
            this.month_of_year = month_of_year;
        
        // prep the grid with a fixed number of rows and columns
        for (int row = 0; row < ROWS; row++)
            insert_row(0);
        
        for (int col = 0; col < COLS; col++)
            insert_column(0);
        
        // pre-add grid elements for every cell, which are updated when the MonthYear changes
        for (int row = 0; row < ROWS; row++) {
            for (int col = 0; col < COLS; col++)
                attach(new Cell(this, row, col), col, row, 1, 1);
        }
        
        update();
        
        notify[PROP_MONTH_OF_YEAR].connect(update);
        notify[PROP_FIRST_OF_WEEK].connect(update);
        notify[PROP_SHOW_OUTSIDE_MONTH].connect(update);
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
    
    private void update() {
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
    
    public void add_event(Component.Event event) {
        // add event to every date it represents
        foreach (Calendar.Date date in event.get_event_date_span()) {
            Cell? cell = date_to_cell.get(date);
            if (cell != null)
                cell.add_event(event);
        }
    }
    
    public void remove_event(Component.Event event) {
        foreach (Calendar.Date date in event.get_event_date_span()) {
            Cell? cell = date_to_cell.get(date);
            if (cell != null)
                cell.remove_event(event);
        }
    }
}

}
