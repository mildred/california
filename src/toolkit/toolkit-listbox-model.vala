/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Toolkit {

/**
 * A simple model for Gtk.ListBox.
 *
 * ListBoxModel is designed to make it easier to maintain a sorted list of objects and make sure
 * the associated Gtk.ListBox is always up-to-date reflecting the state of the model.
 *
 * If the added objects implement the {@link Mutable} interface, their {@link Mutable.mutated}
 * signsl is monitored.  When fired, the listbox's sort and filters will be invalidated.
 */

public class ListBoxModel<G> : BaseObject {
    public const string PROP_SELECTED = "selected";
    
    private const string KEY = "org.yorba.california.listbox-model.model";
    
    /**
     * Returns a Gtk.Widget that is held by the Gtk.ListBox representing the particular item.
     */
    public delegate Gtk.Widget ModelPresentation<G>(G item);
    
    public Gtk.ListBox listbox { get; private set; }
    
    /**
     * The number if items in the {@link ListBoxModel}.
     */
    public int size { get { return items.size; } }
    
    /**
     * The item currently selected by the {@link listbox}, null if no selection has been made.
     */
    public G? selected { get; private set; default = null; }
    
    private unowned ModelPresentation model_presentation;
    private unowned CompareDataFunc<G>? comparator;
    private Gee.HashMap<G, Gtk.ListBoxRow> items;
    
    /**
     * Fired when an item is added to the {@link ListBoxModel}.
     *
     * @see add
     */
    public signal void added(G item);
    
    /**
     * Fired when an item is removed from the {@link ListBoxModel}.
     *
     * @see remove
     */
    public signal void removed(G item);
    
    /**
     * Fired when the {@link listbox} activates an item.
     *
     * Gtk.ListBox can activate an item with a double- or single-click, depending on configuration.
     */
    public signal void activated(G item);
    
    /**
     * Create a {@link ListBoxModel} and tie it to a Gtk.ListBox.
     *
     * The list will be sorted if a comparator is supplied, otherwise added items are appended to
     * the list.
     */
    public ListBoxModel(Gtk.ListBox listbox, ModelPresentation<G> model_presentation,
        CompareDataFunc<G>? comparator = null, owned Gee.HashDataFunc<G>? hash_func = null,
        owned Gee.EqualDataFunc<G>? equal_func = null) {
        this.listbox = listbox;
        this.model_presentation = model_presentation;
        this.comparator = comparator;
        
        items = new Gee.HashMap<G, Gtk.ListBoxRow>((owned) hash_func, (owned) equal_func);
        
        listbox.remove.connect(on_listbox_removed);
        listbox.set_sort_func(listbox_sort_func);
        listbox.row_activated.connect(on_row_activated);
        listbox.row_selected.connect(on_row_selected);
    }
    
    ~ListBoxModel() {
        listbox.row_activated.disconnect(on_row_activated);
        listbox.row_selected.disconnect(on_row_selected);
        
        foreach (G item in items.keys) {
            Mutable? mutable = item as Mutable;
            if (mutable != null)
                mutable.mutated.disconnect(on_mutated);
        }
    }
    
    /**
     * Add an item to the model, which in turns adds it to the {@link listbox}.
     *
     * If the item implements the {@link Mutable} interface, its {@link Mutable.mutated} signal
     * is monitored and will invalidate the listbox's sort and filters.
     *
     * Returns true if the model (and therefore the listbox) were altered due to the addition.
     *
     * @see added
     */
    public bool add(G item) {
        if (items.has_key(item))
            return false;
        
        Mutable? mutable = item as Mutable;
        if (mutable != null)
            mutable.mutated.connect(on_mutated);
        
        // item -> Gtk.ListBoxRow
        Gtk.ListBoxRow row = new Gtk.ListBoxRow();
        row.add(model_presentation(item));
        
        // mappings
        row.set_data<G>(KEY, item);
        items.set(item, row);
        
        listbox.add(row);
        row.show_all();
        
        added(item);
        
        return true;
    }
    
    /**
     * Add a collection of {@link Card}s to the {@link Deck}.
     *
     * Returns the number of Cards added.
     *
     * @see add
     */
    public int add_many(Gee.Iterable<G> items) {
        int count = 0;
        foreach (G item in items) {
            if (add(item))
                count++;
        }
        
        return count;
    }
    
    /**
     * Removes an item from the model, which in turn removes it from the {@link listbox}.
     *
     * Returns true if the model (and therefore the listbox) were altered due to the removal.
     *
     * @see removed
     */
    public bool remove(G item) {
        return internal_remove(item, true);
    }
    
    /**
     * Removes a collection of {@link Card}s from the {@link Deck}.
     *
     * Returns the number of Cards removed.
     *
     * @see remove
     */
    public int remove_many(Gee.Iterable<G> items) {
        int count = 0;
        foreach (G item in items) {
            if (remove(item))
                count++;
        }
        
        return count;
    }
    
    private bool internal_remove(G item, bool remove_from_listbox) {
        Gtk.ListBoxRow row;
        if (!items.unset(item, out row))
            return false;
        
        Mutable? mutable = item as Mutable;
        if (mutable != null)
            mutable.mutated.disconnect(on_mutated);
        
        if (remove_from_listbox)
            listbox.remove(row);
        
        removed(item);
        
        return true;
    }
    
    /**
     * Returns true if the model holds the item.
     */
    public bool contains(G item) {
        return items.has_key(item);
    }
    
    /**
     * Clears all items from the {@link ListBoxModel}.
     *
     * Each removed item generates a {@link removed} signal.
     */
    public void clear() {
        foreach (G item in items.keys)
            remove(item);
    }
    
    // This can be called by our add() method or externally, so don't be too absolutist here
    private void on_listbox_removed(Gtk.Widget widget) {
        // get the actual widget, not the wrapping object
        Gtk.ListBoxRow? row = widget as Gtk.ListBoxRow;
        if (row == null) {
            message("GtkListBox removed non-GtkListBoxRow child");
            
            return;
        }
        
        internal_remove(row.get_data<G>(KEY), false);
    }
    
    private int listbox_sort_func(Gtk.ListBoxRow a, Gtk.ListBoxRow b) {
        unowned G item_a = a.get_data<G>(KEY);
        unowned G item_b = b.get_data<G>(KEY);
        
        if (comparator != null)
            return comparator(item_a, item_b);
        
        return Gee.Functions.get_compare_func_for(typeof(G))(item_a, item_b);
    }
    
    private void on_row_activated(Gtk.ListBoxRow row) {
        activated(row.get_data<G>(KEY));
    }
    
    private void on_row_selected(Gtk.ListBoxRow? row) {
        selected = (row != null) ? row.get_data<G>(KEY) : null;
    }
    
    private void on_mutated(Mutable mutable) {
        Gtk.ListBoxRow? row = items.get((G) mutable);
        if (row == null) {
            message("Mutable not found in ListBoxRow");
            
            return;
        }
        
        row.changed();
    }
    
    public override string to_string() {
        return "ListboxModel";
    }
}

}

