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
    public string title { get; private set; }
    
    protected Source(string title) {
        this.title = title;
    }
    
    public override string to_string() {
        return title;
    }
}

}

