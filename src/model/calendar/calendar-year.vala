/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Calendar {

/**
 * An immutable representation of a calendar year.
 *
 * Because of limitations in GLib's Date representation, years before 1 are unsupported.  Maximum
 * value is described as thousands of years from now.
 */

public class Year : SimpleValue {
    public Year(int value) {
        base (value, 1, int.MAX);
    }
    
    internal Year.from_gdate(GLib.Date gdate) {
        base (gdate.get_year(), 1, int.MAX);
    }
    
    public static Year current(TimeZone tz = new TimeZone.local()) {
        DateTime now = new DateTime.now(tz);
        
        return new Year(now.get_year());
    }
    
    internal inline DateYear to_date_year() {
        return (DateYear) value;
    }
}

}

