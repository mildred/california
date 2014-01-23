/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Backing {

/**
 * A subscription to an active timespan of interest of a calendar.
 *
 * The subscription can notify of calendar event updates and list a complete or partial collections
 * of the same.
 */

public abstract class CalendarSourceSubscription : BaseObject {
    /**
     * The {@link CalendarSource} providing this subscription's information.
     */
    public CalendarSource calendar { get; private set; }
    
    /**
     * The date-time window.
     *
     * This represents the span of time of interest for thie calendar source.
     */
    public Calendar.DateTimeSpan window { get; private set; }
    
    /**
     * Indicates the subscription is running (started).
     *
     * If it's important to know when {@link start} completes in the background, the caller can
     * watch for this property to change state to true.  {@link start_failed} is fired if start()
     * completed with an Error.
     *
     * Once set, the Cancellable passed to start is no longer referenced by the subscription.
     *
     * This can't be set inactive by the caller, but it can happen at any time (such as the
     * calendar being removed or closed).
     */
    public bool active { get; protected set; default = false; }
    
    /**
     * Fired as existing {@link Component.Event}s are discovered when starting a subscription.
     *
     * This is fired while {@link start} is working, either in the foreground or in the background.
     * It won't fire until start() is invoked.
     */
    public signal void event_discovered(Component.Event event);
    
    /**
     * Indicates that an event within the {@link window} has been added to the calendar.
     *
     * The signal is fired for both local additions (added through this interface) and remote
     * additions.
     *
     * This signal won't fire until {@link start} is called.
     */
    public signal void event_added(Component.Event event);
    
    /**
     * Indicates that an event within the {@link date_window} has been removed from the calendar.
     *
     * The signal is fired for both local removals (added through this interface) and remote
     * removals.
     *
     * This signal won't fire until {@link start} is called.
     */
    public signal void event_removed(Component.Event event);
    
    /**
     * Indicates that an event within the {@link date_window} has been altered.
     *
     * This is fired after the alterations have been made.  Since the {@link Component.Instance}s
     * are mutable, it's possible to monitor their properties for changes and be notified that way.
     *
     * The signal is fired for both local additions (added through this interface) and remote
     * additions.
     *
     * This signal won't fire until {@link start} is called.
     */
    public signal void event_altered(Component.Event event);
    
    /**
     * Fired if {@link start} failed.
     *
     * Because start() may require background operations to complete, it's possible for it to return
     * without error and only discover later the issue.  This signal is fired when that occurs.
     *
     * It's possible for this to be called in the context of start().
     *
     * If this fires, this subscription should be considered inactive.  Do not call start() again.
     */
    public signal void start_failed(Error err);
    
    private Gee.HashMap<Component.UID, Component.Event> events = new Gee.HashMap<
        Component.UID, Component.Event>();
    
    protected CalendarSourceSubscription(CalendarSource calendar, Calendar.DateTimeSpan window) {
        this.calendar = calendar;
        this.window = window;
    }
    
    /**
     * Add a pre-existing {@link Component.Event} to the subscription and notify subscribers.
     *
     * As with the other notify_*() methods, subclasses should invoke this method to fire the
     * signal rather than do it directly.  This gives {@link CalenderSourceSubscription} the
     * opportunity to update its internal state prior to firing the signal.
     *
     * It can also be overridden by a subclass to take action before or after the signal is fired.
     *
     * @see event_discovered
     */
    protected virtual void notify_event_discovered(Component.Event event) {
        if (!events.has_key(event.uid)) {
            events.set(event.uid, event);
            event_discovered(event);
        } else {
            debug("Cannot add discovered event %s to %s: already known", event.to_string(), to_string());
        }
    }
    
    /**
     * Add a new {@link Component.Event} to the subscription and notify subscribers.
     *
     * @see notify_event_discovered
     * @see event_added
     */
    protected virtual void notify_event_added(Component.Event event) {
        if (!events.has_key(event.uid)) {
            events.set(event.uid, event);
            event_added(event);
        } else {
            debug("Cannot add event %s to %s: already known", event.to_string(), to_string());
        }
    }
    
    /**
     * Remove an {@link Component.Event} from the subscription and notify subscribers.
     *
     * @see notify_event_discovered
     * @see event_removed
     */
    protected virtual void notify_event_removed(Component.UID uid) {
        Component.Event? event;
        if (events.unset(uid, out event))
            event_removed(event);
        else
            debug("Cannot remove UID %s from %s: not known", uid.to_string(), to_string());
    }
    
    /**
     * Update an altered {@link Component.Event} and notify subscribers.
     *
     * @see notify_event_discovered
     * @see event_altered
     */
    protected virtual void notify_event_altered(Component.Event event) {
        if (events.has_key(event.uid))
            event_altered(event);
        else
            debug("Cannot notify altered event %s in %s: not known", event.to_string(), to_string());
    }
    
    /**
     * Start the subscription.
     *
     * Notification signals won't start until this is called.  This is to allow the caller a chance
     * to connect to the signals of interest before receiving notifications, so nothing is missed.
     *
     * Only new events trigger "event-added".  To fetch a current list of all events in the
     * window, use {@link list_events}.
     *
     * A subscription can't be stopped or the {@link window} altered.  Simply drop the reference
     * and create another one with {@link CalendarSource.subscribe_async}.
     *
     * If start is cancelled, the caller should assume this object to be invalid (incomplete)
     * unless {@link active} is true.  At that point the Cancellable will no longer be used by
     * the subscription.
     */
    public abstract void start(Cancellable? cancellable = null);
    
    /**
     * Returns an {@link Component.Instance} for the {@link Component.UID}.
     *
     * @returns null if the UID has not been seen.
     */
    public Component.Instance? for_uid(Component.UID uid) {
        return events.get(uid);
    }
    
    /**
     * Returns a read-only Map of all known {@link Component.Event}s.
     */
    public Gee.Map<Component.UID, Component.Event> get_events() {
        return events.read_only_view;
    }
    
    public override string to_string() {
        return "%s::%s".printf(calendar.to_string(), window.to_string());
    }
}

}

