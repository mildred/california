/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

extern const string PACKAGE_VERSION;

namespace California {

public class Application : Gtk.Application {
    public const string TITLE = "California";
    public const string DESCRIPTION = _("Desktop Calendar");
    public const string COPYRIGHT = "Copyright 2014 Yorba Foundation";
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
            error("Error registering GearyApplication: %s", err.message);
        }
        
        activate();
        
        exit_status = 0;
        
        return true;
    }
    
    // This method is invoked when the primary instance is first started.
    public override void startup() {
        base.startup();
        
        add_action_entries(action_entries, this);
        
        Gtk.Builder builder = new Gtk.Builder();
        try {
            builder.add_from_resource("/org/yorba/california/rc/app-menu.interface");
        } catch (Error err) {
            error("Error loading app-menu resource: %s", err.message);
        }
        
        MenuModel app_menu = (MenuModel) builder.get_object("app-menu");
        set_app_menu(app_menu);
    }
    
    // This method is invoked when the primary instance is first started or is activated by a
    // secondary instance.  It is called after startup().
    public override void activate() {
        if (main_window == null) {
            main_window = new MainWindow(this);
            main_window.show_all();
        } else {
            main_window.present();
        }
        
        base.activate();
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

