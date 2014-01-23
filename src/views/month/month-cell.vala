/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Views.Month {

/**
 * A single cell within a {@link MonthGrid}.
 */

public class Cell : Gtk.DrawingArea {
    private const int TOP_LINE_FONT_SIZE_PT = 11;
    private const int LINE_FONT_SIZE_PT = 8;
    
    private const int TEXT_MARGIN_PX = 2;
    private const int LINE_SPACING_PX = 4;
    
    public weak Host owner { get; private set; }
    public int row { get; private set; }
    public int col { get; private set; }
    public Calendar.Date? date { get; set; default = null; }
    
    private Gee.TreeSet<Component.Event> all_day_events = new Gee.TreeSet<Component.Event>();
    private Gee.TreeSet<Component.Event> timed_events = new Gee.TreeSet<Component.Event>();
    
    // TODO: We may need to get these colors from the theme
    private static Gdk.RGBA RGBA_BORDER = { red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0 };
    private static Gdk.RGBA RGBA_DAY_OF_MONTH = { red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0 };
    private static Gdk.RGBA RGBA_DAY_OUTSIDE_MONTH = { red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0 };
    private static Gdk.RGBA RGBA_CURRENT_DAY = { red: 0.0, green: 0.25, blue: 0.50, alpha: 0.10 };
    
    private static Pango.FontDescription top_line_font;
    private static Pango.FontDescription line_font;
    private static int top_line_height_px = -1;
    private static int line_height_px = -1;
    
    public Cell(Host owner, int row, int col) {
        this.owner = owner;
        this.row = row;
        this.col = col;
        
        notify["date"].connect(queue_draw);
        
        draw.connect(on_draw);
    }
    
    internal static void init() {
        top_line_font = new Pango.FontDescription();
        top_line_font.set_size(TOP_LINE_FONT_SIZE_PT * Pango.SCALE);
    
        line_font = new Pango.FontDescription();
        line_font.set_size(LINE_FONT_SIZE_PT * Pango.SCALE);
        
        // top_line_height_px and line_height_px can't be calculated until one of the Cells is
        // rendered
    }
    
    internal static void terminate() {
        top_line_font = null;
        line_font = null;
    }
    
    public void clear() {
        date = null;
        timed_events.clear();
        all_day_events.clear();
    }
    
    public void add_event(Component.Event event) {
        bool added;
        if (event.date_time_span != null)
            added = timed_events.add(event);
        else
            added = all_day_events.add(event);
        
        if (!added)
            return;
        
        // subscribe to interesting mutable properties
        event.notify[Component.Event.PROP_SUMMARY].connect(queue_draw);
        event.notify[Component.Event.PROP_DATE_SPAN].connect(on_span_updated);
        event.notify[Component.Event.PROP_DATE_TIME_SPAN].connect(on_span_updated);
        
        queue_draw();
    }
    
    public void remove_event(Component.Event event) {
        // just try to remove from both, for safety
        bool removed = all_day_events.remove(event);
        removed = timed_events.remove(event) || removed;
        
        if (!removed)
            return;
        
        event.notify[Component.Event.PROP_SUMMARY].disconnect(queue_draw);
        event.notify[Component.Event.PROP_DATE_SPAN].disconnect(on_span_updated);
        event.notify[Component.Event.PROP_DATE_TIME_SPAN].disconnect(on_span_updated);
        
        queue_draw();
    }
    
    private void on_span_updated(Object object, ParamSpec param) {
        if (date == null)
            return;
        
        Component.Event event = (Component.Event) object;
        
        // remove from cell if no longer in this day
        if (!(date in event.get_event_date_span())) {
            remove_event(event);
            queue_draw();
            
            return;
        }
        
        // remove and add again to re-sort based on updated information
        if (all_day_events.remove(event))
            all_day_events.add(event);
        
        if (timed_events.remove(event))
            timed_events.add(event);
        
        queue_draw();
    }
    
    private bool on_draw(Cairo.Context ctx) {
        // calculate extents if not already calculated;
        if (line_height_px < 0 || top_line_height_px < 0)
            calculate_extents(out top_line_height_px, out line_height_px);
        
        // shade background if cell represents today
        if (date != null && date.equal_to(Calendar.today)) {
            Gdk.cairo_set_source_rgba(ctx, RGBA_CURRENT_DAY);
            ctx.paint();
        }
        
        int width = get_allocated_width();
        int height = get_allocated_height();
        
        // draw border lines (creates grid effect)
        Gdk.cairo_set_source_rgba(ctx, RGBA_BORDER);
        ctx.set_line_width(0.5);
        
        // only draw bottom line if not on the bottom row
        if (row < Host.ROWS - 1) {
            ctx.move_to(0, height);
            ctx.line_to(width, height);
        }
        
        // only draw right line if not on the right-most column
        if (col < Host.COLS - 1) {
            ctx.move_to(width, 0);
            ctx.line_to(width, height);
        }
        
        ctx.stroke();
        
        // draw day of month as the top line
        if (date != null) {
            Gdk.RGBA color = (date in owner.month_of_year) ? RGBA_DAY_OF_MONTH : RGBA_DAY_OUTSIDE_MONTH;
            draw_line_of_text(ctx, -1, color, date.day_of_month.informal_number);
        }
        
        // represents the line number being drawn (zero-based for remaining lines)
        int line_number = 0;
        
        // draw all-day events
        foreach (Component.Event event in all_day_events)
            draw_line_of_text(ctx, line_number++, RGBA_DAY_OF_MONTH, event.summary);
        
        // draw timed events
        foreach (Component.Event event in timed_events) {
            draw_line_of_text(ctx, line_number++, RGBA_DAY_OF_MONTH, "%d %s".printf(
                event.date_time_span.start_date_time.get_hour(), event.summary));
        }
        
        return true;
    }
    
    private void calculate_extents(out int top_line_height_px, out int line_height_px) {
        Pango.Layout layout = create_pango_layout("Gg");
        layout.set_font_description(top_line_font);
        
        int width;
        layout.get_pixel_size(out width, out top_line_height_px);
        
        layout = create_pango_layout("Gg");
        layout.set_font_description(line_font);
        
        layout.get_pixel_size(out width, out line_height_px);
    }
    
    // If line number is negative, the top line is drawn; otherwise, zero-based line numbers get
    // "regular" treatment
    private void draw_line_of_text(Cairo.Context ctx, int line_number, Gdk.RGBA rgba, string text) {
        Pango.Layout layout = create_pango_layout(text);
        layout.set_font_description((line_number < 0) ? top_line_font : line_font);
        layout.set_ellipsize(Pango.EllipsizeMode.END);
        layout.set_width((get_allocated_width() - (TEXT_MARGIN_PX * 2)) * Pango.SCALE);
        
        int y;
        if (line_number < 0) {
            y = TEXT_MARGIN_PX;
        } else {
            // starting y of "regular" lines
            y = TEXT_MARGIN_PX + top_line_height_px + LINE_SPACING_PX;
            
            // add additional lines
            y += line_number * (line_height_px + LINE_SPACING_PX);
        }
        
        Gdk.cairo_set_source_rgba(ctx, rgba);
        ctx.move_to(TEXT_MARGIN_PX, y);
        Pango.cairo_show_layout(ctx, layout);
    }
}

}

