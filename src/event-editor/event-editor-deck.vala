/* Copyright 2014-2015 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.EventEditor {

public class Deck : Toolkit.Deck {
    public new Component.Event event { get; private set; }
    
    /**
     * Although this {@link Toolkit.Deck} treats all {@link Component.Event}s as being edited,
     * is_update should be used to indicate to the user if a create or update is occurring.
     */
    public Deck(Component.Event event, bool is_update) {
        this.event = event;
        
        MainCard main_card = new MainCard();
        main_card.is_update = is_update;
        
        add_cards(
            iterate<Toolkit.Card>(main_card, new RecurringCard(), new DateTimeCard(), new AttendeesCard())
                .to_array_list()
        );
        
        // "initialize" the Deck with the Event
        go_home(event);
    }
}

}

