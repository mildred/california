/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Backing {

/**
 * An abstract representation of a backing source of information.
 *
 * @see Manager
 */

public abstract class Source : BaseObject {
    private string desc;
    
    protected Source(string desc) {
        this.desc = desc;
    }
    
    /**
     * Asynchronously open the backing store.
     */
    
    public override string to_string() {
        return desc;
    }
}

}

