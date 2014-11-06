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

private Regex email_regex;

internal void init() throws Error {
    // http://www.regular-expressions.info/email.html
    // matches john@dep.aol.museum not john@aol...com
    email_regex = new Regex("[A-Z0-9._%+-]+@(?:[A-Z0-9-]+\\.)+[A-Z]{2,5}", RegexCompileFlags.CASELESS);
}

internal void terminate() {
    email_regex = null;
}

/**
 * Basic validation of a string intended to be parsed as an absolute URI.
 *
 * If null or an empty array is passed for "supported_schemes", then the only character checked
 * for is the presence of a colon separating the scheme from the remainder of the URI.
 *
 * If "supported_schemes" are specified, then the entire scheme (name and separator) should be
 * included, i.e. "http://", "mailto:", etc.
 */
public bool is_valid(string? uri, Gee.Set<string>? supported_schemes) {
    // strip leading and trailing whitespace
    string? stripped = (uri != null) ? uri.strip() : null;
    if (String.is_empty(stripped))
        return false;
    
    // gotta have this, at least
    if (!stripped.contains(":"))
        return false;
    
    if (!traverse<string>(supported_schemes).any(scheme => stripped.has_prefix(scheme)))
        return false;
    
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

/**
 * Validates a string as a valid RFC822 mailbox (i.e. email) address.
 */
public bool is_valid_mailbox(string str) {
    return email_regex.match(str);
}

}

