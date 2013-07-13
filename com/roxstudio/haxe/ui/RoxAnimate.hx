package com.roxstudio.haxe.ui;

import nme.geom.Rectangle;
import nme.geom.Point;
using com.roxstudio.haxe.ui.UiUtil;

class RoxAnimate {

    public static inline var NONE = 0; // no animate
    public static inline var SLIDE = 1; // arg: String = "up"/"right"/"down"/"left"
    public static inline var ZOOM_IN = 2; // popup, arg: Rectangle
    public static inline var ZOOM_OUT = 3; // shrink, arg: Rectangle
    public static inline var FADE = 4;

    public static var SLIDE_LEFT = new RoxAnimate(SLIDE, "left");
    public static var SLIDE_RIGHT = new RoxAnimate(SLIDE, "right");
    public static var NO_ANIMATE = new RoxAnimate(NONE, null);

    public static inline var DEFAULT_INTERVAL = 0.4;

    public var type(default, null): Int;
    public var interval(default, null): Float;
    public var arg(default, null): Dynamic;

    public function new(inType: Int, inArg: Dynamic, ?inInterval: Null<Float> = DEFAULT_INTERVAL) {
        this.type = inType;
        this.interval = inInterval;
        this.arg = inArg;
    }

    public function getReverse() : RoxAnimate {
        return switch (type) {
            case SLIDE:
                var newarg = switch (cast(arg, String)) { case "up": "down"; case "down": "up"; case "left": "right"; case "right": "left"; case _: ""; }
                new RoxAnimate(SLIDE, newarg, interval);
            case ZOOM_IN:
                new RoxAnimate(ZOOM_OUT, arg, interval);
            case ZOOM_OUT:
                new RoxAnimate(ZOOM_IN, arg, interval);
            case FADE:
                new RoxAnimate(ZOOM_IN, arg, interval); // TODO
            #if haxe3 case _ #else default #end:
                this;
        }
    }

    public function toString() : String {
        return "Anim{type:" + type + ",interval:" + interval + ",arg:"
                + (Std.is(arg, Point) ? cast(arg, Point).rox_pointStr()
                : (Std.is(arg, Rectangle) ? cast(arg, Rectangle).rox_rectStr() : arg)) + "}";
    }
}
