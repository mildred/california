/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

/**
 * The application host (or controller).
 *
 * Host's concerns are to present and manipulate {@link View}s and offer common services to them.
 */

namespace California.Host {

private int init_count = 0;

public void init() throws Error {
    if (!Unit.do_init(ref init_count))
        return;
    
    // unit initialization
    View.init();
    Backing.init();
    Calendar.init();
    Toolkit.init();
}

public void terminate() {
    if (!Unit.do_terminate(ref init_count))
        return;
    
    View.terminate();
    Backing.terminate();
    Calendar.terminate();
    Toolkit.terminate();
}

private Toolkit.ComboBoxTextModel<Backing.CalendarSource> build_calendar_source_combo_model(
    Gtk.ComboBoxText combo, bool include_invisible = false, bool include_read_only = false) {
    Toolkit.ComboBoxTextModel<Backing.CalendarSource> model = new Toolkit.ComboBoxTextModel<Backing.CalendarSource>(
        combo, (calendar) => {
        // Use Pango to display a colored circle next to the calendar title
        return "<span color='%s'>&#x25CF;</span> %s".printf(calendar.color, calendar.title);
    });
    
    // returning Pango markup in model presentation
    model.is_markup = true;
    
    // initialize with current list of calendars ... this control does not auto-update as
    // calendars are added/removed/modified
    foreach (Backing.CalendarSource calendar_source in
        Backing.Manager.instance.get_sources_of_type<Backing.CalendarSource>()) {
        if (!include_invisible && !calendar_source.visible)
            continue;
        
        if (!include_read_only && calendar_source.read_only)
            continue;
        
        model.add(calendar_source);
    }
    
    return model;
}

}

