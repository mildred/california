/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Activator {

/**
 * A modal window for selecting and managing {@link Activator.Instance} workflows.
 */

public class Window : Host.ModalWindow {
    private static Activator.Window? instance = null;
    
    private Window(Gtk.Window? parent) {
        base (parent);
        
        InstanceList list = new InstanceList();
        
        // when an Activator instance is selected from the list, swap out the list for the
        // Activator's own interaction
        list.selected.connect(activator => {
            content_area.remove(list);
            content_area.add(activator.create_interaction(null));
        });
        
        content_area.add(list);
    }
    
    public static void display(Gtk.Window? parent) {
        // only allow one instance at a time
        if (instance != null) {
            instance.present_with_time(Gdk.CURRENT_TIME);
            
            return;
        }
        
        instance = new Activator.Window(parent);
        instance.show_all();
        instance.run();
        instance.destroy();
        
        instance = null;
    }
}

}

