/* Copyright 2014-2015 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

// It's either this or double-unref Binding objects; see
// https://bugzilla.gnome.org/show_bug.cgi?id=730967
extern void g_binding_unbind(Binding *binding);

namespace California {

/**
 * A base class for debugging and monitoring.
 */

public abstract class BaseObject : Object {
    /**
     * Returns the base class name as a string.
     *
     * This can be used as a dummy to_string() for {@link BaseObject}s that don't carry state to
     * report.
     */
    public string classname { get { return get_type().name(); } }
    
    protected BaseObject() {
    }
    
    /**
     * Helper for unbinding properties until g_binding_unbind() is bound.
     *
     * See [[https://bugzilla.gnome.org/show_bug.cgi?id=730967]]
     */
    public static void unbind_property(ref Binding? binding) {
        if (binding == null)
            return;
        
        g_binding_unbind(binding);
        binding = null;
    }
    
    /**
     * Returns a string representation of the object ''for debugging and logging only''.
     *
     * String conversion for other purposes (user labels, serialization, etc.) should be handled
     * by other appropriately-named methods.
     */
    public abstract string to_string();
}

}

