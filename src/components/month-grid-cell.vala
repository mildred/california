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
    
    public MonthGridCell(int row, int col) {
        this.row = row;
        this.col = col;
        
        notify["date"].connect(queue_draw);
        
        draw.connect(on_draw);
    }
    
    private bool on_draw(Cairo.Context ctx) {
        if (date == null)
            return true;
        
        if (date.is_now()) {
            ctx.set_source_rgb(1.0, 1.0, 0.80);
            ctx.paint();
        }
        
        Pango.Layout layout = create_pango_layout(date.day_of_month.informal_number);
        ctx.move_to(0, 0);
        ctx.set_source_rgb(0.0, 0.0, 0.0);
        Pango.cairo_show_layout(ctx, layout);
        
        return true;
    }
}

}

