/* Copyright 2014-2015 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Backing {

/**
 * A singleton repository of all supported backing {@link Store}s.
 */

public class Manager : BaseObject {
    public const string PROP_IS_OPEN = "is-open";
    
    public static Manager instance { get; private set; }
    
    public bool is_open { get; private set; default = false; }
    
    private Gee.List<Store> stores = new Gee.ArrayList<Store>();
    
    /**
     * Fired when a {@link Store} cannot be opened.
     */
    public signal void open_store_failed(Store store, Error err);
    
    /**
     * Fired when a {@link Store} adds a new {@link Source}.
     *
     * @see Source.source_added
     */
    public signal void source_added(Store store, Source source);
    
    /**
     * Fired when a {@link Store} removes a {@link Source}.
     *
     * @see Source.source_removed
     */
    public signal void source_removed(Store store, Source source);
    
    private Manager() {
    }
    
    internal static void init() {
        instance = new Manager();
    }
    
    internal static void terminate() {
        instance = null;
    }
    
    /**
     * The various stores are registered in {@link Backing.init}.
     *
     * This *must* be called prior to {@link open_async} for them to be opened properly.
     *
     * TODO: A plugin system may make sense here.
     */
    internal void register(Store store) {
        if (!stores.contains(store))
            stores.add(store);
    }
    
    /**
     * Asynchronously open the {@link Manager}.
     *
     * This must be called before any other operation on the Manager (unless noted).
     *
     * @returns The number of available (opened) {@link AbstractStore}s.
     */
    public async int open_async(Cancellable? cancellable) throws Error {
        int count = 0;
        foreach (Store store in stores) {
            store.source_added.connect(on_source_added);
            store.source_removed.connect(on_source_removed);
            
            try {
                yield store.open_async(cancellable);
                assert(store.is_open);
                
                count++;
            } catch (Error err) {
                store.source_added.disconnect(on_source_added);
                store.source_removed.disconnect(on_source_removed);
                
                // treat cancelled as cancelled
                if (err is IOError.CANCELLED)
                    throw err;
                
                debug("Unable to open backing store %s: %s", store.to_string(), err.message);
                
                open_store_failed(store, err);
            }
        }
        
        is_open = true;
        
        return count;
    }
    
    /**
     * Asynchronously close the {@link Manager}.
     *
     * @see open_async
     */
    public async void close_async(Cancellable? cancellable) throws Error {
        foreach (Store store in stores) {
            store.source_added.disconnect(on_source_added);
            store.source_removed.disconnect(on_source_removed);
            
            try {
                if (store.is_open) {
                    yield store.close_async(cancellable);
                    assert(!store.is_open);
                }
            } catch (Error err) {
                // cancelled means cancelled
                if (err is IOError.CANCELLED)
                    throw err;
                
                debug("Unable to close backing store %s: %s", store.to_string(), err.message);
            }
        }
        
        is_open = false;
    }
    
    private void on_source_added(Store store, Source source) {
        source_added(store, source);
    }
    
    private void on_source_removed(Store store, Source source) {
        source_removed(store, source);
    }
    
    /**
     * Returns a read-only list of all available {@link Store}s.
     *
     * Must only be called while the {@link Manager} is open.
     */
    public Gee.List<Store> get_stores() {
        return stores.read_only_view;
    }
    
    /**
     * Return a specific {@link Store}.
     *
     * This should only be used internally, specifically for {@link Activator}s.
     */
    internal Store? get_store_of_type<G>() {
        foreach (Store store in stores) {
            if (store.get_type().is_a(typeof(G)))
                return store;
        }
        
        return null;
    }
    
    /**
     * Returns a list of all available {@link Source}s of a particular type.
     *
     * Must only be called while the {@link Manager} is open.
     *
     * @see Store.get_sources_of_type
     */
    public Gee.List<G> get_sources_of_type<G>() {
        Gee.List<G> sources = new Gee.ArrayList<G>();
        foreach (Store store in stores)
            sources.add_all(store.get_sources_of_type<G>());
        
        return sources;
    }
    
    public override string to_string() {
        return "Manager";
    }
}

}

