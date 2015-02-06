/* Copyright 2014-2015 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

/**
 * A grab bag of utility classes for working with GTK.
 */

namespace California.Toolkit {

/**
 * Gtk.Stack transition duration is a little quick for my tastes; this default value seems a bit
 * smoother to me.
 */
public const int DEFAULT_STACK_TRANSITION_DURATION_MSEC = 300;

/**
 * Gtk.Stack transition duration for slower transitions (where it really needs to be obvious to
 * user what's going on).
 */
public const int SLOW_STACK_TRANSITION_DURATION_MSEC = 500;

/**
 * Indicates a GTK/GDK event should not be propagated further (no processing by other handlers).
 */
public const bool STOP = true;

/**
 * Indicates a GTK/GDK event should be propagated (continue processing by other handlers).
 */
public const bool PROPAGATE = false;

private int init_count = 0;
private Gee.Set<Gtk.Widget>? dead_pool = null;
private Scheduled? dead_pool_gc = null;

public void init() throws Error {
    if (!Unit.do_init(ref init_count))
        return;
    
    dead_pool = new Gee.HashSet<Gtk.Widget>();
    
    Calendar.init();
    Collection.init();
}

public void terminate() {
    if (!Unit.do_terminate(ref init_count))
        return;
    
    Collection.terminate();
    Calendar.terminate();
    
    dead_pool = null;
    dead_pool_gc = null;
}

/**
 * Spin the GTK event loop until all pending events are completed.
 */
public void spin_event_loop() {
    while (Gtk.events_pending())
        Gtk.main_iteration();
}

/**
 * Sets the window as "busy" by changing the cursor.
 *
 * @returns the window's current Gdk.Cursor.  This will need to be passed to
 * {@link set_window_unbusy}.
 */
public Gdk.Cursor? set_busy(Gtk.Widget widget) {
    return set_toplevel_cursor(widget, Gdk.CursorType.WATCH);
}

/**
 * Sets the window as "unbusy".
 *
 * Pass the Gdk.Cursor returned by {@link set_window_busy}.
 */
public void set_unbusy(Gtk.Widget widget, Gdk.Cursor? unbusy_cursor) {
    Gtk.Widget toplevel = widget.get_toplevel();
    if (!toplevel.is_toplevel()) {
        if (unbusy_cursor != null)
            debug("Unable to set unbusy: widget has no toplevel window");
        
        return;
    }
    
    toplevel.get_window().set_cursor(unbusy_cursor);
}

/**
 * Sets the Gtk.Widget's toplevel's cursor.
 *
 * @returns The toplevel's current cursor.  This can be saved to restore later or simply dropped.
 */
public Gdk.Cursor? set_toplevel_cursor(Gtk.Widget widget, Gdk.CursorType? cursor_type) {
    Gtk.Widget toplevel = widget.get_toplevel();
    if (!toplevel.is_toplevel()) {
        debug("Unable to set cursor: widget has no toplevel window");
        
        return null;
    }
    
    Gdk.Window gdk_window = toplevel.get_window();
    Gdk.Cursor? old_cursor = gdk_window.get_cursor();
    
    if (cursor_type != null)
        gdk_window.set_cursor(new Gdk.Cursor.for_display(toplevel.get_display(), cursor_type));
    else
        gdk_window.set_cursor(null);
    
    return old_cursor;
}

/**
 * Set xalign property on Gtk.Label in a compatible way.
 *
 * GtkMisc is being deprecated in GTK+ 3 and the "xalign" property has been moved to GtkLabel.  This
 * causes compatibility problems with newer versions of Vala generating code that won't link with
 * older versions of GTK+.  This is a convenience method until California requires GTK+ 3.16 as its
 * minimum GTK+ version.
 *
 * See [[https://bugzilla.gnome.org/show_bug.cgi?id=741265]]
 */
public void set_label_xalign(Gtk.Label label, float xalign) {
    label.set("xalign", xalign);
}

/**
 * Destroy a Gtk.Widget when the event loop is idle.
 */
public void destroy_later(Gtk.Widget widget) {
    if (!dead_pool.add(widget))
        return;
    
    // always reschedule
    dead_pool_gc = new Scheduled.once_at_idle(() => {
        // traverse_safely makes a copy of the dead_pool, so filter() won't work to remove destroyed
        // elements, but that also means we can safely remove elements from it in the iterate()
        // handler ... need to jump through these hoops because the widget.destroy() signal handlers
        // may turn around and add more widgets to the dead pool during traversal
        traverse_safely<Gtk.Widget>(dead_pool).iterate((widget) => {
            widget.destroy();
            dead_pool.remove(widget);
        });
    }, Priority.LOW);
}

/**
 * Prevent prelight when a mouse hovers over the widget.
 *
 * This operates by preventing the Gtk.StateFlag.PRELIGHT state from being entered.  This may have
 * negative effects for some widgets and should be used with caution.
 */
public void prevent_prelight(Gtk.Widget widget) {
    widget.state_flags_changed.connect(on_state_flags_changed);
}

private void on_state_flags_changed(Gtk.Widget widget, Gtk.StateFlags old_state_flags) {
    if ((widget.get_state_flags() & Gtk.StateFlags.PRELIGHT) != 0)
        widget.unset_state_flags(Gtk.StateFlags.PRELIGHT);
}

/**
 * When a child GtkScrolledWindow is visible, the entire GtkStack's background color goes black;
 * this overrides the color and uses the toplevel's background color for the child widget.  See:
 * https://bugzilla.gnome.org/show_bug.cgi?id=735421
 * and https://bugzilla.gnome.org/show_bug.cgi?id=742310
 */
public void unity_fixup_background(Gtk.Widget widget) {
#if ENABLE_UNITY
    widget.realize.connect(on_unity_fixup_realize);
    
    Gtk.Container? container = widget as Gtk.Container;
    if (container == null)
        return;
    
    // Fixup all existing children
    container.foreach(unity_fixup_background);
    
    // Fixup all added children
    container.add.connect(unity_fixup_background);
#endif
}

#if ENABLE_UNITY
private void on_unity_fixup_realize(Gtk.Widget widget) {
    Gdk.RGBA bg = widget.get_toplevel().get_style_context().get_background_color(Gtk.StateFlags.NORMAL);
    widget.override_background_color(Gtk.StateFlags.NORMAL, bg);
}
#endif

}
