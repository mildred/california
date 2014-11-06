/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Component {

/**
 * An immutable representation of an iCalendar CAL-ADDRESS (ATTENDEE, ORGANIZER, etc.)
 *
 * Person is not guaranteed to represent an individual per se, but it always represents an RFC822
 * mailbox (i.e. email address), which may be a group list address, multiuser mailbox, etc.
 *
 * For equality purposes, only the {@link mailto} is used.  All other parameters are ignored when
 * comparing Persons for equality.
 *
 * See [[https://tools.ietf.org/html/rfc5545#section-3.3.3]],
 * [[https://tools.ietf.org/html/rfc5545#section-3.8.4.1]],
 * [[https://tools.ietf.org/html/rfc5545#section-3.8.4.3]],
 * [[https://tools.ietf.org/html/rfc5545#section-3.2.2]], and more.
 */

public class Person : BaseObject, Gee.Hashable<Person>, Gee.Comparable<Person> {
    /**
     * The mailto: of the {@link Person}, the only required value for the property.
     */
    public Soup.URI mailto { get; private set; }
    
    /**
     * The CN (common name) for the {@link Person}.
     */
    public string? common_name { get; private set; default = null; }
    
    /**
     * The {@link mailto} URI as a text string.
     *
     * @see mailbox
     */
    public string mailto_text { owned get { return mailto.to_string(false); } }
    
    /**
     * The {@link mailto} as a simple (unadorned) RFC822 mailbox (i.e. email address).
     *
     * This does not include the "mailto:" scheme nor the {@link common_name}, i.e.
     * "bob@example.com"
     */
    public string mailbox { get { return mailto.path; } }
    
    /**
     * The {@link mailto} as a complete (adorned) RFC822 mailbox (i.e. email address) with
     * user-readable name, if supplied.
     *
     * This does not include the "mailto:" scheme but it will include the {@link common_name} if
     * present, i.e. "Bob Jones <bob@example.com>".
     */
    public string full_mailbox { get; private set; }
    
    private Gee.HashSet<string> parameters = new Gee.HashSet<string>(String.ci_hash, String.ci_equal);
    
    /**
     * Create an {@link Person} with the required {@link mailto} and optional {@link common_name}.
     */
    public Person(Soup.URI mailto, string? common_name) throws ComponentError {
        validate_mailto(mailto);
        
        this.mailto = mailto;
        this.common_name = common_name;
        full_mailbox = make_full_address(mailto, common_name);
        
        // store in parameters in case object is serialized as an iCal property.
        if (!String.is_empty(common_name))
            parameters.add(new iCal.icalparameter.cn(common_name).as_ical_string());
    }
    
    internal Person.from_property(iCal.icalproperty prop) throws Error {
        unowned iCal.icalvalue? prop_value = prop.get_value();
        if (prop_value == null || prop_value.is_valid() == 0) {
            throw new ComponentError.INVALID("Property of kind %s has no associated value",
                prop.isa().to_string());
        }
        
        if (prop_value.isa() != iCal.icalvalue_kind.CALADDRESS_VALUE) {
            throw new ComponentError.INVALID("Property of kind %s has value of kind %s",
                prop.isa().to_string(), prop_value.isa().to_string());
        }
        
        string uri = prop_value.get_caladdress();
        if (String.is_empty(uri))
            throw new ComponentError.INVALID("Invalid Person property: no CAL-ADDRESS value");
        
        mailto = URI.parse(uri);
        validate_mailto(mailto);
        
        // load parameters into local table
        unowned iCal.icalparameter? param = prop.get_first_parameter(iCal.icalparameter_kind.ANY_PARAMETER);
        while (param != null) {
            parameters.add(param.as_ical_string());
            
            // parse parameter into well-known (common) property
            switch (param.isa()) {
                case iCal.icalparameter_kind.CN_PARAMETER:
                    common_name = param.get_cn();
                break;
                
                default:
                    // fall-through
                break;
            }
            
            param = prop.get_next_parameter(iCal.icalparameter_kind.ANY_PARAMETER);
        }
        
        full_mailbox = make_full_address(mailto, common_name);
    }
    
    private static void validate_mailto(Soup.URI uri) throws ComponentError {
        if (uri.scheme != "mailto" || String.is_empty(uri.path))
            throw new ComponentError.INVALID("Invalid mailto: %s", uri.to_string(false));
    }
    
    private static string make_full_address(Soup.URI mailto, string? common_name) {
        // watch for common name simply being the email address
        if (String.is_empty(common_name) || String.ascii_ci_equal(mailto.path, common_name))
            return mailto.path;
        
        return "%s <%s>".printf(common_name, mailto.path);
    }
    
    internal iCal.icalproperty as_ical_property() {
        iCal.icalproperty prop = new iCal.icalproperty.attendee(mailto_text);
        foreach (string parameter in parameters)
            prop.add_parameter(new iCal.icalparameter.from_string(parameter));
        
        return prop;
    }
    
    public uint hash() {
        return String.ci_hash(mailto.path);
    }
    
    public bool equal_to(Person other) {
        return (this != other) ? String.ci_equal(mailto.path, other.mailto.path) : true;
    }
    
    public int compare_to(Person other) {
        if (this == other)
            return 0;
        
        // if a common name is supplied, use that first, but need to stabilize sort
        if (!String.is_empty(common_name) && !String.is_empty(other.common_name)) {
            int compare = String.stricmp(common_name, other.common_name);
            if (compare != 0)
                return compare;
        }
        
        return String.stricmp(mailbox, other.mailbox);
    }
    
    public override string to_string() {
        return mailto_text;
    }
}

}

