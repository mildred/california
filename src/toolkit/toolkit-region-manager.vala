/* Copyright 2014-2015 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Toolkit {

/**
 * RegionManager associates Cairo regions with elements of abstract type and provides basic hit
 * detection.
 */

public class RegionManager<G> : BaseObject {
    /**
     * Callback for {@link iterate_hits}.
     *
     * Return false if iterate_hits() should halt iteration.
     */
    public delegate bool HitDetected<G>(G element, Cairo.Region region);
    
    private Gee.HashMap<G, Cairo.Region> regions;
    
    public RegionManager(owned Gee.HashDataFunc<G>? key_hash_func = null, owned Gee.EqualDataFunc<G>? key_equal_func = null) {
        regions = new Gee.HashMap<G, Cairo.Region>(key_hash_func, key_equal_func, region_equal_func);
    }
    
    /**
     * Associate a Cairo.Region with the element.
     *
     * Any regions previously associated with the element are dropped.  This does not expand or
     * contract an existing region.
     */
    public void add_region(G element, Cairo.Region region) {
        regions.set(element, region);
    }
    
    /**
     * Associate a Cairo.Region defined as a rectangle with the element
     *
     * @see add_region
     */
    public void add_rectangle(G element, Cairo.RectangleInt rect) {
        add_region(element, new Cairo.Region.rectangle(rect));
    }
    
    /**
     * Associate a Cairo.Region defined as a set of rectangle points with the element
     *
     * @see add_region
     */
    public void add_points(G element, int x, int y, int width, int height) {
        add_rectangle(element, { x, y, width, height });
    }
    
    /**
     * Unassociated a Cairo.Region from the element.
     *
     * Returns false if the element was unknown to {@link RegionManager}.
     */
    public bool remove_region(G element) {
        return regions.unset(element);
    }
    
    /**
     * Iterate all elements whose regions contain the supplied point.
     *
     * The {@link HitDetected} callback should return true to continue iteration, false to halt it.
     */
    public void iterate_hits(Gdk.Point point, HitDetected<G> hit_detected) {
        // TODO: Obviously there are more sophisticated hit-detection algorithms out there, but
        // this brute-force approach will have to do for now.
        Gee.MapIterator<G, Cairo.Region> iter = regions.map_iterator();
        while (iter.next()) {
            if (iter.get_value().contains_point(point.x, point.y)) {
                if (!hit_detected(iter.get_key(), iter.get_value()))
                    break;
            }
        }
    }
    
    /**
     * Returns a list of elements whose regions contain the supplied point.
     *
     * "Grab air, youse mugs!"
     */
    public Gee.List<G> hit_list(Gdk.Point point) {
        Gee.List<G> list = new Gee.ArrayList<G>();
        iterate_hits(point, (element, region) => {
            list.add(element);
            
            return true;
        });
        
        return list;
    }
    
    private static bool region_equal_func(Cairo.Region a, Cairo.Region b) {
        return a.equal(b);
    }
    
    public override string to_string() {
        return classname;
    }
}

}

