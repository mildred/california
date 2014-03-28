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
    
    private const string ACTION_NEW_EVENT = "win.new-event";
    private const string ACCEL_NEW_EVENT = "<Primary>n";
    
    private const string ACTION_JUMP_TO_TODAY = "win.jump-to-today";
    private const string ACCEL_JUMP_TO_TODAY = "<Primary>t";
    
    private const string ACTION_NEXT = "win.next";
    private const string ACCEL_NEXT = "<Alt>Right";
    
    private const string ACTION_PREVIOUS = "win.previous";
    private const string ACCEL_PREVIOUS = "<Alt>Left";
    
    private static const ActionEntry[] action_entries = {
        { "new-event", on_new_event },
        { "jump-to-today", on_jump_to_today },
        { "next", on_next },
        { "previous", on_previous }
    };
    
    // Set as a property so it can be bound to the current View.Controllable
    public Calendar.FirstOfWeek first_of_week { get; set; }
    
    private View.Controllable current_view;
    private View.Month.Controllable month_view = new View.Month.Controllable();
    
    public MainWindow(Application app) {
        Object (application: app);
        
        title = Application.TITLE;
        set_size_request(800, 600);
        set_default_size(1024, 768);
        set_default_icon_name(Application.ICON_NAME);
        
        bool rtl = get_direction() == Gtk.TextDirection.RTL;
        
        add_action_entries(action_entries, this);
        Application.instance.add_accelerator(ACCEL_NEW_EVENT, ACTION_NEW_EVENT, null);
        Application.instance.add_accelerator(ACCEL_JUMP_TO_TODAY, ACTION_JUMP_TO_TODAY, null);
        Application.instance.add_accelerator(rtl ? ACCEL_PREVIOUS : ACCEL_NEXT, ACTION_NEXT, null);
        Application.instance.add_accelerator(rtl ? ACCEL_NEXT : ACCEL_PREVIOUS, ACTION_PREVIOUS, null);
        
        // start in Month view
        current_view = month_view;
        
        // create GtkHeaderBar and pack it in
        Gtk.HeaderBar headerbar = new Gtk.HeaderBar();
#if !ENABLE_UNITY
        // Unity doesn't support GtkHeaderBar-as-title-bar very well yet; when set, the main
        // window can't be resized no matter what additional GtkWindow properties are set
        headerbar.show_close_button = true;
        set_titlebar(headerbar);
#endif
        
        Gtk.Button today = new Gtk.Button.with_label(_("_Today"));
        today.use_underline = true;
        today.tooltip_text = _("Jump to today's date (Ctrl+T)");
        today.set_action_name(ACTION_JUMP_TO_TODAY);
        
        Gtk.Button prev = new Gtk.Button.from_icon_name(rtl ? "go-previous-rtl-symbolic" : "go-previous-symbolic",
            Gtk.IconSize.MENU);
        prev.tooltip_text = _("Previous (Alt+Left)");
        prev.set_action_name(ACTION_PREVIOUS);
        
        Gtk.Button next = new Gtk.Button.from_icon_name(rtl ? "go-next-rtl-symbolic" : "go-next-symbolic",
            Gtk.IconSize.MENU);
        next.tooltip_text = _("Next (Alt+Right)");
        next.set_action_name(ACTION_NEXT);
        
        Gtk.Box nav_buttons = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        nav_buttons.get_style_context().add_class(Gtk.STYLE_CLASS_LINKED);
        nav_buttons.get_style_context().add_class(Gtk.STYLE_CLASS_RAISED);
        nav_buttons.pack_start(prev);
        nav_buttons.pack_end(next);
        
        // pack left-side of window
        headerbar.pack_start(today);
        headerbar.pack_start(nav_buttons);
        
        Gtk.Button new_event = new Gtk.Button.from_icon_name("list-add-symbolic", Gtk.IconSize.MENU);
        new_event.tooltip_text = _("Create a new event (Ctrl+N)");
        new_event.set_action_name(ACTION_NEW_EVENT);
        
        Gtk.Button calendars = new Gtk.Button.from_icon_name("x-office-calendar-symbolic",
            Gtk.IconSize.MENU);
        calendars.tooltip_text = _("Calendars (Ctrl+L)");
        calendars.set_action_name(Application.ACTION_CALENDAR_MANAGER);
        
        // pack right-side of window
        headerbar.pack_end(new_event);
        headerbar.pack_end(calendars);
        
        Gtk.Box layout = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
#if ENABLE_UNITY
        layout.pack_start(headerbar, false, true, 0);
#endif
        layout.pack_end(month_view, true, true, 0);
        
        // current host bindings and signals
        current_view.request_create_timed_event.connect(on_request_create_timed_event);
        current_view.request_create_all_day_event.connect(on_request_create_all_day_event);
        current_view.request_display_event.connect(on_request_display_event);
        current_view.bind_property(View.Controllable.PROP_CURRENT_LABEL, headerbar, "title",
            BindingFlags.SYNC_CREATE);
        current_view.bind_property(View.Controllable.PROP_IS_VIEWING_TODAY, today, "sensitive",
            BindingFlags.SYNC_CREATE | BindingFlags.INVERT_BOOLEAN);
        current_view.bind_property(View.Controllable.PROP_FIRST_OF_WEEK, this, PROP_FIRST_OF_WEEK,
            BindingFlags.BIDIRECTIONAL);
        
        add(layout);
    }
    
    private void show_interaction(Gtk.Widget relative_to, Gdk.Point? for_location,
        Interaction child) {
        ModalWindow modal_window = new ModalWindow(this);
        modal_window.content_area.add(child);
        
        // when the dialog closes, reset View.Controllable state (selection is maintained while
        // use is viewing/editing Interaction) and destroy widgets
        child.dismissed.connect(() => current_view.unselect_all());
        
        modal_window.show_all();
        modal_window.run();
        modal_window.destroy();
    }
    
    private void on_new_event() {
        // create all-day event for today
        Calendar.DateSpan initial = new Calendar.DateSpan(Calendar.System.today, Calendar.System.today);
        
        // revert to today's date and use the widget for the popover
        create_event(null, initial, null, current_view.today(), null);
    }
    
    private void on_jump_to_today() {
        current_view.today();
    }
    
    private void on_next() {
        current_view.next();
    }
    
    private void on_previous() {
        current_view.prev();
    }
    
    private void on_request_create_timed_event(Calendar.ExactTimeSpan initial, Gtk.Widget relative_to,
        Gdk.Point? for_location) {
        create_event(initial, null, null, relative_to, for_location);
    }
    
    private void on_request_create_all_day_event(Calendar.DateSpan initial, Gtk.Widget relative_to,
        Gdk.Point? for_location) {
        create_event(null, initial, null, relative_to, for_location);
    }
    
    private void create_event(Calendar.ExactTimeSpan? time_span, Calendar.DateSpan? date_span,
        Component.Event? existing, Gtk.Widget relative_to, Gdk.Point? for_location) {
        assert(time_span != null || date_span != null || existing != null);
        
        CreateUpdateEvent create_update_event;
        if (time_span != null)
            create_update_event = new CreateUpdateEvent(time_span);
        else if (date_span != null)
            create_update_event = new CreateUpdateEvent.all_day(date_span);
        else
            create_update_event = new CreateUpdateEvent.update(existing);
        
        create_update_event.create_event.connect((event) => {
            create_event_async.begin(event, null);
        });
        
        create_update_event.update_event.connect((original_source, event) => {
            // TODO: Delete from original source if not the same as the new source
            update_event_async.begin(event, null);
        });
        
        show_interaction(relative_to, for_location, create_update_event);
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
    
    private async void update_event_async(Component.Event event, Cancellable? cancellable) {
        if (event.calendar_source == null)
            return;
        
        try {
            yield event.calendar_source.update_component_async(event, cancellable);
        } catch (Error err) {
            debug("Unable to update event: %s", err.message);
        }
    }
    
    private void on_request_display_event(Component.Event event, Gtk.Widget relative_to,
        Gdk.Point? for_location) {
        ShowEvent show_event = new ShowEvent(event);
        
        show_event.remove_event.connect(() => {
            remove_event_async.begin(event, null);
        });
        
        show_event.update_event.connect(() => {
            create_event(null, null, event, relative_to, for_location);
        });
        
        show_interaction(relative_to, for_location, show_event);
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

