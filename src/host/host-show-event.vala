/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Host {

[GtkTemplate (ui = "/org/yorba/california/rc/show-event.ui")]
public class ShowEvent : Gtk.Grid {
    [GtkChild]
    private Gtk.Label text_label;
    
    private new Component.Event event;
    
    public signal void remove_event(Component.Event event);
    
    public ShowEvent(Component.Event event) {
        this.event = event;
        
        // Each string should end without whitespace; add_lf_lf will ensure each section is
        // separated as long as there's preceding text
        StringBuilder builder = new StringBuilder();
        
        // summary
        if (!String.is_empty(event.summary))
            add_lf_lf(builder).append_printf("<b>%s</b>", Markup.escape_text(event.summary));
        
        // description
        if (!String.is_empty(event.description))
            add_lf_lf(builder).append_printf("%s", Markup.escape_text(event.description));
        
        // if any dates are not in current year, display year in all dates
        Calendar.Date.PrettyFlag date_flags = Calendar.Date.PrettyFlag.NONE;
        Calendar.DateSpan date_span = event.get_event_date_span();
        if (!date_span.start_date.year.equal_to(Calendar.today.year)
            || !date_span.end_date.year.equal_to(Calendar.today.year)) {
            date_flags |= Calendar.Date.PrettyFlag.INCLUDE_YEAR;
        }
        
        // span string is kinda tricky
        string span;
        if (event.is_all_day) {
            if (date_span.is_same_day) {
                // All-day one-day event, print that date's "<full date>", including year if not
                // current year
                span = date_span.start_date.to_pretty_string(date_flags);
            } else {
                // All-day event spanning days, print "<abbrev date> to <abbrev date>"
                date_flags |= Calendar.Date.PrettyFlag.ABBREV;
                /// Prints a span of dates, i.e. "January 3 to January 6"
                span = _("%s to %s").printf(date_span.start_date.to_pretty_string(date_flags),
                    date_span.end_date.to_pretty_string(date_flags));
            }
        } else {
            Calendar.ExactTimeSpan exact_time_span = event.exact_time_span;
            if (exact_time_span.is_same_day) {
                // Single-day timed event, print "<full date>\n<full start time> to <full end time>",
                // including year if not current year
                /// Prints a span of time, i.e. "3:30pm to 4:30pm"
                string timespan = _("%s to %s").printf(
                    exact_time_span.start_exact_time.to_pretty_time_string(Calendar.WallTime.PrettyFlag.NONE),
                    exact_time_span.end_exact_time.to_pretty_time_string(Calendar.WallTime.PrettyFlag.NONE));
                span = "%s\n%s".printf(exact_time_span.start_date.to_pretty_string(date_flags),
                    timespan);
            } else {
                // Multi-day timed event, print "<full time>, <full date>" on both lines,
                // including year if either not current year
                /// Prints two full time and date strings on separate lines, i.e.:
                /// 12 January 2012, 3:30pm
                /// 13 January 2013, 6:30am
                span = _("%s, %s\n%s, %s").printf(
                    exact_time_span.start_exact_time.to_pretty_date_string(date_flags),
                    exact_time_span.start_exact_time.to_pretty_time_string(Calendar.WallTime.PrettyFlag.NONE),
                    exact_time_span.end_exact_time.to_pretty_date_string(date_flags),
                    exact_time_span.end_exact_time.to_pretty_time_string(Calendar.WallTime.PrettyFlag.NONE));
            }
        }
        
        add_lf_lf(builder).append_printf("<small>%s</small>", Markup.escape_text(span));
        
        text_label.label = builder.str;
    }
    
    // Adds two linefeeds if there's existing text
    private unowned StringBuilder add_lf_lf(StringBuilder builder) {
        if (!String.is_empty(builder.str))
            builder.append("\n\n");
        
        return builder;
    }
    
    [GtkCallback]
    private void on_remove_button_clicked() {
        remove_event(event);
    }
}

}

