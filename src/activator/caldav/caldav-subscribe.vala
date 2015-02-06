/* Copyright 2014-2015 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Activator.CalDAV {

internal class Subscribe : California.Activator.Generic.Subscribe {
    public const string ID = "CalDAVActivatorPane";
    
    public override string card_id { get { return ID; } }
    
    public override string? title { get { return null; } }
    
    private Backing.CalDAVSubscribable store;
    
    public Subscribe(Backing.CalDAVSubscribable store, Soup.URI? supplied_url) {
        base (supplied_url, iterate<string>("http://", "https://").to_hash_set());
        
        this.store = store;
    }
    
    protected override async void subscribe_async(string name, Soup.URI uri, string? username,
        string color, Cancellable? cancellable) throws Error {
        yield store.subscribe_caldav_async(name, uri, username, color, cancellable);
    }
}

}

