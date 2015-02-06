/**
 * nl_langinfo bindings.
 *
 * Copyright 2014-2015 Yorba Foundation
 */

[CCode (cprefix = "")]
namespace Langinfo {

[CCode (cheader_filename = "langinfo.h", cname = "nl_langinfo")]
public unowned string lookup(Langinfo.Item item);

/**
 * Use for {@link Langinfo.Item}s prefixed with INT_.
 */
public int lookup_int(Langinfo.Item item) {
    char *ptr = (char *) lookup(item);
    
    return (ptr != null) ? *ptr : 0;
}

[CCode (cheader_filename = "langinfo.h", cname = "nl_item", cprefix = "", has_type_id = false)]
public enum Item {
  /* Abbreviated days of the week. */
  ABDAY_1,          /* Sunday */
  ABDAY_2,
  ABDAY_3,
  ABDAY_4,
  ABDAY_5,
  ABDAY_6,
  ABDAY_7,

  /* Long-named (unabbreviated) days of the week. */
  DAY_1,			/* Sunday */
  DAY_2,			/* Monday */
  DAY_3,			/* Tuesday */
  DAY_4,			/* Wednesday */
  DAY_5,			/* Thursday */
  DAY_6,			/* Friday */
  DAY_7,			/* Saturday */

  /* Abbreviated month names.  */
  ABMON_1,			/* Jan */
  ABMON_2,
  ABMON_3,
  ABMON_4,
  ABMON_5,
  ABMON_6,
  ABMON_7,
  ABMON_8,
  ABMON_9,
  ABMON_10,
  ABMON_11,
  ABMON_12,

  /* Long (unabbreviated) month names.  */
  MON_1,			/* January */
  MON_2,
  MON_3,
  MON_4,
  MON_5,
  MON_6,
  MON_7,
  MON_8,
  MON_9,
  MON_10,
  MON_11,
  MON_12,

  AM_STR,			/* Ante meridiem string. (may be empty)  */
  PM_STR,			/* Post meridiem string. (may be empty)  */

  ERA,

  /**
   * The following are not official and therefore not portable.
   * Those prefixed with INT_ should use lookup_int() rather than lookup().
   */
  
  [CCode (cname = "_NL_TIME_WEEK_NDAYS")]
  INT_TIME_WEEK_NDAYS,
  /**
   * TIME_WEEK_1STDAY returns a straight machine word as a constant indicating a first day (not a
   * pointer) that is interpreted as follows:
   * 19971130 == Sunday
   * 19971201 == Monday
   */
  [CCode (cname = "_NL_TIME_WEEK_1STDAY")]
  TIME_WEEK_1STDAY,
  [CCode (cname = "_NL_TIME_WEEK_1STWEEK")]
  INT_TIME_WEEK_1STWEEK,
  [CCode (cname = "_NL_TIME_FIRST_WEEKDAY")]
  INT_TIME_FIRST_WEEKDAY,
  [CCode (cname = "_NL_TIME_FIRST_WORKDAY")]
  INT_TIME_FIRST_WORKDAY,
  [CCode (cname = "_NL_TIME_CAL_DIRECTION")]
  INT_TIME_CAL_DIRECTION,
  [CCode (cname = "_NL_TIME_TIMEZONE")]
  TIME_TIMEZONE
}

}
