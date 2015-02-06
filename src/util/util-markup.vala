/* Copyright 2014-2015 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Markup {

/**
 * Given a URI, return the prefix markup and the postfix markup as strings.
 *
 * known_protocol indicates the URI has a well-known protocol (i.e. http:// or ftp://, etc.)
 *
 * markup can hold a new string that is placed in between the pre- and post-markup strings.  If
 * null or an empty string is returned, uri will be used.
 *
 * Returns false if the uri should not be included in the string returned by {@link linkify}.  To
 * leave a URI bare, return null for pre_markup, post_markup, and new_uri.
 */
public delegate bool LinkifyDelegate(string uri, bool known_protocol, out string? pre_markup,
    out string? markup, out string? post_markup);

// Regex to detect URIs.
// Originally from https://gist.github.com/gruber/249502
// See http://daringfireball.net/2010/07/improved_regex_for_matching_urls for note on earlier version
// of this regex.
private const string URI_REGEX = """(?i)\b((?:[a-z][\w-]+:(?:/{1,3}|[a-z0-9%])|www\d{0,3}[.]|[a-z0-9.\-]+[.][a-z]{2,4}/)(?:[^\s()<>]+|\(([^\s()<>]+|(\([^\s()<>]+\)))*\))+(?:\(([^\s()<>]+|(\([^\s()<>]+\)))*\)|[^\s`!()\[\]{};:'".,<>?«»“”‘’]))""";

// Regex to determine if a URI has a well-known protocol.
private const string PROTOCOL_REGEX = "^(aim|apt|bitcoin|cvs|ed2k|ftp|file|finger|git|gtalk|http|https|irc|ircs|irc6|lastfm|ldap|ldaps|magnet|mailto|news|nntp|rsync|sftp|skype|smb|sms|svn|telnet|tftp|ssh|webcal|xmpp):";

private Regex uri_regex;
private Regex protocol_regex;

/**
 * Called by Util.init()
 */
internal void init() throws Error {
    uri_regex = new Regex(URI_REGEX, RegexCompileFlags.CASELESS | RegexCompileFlags.OPTIMIZE);
    protocol_regex = new Regex(PROTOCOL_REGEX, RegexCompileFlags.CASELESS | RegexCompileFlags.OPTIMIZE);
}

/**
 * Called by Util.terminate()
 */
internal void terminate() {
    uri_regex = null;
    protocol_regex = null;
}

/**
 * Replace all the URIs in a string with link markup provided by {@link LinkifyDelegate}.
 *
 * NOTE: linkify() is not thread-safe.
 */
public string? linkify(string? unlinked, LinkifyDelegate linkify_cb) {
    if (String.is_empty(unlinked))
        return unlinked;
    
    try {
        return uri_regex.replace_eval(unlinked, -1, 0, 0, (match_info, result) => {
            // match zero is the only match we're interested in
            string? uri = match_info.fetch(0);
            if (String.is_empty(uri))
                return false;
            
            // have original caller provide markup (or drop the URL)
            string? pre_markup, markup, post_markup;
            if (!linkify_cb(uri, protocol_regex.match(uri), out pre_markup, out markup, out post_markup))
                return false;
            
            // put it all together
            result.append_printf("%s%s%s",
                (pre_markup != null) ? pre_markup : "",
                String.is_empty(markup) ? uri : markup,
                (post_markup != null) ? post_markup : ""
            );
            
            return false;
        });
    } catch (RegexError rerr) {
        debug("Unable to linkify string: %s", rerr.message);
        
        return unlinked;
    }
}

}

