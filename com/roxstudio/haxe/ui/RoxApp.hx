package com.roxstudio.haxe.ui;

import com.roxstudio.haxe.utils.GbTracer;
import nme.display.Sprite;
import nme.display.Stage;
import nme.display.StageAlign;
import nme.display.StageScaleMode;
import nme.Lib;

class RoxApp {

    public static var screenWidth: Float;
    public static var screenHeight: Float;
    public static var stage: Stage;

    private function new() {
    }

    public static function init() : Void {
        stage = Lib.current.stage;
        stage.align = StageAlign.TOP_LEFT;
        stage.scaleMode = StageScaleMode.NO_SCALE;
        screenWidth = stage.stageWidth;
        screenHeight = stage.stageHeight;
        GbTracer.init("eng/u2g.dat");
    }

}
