/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Backing {

/**
 * A calendar subscription to an EDS source.
 */

internal class EdsCalendarSourceSubscription : CalendarSourceSubscription {
    private E.CalClientView view;
    // this is different than "active", which gets set when start completes
    private bool started = false;
    
    // Called from EdsCalendarSource.subscribe_async().  The CalClientView should not be started
    public EdsCalendarSourceSubscription(EdsCalendarSource eds_calendar, Calendar.DateSpan window,
        E.CalClientView view) {
        base (eds_calendar, window);
        
        this.view = view;
    }
    
    public override void start(Cancellable? cancellable) {
        // silently ignore repeated starts
        if (started)
            return;
        
        started = true;
        
        // go async
        start_async.begin(cancellable, on_start_completed);
    }
    
    private async void start_async(Cancellable? cancellable) throws Error {
        // prepare flags and fields of interest .. don't want known events delivered via signals
        view.set_fields_of_interest(null);
        view.set_flags(E.CalClientViewFlags.NONE);
        
        // subscribe *before* starting so nothing is missed
        view.objects_added.connect(on_objects_added);
        view.objects_removed.connect(on_objects_removed);
        view.objects_modified.connect(on_objects_modified);
        
        // start now ... will be notified of new events, but not existing ones, which are fetched
        // next
        view.start();
        
        // prime with the list of known events
    }
    
    private void on_start_completed(Object? source, AsyncResult result) {
        try {
            start_async.end(result);
        } catch (Error err) {
            start_failed(err);
            
            return;
        }
        
        // ready
        active = true;
    }
    
    private void on_objects_added(SList<weak iCal.icalcomponent> objects) {
    }
    
    private void on_objects_modified(SList<weak iCal.icalcomponent> objects) {
    }
    
    private void on_objects_removed(SList<weak E.CalComponentId?> uids) {
    }
}

}

