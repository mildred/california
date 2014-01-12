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
    public const int NUM_WEEKS = 5;
    
    /**
     * The month and year being displayed.
     *
     * Defaults to the current month and year.
     */
    public Calendar.MonthOfYear month_of_year { get; set; default = Calendar.MonthOfYear.current(); }
    
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
        column_spacing = 2;
        row_homogeneous = true;
        row_spacing = 2;
        
        if (month_of_year != null)
            this.month_of_year = month_of_year;
        
        // prep the grid with a fixed number of rows and columns
        for (int week = 0; week < NUM_WEEKS; week++)
            insert_row(0);
        
        for (int dofw = 0; dofw < Calendar.DayOfWeek.COUNT; dofw++)
            insert_column(0);
        
        // pre-add grid elements for every cell, which are updated when the MonthYear changes
        for (int row = 0; row < NUM_WEEKS; row++) {
            for (int col = 0; col < Calendar.DayOfWeek.COUNT; col++)
                attach(new MonthGridCell(col, row), col, row, 1, 1);
        }
        
        update();
        
        notify["month-year"].connect(update);
        notify["first-of-week"].connect(update);
        notify["show-outside-month"].connect(update);
    }
    
    private void update() {
        foreach (Calendar.Week week in month_of_year.weeks(first_of_week)) {
            // convert one-based to zero-based row/col indexing
            int row = week.week_of_month - 1;
            assert(row < NUM_WEEKS);
            
            foreach (Calendar.Date date in week) {
                int col = date.day_of_week.ordinal(first_of_week) - 1;
                assert(col < Calendar.DayOfWeek.COUNT);
                
                MonthGridCell cell = (MonthGridCell) get_child_at(col, row);
                if (date in month_of_year)
                    cell.date = date;
                else
                    cell.date = show_outside_month ? date : null;
            }
        }
    }
}

}

