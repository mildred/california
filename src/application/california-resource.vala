/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

/**
 * Utility methods to facilitiate loading Resources.
 *
 * These methods assume that the resource must be present for proper operation and so treat hard
 * failures as cause for application termination.
 */

namespace California.Resource {

public const string DEFAULT_PATH = "/org/yorba/california/rc";

private string create_fullpath(string path, string resource) {
    return "%s%s%s".printf(path, path.has_suffix("/") ? "" : "/", resource);
}

/**
 * Loads the resource and returns it as Bytes.
 */
public Bytes load_bytes(string resource_name, string path = DEFAULT_PATH) {
    string fullpath = create_fullpath(path, resource_name);
    
    try {
        return resources_lookup_data(fullpath, ResourceLookupFlags.NONE);
    } catch (Error err) {
        error("Unable to load resource %s: %s", fullpath, err.message);
    }
}

/**
 * Loads the resource, parses it with Gtk.Builder, and returns it as a casted object.
 *
 * Any load error will cause the application to panic.  This generally indicates the resource
 * was not compiled in or that the path is malformed.
 */
public T load_object<T>(string resource_name, string object_name, string path = DEFAULT_PATH) {
    string fullpath = create_fullpath(path, resource_name);
    
    Gtk.Builder builder = new Gtk.Builder();
    try {
        builder.add_from_resource(fullpath);
    } catch (Error err) {
        error("Unable to load resource %s: %s", fullpath, err.message);
    }
    
    Object? object = builder.get_object(object_name);
    if (object == null)
        error("Unable to load object \"%s\" from %s: not found", object_name, fullpath);
    
    if (!object.get_type().is_a(typeof(T)))
        error("Unable to load object \"%s\" from %s: not of type", object_name, fullpath);
    
    return object;
}

}

