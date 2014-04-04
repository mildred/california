/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Activator {

internal class GoogleActivator : Instance {
    public override string first_card_id { get { return GoogleLoginPane.ID; } }
    
    private Backing.CalDAVSubscribable caldav_store;
    
    public GoogleActivator(string title, Backing.CalDAVSubscribable store) {
        base (title, store);
        
        caldav_store = store;
    }
    
    public override Gee.List<Toolkit.Card> create_cards(Soup.URI? supplied_uri) {
        Gee.List<Toolkit.Card> cards = new Gee.ArrayList<Toolkit.Card>();
        cards.add(new GoogleLoginPane());
        cards.add(new GoogleAuthenticatingPane());
        cards.add(new GoogleCalendarListPane(caldav_store));
        
        return cards;
    }
}

}

