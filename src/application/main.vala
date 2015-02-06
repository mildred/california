/* Copyright 2014-2015 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later). See the COPYING file in this distribution.
 */

int main(string[] args) {
    // prep gettext and locale before anything else
    Intl.setlocale(LocaleCategory.ALL, "");
    Intl.bindtextdomain(GETTEXT_PACKAGE,
        File.new_for_path(PREFIX).get_child("share").get_child("locale").get_path());
    Intl.bind_textdomain_codeset(GETTEXT_PACKAGE, "UTF-8");
    Intl.textdomain(GETTEXT_PACKAGE);
    
    return args[1] != "--tests" ? California.Application.instance.run(args) : California.Tests.run(args);
}

