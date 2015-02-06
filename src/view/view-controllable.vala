/* Copyright 2014-2015 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.View {

/**
 * All views need to offer this interface in their host, giving them a generic interface for the
 * controller window to manipulate.
 *
 * The Controllable is expected to maintain a current date, which can be manipulated through this
 * interface and report itself via properties.
 */

public interface Controllable : Object {
    public const string PROP_CURRENT_LABEL = "current-label";
    public const string PROP_IS_VIEWING_TODAY = "is-viewing-today";
    public const string PROP_DEFAULT_DATE = "default-date";
    public const string PROP_IN_TRANSITION = "in-transition";
    
    /**
     * For {@link execute_when_not_in_transition}.
     */
    public delegate void Callback(View.Controllable controller);
    
    /**
     * A short string uniquely identifying this view.
     *
     * Since this value will be persisted, it's important it does not change without good reason.
     */
    public abstract string id { get; }
    
    /**
     * A user-visible string (short) representing this view.
     */
    public abstract string title { get; }
    
    /**
     * A user-visible string representing the current calendar view.
     */
    public abstract string current_label { get; protected set; }
    
    /**
     * Flag indicating if the current calendar unit matches the unit the {@link today} method
     * could jump to.
     *
     * This value should update dynamically as {@link Calendar.System.today} changes.  There's no
     * requirement for the {@link Controllable} to change its view as the day changes, however.
     */
    public abstract bool is_viewing_today { get; protected set; }
    
    /**
     * The "logical" chronology motion when moving between views of time.
     */
    public abstract ChronologyMotion motion { get; }
    
    /**
     * Indicates when a transition is running (such as when moving between dates).
     */
    public abstract bool in_transition { get; protected set; }
    
    /**
     * Signal from the {@link Controllable} that a DATE-TIME {@link Component.Event} should be
     * created with the specified initial parameters.
     */
    public signal void request_create_timed_event(Calendar.ExactTimeSpan initial, Gtk.Widget relative_to,
        Gdk.Point? for_location);
    
    /**
     * Signal from the {@link Controllable} that a DATE {@link Component.Event} should be
     * created with the specified initial parameters.
     */
    public signal void request_create_all_day_event(Calendar.Span initial, Gtk.Widget relative_to,
        Gdk.Point? for_location);
    
    /**
     * Signal from the {@link Controllable} to display a {@link Component.Event}.
     */
    public signal void request_display_event(Component.Event event, Gtk.Widget relative_to,
        Gdk.Point? for_location);
    
    /**
     * Signal from the {@link Controllable} that the {@link Component.Event} editor should be
     * opened.
     */
    public signal void request_edit_event(Component.Event event, Gtk.Widget relative_to,
        Gdk.Point? for_location);
    
    /**
     * Returns the {@link Container} that should be used to display the {@link Controllable}'s
     * contents.
     *
     * This should not return a new Gtk.Widget each time, rather it returns the Widget the
     * Controllable is maintaining the current view(s) in.
     */
    public abstract View.Container get_container();
    
    /**
     * Move forward one calendar unit.
     */
    public abstract void next();
    
    /**
     * Move backward one calendar unit.
     */
    public abstract void previous();
    
    /**
     * Jump to calendar unit representing the current date.
     */
    public abstract void today();
    
    /**
     * If the view supports a notion of selection, this unselects all selected items.
     *
     * The view controller will use this to clear selection after completing a request (for example,
     * when creating or displaying events).
     */
    public abstract void unselect_all();
    
    /**
     * Return the GtkWidget that represents the specified {@link Calendar.Date}, if available.
     */
    public abstract Gtk.Widget? get_widget_for_date(Calendar.Date date);
    
    /**
     * Execute a {@link Callback} only when the {@link Controllable} is not performing a transition.
     *
     * If the Controllable is not in transition when called, the Callback is executed immediately.
     * Otherwise, execution is delayed until the transition completes.
     */
    public void execute_when_not_transitioning(Callback callback) {
        if (!in_transition) {
            callback(this);
            
            return;
        }
        
        ulong handler_id = 0;
        handler_id = notify[PROP_IN_TRANSITION].connect(() => {
            // watch for spurious notifications
            if (in_transition)
                return;
            
            // disable this signal
            if (handler_id > 0)
                disconnect(handler_id);
            else
                debug("Unable to disconnect in-transition notify signal handler");
            
            callback(this);
        });
    }
}

}

