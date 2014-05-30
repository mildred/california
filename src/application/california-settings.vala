/* Copyright 2014 Yorba Foundation
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
    
    // GSettings schema identifier.
    private const string SCHEMA_ID = "org.yorba.california";
    
    // schema key ids may be the same as property names, but want to keep them different in case
    // one or the other changes
    private const string KEY_CALENDAR_VIEW = "calendar-view";
    
    public static Settings instance { get; private set; }
    
    public string calendar_view { get; set; }
    
    private GLib.Settings settings;
    
    private Settings() {
        // construct after env is in place
        settings = new GLib.Settings(SCHEMA_ID);
        
        // bind GSettings values to properties here, which callers may access directly or bind to
        // themselves (with a bit more type safety)
        settings.bind(KEY_CALENDAR_VIEW, this, PROP_CALENDAR_VIEW, SettingsBindFlags.DEFAULT);
    }
    
    internal static void init() throws Error {
        // this needs to be available before initialization
        assert(Application.instance.exec_file != null);
        
        // if not running installed executable, point GSettings to our copy in the build directory
        if (!Application.instance.is_installed) {
            File schema_dir = Application.instance.build_root_dir.get_child("data");
            Environment.set_variable("GSETTINGS_SCHEMA_DIR", schema_dir.get_path(), true);
        }
        
        instance = new Settings();
    }
    
    internal static void terminate() {
        instance = null;
    }
    
    public override string to_string() {
        return get_class().get_type().name();
    }
}

}

