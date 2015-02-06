/* Copyright 2014-2015 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Toolkit {

/**
 * Uses a {@link Popup} to place a Gtk.Entry over a Gtk.Label, creating the illusion that the user
 * can "edit" the label.
 *
 * If the user presses Enter, {@link accepted} will fire.  It is up to the caller to set the
 * Gtk.Label's text to this field.
 *
 * Callers should subscribe to the {@link dismissed} label to destroy this widget.
 *
 * This currently doesn't deal with font issues (i.e. the editable field will use the system editing
 * font).
 */

public class EditableLabel : Popup {
    /**
     * The Gtk.Label being "edited".
     */
    public Gtk.Label label { get; private set; }
    
    private Gtk.Entry entry = new Gtk.Entry();
    
    /**
     * Fired when the user presses Enter indicating the text should be accepted.
     *
     * It is up to the caller to set the Gtk.Label's text to this text (if so desired).  The
     * {@link EditableLabel} will be dismissed after this signal completes.
     */
    public signal void accepted(string text);
    
    public EditableLabel(Gtk.Label label) {
        base (label, Popup.Position.VERTICAL_CENTER);
        
        // set up Gtk.Entry to look and be sized exactly like the Gtk.Label
        entry.text = label.label;
        entry.width_chars = label.width_chars;
        entry.set_size_request(label.get_allocated_width(), -1);
        add(entry);
        
        // make sure the Popup window is hugging close to label as well
        margin = 0;
        
        // Enter accepts
        entry.activate.connect(on_entry_accepted);
    }
    
    private void on_entry_accepted() {
        accepted(entry.text);
        dismissed();
    }
}

}

