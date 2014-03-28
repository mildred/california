/* Copyright 2014 Yorba Foundation
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
    private Gee.List<Activator> activators = new Gee.ArrayList<Activator>();
    
    /**
     * Fired when a {@link Store} cannot be opened.
     */
    public signal void open_store_failed(Store store, Error err);
    
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
    internal void register_store(Store store) {
        if (!stores.contains(store))
            stores.add(store);
    }
    
    /**
     * The various {@link Activators} are registered in {@link Backing.init}.
     *
     * This *must* be called prior to {@link open_async} for them to be opened properly.
     *
     * TODO: A plugin system may make sense here.
     */
    internal void register_activator(Activator activator) {
        if (!activators.contains(activator))
            activators.add(activator);
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
            try {
                yield store.open_async(cancellable);
                assert(store.is_open);
                
                count++;
            } catch (Error err) {
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
    
    /**
     * Returns a read-only list of all available {@link Activator}s.
     *
     * Must only be called wheil the {@link Manager} is open.
     */
    public Gee.List<Activator> get_activators() {
        return activators.read_only_view;
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
     * Returns a list of all available {@link Source}s of a particular type.
     *
     * The list will be sorted by the Sources title in lexiographic order.
     *
     * Must only be called while the {@link Manager} is open.
     *
     * @see Store.get_sources_of_type
     */
    public Gee.List<G> get_sources_of_type<G>() {
        Gee.List<G> sources = new Gee.ArrayList<G>();
        foreach (Store store in stores)
            sources.add_all(store.get_sources_of_type<G>());
        
        sources.sort((a, b) => {
            return String.stricmp(((Source) a).title, ((Source) b).title);
        });
        
        return sources;
    }
    
    public override string to_string() {
        return "Manager";
    }
}

}

