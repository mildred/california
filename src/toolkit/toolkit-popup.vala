/* Copyright 2014-2015 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Toolkit {

/**
 * A Popup is a single GtkWindow that grabs the application focus and dismisses itself if it
 * ever loses focus.
 *
 * It can also be dismissed if the user presses the Escape key.
 */

public class Popup : Gtk.Window {
    public enum Position {
        BELOW,
        VERTICAL_CENTER
    }
    
    private Gtk.Widget relative_to;
    private Position position;
    private Gtk.Widget? prev_focus = null;
    private int relative_x = 0;
    private int relative_y = 0;
    
    /**
     * Fired when the {@link Popup} is hidden, either due to user interaction (losing focus) or
     * because {@link dismiss} was invoked.
     */
    public virtual signal void dismissed() {
    }
    
    /**
     * Create a {@link Popup} relative to the supplied widget.
     *
     * The GtkWidget must be realized when this is invoked.
     */
    public Popup(Gtk.Widget relative_to, Position position) {
        Object(type:Gtk.WindowType.TOPLEVEL);
        
        assert(relative_to.get_realized());
        this.relative_to = relative_to;
        this.position = position;
        
        set_screen(relative_to.get_screen());
        
        // get coordinates of relative_to widget
        Gtk.Window? relative_to_win = relative_to.get_ancestor(typeof (Gtk.Window)) as Gtk.Window;
        if (relative_to_win != null && relative_to_win.is_toplevel()) {
            int gtk_x, gtk_y;
            relative_to.translate_coordinates(relative_to_win, 0, 0, out gtk_x, out gtk_y);
            
            Gdk.Window gdk_win = relative_to_win.get_window();
            assert(gdk_win != null);
            int gdk_x, gdk_y;
            gdk_win.get_position(out gdk_x, out gdk_y);
            
            relative_x = gtk_x + gdk_x;
            relative_y = gtk_y + gdk_y;
        }
        
        decorated = false;
        resizable = false;
        
        add_events(Gdk.EventMask.KEY_PRESS_MASK);
        
        // if relative_to widget is ever unmapped, go down with it
        relative_to.unmap.connect(() => {
            unmap();
        });
        
        // if this window ever loses focus, it's considered dismissed
        notify["has-toplevel-focus"].connect(() => {
            if (!has_toplevel_focus)
                hide();
        });
    }
    
    /**
     * Programatically dismiss the {@link Popover}.
     *
     * @see dismissed
     */
    public void dismiss() {
        hide();
    }
    
    public override void map() {
        base.map();
        
        switch (position) {
            case Position.BELOW:
                // move Popup window directly below relative_to widget aligned on the left-hand side
                // TODO: RTL support
                // TODO: Better detection to ensure Popup is always fully mapped onto the same screen
                move(relative_x, relative_y + relative_to.get_allocated_height());
            break;
            
            case Position.VERTICAL_CENTER:
                move(relative_x, relative_y + ((relative_to.get_allocated_height() - get_allocated_height()) / 2));
            break;
            
            default:
                assert_not_reached();
        }
        
        prev_focus = get_focus();
        
        Gtk.grab_add(this);
        grab_focus();
    }
    
    public override void unmap() {
        Gtk.grab_remove(this);
        
        if (prev_focus != null) {
            prev_focus.grab_focus();
            prev_focus = null;
        }
        
        base.unmap();
        
        dismissed();
    }
    
    public override bool key_press_event(Gdk.EventKey event) {
        // Escape dismisses popup
        if (event.keyval == Gdk.Key.Escape) {
            hide();
            
            return true;
        }
        
        return base.key_press_event(event);
    }
}

}

