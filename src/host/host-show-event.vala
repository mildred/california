/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Host {

/**
 * MESSAGE IN: Send the Component.Event to be displayed.
 */

[GtkTemplate (ui = "/org/yorba/california/rc/show-event.ui")]
public class ShowEvent : Gtk.Grid, Toolkit.Card {
    public const string ID = "ShowEvent";
    
    private const string FAMILY_NORMAL = "normal";
    private const string FAMILY_REMOVING = "removing";
    
    public string card_id { get { return ID; } }
    
    public string? title { get { return null; } }
    
    public Gtk.Widget? default_widget { get { return null; } }
    
    public Gtk.Widget? initial_focus { get { return null; } }
    
    public bool edit_requested { get; private set; default = false; }
    
    [GtkChild]
    private Gtk.Label summary_text;
    
    [GtkChild]
    private Gtk.Label when_label;
    
    [GtkChild]
    private Gtk.Label when_text;
    
    [GtkChild]
    private Gtk.Label where_label;
    
    [GtkChild]
    private Gtk.Label where_text;
    
    [GtkChild]
    private Gtk.Label calendar_label;
    
    [GtkChild]
    private Gtk.Label calendar_text;
    
    [GtkChild]
    private Gtk.ScrolledWindow description_text_window;
    
    [GtkChild]
    private Gtk.Label description_text;
    
    [GtkChild]
    private Gtk.Box rotating_button_box_container;
    
    private new Component.Event event;
    
    private Toolkit.RotatingButtonBox rotating_button_box = new Toolkit.RotatingButtonBox();
    
    private Gtk.Box action_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 2);
    private Gtk.Button update_button = new Gtk.Button.from_icon_name("edit-symbolic",
        Gtk.IconSize.BUTTON);
    private Gtk.Button remove_button = new Gtk.Button.from_icon_name("user-trash-symbolic",
        Gtk.IconSize.BUTTON);
    
    private Gtk.Label delete_label = new Gtk.Label(_("Delete"));
    private Gtk.Button remove_all_button = new Gtk.Button.with_mnemonic(_("A_ll Events"));
    private Gtk.Button remove_this_button = new Gtk.Button.with_mnemonic(_("_This Event"));
    private Gtk.Button remove_this_future_button = new Gtk.Button.with_mnemonic(
        _("This & _Future Events"));
    private Gtk.Button cancel_remove_button = new Gtk.Button.with_mnemonic(_("_Cancel"));
    
    public ShowEvent() {
        Calendar.System.instance.is_24hr_changed.connect(build_display);
        Calendar.System.instance.today_changed.connect(build_display);
        
        update_button.tooltip_text = _("Edit event");
        remove_button.tooltip_text = _("Delete event");
        update_button.relief = remove_button.relief = Gtk.ReliefStyle.NONE;
        
        action_box.pack_end(update_button, false, false);
        action_box.pack_end(remove_button, false, false);
        
        remove_this_button.get_style_context().add_class("destructive-action");
        remove_this_future_button.get_style_context().add_class("destructive-action");
        remove_all_button.get_style_context().add_class("destructive-action");
        
        update_button.clicked.connect(on_update_button_clicked);
        remove_button.clicked.connect(on_remove_button_clicked);
        remove_all_button.clicked.connect(on_remove_all_button_clicked);
        remove_this_button.clicked.connect(on_remove_this_button_clicked);
        remove_this_future_button.clicked.connect(on_remove_future_button_clicked);
        cancel_remove_button.clicked.connect(on_cancel_remove_recurring_button_clicked);
        
        rotating_button_box.pack_end(FAMILY_NORMAL, action_box, false, true);
        
        delete_label.xalign = 1.0f;
        delete_label.get_style_context().add_class(Gtk.STYLE_CLASS_DIM_LABEL);
        rotating_button_box.pack_start(FAMILY_REMOVING, delete_label);
        rotating_button_box.pack_end(FAMILY_REMOVING, remove_this_button);
        rotating_button_box.pack_end(FAMILY_REMOVING, remove_this_future_button);
        rotating_button_box.pack_end(FAMILY_REMOVING, remove_all_button);
        rotating_button_box.pack_end(FAMILY_REMOVING, cancel_remove_button);
        
        rotating_button_box.get_family_container(FAMILY_REMOVING).homogeneous = false;
        
        rotating_button_box.vexpand = true;
        rotating_button_box.valign = Gtk.Align.END;
        rotating_button_box_container.add(rotating_button_box);
    }
    
    ~ShowEvent() {
        Calendar.System.instance.is_24hr_changed.disconnect(build_display);
        Calendar.System.instance.today_changed.disconnect(build_display);
    }
    
#if ENABLE_UNITY
    // When description_text_window is visible, the entire GtkGrid's background color goes black
    // in the GtkPopover; this overrides the color and uses GtkPopover's background color for the
    // GtkGrid.  See:
    // https://bugzilla.gnome.org/show_bug.cgi?id=735421
    public override void realize() {
        base.realize();
        
        Gdk.RGBA bg = get_toplevel().get_style_context().get_background_color(Gtk.StateFlags.NORMAL);
        override_background_color(Gtk.StateFlags.NORMAL, bg);
    }
#endif
    
    public void jumped_to(Toolkit.Card? from, Toolkit.Card.Jump reason, Value? message) {
        // no message, don't update display
        if (message == null)
            return;
        
        event = message as Component.Event;
        assert(event != null);
        
        description_text.bind_property("visible", description_text_window, "visible",
            BindingFlags.SYNC_CREATE);
        description_text.bind_property("no-show-all", description_text_window, "no-show-all",
            BindingFlags.SYNC_CREATE);
        
        rotating_button_box.show_hide_family(FAMILY_REMOVING, event.is_generated_instance);
        
        build_display();
    }
    
    private void build_display() {
        // summary
        set_label(null, summary_text, event.summary);
        
        // location
        set_label(where_label, where_text, event.location);
        
        // time
        set_label(when_label, when_text, event.get_event_time_pretty_string(Calendar.Date.PrettyFlag.NONE,
            Calendar.ExactTimeSpan.PrettyFlag.NONE, Calendar.Timezone.local));
        
        // calendar
        set_label(calendar_label, calendar_text, event.calendar_source != null ? event.calendar_source.title : null);
        
        // description
        set_label(null, description_text, Markup.linkify(escape(event.description), linkify_delegate));
        
        // if read-only, don't show Delete or Edit buttons; since they're the only two, don't show
        // the entire button box
        bool read_only = event.calendar_source != null && event.calendar_source.read_only;
        rotating_button_box.visible = !read_only;
        rotating_button_box.no_show_all = read_only;
    }
    
    private string? escape(string? plain) {
        return !String.is_empty(plain) ? GLib.Markup.escape_text(plain) : plain;
    }
    
    private bool linkify_delegate(string uri, bool known_protocol, out string? pre_markup,
        out string? post_markup) {
        // preserve but don't linkify if unknown protocol
        if (!known_protocol) {
            pre_markup = null;
            post_markup = null;
            
            return true;
        }
        
        // anchor it
        pre_markup = "<a href=\"%s\">".printf(uri);
        post_markup = "</a>";
        
        return true;
    }
    
    // Note that text is not escaped, up to caller to determine if necessary or not.
    private void set_label(Gtk.Label? label, Gtk.Label text, string? str) {
        if (!String.is_empty(str)) {
            text.label = str;
        } else {
            text.visible = false;
            text.no_show_all = true;
            
            // hide its associated label as well
            if (label != null) {
                label.visible = false;
                label.no_show_all = true;
            }
        }
    }
    
    private void on_remove_button_clicked() {
        // If recurring (and so this is a generated instance of the VEVENT, not the VEVENT itself),
        // reveal additional remove buttons
        if (event.is_generated_instance) {
            rotating_button_box.family = FAMILY_REMOVING;
            
            return;
        }
        
        remove_events_async.begin(null, Backing.CalendarSource.AffectedInstances.ALL);
    }
    
    private void on_cancel_remove_recurring_button_clicked() {
        rotating_button_box.family = FAMILY_NORMAL;
    }
    
    private void on_remove_this_button_clicked() {
        remove_events_async.begin(event.rid, Backing.CalendarSource.AffectedInstances.THIS);
    }
    
    private void on_remove_future_button_clicked() {
        remove_events_async.begin(event.rid, Backing.CalendarSource.AffectedInstances.THIS_AND_FUTURE);
    }
    
    private void on_remove_all_button_clicked() {
        remove_events_async.begin(null, Backing.CalendarSource.AffectedInstances.ALL);
    }
    
    private void on_update_button_clicked() {
        edit_requested = true;
        
        notify_user_closed();
    }
    
    private async void remove_events_async(Component.DateTime? rid,
        Backing.CalendarSource.AffectedInstances affected) {
        Gdk.Cursor? cursor = Toolkit.set_busy(this);
        
        Error? remove_err = null;
        try {
            if (rid == null || affected == Backing.CalendarSource.AffectedInstances.ALL)
                yield event.calendar_source.remove_all_instances_async(event.uid, null);
            else
                yield event.calendar_source.remove_instances_async(event.uid, rid, affected, null);
        } catch (Error err) {
            remove_err = err;
        }
        
        Toolkit.set_unbusy(this, cursor);
        
        if (remove_err == null) {
            notify_success();
        } else {
            bool multiple = (rid != null) || (affected != Backing.CalendarSource.AffectedInstances.THIS);
            
            // No number is supplied because the number of events removed is indefinite in certain
            // situations ... plural text should simply be for "more than one"
            notify_failure(ngettext("Unable to remove event: %s", "Unable to remove events: %s",
                !multiple ? 1 : 2).printf(remove_err.message));
        }
    }
}

}

