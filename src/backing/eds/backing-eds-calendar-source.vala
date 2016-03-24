/* Copyright 2014-2015 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Backing {

/**
 * An interface to an EDS calendar source.
 */

internal class EdsCalendarSource : CalendarSource {
    private const int UPDATE_DELAY_MSEC = 500;
    
    internal E.Source eds_source;
    internal E.SourceCalendar eds_calendar;
    
    private E.SourceWebdav? webdav;
    private E.CalClient? client = null;
    private Scheduled? scheduled_source_write = null;
    private Scheduled? scheduled_source_read = null;
    private Gee.HashSet<string> dirty_read_properties = new Gee.HashSet<string>();
    private Cancellable? source_write_cancellable = null;
    
    public EdsCalendarSource(EdsStore store, E.Source eds_source, E.SourceCalendar eds_calendar) {
        base (store, eds_source.uid, eds_source.display_name);
        
        this.eds_source = eds_source;
        this.eds_calendar = eds_calendar;
        webdav = eds_source.get_extension(E.SOURCE_EXTENSION_WEBDAV_BACKEND) as E.SourceWebdav;
        
        // read-only until opened, when state can be determined from client
        read_only = true;
        
        // can't bind directly because EDS sometimes updates its properties in background threads
        // and our code expects change notifications to only occur in main thread, so schedule
        // those notifications in the main loop
        eds_source.notify["display-name"].connect(on_schedule_source_property_read);
        eds_calendar.notify["selected"].connect(on_schedule_source_property_read);
        eds_calendar.notify["color"].connect(on_schedule_source_property_read);
        if (webdav != null)
            webdav.notify["calendar-auto-schedule"].connect(on_schedule_source_property_read);
        
        // ...and initialize
        title = eds_source.display_name;
        visible = eds_calendar.selected;
        color = eds_calendar.color;
        is_local = eds_calendar.backend_name == "local";
        is_removable = eds_source.removable;
        if (webdav != null)
            server_sends_invites = webdav.calendar_auto_schedule;
        
        // when changed within the app, need to write it back out
        notify[PROP_TITLE].connect(on_title_changed);
        notify[PROP_VISIBLE].connect(on_visible_changed);
        notify[PROP_COLOR].connect(on_color_changed);
        notify[PROP_SERVER_SENDS_INVITES].connect(on_server_sends_invites_changed);
        
        // see note in open_async() about setting the "mailbox" property
    }
    
    ~EdsCalendarSource() {
        // wait for writes to be flushed out, but don't bother doing the same for reads
        if (scheduled_source_write != null)
            scheduled_source_write.wait();
        
        // TODO: May need to have these connections happen under open/close to protect against
        // race conditions, i.e. disconnecting while the property notification is occurring,
        // meaning the scheduled callback may still occur after dtor exits
        eds_source.notify["display-name"].disconnect(on_schedule_source_property_read);
        eds_calendar.notify["selected"].disconnect(on_schedule_source_property_read);
        eds_calendar.notify["color"].disconnect(on_schedule_source_property_read);
        if (webdav != null)
            webdav.notify["calendar-auto-schedule"].disconnect(on_schedule_source_property_read);
        
        // although disconnected, for safety cancel under lock
        lock (dirty_read_properties) {
            scheduled_source_read = null;
        }
    }
    
    private void on_schedule_source_property_read(Object object, ParamSpec pspec) {
        // schedule the property read in the main (UI) loop so notifications of this object's
        // properties happen there and not in a background thread ... note that lock for
        // dirty_read_properties is used for both hash set and Scheduled
        lock (dirty_read_properties) {
            dirty_read_properties.add(pspec.name);
            scheduled_source_read = new Scheduled.once_at_idle(on_read_properties);
        }
    }
    
    private void on_read_properties() {
        // make copy under lock and key
        Gee.HashSet<string> copy = new Gee.HashSet<string>();
        lock (dirty_read_properties) {
            copy.add_all(dirty_read_properties);
            dirty_read_properties.clear();
        }
        
        // update locally outside of lock
        foreach (string name in copy) {
            debug("EDS updated %s property %s", to_string(), name);
            
            switch (name) {
                case "display-name":
                    title = eds_source.display_name;
                break;
                
                case "selected":
                    visible = eds_calendar.selected;
                break;
                
                case "color":
                    color = eds_calendar.color;
                break;
                
                case "calendar-auto-schedule":
                    if (webdav != null)
                        server_sends_invites = webdav.calendar_auto_schedule;
                break;
            }
        }
    }
    
    private void on_title_changed() {
        // on schedule write if something changed
        if (eds_source.display_name == title)
            return;
        
        eds_source.display_name = title;
        schedule_source_write("title=%s".printf(title));
    }
    
    private void on_visible_changed() {
        // only schedule source writes if something actually changed
        if (eds_calendar.selected == visible)
            return;
        
        eds_calendar.selected = visible;
        schedule_source_write("visible=%s".printf(visible.to_string()));
    }
    
    private void on_color_changed() {
        // only schedule writes if something changed
        if (eds_calendar.color == color)
            return;
        
        eds_calendar.color = color;
        schedule_source_write("color=%s".printf(color));
    }
    
    private void on_server_sends_invites_changed() {
        if (webdav == null || webdav.calendar_auto_schedule == server_sends_invites)
            return;
        
        webdav.calendar_auto_schedule = server_sends_invites;
        schedule_source_write("server_sends_invites=%s".printf(server_sends_invites.to_string()));
    }
    
    private void schedule_source_write(string reason) {
        debug("Scheduling update of %s due to %s...", to_string(), reason);
        
        // cancel an outstanding write
        if (source_write_cancellable != null)
            source_write_cancellable.cancel();
        source_write_cancellable = new Cancellable();
        
        scheduled_source_write = new Scheduled.once_after_msec(UPDATE_DELAY_MSEC,
            () => on_background_write_source_async.begin(), Priority.LOW);
    }
    
    private async void on_background_write_source_async() {
        Cancellable? cancellable = source_write_cancellable;
        source_write_cancellable = null;
        
        if (cancellable == null || cancellable.is_cancelled())
            return;
        
        try {
            debug("Updating EDS source %s...", to_string());
            yield eds_source.write(cancellable);
            debug("Updated EDS source %s", to_string());
        } catch (Error err) {
            debug("Error updating EDS source %s: %s", to_string(), err.message);
        }
    }
    
    private string? get_webdav_email() {
        if (webdav == null)
            return null;
        
        // watch for empty and malformed strings
        if (String.is_empty(webdav.email_address) || !Email.is_valid_mailbox(webdav.email_address))
            return null;
        
        debug("WebDAV email for %s: %s", to_string(), webdav.email_address);
        
        return webdav.email_address;
    }
    
    // Can only be called after open_async() has been called
    private string? get_backend_email(Cancellable? cancellable) {
        try {
            string mailbox_string;
            client.get_backend_property_sync(E.CAL_BACKEND_PROPERTY_CAL_EMAIL_ADDRESS, out mailbox_string,
                cancellable);
            if (!String.is_empty(mailbox_string)) {
                debug("Using backend email for %s: %s", to_string(), mailbox_string);
                
                return mailbox_string;
            }
        } catch (Error err) {
            debug("Unable to fetch calendar email from backend for %s: %s", to_string(), err.message);
        }
        
        return null;
    }
    
    private string? get_authentication_email(string? calendar_domain, string? email_domain) {
        E.SourceAuthentication? auth = eds_source.get_extension(E.SOURCE_EXTENSION_AUTHENTICATION)
            as E.SourceAuthentication;
        if (auth == null)
            return null;
        
        // watch for empty string
        if (String.is_empty(auth.user))
            return null;
        
        // if email address, use that
        if (Email.is_valid_mailbox(auth.user)) {
            debug("Using authentication email for %s: %s", to_string(), auth.user);
            
            return auth.user;
        }
        
        // if calendar is on a known service, try tacking on email_domain, but only if both spec'd
        if (calendar_domain == null || email_domain == null)
            return null;
        
        // ... but this only works if an at-sign isn't already present in the username
        if (auth.user.contains("@"))
            return null;
        
        if (auth.host != calendar_domain && !auth.host.has_suffix("." + calendar_domain))
            return null;
        
        string manufactured = "%s%s".printf(auth.user, email_domain);
        if (!Email.is_valid_mailbox(manufactured))
            return null;
        
        debug("Manufactured email for %s: %s", to_string(), manufactured);
        
        return manufactured;
    }
    
    // Invoked by EdsStore prior to making it available outside of unit
    internal async void open_async(Cancellable? cancellable) throws Error {
        client = (E.CalClient) yield E.CalClient.connect(eds_source, E.CalClientSourceType.EVENTS, 1,
            cancellable);
        
        client.bind_property("readonly", this, PROP_READONLY, BindingFlags.SYNC_CREATE);
        client.notify["readonly"].connect(() => {
            debug("%s readonly: %s", to_string(), client.readonly.to_string());
        });
        
        
        //
        // Unfortunately, obtaining an email address associated with a calendar is not guaranteed
        // in a lot of ways with EDS, so use an approach that looks for it in the most likely
        // places .. one approach has to wait until open_async() is called.  First location with
        // valid email wins.
        //
        // Ordering:
        // * WebDAV extension's email address
        // * Use backend extension's email address
        // * Authentication username (if valid email address)
        // * Same with Google, but appending "@gmail.com" if a plain username (i.e.
        //   "alice" -> "alice@gmail.com")
        // * TODO: Same with Yahoo! Calendar, when supported
        //
        mailbox = get_webdav_email();
        if (mailbox == null)
            mailbox = get_backend_email(cancellable);
        if (mailbox == null)
            mailbox = get_authentication_email(null, null);
        if (mailbox == null)
            mailbox = get_authentication_email("google.com", "@gmail.com");
    }
    
    // Invoked by EdsStore when closing and dropping all its refs
    internal async void close_async(Cancellable? cancellable) throws Error {
        // no close -- just drop the ref
        client = null;
        read_only = true;
    }
    
    private void check_open() throws BackingError {
        if (client == null)
            throw new BackingError.UNAVAILABLE("%s has been removed", to_string());
    }
    
    public override async CalendarSourceSubscription subscribe_async(Calendar.ExactTimeSpan window,
        Cancellable? cancellable = null) throws Error {
        check_open();
        
        // construct s-expression describing the CalClientView's purview
        string sexp = "occur-in-time-range? (make-time \"%s\") (make-time \"%s\")".printf(
            E.isodate_from_time_t(window.start_exact_time.to_time_t()),
            E.isodate_from_time_t(window.end_exact_time.to_time_t()));
        
        E.CalClientView view;
        yield client.get_view(sexp, cancellable, out view);
        
        return new EdsCalendarSourceSubscription(this, window, view, sexp);
    }
    
    public override async Component.UID? create_component_async(Component.Instance instance,
        Cancellable? cancellable = null) throws Error {
        check_open();
        
        string? uid;
        yield client.create_object(instance.ical_component, cancellable, out uid);
        
        return !String.is_empty(uid) ? new Component.UID(uid) : null;
    }
    
    public override async void update_component_async(Component.Instance instance,
        Cancellable? cancellable = null) throws Error {
        check_open();
        
        E.CalObjModType modtype =
            instance.can_generate_instances ? E.CalObjModType.ALL : E.CalObjModType.THIS;
        
        yield client.modify_object(instance.ical_component, modtype, cancellable);
    }
    
    public override async void remove_all_instances_async(Component.UID uid,
        Cancellable? cancellable = null) throws Error {
        check_open();
        
        yield client.remove_object(uid.value, null, E.CalObjModType.ALL, cancellable);
    }
    
    public override async void remove_instances_async(Component.UID uid, Component.DateTime rid,
        CalendarSource.AffectedInstances affected, Cancellable? cancellable = null) throws Error {
        check_open();
        
        // Note that E.CalObjModType.ONLY_THIS is *never* used ... examining EDS source code,
        // it appears in e-cal-backend-file.c that ONLY_THIS merely removes the instance but does not
        // include an EXDATE in the original iCal source ... I don't quite understand the benefit of
        // this, as this suggests (a) other calendar clients won't learn of the removal and (b) the
        // instance will be re-generated the next time the user runs an EDS calendar client.  In
        // either case, THIS maps to our desired effect by adding an EXDATE to the iCal source.
        switch (affected) {
            case CalendarSource.AffectedInstances.THIS:
                yield client.remove_object(uid.value, rid.value, E.CalObjModType.THIS, cancellable);
            break;
            
            case CalendarSource.AffectedInstances.THIS_AND_FUTURE:
                yield remove_this_and_future_async(uid, rid, cancellable);
            break;
            
            case CalendarSource.AffectedInstances.ALL:
                yield remove_all_instances_async(uid, cancellable);
            break;
            
            default:
                assert_not_reached();
        }
    }
    
    private async void remove_this_and_future_async(Component.UID uid, Component.DateTime rid,
        Cancellable? cancellable) throws Error {
        // get the master instance ... remember that the Backing.CalendarSource only stores generated
        // instances
        iCal.icalcomponent ical_component;
        yield client.get_object(uid.value, null, cancellable, out ical_component);
        
        // change the RRULE's UNTIL indicating the end of the recurring set (which is, handily enough,
        // the RID)
        unowned iCal.icalproperty? rrule_property = ical_component.get_first_property(
            iCal.icalproperty_kind.RRULE_PROPERTY);
        if (rrule_property == null)
            return;
        
        iCal.icalrecurrencetype rrule = rrule_property.get_rrule();
        
        // In order to be inclusive, need to set UNTIL one tick earlier to ensure the supplied RID
        // is now excluded
        if (rid.is_date) {
            Component.date_to_ical(rid.to_date().previous(), &rrule.until);
        } else {
            Component.exact_time_to_ical(rid.to_exact_time().adjust_time(-1, Calendar.TimeUnit.SECOND),
                &rrule.until);
        }
        
        // COUNT and UNTIL are mutually exclusive in an RRULE ... COUNT can be reliably reset
        // because the RID enforces a new de facto COUNT (assuming the RID originated from the UID's
        // recurring instance; if not, the user has screwed up)
        rrule.count = 0;
        
        rrule_property.set_rrule(rrule);
        
        // write it out ... essentially, this style of remove is actually an update
        yield client.modify_object(ical_component, E.CalObjModType.THIS, cancellable);
    }
    
    public override async void import_icalendar_async(Component.iCalendar ical, Cancellable? cancellable = null)
        throws Error {
        check_open();
        
        yield client.receive_objects(ical.ical_component, cancellable);
    }
}

}

