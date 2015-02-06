/* Copyright 2014-2015 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Calendar {

/**
 * Represents a calendar date ordering, usually locale-dependent.
 */

public enum DateOrdering {
    DMY,
    MDY,
    YMD,
    YDM,
    
    /**
     * Default date ordering (usually used when cannot be determined programmatically).
     *
     * The assumption here is that DMY is more common than any other (in terms of general usage).
     */
    DEFAULT = DMY;
    
    public string to_string() {
        switch (this) {
            case DMY:
                return "DMY";
            
            case MDY:
                return "MDY";
            
            case YMD:
                return "YMD";
            
            case YDM:
                return "YDM";
            
            default:
                assert_not_reached();
        }
    }
}

}

