/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Toolkit {

/**
 * A {@link EventConnector} for (mouse) button events.
 *
 * "Raw" GDK events may be trapped by subscribing to {@link pressed} and {@link released}.  These
 * signals also provide Cancellables; if set (cancelled), the event will not propagate further.
 *
 * Otherwise, ButtonConnector will continue monitoring raw events and convert them into friendlier
 * signals: {@link clicked}, {@link double_clicked}, and {@link triple_clicked}.  A complete set
 * of press/release events are effectively translated into a single clicked event.  This relieves
 * the application of the problem of receving a clicked event and having to wait to determine if
 * a double-click will follow.
 */

public class ButtonConnector : EventConnector {
    // GDK reports 250ms is used to determine if a click is a double-click (and another 250ms for
    // triple-click), so pause just a little more than that to determine if all the clicking is
    // done
    private const int CLICK_DETERMINATION_DELAY_MSEC = 255;
    
    // The actual ButtonEvent, with some useful functionality for release timeouts
    private class InternalButtonEvent : ButtonEvent {
        private uint timeout_id = 0;
        
        public signal void release_timeout();
        
        public InternalButtonEvent(Gtk.Widget widget, Gdk.EventButton event) {
            base (widget, event);
        }
        
        ~InternalButtonEvent() {
            cancel_timeout();
        }
        
        private void cancel_timeout() {
            if (timeout_id == 0)
                return;
            
            Source.remove(timeout_id);
            timeout_id = 0;
        }
        
        public override void update_press(Gtk.Widget widget, Gdk.EventButton press_event) {
            base.update_press(widget, press_event);
            
            cancel_timeout();
        }
        
        public override void update_release(Gtk.Widget widget, Gdk.EventButton release_event) {
            base.update_release(widget, release_event);
            
            cancel_timeout();
            timeout_id = Timeout.add(CLICK_DETERMINATION_DELAY_MSEC, on_timeout, Priority.LOW);
        }
        
        private bool on_timeout() {
            timeout_id = 0;
            
            release_timeout();
            
            return false;
        }
    }
    
    private Gee.HashMap<Gtk.Widget, InternalButtonEvent> primary_states = new Gee.HashMap<
        Gtk.Widget, InternalButtonEvent>();
    private Gee.HashMap<Gtk.Widget, InternalButtonEvent> secondary_states = new Gee.HashMap<
        Gtk.Widget, InternalButtonEvent>();
    private Gee.HashMap<Gtk.Widget, InternalButtonEvent> tertiary_states = new Gee.HashMap<
        Gtk.Widget, InternalButtonEvent>();
    private Cancellable cancellable = new Cancellable();
    
    /**
     * The "raw" "button-pressed" signal received by {@link ButtonConnector}.
     *
     * Signal subscribers should cancel the Cancellable to prevent propagation of the event.
     * This will prevent the various "clicked" signals from firing.
     */
    public signal void pressed(Gtk.Widget widget, Gdk.EventButton event, Cancellable cancellable);
    
    /**
     * The "raw" "button-released" signal received by {@link ButtonConnector}.
     *
     * Signal subscribers should cancel the Cancellable to prevent propagation of the event.
     * This will prevent the various "clicked" signals from firing.
     */
    public signal void released(Gtk.Widget widget, Gdk.EventButton event, Cancellable cancellable);
    
    /**
     * Fired when a button is pressed and released once.
     *
     * The "guaranteed" flag is important to distinguish here.  If set, that indicates a timeout
     * has occurred and the user did not follow the click with a second or third.  If not set,
     * this was fired immediately after the user released the button and it is unknown if the user
     * intends to follow it with more clicks.
     *
     * Because no timeout has occurred, unguaranteed clicks can be processed immediately if they
     * occur on a widget or location where double- and triple-clicks are meaningless.
     *
     * NOTE: This means "clicked" (and {@link double_clicked} and {@link triple_clicked} will be
     * fired ''twice'', once unguaranteed, once guaranteed.  To prevent double-processing, handlers
     * should always check the flag.
     */
    public signal void clicked(ButtonEvent details, bool guaranteed);
    
    /**
     * Fired when a button is pressed and released twice in succession.
     *
     * See {@link clicked} for an explanation of the {@link guaranteed} flag.
     */
    public signal void double_clicked(ButtonEvent details, bool guaranteed);
    
    /**
     * Fired when a button is pressed and released thrice in succession.
     *
     * See {@link clicked} for an explanation of the {@link guaranteed} flag.
     */
    public signal void triple_clicked(ButtonEvent details, bool guaranteed);
    
    /**
     * Create a new {@link ButtonConnector} for monitoring (mouse) button events from Gtk.Widgets.
     */
    public ButtonConnector() {
        base (Gdk.EventMask.BUTTON_PRESS_MASK | Gdk.EventMask.BUTTON_RELEASE_MASK);
    }
    
    /**
     * Subclasses may override this method to hook into this event before or after the signal
     * has fired.
     *
     * @return {@link EVENT_STOP} or {@link EVENT_PROPAGATE}.
     */
    protected virtual bool notify_pressed(Gtk.Widget widget, Gdk.EventButton event) {
        pressed(widget, event, cancellable);
        
        return stop_propagation();
    }
    
    /**
     * Subclasses may override this method to hook into this event before or after the signal
     * has fired.
     *
     * @return {@link EVENT_STOP} or {@link EVENT_PROPAGATE}.
     */
    protected virtual bool notify_released(Gtk.Widget widget, Gdk.EventButton event) {
        released(widget, event, cancellable);
        
        return stop_propagation();
    }
    
    /**
     * Subclasses may override this method to hook into this event before or after the signal
     * has fired.
     */
    protected virtual void notify_clicked(ButtonEvent details, bool guaranteed) {
        clicked(details, guaranteed);
    }
    
    /**
     * Subclasses may override this method to hook into this event before or after the signal
     * has fired.
     */
    protected virtual void notify_double_clicked(ButtonEvent details, bool guaranteed) {
        double_clicked(details, guaranteed);
    }
    
    /**
     * Subclasses may override this method to hook into this event before or after the signal
     * has fired.
     */
    protected virtual void notify_triple_clicked(ButtonEvent details, bool guaranteed) {
        triple_clicked(details, guaranteed);
    }
    
    protected override void connect_signals(Gtk.Widget widget) {
        // clear this, just in case something was lingering
        clear_widget(widget);
        
        widget.button_press_event.connect(on_button_event);
        widget.button_release_event.connect(on_button_event);
    }
    
    protected override void disconnect_signals(Gtk.Widget widget) {
        clear_widget(widget);
        
        widget.button_press_event.disconnect(on_button_event);
        widget.button_release_event.disconnect(on_button_event);
    }
    
    private void clear_widget(Gtk.Widget widget) {
        primary_states.unset(widget);
        secondary_states.unset(widget);
        tertiary_states.unset(widget);
    }
    
    // Checks if the Cancellable has been cancelled, in which case return EVENT_STOP and replaces
    // the Cancellable
    private bool stop_propagation() {
        if (!cancellable.is_cancelled())
            return EVENT_PROPAGATE;
        
        cancellable = new Cancellable();
        
        return EVENT_STOP;
    }
    
    private Gee.HashMap<Gtk.Widget, InternalButtonEvent>? get_states_map(Button button) {
        switch (button) {
            case Button.PRIMARY:
                return primary_states;
            
            case Button.SECONDARY:
                return secondary_states;
            
            case Button.TERTIARY:
                return tertiary_states;
            
            case Button.OTHER:
                return null;
            
            default:
                assert_not_reached();
        }
    }
    
    private bool on_button_event(Gtk.Widget widget, Gdk.EventButton event) {
        Button button = Button.from_event(event);
        
        return process_button_event(widget, event, button, get_states_map(button));
    }
    
    private bool process_button_event(Gtk.Widget widget, Gdk.EventButton event,
        Button button, Gee.HashMap<Gtk.Widget, InternalButtonEvent>? button_states) {
        switch(event.type) {
            case Gdk.EventType.BUTTON_PRESS:
            case Gdk.EventType.2BUTTON_PRESS:
            case Gdk.EventType.3BUTTON_PRESS:
                // notify of raw event
                if (notify_pressed(widget, event) == EVENT_STOP) {
                    // drop any lingering state
                    if (button_states != null)
                        button_states.unset(widget);
                    
                    return EVENT_STOP;
                }
                
                // save state for the release event, potentially updating existing state from
                // previous press (possible for multiple press events to arrive back-to-back
                // when double- and triple-clicking)
                if (button_states != null) {
                    InternalButtonEvent? details = button_states.get(widget);
                    if (details == null) {
                        details = new InternalButtonEvent(widget, event);
                        details.release_timeout.connect(on_release_timeout);
                        button_states.set(widget, details);
                    } else {
                        details.update_press(widget, event);
                    }
                }
            break;
            
            case Gdk.EventType.BUTTON_RELEASE:
                // notify of raw event
                if (notify_released(widget, event) == EVENT_STOP) {
                    // release lingering state
                    if (button_states != null)
                        button_states.unset(widget);
                    
                    return EVENT_STOP;
                }
                
                // update saved state (if any) with release info and start timer
                if (button_states != null) {
                    InternalButtonEvent? details = button_states.get(widget);
                    if (details != null) {
                        // fire "unguaranteed" clicked signals now (with button release) rather than
                        // wait for timeout using the current value of press_type before the details
                        // are updated
                        switch (details.press_type) {
                            case Gdk.EventType.BUTTON_PRESS:
                                notify_clicked(details, false);
                            break;
                            
                            case Gdk.EventType.2BUTTON_PRESS:
                                notify_double_clicked(details, false);
                            break;
                            
                            case Gdk.EventType.3BUTTON_PRESS:
                                notify_triple_clicked(details, false);
                            break;
                        }
                        
                        details.update_release(widget, event);
                    }
                }
            break;
        }
        
        return EVENT_PROPAGATE;
    }
    
    private void on_release_timeout(InternalButtonEvent details) {
        // release button timed-out, meaning it's time to evaluate where the sequence stands and
        // notify subscribers
        switch (details.press_type) {
            case Gdk.EventType.BUTTON_PRESS:
                notify_clicked(details, true);
            break;
            
            case Gdk.EventType.2BUTTON_PRESS:
                notify_double_clicked(details, true);
            break;
            
            case Gdk.EventType.3BUTTON_PRESS:
                notify_triple_clicked(details, true);
            break;
        }
        
        // drop state, now finished with it
        Gee.HashMap<Gtk.Widget, InternalButtonEvent>? states_map = get_states_map(details.button);
        if (states_map != null)
            states_map.unset(details.widget);
    }
}

}
