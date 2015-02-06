/* Copyright 2014-2015 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Component {

/**
 * A mutable convenience representation of an iCalendar recurrence rule (RRULE).
 *
 * See [[https://tools.ietf.org/html/rfc5545#section-3.3.10]]
 * and [[https://tools.ietf.org/html/rfc5545#section-3.8.5.3]]
 */

public class RecurrenceRule : BaseObject {
    public const string PROP_FREQ = "freq";
    public const string PROP_UNTIL = "until";
    public const string PROP_COUNT = "count";
    public const string PROP_INTERVAL = "interval";
    public const string PROP_FIRST_OF_WEEK = "first-of-week";
    
    private const Calendar.Date.PrettyFlag UNTIL_DATE_PRETTY_FLAGS =
        Calendar.Date.PrettyFlag.ABBREV
        | Calendar.Date.PrettyFlag.NO_DAY_OF_WEEK
        | Calendar.Date.PrettyFlag.INCLUDE_OTHER_YEAR;
    
    private const Calendar.WallTime.PrettyFlag UNTIL_TIME_PRETTY_FLAGS =
        Calendar.WallTime.PrettyFlag.NONE;
    
    /**
     * Enumeration of various BY rules (BYSECOND, BYMINUTE, etc.)
     */
    public enum ByRule {
        SECOND = 0,
        MINUTE,
        HOUR,
        DAY,
        MONTH_DAY,
        YEAR_DAY,
        WEEK_NUM,
        MONTH,
        SET_POS,
        /**
         * The number of {@link ByRule}s, this is not a valid value.
         */
        COUNT;
    }
    
    /**
     * Frequency.
     *
     * This is the only required field in an RRULE.
     */
    public iCal.icalrecurrencetype_frequency freq { get; set; }
    
    /**
     * Returns true if {@link freq} is iCal.icalrecurrencetype_frequence.DAILY_RECURRENCE,
     */
    public bool is_daily { get { return freq == iCal.icalrecurrencetype_frequency.DAILY_RECURRENCE; } }
    
    /**
     * Returns true if {@link freq} is iCal.icalrecurrencetype_frequence.DAILY_RECURRENCE,
     */
    public bool is_weekly { get { return freq == iCal.icalrecurrencetype_frequency.WEEKLY_RECURRENCE; } }
    
    /**
     * Returns true if {@link freq} is iCal.icalrecurrencetype_frequence.MONTHLY_RECURRENCE,
     */
    public bool is_monthly { get { return freq == iCal.icalrecurrencetype_frequency.MONTHLY_RECURRENCE; } }
    
    /**
     * Returns true if {@link freq} is iCal.icalrecurrencetype_frequence.YEARLY_RECURRENCE,
     */
    public bool is_yearly { get { return freq == iCal.icalrecurrencetype_frequency.YEARLY_RECURRENCE; } }
    
    /**
     * Until (end date), inclusive.
     *
     * This is mutually exclusive with {@link count} and {@link until_exact_time}.
     *
     * @see set_until_date
     */
    public Calendar.Date? until_date { get; private set; default = null; }
    
    /**
     * Until (end date/time).
     *
     * This is mutually exclusive with {@link count} and {@link until_date}.
     *
     * @see set_until_exact_time
     */
    public Calendar.ExactTime? until_exact_time { get; private set; default = null; }
    
    /**
     * Total number of recurrences.
     *
     * Zero indicates "not set", not zero recurrences.
     *
     * This is mutually exclusive with {@link until_date} and {@link until_exact_time}.
     *
     * @see set_recurrence_count
     */
    public int count { get; private set; default = 0; }
    
    /**
     * Returns true if the recurrence rule has a duration.
     *
     * @see until
     * @see count
     */
    public bool has_duration { get { return until_date != null || until_exact_time != null || count > 0; } }
    
    /**
     * Interval between recurrences.
     *
     * A positive integer representing the interval (duration between) of each recurrence.  The
     * actual amount of time elapsed is determined by the {@link frequency} property.
     *
     * interval may be any value from 1 to short.MAX.
     */
    private int _interval = 1;
    public int interval {
        get { return _interval; }
        set { _interval = value.clamp(1, short.MAX); }
    }
    
    /**
     * Start of work week (WKST).
     */
    public Calendar.DayOfWeek? first_of_week { get; set; default = null; }
    
    private Gee.SortedSet<int> by_second = new Gee.TreeSet<int>();
    private Gee.SortedSet<int> by_minute = new Gee.TreeSet<int>();
    private Gee.SortedSet<int> by_hour = new Gee.TreeSet<int>();
    private Gee.SortedSet<int> by_day = new Gee.TreeSet<int>();
    private Gee.SortedSet<int> by_month_day = new Gee.TreeSet<int>();
    private Gee.SortedSet<int> by_year_day = new Gee.TreeSet<int>();
    private Gee.SortedSet<int> by_week_num = new Gee.TreeSet<int>();
    private Gee.SortedSet<int> by_month = new Gee.TreeSet<int>();
    private Gee.SortedSet<int> by_set_pos = new Gee.TreeSet<int>();
    
    /**
     * Fired when a BY rule is updated (BYSECOND, BYMINUTE, etc.)
     */
    public signal void by_rule_updated(ByRule by_rule);
    
    public RecurrenceRule(iCal.icalrecurrencetype_frequency freq) {
        this.freq = freq;
    }
    
    internal RecurrenceRule.from_ical(iCal.icalcomponent ical_component, bool strict) throws Error {
        // need DTSTART for timezone purposes
        DateTime dtstart = new DateTime(ical_component, iCal.icalproperty_kind.DTSTART_PROPERTY);
        
        // fetch the RRULE from the component
        unowned iCal.icalproperty? rrule_property = ical_component.get_first_property(
            iCal.icalproperty_kind.RRULE_PROPERTY);
        if (rrule_property == null)
            throw new ComponentError.UNAVAILABLE("No RRULE found in component");
        
        iCal.icalrecurrencetype rrule = rrule_property.get_rrule();
        
        freq = rrule.freq;
        interval = rrule.interval;
        
        if (rrule.count > 0) {
            set_recurrence_count(rrule.count);
        } else {
            try {
                Component.DateTime date_time = new DateTime.rrule_until(rrule, dtstart, strict);
                if (date_time.is_date)
                    set_recurrence_end_date(date_time.to_date());
                else
                    set_recurrence_end_exact_time(date_time.to_exact_time());
            } catch (ComponentError comperr) {
                if (!(comperr is ComponentError.UNAVAILABLE))
                    throw comperr;
            }
        }
        
        switch (rrule.week_start) {
            case iCal.icalrecurrencetype_weekday.SUNDAY_WEEKDAY:
                first_of_week = Calendar.DayOfWeek.SUN;
            break;
            
            case iCal.icalrecurrencetype_weekday.MONDAY_WEEKDAY:
                first_of_week = Calendar.DayOfWeek.MON;
            break;
            
            case iCal.icalrecurrencetype_weekday.TUESDAY_WEEKDAY:
                first_of_week = Calendar.DayOfWeek.TUE;
            break;
            
            case iCal.icalrecurrencetype_weekday.WEDNESDAY_WEEKDAY:
                first_of_week = Calendar.DayOfWeek.WED;
            break;
            
            case iCal.icalrecurrencetype_weekday.THURSDAY_WEEKDAY:
                first_of_week = Calendar.DayOfWeek.THU;
            break;
            
            case iCal.icalrecurrencetype_weekday.FRIDAY_WEEKDAY:
                first_of_week = Calendar.DayOfWeek.FRI;
            break;
            
            case iCal.icalrecurrencetype_weekday.SATURDAY_WEEKDAY:
                first_of_week = Calendar.DayOfWeek.SAT;
            break;
            
            case iCal.icalrecurrencetype_weekday.NO_WEEKDAY:
            default:
                first_of_week = null;
            break;
        }
        
        fill_by(rrule.by_second, by_second);
        fill_by(rrule.by_minute, by_minute);
        fill_by(rrule.by_hour, by_hour);
        fill_by(rrule.by_day, by_day);
        fill_by(rrule.by_month_day, by_month_day);
        fill_by(rrule.by_year_day, by_year_day);
        fill_by(rrule.by_week_no, by_week_num);
        fill_by(rrule.by_month, by_month);
        fill_by(rrule.by_set_pos, by_set_pos);
    }
    
    private void fill_by(short[] ical_by_ar, Gee.SortedSet<int> by_set) {
        for (int ctr = 0; ctr < ical_by_ar.length; ctr++) {
            short by = ical_by_ar[ctr];
            if (by == iCal.RECURRENCE_ARRAY_MAX)
                break;
            
            by_set.add(by);
        }
    }
    
    /**
     * Sets the {@link until_date} property.
     *
     * Also sets {@link count} to zero and nulls out {@link until_exact_time}.
     *
     * Passing null will clear all these properties.
     */
    public void set_recurrence_end_date(Calendar.Date? date) {
        freeze_notify();
        
        until_date = date;
        until_exact_time = null;
        count = 0;
        
        thaw_notify();
    }
    
    /**
     * Sets the {@link until_exact_time} property.
     *
     * Also sets {@link count} to zero and nulls out {@link until_date}.
     *
     * Passing null will clear all these properties.
     */
    public void set_recurrence_end_exact_time(Calendar.ExactTime? exact_time) {
        freeze_notify();
        
        until_date = null;
        until_exact_time = exact_time;
        count = 0;
        
        thaw_notify();
    }
    
    /**
     * Returns the UNTIL property as a {@link Calendar.Date}.
     *
     * If {@link until_exact_time} is set, only the Date portion is returned.
     *
     * @returns null if neither {@link until_date} or until_exact_time is set.
     */
    public Calendar.Date? get_recurrence_end_date() {
        if (until_date != null)
            return until_date;
        
        if (until_exact_time != null)
            return new Calendar.Date.from_exact_time(until_exact_time);
        
        return null;
    }
    
    /**
     * Sets the {@link count} property.
     *
     * Also clears {@link until_date} and {@link until_exact_time}.
     *
     * Passing zero will clear all these properties.
     */
    public void set_recurrence_count(int count) {
        freeze_notify();
        
        until_date = null;
        until_exact_time = null;
        this.count = count.clamp(0, int.MAX);
        
        thaw_notify();
    }
    
    /**
     * Encode a {@link Calendar.DayOfWeek} and its position (i.e. second Thursday of the month,
     * last Wednesday of the year) into a value for {@link set_by_rule} when using
     * {@link ByRule.DAY}.
     *
     * For position, 1 = first, 2 = second, -1 = last, -2 = second to last, etc.
     *
     * See [[https://tools.ietf.org/html/rfc5545#section-3.3.10]] for information how these values
     * operate according to this RRULE's {@link freq}.
     *
     * Use null for DayOfWeek and zero for position to mean "any" or "every".
     *
     * @see encode_days
     * @see decode_day
     */
    public static int encode_day(Calendar.DayOfWeek? dow, int position) {
        // these encodings are mapped to iCal.icalrecurrencetype_weekday, which is SUNDAY-based
        int dow_value = (dow != null) ? dow.ordinal(Calendar.FirstOfWeek.SUNDAY) : 0;
        
        position = position.clamp(short.MIN, short.MAX);
        int value = (position * 8) + (position >= 0 ? dow_value : 0 - dow_value);
        
        return value;
    }
    
    /**
     * Decode the integer returned by {@link get_by_rule} when {@link ByRule.DAY} passed in.
     *
     * If null is returned for DayOfWeek or zero for position, that indicates "any" or "every".
     * See {@link encode_day} for more information.
     *
     * See [[https://tools.ietf.org/html/rfc5545#section-3.3.10]] for information how these values
     * operate according to this RRULE's {@link freq}.
     *
     * Returns false if the supplied value is definitely not encoded correctly.
     */
    public static bool decode_day(int value, out Calendar.DayOfWeek? dow, out int position) {
        position = iCal.icalrecurrencetype.day_position((short) value);
        
        dow = null;
        int dow_value = (int) iCal.icalrecurrencetype.day_day_of_week((short) value);
        if (dow_value != 0) {
            try {
                // iCal.icalrecurrencetype_weekday is SUNDAY-based
                dow = Calendar.DayOfWeek.for(dow_value, Calendar.FirstOfWeek.SUNDAY);
            } catch (CalendarError calerr) {
                debug("Unable to decode day of week value %d: %s", dow_value, calerr.message);
                
                return false;
            }
        }
        
        return true;
    }
    
    /**
     * Encode a Gee.Map of {@link Calendar.DayOfWeek} and its position into a value for
     * {@link set_by_rule} when using {@link ByRule.DAY}.
     *
     * See {@link encode_day} for more information about how encoding works.
     */
    public static Gee.Collection<int> encode_days(Gee.Map<Calendar.DayOfWeek?, int>? day_values) {
        if (day_values == null || day_values.size == 0)
            return Gee.Collection.empty<int>();
        
        Gee.Collection<int> encoded = new Gee.ArrayList<int>();
        Gee.MapIterator<Calendar.DayOfWeek?, int> iter = day_values.map_iterator();
        while (iter.next())
            encoded.add(encode_day(iter.get_key(), iter.get_value()));
        
        return encoded;
    }
    
    /**
     * Decode a Gee.Collection of encoded {@link ByRule.DAY} values into their positions and
     * {@link Calendar.DayOfWeek}.
     *
     * Invalid values are skipped.
     *
     * @see encode_day
     * @see encode_days
     * @see decode_day
     */
    public static Gee.Map<Calendar.DayOfWeek?, int> decode_days(Gee.Collection<int>? values) {
        if (values == null || values.size == 0)
            return Gee.Map.empty<Calendar.DayOfWeek?, int>();
        
        Gee.Map<Calendar.DayOfWeek?, int> decoded = new Gee.HashMap<Calendar.DayOfWeek?, int>();
        foreach (int value in values) {
            Calendar.DayOfWeek? dow;
            int position;
            if (decode_day(value, out dow, out position))
                decoded.set(dow, position);
        }
        
        return decoded;
    }
    
    private Gee.SortedSet<int> get_by_set(ByRule by_rule) {
        switch (by_rule) {
            case ByRule.SECOND:
                return by_second;
            
            case ByRule.MINUTE:
                return by_minute;
            
            case ByRule.HOUR:
                return by_hour;
            
            case ByRule.DAY:
                return by_day;
            
            case ByRule.MONTH_DAY:
                return by_month_day;
            
            case ByRule.YEAR_DAY:
                return by_year_day;
            
            case ByRule.WEEK_NUM:
                return by_week_num;
            
            case ByRule.MONTH:
                return by_month;
            
            case ByRule.SET_POS:
                return by_set_pos;
            
            default:
                assert_not_reached();
        }
    }
    
    /**
     * Returns a read-only sorted set of BY rule settings for the specified {@link ByRule}.
     *
     * Note that because BYDAY rules are bit-encoded, their sorting has no relationship to their
     * decoded values.  Callers should decode each value and sort them according to their needs.
     *
     * See [[https://tools.ietf.org/html/rfc5545#section-3.3.10]] for information how these values
     * operate according to their associated ByRule and this RRULE's {@link freq}.
     */
    public Gee.SortedSet<int> get_by_rule(ByRule by_rule) {
        return get_by_set(by_rule).read_only_view;
    }
    
    private bool is_int_short(int value) {
        return value >= short.MIN && value <= short.MAX;
    }
    
    /**
     * Replaces the existing set of values for the BY rules with the supplied values.
     *
     * See [[https://tools.ietf.org/html/rfc5545#section-3.3.10]] for information how these values
     * operate according to their associated ByRule and this RRULE's {@link freq}.
     *
     * Pass null or an empty Collection to clear the by-rules values.
     *
     * Any value greater than short.MAX or less than short.MIN will be dropped.
     *
     * Use {@link encode_days} when passing values for {@link ByRule.DAY}.
     *
     * @see add_by_rule
     * @see by_rule_updated
     */
    public void set_by_rule(ByRule by_rule, Gee.Collection<int>? values) {
        Gee.SortedSet<int> by_set = get_by_set(by_rule);
        
        by_set.clear();
        if (values != null && values.size > 0)
            by_set.add_all(traverse<int>(values).filter(is_int_short).to_array_list());
        
        by_rule_updated(by_rule);
    }
    
    /**
     * Adds the supplied values to the existing set of values for the BY rules.
     *
     * See [[https://tools.ietf.org/html/rfc5545#section-3.3.10]] for information how these values
     * operate according to their associated ByRule and this RRULE's {@link freq}.
     *
     * Null or an empty Collection is a no-op.
     *
     * Any value greater than short.MAX or less than short.MIN will be dropped.
     *
     * Use {@link encode_days} when passing values for {@link ByRule.DAY}.
     *
     * @see set_by_rule
     * @see by_rule_updated
     */
    public void add_by_rule(ByRule by_rule, Gee.Collection<int>? values) {
        Gee.SortedSet<int> by_set = get_by_set(by_rule);
        
        if (values != null && values.size > 0)
            by_set.add_all(traverse<int>(values).filter(is_int_short).to_array_list());
        
        by_rule_updated(by_rule);
    }
    
    /**
     * Returns a Gee.Set of {@link ByRule}s that are active, i.e. have defined rules.
     */
    public Gee.Set<ByRule> get_active_by_rules() {
        Gee.Set<ByRule> active = new Gee.HashSet<ByRule>();
        for (int ctr = 0; ctr < ByRule.COUNT; ctr++) {
            ByRule by_rule = (ByRule) ctr;
            
            if (get_by_set(by_rule).size > 0)
                active.add(by_rule);
        }
        
        return active;
    }
    
    /**
     * Converts a {@link RecurrenceRule} into an iCalendar RRULE property and adds it to the
     * iCal component.
     *
     * This call makes no attempt to remove an existing RRULE property; that should be performed by
     * the caller first.
     */
    internal void add_to_ical(iCal.icalcomponent ical_component) {
        iCal.icalrecurrencetype rrule = { 0 };
        
        rrule.freq = freq;
        
        if (until_date != null)
            date_to_ical(until_date, &rrule.until);
        else if (until_exact_time != null)
            exact_time_to_ical(until_exact_time, &rrule.until);
        else if (count > 0)
            rrule.count = count;
        
        rrule.interval = (short) interval;
        
        if (first_of_week == null)
            rrule.week_start = iCal.icalrecurrencetype_weekday.NO_WEEKDAY;
        else if (first_of_week == Calendar.DayOfWeek.SUN)
            rrule.week_start = iCal.icalrecurrencetype_weekday.SUNDAY_WEEKDAY;
        else if (first_of_week == Calendar.DayOfWeek.MON)
            rrule.week_start = iCal.icalrecurrencetype_weekday.MONDAY_WEEKDAY;
        else if (first_of_week == Calendar.DayOfWeek.TUE)
            rrule.week_start = iCal.icalrecurrencetype_weekday.TUESDAY_WEEKDAY;
        else if (first_of_week == Calendar.DayOfWeek.WED)
            rrule.week_start = iCal.icalrecurrencetype_weekday.WEDNESDAY_WEEKDAY;
        else if (first_of_week == Calendar.DayOfWeek.THU)
            rrule.week_start = iCal.icalrecurrencetype_weekday.THURSDAY_WEEKDAY;
        else if (first_of_week == Calendar.DayOfWeek.FRI)
            rrule.week_start = iCal.icalrecurrencetype_weekday.FRIDAY_WEEKDAY;
        else if (first_of_week == Calendar.DayOfWeek.SAT)
            rrule.week_start = iCal.icalrecurrencetype_weekday.SATURDAY_WEEKDAY;
        else
            assert_not_reached();
        
        fill_ical_by(by_second, &rrule.by_second[0], rrule.by_second.length);
        fill_ical_by(by_minute, &rrule.by_minute[0], rrule.by_minute.length);
        fill_ical_by(by_hour, &rrule.by_hour[0], rrule.by_hour.length);
        fill_ical_by(by_day, &rrule.by_day[0], rrule.by_day.length);
        fill_ical_by(by_month_day, &rrule.by_month_day[0], rrule.by_month_day.length);
        fill_ical_by(by_year_day, &rrule.by_year_day[0], rrule.by_year_day.length);
        fill_ical_by(by_week_num, &rrule.by_week_no[0], rrule.by_week_no.length);
        fill_ical_by(by_month, &rrule.by_month[0], rrule.by_month.length);
        fill_ical_by(by_set_pos, &rrule.by_set_pos[0], rrule.by_set_pos.length);
        
        iCal.icalproperty rrule_property = new iCal.icalproperty(iCal.icalproperty_kind.RRULE_PROPERTY);
        rrule_property.set_rrule(rrule);
        
        ical_component.add_property(rrule_property);
    }
    
    private void fill_ical_by(Gee.SortedSet<int> by_set, short *ical_by_ar, int ar_length) {
        int index = 0;
        foreach (int by in by_set) {
            ical_by_ar[index++] = (short) by;
            
            // watch for overflow
            if (index >= ar_length)
                break;
        }
        
        if (index < ar_length)
            ical_by_ar[index] = (short) iCal.RECURRENCE_ARRAY_MAX;
    }
    
    /**
     * Returns a natural-language string explaining the {@link RecurrenceRule} for the user.
     *
     * The start_date should be the starting date of the associated {@link Instance}.
     *
     * Returns null if the RRULE is beyond the comprehension of this parser.
     */
    public string? explain(Calendar.Date start_date) {
        switch (freq) {
            case iCal.icalrecurrencetype_frequency.DAILY_RECURRENCE:
                return explain_daily(ngettext("%d day", "%d days", interval).printf(interval));
            
            case iCal.icalrecurrencetype_frequency.WEEKLY_RECURRENCE:
                return explain_weekly(ngettext("%d week", "%d weeks", interval).printf(interval));
            
            case iCal.icalrecurrencetype_frequency.MONTHLY_RECURRENCE:
                Gee.Set<ByRule> byrules = get_active_by_rules();
                bool has_byday = byrules.contains(ByRule.DAY);
                bool has_bymonthday = byrules.contains(ByRule.MONTH_DAY);
                
                // requires one and only one
                if (has_byday == has_bymonthday || byrules.size != 1)
                    return null;
                
                string unit = ngettext("%d month", "%d months", interval).printf(interval);
                
                if (has_byday)
                    return explain_monthly_byday(unit);
                else
                    return explain_monthly_bymonthday(unit);
            
            case iCal.icalrecurrencetype_frequency.YEARLY_RECURRENCE:
                return explain_yearly(ngettext("%d year", "%d years", interval).printf(interval), start_date);
            
            default:
                return null;
        }
        
    }
    
    private string? explain_daily(string units) {
        // only explain basic DAILY RRULEs
        if (get_active_by_rules().size != 0)
            return null;
        
        if (count > 0) {
            // As in, "Repeats every day, 2 times"
            return _("Repeats every %s, %s").printf(units,
                ngettext("%d time", "%d times", count).printf(count)
            );
        }
        
        if (until_date != null) {
            // As in, "Repeats every week until Sept. 2, 2014"
            return _("Repeats every %s until %s").printf(units,
                until_date.to_pretty_string(UNTIL_DATE_PRETTY_FLAGS)
            );
        }
        
        if (until_exact_time != null) {
            // As in, "Repeats every month until Sept. 2, 2014, 8:00pm"
            return _("Repeats every %s until %s, %s").printf(units,
                until_exact_time.to_pretty_date_string(UNTIL_DATE_PRETTY_FLAGS),
                until_exact_time.to_pretty_time_string(UNTIL_TIME_PRETTY_FLAGS)
            );
        }
        
        // As in, "Repeats every day"
        return _("Repeats every %s").printf(units);
    }
    
    // Use only with WEEKLY RRULEs
    private string? explain_days_of_the_week() {
        // Gather all the DayOfWeeks amd sort by start of week
        Gee.TreeSet<Calendar.DayOfWeek> dows = new Gee.TreeSet<Calendar.DayOfWeek>(
            Calendar.DayOfWeek.get_comparator_for_first_of_week(Calendar.System.first_of_week));
        foreach (int day in get_by_rule(ByRule.DAY)) {
            Calendar.DayOfWeek dow;
            if (!decode_day(day, out dow, null))
                return null;
            
            dows.add(dow);
        }
        
        // must be at least one to work
        if (dows.size == 0)
            return null;
        
        // look for expressible patterns
        if (dows.size == Calendar.DayOfWeek.COUNT)
            return _("every day");
        
        Gee.Collection<Calendar.DayOfWeek> weekend_days =
            from_array<Calendar.DayOfWeek>(Calendar.DayOfWeek.weekend_days).to_array_list();
        if (Collection.equal<Calendar.DayOfWeek>(weekend_days, dows))
            return _("the weekend");
        
        Gee.Collection<Calendar.DayOfWeek> weekdays =
            from_array<Calendar.DayOfWeek>(Calendar.DayOfWeek.weekdays).to_array_list();
        if (Collection.equal<Calendar.DayOfWeek>(weekdays, dows))
            return _("weekdays");
        
        // assemble a text list of days
        StringBuilder days_of_the_week = new StringBuilder();
        bool first = true;
        foreach (Calendar.DayOfWeek dow in dows) {
            if (!first) {
                // Separator between days of the week, i.e. "Monday, Tuesday, Wednesday"
                days_of_the_week.append(_(", "));
            }
            
            days_of_the_week.append(dow.abbrev_name);
            first = false;
        }
        
        return days_of_the_week.str;
    }
    
    private string? explain_weekly(string units) {
        // can only explain WEEKLY BYDAY rules
        Gee.Set<ByRule> byrules = get_active_by_rules();
        if (byrules.size != 1 || !byrules.contains(ByRule.DAY))
            return null;
        
        string? days_of_the_week = explain_days_of_the_week();
        if (String.is_empty(days_of_the_week))
            return null;
        
        if (count > 0) {
            // As in, "Repeats every week on Monday, Tuesday, 3 times"
            return _("Repeats every %s on %s, %s").printf(units, days_of_the_week,
                ngettext("%d time", "%d times", count).printf(count)
            );
        }
        
        if (until_date != null) {
            // As in, "Repeats every week on Thursday until Sept. 2, 2014"
            return _("Repeats every %s on %s until %s").printf(units, days_of_the_week,
                until_date.to_pretty_string(UNTIL_DATE_PRETTY_FLAGS)
            );
        }
        
        if (until_exact_time != null) {
            // As in, "Repeats every week on Friday, Saturday until Sept. 2, 2014, 8:00pm"
            return _("Repeats every %s on %s until %s, %s").printf(units, days_of_the_week,
                until_exact_time.to_pretty_date_string(UNTIL_DATE_PRETTY_FLAGS),
                until_exact_time.to_pretty_time_string(UNTIL_TIME_PRETTY_FLAGS)
            );
        }
        
        // As in, "Repeats every week on Monday, Wednesday, Friday"
        return _("Repeats every %s on %s").printf(units, days_of_the_week);
    }
    
    private string? explain_monthly_byday(string units) {
        // only support one day of the week for BYMONTHDAT RRULEs
        Gee.Set<int> byday = get_by_rule(ByRule.DAY);
        if (byday.size != 1)
            return null;
        
        Calendar.DayOfWeek? dow;
        int position;
        if (!decode_day(traverse<int>(byday).first(), out dow, out position))
            return null;
        
        // only support a small set of possibilites here
        if (dow == null)
            return null;
        
        string? day = dow.get_day_of_week_of_month(position);
        if (String.is_empty(day))
            return null;
        
        if (count > 0) {
            // As in, "Repeats every month on the first Tuesday, 3 times"
            return _("Repeats every %s on the %s, %s").printf(units, day,
                ngettext("%d time", "%d times", count).printf(count)
            );
        }
        
        if (until_date != null) {
            // As in, "Repeats every month on the second Monday until Sept. 2, 2014"
            return _("Repeats every %s on the %s until %s").printf(units, day,
                until_date.to_pretty_string(UNTIL_DATE_PRETTY_FLAGS)
            );
        }
        
        if (until_exact_time != null) {
            // As in, "Repeats every month on the last Friday until Sept. 2, 2014, 8:00pm"
            return _("Repeats every %s on the %s until %s, %s").printf(units, day,
                until_exact_time.to_pretty_date_string(UNTIL_DATE_PRETTY_FLAGS),
                until_exact_time.to_pretty_time_string(UNTIL_TIME_PRETTY_FLAGS)
            );
        }
        
        // As in, "Repeats every month on the third Tuesday"
        return _("Repeats every %s on the %s").printf(units, day);
    }
    
    private string? explain_monthly_bymonthday(string units) {
        // only MONTHLY BYDAY RRULEs
        Gee.Set<int> byrules = get_active_by_rules();
        if (byrules.size != 1 || !byrules.contains(ByRule.MONTH_DAY))
            return null;
        
        // currently only support one monthday (generally, the same as DTSTART)
        Gee.Set<int> monthdays = get_by_rule(ByRule.MONTH_DAY);
        if (monthdays.size != 1)
            return null;
        
        // As in, "Repeats on day 4 of the month"
        string day = _("day %d").printf(traverse<int>(monthdays).first());
        
        if (count > 0) {
            // As in, "Repeats every month on day 4, 3 times"
            return _("Repeats every %s on %s, %s").printf(units, day,
                ngettext("%d time", "%d times", count).printf(count)
            );
        }
        
        if (until_date != null) {
            // As in, "Repeats every month on day 21 until Sept. 2, 2014"
            return _("Repeats every %s on %s until %s").printf(units, day,
                until_date.to_pretty_string(UNTIL_DATE_PRETTY_FLAGS)
            );
        }
        
        if (until_exact_time != null) {
            // As in, "Repeats every month on day 20 until Sept. 2, 2014, 8:00pm"
            return _("Repeats every %s on %s until %s, %s").printf(units, day,
                until_exact_time.to_pretty_date_string(UNTIL_DATE_PRETTY_FLAGS),
                until_exact_time.to_pretty_time_string(UNTIL_TIME_PRETTY_FLAGS)
            );
        }
        
        // As in, "Repeats every month on day 5"
        return _("Repeats every %s on %s").printf(units, day);
    }
    
    private string? explain_yearly(string units, Calendar.Date start_date) {
        // only explain basic YEARLY RRULEs
        if (get_active_by_rules().size != 0)
            return null;
        
        string date = start_date.to_pretty_string(
            Calendar.Date.PrettyFlag.NO_DAY_OF_WEEK
            | Calendar.Date.PrettyFlag.NO_TODAY
            | Calendar.Date.PrettyFlag.ABBREV
        );
        
        if (count > 0) {
            // As in, "Repeats every year on 3 March 2014, 2 times"
            return _("Repeats every %s on %s, %s").printf(units, date,
                ngettext("%d time", "%d times", count).printf(count)
            );
        }
        
        if (until_date != null) {
            // As in, "Repeats every year on 3 March 2014 until Sept. 2, 2014"
            return _("Repeats every %s on %s until %s").printf(units, date,
                until_date.to_pretty_string(UNTIL_DATE_PRETTY_FLAGS)
            );
        }
        
        if (until_exact_time != null) {
            // As in, "Repeats every year on 3 March 2014 until Sept. 2, 2014, 8:00pm"
            return _("Repeats every %s on %s until %s, %s").printf(units, date,
                until_exact_time.to_pretty_date_string(UNTIL_DATE_PRETTY_FLAGS),
                until_exact_time.to_pretty_time_string(UNTIL_TIME_PRETTY_FLAGS)
            );
        }
        
        // As in, "Repeats every year on 3 March 2014"
        return _("Repeats every %s on %s").printf(units, date);
    }
    
    public override string to_string() {
        return "RRULE %s".printf(freq.to_string());
    }
}

}

