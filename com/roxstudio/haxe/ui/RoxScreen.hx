package com.roxstudio.haxe.ui;

import com.roxstudio.haxe.game.ResKeeper;
import nme.display.Sprite;

enum FinishToScreen {
    PARENT;
    ROOT;
    CLEAR;
    SCREEN(name: String);
}

class RoxScreen extends Sprite {

    public static inline var OK = 0;
    public static inline var CANCELED = -1;

    public var manager(default, null): RoxScreenManager;
    public var screenWidth(default, null): Float;
    public var screenHeight(default, null): Float;
    public var className(get_className, null): String;
    public var disposeAtFinish: Bool = true;

    public function new() {
        super();
    }

    public function init(inManager: RoxScreenManager, inWidth: Float, inHeight: Float) {
        this.manager = inManager;
        this.screenWidth = inWidth;
        this.screenHeight = inHeight;
    }

    public inline function get_className() : String {
        return Type.getClassName(Type.getClass(this));
    }

    public function onCreate() {
    }

    public function onNewRequest(requestData: Dynamic) {
//        trace(Type.getClassName(Type.getClass(this)) + ".onNewRequest: " + requestData);
    }

    public function onShown() {
    }

    /**
    * called when this screen is not the top of display stack
    **/
    public function onHidden() {
    }

    public function onDestroy() {
    }

    public function onScreenResult(requestCode: Int, resultCode: Int, resultData: Dynamic) {
//        trace(Type.getClassName(Type.getClass(this)) + ".onScreenResult: requestCode" + requestCode
//                + ",resultCode=" + resultCode + ",resultData=" + resultData);
    }

    /**
    * return: true - perform default action i.e. cancel this screen, false - prevent canceling this screen
    **/
    public function onBackKey() : Bool {
        return true;
    }

    public function startScreen(screenClassName: String, ?finishToScreen: FinishToScreen, ?animate: RoxAnimate,
                                ?requestCode: Int = 1, ?requestData: Dynamic) {
        manager.startScreen(this, screenClassName, finishToScreen, requestCode, requestData, animate);
    }

    public function finish(?finishToScreen: FinishToScreen, ?animate: RoxAnimate,
                           resultCode: Int, ?resultData: Dynamic) {
        manager.finishScreen(this, finishToScreen, resultCode, resultData, animate);
    }

    override public inline function toString() : String {
        return get_className();
    }

}
