using Toybox.Graphics as Gfx;
using Toybox.WatchUi as Ui;
using Toybox.System as Sys;
using Toybox.Communications as Comm;
using Toybox.Timer as Timer;
import Toybox.Lang;

// UI state: 1=idle, 2=mode chosen (confirm), 3=waiting HTTP, 4=done
var abfrage = 1;
var modeKeyword = "";
var modeLabel = "";
var modeDuration = 0;
var statusText = null;
var ringColor = Gfx.COLOR_BLACK;
var errorRing = false;
var menuOpen = false;

class AimiModesBehaviorDelegate extends Ui.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
        ringColor = Gfx.COLOR_BLACK;
    }

    // Venu X1 / touch: short tap
    function onTap(clickEvent) as Boolean {
        handleSelect();
        Ui.requestUpdate();
        return true;
    }

    // High-level SELECT action (buttons + some touch devices)
    function onSelect() as Boolean {
        handleSelect();
        Ui.requestUpdate();
        return true;
    }

    function onKey(keyEvent) {
        if (keyEvent.getKey() == 4) {
            handleSelect();
            Ui.requestUpdate();
            return true;
        }
        return false;
    }

    function onHold(touchEvent) as Boolean {
        handleSelect();
        Ui.requestUpdate();
        return true;
    }

    function handleSelect() as Void {
        if (abfrage == 1) {
            openModeMenu();
        } else if (abfrage == 2) {
            sendModeToAaps();
            statusText = "Contacting\nAAPS...";
        } else if (abfrage == 3) {
            statusText = "Waiting for\nAAPS...";
        } else {
            resetIdle();
            openModeMenu();
        }
    }

    function resetIdle() as Void {
        abfrage = 1;
        modeKeyword = "";
        modeLabel = "";
        modeDuration = 0;
        statusText = "TAP = choose mode";
        ringColor = Gfx.COLOR_BLACK;
        menuOpen = false;
    }

    function openModeMenu() as Void {
        if (menuOpen) {
            return;
        }
        menuOpen = true;
        abfrage = 2;
        var menu = new Ui.Menu();
        menu.setTitle("AIMI Modes");
        menu.addItem("BFAST  60 min", :bfast);
        menu.addItem("LUNCH  60 min", :lunch);
        menu.addItem("DINNER 60 min", :dinner);
        menu.addItem("HIGH CARB 90 min", :highcarb);
        menu.addItem("FCL  30 min", :fcl);
        menu.addItem("STOP", :stop);
        Ui.pushView(menu, new AimiModesMenuDelegate(), Ui.SLIDE_IMMEDIATE);
    }

    function sendModeToAaps() as Void {
        ringColor = Gfx.COLOR_WHITE;
        abfrage = 3;
        // Query params (not Nightscout JSON) — matches GarminPlugin.onPostMode
        Comm.makeWebRequest(
            url,
            {
                "mode" => modeKeyword,
                "duration" => modeDuration,
                "key" => garminKey
            },
            {
                :method => Comm.HTTP_REQUEST_METHOD_POST,
                :responseType => Comm.HTTP_RESPONSE_CONTENT_TYPE_JSON
            },
            method(:onAapsResponse)
        );
    }

    function onAapsResponse(responseCode as Number, data as Dictionary or String or Null) as Void {
        if (responseCode == 200) {
            Sys.println(data);
            statusText = modeLabel + "\nsent to AAPS";
            ringColor = Gfx.COLOR_GREEN;
        } else {
            statusText = "Error: " + responseCode.toString();
            ringColor = Gfx.COLOR_RED;
            errorRing = true;
        }
        abfrage = 4;
        Ui.requestUpdate();
    }

}

class AimiModesMenuDelegate extends Ui.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onMenuItem(item) {
        menuOpen = false;
        ringColor = Gfx.COLOR_YELLOW;
        if (item == :bfast) {
            modeKeyword = "bfast";
            modeLabel = "BFAST";
            modeDuration = 60;
        } else if (item == :lunch) {
            modeKeyword = "lunch";
            modeLabel = "LUNCH";
            modeDuration = 60;
        } else if (item == :dinner) {
            modeKeyword = "dinner";
            modeLabel = "DINNER";
            modeDuration = 60;
        } else if (item == :highcarb) {
            modeKeyword = "highcarb";
            modeLabel = "HIGH CARB";
            modeDuration = 90;
        } else if (item == :fcl) {
            modeKeyword = "fcl";
            modeLabel = "FCL";
            modeDuration = 30;
        } else if (item == :stop) {
            modeKeyword = "stop";
            modeLabel = "STOP";
            modeDuration = 1;
        }
        statusText = "TAP = send to AAPS";
        abfrage = 2;
    }

    function onBack() as Boolean {
        menuOpen = false;
        abfrage = 1;
        statusText = "TAP = choose mode";
        return false;
    }

}

class AimiModesWidgetView extends Ui.View {

    var openTimer as Timer.Timer or Null = null;

    function initialize() {
        View.initialize();
        statusText = "TAP = choose mode";
    }

    function onLayout(dc) as Void {
        setLayout(Rez.Layouts.MainLayout(dc));
    }

    function onShow() as Void {
        // Venu X1: open mode list immediately (splash alone is not useful)
        if (abfrage == 1 && !menuOpen) {
            openTimer = new Timer.Timer();
            openTimer.start(method(:autoOpenMenu), 100, false);
        }
    }

    function autoOpenMenu() as Void {
        if (abfrage == 1 && !menuOpen) {
            var menu = new Ui.Menu();
            menuOpen = true;
            abfrage = 2;
            menu.setTitle("AIMI Modes");
            menu.addItem("BFAST  60 min", :bfast);
            menu.addItem("LUNCH  60 min", :lunch);
            menu.addItem("DINNER 60 min", :dinner);
            menu.addItem("HIGH CARB 90 min", :highcarb);
            menu.addItem("FCL  30 min", :fcl);
            menu.addItem("STOP", :stop);
            Ui.pushView(menu, new AimiModesMenuDelegate(), Ui.SLIDE_IMMEDIATE);
        }
    }

    function onUpdate(dc) as Void {
        View.onUpdate(dc);

        var addPadding = dc.getWidth() >= 360 ? 10 : 0;

        dc.setColor(ringColor, ringColor);
        dc.fillCircle(dc.getWidth() * 0.5, dc.getHeight() * 0.5, dc.getHeight() * 0.5);
        if (errorRing == false) {
            dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
        } else {
            dc.setColor(Gfx.COLOR_DK_RED, Gfx.COLOR_BLACK);
            errorRing = false;
        }
        dc.fillCircle(dc.getWidth() * 0.5, dc.getHeight() * 0.5, dc.getHeight() * 0.5 - 5);

        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        dc.drawText(
            dc.getWidth() * 0.5,
            dc.getHeight() * 0.5 + 10 - dc.getFontHeight(Gfx.FONT_LARGE) * 0.5 - 40 - 5 - dc.getFontHeight(Gfx.FONT_LARGE) - 5 - addPadding,
            Gfx.FONT_LARGE,
            "AIMI",
            Gfx.TEXT_JUSTIFY_CENTER
        );

        dc.drawBitmap(
            dc.getWidth() * 0.5 - 15,
            dc.getHeight() * 0.5 + 10 - dc.getFontHeight(Gfx.FONT_LARGE) * 0.5 - 40 - 5 - addPadding,
            Ui.loadResource(Rez.Drawables.LauncherIcon)
        );

        var centerLabel = "Modes";
        if (modeLabel.length() > 0) {
            if (modeKeyword.equals("stop")) {
                centerLabel = "STOP";
            } else if (modeDuration > 0) {
                centerLabel = modeLabel + "\n" + modeDuration.toString() + " min";
            } else {
                centerLabel = modeLabel;
            }
        }

        dc.drawText(
            dc.getWidth() * 0.5,
            dc.getHeight() * 0.5 + 10 + 5,
            Gfx.FONT_LARGE,
            centerLabel,
            Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER
        );

        var hint = statusText;
        if (hint == null) {
            hint = "TAP = choose mode";
        }
        dc.drawText(
            dc.getWidth() * 0.5,
            dc.getHeight() * 0.5 + 10 + dc.getFontHeight(Gfx.FONT_LARGE) * 0.5 + 18,
            Gfx.FONT_TINY,
            hint,
            Gfx.TEXT_JUSTIFY_CENTER
        );
    }

    function onHide() as Void {
    }

}
