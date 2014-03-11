/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Calendar {

/**
 * A singleton offering system-based calendar and time information and updates of important changes.
 *
 * Most of System's properties are static as a convenience for callers (to avoid having to always
 * reference {@link instance}).  Since static properties have no notification mechanism, callers
 * interested in being notified of changes must subscribe to the instance's particular signals,
 * i.e. {@link zone_changed}.
 */

public class System : BaseObject {
    private const string CLOCK_FORMAT_SCHEMA = "org.gnome.desktop.interface";
    private const string CLOCK_FORMAT_KEY = "clock-format";
    private const string CLOCK_FORMAT_24H = "24h";
    
    public static System instance { get; private set; }
    
    /**
     * The current date according to the local timezone.
     *
     * TODO: This currently does not update as the program executes.
     */
    public static Date today { get; private set; }
    
    /**
     * Returns the current {@link ExactTime} of the local {@link Timezone}.
     */
    public static ExactTime now {
        owned get {
            return new ExactTime.now(Timezone.local);
        }
    }
    
    /**
     * If the current user is configured to use 12 or 24-hour time.
     */
    public static bool is_24hr { get; private set; }
    
    /**
     * Returns the system's configured zone as an {@link OlsonZone}.
     */
    public static OlsonZone zone { get; private set; }
    
    /**
     * The current system {@link Timezone}.
     *
     * @see timezone_changed
     * @see Timezone.utc
     */
    public static Timezone timezone { get; private set; }
    
    private static DBus.timedated timedated_service;
    private static DBus.Properties timedated_properties;
    
    /**
     * Fired when {@link is_24hr} changes.
     *
     * This means the user has changed the their clock format configuration.
     */
    public signal void is_24hr_changed(bool new_is_24hr);
    
    /**
     * Fired when {@link zone} changes.
     *
     * This generally indicates that the user has changed system time zone manually or that the
     * system detected the change through geolocation services.
     */
    public signal void zone_changed(OlsonZone new_zone);
    
    /**
     * Fired when {@link local_timezone} changes due to system configuration changes.
     */
    public signal void timezone_changed(Timezone new_timezone);
    
    private Settings system_clock_format_schema = new Settings(CLOCK_FORMAT_SCHEMA);
    
    private System() {
        zone = new OlsonZone(timedated_service.timezone);
        timezone = new Timezone(zone);
        debug("Local zone: %s", zone.to_string());
        
        // to be notified of changes as they occur
        timedated_properties.properties_changed.connect(on_timedated_properties_changed);
        
        is_24hr = system_clock_format_schema.get_string(CLOCK_FORMAT_KEY) == CLOCK_FORMAT_24H;
        system_clock_format_schema.changed[CLOCK_FORMAT_KEY].connect(() => {
            bool new_is_24hr = system_clock_format_schema.get_string(CLOCK_FORMAT_KEY) == CLOCK_FORMAT_24H;
            if (new_is_24hr != is_24hr) {
                is_24hr = new_is_24hr;
                is_24hr_changed(is_24hr);
            }
        });
        
        // TODO: Tie this into the event loop so it's properly updated
        today = new Date.now(Timezone.local);
    }
    
    internal static void preinit() throws IOError {
        timedated_service = Bus.get_proxy_sync(BusType.SYSTEM, DBus.timedated.NAME,
            DBus.timedated.OBJECT_PATH);
        timedated_properties = Bus.get_proxy_sync(BusType.SYSTEM, DBus.Properties.NAME,
            DBus.timedated.OBJECT_PATH);
    }
    
    internal static void init() {
        instance = new System();
    }
    
    internal static void terminate() {
        instance = null;
        timedated_service = null;
        timedated_properties = null;
    }
    
    private void on_timedated_properties_changed(string interf,
        HashTable<string, Variant> changed_properties_values, string[] changed_properties) {
        if (changed_properties_values.contains(DBus.timedated.PROP_TIMEZONE)
            || DBus.timedated.PROP_TIMEZONE in changed_properties) {
            zone = new OlsonZone(timedated_service.timezone);
            timezone = new Timezone(zone);
            debug("New local zone: %s", zone.to_string());
            
            // fire signals last in case a subscriber monitoring zone thinks that local_timezone
            // has also changed
            zone_changed(zone);
            timezone_changed(timezone);
        }
    }
    
    public override string to_string() {
        return get_class().get_type().name();
    }
}

}

