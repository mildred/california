/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Component {

/**
 * A single cell within a {@link MonthGrid}.
 */

public class MonthGridCell : Gtk.Box {
    public int row { get; private set; }
    public int col { get; private set; }
    public Calendar.Date? date { get; set; default = null; }
    
    private Gtk.Label day_of_month;
    private Gtk.Label label;
    
    public MonthGridCell(int row, int col) {
        Object(orientation: Gtk.Orientation.VERTICAL);
        
        this.row = row;
        this.col = col;
        day_of_month = new Gtk.Label(null);
        label = new Gtk.Label("%d,%d".printf(row, col));
        
        homogeneous = true;
        spacing = 1;
        
        pack_start(day_of_month, true, true, 0);
        pack_start(label, true, true, 0);
        
        notify["date"].connect(on_date_changed);
    }
    
    private void on_date_changed() {
        day_of_month.set_text(date != null ? date.day_of_month.informal_number : "");
    }
}

}

