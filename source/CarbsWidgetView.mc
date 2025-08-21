using Toybox.Graphics as Gfx;
using Toybox.WatchUi as Ui;
using Toybox.System as Sys;
using Toybox.Communications as Comm;

var carbs = 0;
var error = null;
var abfrage = 1; // 1: start, 2: selected, 3: waiting, 4: finished
var circle, errorCircle = false;

class MyBehaviorDelegate extends Ui.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
        circle = Gfx.COLOR_BLACK;
    }

    // Detect Menu button input
    function onKey(keyEvent) {
        System.println(keyEvent.getKey()); // e.g. KEY_MENU = 7, Start = 4
        if( keyEvent.getKey() == 4 ) {
            if( abfrage == 1 ) {
                onMenu();
            } else if( abfrage == 2 ) {
                frageURL();
                error = "Contacting\nAAPS...";
            } else if ( abfrage == 3 ) {
                error = "Waiting for\nAAPS...";
            } else {
                error = "Click SELECT to start!";
                abfrage = 1;
                carbs = 0;
                circle = Gfx.COLOR_BLACK;
            }
            Ui.requestUpdate();
        }
        return false;
    }

    // Same function as onKey()
    function onHold(touchEvent) {
        if( abfrage == 1 ) {
            onMenu();
        } else if( abfrage == 2 ) {
            frageURL();
            error = "Contacting\nAAPS...";
        } else if ( abfrage == 3 ) {
            error = "Waiting for\nAAPS...";
        } else {
            error = "Click SELECT to start!";
            abfrage = 1;
            carbs = 0;
            circle = Gfx.COLOR_BLACK;
        }
        Ui.requestUpdate();
    }

    function onMenu() {
        abfrage = 2;
        var menu = new Ui.Menu();
        var delegate;
        menu.setTitle("Choose Carbs");
        menu.addItem("5 g", :a);
        menu.addItem("10 g", :b);
        menu.addItem("15 g", :c);
        menu.addItem("20 g", :d);
        menu.addItem("25 g", :e);
        menu.addItem("30 g", :f);
        menu.addItem("40 g", :g);
        menu.addItem("50 g", :h);
        menu.addItem("60 g", :i);
        menu.addItem("70 g", :j);
        menu.addItem("80 g", :k);
        delegate = new MenuInputDelegate(); // a WatchUi.MenuInputDelegate
        WatchUi.pushView(menu, delegate, WatchUi.SLIDE_IMMEDIATE);
     }

    //! Aufbereitete URL abfragen
    function frageURL() {
        circle = Gfx.COLOR_WHITE;
        Comm.makeWebRequest( url, { "eventType" => "Snack Bolus", "carbs" => carbs, "enteredBy" => "Garmin Widget", }, { :method => Comm.HTTP_REQUEST_METHOD_POST, :headers => { "Content-Type" => Comm.HTTP_RESPONSE_CONTENT_TYPE_JSON }, :responseType => Comm.HTTP_RESPONSE_CONTENT_TYPE_JSON}, method(:verarbeiteWerte) );
        abfrage = 3;
        return true;
     }

     //!  Abfrage auswerten
     function verarbeiteWerte( responseCode, data ) {
        if( responseCode == 200 ) {
            Sys.println(data);
            //error = data.toString();
            error = "added to\nAAPS";
            circle = Gfx.COLOR_GREEN;
        } else {
            error = "Error: " + responseCode.toString();
            circle = Gfx.COLOR_RED;
            errorCircle = true;
        }
        abfrage = 4;
        Ui.requestUpdate();
     }

}

class MenuInputDelegate extends Ui.BehaviorDelegate {

    function initialize() {
       BehaviorDelegate.initialize();
    }

    function onMenuItem(item) {
        circle = Gfx.COLOR_YELLOW;
        if (item == :a) {
            carbs = 5;
        } else if (item == :b) {
            carbs = 10;
        } else if (item == :c) {
            carbs = 15;
        } else if (item == :d) {
            carbs = 20;
        } else if (item == :e) {
            carbs = 25;
        } else if (item == :f) {
            carbs = 30;
        } else if (item == :g) {
            carbs = 40;
        } else if (item == :h) {
            carbs = 50;
        } else if (item == :i) {
            carbs = 60;
        } else if (item == :j) {
            carbs = 70;
        } else if (item == :k) {
            carbs = 80;
        }
    }
}

class CarbsWidgetView extends Ui.View {

    function initialize() {
        View.initialize();
    }

    // Load your resources here
    function onLayout(dc) as Void {
        setLayout(Rez.Layouts.MainLayout(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
    }

    // Update the view
    function onUpdate(dc) as Void {
        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);

        // AUSGABE
        var addPadding = dc.getWidth() >= 360 ? 10 : 0;
        // Circle
        dc.setColor(circle, circle);
        dc.fillCircle(dc.getWidth() * 0.5, dc.getHeight() * 0.5, dc.getHeight() * 0.5);
        if (errorCircle == false ) {
            dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
        } else {
            dc.setColor(Gfx.COLOR_DK_RED, Gfx.COLOR_BLACK);
            errorCircle = false;
        }
        dc.fillCircle(dc.getWidth() * 0.5, dc.getHeight() * 0.5, dc.getHeight() * 0.5 - 5);


        // Titel
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        dc.drawText(
                dc.getWidth() * 0.5,
                dc.getHeight() * 0.5 + 10 - dc.getFontHeight(Gfx.FONT_LARGE) * 0.5 - 40 - 5 - dc.getFontHeight(Gfx.FONT_LARGE) - 5 - addPadding,
                Gfx.FONT_LARGE,
                "Carbs",
                Gfx.TEXT_JUSTIFY_CENTER
        );
        // Icon
        dc.drawBitmap(
            dc.getWidth() * 0.5 - 15,
            dc.getHeight() * 0.5 + 10 - dc.getFontHeight(Gfx.FONT_LARGE) * 0.5 - 40 - 5 - addPadding,
            Ui.loadResource(Rez.Drawables.LauncherIcon)
        );
        // Aufgabe
        dc.drawText(
                dc.getWidth() * 0.5,
                dc.getHeight() * 0.5 + 10 + 5,
                Gfx.FONT_LARGE,
                carbs.toString() + " g",
                Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER
        );
        // Anweisung
        var fontSize = Gfx.FONT_TINY;
        var anweisung = (carbs == 0) ? "Click SELECT to start!" : "Push it to\nAAPS?";
        if (error != null ) {
            anweisung = error;
            error = null;
            //fontSize = Gfx.FONT_XTINY;
        }
        dc.drawText(
                dc.getWidth() * 0.5,
                dc.getHeight() * 0.5 + 10 + dc.getFontHeight(Gfx.FONT_LARGE) * 0.5 + 10,
                fontSize,
                anweisung,
                Gfx.TEXT_JUSTIFY_CENTER
        );

    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

}
