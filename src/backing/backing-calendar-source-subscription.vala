/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Backing {

/**
 * An active date span of interest that can notify of calendar event updates and list complete
 * collections of the same.
 */

public abstract class CalendarSourceSubscription : BaseObject {
    /**
     * The {@link CalendarSource} providing this subscription's information.
     */
    public CalendarSource calendar { get; private set; }
    
    /**
     * The date window.
     *
     * This represents the span of time of interest for thie calendar source.
     */
    public Calendar.DateSpan window { get; private set; }
    
    /**
     * Indicates the subscription is running (started).
     *
     * This can't be set inactive by the caller, but it can happen at any time (such as the
     * calendar being removed or closed).
     */
    public bool active { get; protected set; default = false; }
    
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
    
    protected CalendarSourceSubscription(CalendarSource calendar, Calendar.DateSpan window) {
        this.calendar = calendar;
        this.window = window;
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
     * @see start_failed
     */
    public abstract void start(Cancellable? cancellable = null);
    
    public override string to_string() {
        return "%s::%s".printf(calendar.to_string(), window.to_string());
    }
}

}

