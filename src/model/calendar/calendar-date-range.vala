/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Calendar {

/**
 * Represents an immutable range of {@link Date}s.
 */

public class DateRange : BaseObject {
    /**
     * The start of the {@link DateRange}.
     *
     * start will be chronological prior or equal to {@link end}.
     */
    public Date start { get; private set; }
    
    /**
     * The end of the {@link DateRange}.
     *
     * end will be chronological after or equal to {@link start}.
     */
    public Date end { get; private set; }
    
    /**
     * The range is specified by a start and end.
     *
     * {@link DateRange} will sort the start and end to ensure that start is chronologically prior
     * to end.
     */
    public DateRange(Date start, Date end) {
        if (start.compare_to(end) < 0) {
            this.start = start;
            this.end = end;
        } else {
            this.start = end;
            this.end = start;
        }
    }
    
    public override string to_string() {
        return "%s to %s".printf(start.to_string(), end.to_string());
    }
}

}

