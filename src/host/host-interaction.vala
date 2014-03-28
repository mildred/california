/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Host {

/**
 * A simple entry form or display for the user.
 *
 * This abstraction is to handle a couple of problems:
 *
 * (a) Because California currently works only with GTK+ 3.10, GtkPopup is unavailable, although
 * it's a widget we'd like to use soon.  GtkDialog is used in its place, but we don't want to
 * hard-code GtkDialog throughout the application.  So the Glade components are hosted inside a
 * GtkDialog, but this poses other subtle problems (such as with activating default).
 *
 * (b) Glade, at time of writing, doesn't support GtkPopup anyway, so this layer is even required
 * for GTK+ 3.12.
 */

public interface Interaction : Gtk.Widget {
    /**
     * The default widget for the {@link Interaction}.
     */
    public abstract Gtk.Widget? default_widget { get; }
    
    /**
     * Fired when the interaction is cancelled, closed, or dismissed the {@link Interaction},
     * whether due to programmatic reasons or by user request.
     *
     * This should be called by implementing classes even if other signals suggest or imply that
     * the Interaction is dismissed, so a single signal handler can deal with cleanup.
     */
    public signal void dismissed(bool user_request);
    
    /**
     * Fired when the {@link Interaction} has completed successfully.
     *
     * This should only be fired if the Interaction requires valid input from the user to perform
     * some intensive operation.  Merely displaying information and closing the Interaction
     * should simply fire {@link dismissed}.
     *
     * "completed" implies that dismissed will be called shortly thereafter, meaning all
     * cleanup can be handled there.
     */
    public signal void completed();
}

}

