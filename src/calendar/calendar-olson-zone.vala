/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Calendar {

/**
 * The Olson name of a time zone in the tz (or zoneinfo) database.
 *
 * An Olson name is in the form of "Area/Location".  This class merely encapsulates this string
 * and gives it some type-ness; actual time zone calculations is left to {@link Timezone}.
 * In particular, little error-checking is performed by this class.  It also does no processing
 * or consideration for zone aliases ("links").  It is Gee.Hashable, but that is purely based on
 * string comparisons with no other logic involved.
 *
 * This class is immutable.
 *
 * Future expansion may include some processing or parsing of the name itself, but that's not
 * planned at the moment.
 *
 * The IANA database of Olson zones and related information is located at
 * [[https://www.iana.org/time-zones]]
 *
 * @see WindowsZone
 */

public class OlsonZone : BaseObject, Gee.Hashable<OlsonZone> {
    /**
     * The string value this class uses if an empty string is passed to the constructor.
     *
     * Note that this is not the only definition of UTC in the zoneinfo database.  That is,
     * a simple comparison of {@link value} to this constant is no guarantee that an
     * {@link OlsonZone} is or is not UTC.
     */
    public const string UTC = "UTC";
    
    /**
     * An {@link OlsonZone} representation of UTC.
     *
     * @see UTC
     */
    public static OlsonZone utc { get; private set; }
    
    /**
     * The raw Olson zoneinfo name.
     */
    public string value { get; private set; }
    
    private static Gee.HashMap<string, OlsonZone>? windows_to_olson = null;
    
    public OlsonZone(string area_location) {
        string stripped = area_location.strip();
        value = !String.is_empty(stripped) ? stripped : UTC;
    }
    
    internal static void init() {
        utc = new OlsonZone(UTC);
    }
    
    // Load Windows -> Olson conversion table
    internal static void load_conversions() throws Error {
        windows_to_olson = new Gee.HashMap<string, OlsonZone>(String.stri_hash, String.stri_equal);
        
        // to conserve resident objects, as these will stick around the lifetime of the application
        Gee.HashMap<string, OlsonZone> name_to_olson = new Gee.HashMap<string, OlsonZone>(
            String.stri_hash, String.stri_equal);
        
        // Yes, we should be doing this with a proper XML DOM library, but (a) libxml2 is kind of
        // messy to work with, (b) it doesn't guarantee to be compiled with XPath support, which
        // would sure make our lives easier here, and (c) we're in complete control of the data being
        // parsed, and so XML validation and correct traversal is less important
        char[] windows_buf = new char[4096];
        char[] territory_buf = new char[4096];
        char[] olson_buf = new char[4096];
        DataInputStream dins = new DataInputStream(
            new MemoryInputStream.from_bytes(Resource.load_bytes("windowsZones.xml")));
        dins.set_newline_type(DataStreamNewlineType.ANY);
        for (;;) {
            string? line = dins.read_line();
            if (line == null)
                break;
            
            line = line.strip();
            if (String.is_empty(line))
                continue;
            
            // Note that the width specifier matches the size of the character arrays above
            int count = line.scanf("<mapZone other=\"%4096[^\"]\" territory=\"%4096[^\"]\" type=\"%4096[^\"]\"/>",
                windows_buf, territory_buf, olson_buf);
            if (count != 3)
                continue;
            
            // only interested in territory "001", the primary territory, which is how the conversion
            // is made
            string territory = ((string) territory_buf).strip();
            if (territory != "001")
                continue;
            
            string windows = ((string) windows_buf).strip();
            assert(!String.is_empty(windows));
            
            string olson = ((string) olson_buf).strip();
            assert(!String.is_empty(olson));
            
            // unlike other entries, 001 is always a single Olson code, otherwise the value would
            // need to be tokenized
            assert(!olson.contains(" "));
            
            // conserve Olson zone objects (one can be assigned to many Windows zone names)
            OlsonZone? olson_zone = name_to_olson.get(olson);
            if (olson_zone == null) {
                olson_zone = new OlsonZone(olson);
                name_to_olson.set(olson_zone.value, olson_zone);
            }
            
            assert(!windows_to_olson.has_key(windows));
            windows_to_olson.set(windows, olson_zone);
        }
    }
    
    internal static void terminate() {
        utc = null;
        windows_to_olson = null;
    }
    
    /**
     * Returns the {@link OlsonZone}, if any, for a Windows zone name.
     *
     * Windows time zone names tend to be a single descriptive string, such as "Pacific Standard Time".
     * There are often variations of the same time zone with different names depending on political
     * and national bounaries.  They are always transmitted in English.
     *
     * For more information, see
     * [[http://technet.microsoft.com/en-us/library/cc749073%28v=ws.10%29.aspx]]
     */
    public OlsonZone? for_windows_zone(string name) {
        assert(windows_to_olson != null);
        
        return windows_to_olson.get(name.strip());
    }
    
    /**
     * See the class notes for stipulations about object equality.
     */
    public uint hash() {
        return String.stri_hash(value);
    }
    
    /**
     * See the class notes for stipulations about object equality.
     */
    public bool equal_to(OlsonZone other) {
        return (this != other) ? String.stri_equal(value, other.value) : true;
    }
    
    public override string to_string() {
        return value;
    }
}

}
