/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Calendar {

/**
 * An immutable represenation of "wall clock time", that is, an hour, minute, and seconds with no
 * correspondence to a day of a year.
 */

public class WallTime : BaseObject, Gee.Comparable<WallTime>, Gee.Hashable<WallTime> {
    /**
     * Options for {@link to_pretty_string}.
     */
    [Flags]
    public enum PrettyFlag {
        NONE = 0,
        /**
         * Indicates that the {@link seconds} property should be included in the string.
         *
         * @see OPTIONAL_MINUTES
         */
        INCLUDE_SECONDS,
        /**
         * Include minutes only if the time is not on the hour.
         *
         * If minutes are not displayed, seconds will not be either.
         */
        OPTIONAL_MINUTES,
        /**
         * Only show meridiem indicator if post-meridiem.
         *
         * Ignored if displaying 24-hour time.
         */
        MERIDIEM_POST_ONLY,
        /**
         * Use brief meridiem indicators.
         */
        BRIEF_MERIDIEM
    }
    
    public const int HOURS_PER_DAY = 24;
    public const int MIN_HOUR = 0;
    public const int MAX_HOUR = HOURS_PER_DAY - 1;
    
    public const int MINUTES_PER_HOUR = 60;
    public const int MIN_MINUTE = 0;
    public const int MAX_MINUTE = MINUTES_PER_HOUR - 1;
    
    public const int SECONDS_PER_MINUTE = 60;
    public const int MIN_SECOND = 0;
    public const int MAX_SECOND = SECONDS_PER_MINUTE - 1;
    
    /**
     * Earliest {@link WallTime} available.
     */
    public static WallTime earliest { get; private set; }
    
    /**
     * Latest {@link WallTime} available.
     */
    public static WallTime latest { get; private set; }
    
    /**
     * Zero-based hour of the day in 24-hour (or "military") time.
     */
    public int hour { get; private set; }
    
    /**
     * One-based hour of the day in 12-hour notation.
     */
    public int 12hour { get; private set; }
    
    /**
     * Zero-based minute of the {@link hour}.
     */
    public int minute { get; private set; }
    
    /**
     * Zero-based second of the {@link minute}.
     */
    public int second { get; private set; }
    
    /**
     * Indicates if post-meridiem.
     */
    public bool is_pm { get { return hour >= 12; } }
    
    /**
     * Generate a new {@link WallTime} object with the specified values.
     *
     * Values will be clamped to create a valid time.
     */
    public WallTime(int hour, int minute, int second) {
        this.hour = hour.clamp(MIN_HOUR, MAX_HOUR);
        this.minute = minute.clamp(MIN_MINUTE, MAX_MINUTE);
        this.second = second.clamp(MIN_SECOND, MAX_SECOND);
        
        if (hour == 0)
            12hour = 12;
        else if (hour > 12)
            12hour = hour - 12;
        else
            12hour = hour;
    }
    
    /**
     * Generate a new {@link WallTime} with the {@link ExactTIme}'s values.
     *
     * Because date and timezone information is lost in this conversion, the caller should convert
     * the ExactTime to the desired timezone before constructing the WallTime.
     */
    public WallTime.from_exact_time(ExactTime exact_time) {
        this (exact_time.hour, exact_time.minute, exact_time.second);
    }
    
    /**
     * Called from Calendar.init().
     */
    internal static void init() {
        earliest = new WallTime(MIN_HOUR, MIN_MINUTE, MIN_SECOND);
        latest = new WallTime(MAX_HOUR, MAX_MINUTE, MAX_SECOND);
    }
    
    /**
     * Called from Calendar.terminate().
     */
    internal static void terminate() {
        earliest = null;
        latest = null;
    }
    
    /**
     * Returns {@link WallTime} adjusted before or after this one.
     *
     * To subtract time, use a negative value.
     *
     * Like a wall clock, this will rollover to the next or previous day if enough time is
     * specified.  When this occurs, it's indicated in the rollover bool as an out result.
     */
    public WallTime adjust(int value, TimeUnit unit, out bool rollover) {
        if (value == 0) {
            rollover = false;
            
            return this;
        }
        
        int new_hour = hour;
        int new_minute = minute;
        int new_second = second;
        
        switch (unit) {
            case TimeUnit.HOUR:
                adjust_hour(ref new_hour, value, out rollover);
            break;
            
            case TimeUnit.MINUTE:
                adjust_minute(ref new_hour, ref new_minute, value, out rollover);
            break;
            
            case TimeUnit.SECOND:
                adjust_second(ref new_hour, ref new_minute, ref new_second, value, out rollover);
            break;
            
            default:
                assert_not_reached();
        }
        
        return new WallTime(new_hour, new_minute, new_second);
    }
    
    private void adjust_hour(ref int current_hour, int value, out bool rollover) {
        if (value == 0) {
            rollover = false;
            
            return;
        }
        
        // only add/subtract the fraction of 24-hours from the value; adding/subtracting 24 hours
        // (or multiple) is treated as identity operation for wall clock time
        int rem = value.abs() % HOURS_PER_DAY;
        current_hour += (value > 0) ? rem : 0 - rem;
        
        // under/overflow
        if (current_hour < 0) {
            current_hour = HOURS_PER_DAY - current_hour.abs();
            rollover = true;
        } else if (current_hour >= HOURS_PER_DAY) {
            current_hour -= HOURS_PER_DAY;
            rollover = true;
        } else if (value.abs() >= HOURS_PER_DAY) {
            rollover = true;
        } else {
            rollover = false;
        }
    }
    
    private void adjust_minute(ref int current_hour, ref int current_minute, int value, out bool rollover) {
        if (value == 0) {
            rollover = false;
            
            return;
        }
        
        int hours = value.abs() / MINUTES_PER_HOUR;
        adjust_hour(ref current_hour, value > 0 ? hours : 0 - hours, out rollover);
        
        int rem = value.abs() % MINUTES_PER_HOUR;
        current_minute += (value > 0) ? rem : 0 - rem;
        
        // under/overflow ... above logic prevents under/overflow of more than 1 hour
        if (current_minute < 0) {
            current_minute = MINUTES_PER_HOUR - current_minute.abs();
            bool under_rollover;
            adjust_hour(ref current_hour, -1, out under_rollover);
            rollover = rollover || under_rollover;
        } else if (current_minute >= MINUTES_PER_HOUR) {
            current_minute -= MINUTES_PER_HOUR;
            bool over_rollover;
            adjust_hour(ref current_hour, 1, out over_rollover);
            rollover = rollover || over_rollover;
        }
    }
    
    private void adjust_second(ref int current_hour, ref int current_minute, ref int current_second,
        int value, out bool rollover) {
        if (value == 0) {
            rollover = false;
            
            return;
        }
        
        int minutes = value.abs() / SECONDS_PER_MINUTE;
        adjust_minute(ref current_hour, ref current_minute, (value > 0) ? minutes : 0 - minutes,
            out rollover);
        
        int rem = value.abs() % SECONDS_PER_MINUTE;
        current_second += (value > 0) ? rem : 0 - rem;
        
        // under/overflow ... above logic prevents under/overflow of more than 1 minute
        if (current_second < 0) {
            current_second = SECONDS_PER_MINUTE - current_second.abs();
            bool under_rollover;
            adjust_minute(ref current_hour, ref current_minute, -1, out under_rollover);
            rollover = rollover || under_rollover;
        } else if (current_second >= SECONDS_PER_MINUTE) {
            current_second -= SECONDS_PER_MINUTE;
            bool over_rollover;
            adjust_minute(ref current_hour, ref current_minute, 1, out over_rollover);
            rollover = rollover || over_rollover;
        }
    }
    
    /**
     * Returns a prettified, localized user-visible string.
     */
    public string to_pretty_string(PrettyFlag flags) {
        bool include_sec = (flags & PrettyFlag.INCLUDE_SECONDS) != 0;
        bool optional_min = (flags & PrettyFlag.OPTIONAL_MINUTES) != 0;
        bool meridiem_post_only = (flags & PrettyFlag.MERIDIEM_POST_ONLY) != 0;
        bool brief_meridiem = (flags & PrettyFlag.BRIEF_MERIDIEM) != 0;
        
        // TODO: localize all this
        
        unowned string pm = brief_meridiem ? "p" : "pm";
        unowned string am = brief_meridiem ? "a" : "am";
        
        unowned string meridiem;
        if (meridiem_post_only)
            meridiem = is_pm ? pm : "";
        else
            meridiem = is_pm? pm : am;
        
        if (optional_min && minute == 0)
            return "%d%s".printf(12hour, meridiem);
        
        if (!include_sec)
            return "%d:%02d%s".printf(12hour, minute, meridiem);
        
        return "%d:%02d:%02d%s".printf(12hour, minute, second, meridiem);
    }
    
    public int compare_to(WallTime other) {
        if (this == other)
            return 0;
        
        int diff = hour - other.hour;
        if (diff != 0)
            return diff;
        
        diff = minute - other.minute;
        if (diff != 0)
            return diff;
        
        return second - other.second;
    }
    
    public bool equal_to(WallTime other) {
        return compare_to(other) == 0;
    }
    
    public uint hash() {
        // since each unit is >= 60, give each 6 bits (2^6 = 64) of space
        return ((uint) hour << 12) | ((uint) minute << 6) | (uint) second;
    }
    
    public override string to_string() {
        return to_pretty_string(PrettyFlag.INCLUDE_SECONDS);
    }
}

}

