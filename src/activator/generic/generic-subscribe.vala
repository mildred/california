/* Copyright 2014-2015 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Activator.Generic {

[GtkTemplate (ui = "/org/yorba/california/rc/activator-generic-subscribe.ui")]
internal abstract class Subscribe : Gtk.Grid, Toolkit.Card {
    public abstract string card_id { get; }
    
    public abstract string? title { get; }
    
    public Gtk.Widget? default_widget { get { return subscribe_button; } }
    
    public Gtk.Widget? initial_focus { get { return name_entry; } }
    
    [GtkChild]
    private Gtk.ColorButton color_button;
    
    [GtkChild]
    private Gtk.Entry name_entry;
    
    [GtkChild]
    private Gtk.Entry url_entry;
    
    [GtkChild]
    private Gtk.Entry username_entry;
    
    [GtkChild]
    private Gtk.Button subscribe_button;
    
    private Gee.Set<string> schemes;
    private Toolkit.EntryClearTextConnector clear_text_connector = new Toolkit.EntryClearTextConnector();
    
    public Subscribe(Soup.URI? supplied_url, Gee.Set<string> schemes) {
        this.schemes = schemes;
        
        if (supplied_url != null) {
            url_entry.text = supplied_url.to_string(false);
            url_entry.sensitive = false;
        }
        
        clear_text_connector.connect_to(name_entry);
        name_entry.bind_property("text-length", subscribe_button, "sensitive",
            BindingFlags.SYNC_CREATE, on_entry_changed);
        
        clear_text_connector.connect_to(url_entry);
        url_entry.bind_property("text-length", subscribe_button, "sensitive",
            BindingFlags.SYNC_CREATE, on_entry_changed);
        
        // user name is optional
        clear_text_connector.connect_to(username_entry);
    }
    
    public virtual void jumped_to(Toolkit.Card? from, Toolkit.Card.Jump reason, Value? message) {
        name_entry.text = "";
        url_entry.text = "";
        username_entry.text = "";
    }
    
    private bool on_entry_changed(Binding binding, Value source_value, ref Value target_value) {
        target_value =
            name_entry.text_length > 0 
            && url_entry.text_length > 0
            && URI.is_valid(url_entry.text, schemes);
        
        return true;
    }
    
    [GtkCallback]
    private void on_cancel_button_clicked() {
        jump_home();
    }
    
    [GtkCallback]
    private void on_subscribe_button_clicked() {
        sensitive = false;
        
        do_subscribe_async.begin();
    }
    
    private async void do_subscribe_async() {
        Gdk.Cursor? cursor = Toolkit.set_busy(this);
        
        Error? subscribe_err = null;
        try {
            yield subscribe_async(name_entry.text, URI.parse(url_entry.text), username_entry.text,
                Gfx.rgba_to_uint8_rgb_string(color_button.rgba), null);
        } catch (Error err) {
            subscribe_err = err;
        }
        
        Toolkit.set_unbusy(this, cursor);
        
        if (subscribe_err == null) {
            jump_home();
        } else {
            notify_failure(_("Unable to subscribe to calendar at %s: %s").printf(url_entry.text,
                subscribe_err.message));
        }
        
        sensitive = true;
    }
    
    protected abstract async void subscribe_async(string name, Soup.URI uri, string? username,
        string color, Cancellable? cancellable) throws Error;
}

}

