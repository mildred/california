/* Copyright 2014-2015 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.View.Month {

/**
 * A square cell in the {@link Month.Grid} displaying events.
 *
 * @see View.Common.EventsCell
 */

internal class Cell : Common.EventsCell {
    public weak Grid owner { get; private set; }
    public int row { get; private set; }
    public int col { get; private set; }
    
    public Cell(Grid owner, Calendar.Date date, int row, int col) {
        base (owner.owner.palette, date, date.week_of(Calendar.System.first_of_week).to_date_span());
        
        this.owner = owner;
        this.row = row;
        this.col = col;
        
        notify[PROP_DATE].connect(update_top_line);
        
        update_top_line();
    }
    
    protected override Common.EventsCell? get_cell_for_date(Calendar.Date cell_date) {
        return owner.get_cell_for_date(cell_date);
    }
    
    protected override void draw_borders(Cairo.Context ctx) {
        int width = get_allocated_width();
        int height = get_allocated_height();
        
        // draw border lines (creates grid effect)
        Palette.prepare_hairline(ctx, palette.border);
        
        // only draw top line if on the top row
        if (row == 0) {
            ctx.move_to(0, 0);
            ctx.line_to(width, 0);
        }
        
        // only draw bottom line if not on the bottom row
        if (row < owner.rows - 1) {
            ctx.move_to(0, height);
            ctx.line_to(width, height);
        }
        
        // only draw right line if not on the right-most column
        if (col < Grid.COLS - 1) {
            ctx.move_to(width, 0);
            ctx.line_to(width, height);
        }
        
        ctx.stroke();
    }
    
    private void update_top_line() {
        // include abbreviate month name on first of the month
        top_line_text = (date.day_of_month.value == 1)
            ? "%s %s".printf(date.month.abbrev_name, date.day_of_month.informal_number)
            : date.day_of_month.informal_number;
        top_line_rgba = (date in owner.month_of_year)
            ? palette.day_in_range
            : palette.day_outside_range;
    }
}

}
