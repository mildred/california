/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.View {

/**
 * A singleton holding colors and theme information for drawing the various views.
 *
 * TODO: Currently colors are hard-coded.  In the future we'll probably need to get these from the
 * system or the theme.
 */

public class Palette : BaseObject {
    /**
     * Margins around text (in pixels).
     */
    public const int TEXT_MARGIN_PX = 2;
    
    /**
     * Line padding when painting text (in pixels).
     */
    public const int LINE_PADDING_PX = 4;
    
    /**
     * Hairline line width.
     */
    public const double HAIRLINE_WIDTH = 0.5;
    
    /**
     * Dash pattern for Cairo.
     */
    public const double DASHES[] = { 1.0, 3.0 };
    
    private const int NORMAL_FONT_SIZE_PT = 11;
    private const int SMALL_FONT_SIZE_PT = 8;
    
    public static Palette instance { get; private set; }
    
    /**
     * Border color (when separating days, for example).
     */
    public Gdk.RGBA border { get; private set; }
    
    /**
     * Color to use when drawing details of a day inside the current {@link View} range.
     *
     * @see day_outside_range
     */
    public Gdk.RGBA day_in_range { get; private set; }
    
    /**
     * Color to use when drawing details of a day outside the current {@link View} range.
     *
     * @see day_in_range
     */
    public Gdk.RGBA day_outside_range { get; private set; }
    
    /**
     * Background color for day representing current date.
     */
    public Gdk.RGBA current_day { get; private set; }
    
    /**
     * Foreground color representing current time of day.
     */
    public Gdk.RGBA current_time { get; private set; }
    
    /**
     * Background color to use for selected days/time.
     */
    public Gdk.RGBA selection { get; private set; }
    
    /**
     * Normal-sized font.
     *
     * In general this should be used sparingly, as most calendar views need to conserve screen
     * real estate and use {@link Host.ShowEvent} to display a greater amount of detail.
     *
     * @see small_font
     */
    public Pango.FontDescription normal_font;
    
    /**
     * Font height extent for {@link normal_font} (in pixels).
     *
     * This will be a negative value until the main window is mapped to the screen.
     *
     * @see main_window_mapped
     */
    public int normal_font_height_px { get; private set; default = -1; }
    
    /**
     * Small font.
     *
     * This is more appropriate than {@link normal_font} when displaying calendar information,
     * especially event detail.
     */
    public Pango.FontDescription small_font;
    
    /**
     * Font height extent for {@link small_font} (in pixels).
     *
     * This will be a negative value until the main window is mapped to the screen.
     *
     * @see main_window_mapped
     */
    public int small_font_height_px { get; private set; default = -1; }
    
    /**
     * Fired when palette has changed.
     *
     * It's generally simpler to subscribe to this signal rather than the "notify" for every
     * property.
     */
    public signal void palette_changed();
    
    private Palette() {
        border = { red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0 };
        day_in_range = { red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0 };
        day_outside_range = { red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0 };
        current_day = { red: 0.0, green: 0.25, blue: 0.50, alpha: 0.10 };
        current_time = { red: 1.0, green: 0.0, blue: 0.0, alpha: 0.90 };
        selection = { red: 0.0, green: 0.50, blue: 0.50, alpha: 0.10 };
        
        normal_font = new Pango.FontDescription();
        normal_font.set_size(NORMAL_FONT_SIZE_PT * Pango.SCALE);
        
        small_font = new Pango.FontDescription();
        small_font.set_size(SMALL_FONT_SIZE_PT * Pango.SCALE);
    }
    
    internal static void init() {
        instance = new Palette();
    }
    
    internal static void terminate() {
        instance = null;
    }
    
    /**
     * Called by {@link Host.MainWindow} when it's mapped to the screen.
     *
     * This allows for {@link Palette} to retrieve display metrics and other information.
     */
    public void main_window_mapped(Gtk.Window window) {
        bool updated = false;
        
        int height = get_height_extent(window, normal_font);
        if (height != normal_font_height_px) {
            normal_font_height_px = height;
            updated = true;
        }
        
        height = get_height_extent(window, small_font);
        if (height != small_font_height_px) {
            small_font_height_px = height;
            updated = true;
        }
        
        if (updated)
            palette_changed();
    }
    
    private static int get_height_extent(Gtk.Widget widget, Pango.FontDescription font) {
        Pango.Layout layout = widget.create_pango_layout("Gg");
        layout.set_font_description(font);
        
        int width, height;
        layout.get_pixel_size(out width, out height);
        
        return height;
    }
    
    /**
     * Prepare a Cairo.Context for drawing hairlines.
     */
    public static Cairo.Context prepare_hairline(Cairo.Context ctx, Gdk.RGBA rgba) {
        Gdk.cairo_set_source_rgba(ctx, rgba);
        ctx.set_line_width(HAIRLINE_WIDTH);
        ctx.set_line_cap(Cairo.LineCap.ROUND);
        ctx.set_line_join(Cairo.LineJoin.ROUND);
        ctx.set_dash(null, 0);
        
        return ctx;
    }
    
    /**
     * Prepare a Cairo.Context for drawing hairline dashed lines.
     */
    public static Cairo.Context prepare_hairline_dashed(Cairo.Context ctx, Gdk.RGBA rgba) {
        Gdk.cairo_set_source_rgba(ctx, rgba);
        ctx.set_line_width(HAIRLINE_WIDTH);
        ctx.set_line_cap(Cairo.LineCap.ROUND);
        ctx.set_line_join(Cairo.LineJoin.ROUND);
        ctx.set_dash(DASHES, 0);
        
        return ctx;
    }
    
    public override string to_string() {
        return "View.Palette";
    }
}

}

