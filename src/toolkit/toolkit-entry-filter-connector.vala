/* Copyright 2014-2015 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Toolkit {

/**
 * A connector that allows for filtering all text inserted into a Gtk.Entry.
 */

public class EntryFilterConnector : BaseObject {
    private Gee.MapFunc<string, string> filter;
    private Gee.HashSet<Gtk.Entry> entries = new Gee.HashSet<Gtk.Entry>();
    private Gee.HashSet<Gtk.Entry> in_signal = new Gee.HashSet<Gtk.Entry>();
    
    /**
     * A generic filtering mechanism for all connected Gtk.Entry's.
     */
    public EntryFilterConnector(Gee.MapFunc<string, string> filter) {
        this.filter = filter;
    }
    
    /**
     * A specific filter for allowing only numeric input.
     */
    public EntryFilterConnector.only_numeric() {
        this (numeric_filter);
    }
    
    ~EntryFilterConnector() {
        traverse_safely<Gtk.Entry>(entries).iterate(disconnect_from);
    }
    
    public void connect_to(Gtk.Entry entry) {
        if (!entries.add(entry))
            return;
        
        entry.insert_text.connect(on_entry_insert);
    }
    
    public void disconnect_from(Gtk.Entry entry) {
        if (!entries.remove(entry))
            return;
        
        entry.insert_text.disconnect(on_entry_insert);
    }
    
    private static string numeric_filter(owned string str) {
        return from_string(str)
            .filter(ch => ch.isdigit())
            .to_string(ch => ch.to_string());
    }
    
    private void on_entry_insert(Gtk.Editable editable, string new_text, int new_text_length,
        ref int position) {
        Gtk.Entry entry = (Gtk.Entry) editable;
        
        // prevent recursion when our modified text is inserted (i.e. allow the base handler to
        // deal with new text directly)
        if (entry in in_signal)
            return;
        
        // filter
        string filtered = filter(new_text);
        
        // insert new text into place, ensure this handler doesn't attempt to process this
        // modified text ... would use SignalHandler.block_by_func() and unblock_by_func(), but
        // the bindings are ungood
        if (!String.is_empty(filtered)) {
            in_signal.add(entry);
            editable.insert_text(filtered, filtered.length, ref position);
            in_signal.remove(entry);
        }
        
        // don't let the base handler have at the original text
        Signal.stop_emission_by_name(editable, "insert-text");
    }
    
    public override string to_string() {
        return classname;
    }
}

}

