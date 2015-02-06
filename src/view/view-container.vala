/* Copyright 2014-2015 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.View {

/**
 * A Gtk.Widget returned by {@link Controllable} that acts as the container for the entire view.
 *
 * As tempting as it is to make this interface depend on Gtk.Container, we'll leave this fairly
 * generic for now.
 */

public interface Container : Gtk.Widget {
    /**
     * The {@link Controllable} that owns this {@link Container}.
     */
    public abstract unowned Controllable owner { get; }
}

}

