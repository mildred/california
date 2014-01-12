/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Component {

/**
 * Primary application window.
 */

public class MainWindow : Gtk.ApplicationWindow {
    private MonthGrid grid = new MonthGrid(null);
    
    public MainWindow(Application app) {
        Object (application: app);
        
        title = Application.TITLE;
        set_size_request(800, 600);
        
        Gtk.Box layout = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        
        Gtk.ToolButton back = create_button("go-previous-symbolic");
        back.clicked.connect(() => {
            debug("prev");
            grid.month_of_year = grid.month_of_year.adjust(-1);
        });
        
        Gtk.ToolButton fwd = create_button("go-next-symbolic");
        fwd.clicked.connect(() => {
            debug("next");
            grid.month_of_year = grid.month_of_year.adjust(1);
        });
        
        Gtk.Toolbar toolbar = new Gtk.Toolbar();
        toolbar.add(back);
        toolbar.add(fwd);
        
        layout.pack_start(toolbar, false, true, 0);
        layout.pack_end(grid, true, true, 0);
        
        add(layout);
    }
    
    private static Gtk.ToolButton create_button(string icon_name) {
        Gtk.Button button = new Gtk.Button();
        button.image = new Gtk.Image.from_icon_name(icon_name, Gtk.IconSize.BUTTON);
        button.always_show_image = true;
        
        return new Gtk.ToolButton(button, null);
    }
}

}

