/* Copyright 2014-2015 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Host {

[GtkTemplate (ui = "/org/yorba/california/rc/host-main-window-title.ui")]
internal class MainWindowTitle : Gtk.Grid {
    public const string PROP_MOTION = "motion";
    
    public View.ChronologyMotion motion { get; set; default = View.ChronologyMotion.HORIZONTAL; }
    
    [GtkChild]
    public Gtk.Button next_button;
    
    [GtkChild]
    public Gtk.Button prev_button;
    
    [GtkChild]
    public Gtk.Image next_image;
    
    [GtkChild]
    public Gtk.Image prev_image;
    
    [GtkChild]
    public Gtk.Label title_label;
    
    public MainWindowTitle() {
        notify[PROP_MOTION].connect(on_motion_changed);
        on_motion_changed();
    }
    
    private void on_motion_changed() {
        switch (motion) {
            case View.ChronologyMotion.HORIZONTAL:
                bool rtl = (get_direction() == Gtk.TextDirection.RTL);
                
                prev_image.icon_name = rtl ? "go-previous-rtl-symbolic" : "go-previous-symbolic";
                next_image.icon_name = rtl ? "go-next-rtl-symbolic" : "go-next-symbolic";
            break;
            
            case View.ChronologyMotion.VERTICAL:
                prev_image.icon_name = "go-up-symbolic";
                next_image.icon_name = "go-down-symbolic";
            break;
            
            default:
                assert_not_reached();
        }
    }
}

}

