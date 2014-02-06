/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Component {

/**
 * The VTYPE of the {@link Component}.
 *
 * See [[https://tools.ietf.org/html/rfc5545#section-8.3.1]]
 */

public enum VType {
    EVENT;
    
    internal iCal.icalcomponent_kind to_kind() {
        switch (this) {
            case EVENT:
                return iCal.icalcomponent_kind.VEVENT_COMPONENT;
            
            default:
                assert_not_reached();
        }
    }
}

}

