/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Backing {

[GtkTemplate (ui = "/org/yorba/california/rc/webcal-subscribe.ui")]
internal class WebCalActivatorPane : Gtk.Grid, Host.Interaction {
    public Gtk.Widget? default_widget { get { return subscribe_button; } }
    
    [GtkChild]
    private Gtk.ColorButton color_button;
    
    [GtkChild]
    private Gtk.Entry name_entry;
    
    [GtkChild]
    private Gtk.Entry url_entry;
    
    [GtkChild]
    private Gtk.Button subscribe_button;
    
    private WebCalSubscribable store;
    
    public WebCalActivatorPane(WebCalSubscribable store, Soup.URI? supplied_url) {
        this.store = store;
        
        if (supplied_url != null) {
            url_entry.text = supplied_url.to_string(false);
            url_entry.sensitive = false;
        }
        
        name_entry.bind_property("text-length", subscribe_button, "sensitive",
            BindingFlags.SYNC_CREATE, on_entry_changed);
        url_entry.bind_property("text-length", subscribe_button, "sensitive",
            BindingFlags.SYNC_CREATE, on_entry_changed);
    }
    
    private bool on_entry_changed(Binding binding, Value source_value, ref Value target_value) {
        target_value =
            name_entry.text_length > 0 
            && url_entry.text_length > 0
            && URI.is_valid(url_entry.text, { "http://", "https://", "webcal://" });
        
        return true;
    }
    
    [GtkCallback]
    private void on_cancel_button_clicked() {
        dismissed(true);
    }
    
    [GtkCallback]
    private void on_subscribe_button_clicked() {
        sensitive = false;
        
        subscribe_async.begin();
    }
    
    private async void subscribe_async() {
        Gdk.Color color;
        color_button.get_color(out color);
        
        try {
            yield store.subscribe_webcal_async(name_entry.text, URI.parse(url_entry.text),
                Gfx.rgb_to_uint8_rgb_string(color), null);
            completed();
        } catch (Error err) {
            debug("Unable to create subscription to %s: %s", url_entry.text, err.message);
        }
        
        dismissed(true);
    }
}

}

