/* Copyright 2014-2015 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Activator.WebCal {

internal class ActivatorInstance : Instance {
    public override string first_card_id { get { return Subscribe.ID; } }
    
    private Backing.WebCalSubscribable webcal_store;
    
    public ActivatorInstance(string title, Backing.WebCalSubscribable store) {
        base (title, store);
        
        webcal_store = store;
    }
    
    public override Gee.List<Toolkit.Card> create_cards(Soup.URI? supplied_uri) {
        return iterate<Toolkit.Card>(new Subscribe(webcal_store, supplied_uri))
            .to_array_list();
    }
}

}

