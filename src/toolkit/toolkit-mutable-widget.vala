/* Copyright 2014-2015 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Toolkit {

/**
 * A {@link MutableWidget} is a Gtk.Widget whose internal state can change and affect its sort
 * order or filtering.
 */

public interface MutableWidget : Gtk.Widget {
    /**
     * Fired when internal state has changed which may affect sorting or filtering.
     *
     * This can be used by collections and other containers to update their own state, such as
     * re-sorting or re-applying filters.
     */
    public signal void mutated();
}

}

