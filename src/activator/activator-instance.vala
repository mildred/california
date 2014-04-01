/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Activator {

/**
 * Locates, validates, and authorizes access to a {@link Backing.Source}.
 *
 * Actovators are decoupled from the Backing.Source itself because it's possible for Activators
 * to be used for multiple backings.  For example, a Google Calendar Activator can be used to
 * locate the user's calendar information, which can then be passed on to the EDS or a GData
 * backing.
 */

public abstract class Instance : BaseObject {
    public const string PROP_TITLE = "title";
    public const string PROP_STORE = "store";
    
    /**
     * The user-visible title of this {@link Activator} indicating what service or type of service
     * it can prepare a subscription for.
     */
    public string title { get; private set; }
    
    /**
     * The {@link Backing.Store} this {@link Instance} will create the new {@link Backing.Source}
     * in.
     *
     * It's up to the subclass to determine which Stores will work with its information.
     */
    public Backing.Store store { get; private set; }
    
    protected Instance(string title, Backing.Store store) {
        this.title = title;
        this.store = store;
    }
    
    /**
     * Return a {@link Host.Interaction} that guides the user through the steps to create a
     * {@link Backing.Source}.
     */
    public abstract Host.Interaction create_interaction(Soup.URI? supplied_uri);
    
    public override string to_string() {
        return title;
    }
}

}

