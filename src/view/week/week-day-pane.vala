/* Copyright 2014 Yorba Foundation
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
    private Scheduled? scheduled_monitor = null;
    
    public DayPane(Grid owner, Calendar.Date date) {
        base (owner, -1);
        
        this.date = date;
        
        // see query_tooltip()
        has_tooltip = true;
        
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
    
    public void add_event(Component.Event event) {
        if (!days_events.add(event)) {
            debug("Unable to add event %s to day pane for %s: already present", event.to_string(),
                date.to_string());
            
            return;
        }
        
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
        
        event.notify[Component.Event.PROP_SUMMARY].disconnect(queue_draw);
        event.notify[Component.Event.PROP_DATE_SPAN].disconnect(on_update_date_time);
        event.notify[Component.Event.PROP_EXACT_TIME_SPAN].disconnect(on_update_date_time);
        
        queue_draw();
    }
    
    public void clear_events() {
        days_events.clear();
        
        queue_draw();
    }
    
    private void on_update_date_time(Object object, ParamSpec param) {
        Component.Event event = (Component.Event) object;
        
        // remove entirely if not in this date any more
        if (!(date in event.get_event_date_span(Calendar.System.timezone)))
            remove_event(event);
        
        queue_draw();
    }
    
    public Component.Event? get_event_at(Gdk.Point point) {
        Calendar.ExactTime exact_time = new Calendar.ExactTime(Calendar.Timezone.local, date,
            get_wall_time(point.y));
        foreach (Component.Event event in days_events) {
            if (event.is_all_day)
                continue;
            
            if (exact_time in event.exact_time_span)
                return event;
        }
        
        return null;
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
        // convery y into a time of day
        Calendar.WallTime wall_time = get_wall_time(y);
        Calendar.ExactTime exact_time = new Calendar.ExactTime(Calendar.Timezone.local, date, wall_time);
        
        // find event in list that spans this time
        // TODO: This won't work when events are stacked in the UI
        Component.Event? found = traverse<Component.Event>(days_events)
            .first_matching(event => event.exact_time_span.to_timezone(Calendar.Timezone.local).contains(exact_time));
        if (found == null)
            return false;
        
        string? tooltip_text = found.get_data<string?>(KEY_TOOLTIP);
        if (String.is_empty(tooltip_text))
            return false;
        
        tooltip.set_markup(tooltip_text);
        
        return true;
    }
    
    private bool filter_date_spanning_events(Component.Event event) {
        // All-day events are handled in separate container ...
        if (event.is_all_day)
            return false;
        
        // ... as are events that span days (or outside this date, although that technically
        // shouldn't happen)
        return date in event.get_event_date_span(Calendar.Timezone.local);
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
        
        // Can't persist events in TreeSet because mutation is not handled well, see
        // https://bugzilla.gnome.org/show_bug.cgi?id=736444
        Gee.TreeSet<Component.Event> sorted_events = traverse<Component.Event>(days_events)
            .filter(filter_date_spanning_events)
            .filter(event => event.calendar_source != null && event.calendar_source.visible)
            .to_tree_set();
        foreach (Component.Event event in sorted_events) {
            // The actual WallTime is the time on the starting date (which may not be this Pane's
            // date).  The draw WallTime is the time on this Pane's date to start and end drawing
            // the rectangle
            
            Calendar.WallTime actual_start_time =
                event.exact_time_span.start_exact_time.to_timezone(Calendar.Timezone.local).to_wall_time();
            Calendar.WallTime draw_start_time;
            if (event.exact_time_span.start_date.equal_to(date))
                draw_start_time = actual_start_time;
            else
                draw_start_time = Calendar.WallTime.earliest;
            
            Calendar.WallTime actual_end_time =
                event.exact_time_span.end_exact_time.to_timezone(Calendar.Timezone.local).to_wall_time();
            Calendar.WallTime draw_end_time;
            if (event.exact_time_span.end_date.equal_to(date))
                draw_end_time = actual_end_time;
            else
                draw_end_time = Calendar.WallTime.latest;
            
            int start_y = get_line_y(draw_start_time);
            int end_y = get_line_y(draw_end_time);
            
            Gdk.RGBA rgba = event.calendar_source.color_as_rgba();
            
            // event rectangle ... take some space off the right side to let the hour lines show
            int rect_width = get_allocated_width() - RIGHT_MARGIN_PX;
            ctx.rectangle(0, start_y, rect_width, end_y - start_y);
            
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
            Pango.Layout layout_0 = print_line(ctx, draw_start_time, 0, timespan, rgba, rect_width, true);
            Pango.Layout layout_1 = print_line(ctx, draw_start_time, 1, event.summary, rgba, rect_width, false);
            
            // if either was ellipsized, set tooltip (otherwise clear any existing)
            bool is_ellipsized = layout_0.is_ellipsized() || layout_1.is_ellipsized();
            event.set_data<string?>(KEY_TOOLTIP,
                is_ellipsized ? "%s\n%s".printf(timespan, GLib.Markup.escape_text(event.summary)) : null);
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
    
    private Pango.Layout print_line(Cairo.Context ctx, Calendar.WallTime start_time, int lineno, string text,
        Gdk.RGBA rgba, int total_width, bool is_markup) {
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
        
        ctx.move_to(Palette.TEXT_MARGIN_PX, y);
        Gdk.cairo_set_source_rgba(ctx, rgba);
        Pango.cairo_show_layout(ctx, layout);
        
        return layout;
    }
}

}

