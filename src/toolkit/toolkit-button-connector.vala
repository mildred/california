/* Copyright 2014-2015 Yorba Foundation
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
    private Gee.HashMap<Gtk.Widget, ButtonEvent> primary_states = new Gee.HashMap<
        Gtk.Widget, ButtonEvent>();
    private Gee.HashMap<Gtk.Widget, ButtonEvent> secondary_states = new Gee.HashMap<
        Gtk.Widget, ButtonEvent>();
    private Gee.HashMap<Gtk.Widget, ButtonEvent> tertiary_states = new Gee.HashMap<
        Gtk.Widget, ButtonEvent>();
    
    /**
     * The "raw" "button-pressed" signal received by {@link ButtonConnector}.
     *
     * Return {@link STOP} to prevent further propagation of the event.  This will prevent firing
     * of synthesized signals, i.e. {@link clicked} and {@link double_clicked}.
     */
    public signal bool pressed(Gtk.Widget widget, Button button, Gdk.Point point, Gdk.EventType event_type);
    
    /**
     * The "raw" "button-released" signal received by {@link ButtonConnector}.
     *
     * Return {@link STOP} to prevent further propagation of the event.  This will prevent firing
     * of synthesized signals, i.e. {@link clicked} and {@link double_clicked}.
     */
    public signal bool released(Gtk.Widget widget, Button button, Gdk.Point point, Gdk.EventType event_type);
    
    /**
     * Fired when a button is pressed and released once.
     *
     * Note that this can be fired after {@link double_clicked} and {@link triple_clicked}.  That
     * indicates that the user double- or triple-clicked ''and'' the other signal handlers did not
     * return {@link Toolkit.STOP}, indicating the event was unhandled or unabsorbed by the signal
     * handlers.  If either returns STOP, "clicked" will not fire.
     */
    public signal bool clicked(ButtonEvent details);
    
    /**
     * Fired when a button is pressed and released twice in succession.
     *
     * See {@link clicked} for an explanation of signal firing order.
     */
    public signal bool double_clicked(ButtonEvent details);
    
    /**
     * Fired when a button is pressed and released thrice in succession.
     *
     * See {@link clicked} for an explanation of signal firing order.
     */
    public signal bool triple_clicked(ButtonEvent details);
    
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
     * @return {@link STOP} or {@link PROPAGATE}.
     */
    protected virtual bool notify_pressed(Gtk.Widget widget, Button button, Gdk.Point point,
        Gdk.EventType event_type) {
        return pressed(widget, button, point, event_type);
    }
    
    /**
     * Subclasses may override this method to hook into this event before or after the signal
     * has fired.
     *
     * @return {@link STOP} or {@link PROPAGATE}.
     */
    protected virtual bool notify_released(Gtk.Widget widget, Button button, Gdk.Point point,
        Gdk.EventType event_type) {
        return released(widget, button, point, event_type);
    }
    
    /**
     * Subclasses may override this method to hook into this event before or after the signal
     * has fired.
     */
    protected virtual bool notify_clicked(ButtonEvent details) {
        return clicked(details);
    }
    
    /**
     * Subclasses may override this method to hook into this event before or after the signal
     * has fired.
     */
    protected virtual bool notify_double_clicked(ButtonEvent details) {
        return double_clicked(details);
    }
    
    /**
     * Subclasses may override this method to hook into this event before or after the signal
     * has fired.
     */
    protected virtual bool notify_triple_clicked(ButtonEvent details) {
        return triple_clicked(details);
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
    
    private Gee.HashMap<Gtk.Widget, ButtonEvent>? get_states_map(Button button) {
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
        Button button = Button.from_button_event(event);
        
        return process_button_event(widget, event, button, get_states_map(button));
    }
    
    private bool process_button_event(Gtk.Widget widget, Gdk.EventButton event,
        Button button, Gee.HashMap<Gtk.Widget, ButtonEvent>? button_states) {
        switch(event.type) {
            case Gdk.EventType.BUTTON_PRESS:
            case Gdk.EventType.2BUTTON_PRESS:
            case Gdk.EventType.3BUTTON_PRESS:
                // notify of raw event
                Gdk.Point point = Gdk.Point() { x = (int) event.x, y = (int) event.y };
                if (notify_pressed(widget, button, point, event.type) == Toolkit.STOP) {
                    // drop any lingering state
                    if (button_states != null)
                        button_states.unset(widget);
                    
                    return Toolkit.STOP;
                }
                
                // save state for the release event, potentially updating existing state from
                // previous press (possible for multiple press events to arrive back-to-back
                // when double- and triple-clicking)
                if (button_states != null) {
                    ButtonEvent? details = button_states.get(widget);
                    if (details == null) {
                        details = new ButtonEvent(widget, event);
                        details.clicked.connect(synthesize_click);
                        
                        button_states.set(widget, details);
                    } else {
                        details.update_press(widget, event);
                    }
                }
            break;
            
            case Gdk.EventType.BUTTON_RELEASE:
                // notify of raw event
                Gdk.Point point = Gdk.Point() { x = (int) event.x, y = (int) event.y };
                if (notify_released(widget, button, point, event.type) == Toolkit.STOP) {
                    // release lingering state
                    if (button_states != null)
                        button_states.unset(widget);
                    
                    return Toolkit.STOP;
                }
                
                // update saved state (if any) with release info and synthesize click
                if (button_states != null) {
                    ButtonEvent? details = button_states.get(widget);
                    if (details != null)
                        details.update_release(widget, event);
                }
            break;
        }
        
        return Toolkit.PROPAGATE;
    }
    
    private void synthesize_click(ButtonEvent details) {
        bool result = Toolkit.PROPAGATE;
        switch (details.press_type) {
            case Gdk.EventType.BUTTON_PRESS:
                result = notify_clicked(details);
            break;
            
            case Gdk.EventType.2BUTTON_PRESS:
                result = notify_double_clicked(details);
                if (result != Toolkit.STOP)
                    result = notify_clicked(details);
            break;
            
            case Gdk.EventType.3BUTTON_PRESS:
                result = notify_triple_clicked(details);
                if (result != Toolkit.STOP) {
                    result = notify_double_clicked(details);
                    if (result != Toolkit.STOP)
                        result = notify_clicked(details);
                }
            break;
        }
        
        // drop event details if done here or if end-of-the-road click-wise
        if (result == Toolkit.STOP || details.press_type == Gdk.EventType.3BUTTON_PRESS) {
            Gee.HashMap<Gtk.Widget, ButtonEvent>? states_map = get_states_map(details.button);
            if (states_map != null)
                states_map.unset(details.widget);
        }
    }
}

}

