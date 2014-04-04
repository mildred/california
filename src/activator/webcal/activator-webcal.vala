/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Activator {

internal class WebCalActivator : Instance {
    public override string first_card_id { get { return WebCalActivatorPane.ID; } }
    
    private Backing.WebCalSubscribable webcal_store;
    
    public WebCalActivator(string title, Backing.WebCalSubscribable store) {
        base (title, store);
        
        webcal_store = store;
    }
    
    public override Gee.List<Toolkit.Card> create_cards(Soup.URI? supplied_uri) {
        Gee.List<Toolkit.Card> cards = new Gee.ArrayList<Toolkit.Card>();
        cards.add(new WebCalActivatorPane(webcal_store, supplied_uri));
        
        return cards;
    }
}

}

