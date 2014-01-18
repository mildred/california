/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Component {

/**
 * A single cell within a {@link MonthGrid}.
 */

public class MonthGridCell : Gtk.DrawingArea {
    public int row { get; private set; }
    public int col { get; private set; }
    public Calendar.Date? date { get; set; default = null; }
    
    // TODO: We may need to get these colors from the theme
    private static Gdk.RGBA RGBA_BORDER = { red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0 };
    private static Gdk.RGBA RGBA_DAY_OF_MONTH = { red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0 };
    private static Gdk.RGBA RGBA_CURRENT_DAY = { red: 0.0, green: 0.25, blue: 0.50, alpha: 0.10 };
    
    public MonthGridCell(int row, int col) {
        this.row = row;
        this.col = col;
        
        notify["date"].connect(queue_draw);
        
        draw.connect(on_draw);
    }
    
    private bool on_draw(Cairo.Context ctx) {
        if (date != null && date.equal_to(Calendar.today)) {
            Gdk.cairo_set_source_rgba(ctx, RGBA_CURRENT_DAY);
            ctx.paint();
        }
        
        int width = get_allocated_width();
        int height = get_allocated_height();
        
        // draw border lines (creates grid effect)
        Gdk.cairo_set_source_rgba(ctx, RGBA_BORDER);
        ctx.set_line_width(0.5);
        
        // only draw bottom line if not on the bottom row
        if (row < MonthGrid.ROWS - 1) {
            ctx.move_to(0, height);
            ctx.line_to(width, height);
        }
        
        // only draw right line if not on the right-most column
        if (col < MonthGrid.COLS - 1) {
            ctx.move_to(width, 0);
            ctx.line_to(width, height);
        }
        
        ctx.stroke();
        
        if (date != null) {
            Pango.Layout layout = create_pango_layout(date.day_of_month.informal_number);
            ctx.move_to(2, 2);
            Gdk.cairo_set_source_rgba(ctx, RGBA_DAY_OF_MONTH);
            Pango.cairo_show_layout(ctx, layout);
        }
        
        return true;
    }
}

}

