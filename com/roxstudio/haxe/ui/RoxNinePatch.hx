package com.roxstudio.haxe.ui;

import flash.geom.Matrix;
import nme.display.BitmapData;
import nme.display.Sprite;
import nme.geom.Point;
import nme.geom.Rectangle;
import nme.Vector;

class RoxNinePatch extends Sprite {

    public var hScale(default, null): Float;
    public var vScale(default, null): Float;
    public var data(default, null): RoxNinePatchData;
    public var marginLeft(get_marginLeft, null): Float;
    public var marginRight(get_marginRight, null): Float;
    public var marginTop(get_marginTop, null): Float;
    public var marginBottom(get_marginBottom, null): Float;

    public function new(data: RoxNinePatchData) {
        super();
        this.data = data;
        setScale(1.0);
    }

    public function setScale(hScale: Float, ?vScale: Null<Float>) : RoxNinePatch {
        if (vScale == null) vScale = hScale;
        this.hScale = hScale;
        this.vScale = vScale;
        var w = data.clipRect.width, h = data.clipRect.height;
        var g = data.ninePatchGrid;
        graphics.clear();
        if (data.bitmapData != null) {
            var ngw = w * hScale - w + g.width;
            var ngh = h * vScale - h + g.height;
#if !html5
            var vts = new Vector<Float>();
            var hval = [0.0, g.x, g.x + ngw, w * hScale];
            var vval = [0.0, g.y, g.y + ngh, h * vScale];
            for (i in 0...4) {
                for (j in 0...4) {
                    vts.push(hval[j]);
                    vts.push(vval[i]);
                }
            }
            graphics.beginBitmapFill(data.bitmapData, null, false, true);
            graphics.drawTriangles(vts, data.ids, data.uvs);
            graphics.endFill();
#else
            var hval = [0.0, g.x, g.x, g.x + ngw, g.x + ngw, w * hScale];
            var vval = [0.0, g.y, g.y, g.y + ngh, g.y + ngh, h * vScale];
            for (i in 0...3) {
                var yy = vval[i << 1], hh = vval[(i << 1) + 1];
                for (j in 0...3) {
                    var xx = hval[j << 1], ww = hval[(i << 1) + 1], idx = i * 3 + j;
                    var bbmd: BitmapData;
                    if ((bbmd = data.gridBmds[idx]) != null) {
                        graphics.beginBitmapFill(bbmd, new Matrix(ww / bbmd.width, 0, 0, hh / bbmd.height, 0, 0));
                        graphics.drawRect(xx, yy, ww, hh);
                        graphics.endFill();
                    }
                }
            }
#end
        } else { // fake-transparent background
            graphics.beginFill(0xFFFFFF, 0.005);
            graphics.drawRect(0, 0, w * hScale, h * vScale);
            graphics.endFill();
        }
        return this;
    }

    public inline function setDimension(inWidth: Float, inHeight: Float) : RoxNinePatch {
        return setScale(inWidth / data.clipRect.width, inHeight / data.clipRect.height);
    }

    public inline function getContentRect() : Rectangle {
        var g = data.contentGrid, c = data.clipRect;
        return new Rectangle(g.x, g.y, c.width * (hScale - 1) + g.width, c.height * (vScale - 1) + g.height);
    }

    private inline function get_marginLeft() : Float {
        return data.contentGrid.x;
    }

    private inline function get_marginRight() : Float {
        return data.clipRect.width - data.contentGrid.right;
    }

    private inline function get_marginTop() : Float {
        return data.contentGrid.y;
    }

    private inline function get_marginBottom() : Float {
        return data.clipRect.height - data.contentGrid.bottom;
    }

}
