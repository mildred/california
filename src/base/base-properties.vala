/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

/**
 * Helper functions for using GObject properties and bindings.
 */

namespace California.Properties {

public delegate bool ValueToBoolCallback(Value source_value);

/**
 * Simplified binding transformation of a property of any value to a boolean.
 *
 * The transformation is always considered successful.  Use bind_property directly if finer control
 * is required.
 */
public void value_to_bool(Object source, string source_property, Object target, string target_property,
    BindingFlags flags, ValueToBoolCallback cb) {
    source.bind_property(source_property, target, target_property, flags, (binding, source, ref target) => {
        target = cb(source);
        
        return true;
    });
}

}

