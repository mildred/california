/* Copyright 2014-2015 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.View.Week {

/**
 * A long pane displaying hour and half-hour delineations with events displayed as proportional
 * boxes along the span.
 *
 * @see AllDayCell
 */

internal class DayPane : Pane, Common.InstanceContainer {
    public const string PROP_OWNER = "owner";
    public const string PROP_DATE = "date";
    public const string PROP_SELECTION_STATE = "selection-start";
    public const string PROP_SELECTION_END = "selection-end";
    
    private const string KEY_TOOLTIP = "california-week-day-pane-tooltip";
    
    // No matter how wide the event is in the day, always leave a little peeking out so the hour/min
    // lines are visible
    private const int RIGHT_MARGIN_PX = 10;
    
    // Groups coinciding Events together, held in sorted order by their earliest Event
    private class EventStack : Object, Gee.Comparable<EventStack> {
        public Gee.TreeSet<Component.Event> events = new Gee.TreeSet<Component.Event>();
        public Calendar.ExactTimeSpan earliest;
        
        public EventStack(Component.Event initial) {
            add(initial);
        }
        
        public bool coincides_with(Component.Event event) {
            assert(event.exact_time_span != null);
            assert(!events.contains(event));
            
            return traverse<Component.Event>(events)
                .any(contained => event.exact_time_span.coincides_with(contained.exact_time_span));
        }
        
        public void add(Component.Event event) {
            assert(event.exact_time_span != null);
            assert(!events.contains(event));
            
            if (earliest == null || earliest.compare_to(event.exact_time_span) > 0)
                earliest = event.exact_time_span;
            
            events.add(event);
        }
        
        public int compare_to(EventStack other) {
            return earliest.compare_to(other.earliest);
        }
    }
    
    public Calendar.Date date { get; set; }
    
    /**
     * Where the current selection starts, if any.
     */
    public Calendar.WallTime? selection_start { get; private set; }
    
    /**
     * Where the current selection ends, if any.
     */
    public Calendar.WallTime? selection_end { get; private set; }
    
    /**
     * The center point of the current selection.
     */
    public Gdk.Point? selection_point { get; private set; default = null; }
    
    /**
     * @inheritDoc
     */
    public int event_count { get { return days_events.size; } }
    
    /**
     * @inheritDoc
     */
    public Calendar.Span contained_span { get { return date; } }
    
    private Gee.HashSet<Component.Event> days_events = new Gee.HashSet<Component.Event>();
    private Gee.TreeSet<EventStack> event_stacks = new Gee.TreeSet<EventStack>();
    private Toolkit.RegionManager<Component.Event> region_manager = new Toolkit.RegionManager<Component.Event>();
    private Scheduled? scheduled_monitor = null;
    private string key_tooltip_date;
    
    public DayPane(Grid owner, Calendar.Date date) {
        base (owner, -1);
        
        this.date = date;
        
        // see query_tooltip()
        has_tooltip = true;
        
        // store individual tooltip keys so tooltips can be maintained across days for the same
        // event
        key_tooltip_date = KEY_TOOLTIP + date.to_string();;
        
        notify[PROP_DATE].connect(queue_draw);
        
        Calendar.System.instance.is_24hr_changed.connect(queue_draw);
        Calendar.System.instance.today_changed.connect(on_today_changed);
        
        schedule_monitor_minutes();
    }
    
    ~DayPane() {
        Calendar.System.instance.is_24hr_changed.disconnect(queue_draw);
        Calendar.System.instance.today_changed.disconnect(on_today_changed);
    }
    
    private void on_today_changed(Calendar.Date old_today, Calendar.Date new_today) {
        // need to know re: redrawing background color to indicate current day
        if (date.equal_to(old_today) || date.equal_to(new_today)) {
            schedule_monitor_minutes();
            queue_draw();
        }
    }
    
    // If this pane is showing the current date, need to update once a minute to move the horizontal
    // minute indicator
    private void schedule_monitor_minutes() {
        scheduled_monitor = null;
        
        if (!date.equal_to(Calendar.System.today))
            return;
        
        // find the number of seconds remaining in this minute and schedule an update then
        int remaining_sec = (Calendar.WallTime.SECONDS_PER_MINUTE - Calendar.System.now.second).clamp(
            0, Calendar.WallTime.SECONDS_PER_MINUTE);
        scheduled_monitor = new Scheduled.once_after_sec(remaining_sec, on_minute_changed);
    }
    
    private void on_minute_changed() {
        // repaint time indicator
        queue_draw();
        
        // reschedule
        schedule_monitor_minutes();
    }
    
    private bool filter_date_spanning_events(Component.Event event) {
        // All-day events are handled in separate container ...
        if (event.is_all_day)
            return false;
        
        // filter events entirely outside this date (although that should've been caught before)
        return date in event.get_event_date_span(Calendar.Timezone.local);
    }
    
    private void restack_events() {
        // filter out date-spanning Events and not-visible calendars
        Gee.ArrayList<Component.Event> filtered_events = traverse<Component.Event>(days_events)
            .filter(filter_date_spanning_events)
            .filter(event => event.calendar_source != null && event.calendar_source.visible)
            .to_array_list();
        
        Gee.ArrayList<EventStack> stack_list = new Gee.ArrayList<EventStack>();
        foreach (Component.Event event in filtered_events) {
            // search existing stacks for a place for this Event
            EventStack? found = null;
            foreach (EventStack event_stack in stack_list) {
                if (event_stack.coincides_with(event)) {
                    found = event_stack;
                    
                    break;
                }
            }
            
            if (found == null) {
                found = new EventStack(event);
                stack_list.add(found);
            } else {
                found.add(event);
            }
        }
        
        // Can't persist EventStacks in TreeSet because mutation is not handled well, see
        // https://bugzilla.gnome.org/show_bug.cgi?id=736444
        event_stacks = traverse<EventStack>(stack_list).to_tree_set();
    }
    
    public void add_event(Component.Event event) {
        if (!days_events.add(event)) {
            debug("Unable to add event %s to day pane for %s: already present", event.to_string(),
                date.to_string());
            
            return;
        }
        
        restack_events();
        
        event.notify[Component.Event.PROP_SUMMARY].connect(queue_draw);
        event.notify[Component.Event.PROP_DATE_SPAN].connect(on_update_date_time);
        event.notify[Component.Event.PROP_EXACT_TIME_SPAN].connect(on_update_date_time);
        
        queue_draw();
    }
    
    public void remove_event(Component.Event event) {
        if (!days_events.remove(event)) {
            debug("Unable to remove event %s from day pane for %s: not present in sorted_events",
                event.to_string(), date.to_string());
            
            return;
        }
        
        // ignore return code because it's possible the event was not added to the region manager
        // (if a redraw did not occur, for example)
        region_manager.remove_region(event);
        
        restack_events();
        
        event.notify[Component.Event.PROP_SUMMARY].disconnect(queue_draw);
        event.notify[Component.Event.PROP_DATE_SPAN].disconnect(on_update_date_time);
        event.notify[Component.Event.PROP_EXACT_TIME_SPAN].disconnect(on_update_date_time);
        
        queue_draw();
    }
    
    public void clear_events() {
        days_events.clear();
        restack_events();
        
        queue_draw();
    }
    
    private void on_update_date_time(Object object, ParamSpec param) {
        Component.Event event = (Component.Event) object;
        
        // remove entirely if not in this date any more
        if (!(date in event.get_event_date_span(Calendar.System.timezone)))
            remove_event(event);
        
        restack_events();
        
        queue_draw();
    }
    
    public Component.Event? get_event_at(Gdk.Point point) {
        return traverse<Component.Event>(region_manager.hit_list(point)).first();
    }
    
    public void update_selection(Calendar.WallTime wall_time) {
        // round down to the nearest 15-minute mark
        Calendar.WallTime rounded_time = wall_time.round(-15, Calendar.TimeUnit.MINUTE, null);
        
        // assign start first, end second (ordering doesn't matter, possible to select upwards)
        if (selection_start == null) {
            selection_start = rounded_time;
            selection_end = null;
        } else {
            selection_end = rounded_time;
        }
        
        // if same, treat as unselected
        if (selection_start != null && selection_end != null && selection_start.equal_to(selection_end)) {
            clear_selection();
            
            return;
        }
        
        queue_draw();
    }
    
    public Calendar.ExactTimeSpan? get_selection_span() {
        if (selection_start == null || selection_end == null)
            return null;
        
        return new Calendar.ExactTimeSpan(
            new Calendar.ExactTime(Calendar.Timezone.local, date, selection_start),
            new Calendar.ExactTime(Calendar.Timezone.local, date, selection_end)
        );
    }
    
    public void clear_selection() {
        if (selection_start == null && selection_end == null)
            return;
        
        selection_start = null;
        selection_end = null;
        
        queue_draw();
    }
    
    public void notify_calendar_display_changed(Backing.CalendarSource calendar_source) {
        if (traverse<Component.Event>(days_events).any(event => event.calendar_source == calendar_source))
            queue_draw();
    }
    
    public override bool query_tooltip(int x, int y, bool keyboard_mode, Gtk.Tooltip tooltip) {
        Component.Event? found = get_event_at({ x, y });
        if (found == null)
            return false;
        
        string? tooltip_text = found.get_data<string?>(key_tooltip_date);
        if (String.is_empty(tooltip_text))
            return false;
        
        tooltip.set_markup(tooltip_text);
        
        return true;
    }
    
    // note that a painter's algorithm should be used here: background should be painted before
    // calling base method, and foreground afterward
    protected override bool on_draw(Cairo.Context ctx) {
        // shade background color if this is current day
        if (date.equal_to(Calendar.System.today)) {
            Gdk.cairo_set_source_rgba(ctx, palette.current_day);
            ctx.paint();
        }
        
        base.on_draw(ctx);
        
        // each event is drawn with a slightly-transparent rectangle with a solid hairline bounding
        Palette.prepare_hairline(ctx, palette.border);
        
        foreach (EventStack event_stack in event_stacks) {
            // event rectangle ... take some space off the right side to let the hour lines show
            int rect_width = (get_allocated_width() - RIGHT_MARGIN_PX) / event_stack.events.size;
            
            int ctr = 0;
            foreach (Component.Event event in event_stack.events) {
                // The actual WallTime is the time on the starting date (which may not be this Pane's
                // date).  The draw WallTime is the time on this Pane's date to start and end drawing
                // the rectangle
                
                Calendar.WallTime actual_start_time =
                    event.exact_time_span.start_exact_time.to_timezone(Calendar.Timezone.local).to_wall_time();
                Calendar.WallTime draw_start_time;
                if (event.exact_time_span.to_local().start_date.equal_to(date))
                    draw_start_time = actual_start_time;
                else
                    draw_start_time = Calendar.WallTime.earliest;
                
                Calendar.WallTime actual_end_time =
                    event.exact_time_span.end_exact_time.to_timezone(Calendar.Timezone.local).to_wall_time();
                Calendar.WallTime draw_end_time;
                if (event.exact_time_span.to_local().end_date.equal_to(date))
                    draw_end_time = actual_end_time;
                else
                    draw_end_time = Calendar.WallTime.latest;
                
                // for purposes of visualization, an event ends one minute inward on both ends; i.e.
                // an event from 1pm to 2pm is drawn as starting at 1:01pm and ending at 1:59pm
                draw_start_time = draw_start_time.adjust(1, Calendar.TimeUnit.MINUTE, null);
                draw_end_time = draw_end_time.adjust(-1, Calendar.TimeUnit.MINUTE, null);
                
                int start_x = ctr * rect_width;
                int start_y = get_line_y(draw_start_time);
                int end_y = get_line_y(draw_end_time);
                int rect_height = end_y - start_y;
                
                Gdk.RGBA rgba = event.calendar_source.color_as_rgba();
                
                ctx.rectangle(start_x, start_y, rect_width, rect_height);
                region_manager.add_points(event, start_x, start_y, rect_width, rect_height);
                
                // background rectangle (to prevent hour lines from showing when using alpha, below)
                Gdk.cairo_set_source_rgba(ctx, Gfx.WHITE);
                ctx.fill_preserve();
                
                // interior rectangle (use alpha to mute colors)
                rgba.alpha = 0.25;
                Gdk.cairo_set_source_rgba(ctx, rgba);
                ctx.fill_preserve();
                
                // bounding border line and text color
                rgba.alpha = 1.0;
                Gdk.cairo_set_source_rgba(ctx, rgba);
                ctx.stroke();
                
                // time range on first line, summary on second ... note that separator character is an
                // endash
                string timespan = "%s &#x2013; %s".printf(
                    actual_start_time.to_pretty_string(Calendar.WallTime.PrettyFlag.NONE),
                    actual_end_time.to_pretty_string(Calendar.WallTime.PrettyFlag.NONE));
                Pango.Layout layout_0 = print_line(ctx, draw_start_time, 0, timespan, rgba, start_x, rect_width,
                    true);
                Pango.Layout layout_1 = print_line(ctx, draw_start_time, 1, event.summary, rgba, start_x,
                    rect_width, false);
                
                // if either was ellipsized, set tooltip (otherwise clear any existing)
                bool is_ellipsized = layout_0.is_ellipsized() || layout_1.is_ellipsized();
                event.set_data<string?>(key_tooltip_date,
                    is_ellipsized ? "%s\n%s".printf(timespan, GLib.Markup.escape_text(event.summary)) : null);
                
                ctr++;
            }
        }
        
        // draw horizontal line indicating current time
        if (date.equal_to(Calendar.System.today)) {
            int time_of_day_y = get_line_y(Calendar.System.now.to_wall_time());
            
            Palette.prepare_hairline(ctx, palette.current_time);
            ctx.move_to(0, time_of_day_y);
            ctx.line_to(get_allocated_width(), time_of_day_y);
            ctx.stroke();
        }
        
        // draw selection rectangle
        if (selection_start != null && selection_end != null) {
            int start_y = get_line_y(selection_start);
            int end_y = get_line_y(selection_end);
            
            int y = int.min(start_y, end_y);
            int height = int.max(start_y, end_y) - y;
            
            ctx.rectangle(0, y, get_allocated_width(), height);
            Gdk.cairo_set_source_rgba(ctx, palette.selection);
            ctx.fill();
            
            selection_point = Gdk.Point();
            selection_point.x = get_allocated_width() / 2;
            selection_point.y = y + (height / 2);
        } else {
            selection_point = null;
        }
        
        return true;
    }
    
    private Pango.Layout print_line(Cairo.Context ctx, Calendar.WallTime start_time, int lineno,
        string text, Gdk.RGBA rgba, int start_x, int total_width, bool is_markup) {
        Pango.Layout layout = create_pango_layout(null);
        if (is_markup)
            layout.set_markup(text, -1);
        else
            layout.set_text(text, -1);
        layout.set_font_description(palette.small_font);
        layout.set_width((total_width - (Palette.TEXT_MARGIN_PX * 2)) * Pango.SCALE);
        layout.set_ellipsize(Pango.EllipsizeMode.END);
        
        int y = get_line_y(start_time) + Palette.LINE_PADDING_PX
            + (palette.small_font_height_px * lineno);
        
        ctx.move_to(Palette.TEXT_MARGIN_PX + start_x, y);
        Gdk.cairo_set_source_rgba(ctx, rgba);
        Pango.cairo_show_layout(ctx, layout);
        
        return layout;
    }
}

}

