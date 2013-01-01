package com.roxstudio.haxe.ui;

import com.roxstudio.haxe.game.ImageUtil;
import com.roxstudio.haxe.ui.RoxScreenManager;
import nme.display.Sprite;

class RoxScreen extends Sprite {

    public static inline var OK = 0;
    public static inline var CANCELED = -1;

    public var manager(default, null): RoxScreenManager;
    public var screenWidth(default, null): Float;
    public var screenHeight(default, null): Float;
    public var disposeAtFinish: Bool = true;

    public function new() {
        super();
    }

    public function init(inManager: RoxScreenManager, inWidth: Float, inHeight: Float) {
        this.manager = inManager;
        this.screenWidth = inWidth;
        this.screenHeight = inHeight;
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

    public function startScreen(screenClassName: String, ?finishThis: Bool = false, ?animate: RoxAnimate,
                                ?requestCode: Null<Int> = 1, ?requestData: Dynamic) {
//        trace(Type.getClassName(Type.getClass(this)) + ".startScreen: className=" + screenClassName
//                + ",requestCode=" + requestCode + ",requestData=" + requestData + ",animate=" + animate);
        manager.startScreen(this, screenClassName, finishThis, requestCode, requestData, animate);
    }

    public function finish(?toScreenClassName: String, ?animate: RoxAnimate, resultCode: Int, ?resultData: Dynamic) {
//        trace(Type.getClassName(Type.getClass(this)) + ".finish: resultCode=" + resultCode
//                + ",resultData=" + resultData + ",animate=" + animate);
        manager.finishScreen(this, toScreenClassName, resultCode, resultData, animate);
    }

}
