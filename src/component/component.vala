/* Copyright 2014 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

/**
 * A simplified data model of the iCalendar component scheme.
 *
 * This model is intended to limit the exposure of libical to the rest of the application, while
 * also GObject-ifying it and making its information available in a Vala-friendly manner.
 *
 * See [[https://tools.ietf.org/html/rfc5545]]
 */

namespace California.Component {

private int init_count = 0;

private string TODAY;
private string TOMORROW;
private string YESTERDAY;
private string[] TIME_PREPOSITIONS;
private string[] LOCATION_PREPOSITIONS;
private string[] DURATION_PREPOSITIONS;
private string[] DELAY_PREPOSITIONS;
private string[] ORDINAL_SUFFIXES;

public void init() throws Error {
    if (!Unit.do_init(ref init_count))
        return;
    
    // external unit init
    Collection.init();
    Calendar.init();
    
    // Used by quick-add to indicate the user wants to create an event for today.
    // For more information see https://wiki.gnome.org/Apps/California/TranslatingQuickAdd
    TODAY = _("today").casefold();
    
    // Used by quick-add to indicate the user wants to create an event for tomorrow.
    // For more information see https://wiki.gnome.org/Apps/California/TranslatingQuickAdd
    TOMORROW = _("tomorrow").casefold();
    
    // Used by quick-add to indicate the user wants to create an event for yesterday.
    // For more information see https://wiki.gnome.org/Apps/California/TranslatingQuickAdd
    YESTERDAY = _("yesterday").casefold();
    
    // Used by quick-add to determine if the word is a TIME preposition (indicating a
    // specific time of day, not a duration).  Each word must be separated by semi-colons.
    // It's allowable for some or all of these words to
    // be duplicated in the location prepositions list (elsewhere) but not another time list.
    // The list can be empty, but that will limit the parser.
    // Examples: "at 9am", "from 10pm to 11:30pm", "on monday"
    // For more information see https://wiki.gnome.org/Apps/California/TranslatingQuickAdd
    TIME_PREPOSITIONS = _("at;from;to;on;").casefold().split(";");
    
    // Used by quick-add to determine if the word is a DURATION preposition (indicating a
    // a duration of time, not a specific time).  Each word must be separated by semi-colons.
    // It's allowable for some or all of these words to
    // be duplicated in the location prepositions list (elsewhere) but not another time list.
    // The list can be empty, but that will limit the parser.
    // Examples: "for 3 hours", "for 90 minutes"
    // For more information see https://wiki.gnome.org/Apps/California/TranslatingQuickAdd
    DURATION_PREPOSITIONS = _("for;").casefold().split(";");
    
    // Used by quick-add to determine if the word is a DELAY preposition (indicating a specific
    // time from the current moment).  Each word must be separated by semi-colons.
    // It's allowable for some or all of these words to
    // be duplicated in the location prepositions list (elsewhere) but not another time list.
    // The list can be empty, but that will limit the parser.
    // Example: "in 3 hours" (meaning 3 hours from now)
    // For more information see https://wiki.gnome.org/Apps/California/TranslatingQuickAdd
    DELAY_PREPOSITIONS = _("in;").casefold().split(";");
    
    // Used by quick-add to determine if the word is a LOCATION preposition (indicating a
    // specific place).  Each word must be separated by semi-colons.
    // It's allowable for some or all of these words to be duplicated in
    // the time prepositions list (elsewhere).  The list can be empty, but that will limit the
    // parser.
    // Example: "at supermarket", "at Eiffel Tower"
    // For more information see https://wiki.gnome.org/Apps/California/TranslatingQuickAdd
    LOCATION_PREPOSITIONS = _("at;").casefold().split(";");
    
    // Used by quick-add to strip date numbers of common ordinal suffices.  Each word must be
    // separated by semi-colons.
    // The list can be empty, but that will limit the parser if your language supports ordinal
    // suffixes.
    // Example: "1st", "2nd", "3rd", "4th"
    // For more information see https://wiki.gnome.org/Apps/California/TranslatingQuickAdd
    ORDINAL_SUFFIXES = _("st;nd;rd;th").casefold().split(";");
}

public void terminate() {
    if (!Unit.do_terminate(ref init_count))
        return;
    
    TIME_PREPOSITIONS = LOCATION_PREPOSITIONS = DURATION_PREPOSITIONS = ORDINAL_SUFFIXES =
        DELAY_PREPOSITIONS =null;
    TODAY = TOMORROW = YESTERDAY = null;
    
    Calendar.terminate();
    Collection.terminate();
}

}

