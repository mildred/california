/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Component {

/**
 * Primary application window.
 */

public class MainWindow : Gtk.ApplicationWindow {
    public const string PROP_MONTH_OF_YEAR = "month-of-year";
    
    public Calendar.MonthOfYear month_of_year { get; private set; }
    
    private MonthGrid grid = new MonthGrid(null);
    private Gee.ArrayList<Backing.CalendarSourceSubscription> subscriptions = new Gee.ArrayList<
        Backing.CalendarSourceSubscription>();
    
    public MainWindow(Application app) {
        Object (application: app);
        
        title = Application.TITLE;
        set_size_request(800, 600);
        
        notify[PROP_MONTH_OF_YEAR].connect(() => {
            Calendar.DateTimeSpan window = new Calendar.DateTimeSpan.from_date_span(month_of_year,
                new TimeZone.local());
            
            subscriptions.clear();
            foreach (Backing.Store store in Backing.Manager.instance.get_stores()) {
                foreach (Backing.Source source in store.get_sources_of_type(typeof (Backing.CalendarSource))) {
                    Backing.CalendarSource calendar = (Backing.CalendarSource) source;
                    debug("Subscribing to %s...", calendar.to_string());
                    calendar.subscribe_async.begin(window, null, on_subscribed);
                }
            }
        });
        
        // bind the MonthGrid's setting to ours
        bind_property(PROP_MONTH_OF_YEAR, grid, MonthGrid.PROP_MONTH_OF_YEAR);
        
        Gtk.Box layout = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        
        Gtk.ToolButton back = create_button("go-previous-symbolic");
        back.clicked.connect(() => {
            debug("prev");
            month_of_year = month_of_year.adjust(-1);
        });
        
        Gtk.ToolButton fwd = create_button("go-next-symbolic");
        fwd.clicked.connect(() => {
            debug("next");
            month_of_year = month_of_year.adjust(1);
        });
        
        Gtk.Label date_label = new Gtk.Label(null);
        notify[PROP_MONTH_OF_YEAR].connect(() => {
            date_label.label = month_of_year.full_name;
        });
        Gtk.ToolItem date_item = new Gtk.ToolItem();
        date_item.add(date_label);
        
        Gtk.Toolbar toolbar = new Gtk.Toolbar();
        toolbar.add(back);
        toolbar.add(fwd);
        toolbar.add(date_item);
        
        layout.pack_start(toolbar, false, true, 0);
        layout.pack_end(grid, true, true, 0);
        
        add(layout);
        
        // only now set month_of_year so all connected components are updated
        month_of_year = new Calendar.MonthOfYear.now();
    }
    
    private static Gtk.ToolButton create_button(string icon_name) {
        Gtk.Button button = new Gtk.Button();
        button.image = new Gtk.Image.from_icon_name(icon_name, Gtk.IconSize.BUTTON);
        button.always_show_image = true;
        
        return new Gtk.ToolButton(button, null);
    }
    
    private void on_subscribed(Object? source, AsyncResult result) {
        Backing.CalendarSource calendar = (Backing.CalendarSource) source;
        
        try {
            Backing.CalendarSourceSubscription subscription = calendar.subscribe_async.end(result);
            debug("Subscribed to %s", calendar.to_string());
            subscriptions.add(subscription);
            subscription.start();
        } catch (Error err) {
            debug("Unable to subscribe to %s: %s", calendar.to_string(), err.message);
        }
    }
}

}

