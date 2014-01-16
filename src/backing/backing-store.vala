/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Backing {

/**
 * An abstract interface to a storage medium of {@link Source}s, each representing a calendar.
 *
 * @see Manager
 */

public abstract class Store : BaseObject {
    public const string PROP_IS_OPEN = "is-open";
    
    /**
     * Set when the {@link Store} is opened.
     *
     * This must be set by the base class.
     */
    public bool is_open { get; protected set; default = false; }
    
    private string desc;
    
    /**
     * Fired when a {@link Source} is added to the {@link Store}.
     *
     * Also fired in {@link open_async} when Sources are discovered.
     */
    public virtual signal void added(Source source) {
        debug("%s: added %s", to_string(), source.to_string());
    }
    
    /**
     * Fired when an {@link Source} has been removed from the {@link Store}.
     *
     * Callers who are using the Source should disconnect from it and drop their refs.
     *
     * Also called in {@link close_async} when internal refs are being dropped.
     */
    public virtual signal void removed(Source source) {
        debug("%s: removed %s", to_string(), source.to_string());
    }
    
    protected Store(string desc) {
        this.desc = desc;
    }
    
    /**
     * Asynchronously open the {@link Store}.
     *
     * The Store should perform whatever operations are necessary to fulfill the other
     * operations, since some are not asynchronous and are not expected to block.
     *
     * If the backing store has {@link Sources} already registered or created, they should be
     * reported via the "added" signal in the context of the call.
     *
     * Almost all operations on the Store cannot happen until it's been opened.
     */
    internal abstract async void open_async(Cancellable? cancellable) throws Error;
    
    /**
     * Asynchronously close the {@link Store}.
     *
     * All {@link Sources} reported via "added" but not "removed" will be signalled as disconnected
     * via the "removed" signal in the context of this call.
     *
     * @see open_async
     */
    internal abstract async void close_async(Cancellable? cancellable) throws Error;
    
    /**
     * Return a read-ony collection of all {@link Sources} managed by this {@link Store}.
     *
     * @see get_sources_of_type
     */
    public abstract Gee.Collection<Source> get_sources();
    
    /**
     * List all available {@link Sources} of a particular type.
     *
     * Although of_type can be any GType, it obviously is most useful to pass {@link Source} or
     * one of its subclasses.
     */
    public virtual Gee.Collection<Source> get_sources_of_type(Type of_type) {
        Gee.Collection<Source> result = new Gee.ArrayList<Source>();
        foreach (Source source in get_sources()) {
            if (source.get_type().is_a(of_type))
                result.add(source);
        }
        
        return result;
    }
    
    public override string to_string() {
        return desc;
    }
}

}

