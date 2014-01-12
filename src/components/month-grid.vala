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
    public Calendar.MonthOfYear month_year { get; set; default = Calendar.MonthOfYear.current(); }
    
    /**
     * If MonthYear is not supplied, the current date is used.
     */
    public MonthGrid(Calendar.MonthOfYear? month_year) {
        column_homogeneous = true;
        column_spacing = 2;
        row_homogeneous = true;
        row_spacing = 2;
        
        if (month_year != null)
            this.month_year = month_year;
        
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
    }
    
    private void update() {
        try {
            update_cells();
        } catch (CalendarError calerr) {
            debug("Unable to update MonthGrid: %s", calerr.message);
        }
    }
    
    private void update_cells() throws CalendarError {
        foreach (Calendar.Date date in month_year) {
            MonthGridCell? cell = get_cell_for(date);
            if (cell != null)
                cell.date = date;
        }
    }
    
    private MonthGridCell? get_cell_for(Calendar.Date date) {
        if (!date.within_month_year(month_year)) {
            debug("Date %s not in grid's month %s", date.to_string(), month_year.to_string());
            
            return null;
        }
        
        // convert one-based to zero-based row/col indexing
        int row = date.week_of_the_month_monday - 1;
        assert(row < NUM_WEEKS);
        
        int col = date.day_of_week.value_monday - 1;
        assert(col < Calendar.DayOfWeek.COUNT);
        
        return (MonthGridCell) get_child_at(col, row);
    }
}

}

