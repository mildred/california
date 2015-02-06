/* Copyright 2014-2015 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Commandline {

private const string PARAMS = _("[.ics FILE...]");

public bool show_version = false;
public Gee.List<string>? files = null;

private const OptionEntry[] options = {
    { "version", 'V', 0, OptionArg.NONE, ref show_version, N_("Display program version"), null },
    { null }
};

/**
 * Parse the command-line and process the obvious options, converting the remaining to options
 * which are used by the remainder of the application.
 *
 * Returns false if the process should exit with the returned exit code.
 */
public bool parse(string[] args, out int exitcode) {
    OptionContext context = new OptionContext(PARAMS);
    context.set_help_enabled(true);
    context.add_main_entries(options, null);
    context.set_summary(Application.DESCRIPTION);
    context.set_description("%s\n\n%s\n\t%s\n\n%s\n\t%s\n".printf(
        Application.COPYRIGHT,
        _("To log debug to standard out:"),
        _("$ G_MESSAGES_DEBUG=all california"),
        _("Please report problems and requests to:"),
        Application.BUGREPORT_URL));
    
    try {
        context.parse(ref args);
    } catch (OptionError opterr) {
        stdout.printf(_("Unknown options: %s\n").printf(opterr.message));
        stdout.printf("\n%s".printf(context.get_help(true, null)));
        
        exitcode = 1;
        
        return false;
    }
    
    // convert remaining arguments into files (although note that no sanity checking is
    // performed)
    for (int ctr = 1; ctr < args.length; ctr++) {
        if (files == null)
            files = new Gee.ArrayList<string>();
        
        files.add(args[ctr]);
    }
    
    exitcode = 0;
    
    if (show_version) {
        stdout.printf("%s %s\n", Application.TITLE, Application.VERSION);
        
        return false;
    }
    
    return true;
}

}

