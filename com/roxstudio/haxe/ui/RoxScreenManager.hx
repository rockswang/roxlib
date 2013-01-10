package com.roxstudio.haxe.ui;

import com.roxstudio.haxe.game.ResKeeper;
import nme.display.Bitmap;
import nme.display.BitmapData;
import nme.events.KeyboardEvent;
import com.roxstudio.haxe.ui.RoxAnimate;
import nme.Lib;
import com.eclecticdesignstudio.motion.Actuate;
import nme.geom.Rectangle;
import nme.display.Sprite;

class RoxScreenManager extends Sprite {

    private var screens: Hash<RoxScreen>;
    private var stack: List<StackItem>;

    public function new() {
        super();
        screens = new Hash<RoxScreen>();
        stack = new List<StackItem>();
        RoxApp.stage.addEventListener(KeyboardEvent.KEY_UP, function(e: KeyboardEvent) {
            if (e.keyCode == 27 && stack.length > 1) {
                var topscreen: RoxScreen = cast(getChildAt(0));
                if (topscreen.onBackKey()) {
                    finishScreen(topscreen, RoxScreen.CANCELED, null, null);
                    e.stopPropagation();
                }
            }
        });
    }

    public function startScreen(?source: RoxScreen, screenClassName: String, ?finishSource: Bool = false,
                                ?requestCode: Null<Int> = 1,
                                ?requestData: Dynamic, ?animate: RoxAnimate) {
        var srcbmp: Bitmap = null;
        if (finishSource && stack.length > 0) {
            srcbmp = snap(source);
            finishScreen(source, null, RoxScreen.CANCELED, null, new RoxAnimate(RoxAnimate.NONE, null));
            source = stack.length > 0 ? screens.get(stack.first().className) : null;
        }
        var dest = screens.get(screenClassName);
        if (dest == null) {
            ResKeeper.currentBundle = screenClassName;
            dest = Type.createInstance(Type.resolveClass(screenClassName), [ ]);
            dest.init(this, RoxApp.screenWidth, RoxApp.screenHeight);
            if (dest == null) throw "Unknown screenClassName: " + screenClassName;
            screens.set(screenClassName, dest);
            dest.onCreate();
        }
        if (animate == null) animate = RoxAnimate.SLIDE_LEFT;
        var request: Int = requestCode;
        stack.push({ className: screenClassName, requestCode: request, animate: animate });
        ResKeeper.currentBundle = screenClassName;
        dest.onNewRequest(requestData);
        if (source != null) {
            switchScreen(source, dest, false);
            startAnimate(srcbmp != null ? srcbmp : snap(source), snap(dest), animate);
        } else {
            dest.x = dest.y = 0;
            dest.alpha = dest.scaleX = dest.scaleY = 1;
            addChild(dest);
            dest.onShown();
        }
    }

    public function finishScreen(screen: RoxScreen, ?toScreen: String, resultCode: Int, resultData: Dynamic, animate: RoxAnimate) {
        var srcbmp = snap(screen);
        var top: StackItem = null;
        var topscreen: RoxScreen = null;
        while (true) {
            top = stack.pop();
            if (top.className != Type.getClassName(Type.getClass(screen)) || stack.length == 0)
                throw "Illegal stack state or bad target screen '" + toScreen + "'";
            top = stack.first();
            topscreen = screens.get(top.className);
            switchScreen(screen, topscreen, true);
            screen = topscreen;
            if (toScreen == null || top.className == toScreen) break;
        }
        animate = animate != null ? animate : top.animate.getReverse();
        if (animate.type != RoxAnimate.NONE) startAnimate(srcbmp, snap(topscreen), animate);
        topscreen.onScreenResult(top.requestCode, resultCode, resultData);
    }

    private inline function snap(s: RoxScreen) : Bitmap {
        var bmd = new BitmapData(Std.int(s.screenWidth), Std.int(s.screenHeight));
        bmd.draw(s);
        return new Bitmap(bmd);
    }

    private function startAnimate(src: Bitmap, dest: Bitmap, anim: RoxAnimate) {
        var sw = RoxApp.screenWidth, sh = RoxApp.screenHeight;
        addChild(src);
        addChild(dest);
        switch (anim.type) {
            case RoxAnimate.SLIDE:
                switch (cast(anim.arg, String)) {
                    case "up":
                        dest.y = sh;
                    case "right":
                        dest.x = -sw;
                    case "down":
                        dest.y = -sh;
                    case "left":
                        dest.x = sw;
                }
                Actuate.tween(src, anim.interval, { x: -dest.x, y: -dest.y });
                Actuate.tween(dest, anim.interval, { x: 0, y: 0 }).onComplete(animDone, [ src, dest ]);
            case RoxAnimate.ZOOM_IN: // popup
                var r: Rectangle = cast(anim.arg);
                dest.scaleX = dest.scaleY = r.width / sw;
                dest.x = r.x;
                dest.y = r.y;
                dest.alpha = 0;
                Actuate.tween(dest, anim.interval, { x: 0, y: 0, scaleX: 1, scaleY: 1, alpha: 1 })
                        .onComplete(animDone, [ src, dest ]);
            case RoxAnimate.ZOOM_OUT: // shrink
                this.swapChildrenAt(0, 1); // make sure src is on top
                var r: Rectangle = cast(anim.arg);
                var scale = r.width / sw;
                Actuate.tween(src, anim.interval, { x: r.x, y: r.y, scaleX: scale, scaleY: scale, alpha: 0.01 })
                        .onComplete(animDone, [ src, dest ]);

        }
    }

    private inline function animDone(src: Bitmap, dest: Bitmap) {
        removeChild(src);
        removeChild(dest);
    }

    private inline function switchScreen(src: RoxScreen, dest: RoxScreen, finish: Bool) {
        removeChild(src);
        src.onHidden();
        if (finish && src.disposeAtFinish) {
            var classname = Type.getClassName(Type.getClass(src));
            screens.remove(classname);
            ResKeeper.disposeBundle(classname);
            src.onDestroy();
        }
        addChild(dest);
        dest.onShown();
    }

}

private typedef StackItem = {
    var className: String;
    var requestCode: Int;
    var animate: RoxAnimate;
}
