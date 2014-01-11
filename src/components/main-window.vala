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
        
        add(grid);
    }
}

}

