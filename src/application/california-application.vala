/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

extern const string PACKAGE_VERSION;
extern const string GETTEXT_PACKAGE;
extern const string PREFIX;

namespace California {

/**
 * The main California application object.
 */

public class Application : Gtk.Application {
    public const string TITLE = _("California");
    public const string DESCRIPTION = _("Desktop Calendar");
    public const string COPYRIGHT = _("Copyright 2014 Yorba Foundation");
    public const string VERSION = PACKAGE_VERSION;
    public const string WEBSITE_NAME = _("Visit California's home page");
    public const string WEBSITE_URL = "https://wiki.gnome.org/Apps/California";
    public const string ID = "org.yorba.california";
    public const string ICON_NAME = "x-office-calendar";
    
    public const string AUTHORS[] = {
        "Jim Nelson <jim@yorba.org>",
        null
    };
    
    public const string ACTION_CALENDAR_MANAGER = "app.calendar-manager";
    public const string ACTION_ABOUT = "app.about";
    public const string ACTION_QUIT = "app.quit";
    
    private static Application? _instance = null;
    public static Application instance {
        get {
            return (_instance != null) ? _instance : _instance = new Application();
        }
    }
    
    private static const ActionEntry[] action_entries = {
        { "calendar-manager", on_calendar_manager },
        { "about", on_about },
        { "quit", on_quit }
    };
    
    private Host.MainWindow? main_window = null;
    private File? exec_file = null;
    
    private Application() {
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
        
        // prep gettext before initialize various units
        Intl.setlocale(LocaleCategory.ALL, "");
        Intl.bindtextdomain(GETTEXT_PACKAGE,
            File.new_for_path(PREFIX).get_child("share").get_child("locale").get_path());
        Intl.bind_textdomain_codeset(GETTEXT_PACKAGE, "UTF-8");
        Intl.textdomain(GETTEXT_PACKAGE);
        
        // unit initialization
        try {
            Host.init();
            Manager.init();
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
        
        // unit termination
        Manager.terminate();
        Host.terminate();
        
        base.shutdown();
    }
    
    // This method is invoked when the primary instance is first started or is activated by a
    // secondary instance.  It is called after startup().
    public override void activate() {
        if (main_window == null) {
            main_window = new Host.MainWindow(this);
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
    
    private void on_calendar_manager() {
        Manager.Window.display(main_window);
    }
    
    private void on_about() {
        Gtk.show_about_dialog(main_window,
            "program-name", TITLE,
            "comments", DESCRIPTION,
            "authors", AUTHORS,
            "copyright", COPYRIGHT,
            "license-type", Gtk.License.LGPL_2_1,
            "version", VERSION,
            "title", _("About %s").printf(TITLE),
            "logo-icon-name", ICON_NAME,
            "website", WEBSITE_URL,
            "website-label", WEBSITE_NAME,
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

