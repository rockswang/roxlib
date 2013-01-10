package com.roxstudio.haxe.game;

import com.roxstudio.haxe.utils.Random;
import nme.Assets;
import nme.geom.Point;
import nme.geom.Rectangle;
import nme.media.Sound;

using StringTools;

/**
 * ...
 * @author Rocks Wang
 */

class GameUtil {

    public static inline var PId2 = Math.PI / 2;
    public static inline var PI = Math.PI;
    public static inline var PI3d2 = Math.PI * 3 / 2;
    public static inline var PIm2 = Math.PI * 2;
    public static inline var R2D = 180 / Math.PI;
    public static inline var D2R = Math.PI / 180;
    public static inline var IMAX = 2147483647;
    public static inline var IMIN = -2147483648;

    public static var max: Dynamic;
    public static var min: Dynamic;

    private function new() {
    }

#if neko
    public static inline function color(argb: Int) : Dynamic {
        return { rgb: argb & 0xFFFFFF, a: argb >>> 24 };
    }
#else
    public static inline function color(argb: Int) : Int {
        return argb;
    }
#end

    public static inline function clear(array: Dynamic) : Void {
#if flash
        array.length = 0;
#else
        array.splice(0, array.length);
#end
    }

    /**
    * The "magic" haXe class initializer
    **/
    private static function __init__() : Void {
        max = Reflect.makeVarArgs(__rox_max);
        min = Reflect.makeVarArgs(__rox_min);
    }

    private static function __rox_max(args: Array<Dynamic>) : Dynamic {
        var m: Dynamic = Math.NEGATIVE_INFINITY;
        for (a in args) {
            if (a > m) m = a;
        }
        return m;
    }

    private static function __rox_min(args: Array<Dynamic>) : Dynamic {
        var m: Dynamic = Math.POSITIVE_INFINITY;
        for (a in args) {
            if (a < m) m = a;
        }
        return m;
    }

    public static inline function reverseIter<T>(?iterable: Iterable<T>, ?iter: Iterator<T>) : Iterator<T> {
        if (iterable != null) iter = iterable.iterator();
        var all: Array<T> = [];
        for (i in iter) {
            all.push(i);
        }
        all.reverse();
        return all.iterator();
    }

    public static inline function normalizeAngle(angle: Float) : Float {
        if ((angle %= PIm2) < 0) angle += PIm2;
        return angle;
    }

    public static inline function distance(p1: Point, p2: Point) : Float {
        return distanceFF(p1.x, p1.y, p2.x, p2.y);
    }

    public static inline function distanceFF(x1: Float, y1: Float, x2: Float, y2: Float) : Float {
        return Math.sqrt((x1 -= x2) * x1 + (y1 -= y2) * y1);
    }

    public static inline function distanceFR(x: Float, y: Float, p: Point) : Float {
        return distanceFF(x, y, p.x, p.y);
    }

    public static inline function squareDistance(p1: Point, p2: Point) : Float {
        var dx: Float, dy: Float;
        return (dx = p1.x - p2.x) * dx + (dy = p1.y - p2.y) * dy;
    }

    public static inline function theta(p1: Point, p2: Point) : Float {
        return Math.atan2(p2.y - p1.y, p2.x - p1.x);
    }

    public static inline function checkCollision(x1: Float, y1: Float, w1: Float, h1: Float, x2: Float, y2: Float, w2: Float, h2: Float) : Bool {
        return !(x2 + w2 < x1 || x2 - w1 > x1 || y2 + h2 < y1 || y2 - h1 > y1);
    }

    public static inline function checkCollisionRR(r1: Rectangle, ?ox1: Null<Float> = 0, ?oy1: Null<Float> = 0, r2: Rectangle, ?ox2: Null<Float> = 0, ?oy2: Null<Float> = 0) : Bool {
        return checkCollision(r1.x + ox1, r1.y + oy1, r1.width, r1.height, r2.x + ox2, r2.y + oy2, r2.width, r2.height);
    }

    public static inline function checkCollisionFR(x1: Float, y1: Float, w1: Float, h1: Float, r2: Rectangle, ?ox2: Null<Float> = 0, ?oy2: Null<Float> = 0) : Bool {
        return checkCollision(x1, y1, w1, h1, r2.x + ox2, r2.y + oy2, r2.width, r2.height);
    }

    public static inline function pointInRect(ptx: Float, pty: Float, x: Float, y: Float, w: Float, h: Float) : Bool {
//		trace("pointInRect(" + ptx + "," + pty + "," + x + "," + y + "," + w + "," + h + ")=" + (ptx >= x && ptx < x + w && pty >= y && pty < y + h));
        return (ptx >= x && ptx < x + w && pty >= y && pty < y + h);
    }

    public static inline function pointInRectR(ptx: Float, pty: Float, r: Rectangle, ?ox: Null<Float> = 0, ?oy: Null<Float> = 0) : Bool {
        return pointInRect(ptx, pty, r.x + ox, r.y + oy, r.width, r.height);
    }

    public static inline function radian(pt1: Point, pt2: Point) : Float {
        var r = Math.atan2(pt1.y - pt2.y, pt2.x - pt1.x);
        return r < 0 ? PIm2 + r : r;
    }

    public static inline function r2d(radian: Float) : Float {
        return radian * R2D;
    }

    public static inline function rectStr(r: Rectangle) : String {
        return "[x=" + r.x + ",y=" + r.y + ",w=" + r.width + ",h=" + r.height + "]";
    }

    public static inline function pointStr(p: Point) : String {
        return "(" + p.x + "," + p.y + ")";
    }

    public static function parseCsv(csv: String) : Array<Array<String>> {
        var lines: Array<String> = csv.trim().replace("\r\n", "\n").split("\n");
        var ret: Array<Array<String>> = [];
        for (l in lines) {
            ret.push(l.trim().split(","));
        }
        return ret;
    }

    public static function csvToHash(csv: String, ?table: Hash<Array<String>>, ?prefix: String = "") : Hash<Array<String>> {
        if (table == null) table = new Hash<Array<String>>();
        var arr = parseCsv(csv);
        for (a in arr) {
            table.set(prefix + a[0], a);
        }
        return table;
    }

    public static function unXml(txt: String) : String {
        var ret: StringBuf = new StringBuf();
        var i1: Int = 0, i2: Int = 0;
        while (true) {
            i1 = txt.indexOf("&", i2);
            if (i1 < 0) {
                ret.addSub(txt, i2, txt.length - i2);
                break;
            }
            ret.addSub(txt, i2, i1 - i2);
            i2 = txt.indexOf(";", i1);
            if (i2 < 0) {
                ret.addSub(txt, i1, txt.length - i1);
                break;
            }
            i2++;
            switch (txt.substr(i1, i2 - i1)) {
            case "&amp;":
                ret.addChar(0x26); // '&'
            case "&lt;":
                ret.addChar(0x3C); // '<'
            case "&gt;":
                ret.addChar(0x3E); // '>'
            case "&quot;":
                ret.addChar(0x22); // '"'
            case "&apos;":
                ret.addChar(0x27); // '\''
            default:
                ret.addSub(txt, i1, i2 - i1);
            }
        }
        return ret.toString();
    }

    public static function shuffle<T>(array: Array<T>, ?randomSeed: Null<Int>) : Array<T> {
        var rand = new Random();
        if (randomSeed != null) rand.setSeed(randomSeed);
        var len = array.length;
        for (i in 0...len - 1) {
            var i1 = len - i - 1;
            var i2 = rand.int(i1 + 1);
            var tmp: T = array[i1];
            array[i1] = array[i2];
            array[i2] = tmp;
        }
        return array;
    }

    public static inline function hashArrayAdd<T>(hasharr: Hash<Array<T>>, key: String, elem: T) : Hash<Array<T>> {
        var arr = hasharr.get(key);
        if (arr == null) hasharr.set(key, arr = []);
        arr.push(elem);
        return hasharr;
    }

    public static inline function loadSound(inSoundPath: String) : Sound {
        return Assets.getSound(inSoundPath);
    }

}