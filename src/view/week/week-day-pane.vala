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

internal class DayPane : Pane {
    public const string PROP_OWNER = "owner";
    public const string PROP_DATE = "date";
    public const string PROP_SELECTED = "selected";
    
    // No matter how wide the event is in the day, always leave a little peeking out so the hour/min
    // lines are visible
    private const int RIGHT_MARGIN_PX = 10;
    
    public Calendar.Date date { get; set; }
    
    public bool selected { get; set; default = false; }
    
    private Gee.TreeSet<Component.Event> days_events = new Gee.TreeSet<Component.Event>();
    private uint minutes_timeout_id = 0;
    
    public DayPane(Grid owner, Calendar.Date date) {
        base (owner, -1);
        
        this.date = date;
        
        notify[PROP_DATE].connect(queue_draw);
        notify[PROP_SELECTED].connect(queue_draw);
        Calendar.System.instance.is_24hr_changed.connect(queue_draw);
        Calendar.System.instance.today_changed.connect(on_today_changed);
        
        schedule_monitor_minutes();
    }
    
    ~DayPane() {
        Calendar.System.instance.is_24hr_changed.disconnect(queue_draw);
        Calendar.System.instance.today_changed.disconnect(on_today_changed);
        
        cancel_monitor_minutes();
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
        cancel_monitor_minutes();
        
        if (!date.equal_to(Calendar.System.today))
            return;
        
        // find the number of seconds remaining in this minute and schedule an update then
        int remaining_sec = (Calendar.WallTime.SECONDS_PER_MINUTE - Calendar.System.now.second).clamp(
            0, Calendar.WallTime.SECONDS_PER_MINUTE);
        minutes_timeout_id = Timeout.add_seconds(remaining_sec, on_minute_changed);
    }
    
    private bool on_minute_changed() {
        // done this iteration
        minutes_timeout_id = 0;
        
        // repaint time indicator
        queue_draw();
        
        // reschedule
        schedule_monitor_minutes();
        
        return false;
    }
    
    private void cancel_monitor_minutes() {
        if (minutes_timeout_id == 0)
            return;
        
        Source.remove(minutes_timeout_id);
        minutes_timeout_id = 0;
    }
    
    public void add_event(Component.Event event) {
        if (!days_events.add(event))
            return;
        
        queue_draw();
    }
    
    public void remove_event(Component.Event event) {
        if (!days_events.remove(event))
            return;
        
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
    
    // note that a painter's algorithm should be used here: background should be painted before
    // calling base method, and foreground afterward
    protected override bool on_draw(Cairo.Context ctx) {
        // shade background color if this is current day or selected
        if (selected) {
            Gdk.cairo_set_source_rgba(ctx, Palette.instance.selection);
            ctx.paint();
        } else if (date.equal_to(Calendar.System.today)) {
            Gdk.cairo_set_source_rgba(ctx, Palette.instance.current_day);
            ctx.paint();
        }
        
        base.on_draw(ctx);
        
        // each event is drawn with a slightly-transparent rectangle with a solid hairline bounding
        Palette.prepare_hairline(ctx, Palette.instance.border);
        
        foreach (Component.Event event in days_events) {
            // All-day events are handled in separate container ...
            if (event.is_all_day)
                continue;
            
            // ... as are events that span days (or outside this date, although that technically
            // shouldn't happen)
            Calendar.DateSpan date_span = event.get_event_date_span(Calendar.Timezone.local);
            if (!date_span.is_same_day || !(date in date_span))
                continue;
            
            Calendar.WallTime start_time = new Calendar.WallTime.from_exact_time(
                event.exact_time_span.start_exact_time.to_timezone(Calendar.Timezone.local));
            Calendar.WallTime end_time = new Calendar.WallTime.from_exact_time(
                event.exact_time_span.end_exact_time.to_timezone(Calendar.Timezone.local));
            
            int start_y = get_line_y(start_time);
            int end_y = get_line_y(end_time);
            
            Gdk.RGBA rgba = event.calendar_source.color_as_rgba();
            
            // event rectangle ... take some space off the right side to let the hour lines show
            int rect_width = get_allocated_width() - RIGHT_MARGIN_PX;
            ctx.rectangle(0, start_y, rect_width, end_y - start_y);
            
            // background rectangle (to prevent hour lines from showing when using alpha, below)
            Gdk.cairo_set_source_rgba(ctx, Gfx.RGBA_WHITE);
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
                start_time.to_pretty_string(Calendar.WallTime.PrettyFlag.NONE),
                end_time.to_pretty_string(Calendar.WallTime.PrettyFlag.NONE));
            print_line(ctx, start_time, 0, timespan, rgba, rect_width, true);
            print_line(ctx, start_time, 1, event.summary, rgba, rect_width, false);
        }
        
        // draw horizontal line indicating current time
        if (date.equal_to(Calendar.System.today)) {
            int time_of_day_y = get_line_y(new Calendar.WallTime.from_exact_time(Calendar.System.now));
            
            Palette.prepare_hairline(ctx, Palette.instance.current_time);
            ctx.move_to(0, time_of_day_y);
            ctx.line_to(get_allocated_width(), time_of_day_y);
            ctx.stroke();
        }
        
        return true;
    }
    
    private void print_line(Cairo.Context ctx, Calendar.WallTime start_time, int lineno, string text,
        Gdk.RGBA rgba, int total_width, bool is_markup) {
        Pango.Layout layout = create_pango_layout(null);
        if (is_markup)
            layout.set_markup(text, -1);
        else
            layout.set_text(text, -1);
        layout.set_font_description(Palette.instance.small_font);
        layout.set_width((total_width - (Palette.TEXT_MARGIN_PX * 2)) * Pango.SCALE);
        layout.set_ellipsize(Pango.EllipsizeMode.END);
        
        int y = get_line_y(start_time) + Palette.LINE_PADDING_PX
            + (Palette.instance.small_font_height_px * lineno);
        
        ctx.move_to(Palette.TEXT_MARGIN_PX, y);
        Gdk.cairo_set_source_rgba(ctx, rgba);
        Pango.cairo_show_layout(ctx, layout);
    }
}

}
