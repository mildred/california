/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California {

/**
 * A Card is a single pane of widget(s) in a {@link Deck}.
 *
 * The navigation of Cards is tracked within their Deck, and Cards can request navigation via their
 * various signals.  They're also notified when nevigation which affects them is made.
 */

public interface Card : Gtk.Widget {
    /**
     * Each {@link Card} has its own identifier that should be unique within the {@link Deck}.
     *
     * In the Gtk.Stack, this is its name.
     */
    public abstract string card_id { get; }
    
    /**
     * A user-visible string that may be used elsewhere in the application.
     *
     * Gtk.StackSwitcher uses this title.  {@link Deck} does not use the title in any way.
     */
    public abstract string? title { get; }
    
    /** 
     * The widget the {@link Card} wants to be default when navigated to.
     *
     * The widget must have can-default set to true.
     */
    public abstract Gtk.Widget? default_widget { get; }
    
    /**
     * The widget the {@link Card} wants to have initial focus when navigated to.
     *
     * Focus is set after {@link default_widget} is handled, so if this widget has receives-default
     * set to true, it will get the default as well.
     *
     * The widget must have can-focus set to true.
     */
    public abstract Gtk.Widget? initial_focus { get; }
    
    /**
     * Returns the {@link Deck} this {@link Card} is registered to, if any.
     */
    public Deck? deck { get { return parent as Deck; } }
    
    /**
     * Fired when the {@link Card} wishes to jump to another Card in the same {@link Deck.}
     *
     * Each Card can accept a message which parameterizes its activation.  It's up to Cards
     * navigating to the new one to construct and pass an appropriate message.
     *
     * @see jump_to_card_by_name
     */
    public signal void jump_to_card(Card next, Value? message);
    
    /**
     * Fired when the {@link Card} wishes to jump to another Card by its name.
     *
     * @see jump_to_card
     */
    public signal void jump_to_card_by_name(string name, Value? message);
    
    /**
     * Fired when the {@link Card} wishes to jump to the previous Card in the {@link Deck}.
     *
     * Note that this Card's position in the navigation stack is lost; there is no "jump forward".
     */
    public signal void jump_back();
    
    /**
     * Fired when the {@link Card} wishes to jump to the first Card in the {@link Deck}.
     *
     * This clears the Deck's navigation stack, meaning {@link jump_back} will not return to
     * this Card.
     */
    public signal void jump_home();
    
    /**
     * Fired when the {@link Deck}'s work is cancelled, closed, or dismissed, whether due to
     * programmatic reasons or by user request.
     *
     * Implementing classes should fire this after firing the {@link completed signal} so
     * subscribers can maintain their cleanup in a single handler.
     */
    public signal void dismissed(bool user_request);
    
    /**
     * Fired when the {@link Deck}'s work has completed successfully.
     *
     * This should only be fired if the Deck requires valid input from the user to perform
     * some intensive operation.  Merely displaying information and closing the Deck
     * should simply fire {@link dismissed}.
     *
     * "completed" implies that dismissed will be called shortly thereafter, meaning all
     * cleanup can be handled there.
     */
    public signal void completed();
    
    /**
     * Called by {@link Deck} when the {@link Card} has been activated, i.e. put to the "top" of
     * the Deck.
     *
     * message may be null even if the Card expects one; generally this means {@link jump_back}
     * or {@link jump_home} was invoked, resulting in this Card being activated.
     *
     * This is called before dealing with {@link default_widget} and {@link initial_focus}, so
     * changes to those properties in this call, if need be.
     */
    public abstract void jumped_to(Card? from, Value? message);
}

/**
 * A Deck is a collection of {@link Card}s maintained within a Gtk.Stack.
 *
 * Cards control navigation through their various signals, which Deck monitors and acts upon.
 * It also notifies Cards of nagivation changes which affect them via their abstract methods.
 */

public class Deck : Gtk.Stack, Host.Interaction {
    /**
     * @inheritedDoc
     */
    public Gtk.Widget? default_widget { get { return null; } }
    
    /**
     * The number of {@link Card}s registered to the {@link Deck}.
     */
    public int size { get { return list.size; } }
    
    /**
     * All registered {@link Card}s returned as a read-only List.
     */
    public Gee.List<Card> cards { owned get { return list.read_only_view; } }
    
    /**
     * The home {@link Card}.
     */
    public Card? home { owned get { return (list.size > 0) ? list[0] : null; } }
    
    /**
     * The current displayed {@link Card}.
     */
    public Card? top { get; private set; default = null; }
    
    private Gee.List<Card> list = new Gee.LinkedList<Card>();
    private Gee.Deque<Card> navigation_stack = new Gee.LinkedList<Card>();
    private Gee.HashMap<string, Card> names = new Gee.HashMap<string, Card>();
    
    /**
     * Create a new {@link Deck}.
     *
     * By default the Deck configures the underlying Gtk.Stack to slide left and right, depending
     * on the position of the {@link Card}s.  This can be changed, but the recommended
     * transition types are SLIDE_LEFT_RIGHT and SLIDE_UP_DOWN.
     */
    public Deck() {
        transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;
        notify["visible-child"].connect(on_child_to_top);
    }
    
    ~Deck() {
        foreach (Card card in names.values)
            card.map.disconnect(on_card_mapped);
    }
    
    private void on_child_to_top() {
        // disconnect from previous top card and push onto nav stack
        if (top != null) {
            top.jump_to_card.disconnect(on_jump_to_card);
            top.jump_to_card_by_name.disconnect(on_jump_to_card_by_name);
            top.jump_back.disconnect(on_jump_back);
            top.jump_home.disconnect(on_jump_home);
            top.dismissed.disconnect(on_dismissed);
            top.completed.disconnect(on_completed);
            
            navigation_stack.offer_head(top);
            top = null;
        }
        
        // make new visible child top Card and connect to its signals
        top = visible_child as Card;
        if (top != null) {
            top.jump_to_card.connect(on_jump_to_card);
            top.jump_to_card_by_name.connect(on_jump_to_card_by_name);
            top.jump_back.connect(on_jump_back);
            top.jump_home.connect(on_jump_home);
            top.dismissed.connect(on_dismissed);
            top.completed.connect(on_completed);
        }
    }
    
    /**
     * Add {@link Card}s to the {@link Deck}.
     *
     * Cards can be added in multiple batches, but the ordering is important as it dictates how
     * they're presented to the user via transitions and slides.
     *
     * The first Card added is the "home" Card.  The Deck will automatically show it first.
     */
    public void add_cards(Gee.List<Card> cards) {
        if (cards.size == 0)
            return;
        
        // if empty, first card is home and should be made visible when added
        bool set_home_visible = size == 0;
        
        // add each Card using the title if possible, otherwise by ID
        foreach (Card card in cards) {
            // each card must have a unique name
            assert(!String.is_empty(card.card_id));
            assert(!names.has_key(card.card_id));
            
            if (String.is_empty(card.title))
                add_named(card, card.card_id);
            else
                add_titled(card, card.card_id, card.title);
            
            names.set(card.card_id, card);
            
            // deal with initial_focus and default_widget when mapped, as the calls aren't
            // guaranteed to work during programmatic navigation (especially for the first card,
            // i.e. home)
            card.map.connect(on_card_mapped);
            
            // add in order to ensure order is preserved if sparsely removed later
            list.add(card);
        }
        
        if (set_home_visible && home != null) {
            set_visible_child(home);
            home.jumped_to(null, null);
        }
    }
    
    /**
     * Removes {@link Card}s from the {@link Deck}.
     *
     * If the {@link top} card is removed, the Deck will return {@link home}, clearing the
     * navigation stack in the process.
     */
    public void remove_cards(Gee.Iterable<Card> cards) {
        bool displaying = top != null;
        
        foreach (Card card in cards) {
            if (!names.has_key(card.card_id)) {
                message("Card %s not found in Deck", card.card_id);
                
                continue;
            }
            
            card.map.disconnect(on_card_mapped);
            
            remove(card);
            
            if (top == card)
                top = null;
            
            navigation_stack.remove(card);
            names.unset(card.card_id);
            list.remove(card);
        }
        
        // if was displaying a Card and now not, jump home
        if (displaying && top == null && home != null) {
            navigation_stack.clear();
            set_visible_child(home);
            home.jumped_to(null, null);
        }
    }
    
    private void on_jump_to_card(Card card, Card next, Value? message) {
        // do nothing if already visible
        if (get_visible_child() == next) {
            debug("Already showing card %s", next.card_id);
            
            return;
        }
        
        // do nothing if not registered with this Deck
        if (!names.values.contains(next)) {
            GLib.message("Card %s not registered with Deck", next.card_id);
            
            return;
        }
        
        set_visible_child(next);
        next.jumped_to(card, message);
    }
    
    private void on_jump_to_card_by_name(Card card, string name, Value? message) {
        Card? next = names.get(name);
        if (next != null)
            on_jump_to_card(card, next, message);
        else
            GLib.message("Card %s not found in Deck", name);
    }
    
    private void on_jump_back(Card card) {
        // if still not empty, next card is "back", so pop that off and jump to it
        if (!navigation_stack.is_empty)
            on_jump_to_card(card, navigation_stack.poll_head(), null);
    }
    
    private void on_jump_home(Card card) {
        // jumping home clears the navigation stack
        navigation_stack.clear();
        
        if (home != null)
            on_jump_to_card(card, home, null);
        else
            message("No home card in Deck");
    }
    
    private void on_dismissed(bool user_request) {
        dismissed(user_request);
    }
    
    private void on_completed() {
        completed();
    }
    
    private void on_card_mapped(Gtk.Widget widget) {
        Card card = (Card) widget;
        
        if (card.default_widget != null && card.default_widget.can_default)
            card.default_widget.grab_default();
        
        if (card.initial_focus != null && card.initial_focus.can_focus)
            card.initial_focus.grab_focus();
    }
}

}

