/* Copyright 2014-2015 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Backing {

/**
 * Interface allowing for a {@link Store} to subscribe to WebCal calendars.
 *
 * See [[https://web.archive.org/web/20071222113039/http://larry.cannell.org/webcal]] for more
 * information about WebCal.
 */

public interface WebCalSubscribable : Store {
    /**
     * Subscribe to a WebCal link, creating a new {@link CalendarSource} in the process.
     *
     * "title" is the display name of the new subscription and should probably be supplied by the
     * user.
     *
     * The CalendarSource is not returned; rather, callers should be subscribed to the
     * {@link Store.added} signal for notification.
     */
    public abstract async void subscribe_webcal_async(string title, Soup.URI uri, string? username,
        string color, Cancellable? cancellable) throws Error;
}

}

