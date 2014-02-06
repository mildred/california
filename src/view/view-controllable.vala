/* Copyright 2014 Yorba Foundation
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
    
    /**
     * A user-visible string representing the current calendar view.
     */
    public abstract string current_label { get; protected set; }
    
    /**
     * Flag indicating if the current calendar unit matches the unit the {@link today} method
     * could jump to.
     */
    public abstract bool is_viewing_today { get; protected set; }
    
    /**
     * Default {@link Calendar.Date} for the calendar unit in view.
     */
    public abstract Calendar.Date default_date { get; protected set; }
    
    /**
     * Signal from the {@link Controller} that an event should be created with the specified
     * initial parameters.
     */
    public signal void request_create_event(Calendar.DateTimeSpan initial, Gtk.Widget relative_to,
        Cairo.RectangleInt? for_location);
    
    /**
     * Move forward one calendar unit.
     */
    public abstract void next();
    
    /**
     * Move backward one calendar unit.
     */
    public abstract void prev();
    
    /**
     * Jump to calendar unit representing the current date.
     *
     * Returns the Gtk.Widget displaying the current date.
     */
    public abstract Gtk.Widget today();
}

}

