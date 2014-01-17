/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Component {

/**
 * An iCalendar component that has a definitive instance within a calendar.
 *
 * By "instance", this means {@link Event}s, To-Do's, Journals, and Free/Busy components.
 * Alarms are contained within Instance components, and TimeZones are handled separately.
 */

public abstract class Instance : BaseObject {
    /**
     * The date-time stamp of the {@link Instance}.
     *
     * See [[https://tools.ietf.org/html/rfc5545#section-3.8.7.2]]
     */
    public DateTime dtstamp { get; private set; }
    
    /**
     * The {@link UID} of the {@link Instance}.
     */
    public UID uid { get; private set; }
    
    private string desc;
    
    protected Instance(UID uid, DateTime dtstamp, string desc) {
        this.uid = uid;
        this.dtstamp = dtstamp;
        this.desc = desc;
    }
    
    public override string to_string() {
        return desc;
    }
}

}

