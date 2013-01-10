package com.roxstudio.haxe.gesture;

import nme.ui.MultitouchInputMode;
import flash.display.InteractiveObject;
import nme.display.Sprite;
import nme.display.DisplayObjectContainer;
import com.eclecticdesignstudio.motion.actuators.GenericActuator;
import com.eclecticdesignstudio.motion.Actuate;
import com.roxstudio.haxe.gesture.RoxGestureEvent;
import com.roxstudio.haxe.game.GameUtil;
import haxe.Timer;
import nme.Lib;
import nme.display.InteractiveObject;
import nme.events.Event;
import nme.events.MouseEvent;
import nme.events.TouchEvent;
import nme.geom.Point;
import nme.geom.Rectangle;
import nme.ui.Multitouch;

using Lambda;
using com.roxstudio.haxe.game.GfxUtil;
using com.roxstudio.haxe.ui.UiUtil;

class RoxGestureAgent {

    public static inline var TOUCH_POINT = 1;
    public static inline var GESTURE = 2;
    public static inline var GESTURE_CAPTURE = 3;
    public static inline var PAN_X = 1;
    public static inline var PAN_Y = 2;
    public static inline var PAN_XY = 3;

    public static var multitouchSupported(get_multitouchSupported, null): Bool;
    public var mode(default, null): Int;
    public var longPressDelay = 1.0;
    public var swipeTimeout = 0.1; // can be zero, means no timeout

    private static inline var READY = 0;
    private static inline var BEGIN = 1;
    private static inline var TWO_FINGER_MOVE = 2;
    private static inline var MOVE = 4;

//    private static inline var DOUBLE_TAP_DELAY = 0.3;
    private static inline var SWIPE_SCROLL_TIME = 2.0;
    private static inline var SWIPE_SAMPLE_TIME = 0.2;
    private static inline var VELOCITY_RATIO = 1 / 4;
    private static inline var touchEvents = [
        TouchEvent.TOUCH_BEGIN, TouchEvent.TOUCH_END, TouchEvent.TOUCH_MOVE, TouchEvent.TOUCH_OVER,
        TouchEvent.TOUCH_OUT, TouchEvent.TOUCH_ROLL_OVER, TouchEvent.TOUCH_ROLL_OUT, TouchEvent.TOUCH_TAP ];
    private static inline var mouseEvents = [
        MouseEvent.MOUSE_DOWN, MouseEvent.MOUSE_UP, MouseEvent.MOUSE_MOVE, MouseEvent.MOUSE_OVER,
        MouseEvent.MOUSE_OUT, MouseEvent.ROLL_OVER, MouseEvent.ROLL_OUT, MouseEvent.CLICK ];
    private static inline var geTouchEvents = [
        TouchEvent.TOUCH_BEGIN, TouchEvent.TOUCH_END, TouchEvent.TOUCH_MOVE, TouchEvent.TOUCH_OUT ];
    private static inline var geMouseEvents = [
        MouseEvent.MOUSE_DOWN, MouseEvent.MOUSE_UP, MouseEvent.MOUSE_MOVE, MouseEvent.MOUSE_OUT ];

    private var owner: InteractiveObject;
    private var touch0: TouchPoint;
    private var touch1: TouchPoint;
    private var touchList: List<TouchPoint>;
    private var listenEvents: Array<String>;
    private var handler: Dynamic -> Void;
    private var longPressTimer: GenericActuator;
    private var tweener: GenericActuator;
    private var overlay: Sprite; // used in capture mode, to capture events outside the owner
    /**
     * READY -> begin:BEGIN -> end:tap
     * READY -> begin:BEGIN -> move:MOVE [-> MOVE]: pan
     * READY -> begin:BEGIN -> begin:TWO_FINGER_MOVE -> move:TWO_FINGER_MOVE:pinch & rotation
     * READY -> begin:BEGIN -> move:MOVE -> end:swipe
     **/
    private var state: Int;

    public function new(inOwner: InteractiveObject, ?inMode: Null<Int> = GESTURE) {
        owner = inOwner;
        mode = inMode;
        var isTouch = Multitouch.supportsTouchEvents;
        if (isTouch) Multitouch.inputMode = MultitouchInputMode.TOUCH_POINT;
        owner.mouseEnabled = true;
        listenEvents = mode == TOUCH_POINT ? (isTouch ? touchEvents : mouseEvents) : (isTouch ? geTouchEvents : geMouseEvents);
        handler = mode == TOUCH_POINT ? (isTouch ? convertTouch : convertMouse) : (isTouch ? onTouch : onMouse);
        for (type in listenEvents) owner.addEventListener(type, handler);
        if (mode == GESTURE_CAPTURE) Lib.current.stage.addEventListener(Event.RESIZE, function(e) { overlay = null; } );
        touchList = new List<TouchPoint>();
        setReady();
    }

    public function detach() {
        stopTween();
        setReady();
        for (type in listenEvents) owner.removeEventListener(type, handler);
        owner = null;
        overlay = null;
    }

    public inline function getHandler(?flags: Int = PAN_XY) : Dynamic -> Void {
        return callback(handleEvent, flags);
    }

    public inline function startTween(target: Dynamic, interval: Float, properties: Dynamic) {
        tweener = cast(Actuate.tween(target, interval, properties, false));
    }

    public inline function stopTween() {
        if (tweener != null) {
            tweener.stop(null, false, false);
            tweener = null;
        }
    }

    public static inline function localOffset(obj: InteractiveObject, globalOffset: Point) : Point {
        var pt = obj.parent.localToGlobal(new Point(obj.x, obj.y));
        pt.offset(globalOffset.x, globalOffset.y);
        pt = obj.parent.globalToLocal(pt);
        pt.offset(-obj.x, -obj.y);
        return pt;
    }

    private function handleEvent(flags: Int, e: RoxGestureEvent) {
//        trace(">>>t=" + e.target.name+",o="+owner.name+",e="+e);
        var sp: InteractiveObject = cast(e.target);
        if (sp != owner) return;
        switch (e.type) {
            case RoxGestureEvent.GESTURE_PAN:
                var pt = localOffset(sp, cast(e.extra));
                if (flags & PAN_X != 0) sp.x += pt.x;
                if (flags & PAN_Y != 0) sp.y += pt.y;
            case RoxGestureEvent.GESTURE_SWIPE:
                var pt = localOffset(sp, new Point(e.extra.x * SWIPE_SCROLL_TIME, e.extra.y * SWIPE_SCROLL_TIME));
                startTween(sp, SWIPE_SCROLL_TIME, { x: sp.x + pt.x, y: sp.y + pt.y });
            case RoxGestureEvent.GESTURE_PINCH:
                var scale: Float = e.extra;
                var spt = sp.parent.localToGlobal(new Point(sp.x, sp.y));
                var dx = spt.x - e.stageX, dy = spt.y - e.stageY;
                var angle = Math.atan2(dy, dx);
                var nowlen = new Point(dx, dy).length;
                var newlen = nowlen * scale;
                var newpos = Point.polar(newlen, angle);
                newpos.offset(e.stageX, e.stageY);
                newpos = sp.parent.globalToLocal(newpos);
                sp.scaleX *= scale;
                sp.scaleY *= scale;
                sp.x = newpos.x;
                sp.y = newpos.y;
            case RoxGestureEvent.GESTURE_ROTATION:
                var angle: Float = e.extra;
                var spt = sp.parent.localToGlobal(new Point(sp.x, sp.y));
                var dx = spt.x - e.stageX, dy = spt.y - e.stageY;
                var nowang = Math.atan2(dy, dx);
                var length = new Point(dx, dy).length;
                var newang = nowang + angle;
                var newpos = Point.polar(length, newang);
                newpos.offset(e.stageX, e.stageY);
                newpos = sp.parent.globalToLocal(newpos);
                sp.rotation += GameUtil.R2D * angle;
                sp.x = newpos.x;
                sp.y = newpos.y;
        }
    }

    private inline static function get_multitouchSupported() : Bool {
        trace("multitouchSupported: isTouch=" + Multitouch.supportsTouchEvents + ",maxPoints=" + Multitouch.maxTouchPoints);
        return Multitouch.supportsTouchEvents && Multitouch.maxTouchPoints > 1;
    }

    private inline function convertTouch(e: Dynamic) {
        owner.dispatchEvent(new RoxGestureEvent(typeMap.get(e.type), e.bubbles, e.cancelable,
                e.localX, e.localY, e.stageX, e.stageY, e.touchPointID));
    }

    private inline function convertMouse(e: Dynamic) {
        var t: String = e.type;
        if (t == MouseEvent.MOUSE_DOWN || t == MouseEvent.MOUSE_UP || t == MouseEvent.CLICK || e.buttonDown) {
            owner.dispatchEvent(new RoxGestureEvent(typeMap.get(t), e.bubbles, e.cancelable,
                    e.localX, e.localY, e.stageX, e.stageY, 0));
        }
    }

    private inline function onTouch(e: Dynamic) {
        var id: Int = e.touchPointID;
//        trace("onTouch:e=" + e +",touchId="+id);
        var prim = touch0 == null || touch0.tid == id;
        if (prim || (touch1 != null && touch1.tid == id) || (touch0 != null && touch1 == null && touch0.tid != id)) {
            if (handleTouch(typeMap.get(e.type), e, prim, id)) e.rox_stopPropagation();
        }
//        if (id <= 1) {
//            if (handleTouch(typeMap.get(e.type), e, id == 0)) e.rox_stopPropagation();
//        }
    }

    private inline function onMouse(e: Dynamic) {
//        trace("onMouse:e=" + e);
        var t: String = e.type;
        if (t == MouseEvent.MOUSE_DOWN || t == MouseEvent.MOUSE_UP || e.buttonDown) {
            if (handleTouch(typeMap.get(t), e, true, 0)) e.rox_stopPropagation();
        }
    }

    private function handleTouch(type: String, e: Dynamic, prim: Bool, touchId: Int) : Bool {
//        trace("type=" + type + ",e=" + e);
        var pt = new TouchPoint(owner, e, touchId);
        var tp = prim ? touch0 : touch1;
        if (type == RoxGestureEvent.TOUCH_MOVE && tp != null && tp.sx == pt.sx && tp.sy == pt.sy) return false; // NO MOVE -> skip
        var handled = true;
        switch (state) {
        case READY:
            if (prim && type == RoxGestureEvent.TOUCH_BEGIN) {
                state = BEGIN;
                touch0 = pt;
                longPressTimer = cast(Actuate.timer(longPressDelay).onComplete(sendLongPress, [ pt ]));
                stopTween();
                if (mode == GESTURE_CAPTURE) {
                    var stage = Lib.current.stage;
                    if (overlay == null) {
                        overlay = new Sprite();
                        overlay.name = "overlay";
                        overlay.graphics.rox_fillRect(0x01FFFFFF, 0, 0, stage.stageWidth, stage.stageHeight);
                    }
                    stage.addChild(overlay);
                    for (type in listenEvents) overlay.addEventListener(type, handler);
                }
            } else {
                handled = false;
            }
        case BEGIN:
            if (prim && type == RoxGestureEvent.TOUCH_END) {
                owner.dispatchEvent(new RoxGestureEvent(RoxGestureEvent.GESTURE_TAP, pt.lx, pt.ly, pt.sx, pt.sy));
                setReady();
            } else if (prim && type == RoxGestureEvent.TOUCH_MOVE) {
                var pan = new Point(pt.sx - touch0.sx, pt.sy - touch0.sy);
                owner.dispatchEvent(new RoxGestureEvent(RoxGestureEvent.GESTURE_PAN, pt.lx, pt.ly, pt.sx, pt.sy, pan));
                setMove(pt);
            } else if (!prim && type == RoxGestureEvent.TOUCH_BEGIN) {
                setTwoFingerMove(pt);
            } else {
                handled = false;
            }
        case MOVE:
            if (prim && type == RoxGestureEvent.TOUCH_MOVE) {
                var pan = new Point(pt.sx - touch0.sx, pt.sy - touch0.sy);
                owner.dispatchEvent(new RoxGestureEvent(RoxGestureEvent.GESTURE_PAN, pt.lx, pt.ly, pt.sx, pt.sy, pan));
                setMove(pt);
            } else if (prim && (type == RoxGestureEvent.TOUCH_END ||
                    (mode != GESTURE_CAPTURE && type == RoxGestureEvent.TOUCH_OUT && e.target == owner))) {
                if (swipeTimeout <= 0 || pt.time - touch0.time < swipeTimeout) {
                    var beginpt = touchList.pop(), endpt: TouchPoint = null;
                    for (i in touchList) {
                        if (beginpt.time - i.time > SWIPE_SAMPLE_TIME) break;
                        endpt = i;
                    }
                    if (endpt != null) {
                        var dx: Float, dy: Float;
                        var angle = Math.atan2(dy = beginpt.sy - endpt.sy, dx = beginpt.sx - endpt.sx);
                        var velocity = Point.polar(new Point(dx, dy).length / (beginpt.time - endpt.time) * VELOCITY_RATIO, angle);
                        owner.dispatchEvent(new RoxGestureEvent(RoxGestureEvent.GESTURE_SWIPE, pt.lx, pt.ly, pt.sx, pt.sy, velocity));
                    }
                }
                setReady();
            } else if (!prim && type == RoxGestureEvent.TOUCH_BEGIN) {
                owner.dispatchEvent(new RoxGestureEvent(RoxGestureEvent.GESTURE_BEGIN, pt.lx, pt.ly, pt.sx, pt.sy));
                setTwoFingerMove(pt);
            } else {
                handled = false;
            }
        case TWO_FINGER_MOVE:
            if (type == RoxGestureEvent.TOUCH_END) {
                owner.dispatchEvent(new RoxGestureEvent(RoxGestureEvent.GESTURE_END, pt.lx, pt.ly, pt.sx, pt.sy));
                setReady();
            } else if (type == RoxGestureEvent.TOUCH_MOVE) {
                var pt1 = prim ? touch1 : touch0, pt2 = prim ? touch0 : touch1;
                var scale = Point.distance(pt.spt, pt1.spt) / Point.distance(pt2.spt, pt1.spt);
                var angle = Math.atan2(pt.sy - pt1.sy, pt.sx - pt1.sx) - Math.atan2(pt2.sy - pt1.sy, pt2.sx - pt1.sx); // in radius
                var mid = Point.interpolate(pt1.lpt, pt2.lpt, 0.5);
                var gmid = owner.localToGlobal(mid);
                if (scale != 1) owner.dispatchEvent(new RoxGestureEvent(RoxGestureEvent.GESTURE_PINCH, mid.x, mid.y, gmid.x, gmid.y, scale));
                if (angle != 0) owner.dispatchEvent(new RoxGestureEvent(RoxGestureEvent.GESTURE_ROTATION, mid.x, mid.y, gmid.x, gmid.y, angle));
                if (prim) { touch0 = pt; } else { touch1 = pt; }
            } else {
                handled = false;
            }
        }
        return handled;
    }

    private inline function sendLongPress(pt: TouchPoint) {
        owner.dispatchEvent(new RoxGestureEvent(RoxGestureEvent.GESTURE_LONG_PRESS, pt.lx, pt.ly, pt.sx, pt.sy));
        setReady();
    }

    private function setReady() {
        state = READY;
        touch0 = touch1 = null;
        touchList.clear();
        cancelLongPress();
        if (overlay != null && mode == GESTURE_CAPTURE) {
            for (type in listenEvents) overlay.removeEventListener(type, handler);
            Lib.current.stage.removeChild(overlay);
        }
    }

    private inline function setMove(pt: TouchPoint) {
        state = MOVE;
        if (touch0 != null) touchList.push(touch0);
        touch0 = pt;
        cancelLongPress();
    }

    private inline function setTwoFingerMove(pt: TouchPoint) {
        state = TWO_FINGER_MOVE;
        touch1 = pt;
        cancelLongPress();
    }

    private inline function cancelLongPress() {
        if (longPressTimer != null) {
            longPressTimer.stop(null, false, false);
            longPressTimer = null;
        }
    }

    private static inline var MAP: Array<String> = [
        MouseEvent.MOUSE_DOWN, RoxGestureEvent.TOUCH_BEGIN,
        MouseEvent.MOUSE_UP, RoxGestureEvent.TOUCH_END,
        MouseEvent.MOUSE_MOVE, RoxGestureEvent.TOUCH_MOVE,
        MouseEvent.MOUSE_OVER, RoxGestureEvent.TOUCH_OVER,
        MouseEvent.MOUSE_OUT, RoxGestureEvent.TOUCH_OUT,
        MouseEvent.ROLL_OVER, RoxGestureEvent.TOUCH_ROLL_OVER,
        MouseEvent.ROLL_OUT, RoxGestureEvent.TOUCH_ROLL_OUT,
        MouseEvent.CLICK, RoxGestureEvent.TOUCH_TAP,
        TouchEvent.TOUCH_BEGIN, RoxGestureEvent.TOUCH_BEGIN,
        TouchEvent.TOUCH_END, RoxGestureEvent.TOUCH_END,
        TouchEvent.TOUCH_MOVE, RoxGestureEvent.TOUCH_MOVE,
        TouchEvent.TOUCH_OVER, RoxGestureEvent.TOUCH_OVER,
        TouchEvent.TOUCH_OUT, RoxGestureEvent.TOUCH_OUT,
        TouchEvent.TOUCH_ROLL_OVER, RoxGestureEvent.TOUCH_ROLL_OVER,
        TouchEvent.TOUCH_ROLL_OUT, RoxGestureEvent.TOUCH_ROLL_OUT,
        TouchEvent.TOUCH_TAP, RoxGestureEvent.TOUCH_TAP ];

    private static var typeMap: Hash<String> = initTypeMap();

    private inline static function initTypeMap() {
        var map = new Hash<String>();
        for (i in 0...(MAP.length >> 1)) {
            map.set(MAP[i << 1], MAP[(i << 1) + 1]);
        }
        return map;
    }

}

private class TouchPoint {
    public var tid: Int;
    public var lx: Float;
    public var ly: Float;
    public var sx: Float;
    public var sy: Float;
    public var lpt: Point;
    public var spt: Point;
    public var time: Float;
    public function new(src: InteractiveObject, e: Dynamic, touchId: Int) {
        tid = touchId;
        sx = e.stageX;
        sy = e.stageY;
        spt = new Point(sx, sy);
        lpt = src.globalToLocal(spt);
        lx = lpt.x;
        ly = lpt.y;
        time = Timer.stamp();
    }
}
