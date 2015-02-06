/* Copyright 2014-2015 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Component {

/**
 * An iCalendar UID.
 *
 * See [[https://tools.ietf.org/html/rfc5545#section-3.8.4.7]]
 */

public class UID : BaseObject, Gee.Hashable<UID>, Gee.Comparable<UID> {
    private static uint32 serial_number = 0;
    
    public string value { get; private set; }
    
    public UID(string value) {
        this.value = value;
    }
    
    public static UID generate() {
        // Borrowed liberally from EDS' e_cal_component_gen_uid
        return new UID("%s-%d-%d-%d-%08X@%s".printf(
            Calendar.System.now.format("%FT%H:%M:%S%z"),
            Posix.getpid(),
            (int) Posix.getgid(),
            (int) Posix.getppid(),
            serial_number++,
            Environment.get_host_name()));
    }
    
    public uint hash() {
        return value.hash();
    }
    
    public bool equal_to(UID other) {
        return compare_to(other) == 0;
    }
    
    /**
     * Compare UIDs for sort order.
     *
     * This is not particularly useful -- there's no notion of ordering for UIDs -- but can be
     * used to stabilize sorts of {@link Instance}s.
     */
    public int compare_to(UID other) {
        return (this != other) ? strcmp(value, other.value) : 0;
    }
    
    public override string to_string() {
        return value;
    }
}

}

