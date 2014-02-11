/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Backing {

/**
 * An abstract representation of a backing source of information.
 *
 * The Source is initialized, opened, closed, and terminated by the {@link Backing.Manager}.
 * However, a Source may be removed or destroyed at any time.  See {@link is_available} for more
 * information.
 *
 * @see Manager
 */

public abstract class Source : BaseObject {
    public const string PROP_IS_AVAILABLE = "is-available";
    
    /**
     * True if the {@link Source} is unavailable for use due to being removed from it's
     * {@link Backing.Store}.
     *
     * Ref holders should connect to the "notify" signal and disconnect and drop refs when this
     * goes false.
     *
     * @see set_unavailable
     */
    public bool is_available { get; private set; default = true; }
    
    /**
     * A user-visible name for the {@link Source}.
     */
    public string title { get; private set; }
    
    protected Source(string title) {
        this.title = title;
    }
    
    /**
     * Marks a {@link Source} as unavailable.
     *
     * A Source cannot return to the available state after this is called.  Should only be called
     * by the {@link Store} that created or manages the Source.
     *
     * @see is_unavailable
     */
    internal void set_unavailable() {
        is_available = false;
    }
    
    public override string to_string() {
        return title;
    }
}

}

