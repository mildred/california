/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Backing {

internal class WebCalActivator : Activator {
    private WebCalSubscribable webcal_store;
    
    public WebCalActivator(string title, WebCalSubscribable store) {
        base (title, store);
        
        webcal_store = store;
    }
    
    public override Host.Interaction create_interaction(Soup.URI? supplied_uri) {
        return new WebCalActivatorPane(webcal_store, supplied_uri);
    }
}

}

