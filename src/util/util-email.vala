/* Copyright 2014-2015 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Email {

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
 * Validates a string as a valid RFC822 mailbox (i.e. email) address.
 */
public bool is_valid_mailbox(string str) {
    return email_regex.match(str);
}

/**
 * Generates a valid mailto: as a text string.
 *
 * No validity checking is done here on the mailbox; use {@link is_valid_mailbox}.
 */
public string generate_mailto_text(string mailbox) {
    return "mailto:%s".printf(GLib.Uri.escape_string(mailbox, "@"));
}

/**
 * Generates a valid mailto: Soup.URI given a mailbox (i.e. email) address.
 *
 * No validity checking is done here on the mailbox; use {@link is_valid_mailbox}.
 */
public Soup.URI generate_mailto_uri(string mailbox) throws Error {
    return URI.parse(generate_mailto_text(mailbox));
}

}

