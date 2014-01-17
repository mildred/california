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
    private E.Source eds_source;
    private E.SourceCalendar eds_calendar;
    private E.CalClient? client = null;
    
    public EdsCalendarSource(E.Source eds_source, E.SourceCalendar eds_calendar) {
        base ("E.SourceCalendar \"%s\"".printf(eds_source.display_name));
        
        this.eds_source = eds_source;
        this.eds_calendar = eds_calendar;
    }
    
    // Invoked by EdsStore prior to making it available outside of unit
    internal async void open_async(Cancellable? cancellable) throws Error {
        client = (E.CalClient) yield E.CalClient.connect(eds_source, E.CalClientSourceType.EVENTS,
            cancellable);
    }
    
    // Invoked by EdsStore prior to making it available outside of unit
    internal async void close_async(Cancellable? cancellable) throws Error {
        // no close -- just drop the ref
        client = null;
    }
    
    public override async CalendarSourceSubscription subscribe_async(Calendar.DateSpan window,
        Cancellable? cancellable = null) throws Error {
        if (client == null)
            throw new BackingError.UNAVAILABLE("%s has been removed", to_string());
        
        E.CalClientView view;
        yield client.get_view("", cancellable, out view);
        
        return new EdsCalendarSourceSubscription(this, window, view);
    }
}

}

