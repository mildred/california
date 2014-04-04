/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Backing {

/**
 * An abstract representation of a backing source of calendar information.
 *
 * @see Manager
 * @see Source
 */

public abstract class CalendarSource : Source {
    protected CalendarSource(string id, string title) {
        base (id, title);
    }
    
    /**
     * Obtain a {@link CalendarSourceSubscription} for the specified date window.
     */
    public abstract async CalendarSourceSubscription subscribe_async(Calendar.ExactTimeSpan window,
        Cancellable? cancellable = null) throws Error;
    
    /**
     * Creates a new {@link Component} instance on the backing {@link CalendarSource}.
     *
     * Outstanding {@link CalendarSourceSubscriptions} will eventually report the generated
     * instance when it's available.
     *
     * @returns The {@link Component.UID}.of the generated instance, if available.
     */
    public abstract async Component.UID? create_component_async(Component.Instance instance,
        Cancellable? cancellable = null) throws Error;
    
    /**
     * Updates an existing {@link Component} instance on the backing {@link CalendarSource}.
     *
     * Outstanding {@link CalendarSourceSubscriptions} will eventually report the changes when
     * ready.
     */
    public abstract async void update_component_async(Component.Instance instance,
        Cancellable? cancellable = null) throws Error;
    
    /**
     * Destroys (removes) a {@link Component} instance on the backing {@link CalendarSource}.
     *
     * Outstanding {@link CalendarSourceSubscriptions} will eventually report the instance as
     * removed.
     */
    public abstract async void remove_component_async(Component.UID uid,
        Cancellable? cancellable = null) throws Error;
}

}

