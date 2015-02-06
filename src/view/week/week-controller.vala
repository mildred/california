/* Copyright 2014-2015 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.View.Week {

/**
 * The {@link View.Controllable} for the week view.
 */

public class Controller : BaseObject, View.Controllable {
    public const string PROP_WEEK = "week";
    
    public const string VIEW_ID = "week";
    
    private const int CACHE_NEIGHBORS_COUNT = 4;
    
    private class ViewContainer : Gtk.Stack, View.Container {
        private Controller _owner;
        public unowned View.Controllable owner { get { return _owner; } }
        
        public ViewContainer(Controller owner) {
            _owner = owner;
        }
    }
    
    /**
     * The current week of the year being displayed.
     */
    public Calendar.Week week { get; private set; }
    
    /**
     * @inheritDoc
     */
    public string id { get { return VIEW_ID; } }
    
    /**
     * @inheritDoc
     */
    public string title { get { return _("Week"); } }
    
    /**
     * @inheritDoc
     */
    public string current_label { get; protected set; }
    
    /**
     * @inheritDoc
     */
    public bool is_viewing_today { get; protected set; }
    
    /**
     * @inheritDoc
     */
    public ChronologyMotion motion { get { return ChronologyMotion.HORIZONTAL; } }
    
    /**
     * @inheritDoc
     */
    public bool in_transition { get; protected set; }
    
    /**
     * {@link View.Palette} for the entire hosted view.
     */
    public View.Palette palette { get; private set; }
    
    private ViewContainer stack;
    private Toolkit.StackModel<Calendar.Week> stack_model;
    private Calendar.WeekSpan cache_span;
    
    public Controller(View.Palette palette) {
        this.palette = palette;
        
        stack = new ViewContainer(this);
        stack.homogeneous = true;
        stack.transition_duration = Toolkit.SLOW_STACK_TRANSITION_DURATION_MSEC;
        stack.bind_property("transition-running", this, PROP_IN_TRANSITION, BindingFlags.SYNC_CREATE);
        
        stack_model = new Toolkit.StackModel<Calendar.Week>(stack,
            Toolkit.StackModel.OrderedTransitionType.SLIDE_LEFT_RIGHT, model_presentation,
            trim_presentation_from_cache, ensure_presentation_in_cache);
        
        // changing these properties drives a lot of the what the view displays
        Calendar.System.instance.first_of_week_changed.connect(on_first_of_week_changed);
        notify[PROP_WEEK].connect(on_week_changed);
        
        // set this now that signal handlers are in place
        week = Calendar.System.today.week_of(Calendar.System.first_of_week);
    }
    
    ~Controller() {
        Calendar.System.instance.first_of_week_changed.disconnect(on_first_of_week_changed);
    }
    
    /**
     * @inheritDoc
     */
    public View.Container get_container() {
        return stack;
    }
    
    /**
     * @inheritDoc
     */
    public void next() {
        week = week.next();
    }
    
    /**
     * @inheritDoc
     */
    public void previous() {
        week = week.previous();
    }
    
    /**
     * @inheritDoc
     */
    public void today() {
        Calendar.Week this_week = Calendar.System.today.week_of(Calendar.System.first_of_week);
        if (!week.equal_to(this_week))
            week = this_week;
    }
    
    /**
     * @inheritDoc
     */
    public void unselect_all() {
        Grid? current = get_current_grid();
        if (current != null)
            current.unselect_all();
    }
    
    /**
     * @inheritDoc
     */
    public Gtk.Widget? get_widget_for_date(Calendar.Date date) {
        Grid? current_grid = get_current_grid();
        
        return current_grid != null ? current_grid.get_all_day_cell_for_date(date) : null;
    }
    
    private Grid? get_current_grid() {
        return stack.get_visible_child() as Grid;
    }
    
    private Gtk.Widget model_presentation(Calendar.Week week, out string? id) {
        Grid week_grid = new Grid(this, week);
        id = week_grid.id;
        
        return week_grid;
    }
    
    private bool trim_presentation_from_cache(Calendar.Week week, Calendar.Week? visible_week) {
        // always keep today's week in cache
        if (week.equal_to(Calendar.System.today.week_of(Calendar.System.first_of_week)))
            return false;
        
        // otherwise only keep weeks that are in the current cache span
        return !(week in cache_span);
    }
    
    private Gee.Collection<Calendar.Week>? ensure_presentation_in_cache(Calendar.Week? visible_week) {
        // return current cache span as a collection
        Gee.List<Calendar.Week> weeks = cache_span.as_list();
        
        // add today's week to the mix
        weeks.add(Calendar.System.today.week_of(Calendar.System.first_of_week));
        
        return weeks;
    }
    
    private void on_first_of_week_changed() {
        stack_model.clear();
        week = week.start_date.week_of(Calendar.System.first_of_week);
    }
    
    private void on_week_changed() {
        // current_label is Start Date - End Date, Year, unless bounding two years, in which case
        // Start Date, Year - End Date, Year
        Calendar.Date.PrettyFlag start_flags =
            Calendar.Date.PrettyFlag.ABBREV | Calendar.Date.PrettyFlag.NO_DAY_OF_WEEK;
        if (!week.start_date.year.equal_to(week.end_date.year))
            start_flags |= Calendar.Date.PrettyFlag.INCLUDE_YEAR;
        Calendar.Date.PrettyFlag end_flags =
            Calendar.Date.PrettyFlag.ABBREV | Calendar.Date.PrettyFlag.INCLUDE_YEAR
            | Calendar.Date.PrettyFlag.NO_DAY_OF_WEEK;
        
        // date formatting: "<Start Date> to <End Date>"
        current_label = _("%s to %s").printf(week.start_date.to_pretty_string(start_flags),
            week.end_date.to_pretty_string(end_flags));
        
        is_viewing_today = Calendar.System.today in week;
        
        // cache span is split between neighbors ahead and neighbors behind this week
        cache_span = new Calendar.WeekSpan(
            week.adjust(0 - (CACHE_NEIGHBORS_COUNT / 2)),
            week.adjust(CACHE_NEIGHBORS_COUNT / 2)
        );
        
        // show this week via the stack model (which implies adding it to the model)
        stack_model.show(week);
    }
    
    public override string to_string() {
        return "Week.Controller %s".printf(week.to_string());
    }
}

}

