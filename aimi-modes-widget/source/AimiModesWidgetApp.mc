import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class AimiModesWidgetApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
    }

    function onStop(state as Dictionary?) as Void {
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [ new AimiModesWidgetView(), new AimiModesBehaviorDelegate() ];
    }

    (:glance)
    function getGlanceView() as [WatchUi.GlanceView] or [WatchUi.GlanceView, WatchUi.GlanceViewDelegate] or Null {
        return [ new AimiModesGlanceView() ];
    }

}
