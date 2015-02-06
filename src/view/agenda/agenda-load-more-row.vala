/* Copyright 2014-2015 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.View.Agenda {

[GtkTemplate (ui = "/org/yorba/california/rc/view-agenda-load-more-row.ui")]
private class LoadMoreRow : Gtk.Box {
    private unowned Controller owner;
    
    [GtkChild]
    private Gtk.Label showing_until_label;
    
    public signal void load_more();
    
    public LoadMoreRow(Controller owner) {
        this.owner = owner;
        
        owner.notify[Controller.PROP_CURRENT_SPAN].connect(update_ui);
        
        update_ui();
    }
    
    ~LoadMoreRow() {
        owner.notify[Controller.PROP_CURRENT_SPAN].disconnect(update_ui);
    }
    
    private void update_ui() {
        string date_str = owner.current_span.end_date.to_pretty_string(
            Calendar.Date.PrettyFlag.INCLUDE_YEAR
            | Calendar.Date.PrettyFlag.NO_DAY_OF_WEEK
            | Calendar.Date.PrettyFlag.NO_TODAY
        );
        
        // %s is a date, i.e. "Showing events until December 5, 2014"
        showing_until_label.label = _("Showing events until %s").printf(date_str);
    }
    
    [GtkCallback]
    private void on_load_more_button_clicked() {
        load_more();
    }
}

}

