/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

/**
 * Helper functions for using GObject properties and bindings.
 */

namespace California.Properties {

/**
 * Transformation callback used by {@link xform_to_bool}.
 */
public delegate bool BoolTransformer(Value source_value);

/**
 * Transformation callback used by {@link xform_to_string}.
 */
public delegate string? StringTransformer(Value source_value);

/**
 * Simplified binding transformation of a property of any value to a boolean.
 *
 * The transformation is always considered successful.  Use bind_property directly if finer control
 * is required.
 */
public void xform_to_bool(Object source, string source_property, Object target, string target_property,
    BoolTransformer cb, BindingFlags flags = BindingFlags.SYNC_CREATE) {
    source.bind_property(source_property, target, target_property, flags, (binding, source, ref target) => {
        target = cb(source);
        
        return true;
    });
}

/**
 * Simplified binding transformation of a property of any value to a nullable string.
 *
 * The transformation is always considered successful.  Use bind_property directly if finer control
 * is required.
 */
public void xform_to_string(Object source, string source_property, Object target, string target_property,
    StringTransformer cb, BindingFlags flags = BindingFlags.SYNC_CREATE) {
    source.bind_property(source_property, target, target_property, flags, (binding, source, ref target) => {
        target = cb(source);
        
        return true;
    });
}

}

