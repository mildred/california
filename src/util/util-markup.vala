/* Copyright 2014 Yorba Foundation
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
 * Returns false if the uri should not be included in the string returned by {@link linkify}.  To
 * leave a URI bare, return null for both strings and return true.
 */
public delegate bool LinkifyDelegate(string uri, bool known_protocol, out string? pre_markup,
    out string? post_markup);

// Regex to detect URLs.
// Originally from http://daringfireball.net/2010/07/improved_regex_for_matching_urls
private const string URL_REGEX = "(?i)\\b((?:[a-z][\\w-]+:(?:/{1,3}|[a-z0-9%])|www\\d{0,3}[.]|[a-z0-9.\\-]+[.][a-z]{2,4}/)(?:[^\\s()<>]+|\\(([^\\s()<>]+|(\\([^\\s()<>]+\\)))*\\))+(?:\\(([^\\s()<>]+|(\\([^\\s()<>]+\\)))*\\)|[^\\s`!()\\[\\]{};:'\".,<>?«»“”‘’]))";

// Regex to determine if a URL has a known protocol.
private const string PROTOCOL_REGEX = "^(aim|apt|bitcoin|cvs|ed2k|ftp|file|finger|git|gtalk|http|https|irc|ircs|irc6|lastfm|ldap|ldaps|magnet|news|nntp|rsync|sftp|skype|smb|sms|svn|telnet|tftp|ssh|webcal|xmpp):";

private Regex url_regex;
private Regex protocol_regex;

/**
 * Called by Util.init()
 */
internal void init() throws Error {
    url_regex = new Regex(URL_REGEX, RegexCompileFlags.CASELESS | RegexCompileFlags.OPTIMIZE);
    protocol_regex = new Regex(PROTOCOL_REGEX, RegexCompileFlags.CASELESS | RegexCompileFlags.OPTIMIZE);
}

/**
 * Called by Util.terminate()
 */
internal void terminate() {
    url_regex = null;
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
        return url_regex.replace_eval(unlinked, -1, 0, 0, (match_info, result) => {
            // match zero is the only match we're interested in
            string? url = match_info.fetch(0);
            if (String.is_empty(url))
                return false;
            
            // have original caller provide markup (or drop the URL)
            string? pre_markup, post_markup;
            if (!linkify_cb(url, protocol_regex.match(url), out pre_markup, out post_markup))
                return false;
            
            // put it all together
            result.append_printf("%s%s%s",
                (pre_markup != null) ? pre_markup : "",
                url,
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

