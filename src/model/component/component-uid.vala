/* Copyright 2014 Yorba Foundation
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
    public string value { get; private set; }
    
    public UID(string value) {
        this.value = value;
    }
    
    public uint hash() {
        return value.hash();
    }
    
    public bool equal_to(UID other) {
        return (this != other) ? value == other.value : true;
    }
    
    /**
     * Compare UIDs for sort order.
     *
     * This is not particularly useful -- there's no notion of ordering for UIDs -- but can be
     * used to stabilize sorts of {@link Instance}s.
     */
    public int compare_to(UID other) {
        return strcmp(value, other.value);
    }
    
    public override string to_string() {
        return value;
    }
}

}

