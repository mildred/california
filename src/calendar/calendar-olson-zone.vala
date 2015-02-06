/* Copyright 2014-2015 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Calendar {

/**
 * The Olson name of a time zone in the tz (or zoneinfo) database.
 *
 * An Olson name is in the form of "Area/Location".  This class merely encapsulates this string
 * and gives it some type-ness; actual time zone calculations is left to {@link Timezone}.
 * In particular, little error-checking is performed by this class.  It also does no processing
 * or consideration for zone aliases ("links"), which is why it does not implement Gee.Hashable or
 * Gee.Comparable.
 *
 * This class is immutable.
 *
 * Future expansion may include some processing or parsing of the name itself, but that's not
 * planned at the moment.
 *
 * The IANA database of Olson zones and related information is located at
 * [[https://www.iana.org/time-zones]]
 */

public class OlsonZone : BaseObject {
    /**
     * The string value this class uses if an empty string is passed to the constructor.
     *
     * Note that this is not the only definition of UTC in the zoneinfo database.  That is,
     * a simple comparison of {@link value} to this constant is no guarantee that an
     * {@link OlsonZone} is or is not UTC.
     */
    public const string UTC = "UTC";
    
    /**
     * An {@link OlsonZone} representation of UTC.
     *
     * @see UTC
     */
    public static OlsonZone utc { get; private set; }
    
    /**
     * The raw Olson zoneinfo name.
     */
    public string value { get; private set; }
    
    /**
     * Create an {@link OlsonZone} for the specified area location.
     *
     * Passing null or an empty string results in an OlsonZone for {@link UTC}.
     */
    public OlsonZone(string? area_location) {
        value = !String.is_empty(area_location) ? area_location : UTC;
    }
    
    internal static void init() {
        utc = new OlsonZone(UTC);
    }
    
    internal static void terminate() {
        utc = null;
    }
    
    public override string to_string() {
        return value;
    }
}

}
