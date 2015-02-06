/* Copyright 2014-2015 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Host {

[GtkTemplate (ui = "/org/yorba/california/rc/host-import-calendar.ui")]
public class ImportCalendar : Gtk.Dialog {
    public Component.iCalendar ical { get; private set;}
    
    public Backing.CalendarSource? chosen { get; private set; default = null; }
    
    [GtkChild]
    private Gtk.Label title_label;
    
    [GtkChild]
    private Gtk.ListBox calendar_listbox;
    
    [GtkChild]
    private Gtk.Button import_button;
    
    private Toolkit.ListBoxModel<Backing.CalendarSource> model;
    
    public ImportCalendar(Gtk.Window parent, Component.iCalendar ical) {
        this.ical = ical;
        
        transient_for = parent;
        modal = true;
        resizable = false;
        
        title_label.label = ngettext("Select calendar to import event into:",
            "Select calendar to import events into:", ical.events.size);
        
        model = new Toolkit.ListBoxModel<Backing.CalendarSource>(calendar_listbox, model_presentation,
            model_filter);
        model.add_many(Backing.Manager.instance.get_sources_of_type<Backing.CalendarSource>());
        
        on_row_selected();
        calendar_listbox.row_selected.connect(on_row_selected);
    }
    
    private Gtk.Widget model_presentation(Backing.CalendarSource calendar_source) {
        return new CalendarListItem(calendar_source);
    }
    
    private bool model_filter(Backing.CalendarSource calendar_source) {
        return calendar_source.visible && !calendar_source.read_only;
    }
    
    private void on_row_selected() {
        import_button.sensitive = (calendar_listbox.get_selected_row() != null);
    }
    
    [GtkCallback]
    private void on_cancel_button_clicked() {
        response(Gtk.ResponseType.CANCEL);
    }
    
    [GtkCallback]
    private void on_activated() {
        chosen = model.selected;
        
        response(Gtk.ResponseType.OK);
    }
}

}

