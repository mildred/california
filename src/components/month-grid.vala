/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Component {

/**
 * A Gtk.Grid widget that displays a month's worth of days as cells.
 *
 * @see MonthGridCell
 */

public class MonthGrid : Gtk.Grid {
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
    public bool show_outside_month { get; set; default = false; }
    
    /**
     * If MonthYear is not supplied, the current date is used.
     */
    public MonthGrid(Calendar.MonthOfYear? month_of_year) {
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
                attach(new MonthGridCell(row, col), col, row, 1, 1);
        }
        
        update();
        
        notify[PROP_MONTH_OF_YEAR].connect(update);
        notify[PROP_FIRST_OF_WEEK].connect(update);
        notify[PROP_SHOW_OUTSIDE_MONTH].connect(update);
    }
    
    private MonthGridCell get_cell(int row, int col) {
        assert(row >= 0 && row < ROWS);
        assert(col >= 0 && col < COLS);
        
        return (MonthGridCell) get_child_at(col, row);
    }
    
    private void clear() {
        for (int row = 0; row < ROWS; row++) {
            for (int col = 0; col < COLS; col++)
                get_cell(row, col).date = null;
        }
    }
    
    private void update() {
        clear();
        
        foreach (Calendar.Week week in month_of_year.weeks(first_of_week)) {
            debug("%s %d", week.to_string(), week.week_of_month);
            
            // convert one-based to zero-based row/col indexing
            int row = week.week_of_month - 1;
            
            foreach (Calendar.Date date in week) {
                int col = date.day_of_week.ordinal(first_of_week) - 1;
                
                // if the date is in the month or configured to show days outside the month, set
                // the cell to show that date; otherwise, it'll be cleared
                get_cell(row, col).date = (date in month_of_year) || show_outside_month ? date : null;
            }
        }
    }
}

}

