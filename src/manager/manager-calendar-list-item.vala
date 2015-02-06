/* Copyright 2014-2015 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Manager {

/**
 * An interactive list item in a {@link CalendarList}.
 */

[GtkTemplate (ui = "/org/yorba/california/rc/manager-calendar-list-item.ui")]
internal class CalendarListItem : Gtk.Grid, Toolkit.MutableWidget {
    private const int COLOR_DIM = 16;
    
    public Backing.CalendarSource source { get; private set; }
    
    /**
     * Set by {@link CalendarList}.
     */
    public bool is_selected { get; set; default = false; }
    
    [GtkChild]
    private Gtk.Image server_sends_invites_icon;
    
    [GtkChild]
    private Gtk.Image readonly_icon;
    
    [GtkChild]
    private Gtk.CheckButton visible_check_button;
    
    [GtkChild]
    private Gtk.EventBox title_eventbox;
    
    [GtkChild]
    private Gtk.Label title_label;
    
    [GtkChild]
    private Gtk.ColorButton color_button;
    
    [GtkChild]
    private Gtk.Image default_icon;
    
    private Toolkit.EditableLabel? editable_label = null;
    
    public CalendarListItem(Backing.CalendarSource source) {
        this.source = source;
        
        has_tooltip = true;
        
        source.notify[Backing.Source.PROP_TITLE].connect(on_title_changed);
        
        source.bind_property(Backing.Source.PROP_TITLE, title_label, "label",
            BindingFlags.SYNC_CREATE);
        source.bind_property(Backing.Source.PROP_VISIBLE, visible_check_button, "active",
            BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
        source.bind_property(Backing.Source.PROP_COLOR, color_button, "rgba",
            BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL, source_to_color, color_to_source);
        source.bind_property(Backing.Source.PROP_READONLY, readonly_icon, "icon-name",
            BindingFlags.SYNC_CREATE, xform_readonly_to_icon_name);
        source.bind_property(Backing.Source.PROP_READONLY, readonly_icon, "tooltip-text",
            BindingFlags.SYNC_CREATE, xform_readonly_to_tooltip_text);
        source.bind_property(Backing.CalendarSource.PROP_IS_DEFAULT, default_icon, "icon-name",
            BindingFlags.SYNC_CREATE, xform_default_to_icon_name);
        source.bind_property(Backing.CalendarSource.PROP_IS_DEFAULT, default_icon, "tooltip-text",
            BindingFlags.SYNC_CREATE, xform_default_to_tooltip_text);
        source.bind_property(Backing.CalendarSource.PROP_SERVER_SENDS_INVITES, server_sends_invites_icon,
            "icon-name", BindingFlags.SYNC_CREATE, xform_sends_invites_to_icon_name);
        source.bind_property(Backing.CalendarSource.PROP_SERVER_SENDS_INVITES, server_sends_invites_icon,
            "tooltip-text", BindingFlags.SYNC_CREATE, xform_sends_invites_to_tooltip_text);
        
        title_eventbox.button_release_event.connect(on_title_button_release);
    }
    
    ~CalendarListItem() {
        source.notify[Backing.Source.PROP_TITLE].disconnect(on_title_changed);
    }
    
    private void on_title_changed() {
        // title determines sort order, so this is important
        mutated();
    }
    
    private bool xform_readonly_to_icon_name(Binding binding, Value source_value, ref Value target_value) {
        target_value = source.read_only ? "changes-prevent-symbolic" : "";
        
        return true;
    }
    
    private bool xform_readonly_to_tooltip_text(Binding binding, Value source_value, ref Value target_value) {
        target_value = source.read_only ? _("Calendar is read-only") : null;
        
        return true;
    }
    
    private bool xform_default_to_icon_name(Binding binding, Value source_value, ref Value target_value) {
        target_value = source.is_default ? "starred-symbolic" : "";
        
        return true;
    }
    
    private bool xform_default_to_tooltip_text(Binding binding, Value source_value, ref Value target_value) {
        target_value = source.is_default ? _("Calendar is default") : _("Make this calendar default");
        
        return true;
    }
    
    private bool xform_sends_invites_to_icon_name(Binding binding, Value source_value, ref Value target_value) {
        target_value = source.server_sends_invites ? "mail-unread-symbolic" : "";
        
        return true;
    }
    
    private bool xform_sends_invites_to_tooltip_text(Binding binding, Value source_value, ref Value target_value) {
        target_value = source.server_sends_invites
            ? _("Server sends event invitations")
            : _("Server does not send event invitations");
        
        return true;
    }
    
    public override bool query_tooltip(int x, int y, bool keyboard_mode, Gtk.Tooltip tooltip) {
        // no tooltip if text is entirely shown
        if (!title_label.get_layout().is_ellipsized())
            return false;
        
        tooltip.set_text(source.title);
        
        return true;
    }
    
    /**
     * Allow for the user to rename the title of the {@link source}.
     *
     * This presents a {@link Toolkit.EditableLabel} for the user to enter the new name.
     */
    public void rename() {
        if (editable_label == null)
            activate_editable_label();
    }
    
    private bool source_to_color(Binding binding, Value source_value, ref Value target_value) {
        bool used_default;
        target_value = Gfx.rgb_string_to_rgba(source.color, Gfx.BLACK, out used_default);
        
        return !used_default;
    }
    
    private bool color_to_source(Binding binding, Value source_value, ref Value target_value) {
        target_value = Gfx.rgba_to_uint8_rgb_string(color_button.rgba);
        
        return true;
    }
    
    private void activate_editable_label() {
        assert(editable_label == null);
        
        editable_label = new Toolkit.EditableLabel(title_label);
        editable_label.accepted.connect(on_title_edit_accepted);
        editable_label.dismissed.connect(remove_editable_label);
        
        editable_label.show_all();
    }
    
    private void remove_editable_label() {
        assert(editable_label != null);
        
        editable_label.destroy();
        editable_label = null;
    }
    
    private bool on_title_button_release(Gdk.EventButton event) {
        // if already accepting input or not selected, don't activate text entry for rename (but
        // allow signal to propagate further)
        if (editable_label != null || !is_selected)
            return false;
        
        // only interest in primary button clicks
        if (event.button != 1)
            return false;
        
        activate_editable_label();
        
        // don't propagate
        return true;
    }
    
    private void on_title_edit_accepted(string text) {
        if (!String.is_empty(text))
            source.title = text;
    }
    
    [GtkCallback]
    private void on_default_button_clicked() {
        try {
            source.store.make_default_calendar(source);
        } catch (Error err) {
            message("Unable to set default calendar to %s: %s", source.title, err.message);
        }
    }
    
    [GtkCallback]
    private void on_server_sends_invites_button_clicked() {
        source.server_sends_invites = !source.server_sends_invites;
    }
}

}

