/* Copyright 2014-2015 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Calendar {

/**
 * An immutable representation of a time zone and its associated Olson zoneinfo.
 *
 * Like {@link ExactTime}, this class arose because GLib's TimeZone works well for many things but
 * additional functionality needed to be added.  The most pressing need is to maintain the Olson
 * zone information for the lifetime of the object.
 */

public class Timezone : BaseObject {
    /**
     * The {@link Timezone} for UTC.
     */
    public static Timezone utc { get; private set; }
    
    /**
     * The system's configured {@link Timezone}.
     *
     * This is merely a convenience method for {@link System.timezone}.
     *
     * @see System.timezone_changed
     */
    public static Timezone local { get { return System.timezone; } }
    
    /**
     * The {@link OlsonZone} for this {@link Timezone}.
     */
    public OlsonZone zone { get; private set; }
    
    /**
     * Returns true if this {@link Timezone} represents UTC.
     *
     * This merely tests that this object is the same as the current {@link local} object; no deep
     * equality is tested.
     */
    public bool is_utc { get { return this == utc; } }
    
    /**
     * Returns true if this {@link Timezone} represents the system's configured time zone.
     *
     * This merely tests that this object is the same as the current {@link local} object; no deep
     * equality is tested.
     */
    public bool is_local { get { return this == local; } }
    
    internal TimeZone time_zone { get; private set; }
    
    public Timezone(OlsonZone zone) {
        time_zone = new TimeZone(zone.value);
        this.zone = zone;
    }
    
    internal static void init() {
        utc = new Timezone(OlsonZone.utc);
    }
    
    internal static void terminate() {
        utc = null;
    }
    
    public override string to_string() {
        return zone.to_string();
    }
}

}

