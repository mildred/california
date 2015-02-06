/* Copyright 2014-2015 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Host {

[GtkTemplate (ui = "/org/yorba/california/rc/host-calendar-list-item.ui")]
public class CalendarListItem : Gtk.Grid, Toolkit.MutableWidget {
    public Backing.CalendarSource calendar_source { get; private set; }
    
    [GtkChild]
    private Gtk.Image color_image;
    
    [GtkChild]
    private Gtk.Label title_label;
    
    public CalendarListItem(Backing.CalendarSource calendar_source) {
        this.calendar_source = calendar_source;
        
        set_title();
        set_color();
        
        calendar_source.notify[Backing.Source.PROP_TITLE].connect(set_title);
        calendar_source.notify[Backing.Source.PROP_COLOR].connect(set_color);
    }
    
    ~CalendarListItem() {
        calendar_source.notify[Backing.Source.PROP_TITLE].disconnect(set_title);
        calendar_source.notify[Backing.Source.PROP_COLOR].disconnect(set_color);
    }
    
    private void set_title() {
        title_label.label = calendar_source.title;
        mutated();
    }
    
    private void set_color() {
        Gdk.Pixbuf pixbuf = new Gdk.Pixbuf(Gdk.Colorspace.RGB, false, 8, color_image.width_request,
            color_image.height_request);
        pixbuf.fill(Gfx.rgba_to_pixel(calendar_source.color_as_rgba()));
        color_image.set_from_pixbuf(pixbuf);
    }
}

}

