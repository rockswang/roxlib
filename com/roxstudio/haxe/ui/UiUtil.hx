package com.roxstudio.haxe.ui;

import nme.events.MouseEvent;
import nme.display.InteractiveObject;
import nme.events.EventDispatcher;
import nme.events.Event;
import nme.Lib;
import com.roxstudio.haxe.game.GfxUtil;
import haxe.Timer;
import nme.text.TextFieldType;
import com.roxstudio.haxe.net.RoxURLLoader;
import com.roxstudio.haxe.game.ResKeeper;
import com.roxstudio.haxe.game.GameUtil;
import com.roxstudio.haxe.game.ResKeeper;
import nme.display.Bitmap;
import nme.display.BitmapData;
import nme.display.DisplayObject;
import nme.display.DisplayObjectContainer;
import nme.display.GradientType;
import nme.display.Shape;
import nme.display.Sprite;
import nme.geom.Matrix;
import nme.geom.Point;
import nme.geom.Rectangle;
import nme.text.TextField;
import nme.text.TextFormat;
import nme.text.TextFormatAlign;
import nme.utils.ByteArray;

#if haxe3

typedef Hash<T> = Map<String, T>;
typedef IntHash<T> = Map<Int, T>;

#end

class UiUtil {

    public static inline var LEFT = 0x1;
    public static inline var HCENTER = 0x2;
    public static inline var RIGHT = 0x3;
    public static inline var JUSTIFY = 0x4;
    public static inline var TOP = 0x10;
    public static inline var VCENTER = 0x20;
    public static inline var BOTTOM = 0x30;
    public static inline var TOP_LEFT = 0x11; // shortcut for TOP | LEFT
    public static inline var TOP_CENTER = 0x12; // shortcut for TOP | HCENTER
    public static inline var CENTER = 0x22; // shortcut for VCENTER | HCENTER
    public static inline var BOTTOM_CENTER = 0x32; // shortcut for BOTTOM | HCENTER

    private function new() { }

    /**
    * usage: var bmp = new Bitmap(bitmapdata).smooth();
    **/
    public static inline function rox_smooth(bmp: Bitmap) : Bitmap {
        bmp.smoothing = true;
        return bmp;
    }

    public static inline function textFormat(color: Int, size: Float, ?hAlign: Int = LEFT) : TextFormat {
        var format = new TextFormat();
#if android
        format.font = new nme.text.Font("/system/fonts/DroidSansFallback.ttf").fontName;
#else
        format.font = "Microsoft YaHei";
#end
        format.color = color;
        format.size = Std.int(size);
        format.align = switch (hAlign & 0x0F) {
            case HCENTER: TextFormatAlign.CENTER;
            case RIGHT: TextFormatAlign.RIGHT;
            case JUSTIFY: TextFormatAlign.JUSTIFY;
            #if haxe3 case _ #else default #end: TextFormatAlign.LEFT;
        };
        return format;
    }

    private static var textfieldCanvas: BitmapData;
    public static function staticText(text: String, ?color: Int = 0, ?size: Float = 24, ?hAlign: Int = LEFT,
                                      ?multiline: Bool = false, ?width: Null<Float>, ?height: Null<Float>) : TextField {
        if (textfieldCanvas == null) textfieldCanvas = new BitmapData(100, 100);
        var tf = new TextField();
        var ox = tf.x, oy = tf.y;
        tf.selectable = false;
        tf.mouseEnabled = false;
        tf.defaultTextFormat = textFormat(color & 0x00FFFFFF, size, hAlign);
        tf.multiline = tf.wordWrap = multiline;
        if (width != null) tf.width = width;
        if (height != null) tf.height = height;
        tf.x = tf.y = 0;
        tf.text = text;
        textfieldCanvas.draw(tf); // force textfield to update width & height
        if (width == null) tf.width = tf.textWidth + 5;
        if (height == null) tf.height = tf.textHeight + 5;
        tf.x = ox;
        tf.y = oy;
        return tf;
    }

    public static function input(?text: String = "", ?color: Int = 0, ?size: Float = 24, ?hAlign: Int = LEFT,
                                      ?multiline: Bool = false, ?width: Null<Float>, ?height: Null<Float>) : TextField {
        if (textfieldCanvas == null) textfieldCanvas = new BitmapData(100, 100);
        var tf = new TextField();
        var ox = tf.x, oy = tf.y;
        tf.selectable = true;
        tf.mouseEnabled = true;
        tf.type = TextFieldType.INPUT;
        tf.defaultTextFormat = textFormat(color, size, hAlign);
        tf.multiline = tf.wordWrap = multiline;
        if (width != null) tf.width = width;
        if (height != null) tf.height = height;
        tf.x = tf.y = 0;
        tf.text = text;
        textfieldCanvas.draw(tf); // force textfield to update width & height
        if (width == null) tf.width = tf.textWidth + 5;
        if (height == null) tf.height = tf.textHeight + 5;
        tf.x = ox;
        tf.y = oy;
        return tf;
    }

    public static function bitmap(bmpPath: String, ?anchor: Int = TOP_LEFT, ?smooth: Bool = true) : Sprite {
        var sp = new Sprite(), bmp: Bitmap;
        sp.addChild(bmp = new Bitmap(ResKeeper.getAssetImage(bmpPath)));
        bmp.smoothing = smooth;
        rox_anchor(sp, anchor);
        return sp;
    }

    public static function ninePatch(ninePatchPath: String) : RoxNinePatch {
        var id = "9patch://" + ninePatchPath;
        var npd: RoxNinePatchData = cast(ResKeeper.get(id));
        if (npd == null) {
            var bmd = ResKeeper.loadAssetImage(ninePatchPath);
            ResKeeper.add(bmd);
            npd = RoxNinePatchData.fromAndroidNinePng(bmd);
            ResKeeper.add(id, npd);
        }
        return new RoxNinePatch(npd);
    }

    public static function asyncImage(url: String, onComplete: BitmapData -> Void,
                                      ?onRaw: ByteArray -> Void, ?onProgress: Float -> Float -> Void,
                                      ?bundleId: String) {
        var img = ResKeeper.get(url);
        if (img == null) {
            var ldr = new RoxURLLoader(url, RoxURLLoader.IMAGE, function(isOk: Bool, data: Dynamic) {
                if (isOk) {
                    onComplete(cast data);
                    ResKeeper.add(url, data, bundleId);
                } else {
                    onComplete(null);
                }
            });
            ldr.onRaw = onRaw;
            ldr.onProgress = onProgress;
            ldr.start();
        } else { // already in cache
            delay(function() { onComplete(cast img); });
        }
    }

    private static var defaultBg: RoxNinePatchData;
    public static function buttonBackground() : RoxNinePatch {
        if (defaultBg == null) {
            var s = new Shape();
            var gfx = s.graphics;
            var mat = new Matrix();
            mat.createGradientBox(48, 48, GameUtil.PId2, 0, 0);
            gfx.beginGradientFill(GradientType.LINEAR, [ 0xCCFFFF, 0x33CCFF ], [ 1.0, 1.0 ], [ 0, 255 ], mat);
            gfx.lineStyle(2, 0x0099CC);
            gfx.drawRoundRect(1, 1, 46, 46, 16, 16);
            gfx.endFill();
            var bmd = new BitmapData(48, 48, true, 0);
            bmd.draw(s);
            defaultBg = new RoxNinePatchData(new Rectangle(8, 8, 32, 32), bmd);
        }
        return new RoxNinePatch(defaultBg);
    }

    public static function button(?anchor: Int = TOP_LEFT, // anchor point relative to register point
                                  ?iconPath: String,
                                  ?text: String, ?fontColor: Int = 0, ?fontSize: Float = 24,
                                  ?childrenAlign: Int = VCENTER, // alignment of children
                                  ?ninePatchPath: String,
                                  ?listener: Dynamic -> Void) : RoxFlowPane {
        var name = text;
        if (name == null) {
            var i1 = iconPath.lastIndexOf("/"), i2 = iconPath.lastIndexOf(".");
            name = iconPath.substr(i1 + 1, i2 - i1 - 1);
        }
        var bg = ninePatchPath != null ? ninePatch(ninePatchPath) : null;
        var children: Array<DisplayObject> = [];
        if (iconPath != null) {
            var iconsp = UiUtil.bitmap(iconPath);
            children.push(iconsp);
        }
        if (text != null) {
            var texttf = staticText(text, fontColor, fontSize);
            children.push(texttf);
        }

        var sp = new RoxFlowPane(null, null, anchor, children, bg, childrenAlign, listener);
        sp.name = name;
        return sp;
    }

    public static function switchControl(on: Bool) : Sprite {
        var d2rscale = RoxApp.screenWidth / 640;
        var sp = new Sprite();
        GfxUtil.rox_fillRect(sp.graphics, 0x33333333, 0, 0, 100 * d2rscale, 40 * d2rscale);
        var txt = UiUtil.staticText(on ? "ON" : "OFF", 0xFFFFFF, 26 * d2rscale);
        if (on) {
            GfxUtil.rox_fillRoundRect(sp.graphics, 0xFF0000FF, 50 * d2rscale, 0, 50 * d2rscale, 40 * d2rscale, 8);
        } else {
            GfxUtil.rox_fillRoundRect(sp.graphics, 0xFF555555, 0, 0, 50 * d2rscale, 40 * d2rscale, 8);
        }
        sp.addChild(UiUtil.rox_move(txt, (on ? 50 * d2rscale : 0) + (50 * d2rscale - txt.width) / 2, (40 * d2rscale - txt.height) / 2));
        return sp;
    }

    public static inline function rox_pixelWidth(sp: Sprite) : Float { // TODO: need more elegant method
        return cast(sp.getChildAt(0), Bitmap).bitmapData.width;
    }

    public static inline function rox_pixelHeight(sp: Sprite) : Float {
        return cast(sp.getChildAt(0), Bitmap).bitmapData.height;
    }

    public static inline function rox_move(dp: DisplayObject, x: Float, y: Float) : DisplayObject {
        dp.x = x;
        dp.y = y;
        return dp;
    }

    public static function rox_anchor(sp: Sprite, anchor: Int) : Sprite {
        var w = sp.width / sp.scaleX, h = sp.height / sp.scaleY;
        var xoff = (anchor & 0x0F) == RIGHT ? -w : (anchor & 0x0F) == HCENTER ? -w / 2 : 0;
        var yoff = (anchor & 0xF0) == BOTTOM ? -h : (anchor & 0xF0) == VCENTER ? -h / 2 : 0;
        for (i in 0...sp.numChildren) {
            var c = sp.getChildAt(i);
            rox_move(c, c.x + xoff, c.y + yoff);
        }
        return sp;
    }

    public static inline function rox_scale(dp: DisplayObject, scalex: Float, ?scaley: Null<Float>) : DisplayObject {
        dp.scaleX = scalex;
        dp.scaleY = scaley != null ? scaley : scalex;
        return dp;
    }

    public static inline function rox_dimension(dp: DisplayObject) : Rectangle {
        return new Rectangle(dp.x, dp.y, dp.width, dp.height);
    }

    public static inline function rox_rectStr(r: Rectangle) : String {
        return "Rect(" + r.x + "," + r.y + "," + r.width + "," + r.height + ")";
    }

    public static inline function rox_pointStr(p: Point) : String {
        return "Point(" + p.x + "," + p.y + ")";
    }

    public static inline function rox_stopPropagation(event: Dynamic, ?immediate: Null<Bool> = false) {
//#if cpp
//        Reflect.setField(event, "nmeIsCancelled", true);
//        if (immediate) Reflect.setField(event, "nmeIsCancelledNow", true);
//
//#else
        event.stopPropagation();
        if (immediate) event.stopImmediatePropagation();
//#end
    }

    public static inline function rox_removeAll(dpc: DisplayObjectContainer) : DisplayObjectContainer {
        var count = dpc.numChildren;
        for (i in 0...count) {
            dpc.removeChildAt(count - i - 1);
        }
        return dpc;
    }

    public static inline function rox_remove(dpc: DisplayObjectContainer, dp: DisplayObject) : DisplayObjectContainer {
        if (dp != null && dpc.contains(dp)) dpc.removeChild(dp);
        return dpc;
    }

    public static inline function rox_removeByName(dpc: DisplayObjectContainer, name: String) : DisplayObjectContainer {
        var dp = dpc.getChildByName(name);
        if (dp != null) dpc.removeChild(dp);
        return dpc;
    }
    public static inline function rox_onClick(sp: InteractiveObject, listener: Dynamic -> Void) : InteractiveObject {
        sp.mouseEnabled = true;
        sp.addEventListener(MouseEvent.CLICK, listener);
        return sp;
    }

    public static inline function rangeValue<T: Float>(v: T, min: T, max: T) : T {
        return v < min ? min : v > max ? max : v;
    }

    public static function delay(task: Void -> Void, ?timeInSec: Float = 0) {
        Timer.delay(task, Std.int(timeInSec * 1000));
    }

    public static function message(text: String, ?timeInSec: Float = 2.0) {
        var stage = Lib.current.stage;
        var ratio = stage.stageWidth / 640;
        var label = UiUtil.staticText(text, 0xFFFFFF, 24 * ratio);
        var box = new Sprite();
        GfxUtil.rox_fillRoundRect(box.graphics, 0xBB333333, 0, 0, label.width + 20, label.height + 16);
        box.addChild(UiUtil.rox_move(label, (box.width - label.width) / 2, (box.height - label.height) / 2));
        stage.addChild(UiUtil.rox_move(box, (stage.stageWidth - box.width) / 2, stage.stageHeight - box.height - 100 * ratio));
        delay(function() { stage.removeChild(box); }, timeInSec);
    }

}

