/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Calendar {

/**
 * An immutable representation of a calendar year.
 */

public class Year : BaseObject {
    public int value { get; private set; }
    
    public Year(int value) {
        this.value = value;
    }
    
    public inline DateYear to_date_year() {
        return (DateYear) value;
    }
    
    public override string to_string() {
        return value.to_string();
    }
}

}

