/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Manager {

/**
 * An interactive list item in a {@link CalendarList}.
 */

[GtkTemplate (ui = "/org/yorba/california/rc/calendar-manager-list-item.ui")]
public class CalendarListItem : Gtk.Grid {
    private const int COLOR_DIM = 16;
    
    public Backing.CalendarSource source { get; private set; }
    
    [GtkChild]
    private Gtk.Image readonly_icon;
    
    [GtkChild]
    private Gtk.CheckButton visible_check_button;
    
    [GtkChild]
    private Gtk.Label title_label;
    
    [GtkChild]
    private Gtk.ColorButton color_button;
    
    public CalendarListItem(Backing.CalendarSource source) {
        this.source = source;
        
        has_tooltip = true;
        
        source.bind_property(Backing.Source.PROP_TITLE, title_label, "label",
            BindingFlags.SYNC_CREATE);
        source.bind_property(Backing.Source.PROP_VISIBLE, visible_check_button, "active",
            BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
        source.bind_property(Backing.Source.PROP_COLOR, color_button, "rgba",
            BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL, source_to_color, color_to_source);
        Properties.xform_to_string(source, Backing.Source.PROP_READONLY, readonly_icon, "icon-name",
            () => source.read_only ? "changes-prevent-symbolic" : "");
        Properties.xform_to_string(source, Backing.Source.PROP_READONLY, readonly_icon, "tooltip-text",
            () => source.read_only ? _("Calendar is read-only") : null);
    }
    
    public override bool query_tooltip(int x, int y, bool keyboard_mode, Gtk.Tooltip tooltip) {
        // no tooltip if text is entirely shown
        if (!title_label.get_layout().is_ellipsized())
            return false;
        
        tooltip.set_text(source.title);
        
        return true;
    }
    
    private bool source_to_color(Binding binding, Value source_value, ref Value target_value) {
        bool used_default;
        target_value = Gfx.rgb_string_to_rgba(source.color, Gfx.RGBA_BLACK, out used_default);
        
        return !used_default;
    }
    
    private bool color_to_source(Binding binding, Value source_value, ref Value target_value) {
        target_value = Gfx.rgb_to_uint8_rgb_string(Gfx.rgba_to_rgb(color_button.rgba));
        
        return true;
    }
}

}

