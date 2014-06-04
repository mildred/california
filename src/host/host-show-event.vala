/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Host {

[GtkTemplate (ui = "/org/yorba/california/rc/show-event.ui")]
public class ShowEvent : Gtk.Grid, Toolkit.Card {
    public const string ID = "ShowEvent";
    
    public string card_id { get { return ID; } }
    
    public string? title { get { return null; } }
    
    public Gtk.Widget? default_widget { get { return close_button; } }
    
    public Gtk.Widget? initial_focus { get { return close_button; } }
    
    [GtkChild]
    private Gtk.Label text_label;
    
    [GtkChild]
    private Gtk.Button update_button;
    
    [GtkChild]
    private Gtk.Button remove_button;
    
    [GtkChild]
    private Gtk.Button close_button;
    
    private new Component.Event event;
    
    public signal void remove_event(Component.Event event);
    
    public ShowEvent() {
        Calendar.System.instance.is_24hr_changed.connect(build_display);
        Calendar.System.instance.today_changed.connect(build_display);
    }
    
    ~ShowEvent() {
        Calendar.System.instance.is_24hr_changed.disconnect(build_display);
        Calendar.System.instance.today_changed.disconnect(build_display);
    }
    
    public void jumped_to(Toolkit.Card? from, Value? message) {
        if (message == null)
            return;
        
        event = message as Component.Event;
        assert(event != null);
        
        build_display();
    }
    
    private void build_display() {
        // Each string should end without whitespace; add_lf_lf will ensure each section is
        // separated as long as there's preceding text
        StringBuilder builder = new StringBuilder();
        
        // summary
        if (!String.is_empty(event.summary))
            add_lf_lf(builder).append_printf("<b>%s</b>", Markup.escape_text(event.summary));
        
        // location
        if (!String.is_empty(event.location))
            add_lf_lf(builder).append_printf(_("Location: %s"), Markup.escape_text(event.location));
        
        // description
        if (!String.is_empty(event.description))
            add_lf_lf(builder).append_printf("%s", Markup.escape_text(event.description));
        
        add_lf_lf(builder).append_printf("<small>%s</small>",
            Markup.escape_text(event.get_event_time_pretty_string(Calendar.Timezone.local)));
        
        text_label.label = builder.str;
        
        // don't current support updating or removing recurring events properly; see
        // https://bugzilla.gnome.org/show_bug.cgi?id=725786
        // https://bugzilla.gnome.org/show_bug.cgi?id=725787
        bool read_only = event.calendar_source != null && event.calendar_source.read_only;
        bool visible = !event.is_recurring && !read_only;
        update_button.visible = visible;
        update_button.no_show_all = !visible;
        remove_button.visible = visible;
        remove_button.no_show_all = !visible;
    }
    
    // Adds two linefeeds if there's existing text
    private unowned StringBuilder add_lf_lf(StringBuilder builder) {
        if (!String.is_empty(builder.str))
            builder.append("\n\n");
        
        return builder;
    }
    
    [GtkCallback]
    private void on_remove_button_clicked() {
        remove_event(event);
        notify_success();
    }
    
    [GtkCallback]
    private void on_update_button_clicked() {
        jump_to_card_by_name(CreateUpdateEvent.ID, event);
    }
    
    [GtkCallback]
    private void on_close_button_clicked() {
        notify_user_closed();
    }
}

}

