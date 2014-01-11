/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Calendar {

/**
 * Represents a simple (unaggregated) immutable calendar value, always an integer.
 */

public abstract class SimpleValue : BaseObject, Gee.Comparable<SimpleValue>, Gee.Hashable<SimpleValue> {
    public int value { get; private set; }
    
    protected SimpleValue(int value, int min, int max) {
        assert(value >= min && value <= max);
        
        this.value = value;
    }
    
    public virtual int compare_to(SimpleValue other) {
        return (this != other) ? value - other.value : 0;
    }
    
    public virtual bool equal_to(SimpleValue other) {
        return (this != other) ? value == other.value : true;
    }
    
    public virtual uint hash() {
        return value;
    }
    
    public override string to_string() {
        return value.to_string();
    }
}

}

