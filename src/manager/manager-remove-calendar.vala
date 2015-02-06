/* Copyright 2014-2015 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Manager {

[GtkTemplate (ui = "/org/yorba/california/rc/manager-remove-calendar.ui")]
private class RemoveCalendar : Gtk.Grid, Toolkit.Card {
    public const string ID = "RemoveCalendar";
    
    public string card_id { get { return ID; } }
    
    public string? title { get { return null; } }
    
    public Gtk.Widget? default_widget { get { return null; } }
    
    public Gtk.Widget? initial_focus { get { return null; } }
    
    [GtkChild]
    private Gtk.Label explanation_label;
    
    private Backing.CalendarSource? source = null;
    
    public RemoveCalendar() {
    }
    
    public void jumped_to(Toolkit.Card? from, Toolkit.Card.Jump reason, Value? message) {
        source = message as Backing.CalendarSource;
        if (source == null) {
            jump_back();
            
            return;
        }
        
        string fmt;
        if (source.is_local)
            fmt = _("This will remove the %s local calendar from your computer.  All associated information will be deleted permanently.");
        else
            fmt = _("This will remove the %s network calendar from your computer.  This will not affect information stored on the server.");
        
        explanation_label.label = fmt.printf("<b>" + GLib.Markup.escape_text(source.title) + "</b>");
    }
    
    [GtkCallback]
    private void on_cancel_button_clicked() {
        jump_back();
    }
    
    [GtkCallback]
    private void on_remove_button_clicked() {
        remove_calendar_source.begin();
    }
    
    private async void remove_calendar_source() {
        if (source == null)
            return;
        
        Gdk.Cursor? cursor = Toolkit.set_busy(this);
        
        Error? remove_err = null;
        try {
            yield source.store.remove_source_async(source, null);
        } catch (Error err) {
            remove_err = err;
        }
        
        Toolkit.set_unbusy(this, cursor);
        
        if (remove_err == null)
            jump_back();
        else
            report_error(_("Unable to remove calendar: %s").printf(remove_err.message));
    }
}

}

