/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Calendar {

/**
 * An immutable representation of duration, as in a positive span of time.
 *
 * See [[https://tools.ietf.org/html/rfc5545#section-3.8.2.5]]
 */

public class Duration : BaseObject {
    /**
     * Number of absolute days the duration spans.
     */
    public uint days { get { return hours / WallTime.HOURS_PER_DAY; } }
    
    /**
     * Number of absolute hours the duration spans.
     */
    public uint hours { get { return minutes / WallTime.MINUTES_PER_HOUR; } }
    
    /**
     * Number of absolute minutes the duration spans.
     */
    public uint minutes { get { return seconds / WallTime.SECONDS_PER_MINUTE; } }
    
    /**
     * Number of absolute seconds the duration spans.
     */
    public uint seconds { get; private set; }
    
    public Duration(uint days = 0, uint hours = 0, uint minutes = 0, uint seconds = 0) {
        // internally stored as seconds
        this.seconds =
            (days * WallTime.SECONDS_PER_MINUTE * WallTime.MINUTES_PER_HOUR * WallTime.HOURS_PER_DAY)
            + (hours * WallTime.SECONDS_PER_MINUTE * WallTime.MINUTES_PER_HOUR)
            + (minutes * WallTime.SECONDS_PER_MINUTE)
            + seconds;
    }
    
    /**
     * Parses the two tokens into a {@link Duration}.
     *
     * parse() is looking for a pattern where the first token is a number and the second a string
     * of units of time (localized), either hours, minutes, or seconds.  null is returned if that
     * pattern is not located.
     *
     * Future expansion could include a pattern where the first token has a unit as a suffix, i.e.
     * "3hrs" or "4m".
     *
     * It's possible for this call to return a Duration of zero time.
     */
    public static Duration? parse(string value, string unit) {
        if (String.is_empty(value) || String.is_empty(unit))
            return null;
        
        if (!String.is_numeric(value))
            return null;
        
        int duration = int.parse(value);
        if (duration < 0)
            return null;
        
        if (unit in UNIT_DAYS)
            return new Duration(duration);
        
        if (unit in UNIT_HOURS)
            return new Duration(0, duration);
        
        if (unit in UNIT_MINS)
            return new Duration(0, 0, duration);
        
        return null;
    }
    
    public override string to_string() {
        return "%us".printf(seconds);
    }
}

}

