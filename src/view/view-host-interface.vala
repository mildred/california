/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.View {

/**
 * All hosts (view containers) need to implement this interface, giving them a generic interface
 * for a view controller to manipulate.
 *
 * The host is expected to maintain a current date, which can be manipulated through this interface
 * and reports itself via properties.
 */

public interface HostInterface : Object {
    public const string PROP_CURRENT_LABEL = "current-label";
    
    /**
     * A user-visible string representing the current calendar view.
     */
    public abstract string current_label { get; protected set; }
    
    /**
     * Move forward one calendar unit.
     */
    public abstract void next();
    
    /**
     * Move backward one calendar unit.
     */
    public abstract void prev();
    
    /**
     * Jump to calendar unit representing the current date.
     */
    public abstract void today();
}

}

