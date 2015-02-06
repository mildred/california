/* Copyright 2014-2015 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

/**
 * D-Bus interfaces needed for system time/date information.
 */

namespace California.Calendar.DBus {

/**
 * D-Bus interface to systemd-timedated which holds various useful time/date-related information.
 *
 * See [[http://www.freedesktop.org/wiki/Software/systemd/timedated/]]
 */

[DBus (name = "org.freedesktop.timedate1")]
public interface timedated : Object {
    public const string NAME = "org.freedesktop.timedate1";
    public const string OBJECT_PATH = "/org/freedesktop/timedate1";
    
    public const string PROP_TIMEZONE = "Timezone";
    public const string PROP_LOCAL_RTC = "LocalRTC";
    public const string PROP_NTP = "NTP";
    
    public abstract string timezone { owned get; }
    public abstract bool local_rtc { get; }
    public abstract bool ntp { get; }
    
    public abstract void set_time(int64 usec_etc, bool relative, bool user_interaction) throws IOError;
    public abstract void set_timezone(string timezone, bool user_interaction) throws IOError;
    public abstract void set_local_rtc(bool local_rtc, bool fix_system, bool user_interaction)
        throws IOError;
    public abstract void set_ntp(bool use_ntp, bool user_interaction) throws IOError;
}

/**
 * D-Bus interface for querying and monitoring properties.
 *
 * See [[https://pythonhosted.org/txdbus/dbus_overview.html]], "org.freedesktop.DBus.Properties"
 */

[DBus (name = "org.freedesktop.DBus.Properties")]
public interface Properties : Object {
    public const string NAME = "org.freedesktop.DBus.Properties";
    
    public signal void properties_changed(string interf, HashTable<string, Variant> changed_properties_values,
        string[] changed_properties);
    
    public abstract Variant get(string interf, string property) throws IOError;
    public abstract void get_all(string interf, HashTable<string, Variant> properties) throws IOError;
    public abstract void set(string interf, string property, Variant value) throws IOError;
}

}

