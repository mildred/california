/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Gfx {

public const Gdk.Color RGB_BLACK = { 0, 0, 0 };
public const Gdk.Color RGB_WHITE = { 255, 255, 255 };

public const Gdk.RGBA RGBA_BLACK = { 0.0, 0.0, 0.0, 1.0 };
public const Gdk.RGBA RGBA_WHITE = { 1.0, 1.0, 1.0, 1.0 };

/**
 * Convert an RGB string into an RGB structure.
 *
 * The string can be in any of the forms that Gdk.Color.parse accepts.  If unable to parse the
 * string, the {@link default_rgb} is returned and {@link used_default} is set to true.
 */
public Gdk.Color rgb_string_to_rgb(string? rgb_string, Gdk.Color default_rgb, out bool used_default) {
    if (String.is_empty(rgb_string)) {
        used_default = true;
        
        return default_rgb;
    }
    
    Gdk.Color rgb;
    if (!Gdk.Color.parse(rgb_string, out rgb)) {
        debug("Unable to parse RGB color \"%s\"", rgb_string);
        
        used_default = true;
        
        return default_rgb;
    }
    
    used_default = false;
    
    return rgb;
}

/**
 * Convert an RGB string into an RGBA structure.
 *
 * The string can be in any of the forms that Gdk.Color.parse accepts.  If unable to parse the
 * string, the {@link default_rgba} is returned and {@link used_default} is set to true.
 */
public Gdk.RGBA rgb_string_to_rgba(string? rgb_string, Gdk.RGBA default_rgba, out bool used_default) {
    if (String.is_empty(rgb_string)) {
        used_default = true;
        
        return default_rgba;
    }
    
    Gdk.Color rgb;
    if (!Gdk.Color.parse(rgb_string, out rgb)) {
        debug("Unable to parse RGB color \"%s\"", rgb_string);
        
        used_default = true;
        
        return default_rgba;
    }
    
    Gdk.RGBA rgba = Gdk.RGBA();
    rgba.red = uint16_to_fp(rgb.red);
    rgba.green = uint16_to_fp(rgb.green);
    rgba.blue = uint16_to_fp(rgb.blue);
    rgba.alpha = 1.0;
    
    used_default = false;
    
    return rgba;
}

// compiler error if this calculation is done inline when initializing struct
private inline double uint16_to_fp(uint16 value) {
    return (double) value / (double) uint16.MAX;
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
 * Converts a Gdk.RGBA structure into an RGB (Gdk.Color) structure.
 *
 * The alpha channel is necessarily stripped in this conversion.
 */
public Gdk.Color rgba_to_rgb(Gdk.RGBA rgba) {
    Gdk.Color rgb = Gdk.Color();
    rgb.red = fp_to_uint16(rgba.red);
    rgb.green = fp_to_uint16(rgba.green);
    rgb.blue = fp_to_uint16(rgba.blue);
    
    return rgb;
}

private inline uint16 fp_to_uint16(double value) {
    return (uint16) Math.round(value * (double) uint16.MAX);
}

public string rgb_to_uint8_rgb_string(Gdk.Color rgb) {
    return "#%02x%02x%02x".printf(
        uint16_to_uint8(rgb.red),
        uint16_to_uint8(rgb.green),
        uint16_to_uint8(rgb.blue)
    );
}

private inline uint8 uint16_to_uint8(uint16 value) {
    return (uint8) (value / (uint8.MAX + 1));
}

public string rgb_to_string(Gdk.Color rgb) {
    return "(%d,%d,%d)".printf(rgb.red, rgb.green, rgb.blue);
}

public string rgba_to_string(Gdk.RGBA rgba) {
    return "(%lf,%lf,%lf,%lf)".printf(rgba.red, rgba.green, rgba.blue, rgba.alpha);
}

}
