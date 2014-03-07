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
        
        // start in Month view
        current_view = month_view;
        
        // create GtkHeaderBar and pack it in
        Gtk.HeaderBar headerbar = new Gtk.HeaderBar();
        
        Gtk.Button today = new Gtk.Button.with_label(_("Today"));
        today.clicked.connect(() => { current_view.today(); });
        
        Gtk.Button prev = new Gtk.Button.from_icon_name("go-previous-symbolic", Gtk.IconSize.MENU);
        prev.clicked.connect(() => { current_view.prev(); });
        
        Gtk.Button next = new Gtk.Button.from_icon_name("go-next-symbolic", Gtk.IconSize.MENU);
        next.clicked.connect(() => { current_view.next(); });
        
        Gtk.Box nav_buttons = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        nav_buttons.get_style_context().add_class(Gtk.STYLE_CLASS_LINKED);
        nav_buttons.get_style_context().add_class(Gtk.STYLE_CLASS_RAISED);
        nav_buttons.pack_start(prev);
        nav_buttons.pack_end(next);
        
        // pack left-side of window
        headerbar.pack_start(today);
        headerbar.pack_start(nav_buttons);
        
        Gtk.Button new_event = new Gtk.Button.from_icon_name("list-add-symbolic", Gtk.IconSize.MENU);
        new_event.tooltip_text = _("Create a new event for today");
        new_event.clicked.connect(on_new_event);
        
        // pack right-side of window
        headerbar.pack_end(new_event);
        
        Gtk.Box layout = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        layout.pack_start(headerbar, false, true, 0);
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
    
    private Gtk.Widget show_interaction(Gtk.Widget relative_to, Gdk.Point? for_location,
        Gtk.Widget child) {
        Gtk.Dialog dialog = new Gtk.Dialog();
        dialog.transient_for = this;
        dialog.modal = true;
        ((Gtk.Box) dialog.get_content_area()).pack_start(child, true, true, 0);
        
        dialog.close.connect(on_interaction_dismissed);
        
        dialog.show_all();
        
        return dialog;
    }
    
    private void on_interaction_dismissed() {
        // reset View.Controllable state whenever the interaction is dismissed
        current_view.unselect_all();
    }
    
    private void on_new_event() {
        // create all-day event for today
        Calendar.DateSpan initial = new Calendar.DateSpan(Calendar.System.today, Calendar.System.today);
        
        // revert to today's date and use the widget for the popover
        create_event(null, initial, null, current_view.today(), null);
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
        
        Gtk.Widget interaction = show_interaction(relative_to, for_location, create_update_event);
        
        create_update_event.create_event.connect((event) => {
            interaction.destroy();
            create_event_async.begin(event, null);
        });
        
        create_update_event.update_event.connect((original_source, event) => {
            interaction.destroy();
            // TODO: Delete from original source if not the same as the new source
            update_event_async.begin(event, null);
        });
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
        Gtk.Widget interaction = show_interaction(relative_to, for_location, show_event);
        
        show_event.remove_event.connect(() => {
            interaction.destroy();
            remove_event_async.begin(event, null);
        });
        
        show_event.update_event.connect(() => {
            interaction.destroy();
            create_event(null, null, event, relative_to, for_location);
        });
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

