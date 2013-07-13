package com.roxstudio.haxe.game;

import org.bytearray.gif.decoder.GIFDecoder;
import com.roxstudio.haxe.io.IOUtil;
import nme.media.Sound;
import nme.text.Font;
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

#if haxe3

private typedef Hash<T> = Map<String, T>;
private typedef IntHash<T> = Map<Int, T>;

#end

class ResKeeper {

    public static inline var DEFAULT_BUNDLE = "default";

    public static var currentBundle(default, set_currentBundle): String;

    private static var map: Hash<Dynamic>;
    private static var bundles: Hash<Array<String>>;
    private static var maxId: Int = 1;

    private function new() {
    }

    private static function __init__() {
        map = new Hash<Dynamic>();
        bundles = new Hash<Array<String>>();
        set_currentBundle(DEFAULT_BUNDLE);
    }

    public static function getBundle(?bundleId) : Hash<Dynamic> {
        if (bundleId == null) bundleId = currentBundle;
        var bundle = bundles.get(bundleId);
        if (bundle == null) return null;
        var ret = new Hash<Dynamic>();
        for (id in bundle) ret.set(id, map.get(id));
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

    public static function remove(id: String) {
        if (map.remove(id)) {
            for (arr in bundles) {
                arr.remove(id);
            }
        }
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
                throw "Asset image " + path + " not exist.";
            }
        }
        return bmd;
    }

    public static function getAssetFont(path: String, ?bundleId: String) : Font {
        var font: Font = cast(get("assets://" + path));
        if (font == null) {
            font = loadAssetFont(path);
            if (font != null) {
                add("assets://" + path, font, bundleId);
            } else {
                throw "Asset font " + path + " not exist.";
            }
        }
        return font;
    }

    public static function getAssetData(path: String, ?bundleId: String) : ByteArray {
        var data: ByteArray = cast(get("assets://" + path));
        if (data == null) {
            data = loadAssetData(path);
            if (data != null) {
                add("assets://" + path, data, bundleId);
            } else {
                throw "Asset data " + path + " not exist.";
            }
        }
        return data;
    }

    public static function getAssetText(path: String, ?bundleId: String) : String {
        var text: String = cast(get("assets://" + path));
        if (text == null) {
            text = loadAssetText(path);
            if (text != null) {
                add("assets://" + path, text, bundleId);
            } else {
                throw "Asset text " + path + " not exist.";
            }
        }
        return text;
    }

    public static function getAssetSound(path: String, ?bundleId: String) : Sound {
        var snd: Sound = cast(get("assets://" + path));
        if (snd == null) {
            snd = loadAssetSound(path);
            if (snd != null) {
                add("assets://" + path, snd, bundleId);
            } else {
                throw "Asset sound " + path + " not exist.";
            }
        }
        return snd;
    }

#if cpp

    /**
    * local file: id-prefix "file://", e.g.: "file:///sdcard/myapp/image.jpg" or "file:///D:/myapp/image.jpg"
    **/
    public static function getLocalImage(path: String, ?bundleId: String) : BitmapData {
        var id: String = path2url(path);
        var bmd: BitmapData = cast(get(id));
        if (bmd == null) {
            bmd = loadLocalImage(path);
            if (bmd != null) {
                add(id, bmd, bundleId);
            } else {
                throw "Local image file " + path + " not exist.";
            }
        }
        return bmd;
    }

    public static function getLocalText(path: String, ?bundleId: String) : String {
        var id: String = path2url(path);
        var txt: String = cast(get(id));
        if (txt == null) {
            txt = loadLocalText(path);
            if (txt != null) {
                add(id, txt, bundleId);
            } else {
                throw "Local text file " + path + " not exist.";
            }
        }
        return txt;
    }

    public static function getLocalData(path: String, ?bundleId: String) : ByteArray {
        var id: String = path2url(path);
        var data: ByteArray = cast(get(id));
        if (data == null) {
            data = loadLocalData(path);
            if (data != null) {
                add(id, data, bundleId);
            } else {
                throw "Local binary file " + path + " not exist.";
            }
        }
        return data;
    }

    public static function loadLocalImage(path: String) : BitmapData {
        if (FileSystem.exists(path)) {
            var bytes = File.getBytes(path);
            if (bytes == null) return null;
            var ba = IOUtil.rox_toByteArray(bytes);
            if (ba[0] == 'G'.code && ba[1] == 'I'.code && ba[2] == 'F'.code) {
                var gifdec = new GIFDecoder();
                gifdec.read(ba);
                return gifdec.getFrameCount() > 0 ? gifdec.getImage().bitmapData : null;
            } else {
                return BitmapData.loadFromBytes(ba);
            }
        }
        return null;
    }

    public static inline function loadLocalText(path: String) : String {
        return FileSystem.exists(path) ? File.getContent(path) : null;
    }

    public static inline function loadLocalData(path: String) : ByteArray {
        return FileSystem.exists(path) ? ByteArray.fromBytes(File.getBytes(path)) : null;
    }

    public static inline function url2path(url: String) : String {
#if windows
        return url.substr(8); // "file:///D:/xxx/xxx/xxx.xxx"
#else
        return url.substr(7); // "file:///mnt/sdcard/xxx/xxx.xxx"
#end
    }

    public static inline function path2url(path: String) : String {
#if windows
        path = path.replace("\\", "/");
        if (path.length <= 3 || path.substr(1, 2) != ":/") path = FileSystem.fullPath(path);
        return "file:///" + path.replace("\\", "/");
#else
        if (!path.startsWith("/")) path = FileSystem.fullPath(path);
        return "file://" + path;
#end
    }

#end

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

    public static inline function loadAssetFont(path: String) : Font {
        return Assets.getFont(path);
    }

    public static inline function loadAssetSound(path: String) : Sound {
        return Assets.getSound(path);
    }

    public static inline function loadAssetData(path: String) : ByteArray {
        return Assets.getBytes(path);
    }

    public static inline function loadAssetText(path: String) : String {
        return Assets.getText(path);
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
