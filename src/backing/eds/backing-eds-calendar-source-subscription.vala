/* Copyright 2014-2015 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Backing {

/**
 * A calendar subscription to an EDS source.
 */

internal class EdsCalendarSourceSubscription : CalendarSourceSubscription {
    private delegate void InstanceNotifier(Component.Instance instance);
    
    private E.CalClientView view;
    private string sexp;
    // this is different than "active", which gets set when start completes
    private bool started = false;
    private Error? start_err = null;
    
    // Called from EdsCalendarSource.subscribe_async().  The CalClientView should not be started
    public EdsCalendarSourceSubscription(EdsCalendarSource eds_calendar, Calendar.ExactTimeSpan window,
        E.CalClientView view, string sexp) {
        base (eds_calendar, window);
        
        this.view = view;
        this.sexp = sexp;
        
        eds_calendar.notify[Source.PROP_IS_AVAILABLE].connect(() => { stop(eds_calendar); });
    }
    
    ~EdsCalendarSourceSubscription() {
        // need to wait for the finished callback if started
        if (started && !active)
            wait_until_started();
    }
    
    /**
     * @inheritDoc
     */
    public override void wait_until_started(MainContext context = MainContext.default(),
        Cancellable? cancellable = null) throws Error {
        if (!started)
            throw new BackingError.INVALID("EdsCalendarSourceSubscription not started");
        
        if (start_err != null)
            throw start_err;
        
        while (!active) {
            if (cancellable != null && cancellable.is_cancelled())
                throw new IOError.CANCELLED("wait_until_started() cancelled");
            
            context.iteration(true);
        }
    }
    
    /**
     * @inheritDoc
     */
    public override void start(Cancellable? cancellable) {
        // silently ignore repeated starts
        if (started || start_err != null)
            return;
        
        started = true;
        
        try {
            internal_start(cancellable);
        } catch (Error err) {
            start_err = err;
            
            start_failed(err);
        }
    }
    
    private void stop(EdsCalendarSource calendar_source) {
        if (!started || calendar_source.is_available)
            return;
        
        try {
            // wait for start to complete, for sanity's sake
            wait_until_started();
        } catch (Error err) {
            // call it a day
            return;
        }
        
        try {
            view.stop();
        } catch (Error err) {
            debug("Unable to stop E.CalClientView for %s: %s", to_string(), err.message);
        }
        
        started = false;
        active = false;
    }
    
    private void internal_start(Cancellable? cancellable) throws Error {
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
        
        discovery_async.begin(cancellable);
    }
    
    private async void discovery_async(Cancellable? cancellable) {
        SList<unowned iCal.icalcomponent> ical_components;
        try {
            yield view.client.get_object_list(sexp, cancellable, out ical_components);
        } catch (Error err) {
            start_err = err;
            
            start_failed(err);
            
            return;
        }
        
        // process all known objects within the sexp range
        on_objects_discovered_added(ical_components, notify_instance_discovered);
        
        // only set when generation (start) is finished
        active = true;
    }
    
    private void on_objects_added(SList<unowned iCal.icalcomponent> ical_components) {
        // process all added objects
        on_objects_discovered_added(ical_components, notify_instance_added);
    }
    
    private void on_objects_discovered_added(SList<unowned iCal.icalcomponent> ical_components,
        InstanceNotifier notifier) {
        foreach (unowned iCal.icalcomponent ical_component in ical_components) {
            if (String.is_empty(ical_component.get_uid()))
                continue;
            
            Component.UID uid = new Component.UID(ical_component.get_uid());
            
            // remove all existing components with this UID
            if (has_uid(uid))
                notify_master_removed(uid);
            
            // add all instances, master and generated
            Component.Instance? master = add_instance(null, ical_component, notifier);
            if (master == null)
                continue;
            
            // if no recurrences, done
            if (!E.Util.component_has_recurrences(ical_component))
                continue;
            
            // generate recurring instances
            view.client.generate_instances_for_object_sync(
                ical_component,
                window.start_exact_time.to_time_t(),
                window.end_exact_time.to_time_t(),
                (eds_component, start, end) => {
                    add_instance(master, eds_component.get_icalcomponent(), notifier);
                    
                    return true;
                }
            );
        }
    }
    
    // Assumes all existing events with UID/RID have been removed already
    private Component.Instance? add_instance(Component.Instance? master, iCal.icalcomponent ical_component,
        InstanceNotifier notifier) {
        // convert the added component into a new Event
        Component.Event? added_event = null;
        try {
            added_event = Component.Instance.convert(calendar, ical_component) as Component.Event;
            if (added_event != null) {
                // assign the master (if this isn't the master already)
                added_event.master = master;
                
                // notify of didscovery/addition
                notifier(added_event);
            }
        } catch (Error err) {
            debug("Unable to process added event: %s\n%s", err.message, ical_component.as_ical_string());
        }
        
        return added_event;
    }
    
    private void on_objects_modified(SList<unowned iCal.icalcomponent> ical_components) {
        SList<unowned iCal.icalcomponent> add_list = new SList<unowned iCal.icalcomponent>();
        foreach (unowned iCal.icalcomponent ical_component in ical_components) {
            // if not a generated instance and has recurring, treat as an add (which removes and
            // adds generated instances)
            if (!E.Util.component_is_instance(ical_component) && E.Util.component_has_recurrences(ical_component)) {
                add_list.append(ical_component);
                
                continue;
            }
            
            if (String.is_empty(ical_component.get_uid()))
                continue;
            
            Component.UID uid = new Component.UID(ical_component.get_uid());
            
            // if no known instances (master or generated) of this UID, then signalled for something
            // never seen before
            Gee.Collection<Component.Instance>? instances = for_uid(uid);
            if (Collection.size(instances) == 0)
                continue;
            
            // if a generated instance has been updated, get its RID (fall through if unavailable)
            Component.DateTime? rid = null;
            try {
                rid = new Component.DateTime(ical_component, iCal.icalproperty_kind.RECURRENCEID_PROPERTY);
            } catch (ComponentError comperr) {
                if (!(comperr is ComponentError.UNAVAILABLE)) {
                    debug("Unable to get RID of modified component: %s", comperr.message);
                    
                    continue;
                }
            }
            
            Component.Instance? instance = null;
            if (rid == null) {
                // no RID, then this is the master instance; test above looks for an RRULE, so that's
                // not present any more (if it ever was); drop all generated instances, as this
                // master no longer has any
                traverse<Component.Instance>(instances)
                    .filter(inst => inst.is_generated_instance)
                    .iterate(inst => notify_generated_instance_removed(inst.uid, inst.rid));
            
                // the master instance of the bunch is what's been modified
                instance = traverse<Component.Instance>(instances)
                    .filter(inst => inst.is_master_instance)
                    .one();
                if (instance == null) {
                    debug("Cannot find master instance for UID %s (%d generated), skipping",
                        uid.to_string(), Collection.size(instances));
                }
                
            } else {
                // RID found, so a generated instance has been modified; only update that one
                instance = traverse<Component.Instance>(instances)
                    .filter(inst => inst.rid != null && inst.rid.equal_to(rid))
                    .one();
                if (instance == null) {
                    debug("Cannot find generated instance for UID %s RID %s (%d generated), skipping",
                        uid.to_string(), rid.to_string(), Collection.size(instances));
                }
            }
            
            if (instance == null)
                continue;
            
            // only deal with Events at this moment
            Component.Event? modified_event = instance as Component.Event;
            if (modified_event == null)
                continue;
            
            // update event details
            try {
                modified_event.full_update(ical_component, null);
            } catch (Error err) {
                debug("Unable to update event %s: %s\n%s", modified_event.to_string(), err.message,
                    ical_component.as_ical_string());
                
                continue;
            }
            
            notify_instance_altered(modified_event);
        }
        
        // remove and re-add any recurring events
        on_objects_added(add_list);
    }
    
    private void on_objects_removed(SList<unowned E.CalComponentId?> ids) {
        foreach (unowned E.CalComponentId id in ids)
            notify_master_removed(new Component.UID(id.uid));
    }
}

}

