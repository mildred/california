/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

errordomain URIError {
    INVALID
}

/**
 * A collection of URI-related methods.
 */

namespace California.URI {

/**
 * Basic validation of a string intended to be parsed as an absolute URI.
 *
 * If null or an empty array is passed for "supported_schemes", then the only character checked
 * for is the presence of a colon separating the scheme from the remainder of the URI.
 *
 * If "supported_schemes" are specified, then the entire scheme (name and separator) should be
 * included, i.e. "http://", "mailto:", etc.
 */
public bool is_valid(string? uri, string[]? supported_schemes) {
    // strip leading and trailing whitespace
    string? stripped = (uri != null) ? uri.strip() : null;
    if (String.is_empty(stripped))
        return false;
    
    if (supported_schemes == null || supported_schemes.length == 0) {
        if (!stripped.contains(":"))
            return false;
    } else {
        bool found = false;
        foreach (string scheme in supported_schemes) {
            if (stripped.has_prefix(scheme)) {
                found = true;
                
                break;
            }
        }
        
        if (!found)
            return false;
    }
    
    // finally, let Soup.URI decide
    Soup.URI? parsed = new Soup.URI(uri);
    
    return parsed != null;
}

/**
 * Checked creation of a Soup.URI object.
 *
 * This shouldn't be used to create "empty" Soup.URI objects.
 *
 * @throws URIError
 */
public Soup.URI parse(string uri) throws Error {
    Soup.URI? parsed = new Soup.URI(uri);
    if (parsed == null)
        throw new URIError.INVALID("Invalid URI: %s", uri);
    
    return parsed;
}

}

