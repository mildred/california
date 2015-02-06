/* Copyright 2014-2015 Yorba Foundation
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
    public const string PROP_DEFAULT_CALENDAR = "default-calendar";
    
    /**
     * Set when the {@link Store} is opened.
     *
     * This must be set by the base class.
     */
    public bool is_open { get; protected set; default = false; }
    
    /**
     * Set to the default {@link CalendarSource} for this {@link Store}.
     */
    public CalendarSource? default_calendar { get; protected set; default = null; }
    
    private string desc;
    
    /**
     * Fired when a {@link Source} is added to the {@link Store}.
     *
     * Also fired in {@link open_async} when Sources are discovered.
     */
    public virtual signal void source_added(Source source) {
        debug("%s: added %s", to_string(), source.to_string());
    }
    
    /**
     * Fired when an {@link Source} has been removed from the {@link Store}.
     *
     * Callers who are using the Source should disconnect from it and drop their refs.
     *
     * Also called in {@link close_async} when internal refs are being dropped.
     */
    public virtual signal void source_removed(Source source) {
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
     * Asynchronously remove the {@link Source} from the {@link Store}.
     *
     * This is a permanent deletion of local data and the Source will no longer be available to the
     * user.  There is no mechanism here for optionally deleting the account or calendar on the
     * network backend, if any.
     *
     * This Store ''must'' be the same as {@link Source.store}.  INVALID is thrown otherwise.
     *
     * This operation is guaranteed not to succeed if {@link Source.is_removable} is false.
     *
     * The Store must be open before calling this method.
     */
    public abstract async void remove_source_async(Source source, Cancellable? cancellable) throws Error;
    
    /**
     * Return a read-ony list of all {@link Source}s managed by this {@link Store}.
     *
     * The Sources will be sorted by their titles in lexiographic order.
     *
     * @see get_sources_of_type
     * @see Source.title
     */
    public abstract Gee.List<Source> get_sources();
    
    /**
     * List all available {@link Source}s of a particular type.
     *
     * The Sources will be sorted by their titles in lexiographic order.
     *
     * Although any GType can be specified, it obviously is most useful to pass {@link Source} or
     * one of its subclasses.
     */
    public virtual Gee.List<G> get_sources_of_type<G>() {
        Gee.List<G> result = new Gee.ArrayList<G>();
        foreach (Source source in get_sources()) {
            if (source.get_type().is_a(typeof(G)))
                result.add(source);
        }
        
        return result;
    }
    
    /**
     * Set the {@link CalendarSource} to the default for this {@link Store}.
     *
     * @throws {@link BackingError.MISMATCH} if CalendarSource did not originate from this store.
     */
    public abstract void make_default_calendar(Backing.CalendarSource calendar) throws Error;
    
    public override string to_string() {
        return desc;
    }
}

}

