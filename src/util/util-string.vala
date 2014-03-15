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

}

