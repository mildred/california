/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Host {

/**
 * Primary application window.
 */

public class MainWindow : Gtk.ApplicationWindow {
    private View.Controllable current_view;
    private View.Month.Controllable month_view = new View.Month.Controllable();
    
    public MainWindow(Application app) {
        Object (application: app);
        
        title = Application.TITLE;
        set_size_request(800, 600);
        set_default_size(1024, 768);
        
        // start in Month view
        current_view = month_view;
        
        // create GtkHeaderBar and pack it in
        Gtk.HeaderBar headerbar = new Gtk.HeaderBar();
        
        Gtk.Button today = new Gtk.Button.with_label(_("Today"));
        today.clicked.connect(() => { current_view.today(); });
        
        Gtk.Button prev = new Gtk.Button.from_icon_name("go-previous-symbolic", Gtk.IconSize.MENU);
        prev.clicked.connect(() => { current_view.prev(); });
        
        Gtk.Button next = new Gtk.Button.from_icon_name("go-next-symbolic", Gtk.IconSize.MENU);
        next.clicked.connect(() => { current_view.next(); });
        
        Gtk.Box nav_buttons = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        nav_buttons.get_style_context().add_class(Gtk.STYLE_CLASS_LINKED);
        nav_buttons.get_style_context().add_class(Gtk.STYLE_CLASS_RAISED);
        nav_buttons.pack_start(prev);
        nav_buttons.pack_end(next);
        
        // pack left-side of window
        headerbar.pack_start(today);
        headerbar.pack_start(nav_buttons);
        
        Gtk.Button new_event = new Gtk.Button.from_icon_name("list-add-symbolic", Gtk.IconSize.MENU);
        new_event.tooltip_text = _("Create a new event for today");
        new_event.clicked.connect(on_new_event);
        
        // pack right-side of window
        headerbar.pack_end(new_event);
        
        Gtk.Box layout = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        layout.pack_start(headerbar, false, true, 0);
        layout.pack_end(month_view, true, true, 0);
        
        // current host bindings and signals
        current_view.request_create_event.connect(on_request_create_event);
        current_view.bind_property(View.Controllable.PROP_CURRENT_LABEL, headerbar, "title",
            BindingFlags.SYNC_CREATE);
        current_view.bind_property(View.Controllable.PROP_IS_VIEWING_TODAY, today, "sensitive",
            BindingFlags.SYNC_CREATE | BindingFlags.INVERT_BOOLEAN);
        
        add(layout);
    }
    
    private void on_new_event() {
        // start today and now, 1-hour event default
        DateTime dtstart = new DateTime.now(new TimeZone.local());
        Calendar.DateTimeSpan dtspan = new Calendar.DateTimeSpan(dtstart, dtstart.add_hours(1));
        
        // revert to today's date and use the widget for the popover
        Gtk.Widget widget = current_view.today();
        
        on_request_create_event(dtspan, widget, null);
    }
    
    private void on_request_create_event(Calendar.DateTimeSpan initial, Gtk.Widget relative_to,
        Cairo.RectangleInt? for_location) {
        CreateEvent create_event = new CreateEvent(initial);
        
        Gtk.Popover popover = new Gtk.Popover(relative_to);
        if (for_location != null)
            popover.pointing_to = for_location;
        popover.add(create_event);
        
        // when the new event is ready, that's what needs to be created
        create_event.notify[CreateEvent.PROP_NEW_EVENT].connect(() => {
            popover.destroy();
            
            if (create_event.new_event != null && create_event.calendar_source != null) {
                debug("creating...");
                create_event.calendar_source.create_component_async.begin(create_event.new_event,
                    null, on_create_event_completed);
            }
        });
        
        popover.show_all();
    }
    
    private void on_create_event_completed(Object? source, AsyncResult result) {
        try {
            ((Backing.CalendarSource) source).create_component_async.end(result);
        } catch (Error err) {
            debug("Unable to create event: %s", err.message);
        }
    }
}

}

