/* Copyright 2014-2015 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Gfx {

public const Gdk.RGBA BLACK = { 0.0, 0.0, 0.0, 1.0 };
public const Gdk.RGBA WHITE = { 1.0, 1.0, 1.0, 1.0 };

/**
 * Convert an RGBA string into an RGBA structure.
 *
 * The string can be in any of the forms that Gdk.RGBA.parse accepts.  If unable to parse the
 * string, the {@link default_rgba} is returned and {@link used_default} is set to true.
 */
public Gdk.RGBA rgb_string_to_rgba(string? rgb_string, Gdk.RGBA default_rgba, out bool used_default) {
    if (String.is_empty(rgb_string)) {
        used_default = true;
        
        return default_rgba;
    }
    
    Gdk.RGBA rgba = Gdk.RGBA();
    if (!rgba.parse(rgb_string)) {
        debug("Unable to parse RGBA color \"%s\"", rgb_string);
        
        used_default = true;
        
        return default_rgba;
    }
    
    used_default = false;
    
    return rgba;
}

/**
 * Converts the Gdk.RGBA into a 32-bit pixel representation.
 */
public uint32 rgba_to_pixel(Gdk.RGBA rgba) {
    return (uint32) fp_to_uint8(rgba.red) << 24
        | (uint32) fp_to_uint8(rgba.green) << 16
        | (uint32) fp_to_uint8(rgba.blue) << 8
        | (uint32) fp_to_uint8(rgba.alpha);
}

private inline uint8 fp_to_uint8(double value) {
    return (uint8) Math.round(value * (double) uint8.MAX);
}

/**
 * Converts the Gdk.RGBA into an RGB string representation ("#ad12c3")
 *
 * Note that alpha channel information is lost in this conversion.
 */
public string rgba_to_uint8_rgb_string(Gdk.RGBA rgba) {
    return "#%02x%02x%02x".printf(
        fp_to_uint8(rgba.red),
        fp_to_uint8(rgba.green),
        fp_to_uint8(rgba.blue)
    );
}

}
