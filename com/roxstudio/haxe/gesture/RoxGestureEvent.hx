package com.roxstudio.haxe.gesture;

import nme.events.Event;
import nme.events.MouseEvent;
import nme.events.TouchEvent;
import nme.geom.Point;

class RoxGestureEvent extends Event {

    public static inline var TOUCH_BEGIN = "rox_touch_begin";
    public static inline var TOUCH_END = "rox_touch_end";
    public static inline var TOUCH_MOVE = "rox_touch_move";
    public static inline var TOUCH_OVER = "rox_touch_over";
    public static inline var TOUCH_OUT = "rox_touch_out";
    public static inline var TOUCH_ROLL_OVER = "rox_touch_roll_over";
    public static inline var TOUCH_ROLL_OUT = "rox_touch_roll_in";
    public static inline var TOUCH_TAP = "rox_touch_tap";

    public static inline var GESTURE_TAP = "rox_gesture_tap";
//    public static inline var GESTURE_DOUBLE_TAP = "rox_gesture_double_tap";
    public static inline var GESTURE_LONG_PRESS = "rox_gesture_long_press";
    public static inline var GESTURE_PAN = "rox_gesture_pan";
    public static inline var GESTURE_SWIPE = "rox_gesture_swipe";
    public static inline var GESTURE_BEGIN = "rox_gesture_begin";
    public static inline var GESTURE_PINCH = "rox_gesture_pinch";
    public static inline var GESTURE_ROTATION = "rox_gesture_rotation";
    public static inline var GESTURE_END = "rox_gesture_end";

    public var localX(default, null): Float;
    public var localY(default, null): Float;
    public var stageX(default, null): Float;
    public var stageY(default, null): Float;
    public var touchPointID(default, null): Int;
    public var extra(default, null): Dynamic;

    public function new(type: String, ?bubbles: Null<Bool> = true, cancelable: Null<Bool> = false,
                        inLocalX: Float, inLocalY: Float, inStageX: Float, inStageY: Float,
                        ?inTouchPointId: Null<Int> = 0, ?inExtra: Dynamic) {
        super(type, bubbles, cancelable);
        localX = inLocalX;
        localY = inLocalY;
        stageX = inStageX;
        stageY = inStageY;
        touchPointID = inTouchPointId;
        extra = inExtra;
    }

    override public function toString() : String {
        return type + "(" + touchPointID + "): local=(" + localX + "," + localY
                + "), stage=(" + stageX + "," + stageY + "), extra="
                + (Std.is(extra, Point) ? "Point(" + extra.x + "," + extra.y + ")" : extra);
    }

}
