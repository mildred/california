/* Copyright 2014 Yorba Foundation
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
    
    private E.Source eds_source;
    private E.SourceCalendar eds_calendar;
    private E.CalClient? client = null;
    private uint source_write_id = 0;
    private Cancellable? source_write_cancellable = null;
    
    public EdsCalendarSource(E.Source eds_source, E.SourceCalendar eds_calendar) {
        base (eds_source.display_name);
        
        this.eds_source = eds_source;
        this.eds_calendar = eds_calendar;
        
        // use unidirectional bindings so source updates (writing) only occurs when changed from
        // within the app
        eds_calendar.bind_property("selected", this, PROP_VISIBLE, BindingFlags.SYNC_CREATE);
        
        // when changed within the app, need to write it back out
        notify[PROP_VISIBLE].connect(on_visible_changed);
    }
    
    ~EdsCalendarSource() {
        cancel_source_write();
    }
    
    private void on_visible_changed() {
        // only schedule source writes if something actually changed
        if (eds_calendar.selected == visible)
            return;
        
        eds_calendar.selected = visible;
        schedule_source_write("visible=%s".printf(visible.to_string()));
    }
    
    private void schedule_source_write(string reason) {
        cancel_source_write();
        
        debug("Scheduling update of %s due to %s...", to_string(), reason);
        source_write_cancellable = new Cancellable();
        source_write_id = Timeout.add(UPDATE_DELAY_MSEC, on_background_write_source, Priority.LOW);
    }
    
    private void cancel_source_write() {
        if (source_write_id != 0) {
            GLib.Source.remove(source_write_id);
            source_write_id = 0;
        }
        
        if (source_write_cancellable != null) {
            source_write_cancellable.cancel();
            source_write_cancellable = null;
        }
    }
    
    private bool on_background_write_source() {
        // in essence, say this is no longer scheduled ... for now, allow another write to be
        // scheduled while this one is occurring
        source_write_id = 0;
        Cancellable? cancellable = source_write_cancellable;
        source_write_cancellable = null;
        
        if (cancellable == null || cancellable.is_cancelled())
            return false;
        
        try {
            debug("Updating EDS source %s...", to_string());
            // TODO: Fix bindings to use async variant
            eds_source.write_sync(cancellable);
        } catch (Error err) {
            debug("Error updating EDS source %s: %s", to_string(), err.message);
        }
        
        return false;
    }
    
    // Invoked by EdsStore prior to making it available outside of unit
    internal async void open_async(Cancellable? cancellable) throws Error {
        client = (E.CalClient) yield E.CalClient.connect(eds_source, E.CalClientSourceType.EVENTS,
            cancellable);
    }
    
    // Invoked by EdsStore when closing and dropping all its refs
    internal async void close_async(Cancellable? cancellable) throws Error {
        // no close -- just drop the ref
        client = null;
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
        
        return new EdsCalendarSourceSubscription(this, window, view);
    }
    
    public override async Component.UID? create_component_async(Component.Instance instance,
        Cancellable? cancellable = null) throws Error {
        check_open();
        
        // TODO: Fix create_object() bindings so async is possible
        string? uid;
        client.create_object_sync(instance.ical_component, out uid, cancellable);
        
        return !String.is_empty(uid) ? new Component.UID(uid) : null;
    }
    
    public override async void update_component_async(Component.Instance instance,
        Cancellable? cancellable = null) throws Error {
        check_open();
        
        // TODO: Fix modify_object() bindings so async is possible
        client.modify_object_sync(instance.ical_component, E.CalObjModType.THIS, cancellable);
    }
    
    public override async void remove_component_async(Component.UID uid,
        Cancellable? cancellable = null) throws Error {
        check_open();
        
        // TODO: Fix remove_object() bindings so async is possible
        client.remove_object_sync(uid.value, null, E.CalObjModType.THIS, cancellable);
    }
}

}

