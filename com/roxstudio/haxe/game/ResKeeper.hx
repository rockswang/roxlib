package com.roxstudio.haxe.game;

import com.roxstudio.haxe.game.GameUtil;
import nme.Assets;
import nme.display.BitmapData;
import nme.display.BitmapDataChannel;
import nme.geom.Point;
import nme.geom.Rectangle;
import nme.utils.ByteArray;

#if cpp
import sys.FileSystem;
import sys.io.File;
#end

using StringTools;

class ResKeeper {

    public static var currentBundle(default, set_currentBundle): String;

    private static var map: Hash<Dynamic>;
    private static var bundles: Hash<Array<String>>;
    private static var maxId: Int = 1;

    private function new() {
    }

    private static function __init__() {
        map = new Hash<Dynamic>();
        bundles = new Hash<Array<String>>();
        set_currentBundle("default");
    }

    public static function getBundle(?bundleId) : Array<Dynamic> {
        if (bundleId == null) bundleId = currentBundle;
        var bundle = bundles.get(bundleId);
        if (bundle == null) return null;
        var ret: Array<Dynamic> = [];
        for (id in bundle) ret.push(map.get(id));
        return ret;
    }

    public static function disposeBundle(bundleId: String) {
#if debug
        var buf = new StringBuf();
        for (gid in bundles.keys()) {
            buf.add("BUNDLE(" + gid + ")=[");
            for (s in bundles.get(gid)) {
                buf.add(s);
                buf.add(",");
            }
            buf.add("],");
        }
        trace(">>>>disposing '" + bundleId + "' :{{ " + buf + " }}");
#end
        var arr = bundles.get(bundleId);
        if (arr == null) return;
        bundles.remove(bundleId);
        for (id in arr) {
            var res = map.get(id);
            map.remove(id);
            if (res == null) continue;
            if (Reflect.hasField(res, "dispose")) {
                var func = Reflect.field(res, "dispose");
                if (Reflect.isFunction(func)) Reflect.callMethod(res, func, [ ]);
            }
//            if (Std.is(res, BitmapData)) {
//                cast(res, BitmapData).dispose();
//            } else if (Std.is(res, RoxNinePatchData)) {
//                cast(res, RoxNinePatchData).dispose();
//            }
        }
    }

    public static function add(?resId: String, res: Dynamic, ?bundleId: String) : String {
        if (resId == null) resId = "res_" + (maxId++);
        if (bundleId == null) bundleId = currentBundle;
        map.set(resId, res);
        checkCreate(bundleId).push(resId);
        return resId;
    }

    public static inline function get(id: String) : Dynamic {
        return map.get(id);
    }

    /**
    * asset: id-prefix "assets://", e.g.: "assets://res/image.jpg"
    **/
    public static function getAssetImage(path: String, ?bundleId: String) : BitmapData {
        var bmd: BitmapData = cast(get("assets://" + path));
        if (bmd == null) {
            bmd = loadAssetImage(path);
            if (bmd != null) {
                add("assets://" + path, bmd, bundleId);
            } else {
                throw "Asset " + path + " not exist.";
            }
        }
        return bmd;
    }

#if cpp
    public static function getLocalImage(path: String, ?bundleId: String) : BitmapData {
        var id: String = "";
#if windows
        path = path.replace("\\", "/");
        if (path.length <= 3 || path.substr(1, 2) != ":/") path = FileSystem.fullPath(path);
        id = "file:///" + path.replace("\\", "/");
#else
        if (!path.startsWith("/")) path = FileSystem.fullPath(path);
        id = "file://" + path;
#end
        var bmd: BitmapData = cast(get(id));
        if (bmd == null) {
            bmd = loadLocalImage(path);
            if (bmd != null) {
                add(id, bmd, bundleId);
            } else {
                throw "Local file " + path + " not exist.";
        }
        }
        return bmd;
    }

    /**
    * local file: id-prefix "file://", e.g.: "file:///sdcard/myapp/image.jpg" or "file:///D:/myapp/image.jpg"
    **/
    public static function loadLocalImage(path: String) : BitmapData {
        var bb = File.getBytes(path);
        return bb != null ? BitmapData.loadFromHaxeBytes(bb) : null;
    }
#end

//    public static function getBitmapLoader(url: String) : RoxBitmapLoader {
//        var ldr: RoxBitmapLoader = cast(map.get(url));
//        if (ldr == null) {
//            ldr = new RoxBitmapLoader(url);
//            add(url, ldr);
//        }
//        return ldr;
//    }
//
    public static function loadAssetImage(inBitmapPath: String, ?inAlphaBitmapPath: String, ?inTransparentPixel: Point): BitmapData {
        var bmp: BitmapData = Assets.getBitmapData(inBitmapPath, false); // not using cache, image will be managed by engine
        var transparent = #if html5 true #else bmp.transparent #end ;
#if debug
        trace("bitmap loaded: path=" + inBitmapPath + ", width=" + bmp.width + ", height=" + bmp.height + ", transparent=" + transparent);
#end

        var doCopy = #if (neko || cpp) true #else inAlphaBitmapPath != null || inTransparentPixel != null #end;

        var w = bmp.width, h = bmp.height, rect = new Rectangle(0, 0, w, h);
        if (doCopy && !transparent) {
            var transbmp = new BitmapData(w, h, true, #if neko { rgb: 0, a: 0 } #else 0 #end);
            transbmp.copyPixels(bmp, rect, new Point(0, 0));
            bmp = transbmp;
        }

        if (inAlphaBitmapPath != null) {
            var alphabmp: BitmapData = Assets.getBitmapData(inAlphaBitmapPath);
#if debug
            trace("alphaBitmap loaded: path=" + inAlphaBitmapPath + ", width=" + alphabmp.width + ", height=" + alphabmp.height);
#end
            bmp.copyChannel(alphabmp, rect, new Point(0, 0), BitmapDataChannel.RED, BitmapDataChannel.ALPHA);
        } else if (inTransparentPixel != null && GameUtil.pointInRectR(inTransparentPixel.x, inTransparentPixel.y, rect)) {
            var rgb: Int = bmp.getPixel(Std.int(inTransparentPixel.x), Std.int(inTransparentPixel.y));
            var buf: ByteArray = bmp.getPixels(rect);
            buf.position = 0;
            var newbuf: ByteArray = new ByteArray();
            for (i in 0...(buf.length >> 2)) {
                var color = buf.readInt();
                newbuf.writeInt((color & 0x00FFFFFF) == rgb ? rgb : color);
            }
            newbuf.position = 0;
            bmp.setPixels(rect, newbuf);
        }
        return bmp;
    }

    private static inline function set_currentBundle(bundleId: String) : String {
        checkCreate(bundleId);
        return currentBundle = bundleId;
    }

    private static inline function checkCreate(bundleId: String) : Array<String> {
        var arr: Array<String>;
        if ((arr = bundles.get(bundleId)) == null) bundles.set(bundleId, arr = []);
        return arr;
    }

}
