/* Copyright 2014-2015 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Collection {

/**
 * A remove-only stack of elements that allows for marking (saving state) and restoration.
 *
 * To make saving and restoring as efficient as possible, additions are not possible with this
 * collection.  The stack is initialized with elements in the constructor.  Thereafter, elements
 * may only be {@link pop}ped and elements added back via {@link restore}.
 */

public class LookaheadStack<G> : BaseObject {
    /**
     * Returns true if no elements are in the queue.
     */
    public bool is_empty { get { return stack.is_empty; } }
    
    /**
     * Returns the number of elements remaining in the stack.
     */
    public int size { get { return stack.size; } }
    
    /**
     * Returns number of saved markpoints.
     *
     * @see mark
     */
    public int markpoint_count { get { return markpoints.size + (markpoint != null ? 1 : 0); } }
    
    /**
     * Returns the current element at the top of the stack.
     */
    public G? top { owned get { return stack.peek_head(); } }
    
    private Gee.Deque<G> stack;
    private Gee.Deque<Gee.Deque<G>>? markpoints;
    private Gee.Deque<G>? markpoint = null;
    
    public LookaheadStack(Gee.Collection<G> init) {
        // must be initialized here; see
        // https://bugzilla.gnome.org/show_bug.cgi?id=523767
        stack = new Gee.LinkedList<G>();
        stack.add_all(init);
        
        markpoints = new Gee.LinkedList<Gee.Deque<G>>();
    }
    
    /**
     * Returns null if empty.
     */
    public G? pop() {
        if (stack.is_empty)
            return null;
        
        G element = stack.poll_head();
        
        // if markpoint set, save element for later
        if (markpoint != null)
            markpoint.offer_head(element);
        
        return element;
    }
    
    /**
     * Marks the state of the stack so it can be restored with {@link restore}.
     *
     * Multiple markpoints can be made, each requiring a matching {@link restore} to return to the
     * state.
     */
    public void mark() {
        if (markpoint != null)
            markpoints.offer_head(markpoint);
        
        markpoint = new Gee.LinkedList<G>();
    }
    
    /**
     * Restores the state of the stack to the point when the last markpoint was made.
     *
     * This does nothing if {@link mark} was not first called.
     */
    public void restore() {
        if (markpoint != null) {
            // restore elements as stored in marked queue
            while (!markpoint.is_empty)
                stack.offer_head(markpoint.poll_head());
        }
        
        // pop last marked state, if any, as the current marked state
        pop_markpoint();
    }
    
    /**
     * Drops the last markpoint, if any.
     *
     * This is functionally equivalent to {@link restore}, but the current markpoint elements are
     * not added back to the stack.  Prior markpoints remain.
     *
     * @see mark
     */
    public void unmark() {
        pop_markpoint();
    }
    
    /**
     * Drops all markpoints.
     *
     * @see mark
     */
    public void clear_markpoints() {
        markpoint = null;
        markpoints.clear();
    }
    
    private void pop_markpoint() {
        if (!markpoints.is_empty)
            markpoint = markpoints.poll_head();
        else
            markpoint = null;
    }
    
    public override string to_string() {
        return "LookaheadStack (%d elements)".printf(size);
    }
}

}

