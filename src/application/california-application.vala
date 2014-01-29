/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

extern const string PACKAGE_VERSION;

namespace California {

/**
 * The main California application object.
 */

public class Application : Gtk.Application {
    public const string TITLE = "California";
    public const string DESCRIPTION = _("Desktop Calendar");
    public const string COPYRIGHT = _("Copyright 2014 Yorba Foundation");
    public const string VERSION = PACKAGE_VERSION;
    public const string ID = "org.yorba.california";
    
    public const string AUTHORS[] = {
        "Jim Nelson <jim@yorba.org>",
        null
    };
    
    private static const ActionEntry[] action_entries = {
        { "about", on_about },
        { "quit", on_quit }
    };
    
    private MainWindow? main_window = null;
    private File? exec_file = null;
    
    public Application() {
        Object (application_id: ID);
    }
    
    // This method is executed from run() every time.
    public override bool local_command_line(ref unowned string[] args, out int exit_status) {
        exec_file = File.new_for_path(Posix.realpath(Environment.find_program_in_path(args[0])));
        
        try {
            register();
        } catch (Error err) {
            error("Error registering application: %s", err.message);
        }
        
        activate();
        
        exit_status = 0;
        
        return true;
    }
    
    // This method is invoked when the primary instance is first started.
    public override void startup() {
        base.startup();
        
        // internal unit initialization
        try {
            MainWindow.init();
        } catch (Error err) {
            error_message(_("Unable to open California: %s").printf(err.message));
            quit();
        }
        
        add_action_entries(action_entries, this);
        set_app_menu(Resource.load<MenuModel>("app-menu.interface", "app-menu"));
    }
    
    // This method is invoked when the main loop terminates on the primary instance.
    public override void shutdown() {
        main_window.destroy();
        main_window = null;
        
        // internal unit termination
        MainWindow.terminate();
        
        base.shutdown();
    }
    
    // This method is invoked when the primary instance is first started or is activated by a
    // secondary instance.  It is called after startup().
    public override void activate() {
        if (main_window == null) {
            main_window = new MainWindow(this);
            main_window.show_all();
        }
        
        main_window.present();
        
        base.activate();
    }
    
    // Presents a modal error dialog to the user
    public void error_message(string msg) {
        Gtk.MessageDialog dialog = new Gtk.MessageDialog(main_window, Gtk.DialogFlags.MODAL,
            Gtk.MessageType.ERROR, Gtk.ButtonsType.OK, "%s", msg);
        dialog.run();
        dialog.destroy();
    }
    
    private void on_about() {
        // TODO: "website"
        // TODO: "website-label"
        Gtk.show_about_dialog(main_window,
            "program-name", TITLE,
            "comments", DESCRIPTION,
            "authors", AUTHORS,
            "copyright", COPYRIGHT,
            "license-type", Gtk.License.LGPL_2_1,
            "version", VERSION,
            "title", _("About %s").printf(TITLE),
            /// Translators: add your name and email address to receive credit in the About dialog
            /// For example: Yamada Taro <yamada.taro@example.com>
            "translator-credits", _("translator-credits")
        );
    }
    
    private void on_quit() {
        quit();
    }
}

}

