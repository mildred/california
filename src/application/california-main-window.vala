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
        
        Gtk.Box layout = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        
        Gtk.ToolButton today = new Gtk.ToolButton(null, _("Today"));
        today.is_important = true;
        today.clicked.connect(() => { current_host.today(); });
        
        Gtk.ToolButton prev = create_button("go-previous-symbolic");
        prev.clicked.connect(() => { current_host.prev(); });
        
        Gtk.ToolButton next = create_button("go-next-symbolic");
        next.clicked.connect(() => { current_host.next(); });
        
        Gtk.Label date_label = new Gtk.Label(current_host.current_label);
        Gtk.ToolItem date_item = new Gtk.ToolItem();
        date_item.add(date_label);
        
        Gtk.Toolbar toolbar = new Gtk.Toolbar();
        toolbar.add(today);
        toolbar.add(prev);
        toolbar.add(next);
        toolbar.add(date_item);
        
        layout.pack_start(toolbar, false, true, 0);
        layout.pack_end(month_host, true, true, 0);
        
        add(layout);
        
        // update label widget when current date changes
        current_host.notify[View.HostInterface.PROP_CURRENT_LABEL].connect(() => {
            date_label.label = current_host.current_label;
        });
    }
    
    private static Gtk.ToolButton create_button(string icon_name) {
        return new Gtk.ToolButton(new Gtk.Image.from_icon_name(icon_name, Gtk.IconSize.BUTTON), null);
    }
}

}

