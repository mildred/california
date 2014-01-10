/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California {

public class MainWindow : Gtk.ApplicationWindow {
    public MainWindow(Application app) {
        Object (application: app);
        
        title = Application.TITLE;
    }
}

}

