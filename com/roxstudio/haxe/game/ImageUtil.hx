package com.roxstudio.haxe.game;

import com.roxstudio.haxe.ui.RoxBitmapLoader;
import nme.net.URLLoader;
import com.roxstudio.haxe.ui.RoxNinePatchData;
import com.roxstudio.haxe.ui.RoxNinePatch;
import com.roxstudio.haxe.game.GameUtil;
import nme.Assets;
import nme.display.BitmapData;
import nme.display.BitmapDataChannel;
import nme.geom.Point;
import nme.geom.Rectangle;
import nme.utils.ByteArray;

class ImageUtil {

    public static var currentGroup(default, set_currentGroup): String;

    private static var map: Hash<Dynamic>;
    private static var groups: Hash<Array<String>>;

    private function new() {
    }

    private static function __init__() {
        map = new Hash<Dynamic>();
        groups = new Hash<Array<String>>();
        set_currentGroup("default");
    }

    public static function disposeGroup(groupId: String) {
        var buf = new StringBuf();
        for (gid in groups.keys()) {
            buf.add("GROUP(" + gid + ")=[");
            for (s in groups.get(gid)) {
                buf.add(s);
                buf.add(",");
            }
            buf.add("],");
        }
//        trace(">>>>disposing '" + groupId + "' :{{ " + buf + " }}");
        var arr = groups.get(groupId);
        if (arr == null) return;
        groups.remove(groupId);
        for (path in arr) {
            var obj = map.get(path);
            map.remove(path);
            if (obj == null) continue;
            if (Std.is(obj, BitmapData)) {
                cast(obj, BitmapData).dispose();
            } else if (Std.is(obj, RoxNinePatchData)) {
                cast(obj, RoxNinePatchData).dispose();
            } else if (Std.is(obj, RoxBitmapLoader)) {
                cast(obj, RoxBitmapLoader).dispose();
            }
        }
    }

    private static function set_currentGroup(groupId: String) : String {
        if (groups.get(groupId) == null) { // not exist, create new group
            groups.set(groupId, []);
        }
        return currentGroup = groupId;
    }

    public static function getBitmapData(path: String) : BitmapData {
        var bmd: BitmapData = cast(map.get(path));
        if (bmd == null) {
            bmd = loadBitmapData(path);
            if (bmd != null) {
                map.set(path, bmd);
                groups.get(currentGroup).push(path);
            } else {
                throw "Asset " + path + " not exist.";
            }
        }
        return bmd;
    }

    public static function getBitmapLoader(url: String) : RoxBitmapLoader {
        var ldr: RoxBitmapLoader = cast(map.get(url));
        if (ldr == null) {
            ldr = new RoxBitmapLoader(url);
            map.set(url, ldr);
            groups.get(currentGroup).push(url);
        }
        return ldr;
    }

    public static function getNinePatchData(path: String) : RoxNinePatchData {
        var nine: RoxNinePatchData = cast(map.get(path));
        if (nine == null) {
            var bmd = loadBitmapData(path);
            if (bmd != null) {
                nine = RoxNinePatchData.fromAndroidNinePng(bmd);
                map.set(path, nine);
                groups.get(currentGroup).push(path);
            } else {
                throw "Asset " + path + " not exist.";
            }
        }
        return nine;
    }

    public static function loadBitmapData(inBitmapPath: String, ?inAlphaBitmapPath: String, ?inTransparentPixel: Point): BitmapData {
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

}
