/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Host {

/**
 * Primary application window.
 */

public class MainWindow : Gtk.ApplicationWindow {
    private const string PROP_FIRST_OF_WEEK = "first-of-week";
    
    private const string ACTION_QUICK_CREATE_EVENT = "win.quick-create-event";
    private const string ACCEL_QUICK_CREATE_EVENT = "<Primary>n";
    
    private const string ACTION_JUMP_TO_TODAY = "win.jump-to-today";
    private const string ACCEL_JUMP_TO_TODAY = "<Primary>t";
    
    private const string ACTION_NEXT = "win.next";
    private const string ACCEL_NEXT = "<Alt>Right";
    
    private const string ACTION_PREVIOUS = "win.previous";
    private const string ACCEL_PREVIOUS = "<Alt>Left";
    
    private const string ACTION_MONTH = "win.view-month";
    private const string ACCEL_MONTH = "<Ctrl>M";
    
    private const string ACTION_WEEK = "win.view-week";
    private const string ACCEL_WEEK = "<Ctrl>W";
    
    private static const ActionEntry[] action_entries = {
        { "quick-create-event", on_quick_create_event },
        { "jump-to-today", on_jump_to_today },
        { "next", on_next },
        { "previous", on_previous },
        { "view-month", on_view_month },
        { "view-week", on_view_week }
    };
    
    // Set as a property so it can be bound to the current View.Controllable
    public Calendar.FirstOfWeek first_of_week { get; set; }
    
    private Gtk.Button quick_add_button;
    private View.Controllable month_view = new View.Month.Controller();
    private View.Controllable week_view = new View.Week.Controller();
    private View.Controllable? current_controller = null;
    private Gee.HashSet<Binding> current_bindings = new Gee.HashSet<Binding>();
    private Gtk.Stack view_stack = new Gtk.Stack();
    private Gtk.HeaderBar headerbar = new Gtk.HeaderBar();
    private Gtk.Button today = new Gtk.Button.with_label(_("_Today"));
    
    public MainWindow(Application app) {
        Object (application: app);
        
        title = Application.TITLE;
        set_size_request(800, 600);
        set_default_size(1024, 768);
        set_default_icon_name(Application.ICON_NAME);
        
        bool rtl = get_direction() == Gtk.TextDirection.RTL;
        
        add_action_entries(action_entries, this);
        Application.instance.add_accelerator(ACCEL_QUICK_CREATE_EVENT, ACTION_QUICK_CREATE_EVENT, null);
        Application.instance.add_accelerator(ACCEL_JUMP_TO_TODAY, ACTION_JUMP_TO_TODAY, null);
        Application.instance.add_accelerator(rtl ? ACCEL_PREVIOUS : ACCEL_NEXT, ACTION_NEXT, null);
        Application.instance.add_accelerator(rtl ? ACCEL_NEXT : ACCEL_PREVIOUS, ACTION_PREVIOUS, null);
        Application.instance.add_accelerator(ACCEL_MONTH, ACTION_MONTH, null);
        Application.instance.add_accelerator(ACCEL_WEEK, ACTION_WEEK, null);
        
        // view stack settings
        view_stack.homogeneous = true;
        view_stack.transition_duration = Toolkit.DEFAULT_STACK_TRANSITION_DURATION_MSEC;
        view_stack.transition_type = Gtk.StackTransitionType.SLIDE_UP_DOWN;
        
        // subscribe before adding so first add to initialize UI
        view_stack.notify["visible-child"].connect(on_view_changed);
        
        // add views to view stack, first added is first shown
        add_controller(month_view);
        add_controller(week_view);
        
        // if not on Unity, use headerbar as the titlebar (removes window chrome) and provide close
        // button for users who might have trouble finding it otherwise
#if !ENABLE_UNITY
        // Unity doesn't support GtkHeaderBar-as-title-bar very well yet; when set, the main
        // window can't be resized no matter what additional GtkWindow properties are set
        headerbar.show_close_button = true;
        set_titlebar(headerbar);
#endif
        
        today.valign = Gtk.Align.CENTER;
        today.use_underline = true;
        today.tooltip_text = _("Jump to today's date (Ctrl+T)");
        today.set_action_name(ACTION_JUMP_TO_TODAY);
        
        Gtk.Button prev = new Gtk.Button.from_icon_name(rtl ? "go-previous-rtl-symbolic" : "go-previous-symbolic",
            Gtk.IconSize.MENU);
        prev.valign = Gtk.Align.CENTER;
        prev.tooltip_text = _("Previous (Alt+Left)");
        prev.set_action_name(ACTION_PREVIOUS);
        
        Gtk.Button next = new Gtk.Button.from_icon_name(rtl ? "go-next-rtl-symbolic" : "go-next-symbolic",
            Gtk.IconSize.MENU);
        next.valign = Gtk.Align.CENTER;
        next.tooltip_text = _("Next (Alt+Right)");
        next.set_action_name(ACTION_NEXT);
        
        Gtk.Box nav_buttons = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        nav_buttons.get_style_context().add_class(Gtk.STYLE_CLASS_LINKED);
        nav_buttons.get_style_context().add_class(Gtk.STYLE_CLASS_RAISED);
        nav_buttons.pack_start(prev);
        nav_buttons.pack_end(next);
        
        // TODO:
        // Remove Gtk.StackSwitcher for a few reasons: (a) the buttons are kinda wide and
        // would like to conserve header bar space; (b) want to add tooltips to buttons; and (c)
        // want to move to icons at some point
        Gtk.StackSwitcher view_switcher = new Gtk.StackSwitcher();
        view_switcher.stack = view_stack;
        view_switcher.get_style_context().add_class(Gtk.STYLE_CLASS_LINKED);
        view_switcher.get_style_context().add_class(Gtk.STYLE_CLASS_RAISED);
        
        // pack left-side of window
        headerbar.pack_start(today);
        headerbar.pack_start(nav_buttons);
        headerbar.pack_start(view_switcher);
        
        quick_add_button = new Gtk.Button.from_icon_name("list-add-symbolic", Gtk.IconSize.MENU);
        quick_add_button.valign = Gtk.Align.CENTER;
        quick_add_button.tooltip_text = _("Quick add event (Ctrl+N)");
        quick_add_button.set_action_name(ACTION_QUICK_CREATE_EVENT);
        
        Gtk.Button calendars = new Gtk.Button.from_icon_name("x-office-calendar-symbolic",
            Gtk.IconSize.MENU);
        calendars.valign = Gtk.Align.CENTER;
        calendars.tooltip_text = _("Calendars (Ctrl+L)");
        calendars.set_action_name(Application.ACTION_CALENDAR_MANAGER);

        // Vertically center all buttons and put them in a SizeGroup to handle situations where
        // the text button is smaller than the icons buttons due to language (i.e. Hebrew)
        // see https://bugzilla.gnome.org/show_bug.cgi?id=729771
        Gtk.SizeGroup size = new Gtk.SizeGroup(Gtk.SizeGroupMode.VERTICAL);
        size.add_widget(today);
        size.add_widget(prev);
        size.add_widget(next);
        size.add_widget(quick_add_button);
        size.add_widget(calendars);
        
        // pack right-side of window
        headerbar.pack_end(quick_add_button);
        headerbar.pack_end(calendars);
        
        Gtk.Box layout = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        // if on Unity, since headerbar is not the titlebar, need to pack it like any other widget
#if ENABLE_UNITY
        layout.pack_start(headerbar, false, true, 0);
#endif
        layout.pack_end(view_stack, true, true, 0);
        
        add(layout);
    }
    
    public override void map() {
        // give View.Palette a chance to gather display metrics for the various Views (week, months,
        // etc.)
        View.Palette.instance.main_window_mapped(this);
        
        base.map();
    }
    
    private void add_controller(View.Controllable controller) {
        view_stack.add_titled(controller.get_container(), controller.title, controller.title);
        controller.get_container().show_all();
    }
    
    private unowned View.Container? current_view_container() {
        return (View.Container?) view_stack.get_visible_child();
    }
    
    private void on_view_changed() {
        View.Container? view_container = current_view_container();
        if (view_container != null && view_container.owner == current_controller)
            return;
        
        if (current_controller != null) {
            // signals
            current_controller.request_create_timed_event.disconnect(on_request_create_timed_event);
            current_controller.request_create_all_day_event.disconnect(on_request_create_all_day_event);
            current_controller.request_display_event.disconnect(on_request_display_event);
            
            // clear bindings to unbind all of them
            current_bindings.clear();
        }
        
        if (view_container != null) {
            current_controller = view_container.owner;
            
            // signals
            current_controller.request_create_timed_event.connect(on_request_create_timed_event);
            current_controller.request_create_all_day_event.connect(on_request_create_all_day_event);
            current_controller.request_display_event.connect(on_request_display_event);
            
            // bindings
            Binding binding = current_controller.bind_property(View.Controllable.PROP_CURRENT_LABEL,
                headerbar, "title", BindingFlags.SYNC_CREATE);
            current_bindings.add(binding);
            
            binding = current_controller.bind_property(View.Controllable.PROP_IS_VIEWING_TODAY, today,
                "sensitive", BindingFlags.SYNC_CREATE | BindingFlags.INVERT_BOOLEAN);
            current_bindings.add(binding);
            
            binding = current_controller.bind_property(View.Controllable.PROP_FIRST_OF_WEEK, this,
                PROP_FIRST_OF_WEEK, BindingFlags.BIDIRECTIONAL);
            current_bindings.add(binding);
        }
    }
    
    private void show_deck(Gtk.Widget relative_to, Gdk.Point? for_location, Toolkit.Deck deck) {
        Toolkit.DeckWindow deck_window = new Toolkit.DeckWindow(this, deck);
        
        // when the dialog closes, reset View.Controllable state (selection is maintained while
        // use is viewing/editing interaction) and destroy widgets
        deck_window.deck.dismiss.connect(() => {
            current_controller.unselect_all();
            deck_window.hide();
            // give the dialog a change to hide before allowing other signals to fire, which may
            // invoke another dialog (prevents multiple dialogs on screen at same time)
            Toolkit.spin_event_loop();
        });
        
        deck_window.show_all();
        deck_window.run();
        deck_window.destroy();
    }
    
    private void on_quick_create_event() {
        QuickCreateEvent quick_create = new QuickCreateEvent();
        
        quick_create.success.connect(() => {
            if (quick_create.parsed_event == null)
                return;
            
            if (quick_create.parsed_event.is_valid())
                create_event_async.begin(quick_create.parsed_event, null);
            else
                create_event(quick_create.parsed_event, quick_add_button, null);
        });
        
        Toolkit.Deck deck = new Toolkit.Deck();
        deck.add_cards(iterate<Toolkit.Card>(quick_create).to_array_list());
        
        show_deck(quick_add_button, null, deck);
    }
    
    private void on_jump_to_today() {
        current_controller.today();
    }
    
    private void on_next() {
        current_controller.next();
    }
    
    private void on_previous() {
        current_controller.previous();
    }
    
    private void on_view_month() {
        view_stack.set_visible_child(month_view.get_container());
    }
    
    private void on_view_week() {
        view_stack.set_visible_child(week_view.get_container());
    }
    
    private void on_request_create_timed_event(Calendar.ExactTimeSpan initial, Gtk.Widget relative_to,
        Gdk.Point? for_location) {
        Component.Event event = new Component.Event.blank();
        event.set_event_exact_time_span(initial);
        
        create_event(event, relative_to, for_location);
    }
    
    private void on_request_create_all_day_event(Calendar.Span initial, Gtk.Widget relative_to,
        Gdk.Point? for_location) {
        Component.Event event = new Component.Event.blank();
        event.set_event_date_span(initial.to_date_span());
        
        create_event(event, relative_to, for_location);
    }
    
    private void create_event(Component.Event event, Gtk.Widget relative_to, Gdk.Point? for_location) {
        CreateUpdateEvent create_update_event = new CreateUpdateEvent();
        create_update_event.is_update = false;
        
        Toolkit.Deck deck = new Toolkit.Deck();
        deck.add_cards(iterate<Toolkit.Card>(create_update_event).to_array_list());
        deck.go_home(event);
        
        show_deck(relative_to, for_location, deck);
    }
    
    private async void create_event_async(Component.Event event, Cancellable? cancellable) {
        if (event.calendar_source == null)
            return;
        
        try {
            yield event.calendar_source.create_component_async(event, cancellable);
        } catch (Error err) {
            debug("Unable to create event: %s", err.message);
        }
    }
    
    private void on_request_display_event(Component.Event event, Gtk.Widget relative_to,
        Gdk.Point? for_location) {
        ShowEvent show_event = new ShowEvent();
        show_event.remove_event.connect(() => {
            remove_event_async.begin(event, null);
        });
        
        CreateUpdateEvent create_update_event = new CreateUpdateEvent();
        create_update_event.is_update = true;
        
        Toolkit.Deck deck = new Toolkit.Deck();
        deck.add_card(show_event);
        deck.add_card(create_update_event);
        deck.go_home(event);
        
        show_deck(relative_to, for_location, deck);
    }
    
    private async void remove_event_async(Component.Event event, Cancellable? cancellable) {
        try {
            yield event.calendar_source.remove_component_async(event.uid, cancellable);
        } catch (Error err) {
            debug("Unable to destroy event: %s", err.message);
        }
    }
}

}

