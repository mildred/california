/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.String {

public char NUL = '\0';

public inline bool is_empty(string? str) {
    return (str == null) || (str[0] == NUL);
}

public int stricmp(string a, string b) {
    return strcmp(a.casefold(), b.casefold());
}

public uint ci_hash(string str) {
    return str.casefold().hash();
}

public bool ci_equal(string a, string b) {
    return stricmp(a, b) == 0;
}

/**
 * Removes redundant whitespace (including tabs and newlines) and strips whitespace from beginning
 * and end of string.
 */
public string reduce_whitespace(string str) {
    if (str[0] == NUL)
        return str;
    
    StringBuilder builder = new StringBuilder();
    unichar ch;
    unichar last_ch = NUL;
    int index = 0;
    while (str.get_next_char(ref index, out ch)) {
        // if space but last char not NUL (i.e. this is not the first character, a space) and the
        // last char was not a space, append, otherwise drop
        if (ch.isspace()) {
            if (last_ch != NUL && !last_ch.isspace())
                builder.append_unichar(ch);
        } else {
            builder.append_unichar(ch);
        }
        
        last_ch = ch;
    }
    
    return builder.str;
}

/**
 * Returns true if every character in the string is a numeric digit.
 */
public bool is_numeric(string? str) {
    if (is_empty(str))
        return false;
    
    unichar ch;
    int index = 0;
    while (str.get_next_char(ref index, out ch)) {
        if (!ch.isdigit())
            return false;
    }
    
    return true;
}

}

