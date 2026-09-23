using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;

(:glance)
class AimiModesGlanceView extends Ui.GlanceView {

    function initialize() {
        GlanceView.initialize();
    }

    function onUpdate(dc) {
        var width = dc.getWidth();
        var height = dc.getHeight();

        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
        dc.clear();

        dc.setPenWidth(3);
        dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
        dc.drawLine(0, height / 2, width, height / 2);

        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        dc.drawText(0, height / 2 - dc.getFontHeight(Gfx.FONT_GLANCE) - 5, Gfx.FONT_GLANCE, "AIMI", Gfx.TEXT_JUSTIFY_LEFT);
        dc.drawText(0, height / 2 + 5, Gfx.FONT_GLANCE, "Modes", Gfx.TEXT_JUSTIFY_LEFT);
    }

}
