package com.roxstudio.haxe.game;

import nme.display.CapsStyle;
import nme.display.LineScaleMode;
import nme.display.BitmapData;
import nme.display.Graphics;
import nme.geom.Matrix;
import nme.geom.Rectangle;

class GfxUtil {

    private function new() {
    }

    public static inline function rox_line(g: Graphics, thickness: Int = 1, color: Int,
                                           x1: Float, y1: Float, x2: Float, y2: Float) : Graphics {
        g.lineStyle(thickness, color & 0xFFFFFF, (color >>> 24) / 255, false, LineScaleMode.NONE, CapsStyle.NONE);
        g.moveTo(x1, y1);
        g.lineTo(x2, y2);
        g.lineStyle();
        return g;
    }

    public static inline function rox_drawImage(g: Graphics, bmd: BitmapData, ?matrix: Matrix,
                                                ?repeat: Bool = true, ?smooth: Bool = true,
                                                x: Float, y: Float, w: Float, h: Float) : Graphics {
        g.beginBitmapFill(bmd, matrix, repeat, smooth);
        g.drawRect(x, y, w, h);
        g.endFill();
        return g;
    }

    public static inline function rox_drawRegion(g: Graphics, bmd: BitmapData, ?region: Rectangle,
                                                 x: Float, y: Float, ?w: Null<Float>, ?h: Null<Float>,
                                                 ?smooth: Bool = true) : Graphics {
        if (region == null) region = new Rectangle(0, 0, bmd.width, bmd.height);
        if (w == null) w = region.width;
        if (h == null) h = region.height;
        var xsc = w / region.width, ysc = h / region.height;
        var mat = new Matrix(xsc, 0, 0, ysc, x - region.x * xsc, y - region.y * ysc);
        g.beginBitmapFill(bmd, mat, false, smooth);
        g.drawRect(x, y, w, h);
        g.endFill();
        return g;
    }

    public static inline function rox_drawRegionRound(g: Graphics, bmd: BitmapData, ?region: Rectangle,
                                                 x: Float, y: Float, ?w: Null<Float>, ?h: Null<Float>,
                                                 hRadius: Float = 6, ?vRadius: Null<Float>,
                                                 ?smooth: Bool = true) : Graphics {
        if (region == null) region = new Rectangle(0, 0, bmd.width, bmd.height);
        if (w == null) w = region.width;
        if (h == null) h = region.height;
        var xsc = w / region.width, ysc = h / region.height;
        var mat = new Matrix(xsc, 0, 0, ysc, x - region.x * xsc, y - region.y * ysc);
        g.beginBitmapFill(bmd, mat, false, smooth);
        if (vRadius == null) vRadius = hRadius;
        g.drawRoundRect(x, y, w, h, 2 * hRadius, 2 * vRadius);
        g.endFill();
        return g;
    }

    public static inline function rox_bitmapFill(g: Graphics, bmd: BitmapData, ?region: Rectangle,
                                               x: Float, y: Float, w: Float, h: Float) : Graphics {
        if (region == null) region = new Rectangle(0, 0, bmd.width, bmd.height);
        var rx = region.x, ry = region.y, rw = region.width, rh = region.height;
        var mat = new Matrix(1, 0, 0, 1, 0, 0);
        var cols = Std.int((w + rw - 1) / rw), rows = Std.int((h + rh - 1) / rh);
        var remw = w + rw - rw * cols, remh = h + rh - rh * rows;
        for (i in 0...rows) {
            for (j in 0...cols) {
                var xx = x + j * rw, yy = y + i * rh;
                mat.tx = xx - rx;
                mat.ty = yy - ry;
                g.beginBitmapFill(bmd, mat, false, false);
                g.drawRect(xx, yy, j == cols - 1 ? remw : rw, i == rows - 1 ? remh : rh);
            }
        }
        g.endFill();
        return g;
    }

    public static inline function rox_fillRect(g: Graphics, color: Int,
                                               x: Float, y: Float, w: Float, h: Float) : Graphics {
        g.beginFill(color & 0xFFFFFF, (color >>> 24) / 255);
        g.drawRect(x, y, w, h);
        g.endFill();
        return g;
    }

    public static inline function rox_drawRect(g: Graphics, thickness: Float, color: Int,
                                               x: Float, y: Float, w: Float, h: Float) : Graphics {
        g.lineStyle(thickness, color & 0xFFFFFF, (color >>> 24) / 255);
        g.drawRect(x, y, w, h);
        g.lineStyle();
        return g;
    }

    public static inline function rox_fillRoundRect(g: Graphics, color: Int,
                                                    x: Float, y: Float, w: Float, h: Float,
                                                    hRadius: Float = 6, ?vRadius: Null<Float>) : Graphics {
        g.beginFill(color & 0xFFFFFF, (color >>> 24) / 255);
        if (vRadius == null) vRadius = hRadius;
        g.drawRoundRect(x, y, w, h, 2 * hRadius, 2 * vRadius);
        g.endFill();
        return g;
    }

    public static inline function rox_drawRoundRect(g: Graphics, thinkness: Float, color: Int,
                                                    x: Float, y: Float, w: Float, h: Float,
                                                    hRadius: Float = 6, ?vRadius: Null<Float>) : Graphics {
        g.lineStyle(thinkness, color & 0xFFFFFF, (color >>> 24) / 255);
        if (vRadius == null) vRadius = hRadius;
        g.drawRoundRect(x, y, w, h, 2 * hRadius, 2 * vRadius);
        g.lineStyle();
        return g;
    }

}
