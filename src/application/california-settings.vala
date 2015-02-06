/* Copyright 2014-2015 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California {

/**
 * Various application settings for California (stored in GSettings) available as a singleton.
 */

public class Settings : BaseObject {
    public const string PROP_CALENDAR_VIEW = "calendar-view";
    public const string PROP_SMALL_FONT_PTS = "small-font-pts";
    public const string PROP_NORMAL_FONT_PTS = "normal-font-pts";
    public const string PROP_WINDOW_WIDTH = "window-width";
    public const string PROP_WINDOW_HEIGHT = "window-height";
    public const string PROP_WINDOW_MAXIMIZED = "window-maximized";
    
    // GSettings schema identifier.
    private const string SCHEMA_ID = "org.yorba.california";
    
    // schema key ids may be the same as property names, but want to keep them different in case
    // one or the other changes
    private const string KEY_CALENDAR_VIEW = "calendar-view";
    private const string KEY_SMALL_FONT_PTS = "small-font-pts";
    private const string KEY_NORMAL_FONT_PTS = "normal-font-pts";
    private const string KEY_WINDOW_WIDTH = "window-width";
    private const string KEY_WINDOW_HEIGHT = "window-height";
    private const string KEY_WINDOW_MAXIMIZED = "window-maximized";
    private const string KEY_FIRST_OF_WEEK = "first-of-week";
    
    private const string VALUE_FIRST_OF_WEEK_SUNDAY = "sunday";
    private const string VALUE_FIRST_OF_WEEK_MONDAY = "monday";
    private const string VALUE_FIRST_OF_WEEK_SYSTEM = "system";
    
    public static Settings instance { get; private set; }
    
    /**
     * Which view ("month", "week") is currently displayed.
     *
     * The string is determined by the various views' {@link View.Controllable.id}.
     */
    public string calendar_view { get; set; }
    
    /**
     * The size of the small font used throughout the application (in points).
     */
    public int small_font_pts {
        get {
            return settings.get_int(KEY_SMALL_FONT_PTS).clamp(View.Palette.MIN_SMALL_FONT_PTS,
                View.Palette.MAX_SMALL_FONT_PTS);
        }
        
        set {
            settings.set_int(KEY_SMALL_FONT_PTS, value.clamp(View.Palette.MIN_SMALL_FONT_PTS,
                View.Palette.MAX_SMALL_FONT_PTS));
        }
    }
    
    /**
     * The size of the "normal" font used throughout the application (in points).
     */
    public int normal_font_pts {
        get {
            return settings.get_int(KEY_NORMAL_FONT_PTS).clamp(View.Palette.MIN_NORMAL_FONT_PTS,
                View.Palette.MAX_NORMAL_FONT_PTS);
        }
        
        set {
            settings.set_int(KEY_NORMAL_FONT_PTS, value.clamp(View.Palette.MIN_NORMAL_FONT_PTS,
                View.Palette.MAX_NORMAL_FONT_PTS));
        }
    }
    
    /**
     * The width of the main window (in pixels).
     *
     * Do not directly map the window's configuration to this property.  Only set the value after
     * a reasonable delay of user input or when the window is closed (unmapped).
     */
    public int window_width {
        get {
            return settings.get_int(KEY_WINDOW_WIDTH).clamp(Host.MainWindow.MIN_WIDTH, int.MAX);
        }
        
        set {
            settings.set_int(KEY_WINDOW_WIDTH, value.clamp(Host.MainWindow.MIN_WIDTH, int.MAX));
        }
    }
    
    /**
     * The height of the main window (in pixels).
     *
     * Do not directly map the window's configuration to this property.  Only set the value after
     * a reasonable delay of user input or when the window is closed (unmapped).
     */
    public int window_height {
        get {
            return settings.get_int(KEY_WINDOW_HEIGHT).clamp(Host.MainWindow.MIN_HEIGHT, int.MAX);
        }
        
        set {
            settings.set_int(KEY_WINDOW_HEIGHT, value.clamp(Host.MainWindow.MIN_HEIGHT, int.MAX));
        }
    }
    
    /**
     * Set if the main window is maximized.
     */
    public bool window_maximized { get; set; }
    
    private GLib.Settings settings;
    
    private Settings() {
        // construct after env is in place
        settings = new GLib.Settings(SCHEMA_ID);
        
        // bind GSettings values to properties here, which callers may access directly or bind to
        // themselves (with a bit more type safety)
        settings.bind(KEY_CALENDAR_VIEW, this, PROP_CALENDAR_VIEW, SettingsBindFlags.DEFAULT);
        settings.bind(KEY_WINDOW_MAXIMIZED, this, PROP_WINDOW_MAXIMIZED, SettingsBindFlags.DEFAULT);
        
        // bind_mapping() isn't well-bound in the VAPI, so do some of these transformations manually
        settings.changed.connect(on_setting_changed);
        Calendar.System.instance.first_of_week_changed.connect(on_system_first_of_week_changed);
        
        // initialize these unbound values
        on_setting_changed(KEY_FIRST_OF_WEEK);
    }
    
    ~Settings() {
        Calendar.System.instance.first_of_week_changed.disconnect(on_system_first_of_week_changed);
    }
    
    internal static void init() throws Error {
        // this needs to be available before initialization
        assert(Application.instance.exec_file != null);
        
        // if not running installed executable, point GSettings to our copy in the build directory
        if (!Application.instance.is_installed) {
            File schema_dir = Application.instance.build_root_dir.get_child("data");
            Environment.set_variable("GSETTINGS_SCHEMA_DIR", schema_dir.get_path(), true);
        }
        
        // Calendar must be initialized for Settings to set/monitor first-of-week
        Calendar.init();
        
        instance = new Settings();
    }
    
    internal static void terminate() {
        instance = null;
        
        Calendar.terminate();
    }
    
    /**
     * Reset settings to use system-defined (or locale-defined) first day of week.
     *
     * This is necessary because {@link Settings} will monitor {@link Calendar.System.first_of_week}
     * for changes and save them to GSettings, but there's no way via that interface to specify
     * "fall back on system's value".
     */
    public void use_system_first_of_week() {
        settings.set_string(KEY_FIRST_OF_WEEK, VALUE_FIRST_OF_WEEK_SYSTEM);
    }
    
    private void on_setting_changed(string key) {
        switch (key.casefold()) {
            case KEY_FIRST_OF_WEEK:
                on_setting_first_of_week_changed(settings.get_string(KEY_FIRST_OF_WEEK));
            break;
        }
    }
    
    private void on_setting_first_of_week_changed(string value) {
        Calendar.FirstOfWeek to_set;
        switch (value.casefold()) {
            case VALUE_FIRST_OF_WEEK_MONDAY:
                to_set = Calendar.FirstOfWeek.MONDAY;
            break;
            
            case VALUE_FIRST_OF_WEEK_SUNDAY:
                to_set = Calendar.FirstOfWeek.SUNDAY;
            break;
            
            case VALUE_FIRST_OF_WEEK_SYSTEM:
            default:
                to_set = Calendar.System.instance.system_first_of_week;
            break;
        }
        
        // prevent notification loops
        if (Calendar.System.first_of_week != to_set)
            Calendar.System.first_of_week = to_set;
    }
    
    private void on_system_first_of_week_changed(Calendar.FirstOfWeek old_fow,
        Calendar.FirstOfWeek new_fow) {
        string value;
        switch (new_fow) {
            case Calendar.FirstOfWeek.MONDAY:
                value = VALUE_FIRST_OF_WEEK_MONDAY;
            break;
            
            case Calendar.FirstOfWeek.SUNDAY:
                value = VALUE_FIRST_OF_WEEK_SUNDAY;
            break;
            
            default:
                assert_not_reached();
        }
        
        // prevent costly writes and notification loops
        if (settings.get_string(KEY_FIRST_OF_WEEK).casefold() != value)
            settings.set_string(KEY_FIRST_OF_WEEK, value);
    }
    
    public override string to_string() {
        return get_class().get_type().name();
    }
}

}

