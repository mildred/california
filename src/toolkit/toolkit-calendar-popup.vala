/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Toolkit {

/**
 * A simple {@link Popup} window featuring only a GtkCalendar.
 *
 * The {@link date_selected} signal is fired when the user clicks on a day of the month.  The
 * GtkCalendar can be configured with the {@link calendar} property.
 *
 * In current implementation, merely selecting a day (single- or double-click) will fire the
 * date_selected signal and {@link dismiss} the Popup.
 */

public class CalendarPopup : Popup {
    /**
     * The child Gtk.Calendar.
     */
    public Gtk.Calendar calendar { get; private set; default = new Gtk.Calendar(); }
    
    /**
     * Fired when the user selects a day of a month and year.
     *
     * In current implementation the {@link Popup} will be {@link dismissed} with any selection.
     * Future work may allow the user to single-click on a day but require another action to
     * dismiss the Popup.  Best for users to subscribe to {@link dismissed} as well as this signal.
     */
    public signal void date_selected(Calendar.Date date);
    
    /**
     * inheritDoc
     */
    public CalendarPopup(Gtk.Widget relative_to, Calendar.Date initial_date) {
        base (relative_to, Popup.Position.BELOW);
        
        calendar.day = initial_date.day_of_month.value;
        calendar.month = initial_date.month.value - 1;
        calendar.year = initial_date.year.value;
        
        calendar.day_selected.connect(on_day_selected);
        calendar.day_selected_double_click.connect(() => {
            on_day_selected();
            dismiss();
        });
        
        add(calendar);
    }
    
    private void on_day_selected() {
        Calendar.Date date;
        try {
            date = new Calendar.Date(
                Calendar.DayOfMonth.for(calendar.day),
                Calendar.Month.for(calendar.month + 1),
                new Calendar.Year(calendar.year)
            );
        } catch (CalendarError calerr) {
            debug("Unable to generate date from Gtk.Calendar: %s", calerr.message);
            
            return;
        }
        
        date_selected(date);
    }
}

}

