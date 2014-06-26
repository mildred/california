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
    private Gtk.Label description_text;
    
    [GtkChild]
    private Gtk.Button update_button;
    
    [GtkChild]
    private Gtk.Button remove_button;
    
    [GtkChild]
    private Gtk.Button close_button;
    
    private new Component.Event event;
    
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
        // summary
        set_label(null, summary_text, event.summary);
        
        // location
        set_label(where_label, where_text, event.location);
        
        // time
        set_label(when_label, when_text, event.get_event_time_pretty_string(Calendar.Timezone.local));
        
        // description
        set_label(null, description_text, Markup.linkify(escape(event.description), linkify_delegate));
        
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
    
    [GtkCallback]
    private void on_remove_button_clicked() {
        remove_event_async.begin();
    }
    
    [GtkCallback]
    private void on_update_button_clicked() {
        jump_to_card_by_name(CreateUpdateEvent.ID, event);
    }
    
    [GtkCallback]
    private void on_close_button_clicked() {
        notify_user_closed();
    }
    
    private async void remove_event_async() {
        Gdk.Cursor? cursor = Toolkit.set_busy(this);
        
        Error? remove_err = null;
        try {
            yield event.calendar_source.remove_component_async(event.uid, null);
        } catch (Error err) {
            remove_err = err;
        }
        
        Toolkit.set_unbusy(this, cursor);
        
        if (remove_err == null)
            notify_success();
        else
            notify_failure(_("Unable to remove event: %s").printf(remove_err.message));
    }
}

}

