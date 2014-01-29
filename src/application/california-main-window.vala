/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California {

/**
 * Primary application window.
 */

public class MainWindow : Gtk.ApplicationWindow {
    private View.HostInterface current_host;
    private View.Month.Host month_host = new View.Month.Host();
    
    public MainWindow(Application app) {
        Object (application: app);
        
        title = Application.TITLE;
        set_size_request(800, 600);
        set_default_size(1024, 768);
        
        // start in Month view
        current_host = month_host;
        
        // create GtkHeaderBar and pack it in
        Gtk.HeaderBar headerbar = new Gtk.HeaderBar();
        headerbar.title = Application.TITLE;
        headerbar.subtitle = Application.DESCRIPTION;
        
        Gtk.Button today = new Gtk.Button.with_label(_("Today"));
        today.clicked.connect(() => { current_host.today(); });
        
        Gtk.Button prev = new Gtk.Button.from_icon_name("go-previous-symbolic", Gtk.IconSize.MENU);
        prev.clicked.connect(() => { current_host.prev(); });
        
        Gtk.Button next = new Gtk.Button.from_icon_name("go-next-symbolic", Gtk.IconSize.MENU);
        next.clicked.connect(() => { current_host.next(); });
        
        Gtk.Label date_label = new Gtk.Label(null);
        current_host.bind_property(View.HostInterface.PROP_CURRENT_LABEL, date_label, "label",
            BindingFlags.SYNC_CREATE);
        
        // pack left-side of window
        headerbar.pack_start(today);
        headerbar.pack_start(prev);
        headerbar.pack_start(next);
        headerbar.pack_start(date_label);
        
        Gtk.Button new_event = new Gtk.Button.from_icon_name("list-add-symbolic", Gtk.IconSize.MENU);
        new_event.tooltip_text = _("Create a new event");
        
        // pack right-side of window
        headerbar.pack_end(new_event);
        
        Gtk.Box layout = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        layout.pack_start(headerbar, false, true, 0);
        layout.pack_end(month_host, true, true, 0);
        
        add(layout);
    }
    
    /**
     * Should be called at application startup before instantiating {@link MainWindow}.
     */
    public static void init() throws Error {
        View.init();
    }
    
    /**
     * Should be called at application shutdown after destroying {@link MainWindow}.
     */
    public static void terminate() {
        View.terminate();
    }
}

}

