/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Backing {

/**
 * An abstract representation of a backing source of information.
 *
 * The Source is initialized, opened, closed, and terminated by the {@link Backing.Manager}.
 * However, a Source may be removed or destroyed at any time.  See {@link is_available} for more
 * information.
 *
 * @see Manager
 */

public abstract class Source : BaseObject {
    public const string PROP_IS_AVAILABLE = "is-available";
    public const string PROP_TITLE = "title";
    public const string PROP_VISIBLE = "visible";
    public const string PROP_COLOR = "color";
    
    /**
     * True if the {@link Source} is unavailable for use due to being removed from it's
     * {@link Backing.Store}.
     *
     * Ref holders should connect to the "notify" signal and disconnect and drop refs when this
     * goes false.
     *
     * @see set_unavailable
     */
    public bool is_available { get; private set; default = true; }
    
    /**
     * A user-visible name for the {@link Source}.
     */
    public string title { get; set; }
    
    /**
     * Whether the {@link Source} should be visible to the user.
     *
     * The caller should monitor this setting to decide whether or not to display the Source's
     * associated inforamtion.  Hiding a Source does not mean that a Source subscription won't
     * continue generating information.  Likewise, a hidden Source can still accept operations
     * like adding and removing objects.
     *
     * @see CalendarSourceSubscription
     */
    public bool visible { get; set; }
    
    /**
     * The suggested color to use when displaying the {@link Source} or information about or from
     * it.
     */
    public string color { get; set; }
    
    protected Source(string title) {
        this.title = title;
    }
    
    /**
     * Marks a {@link Source} as unavailable.
     *
     * A Source cannot return to the available state after this is called.  Should only be called
     * by the {@link Store} that created or manages the Source.
     *
     * @see is_unavailable
     */
    internal void set_unavailable() {
        is_available = false;
    }
    
    /**
     * Returns the current {@link color} setting as a Gdk.Color.
     *
     * If the color string is unparseable, returns a Gdk.Color that corresponds to "dressy-black".
     */
    public Gdk.Color color_as_rgb() {
        return Gfx.rgb_string_to_rgb(color, Gdk.Color() { red = 0, green = 0, blue = 0 }, null);
    }
    
    /**
     * Returns the current {@link color} setting as a Gdk.RGBA.
     *
     * If the color string is unparseable, returns a Gdk.RGBA that corresponds to "dressy-black".
     */
    public Gdk.RGBA color_as_rgba() {
        return Gfx.rgb_string_to_rgba(color,
            Gdk.RGBA() { red = 0.0, green = 0.0, blue = 0.0, alpha = 1.0 },  null);
    }
    
    /**
     * Set the {@link color} property to the string representation of the Gdk.RGBA structure.
     */
    public void set_color_to_rgba(Gdk.RGBA rgba) {
        color = Gfx.rgb_to_uint8_rgb_string(Gfx.rgba_to_rgb(rgba));
    }
    
    public override string to_string() {
        return title;
    }
}

}

